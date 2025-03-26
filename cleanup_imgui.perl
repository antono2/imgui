#!/usr/bin/perl
use strict;
use warnings;

my $file_in  = 'src/imgui.v';
my $file_out = 'src/imgui.v';

# Only available after generate_imgui_v.sh ran at least once
my $dcimgui_header_file                         = 'include/dcimgui.h';
my $max_enum_member_alias_to_base_value_runs    = 10;
my $enum_member_alias_to_base_value_run_counter = 0;
my $got_struct_scope_content                    = 0;
my %struct_scope_content;
my $got_enum_scope_content = 0;
my %enum_scope_content;
my @needs_c_prefix_array;
my $got_needs_c_prefix_array      = 0;
my $get_enum_base_value_first_run = 1;
my %enum_member_name_value;
my @basetypes = (
  "bool",    "u8",    "i8",  "u16", "i16", "u32",
  "i32",     "u64",   "i64", "int", "f32", "f64",
  "voidptr", "usize", "isize"
);

open my $in_header, '<', $dcimgui_header_file
  or die "Can not read ${dcimgui_header_file}: $!";
my $dcimgui_header = do { local $/; <$in_header> };    # slurp!
close($in_header);

open my $in, '<', $file_in or die "Can not read ${file_in}: $!";
my $content = do { local $/; <$in> };                  # slurp!
close($in);

#### Last comment causes issues
#### Example
# // Obsoleted in 1.90.0: Use ImGuiChildFlags_AlwaysUseWindowPadding in BeginChild() call.
# // #ifndef IMGUI_DISABLE_OBSOLETE_FUNCTIONS
# }
#### Or could be just const on root level: const ( = 3 ) with no name

#### Empty name without corresponding member in dcimgui.h
#### Example
# // Descending = 9->0, Z->A etc.
#	 = 3
#### gets removed
####

#### Trim tailing _t in struct names
#### Example
# ImFontAtlas_t {
# ->
# struct ImFontAtlas {
####

#### Rename enum member names, where it matches the enum name
#### Example
# enum ImGuiHoveredFlags_ {
#   hovered_flags_none = 0
#   hovered_flags_child_windows = 1 << 0
# ->
# enum ImGuiHoveredFlags_ {
#   none = 0
#   child_windows = 1 << 0
####

#### Remove everything in { } scope after "// Obsolete names"
#### Example
# enum x {
#   non_obsolete_member
#   // Obsolete names
#   // some commented code { };
#   obsolete_member
# }
# ->
# enum x {
#   non_obsolete_member
# }
####
basic_cleanup();

#### Append static strings, like version
#### Example
# module main
# ->
# module imgui
# #flag -I @VMODROOT/include
# #include <dcimgui.h>
# pub const version = '1.91.9 WIP'
# pub const version_num = 19187
# pub type C.ImGuiContext = voidptr
# pub type C.ImDrawListSharedData = voidptr
# ...
####
append_static_strings();

#### Find and replace with C.name, where a type in struct/function is unknown locally
#### Example
# ImGuiContext is not in struct names array but used in function
# fn destroy_context(ctx &ImGuiContext)
# ->
# pub type C.ImGuiContext = voidptr
# fn destroy_context(ctx &C.ImGuiContext)
####
find_unknowns_and_set_c_prefix();

#### Alias to base for enum member values
#### Example
# no_auto_open_on_log = 1 << 4
# collapsing_header = 1 << 1 | 1 << 3 | no_auto_open_on_log
# ->
# collapsing_header = 1 << 1 | 1 << 3 | 1 << 4
####
enum_member_alias_to_base_value();

#### Alias to base for top level types
#### Example
# // 8-bit unsigned integer
# type ImU8 = u8
# type ImGuiSortDirection = ImU8
# ->
# type ImGuiSortDirection = u8
####
type_alias_to_base_value();

####
#### Write out result to file
####
open my $out, '>', $file_out or die "Can not write ${file_out}: $!";
print $out $content;
close($out);

####
#### Subs
####
sub refresh_struct_scope_content() {
  %struct_scope_content = ();
  %struct_scope_content = $content =~ /(?:[^\/]struct\s(\w+)\s\{([^\}]+))/gs;
  $got_struct_scope_content = 1;
}

sub refresh_enum_scope_content() {
  %enum_scope_content     = ();
  %enum_scope_content     = $content =~ /(?:[^\/]enum\s(\w+)\s\{([^\}]*\n))/gs;
  $got_enum_scope_content = 1;
}

