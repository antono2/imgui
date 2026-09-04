#!/usr/bin/env perl
use strict;
use warnings;

# Generic cleanup for V files produced by c2v from cimgui/cimplot.
# Usage:
#   perl cleanup_imgui_implot.perl                 # clean src/imgui.v and src/implot.v
#   perl cleanup_imgui_implot.perl imgui           # clean only src/imgui.v
#   perl cleanup_imgui_implot.perl implot          # clean only src/implot.v
#   perl cleanup_imgui_implot.perl input.v out.v imgui|implot

my %CFG = (
  imgui => {
    module => 'imgui', prefix => 'ImGui', lower => 'im_gui_', c_prefix => 'ig',
    in => 'src/imgui.v', fallback => 'cimgui.v', out => 'src/imgui.v', header => 'cimgui/cimgui.h', version_macro => 'IMGUI',
    imports => '',
  },
  implot => {
    module => 'implot', prefix => 'ImPlot', lower => 'im_plot_', c_prefix => 'ImPlot',
    in => 'src/implot.v', fallback => 'cimplot.v', out => 'src/implot.v', header => 'cimplot/cimplot.h', version_macro => 'IMPLOT',
    imports => "\n\nimport imgui\n// C.tm is used by translated callback signatures. Keep the import explicitly.\nimport time as _",
  },
);

if (@ARGV >= 3) {
  clean_one($ARGV[2], $ARGV[0], $ARGV[1]);
  exit 0;
}
my $mode = $ARGV[0] // 'both';
for my $kind (qw(imgui implot)) {
  next if $mode ne 'both' && $mode ne $kind;
  my $in = -e $CFG{$kind}{in} ? $CFG{$kind}{in} : $CFG{$kind}{fallback};
  clean_one($kind, $in, $CFG{$kind}{out});
}

