#!/usr/bin/perl
use strict;
use warnings;

my $file_in  = 'src/imgui.v';
my $file_out = 'src/imgui.v';

# Only available after generate_imgui_v.sh ran at least once
my $header_file                                 = 'include/cimgui.h';
my $prefix_to_remove                            = "ImGui";
my $module_name                                 = "imgui";
my $v_manual_additions_file                     = 'src/manually_added.v';
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
my @basetypes = (    # Note: C.types are added dynamically
  "bool",    "u8",    "i8",    "u16", "i16", "u32",
  "i32",     "u64",   "i64",   "int", "f32", "f64",
  "voidptr", "usize", "isize", "char"
);
my @types_already_defined = (

  #  Also added dynamically; by reading src/manually_added.v
);

my $typedef_regex = qr/type\s(\w+)\s=\s(?:[\d\[\]&]*)?(.*)\n/;

open my $in_header, '<', $header_file
  or die "Can not read ${header_file}: $!";
my $header_content = do { local $/; <$in_header> };    # slurp!
close($in_header);

open my $in, '<', $file_in or die "Can not read ${file_in}: $!";
my $content = do { local $/; <$in> };                  # slurp!
close($in);

open my $in_manual, '<', $v_manual_additions_file
  or die "Can not read ${v_manual_additions_file}: $!";
