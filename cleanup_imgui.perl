#!/usr/bin/perl
use strict;
use warnings;

my $file_in  = 'src/imgui.v';
my $file_out = 'src/imgui.v';

# Only available after generate_imgui_v.sh ran at least once
my $header_file                                 = 'include/cimgui.h';
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

open my $in_header, '<', $header_file
  or die "Can not read ${header_file}: $!";
my $header = do { local $/; <$in_header> };    # slurp!
close($in_header);

open my $in, '<', $file_in or die "Can not read ${file_in}: $!";
my $content = do { local $/; <$in> };          # slurp!
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

#### Example
# 123 = 456
# ->
# _123 = 456
####

#### Example
# fn ig_create_context(shared_font_atlas &ImFontAtlas) &Context
# ->
# fn create_context(shared_font_atlas &ImFontAtlas) &Context
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
#  $line =~ /
#  (?:                # Start non capture group
#  [a-z0-9_]+\s       # Whatever struct member name
#  (?!fn\s\()         # Not "fn", because we deal with function types in structs earlier
#  (?:[&\[\]\d]?)*    # Whatever prefix the struct member type might have,
#                     # we don't want to capture it
#  \s?(\w+)           # Capture group 1 for the member type
#  )                  # End non capture group and add result to map of struct member types
#                     # to just 1, to deduplicate
#  (?{ @struct_member_types{$1} = 1 })
#  /x;
      $line =~
/(?:^\s*[^\s]+\s+(?!fn\s)(?:[&\[\]\d])*([^\s]+)$)(?{ @struct_member_types{$1} = 1 })/gm;
    }
  }

  # Build map of "type abc = 123" on root level
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
      #print $param_type . "\n";
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

  # Type alias on root level may also have a value that's unknown,
  # but it can not be a voidptr alias, like C.name
  foreach my $param_type ( values %typedef_map ) {

    # Ignore fn and C. types
    if ( $param_type =~ /fn\s\(/ or $param_type =~ /\bC\./ ) { next; }
    if (  not( "@basetypes" =~ /\b\Q$param_type\E\b/ )
      and not( "@struct_names" =~ /\b\Q$param_type\E\b/ )
      and not( exists $enum_scope_content{$param_type} )
      and not( exists $typedef_map{$param_type} ) )
    {
      #print $param_type . "\n";
      my @matching_keys =
        grep { $typedef_map{$_} eq $param_type } keys %typedef_map;
      my $key_tmp = $matching_keys[0];
      $typedef_map{$key_tmp} = "voidptr";
      $content =~ s/^(.*type\s+\Q$key_tmp\E\s+=\s+).*$/$1voidptr/m;
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

  # ImPlot functions are in the same namespace as imgui; need to keep im_plot
  #$content =~ s/(\sim_plot_)(?=\w+)/ /g;

  if ( not $got_needs_c_prefix_array ) { refresh_needs_c_prefix_array(); }

  # Remove ImGui from enum names
  my $not_in = join "|", @needs_c_prefix_array;

  #print "####NOT_IN:\n$not_in\n";
  $content =~ s/             # Replace
          [^'\/]             # Not a commented line
          \K                 # Ignore everything to the left, otherwise it would replace "]"
          (?!$not_in)    # Any type that shouldn't be touched
          (\bImGui_?)(?=\w+) # The thing to remove
          //gx;

  # Remove tailing _t from struct names
  $content =~ s/(struct\s\w+)(_t)(\s\{)/$1$3/g;

  #open my $outtmp, '>', 'tmp_implot.v' or die "Can not write tmp_implot.v: $!";
  #print $outtmp $content;
  #close($outtmp);

  # Remove int(...) cast
  if ( $content =~ /\bint\([^\)]+/ ) {
    $content =~ s/\bint\(([^\)]+)\)/$1/g;
  }

  # ~0 to int(~0)
  if ( $content =~ /\s(\~\b0\b)/ ) {
    $content =~ s/\s(\~\b0\b)/int($1)/g;
  }
  
  # fn ig_create_context(shared_font_atlas &ImFontAtlas) &Context -> fn create_context(shared_font_atlas &ImFontAtlas) &Context
  $content =~ s/fn\sig_/fn /g;

  # Remove enum name from members
  # Also refix members names that are just \d+ with _\d+
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
  $header =~
    /^\/\/based\son\simgui.h\sfile\sversion\s"([^"]+)"\s(\d+)\sfrom\s/m;
  my $version_str = $1;
  my $version_num = $2;
  #print "### Found Version: $1 $2\n";
  my $version_v = "";
  if ( length $version_str and length $version_num ) {
    $version_v =
"\npub const version = \"$version_str\"\npub const version_num = $version_num\n";
  }

  my $static_string =
      "\nmodule imgui\n"
    . "\n#flag -I \@VMODROOT/include\n"
    . "#include <cimgui.h>\n"
    . "#flag -DCIMGUI_DEFINE_ENUMS_AND_STRUCTS\n"
    . "#flag -DIMGUI_USE_WCHAR32\n"
    . $version_v
    . "// Placeholder for appending static strings\n";

  # Apply static string
  $content =~ s/\nmodule main\n/$static_string/;

  # Refresh some things to make InputMap not get a C. prefix
  refresh_struct_scope_content();
  refresh_needs_c_prefix_array();

  $static_string = "";

  #if ( not $got_needs_c_prefix_array ) {refresh_needs_c_prefix_array(); }
  foreach my $type_need_c_prefix (@needs_c_prefix_array) {
    $static_string .= "pub type C.$type_need_c_prefix = voidptr\n";
  }

  # Apply static string
  $content =~ s/\/\/ Placeholder for appending static strings\n/$static_string/;

# Replace C.Time_t -> C.time_t
# Replace C.Tm -> C.tm, as they are both coming from time.h and are not translated correctly
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
# Note: No \Q \E here, as text to replace can not be escaped
  $content =~ s/(?<!C\.)\b($needs_c_prefix_search)\b/C\.$1/g;    # [\[\]\d&]*
      #print join ",", $needs_c_prefix_search;
}    # sub

sub get_enum_base_value {
  my $enum_name                       = $_[0];
  my $member_name                     = $_[1];
  my $enum_base_value_already_updated = $_[2];
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
          if ( $val_part =~ /[^0-9][a-zA-Z_\.]+/ ) {
            $contains_alias = 1;
            last;
          }
        }
        if ( not $contains_alias ) {
          push @{ $enum_member_name_value{$cur_enum_name} },
            ( $member_name, $val_complete );
        }
      }    # for line
    }    # for enum_content

    #print "\nenum_member_name_value\n";
    #use Data::Dumper;
    #print Dumper( \%enum_member_name_value );
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
    if ( not $enum_base_value_already_updated ) {

      # Update name value map and try again
      $get_enum_base_value_first_run = 1;
      return get_enum_base_value( $enum_name, $member_name, 1 );
    }
    else {
      print
"$enum_name not found in enum_scope_content map. Reset get_enum_base_value_first_run with no effect.\n";
    }
  }
  print
    "RETURNING EMPTY base_value for enum: $enum_name\nmember: $member_name\n";
  return "";
}    # sub

