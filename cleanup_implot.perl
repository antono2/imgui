#!/usr/bin/perl
use strict;
use warnings;

my $file_in  = $ARGV[0] // (-f 'cimplot.v' ? 'cimplot.v' : 'src/implot.v');
my $file_out = $ARGV[1] // 'src/implot.v';
my $module_name = 'implot';
my $prefix = 'ImPlot';
my $snake_prefix = 'im_plot_';

sub slurp_file {
  my ($path) = @_;
  open my $fh, '<', $path or die "Can not read ${path}: $!";
  local $/;
  my $text = <$fh>;
  close $fh;
  return $text;
}

sub write_file {
  my ($path, $text) = @_;
  open my $fh, '>', $path or die "Can not write ${path}: $!";
  print $fh $text;
  close $fh;
}

sub split_top_level_commas {
  my ($s) = @_;
  return () if !defined($s) || $s eq '';
  my @out; my $cur=''; my $depth=0;
  foreach my $ch (split //, $s) {
    if ($ch eq '(') { $depth++; $cur .= $ch; next; }
    if ($ch eq ')') { $depth-- if $depth > 0; $cur .= $ch; next; }
    if ($ch eq ',' && $depth == 0) { push @out, $cur; $cur=''; next; }
    $cur .= $ch;
  }
  push @out, $cur if $cur ne '';
  return @out;
}

sub camel_to_snake {
  my ($s) = @_;
  $s =~ s/([a-z0-9])([A-Z])/$1_$2/g;
  $s =~ s/([A-Z]+)([A-Z][a-z])/$1_$2/g;
  return lc($s);
}

sub strip_main_prefixes {
  my ($s) = @_;
  return '' if !defined $s;
  $s =~ s/\bmain\.//g;
  $s =~ s/\bMain\.//g;
  return $s;
}

sub clean_public_name {
  my ($name) = @_;
  return '' if !defined $name;
  $name = strip_main_prefixes($name);
  $name =~ s/^C\.//;
  $name =~ s/^${prefix}//;
  $name =~ s/^${module_name}\.//;
  $name =~ s/^Main\.//;
  $name =~ s/\.$//;
  return $name;
}

sub clean_type_expr {
  my ($expr) = @_;
  return '' if !defined $expr;
  $expr = strip_main_prefixes($expr);
  $expr =~ s/\bint\b/i32/g;
  my $changed = 1;
  while ($changed) {
    $changed = 0;
    my $old = $expr;
    $expr =~ s/C\.[A-Za-z_][A-Za-z0-9_]*\(([^()]+)\)/clean_type_expr($1)/ge;
    $changed = 1 if $expr ne $old;
  }
  $expr =~ s/\bImGui([A-Za-z0-9_]+)/'imgui.' . clean_public_name("ImGui$1")/ge;
  $expr =~ s/\b${prefix}([A-Za-z0-9_]+)/clean_public_name("${prefix}$1")/ge;
  $expr =~ s/\b${module_name}\.([A-Za-z0-9_]+)/clean_public_name($1)/ge;
  $expr =~ s/\bMain\b//g;
  $expr =~ s/\bmain\b//g;
  $expr =~ s/\s+/ /g;
  $expr =~ s/^\s+|\s+$//g;
  return $expr;
}

sub clean_value_expr {
  my ($expr) = @_;
  return '' if !defined $expr;
  $expr = strip_main_prefixes($expr);
  my $changed = 1;
  while ($changed) {
    $changed = 0;
    my $old = $expr;
    $expr =~ s/C\.[A-Za-z_][A-Za-z0-9_]*\(([^()]+)\)/clean_value_expr($1)/ge;
    $changed = 1 if $expr ne $old;
  }
  $expr =~ s/\bImGui([A-Za-z0-9_]+)/'imgui.' . clean_public_name("ImGui$1")/ge;
  $expr =~ s/\b${prefix}([A-Za-z0-9_]+)/clean_public_name("${prefix}$1")/ge;
  $expr =~ s/\b${module_name}\.([A-Za-z0-9_]+)/clean_public_name($1)/ge;
  $expr =~ s/\bMain\b//g;
  $expr =~ s/\bmain\b//g;
  $expr =~ s/\s+/ /g;
  $expr =~ s/^\s+|\s+$//g;
  return $expr;
}