my $manual_additions_content = do { local $/; <$in_manual> };    # slurp!
close($in_manual);
my @manual_additions_struct_names =
  $manual_additions_content =~ /\bstruct\s([\w\d]+)\s\{/g;
push @manual_additions_struct_names,
  $manual_additions_content =~ /pub\stype\s([\w\d]+)\s=/g;

# print "##### Manual Additions Struct Names:\n";
# use Data::Dumper;
# print Dumper( \@manual_additions_struct_names );

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

#### Example
# 123 = 456
# ->
# _123 = 456
####

#### Example
# fn ig_create_context(shared_font_atlas &ImFontAtlas) &Context
# ->
# pub fn create_context(shared_font_atlas &ImFontAtlas) &Context
####

#### Comment out Keys.mod_none enum; value is duplicate of Keys.none
#### Comment out Keys.named_begin; value is duplicate of Keys.tab

#### Example
# struct ImVector_ImFontPtr {
# ->
# pub type ImVector_ImFontPtr = C.ImVector_ImFontPtr
# @[typedef]
# struct C.ImVector_ImFontPtr {
####
# open my $qwe, '>', "content_tmp.txt" or die "Can not write content_tmp.txt: $!";
# print $qwe $content . "\n// Got enum scope content: $got_enum_scope_content\n";
# close($qwe);
basic_cleanup();

#### Append static strings, like version
#### Example
# module main
# ->
# module imgui
# pub const version = '1.91.9 WIP'
# pub const version_num = 19187
# pub type
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

#### Remove prefix "ImGui", where not C.
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

#### Set emum explicit value
#### Example
# enum MyEnum {
#   none = 0
#   x
#   y = 200
#   z
# ->
# enum My Enum {
#   none = 0
#   x = 1
#   y = 200
#   z = 201
####
#set_enum_value();

#### Add sub union members to structs by scanning C header file and inserting union members into correct V structs
add_sub_union_members_to_structs();

#### Set default for C.types in structs to unsafe{ nil }
#### Example
# pub type ImRect = C.ImRect
# @[typedef]
# struct C.ImRect {
#   x fn()
#   y voidptr
# ->
# struct MyStruct {
#   x fn() = unsafe{ nil }
#   y voidptr = unsafe{ nil }
####
set_default_nil_for_pointers();

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

# Note: unsafe{nil}, meaning extra { } in structs is added at the end, so it's not handled here
  %struct_scope_content = ();

  # %struct_scope_content = $content =~ /(?:[^\/]struct\s(\w+)\s\{([^\}]+))/gs;
  %struct_scope_content =
    $content =~ /(?:[^\/]struct\s([\w\.]+)\s\{\spub\smut:\s+(\s[^\}]+))/g;
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

  #print join ", ", @typedef_names;
  my %typedef_map;
  if ( not $got_struct_scope_content ) { refresh_struct_scope_content(); }

  # Find struct names and their corresponding V type
  my @struct_names = $content =~
    /(?:pub\stype\s([\w\d]+)\s=\sC\.)/g;    # keys %struct_scope_content;
  $content =~ /(?:struct\s([\w\d\.]+)\s\{)(?{push @struct_names, $1})/g;

  # print "#### STRUCT_NAMES: @struct_names\n";
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

      # Note these don't contain param names, only types in a function defintion
      #print "Got inline_fn_params: $inline_fn_params\n";
      # To prepare for split by "," remove all prefixes and ()
        $inline_fn_params =~ s/\s?fn\s\(//;
        $inline_fn_params =~ s/&*(?:\[\d*\])*//;
        $func_params .= ", " . $inline_fn_params;

      }
    }    # foreach func params
    my @params = split( ", ", $func_params );

    #print "\nProcessing all fn params:\n";
    #use Data::Dumper;
    #print Dumper( \@params );
    foreach my $param (@params) {
      $param =~ s/^\s+|\s+$//g;
      if ( $param =~ /\s?\bfn\b\s\(/ ) { next; }

      #pos($param) = 0;
      if ( $param eq "" or $param =~ /^\bC\./ ) { next; }

      #@func_param_types{$param} = 1;
      #foreach ( $param =~ /(?:(?:\w+)?\s?(?:&)*)(\w+)/gc ) {
      foreach ( $param =~ /(\w+)/gc ) {
        if ( $1 eq "fn" ) {
          next;
        }

        #print "Adding single func param to func_param_types: $1 \n";
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
      $line =~
/(?:^\s*[^\s]+\s+(?!fn\s)(?:[&\[\]\d])*([^\s]+)$)(?{ @struct_member_types{$1} = 1 })/gm;
    }
  }

  # Build map of "type abc = 123" on root level
  # Ignore C. types, as the are in structs already
  while ( $content =~ /$typedef_regex/g ) {
    my $cur_name = $1;
    if ( defined $typedef_map{$cur_name} or $2 =~ /^C\./ ) {
      next;
    }
    $typedef_map{$cur_name} = $2;
  }

  # use Data::Dumper;
  # print Dumper(\%typedef_map);

  # Find types needed as parameter in some function defintion
  # or in a struct, where no local definition was found
  my @manual_additions_struct_names_prefix =
    map { "ImGui$_" } @manual_additions_struct_names;
  foreach my $param_type ( keys %func_param_types ) {
    if (  not( "@basetypes" =~ /\b\Q$param_type\E\b/ )
      and not( "@struct_names" =~ /\b\Q$param_type\E\b/ )
      and not( exists $enum_scope_content{$param_type} )
      and not( exists $typedef_map{$param_type} )
      and not( "@manual_additions_struct_names" =~ /\b\Q$param_type\E\b/ )
      and
      not( "@manual_additions_struct_names_prefix" =~ /\b\Q$param_type\E\b/ ) )
    {
      #print $param_type . "\n";
      push @needs_c_prefix_array, $param_type;
    }
  }
  foreach my $param_type ( keys %struct_member_types ) {
    if (  not( "@basetypes" =~ /\b\Q$param_type\E\b/ )
      and not( "@struct_names" =~ /\b\Q$param_type\E\b/ )
      and not( exists $enum_scope_content{$param_type} )
      and not( exists $typedef_map{$param_type} )
      and not( "@manual_additions_struct_names" =~ /\b\Q$param_type\E\b/ )
      and
      not( "@manual_additions_struct_names_prefix" =~ /\b\Q$param_type\E\b/ ) )
    {
      #print $param_type . "\n";
      push @needs_c_prefix_array, $param_type;
    }
  }

  # Type alias on root level may also have a value that's unknown
  foreach my $param_type ( values %typedef_map ) {

    # Ignore fn and C. types
    if ( $param_type =~ /fn\s\(/ or $param_type =~ /\bC\./ ) { next; }

    if (  not( "@basetypes" =~ /\b\Q$param_type\E\b/ )
      and not( "@struct_names" =~ /\b\Q$param_type\E\b/ )
      and not( exists $enum_scope_content{$param_type} )
      and not( exists $typedef_map{$param_type} )
      and not( "@manual_additions_struct_names" =~ /\b\Q$param_type\E\b/ )
      and
      not( "@manual_additions_struct_names_prefix" =~ /\b\Q$param_type\E\b/ ) )
    {
      # If ImStbTexteditState is unknown
      # pub type ImStbTexteditState = STB_TexteditState
      # ->
      # pub type ImStbTexteditState = C.STB_TexteditState
      # @[typedef]
      # struct C.STB_TexteditState {}
      #
      # print "Param type on root level: $param_type\n";
      # Look up key from value
      my @matching_keys =
        grep { $typedef_map{$_} eq $param_type } keys %typedef_map;

      # print "#### Matching keys: @matching_keys\n";
      my $key_tmp = $matching_keys[0];
      $content =~
s/^([^\n]*\btype\s+\Q$key_tmp\E\s+=\s+(?:[\d&\[\]]+)?)((?!fn\()[^\n]*)$(?{ $typedef_map{$key_tmp} = "C.$2" })/\npub $1C.$2\n@[typedef]\nstruct C.$2 {}/pm;

      # print "#### Found unknown root level type: $key_tmp\n";
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
  $content =~ s/(\sim_gui_)(?=\w+)?/ /g;

  # Remove im_gui_ from values
  $content =~ s/(\b\.im_gui_)(?=\w+)?/\./g;
  refresh_enum_scope_content();

  # struct ImGuiImFontAtlas -> @[typedef]\nstruct C.ImGuiImFontAtlas ...
  # Also append C.type to basetypes
  $content =~
s/^struct\s([\w\d]+)\s\{(?{ push(@basetypes, "C\.$1") })/\n\npub type $1 = C.$1\n@[typedef]\nstruct C.$1 {\npub mut:\n/gm;

  #print "#### BASETYPES: @basetypes\n";
  refresh_needs_c_prefix_array();

  # Remove tailing _t from struct names
  $content =~ s/(struct\s\w+)(_t)(\s\{)/$1$3/g;

  # Remove int(...) cast
  if ( $content =~ /\bint\([^\)]+/ ) {
    $content =~ s/\bint\(([^\)]+)\)/$1/g;
  }

  # ~0 to int(~0)
  if ( $content =~ /\s(\~\b0\b)/ ) {
    $content =~ s/\s(\~\b0\b)/ int($1)/g;
  }

# fn ig_create_context(shared_font_atlas &ImFontAtlas) &Context -> fn create_context(shared_font_atlas &ImFontAtlas) &Context
  $content =~ s/fn\sig_/pub fn /g;

  # fn im_vec4_im_vec4_float -> pub fn im_vec4_im_vec4_float
  $content =~ s/^fn\s/pub fn /gm;

  # Comment out mod_none in Keys enum
  $content =~ s/[^\n]+(\bmod_none\s+=\s+0)/\/\/$1/;

  # Comment out named_begin in Keys enum
  $content =~ s/[^\n]+(\bkey_named_key_begin\s+=\s+512)/\/\/$1/;

  # Remove @[weak] global
  $content =~
s/^@\[weak\]\s__global\sGImGui\s&ImGuiContext\s/\/*\n@[weak]\n__global GImGui &ImGuiContext\n*\//m;

# TODO: @[_allow_multiple_values] in enums doesn't seem to work. error: cannot call a function that does not have a body. For function call ctx := imgui.create_context(unsafe{nil})
# Comment out "none = 0", as it's the same value as mouse_button_left
# Users will have to pass 0 or mouse_button_left for none
  $content =~
    s/(enum\sImGuiPopupFlags_\s\{\s+)(popup_flags_none\s+=\s0)/$1\/\/$2/;

  # Comment mouse_button_default_       = 1
  $content =~
s/(enum\sImGuiPopupFlags_\s\{.*)(popup_flags_mouse_button_default_\s+=\s1)/$1\/\/$2/s;

  # Comment fitting_policy_default_ = 1 << 7
  $content =~
s/(enum\sImGuiTabBarFlags_\s\{.*)(tab_bar_flags_fitting_policy_default_\s+=\stab_bar_flags_fitting_policy_resize_down)/$1\/\/$2/s;

  # Comment pressed_on_default_ = 1 << 5
  $content =~
s/(enum\sImGuiButtonFlagsPrivate_\s\{.*)(button_flags_pressed_on_default_\s+=\sbutton_flags_pressed_on_click_release)/$1\/\/$2/s;

  # Comment round_corners_default_ = 1 << 4 | 1 << 5 | 1 << 6 | 1 << 7
  $content =~
s/(enum\sImDrawFlags_\s\{.*)(im_draw_flags_round_corners_default_\s+=\sim_draw_flags_round_corners_all)/$1\/\/$2/s;

  # Comment cond_mask_ = 1 << 22 | 1 << 23
  $content =~
s/(enum\sImGuiInputFlagsPrivate_\s\{.*)(input_flags_cond_default_\s+=\sinput_flags_cond_hovered\s\|\sinput_flags_cond_active)/$1\/* $2 *\//s;

# Comment supported_by_is_key_pressed = 1 << 0 | 1 << 1 | 1 << 2 | 1 << 3 | 1 << 4 | 1 << 5 | 1 << 6 | 1 << 7
  $content =~
s/(enum\sImGuiInputFlagsPrivate_\s\{.*)(input_flags_supported_by_is_key_pressed\s+=\sinput_flags_repeat_mask_)/$1\/* $2 *\//s;

# Change type ImFileHandle = &C.FILE
# FILE_str(FILE* it);  ‘FILE *’ but argument is of type ‘FILE **’
# $content =~ s/^type\s(C\.)?ImFileHandle\s=\s&C\.FILE/pub type ImFileHandle = C.FILE\n@[typedef]\nstruct C.FILE {}/m;
  $content =~
    s/^type\s(C\.)?ImFileHandle\s=\s&C\.FILE/pub type ImFileHandle = &voidptr/m;

  # Upper case first char in struct member names
  # Except C.ImVec2 ...
  refresh_struct_scope_content();
  foreach my $struct_name ( keys %struct_scope_content ) {
    if ( $struct_name eq "C.ImVec2"
      or $struct_name eq "C.ImVec4"
      or $struct_name eq "C.ImVec2ih"
      or $struct_name eq "C.ImDrawVert"
      or $struct_name eq "C.ImVec1"
      or $struct_name eq "C.ImGuiStoragePair"
      or $struct_name eq "C.ImGuiTextRange" )
    {
      next;
    }
    my $struct_content      = $struct_scope_content{$struct_name};
    my $struct_content_orig = $struct_content;

    # Upper case between \U \E
    $struct_content =~ s/^(\s*)([\w_])(\w*\s+[[:print:]]+)$/$1\U$2\E$3/gm;

   # print "#### New struct content:\n$struct_content\n";
   # Note: Surrounding pub mut: and }, because x and y are common struct members
    $content =~
      s/pub\smut:\s+\Q$struct_content_orig\E\s*\}/pub mut:\n$struct_content}/;
  }

  # Remove enum name from members
  # Also prefix member names that are just \d+ with _\d+
  refresh_enum_scope_content();
  while ( my ( $enum_name, $scope_content ) = each %enum_scope_content ) {
    my $scope_content_clean =
      remove_enum_member_prefix( $enum_name, $scope_content );

#print "Removed enum $enum_name as $enum_name_snake from members: $scope_content_clean\n";

    # Remove enum name from member name
    my @lines = split( /\n/, $scope_content_clean );
    for my $line (@lines) {
      my $line_orig = $line;
      if ( $line =~ /^\/\// or $line !~ /\s=\s/ ) { next; }
      $line =~ /([^\s]+)\s*=\s*/;
      my $member_name = $1;

      #print "Got member_name: $member_name\n";
      my $member_name_clean =
        remove_enum_member_prefix( $enum_name, $member_name );
      if ( $member_name_clean ne "" ) {

        #print "Got member_name_clean: $member_name_clean\n";
        $line =~ s/\Q$member_name\E/$member_name_clean/;

        #print "Clean line: $line\n";
        $scope_content_clean =~ s/\Q$line_orig\E/$line/;
      }
    }
    $content =~ s/\Q$scope_content\E/$scope_content_clean/g;
  }

  # After all replacements/removals prefix numbers that are member names with _
  $content =~ s/\b(\d+)\s+=\s+([[:print:]]+)\s*\n/_$1 = $2\n/sg;

  #$get_enum_base_value_first_run = 1;
  refresh_enum_scope_content();
  refresh_struct_scope_content();
  refresh_needs_c_prefix_array();
}    # sub

sub append_static_strings {
  $header_content =~
    /^\/\/based\son\simgui.h\sfile\sversion\s"([^"]+)"\s(\d+)\sfrom\s/m;
  my $version_str = $1;
  my $version_num = $2;

  #print "### Found Version: $1 $2\n";
  my $version_v = "";
  if ( length $version_str and length $version_num ) {
    $version_v =
"\npub const version = \"$version_str\"\npub const version_num = $version_num\n\n";
  }

  my $static_string =
      "\nmodule $module_name\n\n"
    . $version_v
    . "// Placeholder for appending static strings\n";

  # Apply static string
  $content =~ s/\nmodule main\n/$static_string/;

  $static_string = "";

  # print "\n#### Needs C Prefix Array:\n";
  # use Data::Dumper;
  # print Dumper( \@needs_c_prefix_array );
  my %type_names_on_root_level = $content =~ /$typedef_regex/g;
  foreach my $type_needs_c_prefix (@needs_c_prefix_array) {

    # Make sure this C.type is not already defined manually
    # This does not need another type definition
    my $is_already_defined = 0;
    foreach my $already_defined (@types_already_defined) {
      if ( $already_defined eq $type_needs_c_prefix
        or exists $type_names_on_root_level{$type_needs_c_prefix} )
      {
        $is_already_defined = 1;
        last;
      }
    }
    if ( !$is_already_defined ) {
      my $upper = ucfirst($type_needs_c_prefix);
      $static_string .=
"pub type $upper = C.$type_needs_c_prefix\n@[typedef]\npub struct C.$type_needs_c_prefix {}\n";
      push( @types_already_defined, "C\.$type_needs_c_prefix" );
    }
  }

# args va_list -> args Va_list. It's used in functions, but the V name is Va_list
# This has to be done after unknown types get a struct, otherwise unknown type "va_list" will get an upper case name for the struct as well
  $content =~ s/\bargs\sva_list\b/args Va_list/g;

  # Apply static string
  $content =~ s/\/\/ Placeholder for appending static strings\n/$static_string/;

  refresh_enum_scope_content();
  refresh_needs_c_prefix_array();
}    # sub

# Prepend all occurences of unknown types with C.
# Also remove $prefix_to_remove, like ImGui
sub find_unknowns_and_set_c_prefix {
  refresh_needs_c_prefix_array();
  my $needs_c_prefix_search = join( "|", @needs_c_prefix_array );

# Unmatched ( in regex; marked by <-- HERE in m/(?<!(&?)C\.)\b&?( <-- HERE ...
# Should be an issue with needs_c_prefix_search. Something went wrong at collecting types in func_param_types or struct_member_types
# Note: No \Q \E here, as text to replace can not be escaped
# Also, when there are no unknown types, the search string is empty
# print "#### Needs c prefix search: $needs_c_prefix_search\n";
  if ( $needs_c_prefix_search ne "" ) {
    $content =~ s/(?<!C\.)\b($needs_c_prefix_search)\b/C\.$1/g;    # [\[\]\d&]*
  }

  #print join ",", $needs_c_prefix_search;

# Remove prefix, like ImGui
# Also handle struct member types containing $prefix_to_remove
# Examples
# pub type ImGuiPopupData = C.ImGuiPopupData -> pub type PopupData = C.ImGuiPopupData
# pub type xxx_ImGuiKey_xxx__xxxImGui_xxx = C.xxx_ImGuiKey_xxx__xxxImGui_xxx -> pub type xxx_Key_xxx__xxx_xxx = C.xxx_ImGuiKey_xxx__xxxImGui_xxx

  my $in_struct_scope = 0;
  my @lines           = split "\n", $content;
  foreach my $line (@lines) {

    # Skip commented lines or empty structs
    if ( $line =~ /^\s*\/\// or $line =~ /struct\sC\.[\w\d]+\s*\{\s*\}/ ) {
      next;
    }

    # Flag if current line is inside struct scope
    if ( $line =~ /\bstruct\s(?:C\.)?[\w\d]+\s*\{/ ) {
      $in_struct_scope = 1;

      # print "#### Entering struct scope on line:\n$line\n";
    }

    # Flag if current line leaves struct scope
    if ( $in_struct_scope and $line =~ /^\s*\}/ ) {
      $in_struct_scope = 0;

      # print "#### Leaving struct scope on line:\n$line\n";
    }

    # Ignore line in struct scope, if member type does not contain prefix
    if (  $in_struct_scope
      and $line !~ /[\w\d_]+\s+(.*\Q$prefix_to_remove\E.*)/ )
    {
      next;
    }
    else {
      my $line_orig = $line;

      # Handle all words containing prefix
      if ( $line !~ /\Q$prefix_to_remove\E/ ) { next; }

      # print "Line pre: $line\n";
      foreach my $word (
        $line =~ /\b(?:C\.)?[\w\d]*\Q$prefix_to_remove\E[\w\d]*\b/gc )
      {
        if ( $word !~ /^C\./ ) {
          my $word_orig = $word;

          # print "#### REMOVE ImGui - processing: $word\n";
          $word =~ s/\Q$prefix_to_remove\E//g;

       # Special check for scope, because of line "_ImGuiViewport ImGuiViewport"
          if ($in_struct_scope) {
            $line =~ s/([\w\d_]+\s+.*)(\Q$word_orig\E)/$1$word/;
          }
          else {
            $line =~ s/\Q$word_orig\E/$word/;
          }
        }
      }

      # print "Line post: $line\n";
      # Apply
      $content =~ s/\Q$line_orig\E/$line/;
    }
  }
}    # sub

sub get_enum_base_value {
  my $enum_name                       = $_[0];
  my $member_name                     = $_[1];
  my $enum_base_value_already_updated = $_[2];
  if ($get_enum_base_value_first_run) {
    $get_enum_base_value_first_run = 0;

    # Fill this up on first run
    %enum_member_name_value = ();

    # Map each enum name (key) to each of its members [name, value]
    # Scan each member for its value, but only when they are not an alias
    if ( not $got_enum_scope_content ) { refresh_enum_scope_content(); }

    foreach my $cur_enum_name ( keys %enum_scope_content ) {

     # Append each name&value to enum_member_name_value, where it's a base value
      my @lines = split( '\n', $enum_scope_content{$cur_enum_name} );
      foreach my $line (@lines) {
        $line =~ s/(^\s+|\s+$)//g;    # Trim white space at start/end
        if ( $line eq "" ) { next; }

        #if ( $enum_name eq "HoveredFlagsPrivate_" ) {
        #  print "checking line for HoveredFlagsPrivate_:\n$line\n";
        #}

       # !~ is true for non match. To skip enum members without value assignment
        if ( $line !~ /([a-z0-9_]+)\s+=\s+([[:print:]\s]+)/ ) { next; }
        my $member_name    = $1;
        my $val_complete   = $2;
        my @val_parts      = split( /\|/, $val_complete );
        my $contains_alias = 0;
        for my $val_part (@val_parts) {
          $val_part =~ s/(^\s+|\s+$)//g;    # Trim white space at start/end
                                            # Ignore alias values
          if ( $val_part =~ /[^0-9][a-zA-Z_\.]+/ and $val_part !~ /^int\(/ ) {

# print "Ignoring alias for base val translations: $cur_enum_name.$member_name = $val_complete\n";
            $contains_alias = 1;
            last;
          }
        }
        if ( not $contains_alias ) {

    # print "Adding to enum map: $cur_enum_name.$member_name = $val_complete\n";
          push @{ $enum_member_name_value{$cur_enum_name} },
            ( $member_name, $val_complete );
        }
      }    # for line
    }    # for enum_content

    # print "\nenum_member_name_value\n";
    #use Data::Dumper;
    # print Dumper( \%enum_member_name_value );
  }    # if first run

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

      # if ($member_name eq "repeat_rate_mask_") {
      #   print "### Checking for $member_name in @names_values_arr\n" ;
      # }
      if ( $cur_name eq $member_name ) {

        # print "Enum: $enum_name.$member_name ret: $names_values_arr[$i]\n";
        return $names_values_arr[$i];
      }
    }
  }
  else {
    if ( not $enum_base_value_already_updated ) {

      # Update name value map and try again
      $get_enum_base_value_first_run = 1;
      return get_enum_base_value( $enum_name, $member_name, 1 );
    }
    else {
# print "$enum_name not found in enum_scope_content map. Reset get_enum_base_value_first_run with no effect.\n";
    }
  }

# print "RETURNING EMPTY base_value for enum: $enum_name\nmember: $member_name\n";
  return "";
}    # sub

# enum_name:   TabItemFlags_
# change name: im_gui_tab_item_flags_leading -> leading
# remove dot: DataType_.im_gui_data_type_count -> data_type_count
sub remove_enum_member_prefix {
  my $enum_name                    = $_[0];
  my $member_name_or_scope_content = $_[1];
  my $is_in_another_enum           = $_[2];

  # if parameter is not passed to this sub, default to 0
  $is_in_another_enum //= 0;

  # print "Processing remove_enum_member_prefix enum_name: $enum_name\n";
  # print "is_in_another_enum: $is_in_another_enum\n";
  # Remove im_gui_ and enum name from members
  if (  $is_in_another_enum
    and $is_in_another_enum == 1
    and $member_name_or_scope_content =~ /im_gui_/ )
  {
    # Single line and value contains "."
    $member_name_or_scope_content =~ s/\b(.+)\.(im_gui_)(.+)/$1.$3/g;
    $enum_name = $1;

    # print "\nAfter removing im_plot: $member_name_or_scope_content\n";
  }
  else {
    # Whole enum scope
    #$member_name_or_scope_content =~ s/\b(im_plot_)(?=\w+)?//g;
    $member_name_or_scope_content =~ s/\b(im_gui_)(?=\w+)?//g;
  }

  # Remove "ImGui" pre snake case, because "im_gui_" was removed for each member
  $enum_name =~ s/ImGui//;

  # print "Pre snake case $enum_name\n";
  my @upper_words     = $enum_name =~ /([A-Z][a-z0-9_]*)/g;
  my $enum_name_snake = join( "_", map { lc } @upper_words );

  # print "Post snake case $enum_name_snake\n";
  my $scope_content_clean = $member_name_or_scope_content;
  $scope_content_clean =~ s/\Q$enum_name_snake\E[_]?//g;

# enum: ButtonFlagsPrivate_ member: button_flags_pressed_on_click -> pressed_on_click
# They all seem to end with "Private_"
# Could use the 2nd last _ to remove from, but rather hard code "_private_" for now,
# as it might break member names otherwise
  if ( $enum_name_snake =~ /_private_$/m ) {

    # print "\nPre _private_ removal: $scope_content_clean\n";
    $enum_name_snake     =~ s/private_$//m;
    $scope_content_clean =~ s/\Q$enum_name_snake\E[_]?//g;

    # print "\nPost _private_ removal: $scope_content_clean\n"
  }

# Remove until first _ in enum name and try to remove it from member name start.
  my @enum_name_snake_split = split( /_/, $enum_name_snake );
  my $first_part            = "";
  my $enum_name_to_remove   = $enum_name_snake;
  for ( my $i = length @enum_name_snake_split - 1 ; $i >= 0 ; $i-- ) {
    if ( $enum_name_to_remove =~ /^(?:\s*(_?[^_\W]+)_)/ ) {
      $first_part = $1;
      if ( $first_part eq "_" or $first_part eq "" ) { last; }

      $enum_name_to_remove =~ s/\Q$first_part\E//;

      # print "Enum name first_part snake: $first_part\n";

# Still not clean, because only the last part of the enum name is in member name.
# The member name begins with the last part of enum name
      if ( $scope_content_clean =~ /$enum_name_to_remove/ ) {

        # print "scope_content_clean contains: $first_part\n";

        # print "\nPre _private_ removal: $scope_content_clean\n";
        $scope_content_clean =~ s/^\s*\Q$enum_name_to_remove\E//m;

        # print "\nPost _private_ removal: $scope_content_clean\n"
      }

    }
  }    # for enum name part
       #if ($is_in_another_enum and $is_in_another_enum == 1) {
       #  print "\nAfter scope_content_clean: $scope_content_clean\n"
       #}
  return $scope_content_clean;
}    # sub

sub enum_member_alias_to_base_value {
  for my $enum_name ( keys %enum_scope_content ) {
    my $enum_content = $enum_scope_content{$enum_name};
    my @lines        = split( "\n", $enum_content );
    foreach my $line (@lines) {
      if ( $line =~ /^\/\// or $line !~ /\s=\s/ ) { next; }

      #if ( $line =~ /pressed_on_click \| pressed_on_click_release/ ) {
      #  print "Processing\n$line\n";
      #}
      my $line_orig = $line;

      $line =~ /([a-z0-9_]+)\s+=\s(.*)/;
      my $member_name = $1;
      if ( not $2 ) { next; }
      my $val_complete = $2;

      # if ( $line =~ /pressed_on_click \| pressed_on_click_release/ ) {
      # print "After member_name: $member_name\nval_complete: $val_complete\n";
      # }
      my $val_complete_clean = $val_complete;

# if ($val_complete =~ /\| delay_mask_/) { print "Starting base translation for\n$line\n";}
      my @val_parts = split( /\|/, $val_complete );

# if ($val_complete =~ /\| delay_mask_/) { print "Got val_parts: @val_parts\n";}
      for my $val_part (@val_parts) {
        $val_part =~ s/(^\s+|\s+$)//g;    # Trim white space at start/end
                                          # Ignore non alias values
        if ( $val_part !~ /[A-Za-z]/ ) {

          # print "Skipping val_part: $val_part\n";
          next;
        }

        # print "Enum name: $enum_name\n";
        # print "Line: $line\n";
        # print "val_complete: $val_complete\n";
        # print "val_part: $val_part\n";
        #if (  $enum_name eq "HoveredFlagsPrivate_"
        #  and $member_name eq "allowed_mask_for_is_item_hovered" )
        #{
        #  print
        #"processing: HoveredFlagsPrivate_.allowed_mask_for_is_item_hovered\n";
        #}

        #my $alias = $1;
        my $enum_name_to_find_in = $enum_name;

# Check if it's referencing a value of another enum
#dock_node_flags_local_flags_transfer_mask_ = int(DockNodeFlags_.im_gui_dock_node_flags_no_docking_split) | dock_node_flags_no_resize_flags_mask_ | int(DockNodeFlags_.im_gui_dock_node_flags_auto_hide_tab_bar) | dock_node_flags_central_node | dock_node_flags_no_tab_bar | dock_node_flags_hidden_tab_bar | dock_node_flags_no_window_menu_button | dock_node_flags_no_close_button
# Remove ItemFlags_.im_gui_item_flags_auto_close_popups -> ItemFlags_.auto_close_popups
#if ( $enum_name eq "ItemFlagsPrivate_" ) {
#  print "Cur alias pre . check $alias\n";
#}
        my $is_in_another_enum = 0;
        my $val_part_to_find   = $val_part;
        my $is_minus_operation = 0;
        my $has_operand2       = 0;

        if ( $val_part =~ /([^\.\(\)]+)\.([^\.\(\)]+)/ ) {
          $is_in_another_enum = 1;

          # print "val_part $val_part in $1 is in another enum $val_part\n";
        }
        if ($is_in_another_enum) {
          $enum_name_to_find_in = $1;
          $val_part_to_find     = $2;

# print "Pre remove other enum prefix: $val_part_to_find\n for other enum: $enum_name_to_find_in\n";
          $val_part_to_find = remove_enum_member_prefix( $enum_name_to_find_in,
            $val_part_to_find, $is_in_another_enum );

# print "Post remove other enum prefix: $val_part_to_find\n for other enum: $enum_name_to_find_in\n";
        }

        # Handle "member = xyz - abc"
        if ( $val_part =~ /([^\-\s]+)\s*\-\s*([^\-\s]+)/ ) {
          my $val_part_orig = $val_part;

    # print "Trying to get base value for $1 and $2 in $enum_name_to_find_in\n";
          my $base_value_left  = $1;
          my $left_orig        = $1;
          my $base_value_right = $2;
          my $right_orig       = $2;
          if ( $base_value_left !~ /\d+/ ) {
            $base_value_left =
              get_enum_base_value( $enum_name_to_find_in, $base_value_left );
          }
          if ( $base_value_right !~ /\d+/ ) {
            $base_value_right =
              get_enum_base_value( $enum_name_to_find_in, $base_value_right );
          }

          # Translate and update enum_content
          if ( $base_value_left eq "" or $base_value_right eq "" ) {
            print "Could not translate $val_part\n";
          }
          else {
            $val_part =~ s/\Q$left_orig\E/$base_value_left/;
            $val_part =~ s/\Q$right_orig\E/$base_value_right/;

            # $line_orig is already set above
            $line         =~ s/\Q$val_part_orig\E/$val_part/;
            $enum_content =~ s/\Q$line_orig\E/$line/;
            next;
          }
        }

# Handle "x = 123
#         y = x | 345 -> y = 123 | 345"
#if ( $enum_name eq "DockNodeFlagsPrivate_" ) {
#  print "Checking line for $enum_name:\n$line\n";
#}
# if ($val_part_to_find eq "delay_mask_") {print "Finding base val for $val_part_to_find\n";}
        my $base_value =
          get_enum_base_value( $enum_name_to_find_in, $val_part_to_find );

# if ($val_part_to_find eq "no_resize_flags_mask_") {print "Base val for $val_part_to_find: $base_value\n";}
        if ( not( $base_value eq "" ) ) {
          $base_value =~ s/(^\s+|\s+$)//g;

# print "\n#### Found base val: $base_value\nFor enum $enum_name_to_find_in.$val_part_to_find\nval_complete: $val_complete\nval_part: $val_part\n";

          # print "PRE: $val_complete_clean\n";
          $val_complete_clean =~ s/\Q$val_part\E/$base_value/;

          # print "POST: $val_complete_clean\n";
          $line_orig = $line;
          $line         =~ s/\Q$val_complete\E/$val_complete_clean/;
          $enum_content =~ s/\Q$line_orig\E/$line/;
          $val_complete = $val_complete_clean;

          # if ( $member_name eq "supported_by_set_next_item_shortcut" )
          # {
          #   print "processed $member_name: $enum_content\n";
          #   print "### Line orig:\n$line_orig\nLine clean:\n$line\n";
          # }
        }
      }    # for val_parts in line
    }    # foreach line
         # Apply change
         # print "ApplyEnum:\n$enum_name\nContent:\n$enum_content\n";
    $content =~ s/\Q$enum_scope_content{$enum_name}\E/$enum_content/;

# Note: If you refresh enum scope content here, all translations will be done in one run,
# because later enum members depend on earlier enum members in all cases
#use Data::Dumper;
#my @k = keys %enum_scope_content;
# print Dumper(\@k);
  }    # for enum_scope_content

# At the end, "ImGuiDataType_.data_type_count" -> "int(ImGuiDataType_.data_type_count)"
# Int cast was removed in basic_cleanup(), but here we can assume that all ref.type are translated to base value already.
# If they are still there, they point to an enum value without = assignment
  $content =~
    s/(^[^\/\n]+)(?<!<|"|'|\d\.)(?!int\(|C\.)\b(\w+\.\w+)(?!\))\b/$1int($2)/gm;

  # Also change C.Time_t -> C.time_t. It's coming from time.h
  #             C.Tm     -> C.tm
  $content =~ s/\bC\.Time_t\b/C.time_t/g;
  $content =~ s/\bC\.Tm\b/C.tm/g;

  # Remove redundant pub type ImFileHandle = C.ImFileHandle
  # That was added as unknown type. TODO
  $content =~
s/pub\stype\sImFileHandle\s=\sC\.ImFileHandle\s@\[typedef\]\spub\sstruct\sC\.ImFileHandle\s\{\}//;

  # Also C.ImFileHandle -> ImFileHandle
  $content =~ s/\bC\.ImFileHandle\b/ImFileHandle/g;

  # Replace last few unknown types, because they were not translated
  $content =~
s/pub\stype\sImWchar\s=\sC\.ImWchar\s@\[typedef\]\spub\sstruct\sC\.ImWchar\s\{\}/\npub type ImWchar = u32/;
  $content =~
s/struct\sC\.(?:ImGui)?TextFilter\s\{\}/struct C.ImGuiTextFilter {\npub mut:\n  InputBuf [256]char\n  Filters ImVector_TextRange\n  CountGrep int\n}/;
  $content =~
s/pub\stype\s(?:ImGui)?InputTextCallback\s=\sC\.(?:ImGui)?InputTextCallback\s@\[typedef\]\spub\sstruct\sC\.(?:ImGui)?InputTextCallback\s\{\}/\npub type InputTextCallback = fn(&InputTextCallbackData) int/;
  $content =~
s/pub\stype\s(?:ImGui)?SizeCallback\s=\sC\.(?:ImGui)?SizeCallback\s@\[typedef\]\spub\sstruct\sC\.(?:ImGui)?SizeCallback\s\{\}/\npub type SizeCallback = fn(&SizeCallbackData)/;

  refresh_enum_scope_content();

  # If there are enum members with alias values, run again
  $enum_member_alias_to_base_value_run_counter += 1;
  my $got_work_to_do = 0;
  for my $e_name ( keys %enum_scope_content ) {
    if (
      my @todos = $enum_scope_content{$e_name} =~
      /^[^\n\*]+(?==)(?:[^\n]+)?[\s<\d\|](?!int\()([a-z_]+)[^=\n]+$/gm
      )
    {
      print "Got work to do in $e_name: $1\nUntranslated values: @todos\n";
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

  # Note: At this point @basetypes also contains all C.types
  my $base_types_regex = "(" . join( '|', @basetypes ) . ")";
  my $alias_name_regex = qr/type\s(\w+)\s=\s(?:[\d\[\]&]*)?$base_types_regex\n/;

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
      qr/(type\s\w+\s=\s(?:[\d\[\]&]*)?)($alias_names_regex_group)(\n)/;
    foreach ( $content =~ /$search_replace_regex/g ) {

      # Assuming there is always a map to base type for top/root level types
      # Also, no \Q \E to escape here
      $content =~
s/(type\s\w+\s=\s(?:[\d\[\]&]*)?)($alias_names_regex_group)(\n)/$1$name_type_map{$2}$3/gs;

      # print "#### Replaced top level type: $1$name_type_map{$2}$3";
      pos($content) = 0;
    }
  }
}    # sub

sub set_enum_value {

  # Assuming enum scope content is updated
  # Set all unassigned enum values
  foreach my $enum_name ( keys %enum_scope_content ) {
    my $counter           = 0;
    my $content_changed   = 0;
    my $enum_content      = $enum_scope_content{$enum_name};
    my $enum_content_orig = $enum_content;
    my @lines             = split "\n", $enum_content;

    # print "#### Enum Content Before:\n$enum_content\n";
    foreach my $line (@lines) {

   # For enums without values for all members.
   # If a value is set, it's not "name = 1 << 0 | 1 - 1 | int(AnotherEnum.name)"
      if ( $line =~ /[<\|]/ ) { next; }
      if ( $line =~ /int\(/ ) { next; }
      if ( $line =~ /\s-\s/ ) { next; }
      my $line_orig = $line;
      if ( $line =~ /^\s*[\w_]+\s*=\s*([-\d]+)$/ ) {

        # print "#### Value $enum_name $1\nin line $line\n";
        $counter = $1 + 1;
        next;
      }
      else {
        if ( $line =~ /([\w_]+)/ ) {
          my $name = $1;

          # print "#### Name $enum_name.$name\n";
          $line =~ s/\Q$name\E/$name = $counter/;

# Trim space so \b word boundary works, otherwise tab_hovered and tab can not be distinguished
          $line_orig    =~ s/^\s+|\s+$//g;
          $enum_content =~ s/\b\Q$line_orig\E\b/$line/;
          $counter++;
          $content_changed = 1;
        }
      }
    }
    if ($content_changed) {
      $content =~ s/\Q$enum_content_orig\E/$enum_content/;

      # print "#### Enum Content After:\n$enum_content\n";
    }
  }
}    # sub

sub add_sub_union_members_to_structs {
  my %c_to_v = qw(
    void* voidptr
    float f32
  );

  while ( $header_content =~
    /struct\s+([\w\d_]+)\s+\{[^\}]+union\s*\{([^\}]+)\}\s*;[^\}]\}\s*;/g )
  {
    my $c_struct        = $1;
    my $c_union_content = $2;

    # Translate union content to V
    # print "#### C union content: $c_union_content\n";
    # print "In struct: $c_struct\n";
    # Sample output:
    # #### C union content:  int val_i; float val_f; void* val_p;
    # In struct: ImGuiStoragePair
    # #### C union content:  int BackupInt[2]; float BackupFloat[2];
    # In struct: ImGuiStyleMod
    my $v_struct    = "C.$c_struct";
    my @c_members   = ();
    my @c_name_vals = split ";", $c_union_content;
    foreach my $c_name_val (@c_name_vals) {
      $c_name_val =~ s/^\s+|\s+$//g;

      # Name, Value
      $c_name_val =~
        /([\w\*]+)\s*([\w\d\[\]_]+)(?{ push @c_members, ($2, $1) })/;
    }

    # print "#### C members:\n";
    # use Data::Dumper;
    # print Dumper( \@c_members );

    my @v_members = ();
    my $c_member_name;
    for my $i ( 0 .. $#c_members ) {
      if ( $i % 2 == 0 ) {
        $c_member_name = $c_members[$i];
        next;
      }

      # print "Processing $c_member_name\n";
      my $c_member_type = $c_members[$i];
      my $v_member_type;

      # print "Got type: $c_member_type\n";
      if ( $c_member_name =~ /(\[\d*\])/ ) {
        $v_member_type .= $1;
        $c_member_name =~ s/\[\d*\]//;
      }
      if ( exists $c_to_v{$c_member_type} and defined $c_to_v{$c_member_type} )
      {
        $v_member_type .= $c_to_v{$c_member_type};
      }
      else {
        $v_member_type .= $c_member_type;
      }
      my $v_member_name = $c_member_name;
      push @v_members, ( $v_member_name, $v_member_type );
    }
    my $append_string = "";
    my $v_member_name;
    my $v_member_type;
    for my $i ( 0 .. $#v_members ) {
      if ( $i % 2 == 0 ) { $v_member_name = $v_members[$i]; next; }
      $v_member_type = $v_members[$i];
      $append_string .= "  $v_member_name $v_member_type\n";
    }
    if ( $append_string eq "" ) {
      return;
    }

    # Replace struct scope
    my $struct_scope      = $struct_scope_content{$v_struct};
    my $struct_scope_orig = $struct_scope;
    $struct_scope .= "$append_string";

    # print "#### Added struct sub union:\n$struct_scope\n";
    $content =~ s/\Q$struct_scope_orig\E/$struct_scope/;
  }
}    # sub

# In structs
sub set_default_nil_for_pointers {

  # Pointers or function definitions on top level
  my @ptr_types = ();
  while ( $content =~
    /^\s*(?:pub\s*)?type\s([\w\d_]+)\s*=\s*(?:fn\s*\(|voidptr|(?!\])&+\w+)/gm )
  {
    push @ptr_types, $1;
  }
  my @empty_structs = ();
  while ( $content =~
/pub\s+type\s+([\w\d]+)\s+=\sC\.[\w\d]+\s+@\[typedef\]\s+[^\n]*struct\s+C\.[\w\d]+\s\{\s*\}/g
    )
  {
    push @empty_structs, $1;
  }
  my $ptr_types_search     = join "|", @ptr_types;
  my $empty_structs_search = join "|", @empty_structs;

  # print "#### Ptr types search: $ptr_types_search\n";
  for my $struct_name ( keys %struct_scope_content ) {
    my $cur_content       = $struct_scope_content{$struct_name};
    my $cur_content_clean = $struct_scope_content{$struct_name};

    # Set default for types aliasing pointers. Mandatory
    $cur_content_clean =~
s/(^\s*[\w\d_]+\s+)((?!\])&*(?:$ptr_types_search)[^\n]*)/$1\/*$2*\/voidptr = unsafe{ nil }/gm;

# Set default for fn types
# $cur_content_clean =~ s/(^\s*[\w\d_]+\s+)((?:\bfn\s*\()[^\n]*)/$1$2 = unsafe{ nil }/gm;
# Set default for voidptr
    $cur_content_clean =~
s/(^\s*[\w\d_]+\s+)((?:voidptr)(?!\s=\sunsafe\{)[^\n]*)/$1$2 = unsafe{ nil }/gm;

    # Set default voidptr for normal pointers. Mandatory
    $cur_content_clean =~
s/(^\s*[\w\d_]+\s+)((?:(?!\[\d*\])&+[\w\d]+)(?!\s=\sunsafe\{)[^\n]*)/$1\/*$2*\/voidptr= unsafe{ nil }/gm;

# Set default for empty struct pointers
# $cur_content_clean =~ s/(^\s*[\w\d_]+\s+)((?!\])&(?:$empty_structs_search)(?!\s=\sunsafe\{)[^\n]*)/$1$2 = unsafe{ nil }/gm;

    # Apply
    $content =~ s/\Q$cur_content\E/$cur_content_clean/;
  }

  #### TMP until end
# my %c_structs = ();
# while ($header_content =~ /struct\s+([\w\d]+)\s+\{/g) {
#   @c_structs{$1} = 1;
# }
# # my %seen = ();
# # $seen{$_}++ for @tmp;
# # print Dumper \%seen;
# my %v_structs = ();
# print "#### V structs not translated:\n";
# while ($content =~ /struct\s+C\.([\w\d]+)\s+\{/g) {
#   @v_structs{$1} = 1;
# }
# my @not_found_in_v = ();
# foreach my $c_struct (keys %c_structs) {
#   if (not defined $v_structs{$c_struct}) {
#     push @not_found_in_v, $c_struct;
#   }
# }
# print join "\n", @not_found_in_v;
# print "#### Normal pointer lines:\n";
#my @pointers = ();
#while($content =~ /(^\s*[\w\d_]+\s+)((?:(?!\[\d*\])&+[\w\d]+)(?!\s=\sunsafe\{)[^\n]*)/gm) {
#  push @pointers, ($1, $2);
#}
# print Dumper \@pointers;
}    # THE END