sub refresh_needs_c_prefix_array {
  @needs_c_prefix_array = ();

  # Find function parameter types
  # Using a map to deduplicate
  my %func_param_types;
  my %struct_member_types;

  my $typedef_regex = qr/type\s(\w+)\s=\s(.*)\n/;

  #print join ", ", @typedef_names;
  my %typedef_map;
  if ( not $got_struct_scope_content ) { refresh_struct_scope_content(); }
  my @struct_names = keys %struct_scope_content;
  if ( not $got_enum_scope_content ) { refresh_enum_scope_content(); }

  # All function parameter types and return types.
  my @func_param_content = $content =~ /(?:[^\/]fn\s\w+\()(.*)/g;

  # Also get the callback function defintions
  push @func_param_content, $content =~ /(?:[^\/]fn\s\().*/g;

  #print "\n func_param_content\n";
  #use Data::Dumper;
  #print Dumper( \@func_param_content );
  foreach my $func_params (@func_param_content) {
    if ( $func_params =~ /\)\s(?:&?)*(\w+)/gm ) {

      # Found function return type
      @func_param_types{$1} = 1;

      #print "Start: $func_params\n";
    }

    # Remove end, starting from last )
    $func_params =~ s/\)[^\)]*$//;

    if ( $func_params eq "()" ) { next; }

    foreach my $possibly_fn ($func_params) {
      if ( $possibly_fn =~ /\sfn\s/ ) {

        #print "Param Pre $possibly_fn\n";

# Get fn ( (params) ) (\w+), so it can be appended to @func_param_content and processed again
        $possibly_fn =~ /
        (?:                      # Start non capture group
        (?:fn\s)                 # Has "fn "
        \(                       # Literal (
        (.*)                     # Capture group 1, anything except new line
        (?:\))                   # Literal )
        \s([^,]*)|(?:fn\s\()     # Capture group 2
                                 # Not ", " or positive "fn (", to capture function types 
        (.*)                     # Capture group 3, anything inside function parameters
        )                        # End non capture group
        /x;
        my $inline_fn_params = $3 ? $3 : "$1, $2";
        if ( $inline_fn_params eq "" ) { next; }

        #print "Param Post $inline_fn_params\n";
        use List::Util 1.33 'any';
        if ( not any { /\Q$inline_fn_params\E/ } @func_param_content ) {
          push @func_param_content, $inline_fn_params;

          #print "Pushed $inline_fn_params to func_param_content.\n";
        }
      }
    }
    my @params = split( ",", $func_params );
    foreach my $param (@params) {
      $param =~ s/^\s+|\s+$//g;

      #print "$param processing single func param\n";
      foreach ( $param =~ /(?:\w+\s(?:&?)*)(\w+)/gc ) {
        if ( $1 eq "fn" ) {
          next;
        }
        @func_param_types{$1} = 1;
      }
      pos($param) = 0;    # reset the search location, because /c is used
    }
  }

  #print "FUNC_PARAM_TYPES:\n";
  #print join( ", ", ( keys %func_param_types ) );
  foreach my $struct_content ( values %struct_scope_content ) {
    my @lines = split( "\n", $struct_content );
    foreach my $line (@lines) {
      if ( $line =~ /\/\// ) { next; }

      # Trim whitespace
      #print "$line\|pre trim single struct member\n";
      $line =~ s/^\s+|\s+$//g;
      if ( $line eq "" ) { next; }

    # Ignore fn ( .. struct member types. These are found in @func_param_content
    #print "$line\|processing single struct member\n";
      $line =~ /
      (?:                # Start non capture group
      \w+\s              # Whatever struct member name
      (?!fn\s\()         # Not "fn", because we deal with function types in structs later
      (?:[&\[\]\d]?)*    # Whatever prefix the struct member type might have,
                         # we don't want to capture it 
      (\w+)              # Capture group 1 for the member type
      )                  # End non capture group and add result to map of struct member types
                         # to just 1, to deduplicate
      (?{ @struct_member_types{$1} = 1 })
      /x;
    }
  }

  while ( $content =~ /$typedef_regex/g ) {
    my $cur_name = $1;
    if ( defined $typedef_map{$cur_name} ) {
      next;
    }
    $typedef_map{$cur_name} = $2;
  }

  #use Data::Dumper;
  #print Dumper(\%typedef_map);

  # Find types needed as parameter in some function defintion
  # or in a struct, where no local definition was found
  foreach my $param_type ( keys %func_param_types ) {
    if (  not( "@basetypes" =~ /\b\Q$param_type\E\b/ )
      and not( "@struct_names" =~ /\b\Q$param_type\E\b/ )
      and not( exists $enum_scope_content{$param_type} )
      and not( exists $typedef_map{$param_type} ) )
    {
      # print $param_type . "\n";
      push @needs_c_prefix_array, $param_type;
    }
  }
  foreach my $param_type ( keys %struct_member_types ) {
    if (  not( "@basetypes" =~ /\b\Q$param_type\E\b/ )
      and not( "@struct_names" =~ /\b\Q$param_type\E\b/ )
      and not( exists $enum_scope_content{$param_type} )
      and not( exists $typedef_map{$param_type} ) )
    {
      #print $param_type . "\n";
      push @needs_c_prefix_array, $param_type;
    }
  }

  # Deduplicate
  my %h = map { $_, 1 } @needs_c_prefix_array;
  @needs_c_prefix_array = keys %h;

  $got_needs_c_prefix_array = 1;
}    # sub refresh_needs_c_prefix_array

sub basic_cleanup {

  # Clean up last comment
  $content =~ s/  # Replace
  (               # Start capture group 1
  \/\/[^\n]*      # Starts with a comment in same line
  \s?\n           # Optional space, mandatory new line
  (?!\s\w+)       # Not a word
  \s?\n?          # Optional space and new line
  )               # End capture group 1
  (?>\})          # Positive look ahead
                  # to make sure the } scope is closed
  /\}/gx;

  # Same as above for ")"
  $content =~ s/(\/\/[^\n]*\s?\n(?!\s\w+)\s?\n?)(?>\))/\)/g;

  # Clean up empty name
  $content =~ s/\n\s+\=\s[0-9]//g;
  
  # Remove everything in { } scope after "// Obsolete names"
  ## First the ones with some commented code and "}"
  $content =~ s/(\/\/\sObsolete\snames\n(?:\/\/[^\n]*\n)*\})/\n\}/gs;
  ## Then the ones without
  $content =~ s/\/\/\sObsolete\snames\n[^\}]*//gs;
    
  # Remove im_gui_ from members
  $content =~ s/(\sim_gui_)(?=\w+)/ /g;

  if ( not $got_needs_c_prefix_array ) { refresh_needs_c_prefix_array(); }

  # Remove ImGui from enum names
  my $not_in = join "|", @needs_c_prefix_array;

  #print "####NOT_IN:\n$not_in\n";
  $content =~ s/[^'\/](?!$not_in)(\bImGui_?)(?=\w+)/ /g;

  # Remove tailing _t from struct names
  $content =~ s/(struct\s\w+)(_t)(\s\{)/$1$3/g;

  # Remove enum name from members
  refresh_enum_scope_content();
  while ( my ( $enum_name, $scope_content ) = each %enum_scope_content ) {

    #print "Pre snake case $enum_name\n";
    my @upper_words     = $enum_name =~ /([A-Z][a-z0-9]*)/g;
    my $enum_name_snake = join( "_", map { lc } @upper_words );

    #print "Post snake case $enum_name\n";
    my $scope_content_clean = $scope_content;
    $scope_content_clean =~ s/\Q$enum_name_snake\E[_]?//g;

#print "Removed enum $enum_name as $enum_name_snake from members: $scope_content_clean\n";

    $content =~ s/\Q$scope_content\E/$scope_content_clean/g;
  }
  refresh_enum_scope_content();
  refresh_struct_scope_content();
  refresh_needs_c_prefix_array();
}    # sub

sub append_static_strings {
  $dcimgui_header =~ qr/^#define\sIMGUI_VERSION\s+"([[:print:]]+)"$/m;
  my $version_str = $1;
  $dcimgui_header =~ qr/^#define\sIMGUI_VERSION_NUM\s+([[:print:]]+)$/m;
  my $version_num = $1;

  my $version_v = "";
  if ( length $version_str ) {
    $version_v = "pub const version = '" . $version_str . "'\n";
    if ( length $version_num and $version_num ne $version_str ) {
      $version_v =
        $version_v . "pub const version_num = " . $version_num . "\n";
    }
  }
  my $static_string =
      "\nmodule imgui\n"
    . "\n#flag -I \@VMODROOT/include\n#include <dcimgui.h>\n#include \"backends/dcimgui_impl_glfw.h\"\n#include \"backends/dcimgui_impl_vulkan.h\"\n"
    . $version_v;

  if ( not $got_needs_c_prefix_array ) { refresh_needs_c_prefix_array(); }
  foreach my $type_need_c_prefix (@needs_c_prefix_array) {
    $static_string .= "pub type C.$type_need_c_prefix = voidptr\n";
  }

  $content =~ s/\nmodule main\n/$static_string/;

  # Remove deprecated enum members, which don't need a basetype translation
  my $to_remove = q( tab_active = tab_selected
// [renamed in 1.90.9]
 tab_unfocused = tab_dimmed
// [renamed in 1.90.9]
 tab_unfocused_active = tab_dimmed_selected
// [renamed in 1.90.9]
 nav_highlight = nav_cursor
// [renamed in 1.91.4]);
  $content =~ s/\Q$to_remove\E//;

  refresh_enum_scope_content();
  refresh_needs_c_prefix_array();
}    # sub

# Prepend all occurences of unknown types with C.
# This also keeps all prefixes & and [\d] automatically
sub find_unknowns_and_set_c_prefix {
  if ( not $got_needs_c_prefix_array ) { refresh_needs_c_prefix_array(); }
  my $needs_c_prefix_search = join( "|", @needs_c_prefix_array );

# Unmatched ( in regex; marked by <-- HERE in m/(?<!(&?)C\.)\b&?( <-- HERE ...
# Should be an issue with needs_c_prefix_search. Something went wrong at collecting types in func_param_types or struct_member_types
  $content =~ s/(?<!C\.)\b($needs_c_prefix_search)\b/C\.$1/g;    # [\[\]\d&]*
      #print join ",", $needs_c_prefix_search;
}    # sub

sub get_enum_base_value {
  my $enum_name   = $_[0];
  my $member_name = $_[1];
  if ($get_enum_base_value_first_run) {
    $get_enum_base_value_first_run = 0;
    %enum_member_name_value        = ();

    # Map each enum name (key) to each of its members [name, value]
    # Scan each member for its value, but only when they are not an alias
    if ( not $got_enum_scope_content ) { refresh_enum_scope_content(); }
    foreach my $cur_enum_name ( keys %enum_scope_content ) {

     # Append each name&value to enum_member_name_value, where it's a base value
      my @lines = split( '\n', $enum_scope_content{$cur_enum_name} );
      foreach my $line (@lines) {
        $line =~ /
        [^\/]                  # Not a comment
        ([a-z0-9_]+)           # Capture a1b2_c3, member name in group 1
        \s=\s                  # = 
        ([0-9\s<\|\-xABCDEF]+) # Capture the full value " 123 << 456 | 0x1A2B3 | 789" in group 2
                               # Note that w, "abc_", alias is not captured here
                               # Then add to map of enum_name to [member_name, base_value]
        (?{ push @{$enum_member_name_value{$cur_enum_name}}, ($1, $2); })
        /gcx;
      }
    }

    #print "\nenum_member_name_value\n";
    #use Data::Dumper;
    #print Dumper( \%enum_member_name_value );
  }

  if ( exists $enum_member_name_value{$enum_name}
    and defined $enum_member_name_value{$enum_name} )
  {
    # Make sure to keep @{} around to dereference to array
    my @names_values_arr = @{ $enum_member_name_value{$enum_name} };
    my $cur_name;

    for my $i ( 0 .. $#names_values_arr ) {
      if ( $i % 2 == 0 ) {
        $cur_name = $names_values_arr[$i];
        next;
      }

      #print "### Checking for $cur_name in @names_values_arr" ;
      if ( $cur_name eq $member_name ) {

        #print "exists: name: "
        #  . $enum_name
        #  . " member: "
        #  . $member_name
        #  . " ret: "
        #  . $names_values_arr[$i] . "\n";
        return $names_values_arr[$i];
      }
    }
  }
  else {
    print
"$enum_name not found in enum_scope_content map. Reset get_enum_base_value_first_run to 1 after each iteration, to fetch the translated base values.\n";
  }
  print "RETURNING EMPTY base_value for enum: "
    . $enum_name
    . " member: "
    . $member_name
    . "\nThis is OK.\n";

  return "";
}    # sub

sub enum_member_alias_to_base_value {
  for my $enum_name ( keys %enum_scope_content ) {
    my $enum_content = $enum_scope_content{$enum_name};
    my @lines        = split( "\n", $enum_content );
    foreach my $line (@lines) {
      if ( $line =~ /\/\// ) { next; }

      # Has to be a while
      while (
        $line =~ /
      (?:[\s\|0-9<]+)    # Non capture group of " 123 << 456 | "
      (?:=\s|\|\s|\-\s)  # Non capture group of " " or "| " or "- "
                         # - because some values maybe -1, which are still base values
      ([^0-9][a-z0-9_]+) # Capture group of "a1b2_c3", alias not starting with a number
      /gx
        )
      {
        my $alias = $1;

        # print "\n##ALIAS: $alias\n";
        if (
          not( my $base_value = get_enum_base_value( $enum_name, $alias ) ) eq
          "" )
        {
          $base_value =~ s/(^\s+|\s+$)//g;    # Trim white space at start/end
          $alias      =~ s/(^\s+|\s+$)//g;

          #print "\n#### Found base val: $base_value\nFor enum member $alias\n";
          #print "PRE: $line\n";
          my $orig = $line;
          $line =~ s/\b\Q$alias\E\b/$base_value/;

          #print "POST: $line\n";
          $enum_content =~ s/\Q$orig\E/$line/;
        }
      }
    }    # foreach
         # Apply change
         #print "ApplyEnum:\n$enum_name\nContent:\n$enum_content\n";
    $content =~ s/\Q$enum_scope_content{$enum_name}\E/$enum_content/;

    #use Data::Dumper;
    #my @k = keys %enum_scope_content;
    #print Dumper(\@k);

  }    # for

  # If there are enum members with alias values, run again
  $enum_member_alias_to_base_value_run_counter += 1;
  my $got_work_to_do = 0;
  for my $e_name ( keys %enum_scope_content ) {
    if (
      $enum_scope_content{$e_name} =~ /
      (                 # Capture start, to print the thing later
      ^                 # From line start
      [^\/]             # If it's not a commented line
      [a-z_0-9]+        # Something like a1b2c3_d4e5f6 to make sure it's a member name
      \s=\s             #  =
      (?=[\s\d<\|\-]+)? # Optional base values and separators " 123 << 456 | 789 "
      [a-z_]+           # Alias member value, like abc_def.
                        # Not the same as a1b2c3_d4e5f6, because I don't distinguish between
                        # d and wd 
      )                 # Capture end
      /mx
      )
    {
      print "Got work to do in $e_name: $1\n";
      $got_work_to_do = 1;
      last;    # It's break; for perl
    }
  }

  if ( $got_work_to_do
    and not $enum_member_alias_to_base_value_run_counter >=
    $max_enum_member_alias_to_base_value_runs )
  {
    pos($content) = 0;    # Reset /gc search position
    $get_enum_base_value_first_run = 1;
    refresh_struct_scope_content();
    refresh_enum_scope_content();
    refresh_needs_c_prefix_array();

    # Run again
    enum_member_alias_to_base_value();
  }
  else {
    print
"DONE after $enum_member_alias_to_base_value_run_counter enum base value translation",
      $enum_member_alias_to_base_value_run_counter > 1 ? "s" : "", ".\n";
  }
}    # sub

sub type_alias_to_base_value {
  my $base_types_regex = "(" . join( '|', @basetypes ) . ")";
  my $alias_name_regex = qr/type\s(\w+)\s=\s$base_types_regex\n/;

  # Hash map of name, type
  my %name_type_map;

  while ( $content =~ /$alias_name_regex/g ) {
    my $cur_name = $1;
    if ( defined $name_type_map{$cur_name} ) {
      next;
    }
    $name_type_map{$cur_name} = $2;
  }

  # print "\nname_type_map for replacing top level type alias:\n";
  # use Data::Dumper;
  # print Dumper( \%name_type_map );
  my $alias_names_regex_group = join( "|", keys %name_type_map );

  # print "################ alias names regex group START #############\n";
  # print $alias_names_regex_group;
  # print "################ alias names regex group END #############\n";
  if ( $alias_names_regex_group ne "" ) {

    # Get 3 groups, concat them back together,
    # with type alias replaced by $name_type_map
    my $search_replace_regex =
      qr/(type\s\w+\s=\s)($alias_names_regex_group)(\n)/;
    foreach ( $content =~ /$search_replace_regex/g ) {

      # Assuming there is always a map to base type for top/root level types
      # Also, no \Q \E to escape here
      $content =~
s/(type\s\w+\s=\s)($alias_names_regex_group)(\n)/$1$name_type_map{$2}$3/gs;

      #print "#### Replaced top level type: $1$name_type_map{$2}$3";
      pos($content) = 0;
    }
  }
}    # sub