sub bits_expr {
  my ($n) = @_;
  return undef if !defined($n) || $n < 0;
  return '0' if $n == 0;
  my @parts; my $bit=0;
  while ($n > 0) { push @parts, "1 << $bit" if ($n & 1); $n >>= 1; $bit++; }
  return join(' | ', @parts);
}

sub enum_is_bitflag {
  my ($body) = @_;
  my @vals = map { 0 + $_ } ($body =~ /^\s*\w+\s*=\s*(-?\d+)\s*$/mg);
  return 0 if scalar(@vals) < 3;
  my @sorted = sort { $a <=> $b } @vals;
  my $consecutive = 0;
  for (my $i = 1; $i <= $#sorted; $i++) {
    $consecutive++ if $sorted[$i] == $sorted[$i - 1] + 1;
  }
  return 0 if $consecutive >= 2 && $consecutive >= int(($#sorted) * 0.4);
  my ($pos, $powish) = (0, 0);
  foreach my $v (@sorted) {
    next if $v <= 0;
    $pos++;
    my $tmp = $v;
    my $bits = 0;
    while ($tmp > 0) { $bits += ($tmp & 1); $tmp >>= 1; }
    $powish++ if $bits <= 8;
  }
  return ($pos > 0 && $powish >= int($pos * 0.75)) ? 1 : 0;
}

sub clean_enum_member {
  my ($enum_name, $member) = @_;
  my $clean_enum = clean_public_name($enum_name);
  my $snake = camel_to_snake($clean_enum);
  $snake =~ s/_+$//;
  $member =~ s/^${snake_prefix}//;
  $member =~ s/^\Q${snake}\E_?//;
  $member =~ s/^([0-9])/_$1/;
  return $member;
}

sub clean_function_name {
  my ($name) = @_;
  $name = clean_public_name($name);
  $name =~ s/^ip_//;
  $name =~ s/^im_plot_//;
  $name =~ s/_im_plot_/_/g;
  my $changed = 1;
  while ($changed) {
    $changed = 0;
    if ($name =~ s/^([a-z0-9]+)_\1(?:_|$)/$1_/) { $changed = 1; }
    my @parts = split /_/, $name;
    for my $n (reverse 1 .. int(scalar(@parts) / 2)) {
      next if 2 * $n > scalar(@parts);
      my $a = join('_', @parts[0 .. $n - 1]);
      my $b = join('_', @parts[$n .. (2 * $n) - 1]);
      if ($a ne '' && $a eq $b) {
        my @rest = @parts[(2 * $n) .. $#parts];
        $name = join('_', $a, @rest);
        $name =~ s/_+$//;
        $changed = 1;
        last;
      }
    }
  }
  return $name;
}

sub process_enum_block {
  my ($orig_name, $body) = @_;
  my $name = clean_public_name($orig_name);
  my $bitflag = enum_is_bitflag($body);
  my @out;
  foreach my $line (split /\n/, $body, -1) {
    if ($line =~ /^(\s*)(\w+)(\s*=\s*)([^\n]+?)(\s*)$/) {
      my ($ind, $m, $eq, $rhs, $trail) = ($1, $2, $3, $4, $5);
      my $clean = clean_enum_member($name, $m);
      my $expr = clean_value_expr($rhs);
      if ($expr =~ /^-?\d+$/ && $bitflag) {
        my $bits = bits_expr($expr + 0);
        $expr = defined($bits) ? $bits : $expr;
      }
      push @out, $ind . $clean . $eq . $expr;
    } elsif ($line =~ /^(\s*)(\w+)(\s*)$/) {
      push @out, $1 . clean_enum_member($name, $2) . $3;
    } else {
      push @out, clean_value_expr($line);
    }
  }
  return "pub enum $name {\n" . join("\n", @out) . "\n}";
}

sub process_struct_block {
  my ($orig_name, $body) = @_;
  my $clean = clean_public_name($orig_name);
  my @members;
  foreach my $line (split /\n/, $body, -1) {
    next if $line =~ /^\s*$/;
    if ($line =~ /^\s*(\w+)\s+(.+?)\s*$/) {
      my ($name, $type) = ($1, clean_type_expr($2));
      $name = 'Type' if $name eq 'type';
      $name = '_' . $name if $name =~ /^\d/;
      push @members, "\t$name $type";
    } else {
      push @members, clean_type_expr($line);
    }
  }
  return "pub type $clean = C.$orig_name\n\@[typedef]\npub struct C.$orig_name {\npub mut:\n" . join("\n", @members) . "\n}";
}

sub parse_v_fn_decl {
  my ($line) = @_;
  return unless $line =~ /^\s*(?:pub\s+)?fn\s+([\w\d_]+)\((.*)\)(?:\s+([^\{\n]+))?\s*$/;
  my ($name, $params, $ret) = ($1, defined($2) ? $2 : '', defined($3) ? $3 : '');
  $params =~ s/^\s+|\s+$//g;
  $ret =~ s/^\s+|\s+$//g;
  return ($name, $params, $ret);
}

sub clean_fn_params {
  my ($params) = @_;
  return '' if !defined($params) || $params eq '';
  my @out;
  foreach my $p (split_top_level_commas($params)) {
    $p =~ s/^\s+|\s+$//g;
    next if $p eq '';
    if ($p eq '...') { push @out, '...'; next; }
    if ($p =~ /^mut\s+(\w+)\s+(.+)$/) {
      push @out, 'mut ' . $1 . ' ' . clean_type_expr($2);
    } elsif ($p =~ /^(\w+)\s+(.+)$/) {
      my ($n, $t) = ($1, $2);
      $n = 'type_' if $n eq 'type';
      push @out, $n . ' ' . clean_type_expr($t);
    } else {
      push @out, clean_type_expr($p);
    }
  }
  return join(', ', @out);
}

sub build_c_decl_params {
  my ($params) = @_;
  return '' if !defined($params) || $params eq '';
  my @out;
  foreach my $p (split_top_level_commas($params)) {
    $p =~ s/^\s+|\s+$//g;
    next if $p eq '';
    if ($p eq '...') { push @out, '...'; next; }
    if ($p =~ /^mut\s+(\w+)\s+(.+)$/) {
      push @out, 'mut_' . $1 . ' ' . clean_type_expr($2);
    } elsif ($p =~ /^(\w+)\s+(.+)$/) {
      my ($n, $t) = ($1, $2);
      $n = 'type_' if $n eq 'type';
      push @out, $n . ' ' . clean_type_expr($t);
    } else {
      push @out, clean_type_expr($p);
    }
  }
  return join(', ', @out);
}

sub build_call_args {
  my ($params) = @_;
  return '' if !defined($params) || $params eq '';
  my @out;
  foreach my $p (split_top_level_commas($params)) {
    $p =~ s/^\s+|\s+$//g;
    next if $p eq '' || $p eq '...';
    if ($p =~ /^mut\s+(\w+)\b/) { push @out, 'mut_' . $1; }
    elsif ($p =~ /^(\w+)\b/) {
      my $n = $1;
      $n = 'type_' if $n eq 'type';
      push @out, $n;
    }
  }
  return join(', ', @out);
}

sub transform_functions {
  my ($text) = @_;
  my @lines = split /\n/, $text, -1;
  my @out;
  for (my $i = 0; $i <= $#lines; $i++) {
    my $line = $lines[$i];
    next if $line =~ /^\s*\@\[translated\]\s*$/;
    if ($line =~ /^\s*\@\[c:\s*'([^']+)'\]\s*$/) {
      my $c_symbol = $1;
      my @attrs;
      while ($i < $#lines && $lines[$i + 1] =~ /^\s*\@\[(?!c:|translated).+\]\s*$/) {
        push @attrs, $lines[++$i];
      }
      if ($i < $#lines && $lines[$i + 1] =~ /^\s*(?:pub\s+)?fn\s+/) {
        my $decl = $lines[++$i];
        my ($fn, $params, $ret) = parse_v_fn_decl($decl);
        if (!defined $fn) { push @out, $line, @attrs, $decl; next; }
        my $pub_name = clean_function_name($fn);
        my $v_params = clean_fn_params($params);
        my $ret_clean = clean_type_expr($ret);
        my $ret_suffix = $ret_clean ne '' ? ' ' . $ret_clean : '';
        my $has_variadic = grep { /c2v_variadic/ } @attrs;
        if ($has_variadic || $v_params =~ /\.\.\./) {
          push @out, "\@[c: '$c_symbol']";
          push @out, grep { $_ !~ /translated/ } @attrs;
          push @out, 'pub fn ' . $pub_name . '(' . $v_params . ')' . $ret_suffix;
          push @out, '';
          next;
        }
        my $c_params = build_c_decl_params($v_params);
        my $call = 'C.' . $c_symbol . '(' . build_call_args($v_params) . ')';
        push @out, '\@[keep_args_alive]';
        push @out, 'fn C.' . $c_symbol . '(' . $c_params . ')' . $ret_suffix;
        push @out, '';
        push @out, '\@[inline]';
        push @out, 'pub fn ' . $pub_name . '(' . $v_params . ')' . $ret_suffix . ' {';
        push @out, ($ret_clean ne '' ? "\treturn $call" : "\t$call");
        push @out, '}';
        push @out, '';
        next;
      }
    }
    if ($line =~ /^\s*fn\s+/) { $line =~ s/^\s*fn\s+/pub fn /; }
    if ($line =~ /^\s*type\s+/) { $line =~ s/^\s*type\s+/pub type /; }
    push @out, $line;
  }
  return join("\n", @out);
}

sub rewrite_type_aliases {
  my ($text) = @_;
  my @out;
  foreach my $line (split /\n/, $text, -1) {
    if ($line =~ /^\s*type\s+([^\s=]+)\s*=\s*(.+)$/) {
      my $lhs = clean_public_name($1);
      my $rhs = clean_type_expr($2);
      next if $lhs eq '' || $rhs eq '';
      next if $lhs =~ /\./ || $lhs eq 'Main' || $lhs eq 'main';
      next if $rhs =~ /^C\.main$/i || $rhs eq 'main' || $rhs eq 'Main';
      next if $lhs eq $rhs;
      push @out, "pub type $lhs = $rhs";
      next;
    }
    push @out, $line;
  }
  return join("\n", @out);
}

my $content = slurp_file($file_in);
$content =~ s/\r//g;
$content =~ s/\@\[translated\]\s*//g;
$content =~ s/^module\s+main\s*$/module implot\n\nimport imgui\nimport time/mg;
$content =~ s/\bmain\.//g;
$content =~ s/\bMain\.//g;

$content =~ s/^(?:pub\s+)?struct\s+(\w+)\s*\{(.*?)^\}/process_struct_block($1, $2)/egms;
$content =~ s/^(?:pub\s+)?enum\s+(\w+)\s*\{(.*?)^\}/process_enum_block($1, $2)/egms;
$content = rewrite_type_aliases($content);
$content = transform_functions($content);

$content =~ s/\bmain\.//g;
$content =~ s/\bMain\.//g;
$content =~ s/^pub type Main\.[^\n]*\n(?:\@\[typedef\]\n)?pub struct C\.[^\n]*\{\}\n?//mg;
$content =~ s/^pub type Main[^\n]*\n(?:\@\[typedef\]\n)?pub struct C\.[^\n]*\{\}\n?//mg;
$content =~ s/^pub type (\w+) = \1\s*\n(?:\@\[typedef\]\n)?pub struct \1 \{\}\n?//mg;
$content =~ s/^pub type (\w+) = \1\s*$//mg;
$content =~ s/^\@\[translated\]\s*$//mg;
$content =~ s/\n{3,}/\n\n/g;

write_file($file_out, $content);