# enum_name:   TabItemFlags_
# member name: im_gui_tab_item_flags_leading -> leading
# remove_dot: DataType_.im_gui_data_type_count -> data_type_count
sub remove_enum_member_prefix {
  my $enum_name                    = $_[0];
  my $member_name_or_scope_content = $_[1];
  my $is_in_another_enum           = $_[2];

  # if parameter is not passed to this sub, default to 0
  $is_in_another_enum //= 0;

  #print "Processing remove_enum_member_prefix enum_name: $enum_name\n";
  #print "is_in_another_enum: $is_in_another_enum\n";
  # Remove im_gui_ and enum name from members
  if (  $is_in_another_enum
    and $is_in_another_enum == 1
    and $member_name_or_scope_content =~ /im_gui_/ )
  {
    # Single line and value contains "."
    $member_name_or_scope_content =~ s/\b(.+)\.(im_gui_)(.+)/$1.$3/g;
    $enum_name = $1;
    #print "\nAfter removing im_plot: $member_name_or_scope_content\n";
  }
  else {
    # Whole enum scope
    #$member_name_or_scope_content =~ s/\b(im_plot_)(?=\w+)?//g;
    $member_name_or_scope_content =~ s/\b(im_gui_)(?=\w+)?//g;
  }

  # Remove "ImGui" pre snake case, because "im_gui_" was removed for each member
  $enum_name =~ s/ImGui//;

  #print "Pre snake case $enum_name\n";
  my @upper_words     = $enum_name =~ /([A-Z][a-z0-9_]*)/g;
  my $enum_name_snake = join( "_", map { lc } @upper_words );
  #print "Post snake case $enum_name_snake\n";
  my $scope_content_clean = $member_name_or_scope_content;
  $scope_content_clean =~ s/\Q$enum_name_snake\E[_]?//g;

# enum: ButtonFlagsPrivate_ member: button_flags_pressed_on_click -> pressed_on_click
# They all seem to end with "Private_"
# Could use the 2nd last _ to remove from, but rather hard code "_private_" for now,
# as it might break member names otherwise
  if ( $enum_name_snake =~ /_private_$/m ) {

    #print "\nPre _private_ removal: $scope_content_clean\n";
    $enum_name_snake     =~ s/private_$//m;
    $scope_content_clean =~ s/\Q$enum_name_snake\E[_]?//g;

    #print "\nPost _private_ removal: $scope_content_clean\n"
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
      #print "Enum name first_part snake: $first_part\n";

# Still not clean, because only the last part of the enum name is in member name.
# The member name begins with the last part of enum name
      if ( $scope_content_clean =~ /$enum_name_to_remove/ ) {
        #print "scope_content_clean contains: $first_part\n";

        #print "\nPre _private_ removal: $scope_content_clean\n";
        $scope_content_clean =~ s/^\s*\Q$enum_name_to_remove\E//m;

        #print "\nPost _private_ removal: $scope_content_clean\n"
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
      if ( $line =~ /pressed_on_click \| pressed_on_click_release/ ) {
        print "After member_name: $member_name\nval_complete: $val_complete\n";
      }
      my $val_complete_clean = $val_complete;
      my @val_parts          = split( /\|/, $val_complete );
      for my $val_part (@val_parts)
      {
        $val_part =~ s/(^\s+|\s+$)//g; # Trim white space at start/end
        # Ignore non alias values
        if ( $val_part !~ /[A-Za-z]/ ) { next; }
        #print "Enum name: $enum_name\n";
        #print "Line: $line\n";
        #print "val_complete: $val_complete\n";
        #print "val_part: $val_part\n";
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
        }
        if ($is_in_another_enum) {
          $enum_name_to_find_in = $1;
          $val_part_to_find     = $2;
          #print
#"Pre remove other enum prefix: $val_part_to_find\n for other enum: $enum_name_to_find_in\n";
          $val_part_to_find = remove_enum_member_prefix( $enum_name_to_find_in,
            $val_part_to_find, $is_in_another_enum );
          #print
#"After remove other enum prefix: $val_part_to_find\n for other enum: $enum_name_to_find_in\n";
        }

        # Handle "member = xyz - abc"
        if ( $val_part =~ /([^\-\s]+)\s*\-\s*([^\-\s]+)/ ) {
          my $val_part_orig = $val_part;
          #print
          #  "Trying to get base value for $1 and $2 in $enum_name_to_find_in\n";
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
            $line         =~ s/\b\Q$val_part_orig\E\b/$val_part/;
            $enum_content =~ s/\Q$line_orig\E/$line/;
            next;
          }
        }

        # Case where x = 123
        # y = x | 345 -> y = 123 | 345
        #if ( $enum_name eq "HoveredFlagsPrivate_" ) {
        #  print "checking line for HoveredFlagsPrivate_:\n$line\n";
        #}
        my $base_value =
          get_enum_base_value( $enum_name_to_find_in, $val_part_to_find );
        if ( not( $base_value eq "" ) ) {
          $base_value =~ s/(^\s+|\s+$)//g;
          #print
#"\n#### Found base val: $base_value\nFor enum member $enum_name_to_find_in\nval_complete: $val_complete\nval_part: $val_part\n";

          #print "PRE: $val_complete_clean\n";
          $val_complete_clean =~ s/\Q$val_part\E/$base_value/;
          #print "POST: $val_complete_clean\n";
          $line_orig = $line;
          $line         =~ s/\b\Q$val_complete\E\b/$val_complete_clean/;
          $enum_content =~ s/\Q$line_orig\E/$line/;
          $val_complete = $val_complete_clean;
          #if (  $val_complete eq "HoveredFlagsPrivate_"
          #  and $member_name eq "allowed_mask_for_is_item_hovered" )
          #{
            #print
#"processed HoveredFlagsPrivate_.allowed_mask_for_is_item_hovered: $val_complete_clean\n";
          #}
        }
      }    # for val_parts in line
    }    # foreach line
         # Apply change
         #print "ApplyEnum:\n$enum_name\nContent:\n$enum_content\n";
    $content =~ s/\Q$enum_scope_content{$enum_name}\E/$enum_content/;

    #use Data::Dumper;
    #my @k = keys %enum_scope_content;
    #print Dumper(\@k);

  }    # for enum_scope_content

# At the end, "ImGuiDataType_.data_type_count" -> "int(ImGuiDataType_.data_type_count)"
# Int cast was removed in basic_cleanup(), but here we can assume that all ref.type are translated to base value already.
# If they are still there, they point to an enum value without = assignment
  $content =~ s/(?<!<|"|'|\d\.)(?!int\(|C\.)\b(\w+\.\w+)(?!\))\b/int($1)/g;

  # Also change C.Time_t -> C.time_t. It's coming from time.h
  #             C.Tm     -> C.tm
  $content =~ s/\bC\.Time_t\b/C.time_t/g;
  $content =~ s/\bC\.Tm\b/C.tm/g;

  refresh_enum_scope_content();

  # If there are enum members with alias values, run again
  $enum_member_alias_to_base_value_run_counter += 1;
  my $got_work_to_do = 0;
  for my $e_name ( keys %enum_scope_content ) {
    if (
      $enum_scope_content{$e_name} =~
      /^\s*[a-z_]+[\s]+[^\n]=[\s<\d\|]+(?!int\()([a-z_]+)\s*$/gm
      )
    {
      print "Got work to do in $e_name:\n$1\n";
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