sub clean_one {
  my ($kind, $infile, $outfile) = @_;
  die "Unknown kind $kind\n" unless exists $CFG{$kind};
  die "Missing input $infile\n" unless -e $infile;

  my $src = slurp($infile);
  my $hdrfile = find_header($kind);
  my $hdr = $hdrfile ne '' ? slurp($hdrfile) : '';
  my %const_params = parse_const_params($hdr);
  my ($ver, $vernum) = parse_version($src, $hdr, $kind);

  $src =~ s/\r\n/\n/g;
  $src =~ s/^\s*module\s+(?:main|imgui|implot)\s*\n//m;
  $src =~ s/^\s*\@\[translated\]\s*\n//mg;
  $src =~ s/^\s*\\\@\[/@[/mg;
  $src =~ s#^\s*/\@\[#@[#mg;
  $src =~ s/\bmain\.//g;
  $src =~ s/\bMain\.//g;
  $src =~ s/\bC\.int\(([^)]+)\)/$1/g;

  my @lines = split /\n/, $src;
  my @out;
  my %seen_type;
  my %seen_struct;
  my %seen_enum;
  my (%imported_c_struct, %imported_c_alias);
  if ($kind eq 'implot') {
    my $imgui_file = find_imgui_binding($outfile);
    die "Cannot deduplicate ImPlot declarations: imgui.v was not found\n" if $imgui_file eq '';
    my $imgui_src = slurp($imgui_file);
    while ($imgui_src =~ /^\s*pub\s+struct\s+C\.([A-Za-z_]\w*)\b/gm) {
      $imported_c_struct{$1} = 1;
    }
    while ($imgui_src =~ /^\s*pub\s+type\s+([A-Za-z_]\w*)\s*=\s*C\.([A-Za-z_]\w*)\s*$/gm) {
      $imported_c_alias{$2} = $1;
    }
  }

  for (my $i = 0; $i <= $#lines; $i++) {
    my $line = $lines[$i];
    next if skip_line($line);

    # Attribute mapped function.
    if ($line =~ /^\s*\@\[c:\s*'([^']+)'\]\s*$/) {
      my $csym = $1;
      my @attrs;
      while ($i < $#lines && $lines[$i+1] =~ /^\s*\@\[[^\]]+\]\s*$/) { $i++; push @attrs, $lines[$i]; }
      if ($i < $#lines && $lines[$i+1] =~ /^\s*(?:pub\s+)?fn\s+/) {
        my $decl = $lines[++$i];
        if (my @fn = parse_fn($decl)) { push @out, emit_function($kind, $csym, @fn, \%const_params); }
      }
      next;
    }

    # Unmapped function: infer C symbol.
    if ($line =~ /^\s*(?:pub\s+)?fn\s+/) {
      if (my @fn = parse_fn($line)) {
        my ($vname) = @fn;
        my $csym = infer_c_symbol($kind, $vname);
        push @out, emit_function($kind, $csym, @fn, \%const_params);
      }
      next;
    }

    # Enum block.
    if ($line =~ /^\s*(?:pub\s+)?enum\s+([A-Za-z_]\w*)\s*\{\s*$/) {
      my $orig_enum = $1;
      my @body;
      while (++$i <= $#lines) { last if $lines[$i] =~ /^\s*}\s*$/; push @body, $lines[$i]; }
      my $ename = clean_enum_name($kind, $orig_enum);
      next if $seen_enum{$ename}++;
      push @out, emit_enum($kind, $ename, $orig_enum, \@body);
      next;
    }

    # Struct block.
    if ($line =~ /^\s*(?:pub\s+)?struct\s+((?:C\.)?[A-Za-z_]\w*)\s*\{\s*$/) {
      my $orig = $1;
      my @body;
      while (++$i <= $#lines) { last if $lines[$i] =~ /^\s*}\s*$/; push @body, $lines[$i]; }
      my $clean = clean_type_name($kind, $orig);
      my $c_name = $orig;
      $c_name =~ s/^C\.//;
      if ($kind eq 'implot' && $imported_c_struct{$c_name}) {
        my $alias = $imported_c_alias{$c_name};
        if (defined $alias && !$seen_type{$clean}++) {
          push @out, "pub type $clean = imgui.$alias";
        }
        next;
      }
      next if $clean =~ /^(Main|C)$/ || $clean =~ /\./;
      next if $seen_struct{$clean}++;
      my $block = emit_struct($kind, $orig, $clean, \@body);
      push @out, $block if $block ne '';
      next;
    }

    # Type alias.
    if ($line =~ /^\s*(?:pub\s+)?type\s+((?:C\.)?[A-Za-z_]\w*)\s*=\s*(.+?)\s*$/) {
      my ($raw_name, $raw_rhs) = ($1, $2);
      my ($name, $rhs) = (clean_type_name($kind, $raw_name), clean_type_expr($kind, $raw_rhs));
      next if $name eq '' || $name =~ /\./ || $name eq 'Main' || $name eq $rhs;
      if ($kind eq 'implot' && $raw_rhs =~ /^\s*C\.([A-Za-z_]\w*)\s*$/
          && $imported_c_struct{$1} && defined $imported_c_alias{$1}) {
        $rhs = "imgui.$imported_c_alias{$1}";
      }
      $rhs = normalize_alias_rhs($kind, $name, $rhs);
      next if $seen_type{$name}++;
      push @out, "pub type $name = $rhs";
      next;
    }

    $line = clean_line($kind, $line);
    next if $line =~ /^\s*$/ && (@out == 0 || $out[-1] =~ /^\s*$/);
    push @out, $line;
  }

  my $body = join("\n", @out) . "\n";
  $body = postprocess($kind, $body);
  my $dynamic = dynamic_missing_decls($kind, $body, $hdr, \%imported_c_struct);
  my $final = header_text($kind, $ver, $vernum) . $dynamic . $body;
  $final = postprocess($kind, $final);
  $final =~ s/\\\@\[/@[/g;
  $final =~ s#/\@\[#@[#g;
  $final =~ s/\bmain\.//g;
  $final =~ s/\bMain\.//g;
  $final = final_sanitize($kind, $final);
  $final =~ s/\n{4,}/\n\n\n/g;
  write_file($outfile, $final);
  print "cleaned $kind: $infile -> $outfile\n";
}

sub find_imgui_binding {
  my ($outfile)=@_;
  my $dir = $outfile;
  $dir =~ s#[^/]+$##;
  my @candidates = ('imgui.v', 'src/imgui.v', "${dir}../imgui.v", "${dir}../src/imgui.v");
  for my $f (@candidates) { return $f if -e $f; }
  return '';
}

sub find_header {
  my ($kind)=@_;
  my @candidates = ($CFG{$kind}{header});
  push @candidates, $kind eq 'imgui'
    ? qw(./cimgui/cimgui.h cimgui.h include/cimgui.h ../cimgui/cimgui.h /mnt/data/cimgui.h)
    : qw(./cimplot/cimplot.h cimplot.h include/cimplot.h ../cimplot/cimplot.h /mnt/data/cimplot.h);
  for my $f (@candidates) { return $f if defined $f && -e $f; }
  return '';
}

sub slurp { my ($f)=@_; open my $h, '<', $f or die "Can not read $f: $!"; local $/; my $s=<$h>; close $h; return $s; }
sub write_file { my ($f,$s)=@_; open my $h, '>', $f or die "Can not write $f: $!"; print $h $s; close $h; }

sub skip_line {
  my ($l)=@_;
  return 1 if $l =~ /^\s*\@\[translated\]\s*$/;
  return 1 if $l =~ /^\s*module\s+(?:main|imgui|implot)\s*$/;
  return 1 if $l =~ /^\s*\/\/\s*(This file is automatically generated by|based on|with |typedef |CIMGUI_DEFINE_ENUMS_AND_STRUCTS|namespace)/;

  # Drop raw C/C++ fragments that c2v can leave in translated V. Examples:
  #   #ifdef CIMGUI_DEFINE_ENUMS_AND_STRUCTS
  #   #include "./imgui/misc/freetype/imgui_freetype.h"
  #   typedef struct ImDrawChannel;
  #   struct ImDrawChannel;
  #   typedef ImColor;
  return 1 if $l =~ /^\s*#/;
  return 1 if $l =~ /^\s*typedef\b/;
  return 1 if $l =~ /^\s*struct\s+[A-Za-z_]\w*\s*;\s*$/;
  return 1 if $l =~ /^\s*[A-Za-z_]\w*\s*;\s*$/;
  return 0;
}

sub parse_version {
  my ($src,$hdr,$kind)=@_;
  my ($v,$n)=('', '');
  if ($src =~ /file version\s+"([^"]+)"\s+(\d+)/) { ($v,$n)=($1,$2); }
  my $m = $CFG{$kind}{version_macro};
  if (!$v && $hdr =~ /#define\s+${m}_VERSION\s+"([^"]+)"/) { $v=$1; }
  if (!$n && $hdr =~ /#define\s+${m}_VERSION_NUM\s+(\d+)/) { $n=$1; }
  return ($v,$n);
}

sub header_text {
  my ($kind,$ver,$num)=@_;
  my $s = 'module ' . $CFG{$kind}{module} . $CFG{$kind}{imports} . "\n\n";
  $s .= cleanup_notes($kind);
  $s .= "/*\nMIT License\n\nCopyright Anton Oreskin | https://oreskin.de\n\n";
  $s .= "Permission is hereby granted, free of charge, to any person obtaining a copy\nof this software and associated documentation files (the \"Software\"), to deal\nin the Software without restriction, including without limitation the rights\nto use, copy, modify, merge, publish, distribute, sublicense, and/or sell\ncopies of the Software, and to permit persons to whom the Software is\nfurnished to do so, subject to the following conditions:\n\n";
  $s .= "The above copyright notice and this permission notice shall be included in all\ncopies or substantial portions of the Software.\n\n";
  $s .= "THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR\nIMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,\nFITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE\nAUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER\nLIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,\nOUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE\nSOFTWARE.\n*/\n\n\n";
  $s .= "pub const version = '$ver'\n" if $ver ne '';
  $s .= "pub const version_num = $num\n" if $num ne '';
  $s .= "\n";
  return $s;
}

sub cleanup_notes {
  my ($kind)=@_;
  return "/*
cleanup_imgui_implot.perl non-regression notes

Keep this block current when changing cleanup rules. Do not hardcode one
function, enum member, or struct member; derive facts from cimgui/cimgui.h or
cimplot/cimplot.h, then apply generic V cleanup.

Covered cases and examples:
1. Strip raw C/preprocessor leakage:
     #ifdef CIMGUI_DEFINE_ENUMS_AND_STRUCTS
     typedef struct ImDrawChannel;
     struct ImDrawChannel;
     typedef ImColor;
   Callback typedef parsing is line-based so it never recreates:
     broken callback alias with unsigned __int64 ImU64 payload
2. Const parameter names come from header prototypes:
     CIMGUI_API bool igButton(const char* label,const ImVec2_c size);
   This yields const_label/const_size generically.
3. Missing aliases/opaque declarations are inferred from type positions and
   header typedefs only, not arbitrary capitalized field names.
4. Value backing structs such as ImVec2_c/ImVec4_c/ImColor_c/ImRect_c back public
   aliases ImVec2/ImVec4/ImColor/ImRect. Do not emit duplicate empty C structs.
   Vector fields remain lowercase x/y/z/w for V literals.
5. Remove self-module prefixes: imgui.v must not refer to imgui.Type; implot.v
   must not refer to implot.Type, because each file is already inside that module.
6. STB rectpack names are intentionally preserved from C when c2v produces
   aliases like:
     example: `pub type Stbrp_node_im = Stbrp_node`
   Normalize the RHS to C.stbrp_node and emit an opaque C.stbrp_node typedef
   generically through C-backed alias handling.
7. Enum aliases are handled dynamically, never by member-name lists. V enums
   reject duplicate integer values, while C/C++ enums often define aliases:
     any_popup = 1 << 10 | 1 << 11
     mouse_button_shift_ = 1 << 1
     mouse_button_mask_ = 1 << 2 | 1 << 3
     another_alias = 12
   The cleanup evaluates safe integer enum expressions as it emits each enum;
   if a value was already emitted earlier in the same enum, the later member
   is commented out. This prevents regressions such as `enum value 12 already
   exists` without hardcoding a specific enum or member name.
*/

";
}

sub dynamic_missing_decls {
  my ($kind, $body, $hdr, $imported_c_struct) = @_;
  $imported_c_struct //= {};

  my %defined;
  while ($body =~ /^\s*(?:pub\s+)?type\s+([A-Za-z_]\w*)\s*=/gm) { $defined{$1}=1; }
  while ($body =~ /^\s*(?:pub\s+)?(?:struct|enum)\s+([A-Za-z_]\w*)\b/gm) { $defined{$1}=1; }

  my %builtin = map { $_ => 1 } qw(bool char string voidptr byte rune int i8 u8 i16 u16 i32 u32 i64 u64 f32 f64 usize isize none true false C);
  my %need;
  my $add = sub {
    my ($expr)=@_;
    return unless defined $expr;
    $expr =~ s/\[[^\]]*\]//g;
    while ($expr =~ /(?<![\w.])([A-Z][A-Za-z0-9_]*)(?![\w.])/g) {
      my $t=$1; next if $builtin{$t} || $defined{$t}; $need{$t}=1;
    }
  };
  while ($body =~ /^\s*(?:pub\s+)?type\s+[A-Za-z_]\w*\s*=\s*(.+)$/gm) { $add->($1); }
  while ($body =~ /^\s*(?:pub\s+)?fn\s+[A-Za-z_]\w*\s*\(([^)]*)\)\s*([^\n{]*)/gm) {
    my ($params,$ret)=($1,$2);
    for my $p (split_top_level_commas($params)) { $p =~ s/^\s+|\s+$//g; if ($p =~ /^(?:mut\s+)?[A-Za-z_]\w*\s+(.+)$/) { $add->($1); } }
    $add->($ret);
  }
  while ($body =~ /^\s+([A-Za-z_]\w*)\s+([^\n{}=]+)$/gm) { $add->($2); }
  $need{Va_list}=1 if $body =~ /\b(?:va_list|Va_list)\b/ && !$defined{Va_list};

  my %c_suffix_backing;
  while ($body =~ /^\s*(?:pub\s+)?type\s+([A-Za-z_]\w*)_c\s*=\s*C\.([A-Za-z_]\w*_c)\s*$/gm) { $c_suffix_backing{$1}=$2; }
  while ($body =~ /^\s*(?:pub\s+)?struct\s+C\.([A-Za-z_]\w*)_c\b/gm) { $c_suffix_backing{$1}=$1.'_c'; }

  my %need_c_struct;
  while ($body =~ /^\s*(?:pub\s+)?type\s+[A-Za-z_]\w*\s*=\s*(C\.[A-Za-z_]\w*)/gm) { $need_c_struct{$1}=1; }
  while ($body =~ /^\@\[typedef\]\s*\n\s*pub\s+struct\s+(C\.[A-Za-z_]\w*)/gm) { delete $need_c_struct{$1}; }

  my %callbacks = parse_callback_typedefs($kind, $hdr);
  my %header_types = parse_header_type_names($kind, $hdr);
  my @decls;
  for my $name (sort keys %need) {
    next if $defined{$name};
    if ($name eq 'Va_list') {
      if ($imported_c_struct->{va_list}) {
        push @decls, 'pub type Va_list = imgui.Va_list';
      } else {
        push @decls, "pub type Va_list = C.va_list\n@[typedef]\npub struct C.va_list {}";
      }
      $defined{$name}=1; delete $need_c_struct{'C.va_list'}; next;
    }
    if ($kind eq 'imgui' && $name eq 'ImWchar') { push @decls, "pub type ImWchar = u32"; $defined{$name}=1; next; }
    if (exists $c_suffix_backing{$name}) { push @decls, "pub type $name = C.$c_suffix_backing{$name}"; $defined{$name}=1; delete $need_c_struct{"C.$c_suffix_backing{$name}"}; next; }
    if (exists $callbacks{$name}) { push @decls, $callbacks{$name}; $defined{$name}=1; next; }
    if ($name =~ /Callback$/) { my $target=$name; $target =~ s/Callback$/CallbackData/; my $ret=$name eq 'InputTextCallback' ? ' i32' : ''; push @decls, "pub type $name = fn (&$target)$ret"; $defined{$name}=1; next; }
    next unless $header_types{$name};
    my $cname = $header_types{$name};
    push @decls, "pub type $name = C.$cname\n@[typedef]\npub struct C.$cname {}";
    $defined{$name}=1; delete $need_c_struct{"C.$cname"};
  }

  for my $ct (sort keys %need_c_struct) {
    next if $ct =~ /^C\.(?:int|float|double|char|bool|void)$/;
    my $cname = $ct; $cname =~ s/^C\.//;
    next if $imported_c_struct->{$cname};
    push @decls, "\@[typedef]\npub struct $ct {}";
  }
  return @decls ? join("\n\n", @decls) . "\n\n" : '';
}

sub parse_header_type_names {
  my ($kind, $hdr) = @_;
  my %types;
  for my $line (split /\n/, $hdr) {
    $line =~ s{//.*$}{};
    next if $line =~ /[{}]/;
    if ($line =~ /^\s*typedef\s+(.+?)\s+([A-Za-z_]\w*)\s*;\s*$/) {
      my ($src,$c)=($1,$2); next if $src =~ /\(\*/;
      my $ctype=$c; $ctype=$1 if $src =~ /^struct\s+([A-Za-z_]\w*)$/;
      my $v=clean_type_name($kind,$c); next if $v eq '';
      $types{$v}=$ctype if !exists($types{$v}) || $ctype =~ /_c$/;
    }
    while ($line =~ /\b(?:struct|class)\s+([A-Za-z_]\w*)\b/g) {
      my $c=$1; my $v=clean_type_name($kind,$c); next if $v eq '';
      $types{$v}=$c unless exists $types{$v};
    }
  }
  return %types;
}
sub parse_callback_typedefs {
  my ($kind, $hdr) = @_;
  my %out;
  for my $line (split /\n/, $hdr) {
    $line =~ s{//.*$}{};
    $line =~ s{/\*.*?\*/}{}g;
    next unless $line =~ /^\s*typedef\s+(.+?)\s*\(\*\s*([A-Za-z_]\w*)\s*\)\s*\((.*)\)\s*;\s*$/;
    my ($cret,$cname,$params)=($1,$2,$3);
    next if $cret =~ /[#;{}]/ || $params =~ /[#;{}]/;
    my $name = clean_type_name($kind, $cname); next if $name eq '';
    my $ret = c_type_to_v($kind, $cret);
    my @vp;
    for my $p (split_top_level_commas($params)) {
      $p =~ s/^\s+|\s+$//g; next if $p eq '' || $p eq 'void';
      $p =~ s/\[[^\]]*\]//g; $p =~ s/\s+[A-Za-z_]\w*$//;
      push @vp, c_type_to_v($kind,$p);
    }
    my $sig = 'pub type '.$name.' = fn ('.join(', ',@vp).')';
    $sig .= " $ret" if $ret ne '';
    $out{$name}=$sig;
  }
  return %out;
}
sub c_type_to_v {
  my ($kind, $ct) = @_;

  # remove inline struct definitions like ""
  $ct =~ s/struct\s+[A-Za-z_]\w*\s*\{[^}]*\}//g;

  # remove trailing duplicated type artifacts
  $ct =~ s/\b(struct\s+)?([A-Za-z_]\w*)_c\b/$2/g;

  $ct =~ s/\bconst\b//g;
  my $ptr = ($ct =~ s/\s*\*\s*/ /g);
  $ct =~ s/^\s+|\s+$//g;
  $ct =~ s/\b(\w+)\s+\1\b/$1/g;

  my %map = (
    'void' => '',
    'bool' => 'bool',
    'int' => 'i32',
    'float' => 'f32',
    'double' => 'f64',
    'char' => 'char',
    'unsigned int' => 'u32',
    'unsigned char' => 'u8',
    'size_t' => 'usize',
  );

  my $base = exists $map{$ct} ? $map{$ct} : clean_type_name($kind, $ct);
  $base = 'voidptr' if $base eq '' && $ptr;
  return ($ptr ? '&' : '') . $base;
}

sub guess_c_type_name {
  my ($kind, $name) = @_;
  return 'va_list' if $name eq 'Va_list';
  return 'STB_TexteditState' if $name eq 'ImStbTexteditState';

  my $pref = $kind eq 'imgui' ? 'ImGui' : 'ImPlot';

  if ($name =~ /^(Im(?:Vector|Span|Pool|ChunkStream|BitArray)_(.+))$/) {
    my ($whole, $tail) = ($1, $2);
    my $ctail = ($tail =~ /^Im/) ? $tail : $pref . $tail;
    $whole =~ s/_(.+)$/_$ctail/;
    return $whole;
  }

  return $name if $name =~ /^Im(?:Vec|Draw|Font|Texture|Gui|Plot)/;
  return $pref . $name;
}

sub parse_const_params {
  my ($h)=@_;
  my %m;
  while ($h =~ /^\s*(?:IMGUI_API|IMPLOT_API)\s+[^\n\(]+?\s+(\w+)\s*\(([^;{}]*)\)\s*;/gm) {
    my ($sym,$params)=($1,$2);
    for my $p (split_top_level_commas($params)) {
      next unless $p =~ /\bconst\b/;
      $p =~ s/\[[^\]]*\]//g;
      if ($p =~ /([A-Za-z_]\w*)\s*$/) { $m{$sym}{$1}=1; }
    }
  }
  return %m;
}

sub parse_fn {
  my ($l)=@_;
  return unless $l =~ /^\s*(?:pub\s+)?fn\s+([A-Za-z_]\w*)\s*\((.*)\)\s*([^\{]*)\s*$/;
  my ($n,$p,$r)=($1,$2,$3 // '');
  $r =~ s/^\s+|\s+$//g;
  return ($n,$p,$r);
}

sub emit_function {
  my ($kind, $csym, $vname, $params, $ret, $const_params) = @_;
  $ret //= '';
  $ret = clean_type_expr($kind, $ret);
  $ret =~ s/^\s+|\s+$//g;
  $vname = clean_function_name($kind, $vname);

  my @vparts;
  my @cparts;
  my @args;
  for my $p (split_top_level_commas($params)) {
    $p =~ s/^\s+|\s+$//g;
    next if $p eq '' || $p eq '...';
    next if $p =~ /^vargs\s+/;
    if ($p =~ /^(mut\s+)?([A-Za-z_]\w*)\s+(.+)$/) {
      my ($mut,$name,$typ)=($1 // '', $2, clean_type_expr($kind,$3));
      $typ =~ s/&\s*i8\b/&char/g;
      my $is_const = (exists $const_params->{$csym} && exists $const_params->{$csym}{$name}) || ($typ =~ /^&char$/ && $name =~ /^(fmt|text|text_end|label|str|str_id|overlay|shortcut|name|begin|end|fmt_begin|fmt_end)$/);
      $name = 'const_' . $name if $is_const && $name !~ /^const_/;
      push @vparts, ($mut ? 'mut ' : '') . "$name $typ";
      if ($mut) { push @cparts, "mut_$name $typ"; push @args, "mut_$name"; }
      else { push @cparts, "$name $typ"; push @args, $name; }
    }
  }

  my $vp = join(', ', @vparts);
  my $cp = join(', ', @cparts);
  my $call = 'C.' . $csym . '(' . join(', ', @args) . ')';
  my $s = "\n@[keep_args_alive]\nfn C.$csym($cp)";
  $s .= " $ret" if $ret ne '';
  $s .= "\n\n@[inline]\npub fn $vname($vp)";
  $s .= " $ret" if $ret ne '';
  $s .= " {\n";
  $s .= $ret eq '' ? "\t$call\n" : "\treturn $call\n";
  $s .= "}";
  return $s;
}

sub clean_function_name {
  my ($kind, $name)=@_;
  if ($kind eq 'imgui') {
    $name =~ s/^ig_//;
    $name =~ s/^im_gui_//;
    $name =~ s/im_gui_//g;
  } else {
    $name =~ s/^im_plot_//;
    $name =~ s/im_plot_//g;
    $name =~ s/^implot_//;
  }
  return $name;
}

sub infer_c_symbol {
  my ($kind, $vname)=@_;
  if ($kind eq 'imgui') {
    return special_vec_csym($vname) if $vname =~ /^im_vec[24]_/;
    return 'ig' . snake_to_camel($vname);
  }
  return 'ImPlot' . snake_to_camel($vname);
}

sub special_vec_csym {
  my ($v)=@_;
  my @p = split /_/, $v;
  return snake_to_camel(join('_', @p));
}

sub emit_struct {
  my ($kind, $orig_name, $clean_name, $body_lines)=@_;
  $orig_name =~ s/^C\.//;
  return '' if $clean_name eq '' || $clean_name =~ /\./;
  my @fields;
  for my $l (@$body_lines) {
    next if $l =~ /^\s*$/ || $l =~ /^\s*pub\s*mut\s*:/;
    $l = clean_line($kind, $l);
    next if $l =~ /^\s*$/;
    if ($l =~ /^\s*([A-Za-z_]\w*)\s+(.+?)\s*$/) {
      my ($field,$typ)=($1,clean_type_expr($kind,$2));
      $field = ucfirst($field) unless $orig_name =~ /^(ImVec2|ImVec4|ImVec2_c|ImVec4_c|ImDrawVert)$/;
      push @fields, "\t$field $typ";
    }
  }
  my $s = "\n\npub type $clean_name = C.$orig_name\n@[typedef]\npub struct C.$orig_name {";
  if (@fields) { $s .= "\npub mut:\n" . join("\n", @fields) . "\n}"; }
  else { $s .= "}"; }
  return $s;
}

sub emit_enum {
  my ($kind,$ename,$orig_enum,$body_lines)=@_;
  my $prefix = enum_member_prefix($kind,$orig_enum);
  my @members;
  my %seen_value;
  my %known_value;
  my $next_auto = 0;

  for my $l (@$body_lines) {
    next if $l =~ /^\s*$/ || $l =~ /^\s*\/\//;
    next unless $l =~ /^\s*([A-Za-z_]\w*)\s*(?:=\s*(.+?))?\s*$/;
    my ($name,$expr)=($1,$2);
    $name = clean_enum_member_name($kind,$name,$prefix);
    $name = '_' . $name if $name =~ /^\d/;
    next if $name eq '';

    my ($value, $line);
    if (defined $expr && $expr ne '') {
      $expr = clean_enum_expr($kind,$expr,$ename);
      $value = eval_enum_value($expr, \%known_value);
      if (defined $value) { $next_auto = $value + 1; }
    } else {
      $value = $next_auto++;
    }

    # V does not allow two enum members with the same integer value. C/C++
    # headers often define aliases, so comment out later aliases generically
    # after evaluating safe integer expressions, instead of hardcoding names.
    my $is_duplicate = defined($value) && exists($seen_value{$value});

    if (defined $expr && $expr ne '') {
      if ($is_duplicate) {
        $line = " //$name = $expr";
      } else {
        $line = sprintf(" %-34s = %s", $name, $expr);
      }
    } else {
      if ($is_duplicate) {
        $line = " //$name";
      } else {
        $line = " $name";
      }
    }

    if (defined $value) {
      $known_value{$name} = $value;
      $seen_value{$value} = 1 unless $is_duplicate;
    }
    push @members, $line;
  }
  return "\npub enum $ename {\n" . join("\n", @members) . "\n}";
}

sub eval_enum_value {
  my ($expr, $known) = @_;
  return undef unless defined $expr;
  my $e = $expr;
  $e =~ s{//.*$}{};
  $e =~ s{/\*.*?\*/}{}g;
  $e =~ s/\bC\.int\(([^()]+)\)/($1)/g;
  $e =~ s/\b(?:u32|i32|int)\(([^()]+)\)/($1)/g;
  $e =~ s/\b0x([0-9A-Fa-f]+)\b/hex($1)/ge;
  $e =~ s/\b([A-Za-z_]\w*)\b/exists($known->{$1}) ? $known->{$1} : $1/ge;
  return undef if $e =~ /[A-Za-z_]/;
  return undef if $e =~ /[^0-9+\-*\/|&~^<>() \t]/;
  return undef if $e =~ /<<</ || $e =~ />>>/;
  my $v = eval "no warnings; use integer; $e";
  return undef if $@;
  return undef unless defined $v && $v =~ /^-?\d+$/;
  return int($v);
}

sub clean_enum_name {
  my ($kind,$name)=@_;
  my $had_us = ($name =~ /_$/) ? '_' : '';
  $name =~ s/_$//;
  $name = clean_type_name($kind,$name);
  return $name . $had_us;
}

sub enum_member_prefix {
  my ($kind,$orig_enum)=@_;
  my $n = $orig_enum;
  $n =~ s/_$//;
  return camel_to_snake($n) . '_';
}

sub clean_enum_member_name {
  my ($kind,$name,$prefix)=@_;
  my $lower = $CFG{$kind}{lower};
  $name =~ s/^\Q$lower\E//;
  $name =~ s/^\Q$prefix\E//;
  my $p2 = $prefix;
  $p2 =~ s/^\Q$lower\E//;
  $name =~ s/^\Q$p2\E//;
  my $p3 = $p2;
  $p3 =~ s/private_$//;
  $name =~ s/^\Q$p3\E// if $p3 ne $p2;
  $name =~ s/^im_gui_// if $kind eq 'imgui';
  $name =~ s/^im_plot_// if $kind eq 'implot';
  $name =~ s/^key_// if $p2 =~ /key_$/ && $name =~ /^key_/;
  return $name;
}

sub clean_enum_expr {
  my ($kind,$expr,$ename)=@_;
  $expr =~ s/\s+$//;
  $expr = clean_line($kind,$expr);
  if ($expr =~ /^\d+$/ && $ename =~ /Flags/) { return numeric_to_bits($expr); }
  return $expr;
}

sub numeric_to_bits {
  my ($n)=@_;
  return $n unless defined $n && $n =~ /^\d+$/;
  return '0' if $n == 0;
  my @b;
  my $i=0;
  my $x=$n;
  while ($x > 0) { push @b, "1 << $i" if ($x & 1); $x >>= 1; $i++; }
  return join(' | ', @b);
}

sub clean_line {
  my ($kind,$line)=@_;
  $line =~ s/\bmain\.//g;
  $line =~ s/\bMain\.//g;
  $line =~ s/\bC\.int\(([^)]+)\)/$1/g;
  $line = clean_type_expr($kind,$line);
  return $line;
}

sub clean_type_name {
  my ($kind,$name)=@_;
  return '' unless defined $name;
  $name =~ s/^C\.//;
  $name =~ s/^Main\.//;
  if ($kind eq 'imgui') { $name =~ s/ImGui//g; }
  else { $name =~ s/ImPlot//g; }
  return $name;
}

sub clean_type_expr {
  my ($kind,$s)=@_;
  return '' unless defined $s;
  $s =~ s/\bmain\.//g;
  $s =~ s/\bMain\.//g;
  $s =~ s/\bC\.int\(([^)]+)\)/$1/g;
  $s =~ s/\bi8\b/char/g if $s =~ /\&\s*i8\b/;
  if ($kind eq 'imgui') {
    $s =~ s/\bimgui\.//g;
    $s =~ s/\bImGui(?=[A-Z])//g;
    $s =~ s/ImGui//g if $s =~ /ImVector_|ImSpan_|ImPool_|ImChunkStream_|ImBitArray_/;
  } else {
    $s =~ s/\bimplot\.//g;
    $s =~ s/\bImPlot(?=[A-Z])//g;
    $s =~ s/ImPlot//g if $s =~ /ImVector_|ImSpan_|ImPool_|ImChunkStream_|ImBitArray_/;
    $s =~ s/\bImGui([A-Z]\w*)/imgui.$1/g;
    # cimplot.h includes cimgui.h, so c2v emits both APIs.  ImGui scalar
    # aliases must be reduced to their primitive type, and the remaining
    # shared C declarations must retain their C identity instead of being
    # redeclared in the implot module.
    $s =~ s/\bImU8\b/u8/g;
    $s =~ s/\bImU16\b/u16/g;
    $s =~ s/\bImU32\b/u32/g;
    $s =~ s/\bImU64\b/u64/g;
    $s =~ s/\bImS8\b/i8/g;
    $s =~ s/\bImS16\b/i16/g;
    $s =~ s/\bImS32\b/i32/g;
    $s =~ s/\bImS64\b/i64/g;
    $s =~ s/\bImWchar16\b/u16/g;
    $s =~ s/\bImWchar(?:32)?\b/u32/g;
    $s =~ s/\bSTB_TexteditState\b/C.STB_TexteditState/g;
    $s =~ s/\bStbrp_node\b/C.stbrp_node/g;
    $s =~ s/\bTm\b/C.tm/g;
    $s =~ s/\b(ImVec[24]|ImDraw\w*|ImFont\w*|ImTextureID|ID|Context)\b/imgui.$1/g;
    $s =~ s/\bimgui\.imgui\./imgui./g;
  }
  return $s;
}

sub normalize_alias_rhs {
  my ($kind,$name,$rhs)=@_;
  $rhs =~ s/^int$/i32/;
  $rhs = 'C.' . $rhs if $rhs =~ /^ImBitArray_/;
  if ($kind eq 'imgui') {
    $rhs = '&u32' if $name eq 'ImBitArrayPtr';
    $rhs = 'C.STB_TexteditState' if $name eq 'ImStbTexteditState';
    $rhs = 'C.ImBitArray_ImGuiKey_NamedKey_COUNT__lessImGuiKey_NamedKey_BEGIN' if $name eq 'ImBitArrayForNamedKeys';
    $rhs = 'u32' if $name eq 'ImWchar';
    # c2v sometimes title-cases the C typedef target but the real C name is
    # lower-case stb_rect_pack.h: typedef struct stbrp_node stbrp_node;
    # Example broken V: pub type Stbrp_node_im = Stbrp_node
    $rhs = 'C.stbrp_node' if $rhs eq 'Stbrp_node';
  }
  return $rhs;
}

sub postprocess {
  my ($kind,$s)=@_;
  $s =~ s/\bint\b(?!\()/i32/g;
  $s =~ s/(?<!C\.)\bva_list\b/Va_list/g;
  # c2v marks C static constants with their C identifier as an export.  That
  # makes V emit a second C definition alongside the header's static const.
  # Keep them as public V constants instead; their V name is sufficient.
  $s =~ s/^\@\[export:\s*'[^']+'\]\s*\n\s*const\s+/pub const /gm;
  # V constants must use lowercase snake_case. c2v can retain all-caps
  # ImGui/ImPlot macro names as V const declarations.
  $s =~ s/^(\s*(?:pub\s+)?const\s+)([A-Z][A-Z0-9_]*)\b/$1 . lc($2)/gme;
  $s =~ s/^(\s*__global\s+GImGui\b.*)$/\/\/$1/gm;
  if ($kind eq 'imgui') {
    $s =~ s/(pub type ImStbTexteditState = C\.STB_TexteditState\n)(?!\@\[typedef\])/$1\@\[typedef\]
pub struct C.STB_TexteditState {}

/;
  }
  $s =~ s/\b&char\b/&char/g;
  $s =~ s/^\s*\@\[translated\]\s*\n//mg;
  $s =~ s/\\\@\[/@[/g;
  $s =~ s#/\@\[#@[#g;
  $s =~ s/\bmain\.//g;
  $s =~ s/\bMain\.//g;
  $s =~ s/^\s*\/\/ This file is automatically generated by.*\n//mg;
  $s =~ s/^\s*#.*\n//mg;
  $s =~ s/^\s*typedef\b[^\n]*\n//mg;
  $s =~ s/^\s*struct\s+[A-Za-z_]\w*\s*;\s*\n//mg;
  $s =~ s/^\s*[A-Za-z_]\w*\s*;\s*\n//mg;

  # Duplicate enum aliases are handled while emitting each enum by evaluating
  # safe integer expressions. Keep this post-pass free of enum member names.
  return $s;
}

sub camel_to_snake {
  my ($s)=@_;
  $s =~ s/([a-z0-9])([A-Z])/$1_$2/g;
  $s =~ s/([A-Z]+)([A-Z][a-z])/$1_$2/g;
  return lc $s;
}

sub snake_to_camel {
  my ($s)=@_;
  return join('', map { ucfirst($_) } split /_/, $s);
}

sub split_top_level_commas {
  my ($s)=@_;
  return () unless defined $s;
  my @parts;
  my $cur='';
  my $depth=0;
  for my $ch (split //,$s) {
    if ($ch eq '(' || $ch eq '[') { $depth++; $cur.=$ch; next; }
    if ($ch eq ')' || $ch eq ']') { $depth-- if $depth>0; $cur.=$ch; next; }
    if ($ch eq ',' && $depth==0) { push @parts,$cur; $cur=''; next; }
    $cur.=$ch;
  }
  push @parts,$cur if $cur ne '' || $s eq '';
  return @parts;
}

sub header_alias_decls {
  my ($kind, $body, $hdr) = @_;
  my %defined;
  while ($body =~ /^\s*(?:pub\s+)?type\s+([A-Za-z_]\w*)\s*=/gm) { $defined{$1}=1; }
  my %body_c_struct;
  while ($body =~ /^\s*pub\s+struct\s+C\.([A-Za-z_]\w*)\b/gm) { $body_c_struct{$1}=1; }
  my @decls;
  while ($hdr =~ /^\s*typedef\s+struct\s+([A-Za-z_]\w*)\s+([A-Za-z_]\w*)\s*;/gm) {
    my ($backing, $public) = ($1, $2);
    next if $backing eq $public || !$body_c_struct{$backing};
    my $alias = clean_type_name($kind, $public);
    next if $alias eq '' || $defined{$alias};
    push @decls, "pub type $alias = C.$backing";
    $defined{$alias}=1;
  }
  return @decls ? join("\n", @decls) . "\n\n" : '';
}

sub bridge_c_suffix_aliases {
  my ($s)=@_;
  my %defined;
  while ($s =~ /^\s*pub\s+type\s+([A-Za-z_]\w*)\s*=/gm) { $defined{$1}=1; }
  my @decls;
  while ($s =~ /^\s*pub\s+type\s+([A-Za-z_]\w+)_c\s*=\s*C\.([A-Za-z_]\w+_c)\s*$/gm) {
    my ($base,$cname)=($1,$2); next if $defined{$base}; next unless $s =~ /\b\Q$base\E\b/;
    push @decls, "pub type $base = C.$cname"; $defined{$base}=1;
  }
  if (@decls) { my $insert=join("\n",@decls)."\n\n"; $s =~ s/(pub const version_num[^\n]*\n\n)/$1$insert/s; }
  return $s;
}

sub final_sanitize {
  my ($kind,$s)=@_;
  $s =~ s/^\s*#.*\n//mg;
  $s =~ s/^\s*typedef\b[^\n]*\n//mg;
  $s =~ s/^\s*struct\s+[A-Za-z_]\w*\s*;\s*\n//mg;
  $s =~ s/^\s*[A-Za-z_]\w*\s*;\s*\n//mg;
  $s =~ s/\bunsigned\s+__int64\s+ImU64\b/u64/g;
  $s =~ s/\bunsigned\s+long\s+long\s+ImU64\b/u64/g;
  $s =~ s/\bunsigned\s+long\s+ImU64\b/u64/g;

  for my $base (qw(ImVec2 ImVec2i ImVec4 ImColor ImRect)) {
    if ($s =~ /\b(?:pub\s+type\s+${base}_c\s*=\s*C\.${base}_c|pub\s+struct\s+C\.${base}_c\b)/) {
      $s =~ s/pub\s+type\s+$base\s*=\s*C\.[A-Za-z_]\w*/pub type $base = C.${base}_c/;
    }
  }

  my %seen; my @out;
  for my $line (split /\n/, $s) {
    if ($line =~ /^\s*pub\s+type\s+([A-Za-z_]\w*)\s*=/) { next if $seen{$1}++; }
    push @out,$line;
  }
  $s=join("\n",@out)."\n";
  $s =~ s/(pub struct C\.ImVec2_c \{\n\s*pub mut:\n)\s*[Xx] f32\n\s*[Yy] f32/$1\tx f32\n\ty f32/s;
  $s =~ s/(pub struct C\.ImVec2i_c \{\n\s*pub mut:\n)\s*[Xx] i32\n\s*[Yy] i32/$1\tx i32\n\ty i32/s;
  $s =~ s/(pub struct C\.ImVec4_c \{\n\s*pub mut:\n)\s*[Xx] f32\n\s*[Yy] f32\n\s*[Zz] f32\n\s*[Ww] f32/$1\tx f32\n\ty f32\n\tz f32\n\tw f32/s;
  $s =~ s/\bimgui\.([A-Z][A-Za-z0-9_]*)\b/$1/g if $kind eq 'imgui';
  $s =~ s/\bimplot\.([A-Z][A-Za-z0-9_]*)\b/$1/g if $kind eq 'implot';
  $s =~ s/\n{4,}/\n\n\n/g;
  return $s;
}
