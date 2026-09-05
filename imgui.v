module imgui

/*
cleanup_imgui_implot.perl non-regression notes

Keep this block current when changing cleanup rules. Do not hardcode one
function, enum member, or struct member; derive facts from cimgui/cimgui.h or
cimplot/cimplot.h, then apply generic V cleanup.

Covered cases and examples:
1. Strip raw C/preprocessor leakage:
   Callback typedef parsing is line-based so it never recreates:
     broken callback alias with u64 payload
2. Const parameter names come from header prototypes:
     CIMGUI_API bool igButton(const char* label,const ImVec2_c size);
   This yields const_label/const_size generically.
3. Missing aliases/opaque declarations are inferred from type positions and
   header typedefs only, not arbitrary capitalized field names.
4. Value backing structs such as ImVec2_c/ImVec4_c/ImColor_c/ImRect_c back public
   aliases ImVec2/ImVec4/ImColor/ImRect. Do not emit duplicate empty C structs.
   Vector fields remain lowercase x/y/z/w for V literals.
5. Remove self-module prefixes: imgui.v must not refer to Type; implot.v
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

/*
MIT License

Copyright Anton Oreskin | https://oreskin.de

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

pub const version = '1.92.7'
pub const version_num = 19270

pub type DockNodeSettings = C.ImGuiDockNodeSettings

@[typedef]
pub struct C.ImGuiDockNodeSettings {}

pub type DockRequest = C.ImGuiDockRequest

@[typedef]
pub struct C.ImGuiDockRequest {}

pub type ImColor = C.ImColor_c

pub type ImFontAtlasBuilder = C.ImFontAtlasBuilder

@[typedef]
pub struct C.ImFontAtlasBuilder {}

pub type ImRect = C.ImRect_c

pub type ImVec2 = C.ImVec2_c

pub type ImVec2i = C.ImVec2i_c

pub type ImVec4 = C.ImVec4_c

pub type ImWchar = u32

pub type InputTextCallback = fn (&InputTextCallbackData) i32

pub type SizeCallback = fn (&SizeCallbackData)

pub type TextFilter = C.ImGuiTextFilter

@[typedef]
pub struct C.ImGuiTextFilter {}

pub type Va_list = C.va_list

@[typedef]
pub struct C.va_list {}

@[typedef]
pub struct C.stbrp_node {}

// docking branch

pub type ImVector_const_charPtr = C.ImVector_const_charPtr

@[typedef]
pub struct C.ImVector_const_charPtr {
pub mut:
	Size     i32
	Capacity i32
	Data     &&u8
}

pub type ID = u32
pub type ImS8 = i8
pub type ImU8 = u8
pub type ImS16 = i16
pub type ImU16 = u16
pub type ImS32 = i32
pub type ImU32 = u32
pub type ImS64 = i64
pub type ImU64 = i64
pub type Col = i32
pub type Cond = i32
pub type DataType = i32
pub type MouseButton = i32
pub type MouseCursor = i32
pub type StyleVar = i32
pub type TableBgTarget = i32
pub type ImDrawFlags = i32
pub type ImDrawListFlags = i32
pub type ImDrawTextFlags = i32
pub type ImFontFlags = i32
pub type ImFontAtlasFlags = i32
pub type BackendFlags = i32
pub type ButtonFlags = i32
pub type ChildFlags = i32
pub type ColorEditFlags = i32
pub type ConfigFlags = i32
pub type ComboFlags = i32
pub type DockNodeFlags = i32
pub type DragDropFlags = i32
pub type FocusedFlags = i32
pub type HoveredFlags = i32
pub type InputFlags = i32
pub type InputTextFlags = i32
pub type ItemFlags = i32
pub type KeyChord = i32
pub type ListClipperFlags = i32
pub type PopupFlags = i32
pub type MultiSelectFlags = i32
pub type SelectableFlags = i32
pub type SliderFlags = i32
pub type TabBarFlags = i32
pub type TabItemFlags = i32
pub type TableFlags = i32
pub type TableColumnFlags = i32
pub type TableRowFlags = i32
pub type TreeNodeFlags = i32
pub type ViewportFlags = i32
pub type WindowFlags = i32
pub type ImWchar32 = u32
pub type ImWchar16 = u16
pub type SelectionUserData = i64
pub type MemAllocFunc = fn (usize, voidptr) voidptr

pub type MemFreeFunc = fn (voidptr, voidptr)

pub type ImVec2_c = C.ImVec2_c

@[typedef]
pub struct C.ImVec2_c {
pub mut:
	x f32
	y f32
}

pub type ImVec4_c = C.ImVec4_c

@[typedef]
pub struct C.ImVec4_c {
pub mut:
	x f32
	y f32
	z f32
	w f32
}

pub type ImTextureID = i64

pub type ImTextureRef_c = C.ImTextureRef_c

@[typedef]
pub struct C.ImTextureRef_c {
pub mut:
	_TexData &ImTextureData
	_TexID   ImTextureID
}

pub enum WindowFlags_ {
	none                        = 0
	no_title_bar                = 1 << 0
	no_resize                   = 1 << 1
	no_move                     = 1 << 2
	no_scrollbar                = 1 << 3
	no_scroll_with_mouse        = 1 << 4
	no_collapse                 = 1 << 5
	always_auto_resize          = 1 << 6
	no_background               = 1 << 7
	no_saved_settings           = 1 << 8
	no_mouse_inputs             = 1 << 9
	menu_bar                    = 1 << 10
	horizontal_scrollbar        = 1 << 11
	no_focus_on_appearing       = 1 << 12
	no_bring_to_front_on_focus  = 1 << 13
	always_vertical_scrollbar   = 1 << 14
	always_horizontal_scrollbar = 1 << 15
	no_nav_inputs               = 1 << 16
	no_nav_focus                = 1 << 17
	unsaved_document            = 1 << 18
	no_docking                  = 1 << 19
	no_nav                      = 1 << 16 | 1 << 17
	no_decoration               = 1 << 0 | 1 << 1 | 1 << 3 | 1 << 5
	no_inputs                   = 1 << 9 | 1 << 16 | 1 << 17
	dock_node_host              = 1 << 23
	child_window                = 1 << 24
	tooltip                     = 1 << 25
	popup                       = 1 << 26
	modal                       = 1 << 27
	child_menu                  = 1 << 28
}

pub enum ChildFlags_ {
	none                      = 0
	borders                   = 1 << 0
	always_use_window_padding = 1 << 1
	resize_x                  = 1 << 2
	resize_y                  = 1 << 3
	auto_resize_x             = 1 << 4
	auto_resize_y             = 1 << 5
	always_auto_resize        = 1 << 6
	frame_style               = 1 << 7
	nav_flattened             = 1 << 8
}

pub enum ItemFlags_ {
	none                 = 0
	no_tab_stop          = 1 << 0
	no_nav               = 1 << 1
	no_nav_default_focus = 1 << 2
	button_repeat        = 1 << 3
	auto_close_popups    = 1 << 4
	allow_duplicate_id   = 1 << 5
	disabled             = 1 << 6
}

pub enum InputTextFlags_ {
	none                    = 0
	chars_decimal           = 1 << 0
	chars_hexadecimal       = 1 << 1
	chars_scientific        = 1 << 2
	chars_uppercase         = 1 << 3
	chars_no_blank          = 1 << 4
	allow_tab_input         = 1 << 5
	enter_returns_true      = 1 << 6
	escape_clears_all       = 1 << 7
	ctrl_enter_for_new_line = 1 << 8
	read_only               = 1 << 9
	password                = 1 << 10
	always_overwrite        = 1 << 11
	auto_select_all         = 1 << 12
	parse_empty_ref_val     = 1 << 13
	display_empty_ref_val   = 1 << 14
	no_horizontal_scroll    = 1 << 15
	no_undo_redo            = 1 << 16
	elide_left              = 1 << 17
	callback_completion     = 1 << 18
	callback_history        = 1 << 19
	callback_always         = 1 << 20
	callback_char_filter    = 1 << 21
	callback_resize         = 1 << 22
	callback_edit           = 1 << 23
	word_wrap               = 1 << 24
}

pub enum TreeNodeFlags_ {
	none                     = 0
	selected                 = 1 << 0
	framed                   = 1 << 1
	allow_overlap            = 1 << 2
	no_tree_push_on_open     = 1 << 3
	no_auto_open_on_log      = 1 << 4
	default_open             = 1 << 5
	open_on_double_click     = 1 << 6
	open_on_arrow            = 1 << 7
	leaf                     = 1 << 8
	bullet                   = 1 << 9
	frame_padding            = 1 << 10
	span_avail_width         = 1 << 11
	span_full_width          = 1 << 12
	span_label_width         = 1 << 13
	span_all_columns         = 1 << 14
	label_span_all_columns   = 1 << 15
	nav_left_jumps_to_parent = 1 << 17
	collapsing_header        = 1 << 1 | 1 << 3 | 1 << 4
	draw_lines_none          = 1 << 18
	draw_lines_full          = 1 << 19
	draw_lines_to_nodes      = 1 << 20
}

pub enum PopupFlags_ {
	none                        = 0
	mouse_button_left           = 1 << 2
	mouse_button_right          = 1 << 3
	mouse_button_middle         = 1 << 2 | 1 << 3
	no_reopen                   = 1 << 5
	no_open_over_existing_popup = 1 << 7
	no_open_over_items          = 1 << 8
	any_popup_id                = 1 << 10
	any_popup_level             = 1 << 11
	any_popup                   = 1 << 10 | 1 << 11
	mouse_button_shift_         = 1 << 1
	// mouse_button_mask_ = 1 << 2 | 1 << 3
	invalid_mask_ = 1 << 0 | 1 << 1
}

pub enum SelectableFlags_ {
	none                 = 0
	no_auto_close_popups = 1 << 0
	span_all_columns     = 1 << 1
	allow_double_click   = 1 << 2
	disabled             = 1 << 3
	allow_overlap        = 1 << 4
	highlight            = 1 << 5
	select_on_nav        = 1 << 6
}

pub enum ComboFlags_ {
	none              = 0
	popup_align_left  = 1 << 0
	height_small      = 1 << 1
	height_regular    = 1 << 2
	height_large      = 1 << 3
	height_largest    = 1 << 4
	no_arrow_button   = 1 << 5
	no_preview        = 1 << 6
	width_fit_preview = 1 << 7
	height_mask_      = 1 << 1 | 1 << 2 | 1 << 3 | 1 << 4
}

pub enum TabBarFlags_ {
	none                              = 0
	reorderable                       = 1 << 0
	auto_select_new_tabs              = 1 << 1
	tab_list_popup_button             = 1 << 2
	no_close_with_middle_mouse_button = 1 << 3
	no_tab_list_scrolling_buttons     = 1 << 4
	no_tooltip                        = 1 << 5
	draw_selected_overline            = 1 << 6
	fitting_policy_mixed              = 1 << 7
	fitting_policy_shrink             = 1 << 8
	fitting_policy_scroll             = 1 << 9
	fitting_policy_mask_              = 1 << 7 | 1 << 8 | 1 << 9
	// fitting_policy_default_ = 1 << 7
}

pub enum TabItemFlags_ {
	none                              = 0
	unsaved_document                  = 1 << 0
	set_selected                      = 1 << 1
	no_close_with_middle_mouse_button = 1 << 2
	no_push_id                        = 1 << 3
	no_tooltip                        = 1 << 4
	no_reorder                        = 1 << 5
	leading                           = 1 << 6
	trailing                          = 1 << 7
	no_assumed_closure                = 1 << 8
}

pub enum FocusedFlags_ {
	none                   = 0
	child_windows          = 1 << 0
	root_window            = 1 << 1
	any_window             = 1 << 2
	no_popup_hierarchy     = 1 << 3
	dock_hierarchy         = 1 << 4
	root_and_child_windows = 1 << 0 | 1 << 1
}

pub enum HoveredFlags_ {
	none                              = 0
	child_windows                     = 1 << 0
	root_window                       = 1 << 1
	any_window                        = 1 << 2
	no_popup_hierarchy                = 1 << 3
	dock_hierarchy                    = 1 << 4
	allow_when_blocked_by_popup       = 1 << 5
	allow_when_blocked_by_active_item = 1 << 7
	allow_when_overlapped_by_item     = 1 << 8
	allow_when_overlapped_by_window   = 1 << 9
	allow_when_disabled               = 1 << 10
	no_nav_override                   = 1 << 11
	allow_when_overlapped             = 1 << 8 | 1 << 9
	rect_only                         = 1 << 5 | 1 << 7 | 1 << 8 | 1 << 9
	root_and_child_windows            = 1 << 0 | 1 << 1
	for_tooltip                       = 1 << 12
	stationary                        = 1 << 13
	delay_none                        = 1 << 14
	delay_short                       = 1 << 15
	delay_normal                      = 1 << 16
	no_shared_delay                   = 1 << 17
}

pub enum DockNodeFlags_ {
	none                         = 0
	keep_alive_only              = 1 << 0
	no_docking_over_central_node = 1 << 2
	passthru_central_node        = 1 << 3
	no_docking_split             = 1 << 4
	no_resize                    = 1 << 5
	auto_hide_tab_bar            = 1 << 6
	no_undocking                 = 1 << 7
}

pub enum DragDropFlags_ {
	none                          = 0
	source_no_preview_tooltip     = 1 << 0
	source_no_disable_hover       = 1 << 1
	source_no_hold_to_open_others = 1 << 2
	source_allow_null_id          = 1 << 3
	source_extern                 = 1 << 4
	payload_auto_expire           = 1 << 5
	payload_no_cross_context      = 1 << 6
	payload_no_cross_process      = 1 << 7
	accept_before_delivery        = 1 << 10
	accept_no_draw_default_rect   = 1 << 11
	accept_no_preview_tooltip     = 1 << 12
	accept_draw_as_hovered        = 1 << 13
	accept_peek_only              = 1 << 10 | 1 << 11
}

pub enum DataType_ {
	s8
	u8
	s16
	u16
	s32
	u32
	s64
	u64
	float
	double
	bool
	string
	count
}

pub enum Dir {
	none  = -1
	left  = 0
	right = 1
	up    = 2
	down  = 3
	count = 4
}

pub enum SortDirection {
	none       = 0
	ascending  = 1
	descending = 2
}

pub enum Key {
	none            = 0
	named_key_begin = 512
	// tab = 512
	left_arrow             = 513
	right_arrow            = 514
	up_arrow               = 515
	down_arrow             = 516
	page_up                = 517
	page_down              = 518
	home                   = 519
	end                    = 520
	insert                 = 521
	delete                 = 522
	backspace              = 523
	space                  = 524
	enter                  = 525
	escape                 = 526
	left_ctrl              = 527
	left_shift             = 528
	left_alt               = 529
	left_super             = 530
	right_ctrl             = 531
	right_shift            = 532
	right_alt              = 533
	right_super            = 534
	menu                   = 535
	_0                     = 536
	_1                     = 537
	_2                     = 538
	_3                     = 539
	_4                     = 540
	_5                     = 541
	_6                     = 542
	_7                     = 543
	_8                     = 544
	_9                     = 545
	a                      = 546
	b                      = 547
	c                      = 548
	d                      = 549
	e                      = 550
	f                      = 551
	g                      = 552
	h                      = 553
	i                      = 554
	j                      = 555
	k                      = 556
	l                      = 557
	m                      = 558
	n                      = 559
	o                      = 560
	p                      = 561
	q                      = 562
	r                      = 563
	s                      = 564
	t                      = 565
	u                      = 566
	v                      = 567
	w                      = 568
	x                      = 569
	y                      = 570
	z                      = 571
	f1                     = 572
	f2                     = 573
	f3                     = 574
	f4                     = 575
	f5                     = 576
	f6                     = 577
	f7                     = 578
	f8                     = 579
	f9                     = 580
	f10                    = 581
	f11                    = 582
	f12                    = 583
	f13                    = 584
	f14                    = 585
	f15                    = 586
	f16                    = 587
	f17                    = 588
	f18                    = 589
	f19                    = 590
	f20                    = 591
	f21                    = 592
	f22                    = 593
	f23                    = 594
	f24                    = 595
	apostrophe             = 596
	comma                  = 597
	minus                  = 598
	period                 = 599
	slash                  = 600
	semicolon              = 601
	equal                  = 602
	left_bracket           = 603
	backslash              = 604
	right_bracket          = 605
	grave_accent           = 606
	caps_lock              = 607
	scroll_lock            = 608
	num_lock               = 609
	print_screen           = 610
	pause                  = 611
	keypad0                = 612
	keypad1                = 613
	keypad2                = 614
	keypad3                = 615
	keypad4                = 616
	keypad5                = 617
	keypad6                = 618
	keypad7                = 619
	keypad8                = 620
	keypad9                = 621
	keypad_decimal         = 622
	keypad_divide          = 623
	keypad_multiply        = 624
	keypad_subtract        = 625
	keypad_add             = 626
	keypad_enter           = 627
	keypad_equal           = 628
	app_back               = 629
	app_forward            = 630
	oem102                 = 631
	gamepad_start          = 632
	gamepad_back           = 633
	gamepad_face_left      = 634
	gamepad_face_right     = 635
	gamepad_face_up        = 636
	gamepad_face_down      = 637
	gamepad_dpad_left      = 638
	gamepad_dpad_right     = 639
	gamepad_dpad_up        = 640
	gamepad_dpad_down      = 641
	gamepad_l1             = 642
	gamepad_r1             = 643
	gamepad_l2             = 644
	gamepad_r2             = 645
	gamepad_l3             = 646
	gamepad_r3             = 647
	gamepad_ls_tick_left   = 648
	gamepad_ls_tick_right  = 649
	gamepad_ls_tick_up     = 650
	gamepad_ls_tick_down   = 651
	gamepad_rs_tick_left   = 652
	gamepad_rs_tick_right  = 653
	gamepad_rs_tick_up     = 654
	gamepad_rs_tick_down   = 655
	mouse_left             = 656
	mouse_right            = 657
	mouse_middle           = 658
	mouse_x1               = 659
	mouse_x2               = 660
	mouse_wheel_x          = 661
	mouse_wheel_y          = 662
	reserved_for_mod_ctrl  = 663
	reserved_for_mod_shift = 664
	reserved_for_mod_alt   = 665
	reserved_for_mod_super = 666
	named_key_end          = 667
	named_key_count        = 155
	// mod_none = 0
	mod_ctrl  = 4096
	mod_shift = 8192
	mod_alt   = 16384
	mod_super = 32768
	mod_mask_ = 61440
}

pub enum InputFlags_ {
	none                    = 0
	repeat                  = 1 << 0
	route_active            = 1 << 10
	route_focused           = 1 << 11
	route_global            = 1 << 12
	route_always            = 1 << 13
	route_over_focused      = 1 << 14
	route_over_active       = 1 << 15
	route_unless_bg_focused = 1 << 16
	route_from_root_window  = 1 << 17
	tooltip                 = 1 << 18
}

pub enum ConfigFlags_ {
	none                   = 0
	nav_enable_keyboard    = 1 << 0
	nav_enable_gamepad     = 1 << 1
	no_mouse               = 1 << 4
	no_mouse_cursor_change = 1 << 5
	no_keyboard            = 1 << 6
	docking_enable         = 1 << 7
	viewports_enable       = 1 << 10
	is_srgb                = 1 << 20
	is_touch_screen        = 1 << 21
}

pub enum BackendFlags_ {
	none                       = 0
	has_gamepad                = 1 << 0
	has_mouse_cursors          = 1 << 1
	has_set_mouse_pos          = 1 << 2
	renderer_has_vtx_offset    = 1 << 3
	renderer_has_textures      = 1 << 4
	renderer_has_viewports     = 1 << 10
	platform_has_viewports     = 1 << 11
	has_mouse_hovered_viewport = 1 << 12
	has_parent_viewport        = 1 << 13
}

pub enum Col_ {
	text
	text_disabled
	window_bg
	child_bg
	popup_bg
	border
	border_shadow
	frame_bg
	frame_bg_hovered
	frame_bg_active
	title_bg
	title_bg_active
	title_bg_collapsed
	menu_bar_bg
	scrollbar_bg
	scrollbar_grab
	scrollbar_grab_hovered
	scrollbar_grab_active
	check_mark
	slider_grab
	slider_grab_active
	button
	button_hovered
	button_active
	header
	header_hovered
	header_active
	separator
	separator_hovered
	separator_active
	resize_grip
	resize_grip_hovered
	resize_grip_active
	input_text_cursor
	tab_hovered
	tab
	tab_selected
	tab_selected_overline
	tab_dimmed
	tab_dimmed_selected
	tab_dimmed_selected_overline
	docking_preview
	docking_empty_bg
	plot_lines
	plot_lines_hovered
	plot_histogram
	plot_histogram_hovered
	table_header_bg
	table_border_strong
	table_border_light
	table_row_bg
	table_row_bg_alt
	text_link
	text_selected_bg
	tree_lines
	drag_drop_target
	drag_drop_target_bg
	unsaved_marker
	nav_cursor
	nav_windowing_highlight
	nav_windowing_dim_bg
	modal_window_dim_bg
	count
}

pub enum StyleVar_ {
	alpha
	disabled_alpha
	window_padding
	window_rounding
	window_border_size
	window_min_size
	window_title_align
	child_rounding
	child_border_size
	popup_rounding
	popup_border_size
	frame_padding
	frame_rounding
	frame_border_size
	item_spacing
	item_inner_spacing
	indent_spacing
	cell_padding
	scrollbar_size
	scrollbar_rounding
	scrollbar_padding
	grab_min_size
	grab_rounding
	image_rounding
	image_border_size
	tab_rounding
	tab_border_size
	tab_min_width_base
	tab_min_width_shrink
	tab_bar_border_size
	tab_bar_overline_size
	table_angled_headers_angle
	table_angled_headers_text_align
	tree_lines_size
	tree_lines_rounding
	button_text_align
	selectable_text_align
	separator_size
	separator_text_border_size
	separator_text_align
	separator_text_padding
	docking_separator_size
	count
}

pub enum ButtonFlags_ {
	none                = 0
	mouse_button_left   = 1 << 0
	mouse_button_right  = 1 << 1
	mouse_button_middle = 1 << 2
	mouse_button_mask_  = 1 << 0 | 1 << 1 | 1 << 2
	enable_nav          = 1 << 3
	allow_overlap       = 1 << 12
}

pub enum ColorEditFlags_ {
	none               = 0
	no_alpha           = 1 << 1
	no_picker          = 1 << 2
	no_options         = 1 << 3
	no_small_preview   = 1 << 4
	no_inputs          = 1 << 5
	no_tooltip         = 1 << 6
	no_label           = 1 << 7
	no_side_preview    = 1 << 8
	no_drag_drop       = 1 << 9
	no_border          = 1 << 10
	no_color_markers   = 1 << 11
	alpha_opaque       = 1 << 12
	alpha_no_bg        = 1 << 13
	alpha_preview_half = 1 << 14
	alpha_bar          = 1 << 18
	hdr                = 1 << 19
	display_rgb        = 1 << 20
	display_hsv        = 1 << 21
	display_hex        = 1 << 22
	uint8              = 1 << 23
	float              = 1 << 24
	picker_hue_bar     = 1 << 25
	picker_hue_wheel   = 1 << 26
	input_rgb          = 1 << 27
	input_hsv          = 1 << 28
	default_options_   = 1 << 20 | 1 << 23 | 1 << 25 | 1 << 27
	alpha_mask_        = 1 << 1 | 1 << 12 | 1 << 13 | 1 << 14
	display_mask_      = 1 << 20 | 1 << 21 | 1 << 22
	data_type_mask_    = 1 << 23 | 1 << 24
	picker_mask_       = 1 << 25 | 1 << 26
	input_mask_        = 1 << 27 | 1 << 28
}

pub enum SliderFlags_ {
	none               = 0
	logarithmic        = 1 << 5
	no_round_to_format = 1 << 6
	no_input           = 1 << 7
	wrap_around        = 1 << 8
	clamp_on_input     = 1 << 9
	clamp_zero_range   = 1 << 10
	no_speed_tweaks    = 1 << 11
	color_markers      = 1 << 12
	always_clamp       = 1 << 9 | 1 << 10
	invalid_mask_      = 1 << 0 | 1 << 1 | 1 << 2 | 1 << 3 | 1 << 28 | 1 << 29 | 1 << 30
}

pub enum MouseButton_ {
	left   = 0
	right  = 1
	middle = 2
	count  = 5
}

pub enum MouseCursor_ {
	none  = -1
	arrow = 0
	text_input
	resize_all
	resize_ns
	resize_ew
	resize_nesw
	resize_nwse
	hand
	wait
	progress
	not_allowed
	count
}

pub enum MouseSource {
	mouse        = 0
	touch_screen = 1
	pen          = 2
	count        = 3
}

pub enum Cond_ {
	none           = 0
	always         = 1
	once           = 2
	first_use_ever = 4
	appearing      = 8
}

pub enum TableFlags_ {
	none                            = 0
	resizable                       = 1 << 0
	reorderable                     = 1 << 1
	hideable                        = 1 << 2
	sortable                        = 1 << 3
	no_saved_settings               = 1 << 4
	context_menu_in_body            = 1 << 5
	row_bg                          = 1 << 6
	borders_inner_h                 = 1 << 7
	borders_outer_h                 = 1 << 8
	borders_inner_v                 = 1 << 9
	borders_outer_v                 = 1 << 10
	borders_h                       = 1 << 7 | 1 << 8
	borders_v                       = 1 << 9 | 1 << 10
	borders_inner                   = 1 << 7 | 1 << 9
	borders_outer                   = 1 << 8 | 1 << 10
	borders                         = 1 << 7 | 1 << 8 | 1 << 9 | 1 << 10
	no_borders_in_body              = 1 << 11
	no_borders_in_body_until_resize = 1 << 12
	sizing_fixed_fit                = 1 << 13
	sizing_fixed_same               = 1 << 14
	sizing_stretch_prop             = 1 << 13 | 1 << 14
	sizing_stretch_same             = 1 << 15
	no_host_extend_x                = 1 << 16
	no_host_extend_y                = 1 << 17
	no_keep_columns_visible         = 1 << 18
	precise_widths                  = 1 << 19
	no_clip                         = 1 << 20
	pad_outer_x                     = 1 << 21
	no_pad_outer_x                  = 1 << 22
	no_pad_inner_x                  = 1 << 23
	scroll_x                        = 1 << 24
	scroll_y                        = 1 << 25
	sort_multi                      = 1 << 26
	sort_tristate                   = 1 << 27
	highlight_hovered_column        = 1 << 28
	sizing_mask_                    = 1 << 13 | 1 << 14 | 1 << 15
}

pub enum TableColumnFlags_ {
	none                   = 0
	disabled               = 1 << 0
	default_hide           = 1 << 1
	default_sort           = 1 << 2
	width_stretch          = 1 << 3
	width_fixed            = 1 << 4
	no_resize              = 1 << 5
	no_reorder             = 1 << 6
	no_hide                = 1 << 7
	no_clip                = 1 << 8
	no_sort                = 1 << 9
	no_sort_ascending      = 1 << 10
	no_sort_descending     = 1 << 11
	no_header_label        = 1 << 12
	no_header_width        = 1 << 13
	prefer_sort_ascending  = 1 << 14
	prefer_sort_descending = 1 << 15
	indent_enable          = 1 << 16
	indent_disable         = 1 << 17
	angled_header          = 1 << 18
	is_enabled             = 1 << 24
	is_visible             = 1 << 25
	is_sorted              = 1 << 26
	is_hovered             = 1 << 27
	width_mask_            = 1 << 3 | 1 << 4
	indent_mask_           = 1 << 16 | 1 << 17
	status_mask_           = 1 << 24 | 1 << 25 | 1 << 26 | 1 << 27
	no_direct_resize_      = 1 << 30
}

pub enum TableRowFlags_ {
	none    = 0
	headers = 1 << 0
}

pub enum TableBgTarget_ {
	none    = 0
	row_bg0 = 1
	row_bg1 = 2
	cell_bg = 3
}

pub type TableSortSpecs = C.ImGuiTableSortSpecs

@[typedef]
pub struct C.ImGuiTableSortSpecs {
pub mut:
	Specs      &TableColumnSortSpecs
	SpecsCount i32
	SpecsDirty bool
}

pub type TableColumnSortSpecs = C.ImGuiTableColumnSortSpecs

@[typedef]
pub struct C.ImGuiTableColumnSortSpecs {
pub mut:
	ColumnUserID  ID
	ColumnIndex   ImS16
	SortOrder     ImS16
	SortDirection SortDirection
}

pub type Style = C.ImGuiStyle

@[typedef]
pub struct C.ImGuiStyle {
pub mut:
	FontSizeBase                     f32
	FontScaleMain                    f32
	FontScaleDpi                     f32
	Alpha                            f32
	DisabledAlpha                    f32
	WindowPadding                    ImVec2_c
	WindowRounding                   f32
	WindowBorderSize                 f32
	WindowBorderHoverPadding         f32
	WindowMinSize                    ImVec2_c
	WindowTitleAlign                 ImVec2_c
	WindowMenuButtonPosition         Dir
	ChildRounding                    f32
	ChildBorderSize                  f32
	PopupRounding                    f32
	PopupBorderSize                  f32
	FramePadding                     ImVec2_c
	FrameRounding                    f32
	FrameBorderSize                  f32
	ItemSpacing                      ImVec2_c
	ItemInnerSpacing                 ImVec2_c
	CellPadding                      ImVec2_c
	TouchExtraPadding                ImVec2_c
	IndentSpacing                    f32
	ColumnsMinSpacing                f32
	ScrollbarSize                    f32
	ScrollbarRounding                f32
	ScrollbarPadding                 f32
	GrabMinSize                      f32
	GrabRounding                     f32
	LogSliderDeadzone                f32
	ImageRounding                    f32
	ImageBorderSize                  f32
	TabRounding                      f32
	TabBorderSize                    f32
	TabMinWidthBase                  f32
	TabMinWidthShrink                f32
	TabCloseButtonMinWidthSelected   f32
	TabCloseButtonMinWidthUnselected f32
	TabBarBorderSize                 f32
	TabBarOverlineSize               f32
	TableAngledHeadersAngle          f32
	TableAngledHeadersTextAlign      ImVec2_c
	TreeLinesFlags                   TreeNodeFlags
	TreeLinesSize                    f32
	TreeLinesRounding                f32
	DragDropTargetRounding           f32
	DragDropTargetBorderSize         f32
	DragDropTargetPadding            f32
	ColorMarkerSize                  f32
	ColorButtonPosition              Dir
	ButtonTextAlign                  ImVec2_c
	SelectableTextAlign              ImVec2_c
	SeparatorSize                    f32
	SeparatorTextBorderSize          f32
	SeparatorTextAlign               ImVec2_c
	SeparatorTextPadding             ImVec2_c
	DisplayWindowPadding             ImVec2_c
	DisplaySafeAreaPadding           ImVec2_c
	DockingNodeHasCloseButton        bool
	DockingSeparatorSize             f32
	MouseCursorScale                 f32
	AntiAliasedLines                 bool
	AntiAliasedLinesUseTex           bool
	AntiAliasedFill                  bool
	CurveTessellationTol             f32
	CircleTessellationMaxError       f32
	Colors                           [62]imgui.ImVec4_c
	HoverStationaryDelay             f32
	HoverDelayShort                  f32
	HoverDelayNormal                 f32
	HoverFlagsForTooltipMouse        HoveredFlags
	HoverFlagsForTooltipNav          HoveredFlags
	_MainScale                       f32
	_NextFrameFontSizeBase           f32
}

pub type KeyData = C.ImGuiKeyData

@[typedef]
pub struct C.ImGuiKeyData {
pub mut:
	Down             bool
	DownDuration     f32
	DownDurationPrev f32
	AnalogValue      f32
}

pub type ImVector_ImWchar = C.ImVector_ImWchar

@[typedef]
pub struct C.ImVector_ImWchar {
pub mut:
	Size     i32
	Capacity i32
	Data     &ImWchar
}

pub type IO = C.ImGuiIO

@[typedef]
pub struct C.ImGuiIO {
pub mut:
	ConfigFlags                                   ConfigFlags
	BackendFlags                                  BackendFlags
	DisplaySize                                   ImVec2_c
	DisplayFramebufferScale                       ImVec2_c
	DeltaTime                                     f32
	IniSavingRate                                 f32
	IniFilename                                   &char
	LogFilename                                   &char
	UserData                                      voidptr
	Fonts                                         &ImFontAtlas
	FontDefault                                   &ImFont
	FontAllowUserScaling                          bool
	ConfigNavSwapGamepadButtons                   bool
	ConfigNavMoveSetMousePos                      bool
	ConfigNavCaptureKeyboard                      bool
	ConfigNavEscapeClearFocusItem                 bool
	ConfigNavEscapeClearFocusWindow               bool
	ConfigNavCursorVisibleAuto                    bool
	ConfigNavCursorVisibleAlways                  bool
	ConfigDockingNoSplit                          bool
	ConfigDockingNoDockingOver                    bool
	ConfigDockingWithShift                        bool
	ConfigDockingAlwaysTabBar                     bool
	ConfigDockingTransparentPayload               bool
	ConfigViewportsNoAutoMerge                    bool
	ConfigViewportsNoTaskBarIcon                  bool
	ConfigViewportsNoDecoration                   bool
	ConfigViewportsNoDefaultParent                bool
	ConfigViewportsPlatformFocusSetsImGuiFocus    bool
	ConfigDpiScaleFonts                           bool
	ConfigDpiScaleViewports                       bool
	MouseDrawCursor                               bool
	ConfigMacOSXBehaviors                         bool
	ConfigInputTrickleEventQueue                  bool
	ConfigInputTextCursorBlink                    bool
	ConfigInputTextEnterKeepActive                bool
	ConfigDragClickToInputText                    bool
	ConfigWindowsResizeFromEdges                  bool
	ConfigWindowsMoveFromTitleBarOnly             bool
	ConfigWindowsCopyContentsWithCtrlC            bool
	ConfigScrollbarScrollByPage                   bool
	ConfigMemoryCompactTimer                      f32
	MouseDoubleClickTime                          f32
	MouseDoubleClickMaxDist                       f32
	MouseDragThreshold                            f32
	KeyRepeatDelay                                f32
	KeyRepeatRate                                 f32
	ConfigErrorRecovery                           bool
	ConfigErrorRecoveryEnableAssert               bool
	ConfigErrorRecoveryEnableDebugLog             bool
	ConfigErrorRecoveryEnableTooltip              bool
	ConfigDebugIsDebuggerPresent                  bool
	ConfigDebugHighlightIdConflicts               bool
	ConfigDebugHighlightIdConflictsShowItemPicker bool
	ConfigDebugBeginReturnValueOnce               bool
	ConfigDebugBeginReturnValueLoop               bool
	ConfigDebugIgnoreFocusLoss                    bool
	ConfigDebugIniSettings                        bool
	BackendPlatformName                           &char
	BackendRendererName                           &char
	BackendPlatformUserData                       voidptr
	BackendRendererUserData                       voidptr
	BackendLanguageUserData                       voidptr
	WantCaptureMouse                              bool
	WantCaptureKeyboard                           bool
	WantTextInput                                 bool
	WantSetMousePos                               bool
	WantSaveIniSettings                           bool
	NavActive                                     bool
	NavVisible                                    bool
	Framerate                                     f32
	MetricsRenderVertices                         i32
	MetricsRenderIndices                          i32
	MetricsRenderWindows                          i32
	MetricsActiveWindows                          i32
	MouseDelta                                    ImVec2_c
	Ctx                                           &Context
	MousePos                                      ImVec2_c
	MouseDown                                     [5]bool
	MouseWheel                                    f32
	MouseWheelH                                   f32
	MouseSource                                   MouseSource
	MouseHoveredViewport                          ID
	KeyCtrl                                       bool
	KeyShift                                      bool
	KeyAlt                                        bool
	KeySuper                                      bool
	KeyMods                                       KeyChord
	KeysData                                      [155]KeyData
	WantCaptureMouseUnlessPopupClose              bool
	MousePosPrev                                  ImVec2_c
	MouseClickedPos                               [5]imgui.ImVec2_c
	MouseClickedTime                              [5]f64
	MouseClicked                                  [5]bool
	MouseDoubleClicked                            [5]bool
	MouseClickedCount                             [5]ImU16
	MouseClickedLastCount                         [5]ImU16
	MouseReleased                                 [5]bool
	MouseReleasedTime                             [5]f64
	MouseDownOwned                                [5]bool
	MouseDownOwnedUnlessPopupClose                [5]bool
	MouseWheelRequestAxisSwap                     bool
	MouseCtrlLeftAsRightClick                     bool
	MouseDownDuration                             [5]f32
	MouseDownDurationPrev                         [5]f32
	MouseDragMaxDistanceAbs                       [5]imgui.ImVec2_c
	MouseDragMaxDistanceSqr                       [5]f32
	PenPressure                                   f32
	AppFocusLost                                  bool
	AppAcceptingEvents                            bool
	InputQueueSurrogate                           ImWchar16
	InputQueueCharacters                          ImVector_ImWchar
}

pub type InputTextCallbackData = C.ImGuiInputTextCallbackData

@[typedef]
pub struct C.ImGuiInputTextCallbackData {
pub mut:
	Ctx            &Context
	EventFlag      InputTextFlags
	Flags          InputTextFlags
	UserData       voidptr
	ID             ID
	EventKey       Key
	EventChar      ImWchar
	EventActivated bool
	BufDirty       bool
	Buf            &char
	BufTextLen     i32
	BufSize        i32
	CursorPos      i32
	SelectionStart i32
	SelectionEnd   i32
}

pub type SizeCallbackData = C.ImGuiSizeCallbackData

@[typedef]
pub struct C.ImGuiSizeCallbackData {
pub mut:
	UserData    voidptr
	Pos         ImVec2_c
	CurrentSize ImVec2_c
	DesiredSize ImVec2_c
}

pub type WindowClass = C.ImGuiWindowClass

@[typedef]
pub struct C.ImGuiWindowClass {
pub mut:
	ClassId                    ID
	ParentViewportId           ID
	FocusRouteParentWindowId   ID
	ViewportFlagsOverrideSet   ViewportFlags
	ViewportFlagsOverrideClear ViewportFlags
	TabItemFlagsOverrideSet    TabItemFlags
	DockNodeFlagsOverrideSet   DockNodeFlags
	DockingAlwaysTabBar        bool
	DockingAllowUnclassed      bool
}

pub type Payload = C.ImGuiPayload

@[typedef]
pub struct C.ImGuiPayload {
pub mut:
	Data           voidptr
	DataSize       i32
	SourceId       ID
	SourceParentId ID
	DataFrameCount i32
	DataType       [33]i8
	Preview        bool
	Delivery       bool
}

pub type OnceUponAFrame = C.ImGuiOnceUponAFrame

@[typedef]
pub struct C.ImGuiOnceUponAFrame {
pub mut:
	RefFrame i32
}

pub type TextRange = C.ImGuiTextRange

@[typedef]
pub struct C.ImGuiTextRange {
pub mut:
	B &char
	E &char
}

pub type ImVector_TextRange = C.ImVector_ImGuiTextRange

@[typedef]
pub struct C.ImVector_ImGuiTextRange {
pub mut:
	Size     i32
	Capacity i32
	Data     &TextRange
}

pub type ImVector_char = C.ImVector_char

@[typedef]
pub struct C.ImVector_char {
pub mut:
	Size     i32
	Capacity i32
	Data     &char
}

pub type TextBuffer = C.ImGuiTextBuffer

@[typedef]
pub struct C.ImGuiTextBuffer {
pub mut:
	Buf ImVector_char
}

pub type StoragePair = C.ImGuiStoragePair

@[typedef]
pub struct C.ImGuiStoragePair {
pub mut:
	Key ID
}

pub type ImVector_StoragePair = C.ImVector_ImGuiStoragePair

@[typedef]
pub struct C.ImVector_ImGuiStoragePair {
pub mut:
	Size     i32
	Capacity i32
	Data     &StoragePair
}

pub type Storage = C.ImGuiStorage

@[typedef]
pub struct C.ImGuiStorage {
pub mut:
	Data ImVector_StoragePair
}

pub enum ListClipperFlags_ {
	none                      = 0
	no_set_table_row_counters = 1 << 0
}

pub type ListClipper = C.ImGuiListClipper

@[typedef]
pub struct C.ImGuiListClipper {
pub mut:
	DisplayStart     i32
	DisplayEnd       i32
	UserIndex        i32
	ItemsCount       i32
	ItemsHeight      f32
	Flags            ListClipperFlags
	StartPosY        f64
	StartSeekOffsetY f64
	Ctx              &Context
	TempData         voidptr
}

pub type ImColor_c = C.ImColor_c

@[typedef]
pub struct C.ImColor_c {
pub mut:
	Value ImVec4_c
}

pub enum MultiSelectFlags_ {
	none                      = 0
	single_select             = 1 << 0
	no_select_all             = 1 << 1
	no_range_select           = 1 << 2
	no_auto_select            = 1 << 3
	no_auto_clear             = 1 << 4
	no_auto_clear_on_reselect = 1 << 5
	box_select1d              = 1 << 6
	box_select2d              = 1 << 7
	box_select_no_scroll      = 1 << 8
	clear_on_escape           = 1 << 9
	clear_on_click_void       = 1 << 10
	scope_window              = 1 << 11
	scope_rect                = 1 << 12
	select_on_auto            = 1 << 13
	select_on_click_always    = 1 << 14
	select_on_click_release   = 1 << 15
	nav_wrap_x                = 1 << 16
	no_select_on_right_click  = 1 << 17
	select_on_mask_           = 1 << 13 | 1 << 14 | 1 << 15
}

pub type ImVector_SelectionRequest = C.ImVector_ImGuiSelectionRequest

@[typedef]
pub struct C.ImVector_ImGuiSelectionRequest {
pub mut:
	Size     i32
	Capacity i32
	Data     &SelectionRequest
}

pub type MultiSelectIO = C.ImGuiMultiSelectIO

@[typedef]
pub struct C.ImGuiMultiSelectIO {
pub mut:
	Requests      ImVector_SelectionRequest
	RangeSrcItem  SelectionUserData
	NavIdItem     SelectionUserData
	NavIdSelected bool
	RangeSrcReset bool
	ItemsCount    i32
}

pub enum SelectionRequestType {
	none = 0
	set_all
	set_range
}

pub type SelectionRequest = C.ImGuiSelectionRequest

@[typedef]
pub struct C.ImGuiSelectionRequest {
pub mut:
	Type           SelectionRequestType
	Selected       bool
	RangeDirection ImS8
	RangeFirstItem SelectionUserData
	RangeLastItem  SelectionUserData
}

pub type SelectionBasicStorage = C.ImGuiSelectionBasicStorage

@[typedef]
pub struct C.ImGuiSelectionBasicStorage {
pub mut:
	Size                    i32
	PreserveOrder           bool
	UserData                voidptr
	AdapterIndexToStorageId fn (&imgui.SelectionBasicStorage, i32) imgui.ID
	_SelectionOrder         i32
	_Storage                Storage
}

pub type SelectionExternalStorage = C.ImGuiSelectionExternalStorage

@[typedef]
pub struct C.ImGuiSelectionExternalStorage {
pub mut:
	UserData               voidptr
	AdapterSetItemSelected fn (&imgui.SelectionExternalStorage, i32, bool)
}

pub type ImDrawIdx = u16
pub type ImDrawCallback = fn (&ImDrawList, &ImDrawCmd)

pub type ImDrawCmd = C.ImDrawCmd

@[typedef]
pub struct C.ImDrawCmd {
pub mut:
	ClipRect               ImVec4_c
	TexRef                 ImTextureRef_c
	VtxOffset              u32
	IdxOffset              u32
	ElemCount              u32
	UserCallback           ImDrawCallback
	UserCallbackData       voidptr
	UserCallbackDataSize   i32
	UserCallbackDataOffset i32
}

pub type ImDrawVert = C.ImDrawVert

@[typedef]
pub struct C.ImDrawVert {
pub mut:
	pos ImVec2_c
	uv  ImVec2_c
	col ImU32
}

pub type ImDrawCmdHeader = C.ImDrawCmdHeader

@[typedef]
pub struct C.ImDrawCmdHeader {
pub mut:
	ClipRect  ImVec4_c
	TexRef    ImTextureRef_c
	VtxOffset u32
}

pub type ImVector_ImDrawCmd = C.ImVector_ImDrawCmd

@[typedef]
pub struct C.ImVector_ImDrawCmd {
pub mut:
	Size     i32
	Capacity i32
	Data     &ImDrawCmd
}

pub type ImVector_ImDrawIdx = C.ImVector_ImDrawIdx

@[typedef]
pub struct C.ImVector_ImDrawIdx {
pub mut:
	Size     i32
	Capacity i32
	Data     &ImDrawIdx
}

pub type ImDrawChannel = C.ImDrawChannel

@[typedef]
pub struct C.ImDrawChannel {
pub mut:
	_CmdBuffer ImVector_ImDrawCmd
	_IdxBuffer ImVector_ImDrawIdx
}

pub type ImVector_ImDrawChannel = C.ImVector_ImDrawChannel

@[typedef]
pub struct C.ImVector_ImDrawChannel {
pub mut:
	Size     i32
	Capacity i32
	Data     &ImDrawChannel
}

pub type ImDrawListSplitter = C.ImDrawListSplitter

@[typedef]
pub struct C.ImDrawListSplitter {
pub mut:
	_Current  i32
	_Count    i32
	_Channels ImVector_ImDrawChannel
}

pub enum ImDrawFlags_ {
	none                       = 0
	closed                     = 1 << 0
	round_corners_top_left     = 1 << 4
	round_corners_top_right    = 1 << 5
	round_corners_bottom_left  = 1 << 6
	round_corners_bottom_right = 1 << 7
	round_corners_none         = 1 << 8
	round_corners_top          = 1 << 4 | 1 << 5
	round_corners_bottom       = 1 << 6 | 1 << 7
	round_corners_left         = 1 << 4 | 1 << 6
	round_corners_right        = 1 << 5 | 1 << 7
	round_corners_all          = 1 << 4 | 1 << 5 | 1 << 6 | 1 << 7
	// round_corners_default_ = 1 << 4 | 1 << 5 | 1 << 6 | 1 << 7
	round_corners_mask_ = 1 << 4 | 1 << 5 | 1 << 6 | 1 << 7 | 1 << 8
}

pub enum ImDrawListFlags_ {
	none                       = 0
	anti_aliased_lines         = 1 << 0
	anti_aliased_lines_use_tex = 1 << 1
	anti_aliased_fill          = 1 << 2
	allow_vtx_offset           = 1 << 3
}

pub type ImVector_ImDrawVert = C.ImVector_ImDrawVert

@[typedef]
pub struct C.ImVector_ImDrawVert {
pub mut:
	Size     i32
	Capacity i32
	Data     &ImDrawVert
}

pub type ImVector_ImVec2 = C.ImVector_ImVec2

@[typedef]
pub struct C.ImVector_ImVec2 {
pub mut:
	Size     i32
	Capacity i32
	Data     &ImVec2_c
}

pub type ImVector_ImVec4 = C.ImVector_ImVec4

@[typedef]
pub struct C.ImVector_ImVec4 {
pub mut:
	Size     i32
	Capacity i32
	Data     &ImVec4_c
}

pub type ImVector_ImTextureRef = C.ImVector_ImTextureRef

@[typedef]
pub struct C.ImVector_ImTextureRef {
pub mut:
	Size     i32
	Capacity i32
	Data     &ImTextureRef_c
}

pub type ImVector_ImU8 = C.ImVector_ImU8

@[typedef]
pub struct C.ImVector_ImU8 {
pub mut:
	Size     i32
	Capacity i32
	Data     &ImU8
}

pub type ImDrawList = C.ImDrawList

@[typedef]
pub struct C.ImDrawList {
pub mut:
	CmdBuffer         ImVector_ImDrawCmd
	IdxBuffer         ImVector_ImDrawIdx
	VtxBuffer         ImVector_ImDrawVert
	Flags             ImDrawListFlags
	_VtxCurrentIdx    u32
	_Data             &ImDrawListSharedData
	_VtxWritePtr      &ImDrawVert
	_IdxWritePtr      &ImDrawIdx
	_Path             ImVector_ImVec2
	_CmdHeader        ImDrawCmdHeader
	_Splitter         ImDrawListSplitter
	_ClipRectStack    ImVector_ImVec4
	_TextureStack     ImVector_ImTextureRef
	_CallbacksDataBuf ImVector_ImU8
	_FringeScale      f32
	_OwnerName        &char
}

pub type ImVector_ImDrawListPtr = C.ImVector_ImDrawListPtr

@[typedef]
pub struct C.ImVector_ImDrawListPtr {
pub mut:
	Size     i32
	Capacity i32
	Data     &&ImDrawList
}

pub type ImVector_ImTextureDataPtr = C.ImVector_ImTextureDataPtr

@[typedef]
pub struct C.ImVector_ImTextureDataPtr {
pub mut:
	Size     i32
	Capacity i32
	Data     &&ImTextureData
}

pub type ImDrawData = C.ImDrawData

@[typedef]
pub struct C.ImDrawData {
pub mut:
	Valid            bool
	CmdListsCount    i32
	TotalIdxCount    i32
	TotalVtxCount    i32
	CmdLists         ImVector_ImDrawListPtr
	DisplayPos       ImVec2_c
	DisplaySize      ImVec2_c
	FramebufferScale ImVec2_c
	OwnerViewport    &Viewport
	Textures         &ImVector_ImTextureDataPtr
}

pub enum ImTextureFormat {
	rgba_32
	alpha8
}

pub enum ImTextureStatus {
	ok
	destroyed
	want_create
	want_updates
	want_destroy
}

pub type ImTextureRect = C.ImTextureRect

@[typedef]
pub struct C.ImTextureRect {
pub mut:
	X u16
	Y u16
	W u16
	H u16
}

pub type ImVector_ImTextureRect = C.ImVector_ImTextureRect

@[typedef]
pub struct C.ImVector_ImTextureRect {
pub mut:
	Size     i32
	Capacity i32
	Data     &ImTextureRect
}

pub type ImTextureData = C.ImTextureData

@[typedef]
pub struct C.ImTextureData {
pub mut:
	UniqueID             i32
	Status               ImTextureStatus
	BackendUserData      voidptr
	TexID                ImTextureID
	Format               ImTextureFormat
	Width                i32
	Height               i32
	BytesPerPixel        i32
	Pixels               &u8
	UsedRect             ImTextureRect
	UpdateRect           ImTextureRect
	Updates              ImVector_ImTextureRect
	UnusedFrames         i32
	RefCount             u16
	UseColors            bool
	WantDestroyNextFrame bool
}

pub type ImFontConfig = C.ImFontConfig

@[typedef]
pub struct C.ImFontConfig {
pub mut:
	Name                 [40]i8
	FontData             voidptr
	FontDataSize         i32
	FontDataOwnedByAtlas bool
	MergeMode            bool
	PixelSnapH           bool
	OversampleH          ImS8
	OversampleV          ImS8
	EllipsisChar         ImWchar
	SizePixels           f32
	GlyphRanges          &ImWchar
	GlyphExcludeRanges   &ImWchar
	GlyphOffset          ImVec2_c
	GlyphMinAdvanceX     f32
	GlyphMaxAdvanceX     f32
	GlyphExtraAdvanceX   f32
	FontNo               ImU32
	FontLoaderFlags      u32
	RasterizerMultiply   f32
	RasterizerDensity    f32
	ExtraSizeScale       f32
	Flags                ImFontFlags
	DstFont              &ImFont
	FontLoader           &ImFontLoader
	FontLoaderData       voidptr
}

pub type ImFontGlyph = C.ImFontGlyph

@[typedef]
pub struct C.ImFontGlyph {
pub mut:
	Colored   u32
	Visible   u32
	SourceIdx u32
	Codepoint u32
	AdvanceX  f32
	X0        f32
	Y0        f32
	X1        f32
	Y1        f32
	U0        f32
	V0        f32
	U1        f32
	V1        f32
	PackId    i32
}

pub type ImVector_ImU32 = C.ImVector_ImU32

@[typedef]
pub struct C.ImVector_ImU32 {
pub mut:
	Size     i32
	Capacity i32
	Data     &ImU32
}

pub type ImFontGlyphRangesBuilder = C.ImFontGlyphRangesBuilder

@[typedef]
pub struct C.ImFontGlyphRangesBuilder {
pub mut:
	UsedChars ImVector_ImU32
}

pub type ImFontAtlasRectId = i32

pub type ImFontAtlasRect = C.ImFontAtlasRect

@[typedef]
pub struct C.ImFontAtlasRect {
pub mut:
	X   u16
	Y   u16
	W   u16
	H   u16
	Uv0 ImVec2_c
	Uv1 ImVec2_c
}

pub enum ImFontAtlasFlags_ {
	none                   = 0
	no_power_of_two_height = 1 << 0
	no_mouse_cursors       = 1 << 1
	no_baked_lines         = 1 << 2
}

pub type ImVector_ImFontPtr = C.ImVector_ImFontPtr

@[typedef]
pub struct C.ImVector_ImFontPtr {
pub mut:
	Size     i32
	Capacity i32
	Data     &&ImFont
}

pub type ImVector_ImFontConfig = C.ImVector_ImFontConfig

@[typedef]
pub struct C.ImVector_ImFontConfig {
pub mut:
	Size     i32
	Capacity i32
	Data     &ImFontConfig
}

pub type ImVector_ImDrawListSharedDataPtr = C.ImVector_ImDrawListSharedDataPtr

@[typedef]
pub struct C.ImVector_ImDrawListSharedDataPtr {
pub mut:
	Size     i32
	Capacity i32
	Data     &&ImDrawListSharedData
}

pub type ImFontAtlas = C.ImFontAtlas

@[typedef]
pub struct C.ImFontAtlas {
pub mut:
	Flags               ImFontAtlasFlags
	TexDesiredFormat    ImTextureFormat
	TexGlyphPadding     i32
	TexMinWidth         i32
	TexMinHeight        i32
	TexMaxWidth         i32
	TexMaxHeight        i32
	UserData            voidptr
	TexRef              ImTextureRef_c
	TexData             &ImTextureData
	TexList             ImVector_ImTextureDataPtr
	Locked              bool
	RendererHasTextures bool
	TexIsBuilt          bool
	TexPixelsUseColors  bool
	TexUvScale          ImVec2_c
	TexUvWhitePixel     ImVec2_c
	Fonts               ImVector_ImFontPtr
	Sources             ImVector_ImFontConfig
	TexUvLines          [33]imgui.ImVec4_c
	TexNextUniqueID     i32
	FontNextUniqueID    i32
	DrawListSharedDatas ImVector_ImDrawListSharedDataPtr
	Builder             &ImFontAtlasBuilder
	FontLoader          &ImFontLoader
	FontLoaderName      &char
	FontLoaderData      voidptr
	FontLoaderFlags     u32
	RefCount            i32
	OwnerContext        &Context
}

pub type ImVector_float = C.ImVector_float

@[typedef]
pub struct C.ImVector_float {
pub mut:
	Size     i32
	Capacity i32
	Data     &f32
}

pub type ImVector_ImU16 = C.ImVector_ImU16

@[typedef]
pub struct C.ImVector_ImU16 {
pub mut:
	Size     i32
	Capacity i32
	Data     &ImU16
}

pub type ImVector_ImFontGlyph = C.ImVector_ImFontGlyph

@[typedef]
pub struct C.ImVector_ImFontGlyph {
pub mut:
	Size     i32
	Capacity i32
	Data     &ImFontGlyph
}

pub type ImFontBaked = C.ImFontBaked

@[typedef]
pub struct C.ImFontBaked {
pub mut:
	IndexAdvanceX        ImVector_float
	FallbackAdvanceX     f32
	Size                 f32
	RasterizerDensity    f32
	IndexLookup          ImVector_ImU16
	Glyphs               ImVector_ImFontGlyph
	FallbackGlyphIndex   i32
	Ascent               f32
	Descent              f32
	MetricsTotalSurface  u32
	WantDestroy          u32
	LoadNoFallback       u32
	LoadNoRenderOnLayout u32
	LastUsedFrame        i32
	BakedId              ID
	OwnerFont            &ImFont
	FontLoaderDatas      voidptr
}

pub enum ImFontFlags_ {
	none             = 0
	no_load_error    = 1 << 1
	no_load_glyphs   = 1 << 2
	lock_baked_sizes = 1 << 3
}

pub type ImVector_ImFontConfigPtr = C.ImVector_ImFontConfigPtr

@[typedef]
pub struct C.ImVector_ImFontConfigPtr {
pub mut:
	Size     i32
	Capacity i32
	Data     &&ImFontConfig
}

pub type ImFont = C.ImFont

@[typedef]
pub struct C.ImFont {
pub mut:
	LastBaked                &ImFontBaked
	OwnerAtlas               &ImFontAtlas
	Flags                    ImFontFlags
	CurrentRasterizerDensity f32
	FontId                   ID
	LegacySize               f32
	Sources                  ImVector_ImFontConfigPtr
	EllipsisChar             ImWchar
	FallbackChar             ImWchar
	Used8kPagesMap           [1]ImU8
	EllipsisAutoBake         bool
	RemapPairs               Storage
}

pub enum ViewportFlags_ {
	none                   = 0
	is_platform_window     = 1 << 0
	is_platform_monitor    = 1 << 1
	owned_by_app           = 1 << 2
	no_decoration          = 1 << 3
	no_task_bar_icon       = 1 << 4
	no_focus_on_appearing  = 1 << 5
	no_focus_on_click      = 1 << 6
	no_inputs              = 1 << 7
	no_renderer_clear      = 1 << 8
	no_auto_merge          = 1 << 9
	top_most               = 1 << 10
	can_host_other_windows = 1 << 11
	is_minimized           = 1 << 12
	is_focused             = 1 << 13
}

pub type Viewport = C.ImGuiViewport

@[typedef]
pub struct C.ImGuiViewport {
pub mut:
	ID                    ID
	Flags                 ViewportFlags
	Pos                   ImVec2_c
	Size                  ImVec2_c
	FramebufferScale      ImVec2_c
	WorkPos               ImVec2_c
	WorkSize              ImVec2_c
	DpiScale              f32
	ParentViewportId      ID
	ParentViewport        &Viewport
	DrawData              &ImDrawData
	RendererUserData      voidptr
	PlatformUserData      voidptr
	PlatformHandle        voidptr
	PlatformHandleRaw     voidptr
	PlatformWindowCreated bool
	PlatformRequestMove   bool
	PlatformRequestResize bool
	PlatformRequestClose  bool
}

pub type ImVector_PlatformMonitor = C.ImVector_ImGuiPlatformMonitor

@[typedef]
pub struct C.ImVector_ImGuiPlatformMonitor {
pub mut:
	Size     i32
	Capacity i32
	Data     &PlatformMonitor
}

pub type ImVector_ViewportPtr = C.ImVector_ImGuiViewportPtr

@[typedef]
pub struct C.ImVector_ImGuiViewportPtr {
pub mut:
	Size     i32
	Capacity i32
	Data     &&Viewport
}

pub type PlatformIO = C.ImGuiPlatformIO

@[typedef]
pub struct C.ImGuiPlatformIO {
pub mut:
	Platform_GetClipboardTextFn        fn (&imgui.Context) &char
	Platform_SetClipboardTextFn        fn (&imgui.Context, &char)
	Platform_ClipboardUserData         voidptr
	Platform_OpenInShellFn             fn (&imgui.Context, &char) bool
	Platform_OpenInShellUserData       voidptr
	Platform_SetImeDataFn              fn (&imgui.Context, &imgui.Viewport, &imgui.PlatformImeData)
	Platform_ImeUserData               voidptr
	Platform_LocaleDecimalPoint        ImWchar
	Renderer_TextureMaxWidth           i32
	Renderer_TextureMaxHeight          i32
	Renderer_RenderState               voidptr
	Platform_CreateWindow              fn (&imgui.Viewport)
	Platform_DestroyWindow             fn (&imgui.Viewport)
	Platform_ShowWindow                fn (&imgui.Viewport)
	Platform_SetWindowPos              fn (&imgui.Viewport, imgui.ImVec2_c)
	Platform_GetWindowPos              fn (&imgui.Viewport) imgui.ImVec2_c
	Platform_SetWindowSize             fn (&imgui.Viewport, imgui.ImVec2_c)
	Platform_GetWindowSize             fn (&imgui.Viewport) imgui.ImVec2_c
	Platform_GetWindowFramebufferScale fn (&imgui.Viewport) imgui.ImVec2_c
	Platform_SetWindowFocus            fn (&imgui.Viewport)
	Platform_GetWindowFocus            fn (&imgui.Viewport) bool
	Platform_GetWindowMinimized        fn (&imgui.Viewport) bool
	Platform_SetWindowTitle            fn (&imgui.Viewport, &char)
	Platform_SetWindowAlpha            fn (&imgui.Viewport, f32)
	Platform_UpdateWindow              fn (&imgui.Viewport)
	Platform_RenderWindow              fn (&imgui.Viewport, voidptr)
	Platform_SwapBuffers               fn (&imgui.Viewport, voidptr)
	Platform_GetWindowDpiScale         fn (&imgui.Viewport) f32
	Platform_OnChangedViewport         fn (&imgui.Viewport)
	Platform_GetWindowWorkAreaInsets   fn (&imgui.Viewport) imgui.ImVec4_c
	Platform_CreateVkSurface           fn (&imgui.Viewport, imgui.ImU64, voidptr, &imgui.ImU64) i32
	Renderer_CreateWindow              fn (&imgui.Viewport)
	Renderer_DestroyWindow             fn (&imgui.Viewport)
	Renderer_SetWindowSize             fn (&imgui.Viewport, imgui.ImVec2_c)
	Renderer_RenderWindow              fn (&imgui.Viewport, voidptr)
	Renderer_SwapBuffers               fn (&imgui.Viewport, voidptr)
	Monitors                           ImVector_PlatformMonitor
	Textures                           ImVector_ImTextureDataPtr
	Viewports                          ImVector_ViewportPtr
}

pub type PlatformMonitor = C.ImGuiPlatformMonitor

@[typedef]
pub struct C.ImGuiPlatformMonitor {
pub mut:
	MainPos        ImVec2_c
	MainSize       ImVec2_c
	WorkPos        ImVec2_c
	WorkSize       ImVec2_c
	DpiScale       f32
	PlatformHandle voidptr
}

pub type PlatformImeData = C.ImGuiPlatformImeData

@[typedef]
pub struct C.ImGuiPlatformImeData {
pub mut:
	WantVisible     bool
	WantTextInput   bool
	InputPos        ImVec2_c
	InputLineHeight f32
	ViewportId      ID
}

pub type DataAuthority = i32
pub type LayoutType = i32
pub type ActivateFlags = i32
pub type DebugLogFlags = i32
pub type FocusRequestFlags = i32
pub type ItemStatusFlags = i32
pub type OldColumnFlags = i32
pub type LogFlags = i32
pub type NavRenderCursorFlags = i32
pub type NavMoveFlags = i32
pub type NextItemDataFlags = i32
pub type NextWindowDataFlags = i32
pub type ScrollFlags = i32
pub type SeparatorFlags = i32
pub type TextFlags = i32
pub type TooltipFlags = i32
pub type TypingSelectFlags = i32
pub type WindowBgClickFlags = i32
pub type WindowRefreshFlags = i32
pub type TableColumnIdx = i16
pub type TableDrawChannelIdx = u16

pub enum ImDrawTextFlags_ {
	none             = 0
	cpu_fine_clip    = 1 << 0
	wrap_keep_blanks = 1 << 1
	stop_on_new_line = 1 << 2
}

pub enum ImWcharClass {
	blank
	punct
	other
}

pub type ImFileHandle = &C.FILE

pub type ImVec1 = C.ImVec1

@[typedef]
pub struct C.ImVec1 {
pub mut:
	X f32
}

pub type ImVec2i_c = C.ImVec2i_c

@[typedef]
pub struct C.ImVec2i_c {
pub mut:
	x i32
	y i32
}

pub type ImVec2ih = C.ImVec2ih

@[typedef]
pub struct C.ImVec2ih {
pub mut:
	X i16
	Y i16
}

pub type ImRect_c = C.ImRect_c

@[typedef]
pub struct C.ImRect_c {
pub mut:
	Min ImVec2_c
	Max ImVec2_c
}

pub type ImBitArrayPtr = &u32

pub type ImBitVector = C.ImBitVector

@[typedef]
pub struct C.ImBitVector {
pub mut:
	Storage ImVector_ImU32
}

pub type ImPoolIdx = i32

pub type ImVector_int = C.ImVector_int

@[typedef]
pub struct C.ImVector_int {
pub mut:
	Size     i32
	Capacity i32
	Data     &i32
}

pub type TextIndex = C.ImGuiTextIndex

@[typedef]
pub struct C.ImGuiTextIndex {
pub mut:
	Offsets   ImVector_int
	EndOffset i32
}

pub type ImDrawListSharedData = C.ImDrawListSharedData

@[typedef]
pub struct C.ImDrawListSharedData {
pub mut:
	TexUvWhitePixel       ImVec2_c
	TexUvLines            &ImVec4_c
	FontAtlas             &ImFontAtlas
	Font                  &ImFont
	FontSize              f32
	FontScale             f32
	CurveTessellationTol  f32
	CircleSegmentMaxError f32
	InitialFringeScale    f32
	InitialFlags          ImDrawListFlags
	ClipRectFullscreen    ImVec4_c
	TempBuffer            ImVector_ImVec2
	DrawLists             ImVector_ImDrawListPtr
	Context               &Context
	ArcFastVtx            [48]imgui.ImVec2_c
	ArcFastRadiusCutoff   f32
	CircleSegmentCounts   [64]ImU8
}

pub type ImDrawDataBuilder = C.ImDrawDataBuilder

@[typedef]
pub struct C.ImDrawDataBuilder {
pub mut:
	Layers     [2]&ImVector_ImDrawListPtr
	LayerData1 ImVector_ImDrawListPtr
}

pub type ImFontStackData = C.ImFontStackData

@[typedef]
pub struct C.ImFontStackData {
pub mut:
	Font                  &ImFont
	FontSizeBeforeScaling f32
	FontSizeAfterScaling  f32
}

pub type StyleVarInfo = C.ImGuiStyleVarInfo

@[typedef]
pub struct C.ImGuiStyleVarInfo {
pub mut:
	Count    ImU32
	DataType DataType
	Offset   ImU32
}

pub type ColorMod = C.ImGuiColorMod

@[typedef]
pub struct C.ImGuiColorMod {
pub mut:
	Col         Col
	BackupValue ImVec4_c
}

pub type StyleMod = C.ImGuiStyleMod

@[typedef]
pub struct C.ImGuiStyleMod {
pub mut:
	VarIdx StyleVar
}

pub type DataTypeStorage = C.ImGuiDataTypeStorage

@[typedef]
pub struct C.ImGuiDataTypeStorage {
pub mut:
	Data [8]ImU8
}

pub type DataTypeInfo = C.ImGuiDataTypeInfo

@[typedef]
pub struct C.ImGuiDataTypeInfo {
pub mut:
	Size     usize
	Name     &char
	PrintFmt &char
	ScanFmt  &char
}

pub enum DataTypePrivate_ {
	pointer = 12
	id
}

pub enum ItemFlagsPrivate_ {
	read_only                  = 1 << 11
	mixed_value                = 1 << 12
	no_window_hoverable_check  = 1 << 13
	allow_overlap              = 1 << 14
	no_nav_disable_mouse_hover = 1 << 15
	no_mark_edited             = 1 << 16
	no_focus                   = 1 << 17
	inputable                  = 1 << 20
	has_selection_user_data    = 1 << 21
	is_multi_select            = 1 << 22
	default_                   = 1 << 4
}

pub enum ItemStatusFlags_ {
	none              = 0
	hovered_rect      = 1 << 0
	has_display_rect  = 1 << 1
	edited            = 1 << 2
	toggled_selection = 1 << 3
	toggled_open      = 1 << 4
	has_deactivated   = 1 << 5
	deactivated       = 1 << 6
	hovered_window    = 1 << 7
	visible           = 1 << 8
	has_clip_rect     = 1 << 9
	has_shortcut      = 1 << 10
}

pub enum HoveredFlagsPrivate_ {
	delay_mask_                        = 1 << 14 | 1 << 15 | 1 << 16 | 1 << 17
	allowed_mask_for_is_window_hovered = 1 << 0 | 1 << 1 | 1 << 2 | 1 << 3 | 1 << 4 | 1 << 5 | 1 << 7 | 1 << 12 | 1 << 13
	allowed_mask_for_is_item_hovered   = 1 << 5 | 1 << 7 | 1 << 8 | 1 << 9 | 1 << 10 | 1 << 11 | 1 << 12 | 1 << 13 | 1 << 14 | 1 << 15 | 1 << 16 | 1 << 17
}

pub enum InputTextFlagsPrivate_ {
	multiline              = 1 << 26
	temp_input             = 1 << 27
	localize_decimal_point = 1 << 28
}

pub enum ButtonFlagsPrivate_ {
	pressed_on_click                  = 1 << 4
	pressed_on_click_release          = 1 << 5
	pressed_on_click_release_anywhere = 1 << 6
	pressed_on_release                = 1 << 7
	pressed_on_double_click           = 1 << 8
	pressed_on_drag_drop_hold         = 1 << 9
	flatten_children                  = 1 << 11
	align_text_base_line              = 1 << 15
	no_key_mods_allowed               = 1 << 16
	no_holding_active_id              = 1 << 17
	no_nav_focus                      = 1 << 18
	no_hovered_on_focus               = 1 << 19
	no_set_key_owner                  = 1 << 20
	no_test_key_owner                 = 1 << 21
	no_focus                          = 1 << 22
	pressed_on_mask_                  = 1 << 4 | 1 << 5 | 1 << 6 | 1 << 7 | 1 << 8 | 1 << 9
	// pressed_on_default_ = 1 << 5
}

pub enum ComboFlagsPrivate_ {
	custom_preview = 1 << 20
}

pub enum SliderFlagsPrivate_ {
	vertical  = 1 << 20
	read_only = 1 << 21
}

pub enum SelectableFlagsPrivate_ {
	no_holding_active_id     = 1 << 20
	select_on_click          = 1 << 22
	select_on_release        = 1 << 23
	span_avail_width         = 1 << 24
	set_nav_id_on_hover      = 1 << 25
	no_pad_with_half_spacing = 1 << 26
	no_set_key_owner         = 1 << 27
}

pub enum TreeNodeFlagsPrivate_ {
	no_nav_focus                   = 1 << 27
	clip_label_for_trailing_button = 1 << 28
	upside_down_arrow              = 1 << 29
	open_on_mask_                  = 1 << 6 | 1 << 7
	draw_lines_mask_               = 1 << 18 | 1 << 19 | 1 << 20
}

pub enum SeparatorFlags_ {
	none             = 0
	horizontal       = 1 << 0
	vertical         = 1 << 1
	span_all_columns = 1 << 2
}

pub enum FocusRequestFlags_ {
	none                  = 0
	restore_focused_child = 1 << 0
	unless_below_modal    = 1 << 1
}

pub enum TextFlags_ {
	none                            = 0
	no_width_for_large_clipped_text = 1 << 0
}

pub enum TooltipFlags_ {
	none              = 0
	override_previous = 1 << 1
}

pub enum LayoutType_ {
	horizontal = 0
	vertical   = 1
}

pub enum LogFlags_ {
	none             = 0
	output_tty       = 1 << 0
	output_file      = 1 << 1
	output_buffer    = 1 << 2
	output_clipboard = 1 << 3
	output_mask_     = 1 << 0 | 1 << 1 | 1 << 2 | 1 << 3
}

pub enum Axis {
	none = -1
	x    = 0
	y    = 1
}

pub enum PlotType {
	lines
	histogram
}

pub type ComboPreviewData = C.ImGuiComboPreviewData

@[typedef]
pub struct C.ImGuiComboPreviewData {
pub mut:
	PreviewRect                  ImRect_c
	BackupCursorPos              ImVec2_c
	BackupCursorMaxPos           ImVec2_c
	BackupCursorPosPrevLine      ImVec2_c
	BackupPrevLineTextBaseOffset f32
	BackupLayout                 LayoutType
}

pub type GroupData = C.ImGuiGroupData

@[typedef]
pub struct C.ImGuiGroupData {
pub mut:
	WindowID                             ID
	BackupCursorPos                      ImVec2_c
	BackupCursorMaxPos                   ImVec2_c
	BackupCursorPosPrevLine              ImVec2_c
	BackupIndent                         ImVec1
	BackupGroupOffset                    ImVec1
	BackupCurrLineSize                   ImVec2_c
	BackupCurrLineTextBaseOffset         f32
	BackupActiveIdIsAlive                ID
	BackupActiveIdHasBeenEditedThisFrame bool
	BackupDeactivatedIdIsAlive           bool
	BackupHoveredIdIsAlive               bool
	BackupIsSameLine                     bool
	EmitItem                             bool
}

pub type MenuColumns = C.ImGuiMenuColumns

@[typedef]
pub struct C.ImGuiMenuColumns {
pub mut:
	TotalWidth     ImU32
	NextTotalWidth ImU32
	Spacing        ImU16
	OffsetIcon     ImU16
	OffsetLabel    ImU16
	OffsetShortcut ImU16
	OffsetMark     ImU16
	Widths         [4]ImU16
}

pub type InputTextDeactivatedState = C.ImGuiInputTextDeactivatedState

@[typedef]
pub struct C.ImGuiInputTextDeactivatedState {
pub mut:
	ID    ID
	TextA ImVector_char
}

pub type ImStbTexteditState = C.STB_TexteditState

@[typedef]
pub struct C.STB_TexteditState {}

pub type InputTextState = C.ImGuiInputTextState

@[typedef]
pub struct C.ImGuiInputTextState {
pub mut:
	Ctx                  &Context
	Stb                  &ImStbTexteditState
	Flags                InputTextFlags
	ID                   ID
	TextLen              i32
	TextSrc              &char
	TextA                ImVector_char
	TextToRevertTo       ImVector_char
	CallbackTextBackup   ImVector_char
	BufCapacity          i32
	Scroll               ImVec2_c
	LineCount            i32
	WrapWidth            f32
	CursorAnim           f32
	CursorFollow         bool
	CursorCenterY        bool
	SelectedAllMouseLock bool
	EditedBefore         bool
	EditedThisFrame      bool
	WantReloadUserBuf    bool
	LastMoveDirectionLR  ImS8
	ReloadSelectionStart i32
	ReloadSelectionEnd   i32
}

pub enum WindowRefreshFlags_ {
	none                 = 0
	try_to_avoid_refresh = 1 << 0
	refresh_on_hover     = 1 << 1
	refresh_on_focus     = 1 << 2
}

pub enum WindowBgClickFlags_ {
	none = 0
	move = 1 << 0
}

pub enum NextWindowDataFlags_ {
	none                = 0
	has_pos             = 1 << 0
	has_size            = 1 << 1
	has_content_size    = 1 << 2
	has_collapsed       = 1 << 3
	has_size_constraint = 1 << 4
	has_focus           = 1 << 5
	has_bg_alpha        = 1 << 6
	has_scroll          = 1 << 7
	has_window_flags    = 1 << 8
	has_child_flags     = 1 << 9
	has_refresh_policy  = 1 << 10
	has_viewport        = 1 << 11
	has_dock            = 1 << 12
	has_window_class    = 1 << 13
}

pub type NextWindowData = C.ImGuiNextWindowData

@[typedef]
pub struct C.ImGuiNextWindowData {
pub mut:
	HasFlags             NextWindowDataFlags
	PosCond              Cond
	SizeCond             Cond
	CollapsedCond        Cond
	DockCond             Cond
	PosVal               ImVec2_c
	PosPivotVal          ImVec2_c
	SizeVal              ImVec2_c
	ContentSizeVal       ImVec2_c
	ScrollVal            ImVec2_c
	WindowFlags          WindowFlags
	ChildFlags           ChildFlags
	PosUndock            bool
	CollapsedVal         bool
	SizeConstraintRect   ImRect_c
	SizeCallback         SizeCallback
	SizeCallbackUserData voidptr
	BgAlphaVal           f32
	ViewportId           ID
	DockId               ID
	WindowClass          WindowClass
	MenuBarOffsetMinVal  ImVec2_c
	RefreshFlagsVal      WindowRefreshFlags
}

pub enum NextItemDataFlags_ {
	none             = 0
	has_width        = 1 << 0
	has_open         = 1 << 1
	has_shortcut     = 1 << 2
	has_ref_val      = 1 << 3
	has_storage_id   = 1 << 4
	has_color_marker = 1 << 5
}

pub type NextItemData = C.ImGuiNextItemData

@[typedef]
pub struct C.ImGuiNextItemData {
pub mut:
	HasFlags          NextItemDataFlags
	ItemFlags         ItemFlags
	FocusScopeId      ID
	SelectionUserData SelectionUserData
	Width             f32
	Shortcut          KeyChord
	ShortcutFlags     InputFlags
	OpenVal           bool
	OpenCond          ImU8
	RefVal            DataTypeStorage
	StorageId         ID
	ColorMarker       ImU32
}

pub type LastItemData = C.ImGuiLastItemData

@[typedef]
pub struct C.ImGuiLastItemData {
pub mut:
	ID          ID
	ItemFlags   ItemFlags
	StatusFlags ItemStatusFlags
	Rect        ImRect_c
	NavRect     ImRect_c
	DisplayRect ImRect_c
	ClipRect    ImRect_c
	Shortcut    KeyChord
}

pub type TreeNodeStackData = C.ImGuiTreeNodeStackData

@[typedef]
pub struct C.ImGuiTreeNodeStackData {
pub mut:
	ID                   ID
	TreeFlags            TreeNodeFlags
	ItemFlags            ItemFlags
	NavRect              ImRect_c
	DrawLinesX1          f32
	DrawLinesToNodesY2   f32
	DrawLinesTableColumn TableColumnIdx
}

pub type ErrorRecoveryState = C.ImGuiErrorRecoveryState

@[typedef]
pub struct C.ImGuiErrorRecoveryState {
pub mut:
	SizeOfWindowStack     i16
	SizeOfIDStack         i16
	SizeOfTreeStack       i16
	SizeOfColorStack      i16
	SizeOfStyleVarStack   i16
	SizeOfFontStack       i16
	SizeOfFocusScopeStack i16
	SizeOfGroupStack      i16
	SizeOfItemFlagsStack  i16
	SizeOfBeginPopupStack i16
	SizeOfDisabledStack   i16
}

pub type WindowStackData = C.ImGuiWindowStackData

@[typedef]
pub struct C.ImGuiWindowStackData {
pub mut:
	Window                              &Window
	ParentLastItemDataBackup            LastItemData
	StackSizesInBegin                   ErrorRecoveryState
	DisabledOverrideReenable            bool
	DisabledOverrideReenableAlphaBackup f32
}

pub type ShrinkWidthItem = C.ImGuiShrinkWidthItem

@[typedef]
pub struct C.ImGuiShrinkWidthItem {
pub mut:
	Index        i32
	Width        f32
	InitialWidth f32
}

pub type PtrOrIndex = C.ImGuiPtrOrIndex

@[typedef]
pub struct C.ImGuiPtrOrIndex {
pub mut:
	Ptr   voidptr
	Index i32
}

pub type DeactivatedItemData = C.ImGuiDeactivatedItemData

@[typedef]
pub struct C.ImGuiDeactivatedItemData {
pub mut:
	ID                  ID
	ElapseFrame         i32
	HasBeenEditedBefore bool
	IsAlive             bool
}

pub enum PopupPositionPolicy {
	default
	combo_box
	tooltip
}

pub type PopupData = C.ImGuiPopupData

@[typedef]
pub struct C.ImGuiPopupData {
pub mut:
	PopupId          ID
	Window           &Window
	RestoreNavWindow &Window
	ParentNavLayer   i32
	OpenFrameCount   i32
	OpenParentId     ID
	OpenPopupPos     ImVec2_c
	OpenMousePos     ImVec2_c
}

pub type ImBitArray_Key_NamedKey_COUNT__lessKey_NamedKey_BEGIN = C.ImBitArray_ImGuiKey_NamedKey_COUNT__lessImGuiKey_NamedKey_BEGIN

@[typedef]
pub struct C.ImBitArray_ImGuiKey_NamedKey_COUNT__lessImGuiKey_NamedKey_BEGIN {
pub mut:
	Data [5]ImU32
}

pub type ImBitArrayForNamedKeys = C.ImBitArray_ImGuiKey_NamedKey_COUNT__lessImGuiKey_NamedKey_BEGIN

pub enum InputEventType {
	none = 0
	mouse_pos
	mouse_wheel
	mouse_button
	mouse_viewport
	key
	text
	focus
	count
}

pub enum InputSource {
	none     = 0
	mouse    = 1
	keyboard = 2
	gamepad  = 3
	count    = 4
}

pub type InputEventMousePos = C.ImGuiInputEventMousePos

@[typedef]
pub struct C.ImGuiInputEventMousePos {
pub mut:
	PosX        f32
	PosY        f32
	MouseSource MouseSource
}

pub type InputEventMouseWheel = C.ImGuiInputEventMouseWheel

@[typedef]
pub struct C.ImGuiInputEventMouseWheel {
pub mut:
	WheelX      f32
	WheelY      f32
	MouseSource MouseSource
}

pub type InputEventMouseButton = C.ImGuiInputEventMouseButton

@[typedef]
pub struct C.ImGuiInputEventMouseButton {
pub mut:
	Button      i32
	Down        bool
	MouseSource MouseSource
}

pub type InputEventMouseViewport = C.ImGuiInputEventMouseViewport

@[typedef]
pub struct C.ImGuiInputEventMouseViewport {
pub mut:
	HoveredViewportID ID
}

pub type InputEventKey = C.ImGuiInputEventKey

@[typedef]
pub struct C.ImGuiInputEventKey {
pub mut:
	Key         Key
	Down        bool
	AnalogValue f32
}

pub type InputEventText = C.ImGuiInputEventText

@[typedef]
pub struct C.ImGuiInputEventText {
pub mut:
	Char u32
}

pub type InputEventAppFocused = C.ImGuiInputEventAppFocused

@[typedef]
pub struct C.ImGuiInputEventAppFocused {
pub mut:
	Focused bool
}

pub type InputEvent = C.ImGuiInputEvent

@[typedef]
pub struct C.ImGuiInputEvent {
pub mut:
	Type              InputEventType
	Source            InputSource
	EventId           ImU32
	AddedByTestEngine bool
}

pub type KeyRoutingIndex = i16

pub type KeyRoutingData = C.ImGuiKeyRoutingData

@[typedef]
pub struct C.ImGuiKeyRoutingData {
pub mut:
	NextEntryIndex   KeyRoutingIndex
	Mods             ImU16
	RoutingCurrScore ImU16
	RoutingNextScore ImU16
	RoutingCurr      ID
	RoutingNext      ID
}

pub type ImVector_KeyRoutingData = C.ImVector_ImGuiKeyRoutingData

@[typedef]
pub struct C.ImVector_ImGuiKeyRoutingData {
pub mut:
	Size     i32
	Capacity i32
	Data     &KeyRoutingData
}

pub type KeyRoutingTable = C.ImGuiKeyRoutingTable

@[typedef]
pub struct C.ImGuiKeyRoutingTable {
pub mut:
	Index       [155]KeyRoutingIndex
	Entries     ImVector_KeyRoutingData
	EntriesNext ImVector_KeyRoutingData
}

pub type KeyOwnerData = C.ImGuiKeyOwnerData

@[typedef]
pub struct C.ImGuiKeyOwnerData {
pub mut:
	OwnerCurr        ID
	OwnerNext        ID
	LockThisFrame    bool
	LockUntilRelease bool
}

pub enum InputFlagsPrivate_ {
	repeat_rate_default                    = 1 << 1
	repeat_rate_nav_move                   = 1 << 2
	repeat_rate_nav_tweak                  = 1 << 3
	repeat_until_release                   = 1 << 4
	repeat_until_key_mods_change           = 1 << 5
	repeat_until_key_mods_change_from_none = 1 << 6
	repeat_until_other_key_press           = 1 << 7
	lock_this_frame                        = 1 << 20
	lock_until_release                     = 1 << 21
	cond_hovered                           = 1 << 22
	cond_active                            = 1 << 23
	cond_default_                          = 1 << 22 | 1 << 23
	repeat_rate_mask_                      = 1 << 1 | 1 << 2 | 1 << 3
	repeat_until_mask_                     = 1 << 4 | 1 << 5 | 1 << 6 | 1 << 7
	repeat_mask_                           = 1 << 0 | 1 << 1 | 1 << 2 | 1 << 3 | 1 << 4 | 1 << 5 | 1 << 6 | 1 << 7
	// cond_mask_ = 1 << 22 | 1 << 23
	route_type_mask_    = 1 << 10 | 1 << 11 | 1 << 12 | 1 << 13
	route_options_mask_ = 1 << 14 | 1 << 15 | 1 << 16 | 1 << 17
	// supported_by_is_key_pressed = 1 << 0 | 1 << 1 | 1 << 2 | 1 << 3 | 1 << 4 | 1 << 5 | 1 << 6 | 1 << 7
	supported_by_is_mouse_clicked       = 1 << 0
	supported_by_shortcut               = 1 << 0 | 1 << 1 | 1 << 2 | 1 << 3 | 1 << 4 | 1 << 5 | 1 << 6 | 1 << 7 | 1 << 10 | 1 << 11 | 1 << 12 | 1 << 13 | 1 << 14 | 1 << 15 | 1 << 16 | 1 << 17
	supported_by_set_next_item_shortcut = 1 << 0 | 1 << 1 | 1 << 2 | 1 << 3 | 1 << 4 | 1 << 5 | 1 << 6 | 1 << 7 | 1 << 10 | 1 << 11 | 1 << 12 | 1 << 13 | 1 << 14 | 1 << 15 | 1 << 16 | 1 << 17 | 1 << 18
	supported_by_set_key_owner          = 1 << 20 | 1 << 21
	supported_by_set_item_key_owner     = 1 << 20 | 1 << 21 | 1 << 22 | 1 << 23
}

pub type ListClipperRange = C.ImGuiListClipperRange

@[typedef]
pub struct C.ImGuiListClipperRange {
pub mut:
	Min                 i32
	Max                 i32
	PosToIndexConvert   bool
	PosToIndexOffsetMin ImS8
	PosToIndexOffsetMax ImS8
}

pub type ImVector_ListClipperRange = C.ImVector_ImGuiListClipperRange

@[typedef]
pub struct C.ImVector_ImGuiListClipperRange {
pub mut:
	Size     i32
	Capacity i32
	Data     &ListClipperRange
}

pub type ListClipperData = C.ImGuiListClipperData

@[typedef]
pub struct C.ImGuiListClipperData {
pub mut:
	ListClipper     &ListClipper
	LossynessOffset f32
	StepNo          i32
	ItemsFrozen     i32
	Ranges          ImVector_ListClipperRange
}

pub enum ActivateFlags_ {
	none                  = 0
	prefer_input          = 1 << 0
	prefer_tweak          = 1 << 1
	try_to_preserve_state = 1 << 2
	from_tabbing          = 1 << 3
	from_shortcut         = 1 << 4
	from_focus_api        = 1 << 5
}

pub enum ScrollFlags_ {
	none                  = 0
	keep_visible_edge_x   = 1 << 0
	keep_visible_edge_y   = 1 << 1
	keep_visible_center_x = 1 << 2
	keep_visible_center_y = 1 << 3
	always_center_x       = 1 << 4
	always_center_y       = 1 << 5
	no_scroll_parent      = 1 << 6
	mask_x_               = 1 << 0 | 1 << 2 | 1 << 4
	mask_y_               = 1 << 1 | 1 << 3 | 1 << 5
}

pub enum NavRenderCursorFlags_ {
	none        = 0
	compact     = 1 << 1
	always_draw = 1 << 2
	no_rounding = 1 << 3
}

pub enum NavMoveFlags_ {
	none                      = 0
	loop_x                    = 1 << 0
	loop_y                    = 1 << 1
	wrap_x                    = 1 << 2
	wrap_y                    = 1 << 3
	wrap_mask_                = 1 << 0 | 1 << 1 | 1 << 2 | 1 << 3
	allow_current_nav_id      = 1 << 4
	also_score_visible_set    = 1 << 5
	scroll_to_edge_y          = 1 << 6
	forwarded                 = 1 << 7
	debug_no_result           = 1 << 8
	focus_api                 = 1 << 9
	is_tabbing                = 1 << 10
	is_page_move              = 1 << 11
	activate                  = 1 << 12
	no_select                 = 1 << 13
	no_set_nav_cursor_visible = 1 << 14
	no_clear_active_id        = 1 << 15
}

pub enum NavLayer {
	main = 0
	menu = 1
	count
}

pub type NavItemData = C.ImGuiNavItemData

@[typedef]
pub struct C.ImGuiNavItemData {
pub mut:
	Window            &Window
	ID                ID
	FocusScopeId      ID
	RectRel           ImRect_c
	ItemFlags         ItemFlags
	DistBox           f32
	DistCenter        f32
	DistAxial         f32
	SelectionUserData SelectionUserData
}

pub type FocusScopeData = C.ImGuiFocusScopeData

@[typedef]
pub struct C.ImGuiFocusScopeData {
pub mut:
	ID       ID
	WindowID ID
}

pub enum TypingSelectFlags_ {
	none                   = 0
	allow_backspace        = 1 << 0
	allow_single_char_mode = 1 << 1
}

pub type TypingSelectRequest = C.ImGuiTypingSelectRequest

@[typedef]
pub struct C.ImGuiTypingSelectRequest {
pub mut:
	Flags           TypingSelectFlags
	SearchBufferLen i32
	SearchBuffer    &char
	SelectRequest   bool
	SingleCharMode  bool
	SingleCharSize  ImS8
}

pub type TypingSelectState = C.ImGuiTypingSelectState

@[typedef]
pub struct C.ImGuiTypingSelectState {
pub mut:
	Request            TypingSelectRequest
	SearchBuffer       [64]i8
	FocusScope         ID
	LastRequestFrame   i32
	LastRequestTime    f32
	SingleCharModeLock bool
}

pub enum OldColumnFlags_ {
	none                      = 0
	no_border                 = 1 << 0
	no_resize                 = 1 << 1
	no_preserve_widths        = 1 << 2
	no_force_within_window    = 1 << 3
	grow_parent_contents_size = 1 << 4
}

pub type OldColumnData = C.ImGuiOldColumnData

@[typedef]
pub struct C.ImGuiOldColumnData {
pub mut:
	OffsetNorm             f32
	OffsetNormBeforeResize f32
	Flags                  OldColumnFlags
	ClipRect               ImRect_c
}

pub type ImVector_OldColumnData = C.ImVector_ImGuiOldColumnData

@[typedef]
pub struct C.ImVector_ImGuiOldColumnData {
pub mut:
	Size     i32
	Capacity i32
	Data     &OldColumnData
}

pub type OldColumns = C.ImGuiOldColumns

@[typedef]
pub struct C.ImGuiOldColumns {
pub mut:
	ID                       ID
	Flags                    OldColumnFlags
	IsFirstFrame             bool
	IsBeingResized           bool
	Current                  i32
	Count                    i32
	OffMinX                  f32
	OffMaxX                  f32
	LineMinY                 f32
	LineMaxY                 f32
	HostCursorPosY           f32
	HostCursorMaxPosX        f32
	HostInitialClipRect      ImRect_c
	HostBackupClipRect       ImRect_c
	HostBackupParentWorkRect ImRect_c
	Columns                  ImVector_OldColumnData
	Splitter                 ImDrawListSplitter
}

pub type BoxSelectState = C.ImGuiBoxSelectState

@[typedef]
pub struct C.ImGuiBoxSelectState {
pub mut:
	ID                    ID
	IsActive              bool
	IsStarting            bool
	IsStartedFromVoid     bool
	IsStartedSetNavIdOnce bool
	RequestClear          bool
	KeyMods               KeyChord
	StartPosRel           ImVec2_c
	EndPosRel             ImVec2_c
	ScrollAccum           ImVec2_c
	Window                &Window
	UnclipMode            bool
	UnclipRect            ImRect_c
	BoxSelectRectPrev     ImRect_c
	BoxSelectRectCurr     ImRect_c
}

pub type MultiSelectTempData = C.ImGuiMultiSelectTempData

@[typedef]
pub struct C.ImGuiMultiSelectTempData {
pub mut:
	IO                 MultiSelectIO
	Storage            &MultiSelectState
	FocusScopeId       ID
	Flags              MultiSelectFlags
	ScopeRectMin       ImVec2_c
	BackupCursorMaxPos ImVec2_c
	LastSubmittedItem  SelectionUserData
	BoxSelectId        ID
	KeyMods            KeyChord
	LoopRequestSetAll  ImS8
	IsEndIO            bool
	IsFocused          bool
	IsKeyboardSetRange bool
	NavIdPassedBy      bool
	RangeSrcPassedBy   bool
	RangeDstPassedBy   bool
}

pub type MultiSelectState = C.ImGuiMultiSelectState

@[typedef]
pub struct C.ImGuiMultiSelectState {
pub mut:
	Window            &Window
	ID                ID
	LastFrameActive   i32
	LastSelectionSize i32
	RangeSelected     ImS8
	NavIdSelected     ImS8
	RangeSrcItem      SelectionUserData
	NavIdItem         SelectionUserData
}

pub enum DockNodeFlagsPrivate_ {
	dock_space                    = 1 << 10
	central_node                  = 1 << 11
	no_tab_bar                    = 1 << 12
	hidden_tab_bar                = 1 << 13
	no_window_menu_button         = 1 << 14
	no_close_button               = 1 << 15
	no_resize_x                   = 1 << 16
	no_resize_y                   = 1 << 17
	docked_windows_in_focus_route = 1 << 18
	no_docking_split_other        = 1 << 19
	no_docking_over_me            = 1 << 20
	no_docking_over_other         = 1 << 21
	no_docking_over_empty         = 1 << 22
	no_docking                    = 1 << 4 | 1 << 19 | 1 << 20 | 1 << 21 | 1 << 22
	shared_flags_inherit_mask_    = -1
	no_resize_flags_mask_         = 1 << 5 | 1 << 16 | 1 << 17
	local_flags_transfer_mask_    = 1 << 4 | 1 << 5 | 1 << 6 | 1 << 11 | 1 << 12 | 1 << 13 | 1 << 14 | 1 << 15 | 1 << 16 | 1 << 17
	saved_flags_mask_             = 1 << 5 | 1 << 10 | 1 << 11 | 1 << 12 | 1 << 13 | 1 << 14 | 1 << 15 | 1 << 16 | 1 << 17
}

pub enum DataAuthority_ {
	auto
	dock_node
	window
}

pub enum DockNodeState {
	unknown
	host_window_hidden_because_single_window
	host_window_hidden_because_windows_are_resizing
	host_window_visible
}

pub type ImVector_WindowPtr = C.ImVector_ImGuiWindowPtr

@[typedef]
pub struct C.ImVector_ImGuiWindowPtr {
pub mut:
	Size     i32
	Capacity i32
	Data     &&Window
}

pub type DockNode = C.ImGuiDockNode

@[typedef]
pub struct C.ImGuiDockNode {
pub mut:
	ID                     ID
	SharedFlags            DockNodeFlags
	LocalFlags             DockNodeFlags
	LocalFlagsInWindows    DockNodeFlags
	MergedFlags            DockNodeFlags
	State                  DockNodeState
	ParentNode             &DockNode
	ChildNodes             [2]&imgui.DockNode
	Windows                ImVector_WindowPtr
	TabBar                 &TabBar
	Pos                    ImVec2_c
	Size                   ImVec2_c
	SizeRef                ImVec2_c
	SplitAxis              Axis
	WindowClass            WindowClass
	LastBgColor            ImU32
	HostWindow             &Window
	VisibleWindow          &Window
	CentralNode            &DockNode
	OnlyNodeWithWindows    &DockNode
	CountNodeWithWindows   i32
	LastFrameAlive         i32
	LastFrameActive        i32
	LastFrameFocused       i32
	LastFocusedNodeId      ID
	SelectedTabId          ID
	WantCloseTabId         ID
	RefViewportId          ID
	AuthorityForPos        DataAuthority
	AuthorityForSize       DataAuthority
	AuthorityForViewport   DataAuthority
	IsVisible              bool
	IsFocused              bool
	IsBgDrawnThisFrame     bool
	HasCloseButton         bool
	HasWindowMenuButton    bool
	HasCentralNodeChild    bool
	WantCloseAll           bool
	WantLockSizeOnce       bool
	WantMouseMove          bool
	WantHiddenTabBarUpdate bool
	WantHiddenTabBarToggle bool
}

pub enum WindowDockStyleCol {
	text
	tab_hovered
	tab_focused
	tab_selected
	tab_selected_overline
	tab_dimmed
	tab_dimmed_selected
	tab_dimmed_selected_overline
	unsaved_marker
	count
}

pub type WindowDockStyle = C.ImGuiWindowDockStyle

@[typedef]
pub struct C.ImGuiWindowDockStyle {
pub mut:
	Colors [9]ImU32
}

pub type ImVector_DockRequest = C.ImVector_ImGuiDockRequest

@[typedef]
pub struct C.ImVector_ImGuiDockRequest {
pub mut:
	Size     i32
	Capacity i32
	Data     &DockRequest
}

pub type ImVector_DockNodeSettings = C.ImVector_ImGuiDockNodeSettings

@[typedef]
pub struct C.ImVector_ImGuiDockNodeSettings {
pub mut:
	Size     i32
	Capacity i32
	Data     &DockNodeSettings
}

pub type DockContext = C.ImGuiDockContext

@[typedef]
pub struct C.ImGuiDockContext {
pub mut:
	Nodes           Storage
	Requests        ImVector_DockRequest
	NodesSettings   ImVector_DockNodeSettings
	WantFullRebuild bool
}

pub type ViewportP = C.ImGuiViewportP

@[typedef]
pub struct C.ImGuiViewportP {
pub mut:
	_ImGuiViewport              Viewport
	Window                      &Window
	Idx                         i32
	LastFrameActive             i32
	LastFocusedStampCount       i32
	LastNameHash                ID
	LastPos                     ImVec2_c
	LastSize                    ImVec2_c
	Alpha                       f32
	LastAlpha                   f32
	LastFocusedHadNavWindow     bool
	PlatformMonitor             i16
	BgFgDrawListsLastTimeActive [2]f32
	BgFgDrawLists               [2]&ImDrawList
	DrawDataP                   ImDrawData
	DrawDataBuilder             ImDrawDataBuilder
	LastPlatformPos             ImVec2_c
	LastPlatformSize            ImVec2_c
	LastRendererSize            ImVec2_c
	WorkInsetMin                ImVec2_c
	WorkInsetMax                ImVec2_c
	BuildWorkInsetMin           ImVec2_c
	BuildWorkInsetMax           ImVec2_c
}

pub type WindowSettings = C.ImGuiWindowSettings

@[typedef]
pub struct C.ImGuiWindowSettings {
pub mut:
	ID          ID
	Pos         ImVec2ih
	Size        ImVec2ih
	ViewportPos ImVec2ih
	ViewportId  ID
	DockId      ID
	ClassId     ID
	DockOrder   i16
	Collapsed   bool
	IsChild     bool
	WantApply   bool
	WantDelete  bool
}

pub type SettingsHandler = C.ImGuiSettingsHandler

@[typedef]
pub struct C.ImGuiSettingsHandler {
pub mut:
	TypeName   &char
	TypeHash   ID
	ClearAllFn fn (&imgui.Context, &imgui.SettingsHandler)
	ReadInitFn fn (&imgui.Context, &imgui.SettingsHandler)
	ReadOpenFn fn (&imgui.Context, &imgui.SettingsHandler, &char) voidptr
	ReadLineFn fn (&imgui.Context, &imgui.SettingsHandler, voidptr, &char)
	ApplyAllFn fn (&imgui.Context, &imgui.SettingsHandler)
	WriteAllFn fn (&imgui.Context, &imgui.SettingsHandler, &imgui.TextBuffer)
	UserData   voidptr
}

pub enum LocKey {
	version_str                         = 0
	table_size_one                      = 1
	table_size_all_fit                  = 2
	table_size_all_default              = 3
	table_reset_order                   = 4
	windowing_main_menu_bar             = 5
	windowing_popup                     = 6
	windowing_untitled                  = 7
	open_link_s                         = 8
	copy_link                           = 9
	docking_hide_tab_bar                = 10
	docking_hold_shift_to_dock          = 11
	docking_drag_to_undock_or_move_node = 12
	count                               = 13
}

pub type LocEntry = C.ImGuiLocEntry

@[typedef]
pub struct C.ImGuiLocEntry {
pub mut:
	Key  LocKey
	Text &char
}

pub type ErrorCallback = fn (&Context, voidptr, &char)

pub enum DebugLogFlags_ {
	none                  = 0
	event_error           = 1 << 0
	event_active_id       = 1 << 1
	event_focus           = 1 << 2
	event_popup           = 1 << 3
	event_nav             = 1 << 4
	event_clipper         = 1 << 5
	event_selection       = 1 << 6
	event_io              = 1 << 7
	event_font            = 1 << 8
	event_input_routing   = 1 << 9
	event_docking         = 1 << 10
	event_viewport        = 1 << 11
	event_mask_           = 1 << 0 | 1 << 1 | 1 << 2 | 1 << 3 | 1 << 4 | 1 << 5 | 1 << 6 | 1 << 7 | 1 << 8 | 1 << 9 | 1 << 10 | 1 << 11
	output_to_tty         = 1 << 20
	output_to_debugger    = 1 << 21
	output_to_test_engine = 1 << 22
}

pub type DebugAllocEntry = C.ImGuiDebugAllocEntry

@[typedef]
pub struct C.ImGuiDebugAllocEntry {
pub mut:
	FrameCount i32
	AllocCount ImS16
	FreeCount  ImS16
}

pub type DebugAllocInfo = C.ImGuiDebugAllocInfo

@[typedef]
pub struct C.ImGuiDebugAllocInfo {
pub mut:
	TotalAllocCount i32
	TotalFreeCount  i32
	LastEntriesIdx  ImS16
	LastEntriesBuf  [6]DebugAllocEntry
}

pub type MetricsConfig = C.ImGuiMetricsConfig

@[typedef]
pub struct C.ImGuiMetricsConfig {
pub mut:
	ShowDebugLog             bool
	ShowIDStackTool          bool
	ShowWindowsRects         bool
	ShowWindowsBeginOrder    bool
	ShowTablesRects          bool
	ShowDrawCmdMesh          bool
	ShowDrawCmdBoundingBoxes bool
	ShowTextEncodingViewer   bool
	ShowTextureUsedRect      bool
	ShowDockingNodes         bool
	ShowWindowsRectsType     i32
	ShowTablesRectsType      i32
	HighlightMonitorIdx      i32
	HighlightViewportID      ID
	ShowFontPreview          bool
}

pub type StackLevelInfo = C.ImGuiStackLevelInfo

@[typedef]
pub struct C.ImGuiStackLevelInfo {
pub mut:
	ID              ID
	QueryFrameCount ImS8
	QuerySuccess    bool
	DataType        ImS8
	DescOffset      i32
}

pub type ImVector_StackLevelInfo = C.ImVector_ImGuiStackLevelInfo

@[typedef]
pub struct C.ImVector_ImGuiStackLevelInfo {
pub mut:
	Size     i32
	Capacity i32
	Data     &StackLevelInfo
}

pub type DebugItemPathQuery = C.ImGuiDebugItemPathQuery

@[typedef]
pub struct C.ImGuiDebugItemPathQuery {
pub mut:
	MainID         ID
	Active         bool
	Complete       bool
	Step           ImS8
	Results        ImVector_StackLevelInfo
	ResultsDescBuf TextBuffer
	ResultPathBuf  TextBuffer
}

pub type IDStackTool = C.ImGuiIDStackTool

@[typedef]
pub struct C.ImGuiIDStackTool {
pub mut:
	OptHexEncodeNonAsciiChars bool
	OptCopyToClipboardOnCtrlC bool
	LastActiveFrame           i32
	CopyToClipboardLastTime   f32
}

pub type ContextHookCallback = fn (&Context, &ContextHook)

pub enum ContextHookType {
	new_frame_pre
	new_frame_post
	end_frame_pre
	end_frame_post
	render_pre
	render_post
	shutdown
	pending_removal_
}

pub type ContextHook = C.ImGuiContextHook

@[typedef]
pub struct C.ImGuiContextHook {
pub mut:
	HookId   ID
	Type     ContextHookType
	Owner    ID
	Callback ContextHookCallback
	UserData voidptr
}

pub type DemoMarkerCallback = fn (&char, i32, &char)

pub type ImVector_ImFontAtlasPtr = C.ImVector_ImFontAtlasPtr

@[typedef]
pub struct C.ImVector_ImFontAtlasPtr {
pub mut:
	Size     i32
	Capacity i32
	Data     &&ImFontAtlas
}

pub type ImVector_InputEvent = C.ImVector_ImGuiInputEvent

@[typedef]
pub struct C.ImVector_ImGuiInputEvent {
pub mut:
	Size     i32
	Capacity i32
	Data     &InputEvent
}

pub type ImVector_WindowStackData = C.ImVector_ImGuiWindowStackData

@[typedef]
pub struct C.ImVector_ImGuiWindowStackData {
pub mut:
	Size     i32
	Capacity i32
	Data     &WindowStackData
}

pub type ImVector_ColorMod = C.ImVector_ImGuiColorMod

@[typedef]
pub struct C.ImVector_ImGuiColorMod {
pub mut:
	Size     i32
	Capacity i32
	Data     &ColorMod
}

pub type ImVector_StyleMod = C.ImVector_ImGuiStyleMod

@[typedef]
pub struct C.ImVector_ImGuiStyleMod {
pub mut:
	Size     i32
	Capacity i32
	Data     &StyleMod
}

pub type ImVector_ImFontStackData = C.ImVector_ImFontStackData

@[typedef]
pub struct C.ImVector_ImFontStackData {
pub mut:
	Size     i32
	Capacity i32
	Data     &ImFontStackData
}

pub type ImVector_FocusScopeData = C.ImVector_ImGuiFocusScopeData

@[typedef]
pub struct C.ImVector_ImGuiFocusScopeData {
pub mut:
	Size     i32
	Capacity i32
	Data     &FocusScopeData
}

pub type ImVector_ItemFlags = C.ImVector_ImGuiItemFlags

@[typedef]
pub struct C.ImVector_ImGuiItemFlags {
pub mut:
	Size     i32
	Capacity i32
	Data     &ItemFlags
}

pub type ImVector_GroupData = C.ImVector_ImGuiGroupData

@[typedef]
pub struct C.ImVector_ImGuiGroupData {
pub mut:
	Size     i32
	Capacity i32
	Data     &GroupData
}

pub type ImVector_PopupData = C.ImVector_ImGuiPopupData

@[typedef]
pub struct C.ImVector_ImGuiPopupData {
pub mut:
	Size     i32
	Capacity i32
	Data     &PopupData
}

pub type ImVector_TreeNodeStackData = C.ImVector_ImGuiTreeNodeStackData

@[typedef]
pub struct C.ImVector_ImGuiTreeNodeStackData {
pub mut:
	Size     i32
	Capacity i32
	Data     &TreeNodeStackData
}

pub type ImVector_ViewportPPtr = C.ImVector_ImGuiViewportPPtr

@[typedef]
pub struct C.ImVector_ImGuiViewportPPtr {
pub mut:
	Size     i32
	Capacity i32
	Data     &&ViewportP
}

pub type ImVector_unsigned_char = C.ImVector_unsigned_char

@[typedef]
pub struct C.ImVector_unsigned_char {
pub mut:
	Size     i32
	Capacity i32
	Data     &u8
}

pub type ImVector_ListClipperData = C.ImVector_ImGuiListClipperData

@[typedef]
pub struct C.ImVector_ImGuiListClipperData {
pub mut:
	Size     i32
	Capacity i32
	Data     &ListClipperData
}

pub type ImVector_TableTempData = C.ImVector_ImGuiTableTempData

@[typedef]
pub struct C.ImVector_ImGuiTableTempData {
pub mut:
	Size     i32
	Capacity i32
	Data     &TableTempData
}

pub type ImVector_Table = C.ImVector_ImGuiTable

@[typedef]
pub struct C.ImVector_ImGuiTable {
pub mut:
	Size     i32
	Capacity i32
	Data     &Table
}

pub type ImPool_Table = C.ImPool_ImGuiTable

@[typedef]
pub struct C.ImPool_ImGuiTable {
pub mut:
	Buf        ImVector_Table
	Map        Storage
	FreeIdx    ImPoolIdx
	AliveCount ImPoolIdx
}

pub type ImVector_TabBar = C.ImVector_ImGuiTabBar

@[typedef]
pub struct C.ImVector_ImGuiTabBar {
pub mut:
	Size     i32
	Capacity i32
	Data     &TabBar
}

pub type ImPool_TabBar = C.ImPool_ImGuiTabBar

@[typedef]
pub struct C.ImPool_ImGuiTabBar {
pub mut:
	Buf        ImVector_TabBar
	Map        Storage
	FreeIdx    ImPoolIdx
	AliveCount ImPoolIdx
}

pub type ImVector_PtrOrIndex = C.ImVector_ImGuiPtrOrIndex

@[typedef]
pub struct C.ImVector_ImGuiPtrOrIndex {
pub mut:
	Size     i32
	Capacity i32
	Data     &PtrOrIndex
}

pub type ImVector_ShrinkWidthItem = C.ImVector_ImGuiShrinkWidthItem

@[typedef]
pub struct C.ImVector_ImGuiShrinkWidthItem {
pub mut:
	Size     i32
	Capacity i32
	Data     &ShrinkWidthItem
}

pub type ImVector_MultiSelectTempData = C.ImVector_ImGuiMultiSelectTempData

@[typedef]
pub struct C.ImVector_ImGuiMultiSelectTempData {
pub mut:
	Size     i32
	Capacity i32
	Data     &MultiSelectTempData
}

pub type ImVector_MultiSelectState = C.ImVector_ImGuiMultiSelectState

@[typedef]
pub struct C.ImVector_ImGuiMultiSelectState {
pub mut:
	Size     i32
	Capacity i32
	Data     &MultiSelectState
}

pub type ImPool_MultiSelectState = C.ImPool_ImGuiMultiSelectState

@[typedef]
pub struct C.ImPool_ImGuiMultiSelectState {
pub mut:
	Buf        ImVector_MultiSelectState
	Map        Storage
	FreeIdx    ImPoolIdx
	AliveCount ImPoolIdx
}

pub type ImVector_ID = C.ImVector_ImGuiID

@[typedef]
pub struct C.ImVector_ImGuiID {
pub mut:
	Size     i32
	Capacity i32
	Data     &ID
}

pub type ImVector_SettingsHandler = C.ImVector_ImGuiSettingsHandler

@[typedef]
pub struct C.ImVector_ImGuiSettingsHandler {
pub mut:
	Size     i32
	Capacity i32
	Data     &SettingsHandler
}

pub type ImChunkStream_WindowSettings = C.ImChunkStream_ImGuiWindowSettings

@[typedef]
pub struct C.ImChunkStream_ImGuiWindowSettings {
pub mut:
	Buf ImVector_char
}

pub type ImChunkStream_TableSettings = C.ImChunkStream_ImGuiTableSettings

@[typedef]
pub struct C.ImChunkStream_ImGuiTableSettings {
pub mut:
	Buf ImVector_char
}

pub type ImVector_ContextHook = C.ImVector_ImGuiContextHook

@[typedef]
pub struct C.ImVector_ImGuiContextHook {
pub mut:
	Size     i32
	Capacity i32
	Data     &ContextHook
}

pub type Context = C.ImGuiContext

@[typedef]
pub struct C.ImGuiContext {
pub mut:
	Initialized                        bool
	WithinFrameScope                   bool
	WithinFrameScopeWithImplicitWindow bool
	TestEngineHookItems                bool
	FrameCount                         i32
	FrameCountEnded                    i32
	FrameCountPlatformEnded            i32
	FrameCountRendered                 i32
	Time                               f64
	ContextName                        [16]i8
	IO                                 IO
	PlatformIO                         PlatformIO
	Style                              Style
	ConfigFlagsCurrFrame               ConfigFlags
	ConfigFlagsLastFrame               ConfigFlags
	FontAtlases                        ImVector_ImFontAtlasPtr
	Font                               &ImFont
	FontBaked                          &ImFontBaked
	FontSize                           f32
	FontSizeBase                       f32
	FontBakedScale                     f32
	FontRasterizerDensity              f32
	CurrentDpiScale                    f32
	DrawListSharedData                 ImDrawListSharedData
	WithinEndChildID                   ID
	TestEngine                         voidptr
	InputEventsQueue                   ImVector_InputEvent
	InputEventsTrail                   ImVector_InputEvent
	InputEventsNextMouseSource         MouseSource
	InputEventsNextEventId             ImU32
	Windows                            ImVector_WindowPtr
	WindowsFocusOrder                  ImVector_WindowPtr
	WindowsTempSortBuffer              ImVector_WindowPtr
	CurrentWindowStack                 ImVector_WindowStackData
	WindowsById                        Storage
	WindowsActiveCount                 i32
	WindowsBorderHoverPadding          f32
	DebugBreakInWindow                 ID
	CurrentWindow                      &Window
	HoveredWindow                      &Window
	HoveredWindowUnderMovingWindow     &Window
	HoveredWindowBeforeClear           &Window
	MovingWindow                       &Window
	WheelingWindow                     &Window
	WheelingWindowRefMousePos          ImVec2_c
	WheelingWindowStartFrame           i32
	WheelingWindowScrolledFrame        i32
	WheelingWindowReleaseTimer         f32
	WheelingWindowWheelRemainder       ImVec2_c
	WheelingAxisAvg                    ImVec2_c
	DebugDrawIdConflictsId             ID
	DebugHookIdInfoId                  ID
	HoveredId                          ID
	HoveredIdPreviousFrame             ID
	HoveredIdPreviousFrameItemCount    i32
	HoveredIdTimer                     f32
	HoveredIdNotActiveTimer            f32
	HoveredIdAllowOverlap              bool
	HoveredIdIsDisabled                bool
	ItemUnclipByLog                    bool
	ActiveId                           ID
	ActiveIdIsAlive                    ID
	ActiveIdTimer                      f32
	ActiveIdIsJustActivated            bool
	ActiveIdAllowOverlap               bool
	ActiveIdNoClearOnFocusLoss         bool
	ActiveIdHasBeenPressedBefore       bool
	ActiveIdHasBeenEditedBefore        bool
	ActiveIdHasBeenEditedThisFrame     bool
	ActiveIdFromShortcut               bool
	ActiveIdMouseButton                ImS8
	ActiveIdDisabledId                 ID
	ActiveIdClickOffset                ImVec2_c
	ActiveIdSource                     InputSource
	ActiveIdWindow                     &Window
	ActiveIdPreviousFrame              ID
	DeactivatedItemData                DeactivatedItemData
	ActiveIdValueOnActivation          DataTypeStorage
	LastActiveId                       ID
	LastActiveIdTimer                  f32
	LastKeyModsChangeTime              f64
	LastKeyModsChangeFromNoneTime      f64
	LastKeyboardKeyPressTime           f64
	KeysMayBeCharInput                 ImBitArrayForNamedKeys
	KeysOwnerData                      [155]KeyOwnerData
	KeysRoutingTable                   KeyRoutingTable
	ActiveIdUsingNavDirMask            ImU32
	ActiveIdUsingAllKeyboardKeys       bool
	DebugBreakInShortcutRouting        KeyChord
	CurrentFocusScopeId                ID
	CurrentItemFlags                   ItemFlags
	DebugLocateId                      ID
	NextItemData                       NextItemData
	LastItemData                       LastItemData
	NextWindowData                     NextWindowData
	DebugShowGroupRects                bool
	GcCompactAll                       bool
	DebugFlashStyleColorIdx            Col
	ColorStack                         ImVector_ColorMod
	StyleVarStack                      ImVector_StyleMod
	FontStack                          ImVector_ImFontStackData
	FocusScopeStack                    ImVector_FocusScopeData
	ItemFlagsStack                     ImVector_ItemFlags
	GroupStack                         ImVector_GroupData
	OpenPopupStack                     ImVector_PopupData
	BeginPopupStack                    ImVector_PopupData
	TreeNodeStack                      ImVector_TreeNodeStackData
	Viewports                          ImVector_ViewportPPtr
	CurrentViewport                    &ViewportP
	MouseViewport                      &ViewportP
	MouseLastHoveredViewport           &ViewportP
	PlatformLastFocusedViewportId      ID
	FallbackMonitor                    PlatformMonitor
	PlatformMonitorsFullWorkRect       ImRect_c
	ViewportCreatedCount               i32
	PlatformWindowsCreatedCount        i32
	ViewportFocusedStampCount          i32
	NavCursorVisible                   bool
	NavHighlightItemUnderNav           bool
	NavMousePosDirty                   bool
	NavIdIsAlive                       bool
	NavId                              ID
	NavWindow                          &Window
	NavFocusScopeId                    ID
	NavLayer                           NavLayer
	NavIdItemFlags                     ItemFlags
	NavActivateId                      ID
	NavActivateDownId                  ID
	NavActivatePressedId               ID
	NavActivateFlags                   ActivateFlags
	NavFocusRoute                      ImVector_FocusScopeData
	NavHighlightActivatedId            ID
	NavHighlightActivatedTimer         f32
	NavOpenContextMenuItemId           ID
	NavOpenContextMenuWindowId         ID
	NavNextActivateId                  ID
	NavNextActivateFlags               ActivateFlags
	NavInputSource                     InputSource
	NavLastValidSelectionUserData      SelectionUserData
	NavCursorHideFrames                ImS8
	NavAnyRequest                      bool
	NavInitRequest                     bool
	NavInitRequestFromMove             bool
	NavInitResult                      NavItemData
	NavMoveSubmitted                   bool
	NavMoveScoringItems                bool
	NavMoveForwardToNextFrame          bool
	NavMoveFlags                       NavMoveFlags
	NavMoveScrollFlags                 ScrollFlags
	NavMoveKeyMods                     KeyChord
	NavMoveDir                         Dir
	NavMoveDirForDebug                 Dir
	NavMoveClipDir                     Dir
	NavScoringRect                     ImRect_c
	NavScoringNoClipRect               ImRect_c
	NavScoringDebugCount               i32
	NavTabbingDir                      i32
	NavTabbingCounter                  i32
	NavMoveResultLocal                 NavItemData
	NavMoveResultLocalVisible          NavItemData
	NavMoveResultOther                 NavItemData
	NavTabbingResultFirst              NavItemData
	NavJustMovedFromFocusScopeId       ID
	NavJustMovedToId                   ID
	NavJustMovedToFocusScopeId         ID
	NavJustMovedToKeyMods              KeyChord
	NavJustMovedToIsTabbing            bool
	NavJustMovedToHasSelectionData     bool
	ConfigNavEnableTabbing             bool
	ConfigNavWindowingWithGamepad      bool
	ConfigNavWindowingKeyNext          KeyChord
	ConfigNavWindowingKeyPrev          KeyChord
	NavWindowingTarget                 &Window
	NavWindowingTargetAnim             &Window
	NavWindowingListWindow             &Window
	NavWindowingTimer                  f32
	NavWindowingHighlightAlpha         f32
	NavWindowingInputSource            InputSource
	NavWindowingToggleLayer            bool
	NavWindowingToggleKey              Key
	NavWindowingAccumDeltaPos          ImVec2_c
	NavWindowingAccumDeltaSize         ImVec2_c
	DimBgRatio                         f32
	DragDropActive                     bool
	DragDropWithinSource               bool
	DragDropWithinTarget               bool
	DragDropSourceFlags                DragDropFlags
	DragDropSourceFrameCount           i32
	DragDropMouseButton                i32
	DragDropPayload                    Payload
	DragDropTargetRect                 ImRect_c
	DragDropTargetClipRect             ImRect_c
	DragDropTargetId                   ID
	DragDropTargetFullViewport         ID
	DragDropAcceptFlagsCurr            DragDropFlags
	DragDropAcceptFlagsPrev            DragDropFlags
	DragDropAcceptIdCurrRectSurface    f32
	DragDropAcceptIdCurr               ID
	DragDropAcceptIdPrev               ID
	DragDropAcceptFrameCount           i32
	DragDropHoldJustPressedId          ID
	DragDropPayloadBufHeap             ImVector_unsigned_char
	DragDropPayloadBufLocal            [16]u8
	ClipperTempDataStacked             i32
	ClipperTempData                    ImVector_ListClipperData
	CurrentTable                       &Table
	DebugBreakInTable                  ID
	TablesTempDataStacked              i32
	TablesTempData                     ImVector_TableTempData
	Tables                             ImPool_Table
	TablesLastTimeActive               ImVector_float
	DrawChannelsTempMergeBuffer        ImVector_ImDrawChannel
	CurrentTabBar                      &TabBar
	TabBars                            ImPool_TabBar
	CurrentTabBarStack                 ImVector_PtrOrIndex
	ShrinkWidthBuffer                  ImVector_ShrinkWidthItem
	BoxSelectState                     BoxSelectState
	CurrentMultiSelect                 &MultiSelectTempData
	MultiSelectTempDataStacked         i32
	MultiSelectTempData                ImVector_MultiSelectTempData
	MultiSelectStorage                 ImPool_MultiSelectState
	HoverItemDelayId                   ID
	HoverItemDelayIdPreviousFrame      ID
	HoverItemDelayTimer                f32
	HoverItemDelayClearTimer           f32
	HoverItemUnlockedStationaryId      ID
	HoverWindowUnlockedStationaryId    ID
	MouseCursor                        MouseCursor
	MouseStationaryTimer               f32
	MouseLastValidPos                  ImVec2_c
	InputTextState                     InputTextState
	InputTextLineIndex                 TextIndex
	InputTextDeactivatedState          InputTextDeactivatedState
	InputTextPasswordFontBackupBaked   ImFontBaked
	InputTextPasswordFontBackupFlags   ImFontFlags
	InputTextReactivateId              ID
	TempInputId                        ID
	DataTypeZeroValue                  DataTypeStorage
	BeginMenuDepth                     i32
	BeginComboDepth                    i32
	ColorEditOptions                   ColorEditFlags
	ColorEditCurrentID                 ID
	ColorEditSavedID                   ID
	ColorEditSavedHue                  f32
	ColorEditSavedSat                  f32
	ColorEditSavedColor                ImU32
	ColorPickerRef                     ImVec4_c
	ComboPreviewData                   ComboPreviewData
	WindowResizeBorderExpectedRect     ImRect_c
	WindowResizeRelativeMode           bool
	ScrollbarSeekMode                  i16
	ScrollbarClickDeltaToGrabCenter    f32
	SliderGrabClickOffset              f32
	SliderCurrentAccum                 f32
	SliderCurrentAccumDirty            bool
	DragCurrentAccumDirty              bool
	DragCurrentAccum                   f32
	DragSpeedDefaultRatio              f32
	DisabledAlphaBackup                f32
	DisabledStackSize                  i16
	TooltipOverrideCount               i16
	TooltipPreviousWindow              &Window
	ClipboardHandlerData               ImVector_char
	MenusIdSubmittedThisFrame          ImVector_ID
	TypingSelectState                  TypingSelectState
	PlatformImeData                    PlatformImeData
	PlatformImeDataPrev                PlatformImeData
	UserTextures                       ImVector_ImTextureDataPtr
	DockContext                        DockContext
	DockNodeWindowMenuHandler          fn (&imgui.Context, &imgui.DockNode, &imgui.TabBar)
	SettingsLoaded                     bool
	SettingsDirtyTimer                 f32
	SettingsIniData                    TextBuffer
	SettingsHandlers                   ImVector_SettingsHandler
	SettingsWindows                    ImChunkStream_WindowSettings
	SettingsTables                     ImChunkStream_TableSettings
	Hooks                              ImVector_ContextHook
	HookIdNext                         ID
	DemoMarkerCallback                 DemoMarkerCallback
	LocalizationTable                  [13]&char
	LogEnabled                         bool
	LogLineFirstItem                   bool
	LogFlags                           LogFlags
	LogWindow                          &Window
	LogFile                            ImFileHandle
	LogBuffer                          TextBuffer
	LogNextPrefix                      &char
	LogNextSuffix                      &char
	LogLinePosY                        f32
	LogDepthRef                        i32
	LogDepthToExpand                   i32
	LogDepthToExpandDefault            i32
	ErrorCallback                      ErrorCallback
	ErrorCallbackUserData              voidptr
	ErrorTooltipLockedPos              ImVec2_c
	ErrorFirst                         bool
	ErrorCountCurrentFrame             i32
	StackSizesInNewFrame               ErrorRecoveryState
	StackSizesInBeginForCurrentWindow  &ErrorRecoveryState
	DebugDrawIdConflictsCount          i32
	DebugLogFlags                      DebugLogFlags
	DebugLogBuf                        TextBuffer
	DebugLogIndex                      TextIndex
	DebugLogSkippedErrors              i32
	DebugLogAutoDisableFlags           DebugLogFlags
	DebugLogAutoDisableFrames          ImU8
	DebugLocateFrames                  ImU8
	DebugBreakInLocateId               bool
	DebugBreakKeyChord                 KeyChord
	DebugBeginReturnValueCullDepth     ImS8
	DebugItemPickerActive              bool
	DebugItemPickerMouseButton         ImU8
	DebugItemPickerBreakId             ID
	DebugFlashStyleColorTime           f32
	DebugFlashStyleColorBackup         ImVec4_c
	DebugMetricsConfig                 MetricsConfig
	DebugItemPathQuery                 DebugItemPathQuery
	DebugIDStackTool                   IDStackTool
	DebugAllocInfo                     DebugAllocInfo
	DebugHoveredDockNode               &DockNode
	FramerateSecPerFrame               [60]f32
	FramerateSecPerFrameIdx            i32
	FramerateSecPerFrameCount          i32
	FramerateSecPerFrameAccum          f32
	WantCaptureMouseNextFrame          i32
	WantCaptureKeyboardNextFrame       i32
	WantTextInputNextFrame             i32
	TempBuffer                         ImVector_char
	TempKeychordName                   [64]i8
}

pub type WindowTempData = C.ImGuiWindowTempData

@[typedef]
pub struct C.ImGuiWindowTempData {
pub mut:
	CursorPos                     ImVec2_c
	CursorPosPrevLine             ImVec2_c
	CursorStartPos                ImVec2_c
	CursorMaxPos                  ImVec2_c
	IdealMaxPos                   ImVec2_c
	CurrLineSize                  ImVec2_c
	PrevLineSize                  ImVec2_c
	CurrLineTextBaseOffset        f32
	PrevLineTextBaseOffset        f32
	IsSameLine                    bool
	IsSetPos                      bool
	Indent                        ImVec1
	ColumnsOffset                 ImVec1
	GroupOffset                   ImVec1
	CursorStartPosLossyness       ImVec2_c
	NavLayerCurrent               NavLayer
	NavLayersActiveMask           i16
	NavLayersActiveMaskNext       i16
	NavIsScrollPushableX          bool
	NavHideHighlightOneFrame      bool
	NavWindowHasScrollY           bool
	MenuBarAppending              bool
	MenuBarOffset                 ImVec2_c
	MenuColumns                   MenuColumns
	TreeDepth                     i32
	TreeHasStackDataDepthMask     ImU32
	TreeRecordsClippedNodesY2Mask ImU32
	ChildWindows                  ImVector_WindowPtr
	StateStorage                  &Storage
	CurrentColumns                &OldColumns
	CurrentTableIdx               i32
	LayoutType                    LayoutType
	ParentLayoutType              LayoutType
	ModalDimBgColor               ImU32
	WindowItemStatusFlags         ItemStatusFlags
	ChildItemStatusFlags          ItemStatusFlags
	DockTabItemStatusFlags        ItemStatusFlags
	DockTabItemRect               ImRect_c
	ItemWidth                     f32
	ItemWidthDefault              f32
	TextWrapPos                   f32
	ItemWidthStack                ImVector_float
	TextWrapPosStack              ImVector_float
}

pub type ImVector_OldColumns = C.ImVector_ImGuiOldColumns

@[typedef]
pub struct C.ImVector_ImGuiOldColumns {
pub mut:
	Size     i32
	Capacity i32
	Data     &OldColumns
}

pub type Window = C.ImGuiWindow

@[typedef]
pub struct C.ImGuiWindow {
pub mut:
	Ctx                                &Context
	Name                               &char
	ID                                 ID
	Flags                              WindowFlags
	FlagsPreviousFrame                 WindowFlags
	ChildFlags                         ChildFlags
	WindowClass                        WindowClass
	Viewport                           &ViewportP
	ViewportId                         ID
	ViewportPos                        ImVec2_c
	ViewportAllowPlatformMonitorExtend i32
	Pos                                ImVec2_c
	Size                               ImVec2_c
	SizeFull                           ImVec2_c
	ContentSize                        ImVec2_c
	ContentSizeIdeal                   ImVec2_c
	ContentSizeExplicit                ImVec2_c
	WindowPadding                      ImVec2_c
	WindowRounding                     f32
	WindowBorderSize                   f32
	TitleBarHeight                     f32
	MenuBarHeight                      f32
	DecoOuterSizeX1                    f32
	DecoOuterSizeY1                    f32
	DecoOuterSizeX2                    f32
	DecoOuterSizeY2                    f32
	DecoInnerSizeX1                    f32
	DecoInnerSizeY1                    f32
	NameBufLen                         i32
	MoveId                             ID
	TabId                              ID
	ChildId                            ID
	PopupId                            ID
	Scroll                             ImVec2_c
	ScrollMax                          ImVec2_c
	ScrollTarget                       ImVec2_c
	ScrollTargetCenterRatio            ImVec2_c
	ScrollTargetEdgeSnapDist           ImVec2_c
	ScrollbarSizes                     ImVec2_c
	ScrollbarX                         bool
	ScrollbarY                         bool
	ScrollbarXStabilizeEnabled         bool
	ScrollbarXStabilizeToggledHistory  ImU8
	ViewportOwned                      bool
	Active                             bool
	WasActive                          bool
	WriteAccessed                      bool
	Collapsed                          bool
	WantCollapseToggle                 bool
	SkipItems                          bool
	SkipRefresh                        bool
	Appearing                          bool
	Hidden                             bool
	IsFallbackWindow                   bool
	IsExplicitChild                    bool
	HasCloseButton                     bool
	ResizeBorderHovered                i8
	ResizeBorderHeld                   i8
	BeginCount                         i16
	BeginCountPreviousFrame            i16
	BeginOrderWithinParent             i16
	BeginOrderWithinContext            i16
	FocusOrder                         i16
	AutoPosLastDirection               Dir
	AutoFitFramesX                     ImS8
	AutoFitFramesY                     ImS8
	AutoFitOnlyGrows                   bool
	HiddenFramesCanSkipItems           ImS8
	HiddenFramesCannotSkipItems        ImS8
	HiddenFramesForRenderOnly          ImS8
	DisableInputsFrames                ImS8
	BgClickFlags                       WindowBgClickFlags
	SetWindowPosAllowFlags             Cond
	SetWindowSizeAllowFlags            Cond
	SetWindowCollapsedAllowFlags       Cond
	SetWindowDockAllowFlags            Cond
	SetWindowPosVal                    ImVec2_c
	SetWindowPosPivot                  ImVec2_c
	IDStack                            ImVector_ID
	DC                                 WindowTempData
	OuterRectClipped                   ImRect_c
	InnerRect                          ImRect_c
	InnerClipRect                      ImRect_c
	WorkRect                           ImRect_c
	ParentWorkRect                     ImRect_c
	ClipRect                           ImRect_c
	ContentRegionRect                  ImRect_c
	HitTestHoleSize                    ImVec2ih
	HitTestHoleOffset                  ImVec2ih
	LastFrameActive                    i32
	LastFrameJustFocused               i32
	LastTimeActive                     f32
	StateStorage                       Storage
	ColumnsStorage                     ImVector_OldColumns
	FontWindowScale                    f32
	FontWindowScaleParents             f32
	FontRefSize                        f32
	SettingsOffset                     i32
	DrawList                           &ImDrawList
	DrawListInst                       ImDrawList
	ParentWindow                       &Window
	ParentWindowInBeginStack           &Window
	RootWindow                         &Window
	RootWindowPopupTree                &Window
	RootWindowDockTree                 &Window
	RootWindowForTitleBarHighlight     &Window
	RootWindowForNav                   &Window
	ParentWindowForFocusRoute          &Window
	NavLastChildNavWindow              &Window
	NavLastIds                         [2]imgui.ID
	NavRectRel                         [2]ImRect_c
	NavPreferredScoringPosRel          [2]imgui.ImVec2_c
	NavRootFocusScopeId                ID
	MemoryDrawListIdxCapacity          i32
	MemoryDrawListVtxCapacity          i32
	MemoryCompacted                    bool
	DockIsActive                       bool
	DockNodeIsVisible                  bool
	DockTabIsVisible                   bool
	DockTabWantClose                   bool
	DockOrder                          i16
	DockStyle                          WindowDockStyle
	DockNode                           &DockNode
	DockNodeAsHost                     &DockNode
	DockId                             ID
}

pub enum TabBarFlagsPrivate_ {
	dock_node     = 1 << 20
	is_focused    = 1 << 21
	save_settings = 1 << 22
}

pub enum TabItemFlagsPrivate_ {
	section_mask_   = 1 << 6 | 1 << 7
	no_close_button = 1 << 20
	button          = 1 << 21
	invisible       = 1 << 22
	unsorted        = 1 << 23
}

pub type TabItem = C.ImGuiTabItem

@[typedef]
pub struct C.ImGuiTabItem {
pub mut:
	ID                ID
	Flags             TabItemFlags
	Window            &Window
	LastFrameVisible  i32
	LastFrameSelected i32
	Offset            f32
	Width             f32
	ContentWidth      f32
	RequestedWidth    f32
	NameOffset        ImS32
	BeginOrder        ImS16
	IndexDuringLayout ImS16
	WantClose         bool
}

pub type ImVector_TabItem = C.ImVector_ImGuiTabItem

@[typedef]
pub struct C.ImVector_ImGuiTabItem {
pub mut:
	Size     i32
	Capacity i32
	Data     &TabItem
}

pub type TabBar = C.ImGuiTabBar

@[typedef]
pub struct C.ImGuiTabBar {
pub mut:
	Window                          &Window
	Tabs                            ImVector_TabItem
	Flags                           TabBarFlags
	ID                              ID
	SelectedTabId                   ID
	NextSelectedTabId               ID
	NextScrollToTabId               ID
	VisibleTabId                    ID
	CurrFrameVisible                i32
	PrevFrameVisible                i32
	BarRect                         ImRect_c
	BarRectPrevWidth                f32
	CurrTabsContentsHeight          f32
	PrevTabsContentsHeight          f32
	WidthAllTabs                    f32
	WidthAllTabsIdeal               f32
	ScrollingAnim                   f32
	ScrollingTarget                 f32
	ScrollingTargetDistToVisibility f32
	ScrollingSpeed                  f32
	ScrollingRectMinX               f32
	ScrollingRectMaxX               f32
	SeparatorMinX                   f32
	SeparatorMaxX                   f32
	ReorderRequestTabId             ID
	ReorderRequestOffset            ImS16
	BeginCount                      ImS8
	WantLayout                      bool
	VisibleTabWasSubmitted          bool
	TabsAddedNew                    bool
	ScrollButtonEnabled             bool
	TabsActiveCount                 ImS16
	LastTabItemIdx                  ImS16
	ItemSpacingY                    f32
	FramePadding                    ImVec2_c
	BackupCursorPos                 ImVec2_c
	TabsNames                       TextBuffer
}

pub type TableColumn = C.ImGuiTableColumn

@[typedef]
pub struct C.ImGuiTableColumn {
pub mut:
	Flags                    TableColumnFlags
	WidthGiven               f32
	MinX                     f32
	MaxX                     f32
	WidthRequest             f32
	WidthAuto                f32
	WidthMax                 f32
	StretchWeight            f32
	InitStretchWeightOrWidth f32
	ClipRect                 ImRect_c
	UserID                   ID
	WorkMinX                 f32
	WorkMaxX                 f32
	ItemWidth                f32
	ContentMaxXFrozen        f32
	ContentMaxXUnfrozen      f32
	ContentMaxXHeadersUsed   f32
	ContentMaxXHeadersIdeal  f32
	NameOffset               ImS16
	DisplayOrder             TableColumnIdx
	IndexWithinEnabledSet    TableColumnIdx
	PrevEnabledColumn        TableColumnIdx
	NextEnabledColumn        TableColumnIdx
	SortOrder                TableColumnIdx
	DrawChannelCurrent       TableDrawChannelIdx
	DrawChannelFrozen        TableDrawChannelIdx
	DrawChannelUnfrozen      TableDrawChannelIdx
	IsEnabled                bool
	IsUserEnabled            bool
	IsUserEnabledNextFrame   bool
	IsVisibleX               bool
	IsVisibleY               bool
	IsRequestOutput          bool
	IsSkipItems              bool
	IsPreserveWidthAuto      bool
	NavLayerCurrent          ImS8
	AutoFitQueue             ImU8
	CannotSkipItemsQueue     ImU8
	SortDirection            ImU8
	SortDirectionsAvailCount ImU8
	SortDirectionsAvailMask  ImU8
	SortDirectionsAvailList  ImU8
}

pub type TableCellData = C.ImGuiTableCellData

@[typedef]
pub struct C.ImGuiTableCellData {
pub mut:
	BgColor ImU32
	Column  TableColumnIdx
}

pub type TableHeaderData = C.ImGuiTableHeaderData

@[typedef]
pub struct C.ImGuiTableHeaderData {
pub mut:
	Index     TableColumnIdx
	TextColor ImU32
	BgColor0  ImU32
	BgColor1  ImU32
}

pub type TableInstanceData = C.ImGuiTableInstanceData

@[typedef]
pub struct C.ImGuiTableInstanceData {
pub mut:
	TableInstanceID         ID
	LastOuterHeight         f32
	LastTopHeadersRowHeight f32
	LastFrozenHeight        f32
	HoveredRowLast          i32
	HoveredRowNext          i32
}

pub type ImSpan_TableColumn = C.ImSpan_ImGuiTableColumn

@[typedef]
pub struct C.ImSpan_ImGuiTableColumn {
pub mut:
	Data    &TableColumn
	DataEnd &TableColumn
}

pub type ImSpan_TableColumnIdx = C.ImSpan_ImGuiTableColumnIdx

@[typedef]
pub struct C.ImSpan_ImGuiTableColumnIdx {
pub mut:
	Data    &TableColumnIdx
	DataEnd &TableColumnIdx
}

pub type ImSpan_TableCellData = C.ImSpan_ImGuiTableCellData

@[typedef]
pub struct C.ImSpan_ImGuiTableCellData {
pub mut:
	Data    &TableCellData
	DataEnd &TableCellData
}

pub type ImVector_TableInstanceData = C.ImVector_ImGuiTableInstanceData

@[typedef]
pub struct C.ImVector_ImGuiTableInstanceData {
pub mut:
	Size     i32
	Capacity i32
	Data     &TableInstanceData
}

pub type ImVector_TableColumnSortSpecs = C.ImVector_ImGuiTableColumnSortSpecs

@[typedef]
pub struct C.ImVector_ImGuiTableColumnSortSpecs {
pub mut:
	Size     i32
	Capacity i32
	Data     &TableColumnSortSpecs
}

pub type Table = C.ImGuiTable

@[typedef]
pub struct C.ImGuiTable {
pub mut:
	ID                         ID
	Flags                      TableFlags
	RawData                    voidptr
	TempData                   &TableTempData
	Columns                    ImSpan_TableColumn
	DisplayOrderToIndex        ImSpan_TableColumnIdx
	RowCellData                ImSpan_TableCellData
	EnabledMaskByDisplayOrder  ImBitArrayPtr
	EnabledMaskByIndex         ImBitArrayPtr
	VisibleMaskByIndex         ImBitArrayPtr
	SettingsLoadedFlags        TableFlags
	SettingsOffset             i32
	LastFrameActive            i32
	ColumnsCount               i32
	CurrentRow                 i32
	CurrentColumn              i32
	InstanceCurrent            ImS16
	InstanceInteracted         ImS16
	RowPosY1                   f32
	RowPosY2                   f32
	RowMinHeight               f32
	RowCellPaddingY            f32
	RowTextBaseline            f32
	RowIndentOffsetX           f32
	RowFlags                   TableRowFlags
	LastRowFlags               TableRowFlags
	RowBgColorCounter          i32
	RowBgColor                 [2]ImU32
	BorderColorStrong          ImU32
	BorderColorLight           ImU32
	BorderX1                   f32
	BorderX2                   f32
	HostIndentX                f32
	MinColumnWidth             f32
	OuterPaddingX              f32
	CellPaddingX               f32
	CellSpacingX1              f32
	CellSpacingX2              f32
	InnerWidth                 f32
	ColumnsGivenWidth          f32
	ColumnsAutoFitWidth        f32
	ColumnsStretchSumWeights   f32
	ResizedColumnNextWidth     f32
	ResizeLockMinContentsX2    f32
	RefScale                   f32
	AngledHeadersHeight        f32
	AngledHeadersSlope         f32
	OuterRect                  ImRect_c
	InnerRect                  ImRect_c
	WorkRect                   ImRect_c
	InnerClipRect              ImRect_c
	BgClipRect                 ImRect_c
	Bg0ClipRectForDrawCmd      ImRect_c
	Bg2ClipRectForDrawCmd      ImRect_c
	HostClipRect               ImRect_c
	HostBackupInnerClipRect    ImRect_c
	OuterWindow                &Window
	InnerWindow                &Window
	ColumnsNames               TextBuffer
	DrawSplitter               &ImDrawListSplitter
	InstanceDataFirst          TableInstanceData
	InstanceDataExtra          ImVector_TableInstanceData
	SortSpecsSingle            TableColumnSortSpecs
	SortSpecsMulti             ImVector_TableColumnSortSpecs
	SortSpecs                  TableSortSpecs
	SortSpecsCount             TableColumnIdx
	ColumnsEnabledCount        TableColumnIdx
	ColumnsEnabledFixedCount   TableColumnIdx
	DeclColumnsCount           TableColumnIdx
	AngledHeadersCount         TableColumnIdx
	HoveredColumnBody          TableColumnIdx
	HoveredColumnBorder        TableColumnIdx
	HighlightColumnHeader      TableColumnIdx
	AutoFitSingleColumn        TableColumnIdx
	ResizedColumn              TableColumnIdx
	LastResizedColumn          TableColumnIdx
	HeldHeaderColumn           TableColumnIdx
	LastHeldHeaderColumn       TableColumnIdx
	ReorderColumn              TableColumnIdx
	ReorderColumnDstOrder      TableColumnIdx
	LeftMostEnabledColumn      TableColumnIdx
	RightMostEnabledColumn     TableColumnIdx
	LeftMostStretchedColumn    TableColumnIdx
	RightMostStretchedColumn   TableColumnIdx
	ContextPopupColumn         TableColumnIdx
	FreezeRowsRequest          TableColumnIdx
	FreezeRowsCount            TableColumnIdx
	FreezeColumnsRequest       TableColumnIdx
	FreezeColumnsCount         TableColumnIdx
	RowCellDataCurrent         TableColumnIdx
	DummyDrawChannel           TableDrawChannelIdx
	Bg2DrawChannelCurrent      TableDrawChannelIdx
	Bg2DrawChannelUnfrozen     TableDrawChannelIdx
	NavLayer                   ImS8
	IsLayoutLocked             bool
	IsInsideRow                bool
	IsInitializing             bool
	IsSortSpecsDirty           bool
	IsUsingHeaders             bool
	IsContextPopupOpen         bool
	DisableDefaultContextMenu  bool
	IsSettingsRequestLoad      bool
	IsSettingsDirty            bool
	IsDefaultDisplayOrder      bool
	IsResetAllRequest          bool
	IsResetDisplayOrderRequest bool
	IsUnfrozenRows             bool
	IsDefaultSizingPolicy      bool
	IsActiveIdAliveBeforeTable bool
	IsActiveIdInTable          bool
	HasScrollbarYCurr          bool
	HasScrollbarYPrev          bool
	MemoryCompacted            bool
	HostSkipItems              bool
}

pub type ImVector_TableHeaderData = C.ImVector_ImGuiTableHeaderData

@[typedef]
pub struct C.ImVector_ImGuiTableHeaderData {
pub mut:
	Size     i32
	Capacity i32
	Data     &TableHeaderData
}

pub type TableTempData = C.ImGuiTableTempData

@[typedef]
pub struct C.ImGuiTableTempData {
pub mut:
	WindowID                     ID
	TableIndex                   i32
	LastTimeActive               f32
	AngledHeadersExtraWidth      f32
	AngledHeadersRequests        ImVector_TableHeaderData
	UserOuterSize                ImVec2_c
	DrawSplitter                 ImDrawListSplitter
	HostBackupWorkRect           ImRect_c
	HostBackupParentWorkRect     ImRect_c
	HostBackupPrevLineSize       ImVec2_c
	HostBackupCurrLineSize       ImVec2_c
	HostBackupCursorMaxPos       ImVec2_c
	HostBackupColumnsOffset      ImVec1
	HostBackupItemWidth          f32
	HostBackupItemWidthStackSize i32
}

pub type TableColumnSettings = C.ImGuiTableColumnSettings

@[typedef]
pub struct C.ImGuiTableColumnSettings {
pub mut:
	WidthOrWeight f32
	UserID        ID
	Index         TableColumnIdx
	DisplayOrder  TableColumnIdx
	SortOrder     TableColumnIdx
	SortDirection ImU8
	IsEnabled     ImS8
	IsStretch     ImU8
}

pub type TableSettings = C.ImGuiTableSettings

@[typedef]
pub struct C.ImGuiTableSettings {
pub mut:
	ID              ID
	SaveFlags       TableFlags
	RefScale        f32
	ColumnsCount    TableColumnIdx
	ColumnsCountMax TableColumnIdx
	WantApply       bool
}

pub type ImFontLoader = C.ImFontLoader

@[typedef]
pub struct C.ImFontLoader {
pub mut:
	Name                       &char
	LoaderInit                 fn (&imgui.ImFontAtlas) bool
	LoaderShutdown             fn (&imgui.ImFontAtlas)
	FontSrcInit                fn (&imgui.ImFontAtlas, &imgui.ImFontConfig) bool
	FontSrcDestroy             fn (&imgui.ImFontAtlas, &imgui.ImFontConfig)
	FontSrcContainsGlyph       fn (&imgui.ImFontAtlas, &imgui.ImFontConfig, imgui.ImWchar) bool
	FontBakedInit              fn (&imgui.ImFontAtlas, &imgui.ImFontConfig, &imgui.ImFontBaked, voidptr) bool
	FontBakedDestroy           fn (&imgui.ImFontAtlas, &imgui.ImFontConfig, &imgui.ImFontBaked, voidptr)
	FontBakedLoadGlyph         fn (&imgui.ImFontAtlas, &imgui.ImFontConfig, &imgui.ImFontBaked, voidptr, imgui.ImWchar, &imgui.ImFontGlyph, &f32) bool
	FontBakedSrcLoaderDataSize usize
}

pub type ImFontAtlasRectEntry = C.ImFontAtlasRectEntry

@[typedef]
pub struct C.ImFontAtlasRectEntry {
pub mut:
	TargetIndex i32
	Generation  u32
	IsUsed      u32
}

pub type ImFontAtlasPostProcessData = C.ImFontAtlasPostProcessData

@[typedef]
pub struct C.ImFontAtlasPostProcessData {
pub mut:
	FontAtlas &ImFontAtlas
	Font      &ImFont
	FontSrc   &ImFontConfig
	FontBaked &ImFontBaked
	Glyph     &ImFontGlyph
	Pixels    voidptr
	Format    ImTextureFormat
	Pitch     i32
	Width     i32
	Height    i32
}

pub type Stbrp_node_im = C.stbrp_node

pub type Stbrp_context_opaque = C.Stbrp_context_opaque

@[typedef]
pub struct C.Stbrp_context_opaque {
pub mut:
	Data [80]i8
}

pub type ImVector_stbrp_node_im = C.ImVector_stbrp_node_im

@[typedef]
pub struct C.ImVector_stbrp_node_im {
pub mut:
	Size     i32
	Capacity i32
	Data     &Stbrp_node_im
}

pub type ImVector_ImFontAtlasRectEntry = C.ImVector_ImFontAtlasRectEntry

@[typedef]
pub struct C.ImVector_ImFontAtlasRectEntry {
pub mut:
	Size     i32
	Capacity i32
	Data     &ImFontAtlasRectEntry
}

pub type ImVector_ImFontBakedPtr = C.ImVector_ImFontBakedPtr

@[typedef]
pub struct C.ImVector_ImFontBakedPtr {
pub mut:
	Size     i32
	Capacity i32
	Data     &&ImFontBaked
}

pub type ImStableVector_ImFontBaked__32 = C.ImStableVector_ImFontBaked__32

@[typedef]
pub struct C.ImStableVector_ImFontBaked__32 {
pub mut:
	Size     i32
	Capacity i32
	Blocks   ImVector_ImFontBakedPtr
}

pub type ImTextureRef = C.ImTextureRef

@[typedef]
pub struct C.ImTextureRef {
pub mut:
	PackContext              Stbrp_context_opaque
	PackNodes                ImVector_stbrp_node_im
	Rects                    ImVector_ImTextureRect
	RectsIndex               ImVector_ImFontAtlasRectEntry
	TempBuffer               ImVector_unsigned_char
	RectsIndexFreeListStart  i32
	RectsPackedCount         i32
	RectsPackedSurface       i32
	RectsDiscardedCount      i32
	RectsDiscardedSurface    i32
	FrameCount               i32
	MaxRectSize              ImVec2i_c
	MaxRectBounds            ImVec2i_c
	LockDisableResize        bool
	PreloadedAllGlyphsRanges bool
	BakedPool                ImStableVector_ImFontBaked__32
	BakedMap                 Storage
	BakedDiscardedCount      i32
	PackIdMouseCursors       ImFontAtlasRectId
	PackIdLinesTexData       ImFontAtlasRectId
}

@[keep_args_alive]
fn C.ImVec2_ImVec2_Nil() &ImVec2

@[inline]
pub fn im_vec2_im_vec2_nil() &ImVec2 {
	return C.ImVec2_ImVec2_Nil()
}

@[keep_args_alive]
fn C.ImVec2_destroy(self &ImVec2)

@[inline]
pub fn im_vec2_destroy(self &ImVec2) {
	C.ImVec2_destroy(self)
}

@[keep_args_alive]
fn C.ImVec2_ImVec2_Float(_x f32, _y f32) &ImVec2

@[inline]
pub fn im_vec2_im_vec2_float(_x f32, _y f32) &ImVec2 {
	return C.ImVec2_ImVec2_Float(_x, _y)
}

@[keep_args_alive]
fn C.ImVec4_ImVec4_Nil() &ImVec4

@[inline]
pub fn im_vec4_im_vec4_nil() &ImVec4 {
	return C.ImVec4_ImVec4_Nil()
}

@[keep_args_alive]
fn C.ImVec4_destroy(self &ImVec4)

@[inline]
pub fn im_vec4_destroy(self &ImVec4) {
	C.ImVec4_destroy(self)
}

@[keep_args_alive]
fn C.ImVec4_ImVec4_Float(_x f32, _y f32, _z f32, _w f32) &ImVec4

@[inline]
pub fn im_vec4_im_vec4_float(_x f32, _y f32, _z f32, _w f32) &ImVec4 {
	return C.ImVec4_ImVec4_Float(_x, _y, _z, _w)
}

@[keep_args_alive]
fn C.ImTextureRef_ImTextureRef_Nil() &ImTextureRef

@[inline]
pub fn im_texture_ref_im_texture_ref_nil() &ImTextureRef {
	return C.ImTextureRef_ImTextureRef_Nil()
}

@[keep_args_alive]
fn C.ImTextureRef_destroy(self &ImTextureRef)

@[inline]
pub fn im_texture_ref_destroy(self &ImTextureRef) {
	C.ImTextureRef_destroy(self)
}

@[keep_args_alive]
fn C.ImTextureRef_ImTextureRef_TextureID(tex_id ImTextureID) &ImTextureRef

@[inline]
pub fn im_texture_ref_im_texture_ref_texture_id(tex_id ImTextureID) &ImTextureRef {
	return C.ImTextureRef_ImTextureRef_TextureID(tex_id)
}

@[keep_args_alive]
fn C.ImTextureRef_GetTexID(self &ImTextureRef) ImTextureID

@[inline]
pub fn im_texture_ref_get_tex_id(self &ImTextureRef) ImTextureID {
	return C.ImTextureRef_GetTexID(self)
}

@[keep_args_alive]
fn C.igCreateContext(shared_font_atlas &ImFontAtlas) &Context

@[inline]
pub fn create_context(shared_font_atlas &ImFontAtlas) &Context {
	return C.igCreateContext(shared_font_atlas)
}

@[keep_args_alive]
fn C.igDestroyContext(ctx &Context)

@[inline]
pub fn destroy_context(ctx &Context) {
	C.igDestroyContext(ctx)
}

@[keep_args_alive]
fn C.igGetCurrentContext() &Context

@[inline]
pub fn get_current_context() &Context {
	return C.igGetCurrentContext()
}

@[keep_args_alive]
fn C.igSetCurrentContext(ctx &Context)

@[inline]
pub fn set_current_context(ctx &Context) {
	C.igSetCurrentContext(ctx)
}

@[keep_args_alive]
fn C.igGetIO_Nil() &IO

@[inline]
pub fn get_io_nil() &IO {
	return C.igGetIO_Nil()
}

@[keep_args_alive]
fn C.igGetPlatformIO_Nil() &PlatformIO

@[inline]
pub fn get_platform_io_nil() &PlatformIO {
	return C.igGetPlatformIO_Nil()
}

@[keep_args_alive]
fn C.igGetStyle() &Style

@[inline]
pub fn get_style() &Style {
	return C.igGetStyle()
}

@[keep_args_alive]
fn C.igNewFrame()

@[inline]
pub fn new_frame() {
	C.igNewFrame()
}

@[keep_args_alive]
fn C.igEndFrame()

@[inline]
pub fn end_frame() {
	C.igEndFrame()
}

@[keep_args_alive]
fn C.igRender()

@[inline]
pub fn render() {
	C.igRender()
}

@[keep_args_alive]
fn C.igGetDrawData() &ImDrawData

@[inline]
pub fn get_draw_data() &ImDrawData {
	return C.igGetDrawData()
}

@[keep_args_alive]
fn C.igShowDemoWindow(p_open &bool)

@[inline]
pub fn show_demo_window(p_open &bool) {
	C.igShowDemoWindow(p_open)
}

@[keep_args_alive]
fn C.igShowMetricsWindow(p_open &bool)

@[inline]
pub fn show_metrics_window(p_open &bool) {
	C.igShowMetricsWindow(p_open)
}

@[keep_args_alive]
fn C.igShowDebugLogWindow(p_open &bool)

@[inline]
pub fn show_debug_log_window(p_open &bool) {
	C.igShowDebugLogWindow(p_open)
}

@[keep_args_alive]
fn C.igShowIDStackToolWindow(p_open &bool)

@[inline]
pub fn show_ids_tack_tool_window(p_open &bool) {
	C.igShowIDStackToolWindow(p_open)
}

@[keep_args_alive]
fn C.igShowAboutWindow(p_open &bool)

@[inline]
pub fn show_about_window(p_open &bool) {
	C.igShowAboutWindow(p_open)
}

@[keep_args_alive]
fn C.igShowStyleEditor(ref &Style)

@[inline]
pub fn show_style_editor(ref &Style) {
	C.igShowStyleEditor(ref)
}

@[keep_args_alive]
fn C.igShowStyleSelector(const_label &char) bool

@[inline]
pub fn show_style_selector(const_label &char) bool {
	return C.igShowStyleSelector(const_label)
}

@[keep_args_alive]
fn C.igShowFontSelector(const_label &char)

@[inline]
pub fn show_font_selector(const_label &char) {
	C.igShowFontSelector(const_label)
}

@[keep_args_alive]
fn C.igShowUserGuide()

@[inline]
pub fn show_user_guide() {
	C.igShowUserGuide()
}

@[keep_args_alive]
fn C.igGetVersion() &char

@[inline]
pub fn get_version() &char {
	return C.igGetVersion()
}

@[keep_args_alive]
fn C.igStyleColorsDark(dst &Style)

@[inline]
pub fn style_colors_dark(dst &Style) {
	C.igStyleColorsDark(dst)
}

@[keep_args_alive]
fn C.igStyleColorsLight(dst &Style)

@[inline]
pub fn style_colors_light(dst &Style) {
	C.igStyleColorsLight(dst)
}

@[keep_args_alive]
fn C.igStyleColorsClassic(dst &Style)

@[inline]
pub fn style_colors_classic(dst &Style) {
	C.igStyleColorsClassic(dst)
}

@[keep_args_alive]
fn C.igBegin(const_name &char, p_open &bool, flags WindowFlags) bool

@[inline]
pub fn begin(const_name &char, p_open &bool, flags WindowFlags) bool {
	return C.igBegin(const_name, p_open, flags)
}

@[keep_args_alive]
fn C.igEnd()

@[inline]
pub fn end() {
	C.igEnd()
}

@[keep_args_alive]
fn C.igBeginChild_Str(const_str_id &char, size ImVec2_c, child_flags ChildFlags, window_flags WindowFlags) bool

@[inline]
pub fn begin_child_str(const_str_id &char, size ImVec2_c, child_flags ChildFlags, window_flags WindowFlags) bool {
	return C.igBeginChild_Str(const_str_id, size, child_flags, window_flags)
}

@[keep_args_alive]
fn C.igBeginChild_ID(id ID, size ImVec2_c, child_flags ChildFlags, window_flags WindowFlags) bool

@[inline]
pub fn begin_child_id(id ID, size ImVec2_c, child_flags ChildFlags, window_flags WindowFlags) bool {
	return C.igBeginChild_ID(id, size, child_flags, window_flags)
}

@[keep_args_alive]
fn C.igEndChild()

@[inline]
pub fn end_child() {
	C.igEndChild()
}

@[keep_args_alive]
fn C.igIsWindowAppearing() bool

@[inline]
pub fn is_window_appearing() bool {
	return C.igIsWindowAppearing()
}

@[keep_args_alive]
fn C.igIsWindowCollapsed() bool

@[inline]
pub fn is_window_collapsed() bool {
	return C.igIsWindowCollapsed()
}

@[keep_args_alive]
fn C.igIsWindowFocused(flags FocusedFlags) bool

@[inline]
pub fn is_window_focused(flags FocusedFlags) bool {
	return C.igIsWindowFocused(flags)
}

@[keep_args_alive]
fn C.igIsWindowHovered(flags HoveredFlags) bool

@[inline]
pub fn is_window_hovered(flags HoveredFlags) bool {
	return C.igIsWindowHovered(flags)
}

@[keep_args_alive]
fn C.igGetWindowDrawList() &ImDrawList

@[inline]
pub fn get_window_draw_list() &ImDrawList {
	return C.igGetWindowDrawList()
}

@[keep_args_alive]
fn C.igGetWindowDpiScale() f32

@[inline]
pub fn get_window_dpi_scale() f32 {
	return C.igGetWindowDpiScale()
}

@[keep_args_alive]
fn C.igGetWindowPos() ImVec2_c

@[inline]
pub fn get_window_pos() ImVec2_c {
	return C.igGetWindowPos()
}

@[keep_args_alive]
fn C.igGetWindowSize() ImVec2_c

@[inline]
pub fn get_window_size() ImVec2_c {
	return C.igGetWindowSize()
}

@[keep_args_alive]
fn C.igGetWindowWidth() f32

@[inline]
pub fn get_window_width() f32 {
	return C.igGetWindowWidth()
}

@[keep_args_alive]
fn C.igGetWindowHeight() f32

@[inline]
pub fn get_window_height() f32 {
	return C.igGetWindowHeight()
}

@[keep_args_alive]
fn C.igGetWindowViewport() &Viewport

@[inline]
pub fn get_window_viewport() &Viewport {
	return C.igGetWindowViewport()
}

@[keep_args_alive]
fn C.igSetNextWindowPos(pos ImVec2_c, cond Cond, pivot ImVec2_c)

@[inline]
pub fn set_next_window_pos(pos ImVec2_c, cond Cond, pivot ImVec2_c) {
	C.igSetNextWindowPos(pos, cond, pivot)
}

@[keep_args_alive]
fn C.igSetNextWindowSize(size ImVec2_c, cond Cond)

@[inline]
pub fn set_next_window_size(size ImVec2_c, cond Cond) {
	C.igSetNextWindowSize(size, cond)
}

@[keep_args_alive]
fn C.igSetNextWindowSizeConstraints(size_min ImVec2_c, size_max ImVec2_c, custom_callback SizeCallback, custom_callback_data voidptr)

@[inline]
pub fn set_next_window_size_constraints(size_min ImVec2_c, size_max ImVec2_c, custom_callback SizeCallback, custom_callback_data voidptr) {
	C.igSetNextWindowSizeConstraints(size_min, size_max, custom_callback, custom_callback_data)
}

@[keep_args_alive]
fn C.igSetNextWindowContentSize(size ImVec2_c)

@[inline]
pub fn set_next_window_content_size(size ImVec2_c) {
	C.igSetNextWindowContentSize(size)
}

@[keep_args_alive]
fn C.igSetNextWindowCollapsed(collapsed bool, cond Cond)

@[inline]
pub fn set_next_window_collapsed(collapsed bool, cond Cond) {
	C.igSetNextWindowCollapsed(collapsed, cond)
}

@[keep_args_alive]
fn C.igSetNextWindowFocus()

@[inline]
pub fn set_next_window_focus() {
	C.igSetNextWindowFocus()
}

@[keep_args_alive]
fn C.igSetNextWindowScroll(scroll ImVec2_c)

@[inline]
pub fn set_next_window_scroll(scroll ImVec2_c) {
	C.igSetNextWindowScroll(scroll)
}

@[keep_args_alive]
fn C.igSetNextWindowBgAlpha(alpha f32)

@[inline]
pub fn set_next_window_bg_alpha(alpha f32) {
	C.igSetNextWindowBgAlpha(alpha)
}

@[keep_args_alive]
fn C.igSetNextWindowViewport(viewport_id ID)

@[inline]
pub fn set_next_window_viewport(viewport_id ID) {
	C.igSetNextWindowViewport(viewport_id)
}

@[keep_args_alive]
fn C.igSetWindowPos_Vec2(pos ImVec2_c, cond Cond)

@[inline]
pub fn set_window_pos_vec2(pos ImVec2_c, cond Cond) {
	C.igSetWindowPos_Vec2(pos, cond)
}

@[keep_args_alive]
fn C.igSetWindowSize_Vec2(size ImVec2_c, cond Cond)

@[inline]
pub fn set_window_size_vec2(size ImVec2_c, cond Cond) {
	C.igSetWindowSize_Vec2(size, cond)
}

@[keep_args_alive]
fn C.igSetWindowCollapsed_Bool(collapsed bool, cond Cond)

@[inline]
pub fn set_window_collapsed_bool(collapsed bool, cond Cond) {
	C.igSetWindowCollapsed_Bool(collapsed, cond)
}

@[keep_args_alive]
fn C.igSetWindowFocus_Nil()

@[inline]
pub fn set_window_focus_nil() {
	C.igSetWindowFocus_Nil()
}

@[keep_args_alive]
fn C.igSetWindowPos_Str(const_name &char, pos ImVec2_c, cond Cond)

@[inline]
pub fn set_window_pos_str(const_name &char, pos ImVec2_c, cond Cond) {
	C.igSetWindowPos_Str(const_name, pos, cond)
}

@[keep_args_alive]
fn C.igSetWindowSize_Str(const_name &char, size ImVec2_c, cond Cond)

@[inline]
pub fn set_window_size_str(const_name &char, size ImVec2_c, cond Cond) {
	C.igSetWindowSize_Str(const_name, size, cond)
}

@[keep_args_alive]
fn C.igSetWindowCollapsed_Str(const_name &char, collapsed bool, cond Cond)

@[inline]
pub fn set_window_collapsed_str(const_name &char, collapsed bool, cond Cond) {
	C.igSetWindowCollapsed_Str(const_name, collapsed, cond)
}

@[keep_args_alive]
fn C.igSetWindowFocus_Str(const_name &char)

@[inline]
pub fn set_window_focus_str(const_name &char) {
	C.igSetWindowFocus_Str(const_name)
}

@[keep_args_alive]
fn C.igGetScrollX() f32

@[inline]
pub fn get_scroll_x() f32 {
	return C.igGetScrollX()
}

@[keep_args_alive]
fn C.igGetScrollY() f32

@[inline]
pub fn get_scroll_y() f32 {
	return C.igGetScrollY()
}

@[keep_args_alive]
fn C.igSetScrollX_Float(scroll_x f32)

@[inline]
pub fn set_scroll_x_float(scroll_x f32) {
	C.igSetScrollX_Float(scroll_x)
}

@[keep_args_alive]
fn C.igSetScrollY_Float(scroll_y f32)

@[inline]
pub fn set_scroll_y_float(scroll_y f32) {
	C.igSetScrollY_Float(scroll_y)
}

@[keep_args_alive]
fn C.igGetScrollMaxX() f32

@[inline]
pub fn get_scroll_max_x() f32 {
	return C.igGetScrollMaxX()
}

@[keep_args_alive]
fn C.igGetScrollMaxY() f32

@[inline]
pub fn get_scroll_max_y() f32 {
	return C.igGetScrollMaxY()
}

@[keep_args_alive]
fn C.igSetScrollHereX(center_x_ratio f32)

@[inline]
pub fn set_scroll_here_x(center_x_ratio f32) {
	C.igSetScrollHereX(center_x_ratio)
}

@[keep_args_alive]
fn C.igSetScrollHereY(center_y_ratio f32)

@[inline]
pub fn set_scroll_here_y(center_y_ratio f32) {
	C.igSetScrollHereY(center_y_ratio)
}

@[keep_args_alive]
fn C.igSetScrollFromPosX_Float(local_x f32, center_x_ratio f32)

@[inline]
pub fn set_scroll_from_pos_x_float(local_x f32, center_x_ratio f32) {
	C.igSetScrollFromPosX_Float(local_x, center_x_ratio)
}

@[keep_args_alive]
fn C.igSetScrollFromPosY_Float(local_y f32, center_y_ratio f32)

@[inline]
pub fn set_scroll_from_pos_y_float(local_y f32, center_y_ratio f32) {
	C.igSetScrollFromPosY_Float(local_y, center_y_ratio)
}

@[keep_args_alive]
fn C.igPushFont(font &ImFont, font_size_base_unscaled f32)

@[inline]
pub fn push_font(font &ImFont, font_size_base_unscaled f32) {
	C.igPushFont(font, font_size_base_unscaled)
}

@[keep_args_alive]
fn C.igPopFont()

@[inline]
pub fn pop_font() {
	C.igPopFont()
}

@[keep_args_alive]
fn C.igGetFont() &ImFont

@[inline]
pub fn get_font() &ImFont {
	return C.igGetFont()
}

@[keep_args_alive]
fn C.igGetFontSize() f32

@[inline]
pub fn get_font_size() f32 {
	return C.igGetFontSize()
}

@[keep_args_alive]
fn C.igGetFontBaked() &ImFontBaked

@[inline]
pub fn get_font_baked() &ImFontBaked {
	return C.igGetFontBaked()
}

@[keep_args_alive]
fn C.igPushStyleColor_U32(idx Col, col ImU32)

@[inline]
pub fn push_style_color_u32(idx Col, col ImU32) {
	C.igPushStyleColor_U32(idx, col)
}

@[keep_args_alive]
fn C.igPushStyleColor_Vec4(idx Col, col ImVec4_c)

@[inline]
pub fn push_style_color_vec4(idx Col, col ImVec4_c) {
	C.igPushStyleColor_Vec4(idx, col)
}

@[keep_args_alive]
fn C.igPopStyleColor(count i32)

@[inline]
pub fn pop_style_color(count i32) {
	C.igPopStyleColor(count)
}

@[keep_args_alive]
fn C.igPushStyleVar_Float(idx StyleVar, val f32)

@[inline]
pub fn push_style_var_float(idx StyleVar, val f32) {
	C.igPushStyleVar_Float(idx, val)
}

@[keep_args_alive]
fn C.igPushStyleVar_Vec2(idx StyleVar, val ImVec2_c)

@[inline]
pub fn push_style_var_vec2(idx StyleVar, val ImVec2_c) {
	C.igPushStyleVar_Vec2(idx, val)
}

@[keep_args_alive]
fn C.igPushStyleVarX(idx StyleVar, val_x f32)

@[inline]
pub fn push_style_var_x(idx StyleVar, val_x f32) {
	C.igPushStyleVarX(idx, val_x)
}

@[keep_args_alive]
fn C.igPushStyleVarY(idx StyleVar, val_y f32)

@[inline]
pub fn push_style_var_y(idx StyleVar, val_y f32) {
	C.igPushStyleVarY(idx, val_y)
}

@[keep_args_alive]
fn C.igPopStyleVar(count i32)

@[inline]
pub fn pop_style_var(count i32) {
	C.igPopStyleVar(count)
}

@[keep_args_alive]
fn C.igPushItemFlag(option ItemFlags, enabled bool)

@[inline]
pub fn push_item_flag(option ItemFlags, enabled bool) {
	C.igPushItemFlag(option, enabled)
}

@[keep_args_alive]
fn C.igPopItemFlag()

@[inline]
pub fn pop_item_flag() {
	C.igPopItemFlag()
}

@[keep_args_alive]
fn C.igPushItemWidth(item_width f32)

@[inline]
pub fn push_item_width(item_width f32) {
	C.igPushItemWidth(item_width)
}

@[keep_args_alive]
fn C.igPopItemWidth()

@[inline]
pub fn pop_item_width() {
	C.igPopItemWidth()
}

@[keep_args_alive]
fn C.igSetNextItemWidth(item_width f32)

@[inline]
pub fn set_next_item_width(item_width f32) {
	C.igSetNextItemWidth(item_width)
}

@[keep_args_alive]
fn C.igCalcItemWidth() f32

@[inline]
pub fn calc_item_width() f32 {
	return C.igCalcItemWidth()
}

@[keep_args_alive]
fn C.igPushTextWrapPos(wrap_local_pos_x f32)

@[inline]
pub fn push_text_wrap_pos(wrap_local_pos_x f32) {
	C.igPushTextWrapPos(wrap_local_pos_x)
}

@[keep_args_alive]
fn C.igPopTextWrapPos()

@[inline]
pub fn pop_text_wrap_pos() {
	C.igPopTextWrapPos()
}

@[keep_args_alive]
fn C.igGetFontTexUvWhitePixel() ImVec2_c

@[inline]
pub fn get_font_tex_uv_white_pixel() ImVec2_c {
	return C.igGetFontTexUvWhitePixel()
}

@[keep_args_alive]
fn C.igGetColorU32_Col(idx Col, alpha_mul f32) ImU32

@[inline]
pub fn get_color_u32_col(idx Col, alpha_mul f32) ImU32 {
	return C.igGetColorU32_Col(idx, alpha_mul)
}

@[keep_args_alive]
fn C.igGetColorU32_Vec4(col ImVec4_c) ImU32

@[inline]
pub fn get_color_u32_vec4(col ImVec4_c) ImU32 {
	return C.igGetColorU32_Vec4(col)
}

@[keep_args_alive]
fn C.igGetColorU32_U32(col ImU32, alpha_mul f32) ImU32

@[inline]
pub fn get_color_u32_u32(col ImU32, alpha_mul f32) ImU32 {
	return C.igGetColorU32_U32(col, alpha_mul)
}

@[keep_args_alive]
fn C.igGetStyleColorVec4(idx Col) &ImVec4_c

@[inline]
pub fn get_style_color_vec4(idx Col) &ImVec4_c {
	return C.igGetStyleColorVec4(idx)
}

@[keep_args_alive]
fn C.igGetCursorScreenPos() ImVec2_c

@[inline]
pub fn get_cursor_screen_pos() ImVec2_c {
	return C.igGetCursorScreenPos()
}

@[keep_args_alive]
fn C.igSetCursorScreenPos(pos ImVec2_c)

@[inline]
pub fn set_cursor_screen_pos(pos ImVec2_c) {
	C.igSetCursorScreenPos(pos)
}

@[keep_args_alive]
fn C.igGetContentRegionAvail() ImVec2_c

@[inline]
pub fn get_content_region_avail() ImVec2_c {
	return C.igGetContentRegionAvail()
}

@[keep_args_alive]
fn C.igGetCursorPos() ImVec2_c

@[inline]
pub fn get_cursor_pos() ImVec2_c {
	return C.igGetCursorPos()
}

@[keep_args_alive]
fn C.igGetCursorPosX() f32

@[inline]
pub fn get_cursor_pos_x() f32 {
	return C.igGetCursorPosX()
}

@[keep_args_alive]
fn C.igGetCursorPosY() f32

@[inline]
pub fn get_cursor_pos_y() f32 {
	return C.igGetCursorPosY()
}

@[keep_args_alive]
fn C.igSetCursorPos(local_pos ImVec2_c)

@[inline]
pub fn set_cursor_pos(local_pos ImVec2_c) {
	C.igSetCursorPos(local_pos)
}

@[keep_args_alive]
fn C.igSetCursorPosX(local_x f32)

@[inline]
pub fn set_cursor_pos_x(local_x f32) {
	C.igSetCursorPosX(local_x)
}

@[keep_args_alive]
fn C.igSetCursorPosY(local_y f32)

@[inline]
pub fn set_cursor_pos_y(local_y f32) {
	C.igSetCursorPosY(local_y)
}

@[keep_args_alive]
fn C.igGetCursorStartPos() ImVec2_c

@[inline]
pub fn get_cursor_start_pos() ImVec2_c {
	return C.igGetCursorStartPos()
}

@[keep_args_alive]
fn C.igSeparator()

@[inline]
pub fn separator() {
	C.igSeparator()
}

@[keep_args_alive]
fn C.igSameLine(offset_from_start_x f32, spacing f32)

@[inline]
pub fn same_line(offset_from_start_x f32, spacing f32) {
	C.igSameLine(offset_from_start_x, spacing)
}

@[keep_args_alive]
fn C.igNewLine()

@[inline]
pub fn new_line() {
	C.igNewLine()
}

@[keep_args_alive]
fn C.igSpacing()

@[inline]
pub fn spacing() {
	C.igSpacing()
}

@[keep_args_alive]
fn C.igDummy(size ImVec2_c)

@[inline]
pub fn dummy(size ImVec2_c) {
	C.igDummy(size)
}

@[keep_args_alive]
fn C.igIndent(indent_w f32)

@[inline]
pub fn indent(indent_w f32) {
	C.igIndent(indent_w)
}

@[keep_args_alive]
fn C.igUnindent(indent_w f32)

@[inline]
pub fn unindent(indent_w f32) {
	C.igUnindent(indent_w)
}

@[keep_args_alive]
fn C.igBeginGroup()

@[inline]
pub fn begin_group() {
	C.igBeginGroup()
}

@[keep_args_alive]
fn C.igEndGroup()

@[inline]
pub fn end_group() {
	C.igEndGroup()
}

@[keep_args_alive]
fn C.igAlignTextToFramePadding()

@[inline]
pub fn align_text_to_frame_padding() {
	C.igAlignTextToFramePadding()
}

@[keep_args_alive]
fn C.igGetTextLineHeight() f32

@[inline]
pub fn get_text_line_height() f32 {
	return C.igGetTextLineHeight()
}

@[keep_args_alive]
fn C.igGetTextLineHeightWithSpacing() f32

@[inline]
pub fn get_text_line_height_with_spacing() f32 {
	return C.igGetTextLineHeightWithSpacing()
}

@[keep_args_alive]
fn C.igGetFrameHeight() f32

@[inline]
pub fn get_frame_height() f32 {
	return C.igGetFrameHeight()
}

@[keep_args_alive]
fn C.igGetFrameHeightWithSpacing() f32

@[inline]
pub fn get_frame_height_with_spacing() f32 {
	return C.igGetFrameHeightWithSpacing()
}

@[keep_args_alive]
fn C.igPushID_Str(const_str_id &char)

@[inline]
pub fn push_id_str(const_str_id &char) {
	C.igPushID_Str(const_str_id)
}

@[keep_args_alive]
fn C.igPushID_StrStr(str_id_begin &char, str_id_end &char)

@[inline]
pub fn push_id_str_str(str_id_begin &char, str_id_end &char) {
	C.igPushID_StrStr(str_id_begin, str_id_end)
}

@[keep_args_alive]
fn C.igPushID_Ptr(ptr_id voidptr)

@[inline]
pub fn push_id_ptr(ptr_id voidptr) {
	C.igPushID_Ptr(ptr_id)
}

@[keep_args_alive]
fn C.igPushID_Int(int_id i32)

@[inline]
pub fn push_id_int(int_id i32) {
	C.igPushID_Int(int_id)
}

@[keep_args_alive]
fn C.igPopID()

@[inline]
pub fn pop_id() {
	C.igPopID()
}

@[keep_args_alive]
fn C.igGetID_Str(const_str_id &char) ID

@[inline]
pub fn get_id_str(const_str_id &char) ID {
	return C.igGetID_Str(const_str_id)
}

@[keep_args_alive]
fn C.igGetID_StrStr(str_id_begin &char, str_id_end &char) ID

@[inline]
pub fn get_id_str_str(str_id_begin &char, str_id_end &char) ID {
	return C.igGetID_StrStr(str_id_begin, str_id_end)
}

@[keep_args_alive]
fn C.igGetID_Ptr(ptr_id voidptr) ID

@[inline]
pub fn get_id_ptr(ptr_id voidptr) ID {
	return C.igGetID_Ptr(ptr_id)
}

@[keep_args_alive]
fn C.igGetID_Int(int_id i32) ID

@[inline]
pub fn get_id_int(int_id i32) ID {
	return C.igGetID_Int(int_id)
}

@[keep_args_alive]
fn C.igTextUnformatted(const_text &char, const_text_end &char)

@[inline]
pub fn text_unformatted(const_text &char, const_text_end &char) {
	C.igTextUnformatted(const_text, const_text_end)
}

@[keep_args_alive]
fn C.igText(const_fmt &char)

@[inline]
pub fn text(const_fmt &char) {
	C.igText(const_fmt)
}

@[keep_args_alive]
fn C.igTextV(const_fmt &char, args Va_list)

@[inline]
pub fn text_v(const_fmt &char, args Va_list) {
	C.igTextV(const_fmt, args)
}

@[keep_args_alive]
fn C.igTextColored(col ImVec4_c, const_fmt &char)

@[inline]
pub fn text_colored(col ImVec4_c, const_fmt &char) {
	C.igTextColored(col, const_fmt)
}

@[keep_args_alive]
fn C.igTextColoredV(col ImVec4_c, const_fmt &char, args Va_list)

@[inline]
pub fn text_colored_v(col ImVec4_c, const_fmt &char, args Va_list) {
	C.igTextColoredV(col, const_fmt, args)
}

@[keep_args_alive]
fn C.igTextDisabled(const_fmt &char)

@[inline]
pub fn text_disabled(const_fmt &char) {
	C.igTextDisabled(const_fmt)
}

@[keep_args_alive]
fn C.igTextDisabledV(const_fmt &char, args Va_list)

@[inline]
pub fn text_disabled_v(const_fmt &char, args Va_list) {
	C.igTextDisabledV(const_fmt, args)
}

@[keep_args_alive]
fn C.igTextWrapped(const_fmt &char)

@[inline]
pub fn text_wrapped(const_fmt &char) {
	C.igTextWrapped(const_fmt)
}

@[keep_args_alive]
fn C.igTextWrappedV(const_fmt &char, args Va_list)

@[inline]
pub fn text_wrapped_v(const_fmt &char, args Va_list) {
	C.igTextWrappedV(const_fmt, args)
}

@[keep_args_alive]
fn C.igLabelText(const_label &char, const_fmt &char)

@[inline]
pub fn label_text(const_label &char, const_fmt &char) {
	C.igLabelText(const_label, const_fmt)
}

@[keep_args_alive]
fn C.igLabelTextV(const_label &char, const_fmt &char, args Va_list)

@[inline]
pub fn label_text_v(const_label &char, const_fmt &char, args Va_list) {
	C.igLabelTextV(const_label, const_fmt, args)
}

@[keep_args_alive]
fn C.igBulletText(const_fmt &char)

@[inline]
pub fn bullet_text(const_fmt &char) {
	C.igBulletText(const_fmt)
}

@[keep_args_alive]
fn C.igBulletTextV(const_fmt &char, args Va_list)

@[inline]
pub fn bullet_text_v(const_fmt &char, args Va_list) {
	C.igBulletTextV(const_fmt, args)
}

@[keep_args_alive]
fn C.igSeparatorText(const_label &char)

@[inline]
pub fn separator_text(const_label &char) {
	C.igSeparatorText(const_label)
}

@[keep_args_alive]
fn C.igButton(const_label &char, size ImVec2_c) bool

@[inline]
pub fn button(const_label &char, size ImVec2_c) bool {
	return C.igButton(const_label, size)
}

@[keep_args_alive]
fn C.igSmallButton(const_label &char) bool

@[inline]
pub fn small_button(const_label &char) bool {
	return C.igSmallButton(const_label)
}

@[keep_args_alive]
fn C.igInvisibleButton(const_str_id &char, size ImVec2_c, flags ButtonFlags) bool

@[inline]
pub fn invisible_button(const_str_id &char, size ImVec2_c, flags ButtonFlags) bool {
	return C.igInvisibleButton(const_str_id, size, flags)
}

@[keep_args_alive]
fn C.igArrowButton(const_str_id &char, dir Dir) bool

@[inline]
pub fn arrow_button(const_str_id &char, dir Dir) bool {
	return C.igArrowButton(const_str_id, dir)
}

@[keep_args_alive]
fn C.igCheckbox(const_label &char, v &bool) bool

@[inline]
pub fn checkbox(const_label &char, v &bool) bool {
	return C.igCheckbox(const_label, v)
}

@[keep_args_alive]
fn C.igCheckboxFlags_IntPtr(const_label &char, flags &i32, flags_value i32) bool

@[inline]
pub fn checkbox_flags_int_ptr(const_label &char, flags &i32, flags_value i32) bool {
	return C.igCheckboxFlags_IntPtr(const_label, flags, flags_value)
}

@[keep_args_alive]
fn C.igCheckboxFlags_UintPtr(const_label &char, flags &u32, flags_value u32) bool

@[inline]
pub fn checkbox_flags_uint_ptr(const_label &char, flags &u32, flags_value u32) bool {
	return C.igCheckboxFlags_UintPtr(const_label, flags, flags_value)
}

@[keep_args_alive]
fn C.igRadioButton_Bool(const_label &char, active bool) bool

@[inline]
pub fn radio_button_bool(const_label &char, active bool) bool {
	return C.igRadioButton_Bool(const_label, active)
}

@[keep_args_alive]
fn C.igRadioButton_IntPtr(const_label &char, v &i32, v_button i32) bool

@[inline]
pub fn radio_button_int_ptr(const_label &char, v &i32, v_button i32) bool {
	return C.igRadioButton_IntPtr(const_label, v, v_button)
}

@[keep_args_alive]
fn C.igProgressBar(fraction f32, size_arg ImVec2_c, const_overlay &char)

@[inline]
pub fn progress_bar(fraction f32, size_arg ImVec2_c, const_overlay &char) {
	C.igProgressBar(fraction, size_arg, const_overlay)
}

@[keep_args_alive]
fn C.igBullet()

@[inline]
pub fn bullet() {
	C.igBullet()
}

@[keep_args_alive]
fn C.igTextLink(const_label &char) bool

@[inline]
pub fn text_link(const_label &char) bool {
	return C.igTextLink(const_label)
}

@[keep_args_alive]
fn C.igTextLinkOpenURL(const_label &char, url &char) bool

@[inline]
pub fn text_link_open_url(const_label &char, url &char) bool {
	return C.igTextLinkOpenURL(const_label, url)
}

@[keep_args_alive]
fn C.igImage(tex_ref ImTextureRef_c, image_size ImVec2_c, uv0 ImVec2_c, uv1 ImVec2_c)

@[inline]
pub fn image(tex_ref ImTextureRef_c, image_size ImVec2_c, uv0 ImVec2_c, uv1 ImVec2_c) {
	C.igImage(tex_ref, image_size, uv0, uv1)
}

@[keep_args_alive]
fn C.igImageWithBg(tex_ref ImTextureRef_c, image_size ImVec2_c, uv0 ImVec2_c, uv1 ImVec2_c, bg_col ImVec4_c, tint_col ImVec4_c)

@[inline]
pub fn image_with_bg(tex_ref ImTextureRef_c, image_size ImVec2_c, uv0 ImVec2_c, uv1 ImVec2_c, bg_col ImVec4_c, tint_col ImVec4_c) {
	C.igImageWithBg(tex_ref, image_size, uv0, uv1, bg_col, tint_col)
}

@[keep_args_alive]
fn C.igImageButton(const_str_id &char, tex_ref ImTextureRef_c, image_size ImVec2_c, uv0 ImVec2_c, uv1 ImVec2_c, bg_col ImVec4_c, tint_col ImVec4_c) bool

@[inline]
pub fn image_button(const_str_id &char, tex_ref ImTextureRef_c, image_size ImVec2_c, uv0 ImVec2_c, uv1 ImVec2_c, bg_col ImVec4_c, tint_col ImVec4_c) bool {
	return C.igImageButton(const_str_id, tex_ref, image_size, uv0, uv1, bg_col, tint_col)
}

@[keep_args_alive]
fn C.igBeginCombo(const_label &char, preview_value &char, flags ComboFlags) bool

@[inline]
pub fn begin_combo(const_label &char, preview_value &char, flags ComboFlags) bool {
	return C.igBeginCombo(const_label, preview_value, flags)
}

@[keep_args_alive]
fn C.igEndCombo()

@[inline]
pub fn end_combo() {
	C.igEndCombo()
}

@[keep_args_alive]
fn C.igCombo_Str_arr(const_label &char, current_item &i32, items &&u8, items_count i32, popup_max_height_in_items i32) bool

@[inline]
pub fn combo_str_arr(const_label &char, current_item &i32, items &&u8, items_count i32, popup_max_height_in_items i32) bool {
	return C.igCombo_Str_arr(const_label, current_item, items, items_count,
		popup_max_height_in_items)
}

@[keep_args_alive]
fn C.igCombo_Str(const_label &char, current_item &i32, items_separated_by_zeros &char, popup_max_height_in_items i32) bool

@[inline]
pub fn combo_str(const_label &char, current_item &i32, items_separated_by_zeros &char, popup_max_height_in_items i32) bool {
	return C.igCombo_Str(const_label, current_item, items_separated_by_zeros,
		popup_max_height_in_items)
}

@[keep_args_alive]
fn C.igCombo_FnStrPtr(const_label &char, current_item &i32, getter fn (voidptr, i32) &char, user_data voidptr, items_count i32, popup_max_height_in_items i32) bool

@[inline]
pub fn combo_fn_str_ptr(const_label &char, current_item &i32, getter fn (voidptr, i32) &char, user_data voidptr, items_count i32, popup_max_height_in_items i32) bool {
	return C.igCombo_FnStrPtr(const_label, current_item, getter, user_data, items_count,
		popup_max_height_in_items)
}

@[keep_args_alive]
fn C.igDragFloat(const_label &char, v &f32, v_speed f32, v_min f32, v_max f32, format &char, flags SliderFlags) bool

@[inline]
pub fn drag_float(const_label &char, v &f32, v_speed f32, v_min f32, v_max f32, format &char, flags SliderFlags) bool {
	return C.igDragFloat(const_label, v, v_speed, v_min, v_max, format, flags)
}

@[keep_args_alive]
fn C.igDragFloat2(const_label &char, v &f32, v_speed f32, v_min f32, v_max f32, format &char, flags SliderFlags) bool

@[inline]
pub fn drag_float2(const_label &char, v &f32, v_speed f32, v_min f32, v_max f32, format &char, flags SliderFlags) bool {
	return C.igDragFloat2(const_label, v, v_speed, v_min, v_max, format, flags)
}

@[keep_args_alive]
fn C.igDragFloat3(const_label &char, v &f32, v_speed f32, v_min f32, v_max f32, format &char, flags SliderFlags) bool

@[inline]
pub fn drag_float3(const_label &char, v &f32, v_speed f32, v_min f32, v_max f32, format &char, flags SliderFlags) bool {
	return C.igDragFloat3(const_label, v, v_speed, v_min, v_max, format, flags)
}

@[keep_args_alive]
fn C.igDragFloat4(const_label &char, v &f32, v_speed f32, v_min f32, v_max f32, format &char, flags SliderFlags) bool

@[inline]
pub fn drag_float4(const_label &char, v &f32, v_speed f32, v_min f32, v_max f32, format &char, flags SliderFlags) bool {
	return C.igDragFloat4(const_label, v, v_speed, v_min, v_max, format, flags)
}

@[keep_args_alive]
fn C.igDragFloatRange2(const_label &char, v_current_min &f32, v_current_max &f32, v_speed f32, v_min f32, v_max f32, format &char, format_max &char, flags SliderFlags) bool

@[inline]
pub fn drag_float_range2(const_label &char, v_current_min &f32, v_current_max &f32, v_speed f32, v_min f32, v_max f32, format &char, format_max &char, flags SliderFlags) bool {
	return C.igDragFloatRange2(const_label, v_current_min, v_current_max, v_speed, v_min, v_max,
		format, format_max, flags)
}

@[keep_args_alive]
fn C.igDragInt(const_label &char, v &i32, v_speed f32, v_min i32, v_max i32, format &char, flags SliderFlags) bool

@[inline]
pub fn drag_int(const_label &char, v &i32, v_speed f32, v_min i32, v_max i32, format &char, flags SliderFlags) bool {
	return C.igDragInt(const_label, v, v_speed, v_min, v_max, format, flags)
}

@[keep_args_alive]
fn C.igDragInt2(const_label &char, v &i32, v_speed f32, v_min i32, v_max i32, format &char, flags SliderFlags) bool

@[inline]
pub fn drag_int2(const_label &char, v &i32, v_speed f32, v_min i32, v_max i32, format &char, flags SliderFlags) bool {
	return C.igDragInt2(const_label, v, v_speed, v_min, v_max, format, flags)
}

@[keep_args_alive]
fn C.igDragInt3(const_label &char, v &i32, v_speed f32, v_min i32, v_max i32, format &char, flags SliderFlags) bool

@[inline]
pub fn drag_int3(const_label &char, v &i32, v_speed f32, v_min i32, v_max i32, format &char, flags SliderFlags) bool {
	return C.igDragInt3(const_label, v, v_speed, v_min, v_max, format, flags)
}

@[keep_args_alive]
fn C.igDragInt4(const_label &char, v &i32, v_speed f32, v_min i32, v_max i32, format &char, flags SliderFlags) bool

@[inline]
pub fn drag_int4(const_label &char, v &i32, v_speed f32, v_min i32, v_max i32, format &char, flags SliderFlags) bool {
	return C.igDragInt4(const_label, v, v_speed, v_min, v_max, format, flags)
}

@[keep_args_alive]
fn C.igDragIntRange2(const_label &char, v_current_min &i32, v_current_max &i32, v_speed f32, v_min i32, v_max i32, format &char, format_max &char, flags SliderFlags) bool

@[inline]
pub fn drag_int_range2(const_label &char, v_current_min &i32, v_current_max &i32, v_speed f32, v_min i32, v_max i32, format &char, format_max &char, flags SliderFlags) bool {
	return C.igDragIntRange2(const_label, v_current_min, v_current_max, v_speed, v_min, v_max,
		format, format_max, flags)
}

@[keep_args_alive]
fn C.igDragScalar(const_label &char, data_type DataType, p_data voidptr, v_speed f32, p_min voidptr, p_max voidptr, format &char, flags SliderFlags) bool

@[inline]
pub fn drag_scalar(const_label &char, data_type DataType, p_data voidptr, v_speed f32, p_min voidptr, p_max voidptr, format &char, flags SliderFlags) bool {
	return C.igDragScalar(const_label, data_type, p_data, v_speed, p_min, p_max, format, flags)
}

@[keep_args_alive]
fn C.igDragScalarN(const_label &char, data_type DataType, p_data voidptr, components i32, v_speed f32, p_min voidptr, p_max voidptr, format &char, flags SliderFlags) bool

@[inline]
pub fn drag_scalar_n(const_label &char, data_type DataType, p_data voidptr, components i32, v_speed f32, p_min voidptr, p_max voidptr, format &char, flags SliderFlags) bool {
	return C.igDragScalarN(const_label, data_type, p_data, components, v_speed, p_min, p_max,
		format, flags)
}

@[keep_args_alive]
fn C.igSliderFloat(const_label &char, v &f32, v_min f32, v_max f32, format &char, flags SliderFlags) bool

@[inline]
pub fn slider_float(const_label &char, v &f32, v_min f32, v_max f32, format &char, flags SliderFlags) bool {
	return C.igSliderFloat(const_label, v, v_min, v_max, format, flags)
}

@[keep_args_alive]
fn C.igSliderFloat2(const_label &char, v &f32, v_min f32, v_max f32, format &char, flags SliderFlags) bool

@[inline]
pub fn slider_float2(const_label &char, v &f32, v_min f32, v_max f32, format &char, flags SliderFlags) bool {
	return C.igSliderFloat2(const_label, v, v_min, v_max, format, flags)
}

@[keep_args_alive]
fn C.igSliderFloat3(const_label &char, v &f32, v_min f32, v_max f32, format &char, flags SliderFlags) bool

@[inline]
pub fn slider_float3(const_label &char, v &f32, v_min f32, v_max f32, format &char, flags SliderFlags) bool {
	return C.igSliderFloat3(const_label, v, v_min, v_max, format, flags)
}

@[keep_args_alive]
fn C.igSliderFloat4(const_label &char, v &f32, v_min f32, v_max f32, format &char, flags SliderFlags) bool

@[inline]
pub fn slider_float4(const_label &char, v &f32, v_min f32, v_max f32, format &char, flags SliderFlags) bool {
	return C.igSliderFloat4(const_label, v, v_min, v_max, format, flags)
}

@[keep_args_alive]
fn C.igSliderAngle(const_label &char, v_rad &f32, v_degrees_min f32, v_degrees_max f32, format &char, flags SliderFlags) bool

@[inline]
pub fn slider_angle(const_label &char, v_rad &f32, v_degrees_min f32, v_degrees_max f32, format &char, flags SliderFlags) bool {
	return C.igSliderAngle(const_label, v_rad, v_degrees_min, v_degrees_max, format, flags)
}

@[keep_args_alive]
fn C.igSliderInt(const_label &char, v &i32, v_min i32, v_max i32, format &char, flags SliderFlags) bool

@[inline]
pub fn slider_int(const_label &char, v &i32, v_min i32, v_max i32, format &char, flags SliderFlags) bool {
	return C.igSliderInt(const_label, v, v_min, v_max, format, flags)
}

@[keep_args_alive]
fn C.igSliderInt2(const_label &char, v &i32, v_min i32, v_max i32, format &char, flags SliderFlags) bool

@[inline]
pub fn slider_int2(const_label &char, v &i32, v_min i32, v_max i32, format &char, flags SliderFlags) bool {
	return C.igSliderInt2(const_label, v, v_min, v_max, format, flags)
}

@[keep_args_alive]
fn C.igSliderInt3(const_label &char, v &i32, v_min i32, v_max i32, format &char, flags SliderFlags) bool

@[inline]
pub fn slider_int3(const_label &char, v &i32, v_min i32, v_max i32, format &char, flags SliderFlags) bool {
	return C.igSliderInt3(const_label, v, v_min, v_max, format, flags)
}

@[keep_args_alive]
fn C.igSliderInt4(const_label &char, v &i32, v_min i32, v_max i32, format &char, flags SliderFlags) bool

@[inline]
pub fn slider_int4(const_label &char, v &i32, v_min i32, v_max i32, format &char, flags SliderFlags) bool {
	return C.igSliderInt4(const_label, v, v_min, v_max, format, flags)
}

@[keep_args_alive]
fn C.igSliderScalar(const_label &char, data_type DataType, p_data voidptr, p_min voidptr, p_max voidptr, format &char, flags SliderFlags) bool

@[inline]
pub fn slider_scalar(const_label &char, data_type DataType, p_data voidptr, p_min voidptr, p_max voidptr, format &char, flags SliderFlags) bool {
	return C.igSliderScalar(const_label, data_type, p_data, p_min, p_max, format, flags)
}

@[keep_args_alive]
fn C.igSliderScalarN(const_label &char, data_type DataType, p_data voidptr, components i32, p_min voidptr, p_max voidptr, format &char, flags SliderFlags) bool

@[inline]
pub fn slider_scalar_n(const_label &char, data_type DataType, p_data voidptr, components i32, p_min voidptr, p_max voidptr, format &char, flags SliderFlags) bool {
	return C.igSliderScalarN(const_label, data_type, p_data, components, p_min, p_max, format,
		flags)
}

@[keep_args_alive]
fn C.igVSliderFloat(const_label &char, size ImVec2_c, v &f32, v_min f32, v_max f32, format &char, flags SliderFlags) bool

@[inline]
pub fn vs_lider_float(const_label &char, size ImVec2_c, v &f32, v_min f32, v_max f32, format &char, flags SliderFlags) bool {
	return C.igVSliderFloat(const_label, size, v, v_min, v_max, format, flags)
}

@[keep_args_alive]
fn C.igVSliderInt(const_label &char, size ImVec2_c, v &i32, v_min i32, v_max i32, format &char, flags SliderFlags) bool

@[inline]
pub fn vs_lider_int(const_label &char, size ImVec2_c, v &i32, v_min i32, v_max i32, format &char, flags SliderFlags) bool {
	return C.igVSliderInt(const_label, size, v, v_min, v_max, format, flags)
}

@[keep_args_alive]
fn C.igVSliderScalar(const_label &char, size ImVec2_c, data_type DataType, p_data voidptr, p_min voidptr, p_max voidptr, format &char, flags SliderFlags) bool

@[inline]
pub fn vs_lider_scalar(const_label &char, size ImVec2_c, data_type DataType, p_data voidptr, p_min voidptr, p_max voidptr, format &char, flags SliderFlags) bool {
	return C.igVSliderScalar(const_label, size, data_type, p_data, p_min, p_max, format, flags)
}

@[keep_args_alive]
fn C.igInputText(const_label &char, buf &char, buf_size usize, flags InputTextFlags, callback InputTextCallback, user_data voidptr) bool

@[inline]
pub fn input_text(const_label &char, buf &char, buf_size usize, flags InputTextFlags, callback InputTextCallback, user_data voidptr) bool {
	return C.igInputText(const_label, buf, buf_size, flags, callback, user_data)
}

@[keep_args_alive]
fn C.igInputTextMultiline(const_label &char, buf &char, buf_size usize, size ImVec2_c, flags InputTextFlags, callback InputTextCallback, user_data voidptr) bool

@[inline]
pub fn input_text_multiline(const_label &char, buf &char, buf_size usize, size ImVec2_c, flags InputTextFlags, callback InputTextCallback, user_data voidptr) bool {
	return C.igInputTextMultiline(const_label, buf, buf_size, size, flags, callback, user_data)
}

@[keep_args_alive]
fn C.igInputTextWithHint(const_label &char, hint &char, buf &char, buf_size usize, flags InputTextFlags, callback InputTextCallback, user_data voidptr) bool

@[inline]
pub fn input_text_with_hint(const_label &char, hint &char, buf &char, buf_size usize, flags InputTextFlags, callback InputTextCallback, user_data voidptr) bool {
	return C.igInputTextWithHint(const_label, hint, buf, buf_size, flags, callback, user_data)
}

@[keep_args_alive]
fn C.igInputFloat(const_label &char, v &f32, step f32, step_fast f32, format &char, flags InputTextFlags) bool

@[inline]
pub fn input_float(const_label &char, v &f32, step f32, step_fast f32, format &char, flags InputTextFlags) bool {
	return C.igInputFloat(const_label, v, step, step_fast, format, flags)
}

@[keep_args_alive]
fn C.igInputFloat2(const_label &char, v &f32, format &char, flags InputTextFlags) bool

@[inline]
pub fn input_float2(const_label &char, v &f32, format &char, flags InputTextFlags) bool {
	return C.igInputFloat2(const_label, v, format, flags)
}

@[keep_args_alive]
fn C.igInputFloat3(const_label &char, v &f32, format &char, flags InputTextFlags) bool

@[inline]
pub fn input_float3(const_label &char, v &f32, format &char, flags InputTextFlags) bool {
	return C.igInputFloat3(const_label, v, format, flags)
}

@[keep_args_alive]
fn C.igInputFloat4(const_label &char, v &f32, format &char, flags InputTextFlags) bool

@[inline]
pub fn input_float4(const_label &char, v &f32, format &char, flags InputTextFlags) bool {
	return C.igInputFloat4(const_label, v, format, flags)
}

@[keep_args_alive]
fn C.igInputInt(const_label &char, v &i32, step i32, step_fast i32, flags InputTextFlags) bool

@[inline]
pub fn input_int(const_label &char, v &i32, step i32, step_fast i32, flags InputTextFlags) bool {
	return C.igInputInt(const_label, v, step, step_fast, flags)
}

@[keep_args_alive]
fn C.igInputInt2(const_label &char, v &i32, flags InputTextFlags) bool

@[inline]
pub fn input_int2(const_label &char, v &i32, flags InputTextFlags) bool {
	return C.igInputInt2(const_label, v, flags)
}

@[keep_args_alive]
fn C.igInputInt3(const_label &char, v &i32, flags InputTextFlags) bool

@[inline]
pub fn input_int3(const_label &char, v &i32, flags InputTextFlags) bool {
	return C.igInputInt3(const_label, v, flags)
}

@[keep_args_alive]
fn C.igInputInt4(const_label &char, v &i32, flags InputTextFlags) bool

@[inline]
pub fn input_int4(const_label &char, v &i32, flags InputTextFlags) bool {
	return C.igInputInt4(const_label, v, flags)
}

@[keep_args_alive]
fn C.igInputDouble(const_label &char, v &f64, step f64, step_fast f64, format &char, flags InputTextFlags) bool

@[inline]
pub fn input_double(const_label &char, v &f64, step f64, step_fast f64, format &char, flags InputTextFlags) bool {
	return C.igInputDouble(const_label, v, step, step_fast, format, flags)
}

@[keep_args_alive]
fn C.igInputScalar(const_label &char, data_type DataType, p_data voidptr, p_step voidptr, p_step_fast voidptr, format &char, flags InputTextFlags) bool

@[inline]
pub fn input_scalar(const_label &char, data_type DataType, p_data voidptr, p_step voidptr, p_step_fast voidptr, format &char, flags InputTextFlags) bool {
	return C.igInputScalar(const_label, data_type, p_data, p_step, p_step_fast, format, flags)
}

@[keep_args_alive]
fn C.igInputScalarN(const_label &char, data_type DataType, p_data voidptr, components i32, p_step voidptr, p_step_fast voidptr, format &char, flags InputTextFlags) bool

@[inline]
pub fn input_scalar_n(const_label &char, data_type DataType, p_data voidptr, components i32, p_step voidptr, p_step_fast voidptr, format &char, flags InputTextFlags) bool {
	return C.igInputScalarN(const_label, data_type, p_data, components, p_step, p_step_fast,
		format, flags)
}

@[keep_args_alive]
fn C.igColorEdit3(const_label &char, col &f32, flags ColorEditFlags) bool

@[inline]
pub fn color_edit3(const_label &char, col &f32, flags ColorEditFlags) bool {
	return C.igColorEdit3(const_label, col, flags)
}

@[keep_args_alive]
fn C.igColorEdit4(const_label &char, col &f32, flags ColorEditFlags) bool

@[inline]
pub fn color_edit4(const_label &char, col &f32, flags ColorEditFlags) bool {
	return C.igColorEdit4(const_label, col, flags)
}

@[keep_args_alive]
fn C.igColorPicker3(const_label &char, col &f32, flags ColorEditFlags) bool

@[inline]
pub fn color_picker3(const_label &char, col &f32, flags ColorEditFlags) bool {
	return C.igColorPicker3(const_label, col, flags)
}

@[keep_args_alive]
fn C.igColorPicker4(const_label &char, col &f32, flags ColorEditFlags, ref_col &f32) bool

@[inline]
pub fn color_picker4(const_label &char, col &f32, flags ColorEditFlags, ref_col &f32) bool {
	return C.igColorPicker4(const_label, col, flags, ref_col)
}

@[keep_args_alive]
fn C.igColorButton(desc_id &char, col ImVec4_c, flags ColorEditFlags, size ImVec2_c) bool

@[inline]
pub fn color_button(desc_id &char, col ImVec4_c, flags ColorEditFlags, size ImVec2_c) bool {
	return C.igColorButton(desc_id, col, flags, size)
}

@[keep_args_alive]
fn C.igSetColorEditOptions(flags ColorEditFlags)

@[inline]
pub fn set_color_edit_options(flags ColorEditFlags) {
	C.igSetColorEditOptions(flags)
}

@[keep_args_alive]
fn C.igTreeNode_Str(const_label &char) bool

@[inline]
pub fn tree_node_str(const_label &char) bool {
	return C.igTreeNode_Str(const_label)
}

@[keep_args_alive]
fn C.igTreeNode_StrStr(const_str_id &char, const_fmt &char) bool

@[inline]
pub fn tree_node_str_str(const_str_id &char, const_fmt &char) bool {
	return C.igTreeNode_StrStr(const_str_id, const_fmt)
}

@[keep_args_alive]
fn C.igTreeNode_Ptr(ptr_id voidptr, const_fmt &char) bool

@[inline]
pub fn tree_node_ptr(ptr_id voidptr, const_fmt &char) bool {
	return C.igTreeNode_Ptr(ptr_id, const_fmt)
}

@[keep_args_alive]
fn C.igTreeNodeV_Str(const_str_id &char, const_fmt &char, args Va_list) bool

@[inline]
pub fn tree_node_v_str(const_str_id &char, const_fmt &char, args Va_list) bool {
	return C.igTreeNodeV_Str(const_str_id, const_fmt, args)
}

@[keep_args_alive]
fn C.igTreeNodeV_Ptr(ptr_id voidptr, const_fmt &char, args Va_list) bool

@[inline]
pub fn tree_node_v_ptr(ptr_id voidptr, const_fmt &char, args Va_list) bool {
	return C.igTreeNodeV_Ptr(ptr_id, const_fmt, args)
}

@[keep_args_alive]
fn C.igTreeNodeEx_Str(const_label &char, flags TreeNodeFlags) bool

@[inline]
pub fn tree_node_ex_str(const_label &char, flags TreeNodeFlags) bool {
	return C.igTreeNodeEx_Str(const_label, flags)
}

@[keep_args_alive]
fn C.igTreeNodeEx_StrStr(const_str_id &char, flags TreeNodeFlags, const_fmt &char) bool

@[inline]
pub fn tree_node_ex_str_str(const_str_id &char, flags TreeNodeFlags, const_fmt &char) bool {
	return C.igTreeNodeEx_StrStr(const_str_id, flags, const_fmt)
}

@[keep_args_alive]
fn C.igTreeNodeEx_Ptr(ptr_id voidptr, flags TreeNodeFlags, const_fmt &char) bool

@[inline]
pub fn tree_node_ex_ptr(ptr_id voidptr, flags TreeNodeFlags, const_fmt &char) bool {
	return C.igTreeNodeEx_Ptr(ptr_id, flags, const_fmt)
}

@[keep_args_alive]
fn C.igTreeNodeExV_Str(const_str_id &char, flags TreeNodeFlags, const_fmt &char, args Va_list) bool

@[inline]
pub fn tree_node_ex_v_str(const_str_id &char, flags TreeNodeFlags, const_fmt &char, args Va_list) bool {
	return C.igTreeNodeExV_Str(const_str_id, flags, const_fmt, args)
}

@[keep_args_alive]
fn C.igTreeNodeExV_Ptr(ptr_id voidptr, flags TreeNodeFlags, const_fmt &char, args Va_list) bool

@[inline]
pub fn tree_node_ex_v_ptr(ptr_id voidptr, flags TreeNodeFlags, const_fmt &char, args Va_list) bool {
	return C.igTreeNodeExV_Ptr(ptr_id, flags, const_fmt, args)
}

@[keep_args_alive]
fn C.igTreePush_Str(const_str_id &char)

@[inline]
pub fn tree_push_str(const_str_id &char) {
	C.igTreePush_Str(const_str_id)
}

@[keep_args_alive]
fn C.igTreePush_Ptr(ptr_id voidptr)

@[inline]
pub fn tree_push_ptr(ptr_id voidptr) {
	C.igTreePush_Ptr(ptr_id)
}

@[keep_args_alive]
fn C.igTreePop()

@[inline]
pub fn tree_pop() {
	C.igTreePop()
}

@[keep_args_alive]
fn C.igGetTreeNodeToLabelSpacing() f32

@[inline]
pub fn get_tree_node_to_label_spacing() f32 {
	return C.igGetTreeNodeToLabelSpacing()
}

@[keep_args_alive]
fn C.igCollapsingHeader_TreeNodeFlags(const_label &char, flags TreeNodeFlags) bool

@[inline]
pub fn collapsing_header_tree_node_flags(const_label &char, flags TreeNodeFlags) bool {
	return C.igCollapsingHeader_TreeNodeFlags(const_label, flags)
}

@[keep_args_alive]
fn C.igCollapsingHeader_BoolPtr(const_label &char, p_visible &bool, flags TreeNodeFlags) bool

@[inline]
pub fn collapsing_header_bool_ptr(const_label &char, p_visible &bool, flags TreeNodeFlags) bool {
	return C.igCollapsingHeader_BoolPtr(const_label, p_visible, flags)
}

@[keep_args_alive]
fn C.igSetNextItemOpen(is_open bool, cond Cond)

@[inline]
pub fn set_next_item_open(is_open bool, cond Cond) {
	C.igSetNextItemOpen(is_open, cond)
}

@[keep_args_alive]
fn C.igSetNextItemStorageID(storage_id ID)

@[inline]
pub fn set_next_item_storage_id(storage_id ID) {
	C.igSetNextItemStorageID(storage_id)
}

@[keep_args_alive]
fn C.igTreeNodeGetOpen(storage_id ID) bool

@[inline]
pub fn tree_node_get_open(storage_id ID) bool {
	return C.igTreeNodeGetOpen(storage_id)
}

@[keep_args_alive]
fn C.igSelectable_Bool(const_label &char, selected bool, flags SelectableFlags, size ImVec2_c) bool

@[inline]
pub fn selectable_bool(const_label &char, selected bool, flags SelectableFlags, size ImVec2_c) bool {
	return C.igSelectable_Bool(const_label, selected, flags, size)
}

@[keep_args_alive]
fn C.igSelectable_BoolPtr(const_label &char, p_selected &bool, flags SelectableFlags, size ImVec2_c) bool

@[inline]
pub fn selectable_bool_ptr(const_label &char, p_selected &bool, flags SelectableFlags, size ImVec2_c) bool {
	return C.igSelectable_BoolPtr(const_label, p_selected, flags, size)
}

@[keep_args_alive]
fn C.igBeginMultiSelect(flags MultiSelectFlags, selection_size i32, items_count i32) &MultiSelectIO

@[inline]
pub fn begin_multi_select(flags MultiSelectFlags, selection_size i32, items_count i32) &MultiSelectIO {
	return C.igBeginMultiSelect(flags, selection_size, items_count)
}

@[keep_args_alive]
fn C.igEndMultiSelect() &MultiSelectIO

@[inline]
pub fn end_multi_select() &MultiSelectIO {
	return C.igEndMultiSelect()
}

@[keep_args_alive]
fn C.igSetNextItemSelectionUserData(selection_user_data SelectionUserData)

@[inline]
pub fn set_next_item_selection_user_data(selection_user_data SelectionUserData) {
	C.igSetNextItemSelectionUserData(selection_user_data)
}

@[keep_args_alive]
fn C.igIsItemToggledSelection() bool

@[inline]
pub fn is_item_toggled_selection() bool {
	return C.igIsItemToggledSelection()
}

@[keep_args_alive]
fn C.igBeginListBox(const_label &char, size ImVec2_c) bool

@[inline]
pub fn begin_list_box(const_label &char, size ImVec2_c) bool {
	return C.igBeginListBox(const_label, size)
}

@[keep_args_alive]
fn C.igEndListBox()

@[inline]
pub fn end_list_box() {
	C.igEndListBox()
}

@[keep_args_alive]
fn C.igListBox_Str_arr(const_label &char, current_item &i32, items &&u8, items_count i32, height_in_items i32) bool

@[inline]
pub fn list_box_str_arr(const_label &char, current_item &i32, items &&u8, items_count i32, height_in_items i32) bool {
	return C.igListBox_Str_arr(const_label, current_item, items, items_count, height_in_items)
}

@[keep_args_alive]
fn C.igListBox_FnStrPtr(const_label &char, current_item &i32, getter fn (voidptr, i32) &char, user_data voidptr, items_count i32, height_in_items i32) bool

@[inline]
pub fn list_box_fn_str_ptr(const_label &char, current_item &i32, getter fn (voidptr, i32) &char, user_data voidptr, items_count i32, height_in_items i32) bool {
	return C.igListBox_FnStrPtr(const_label, current_item, getter, user_data, items_count,
		height_in_items)
}

@[keep_args_alive]
fn C.igPlotLines_FloatPtr(const_label &char, values &f32, values_count i32, values_offset i32, overlay_text &char, scale_min f32, scale_max f32, graph_size ImVec2_c, stride i32)

@[inline]
pub fn plot_lines_float_ptr(const_label &char, values &f32, values_count i32, values_offset i32, overlay_text &char, scale_min f32, scale_max f32, graph_size ImVec2_c, stride i32) {
	C.igPlotLines_FloatPtr(const_label, values, values_count, values_offset, overlay_text,
		scale_min, scale_max, graph_size, stride)
}

@[keep_args_alive]
fn C.igPlotLines_FnFloatPtr(const_label &char, values_getter fn (voidptr, i32) f32, data voidptr, values_count i32, values_offset i32, overlay_text &char, scale_min f32, scale_max f32, graph_size ImVec2_c)

@[inline]
pub fn plot_lines_fn_float_ptr(const_label &char, values_getter fn (voidptr, i32) f32, data voidptr, values_count i32, values_offset i32, overlay_text &char, scale_min f32, scale_max f32, graph_size ImVec2_c) {
	C.igPlotLines_FnFloatPtr(const_label, values_getter, data, values_count, values_offset,
		overlay_text, scale_min, scale_max, graph_size)
}

@[keep_args_alive]
fn C.igPlotHistogram_FloatPtr(const_label &char, values &f32, values_count i32, values_offset i32, overlay_text &char, scale_min f32, scale_max f32, graph_size ImVec2_c, stride i32)

@[inline]
pub fn plot_histogram_float_ptr(const_label &char, values &f32, values_count i32, values_offset i32, overlay_text &char, scale_min f32, scale_max f32, graph_size ImVec2_c, stride i32) {
	C.igPlotHistogram_FloatPtr(const_label, values, values_count, values_offset, overlay_text,
		scale_min, scale_max, graph_size, stride)
}

@[keep_args_alive]
fn C.igPlotHistogram_FnFloatPtr(const_label &char, values_getter fn (voidptr, i32) f32, data voidptr, values_count i32, values_offset i32, overlay_text &char, scale_min f32, scale_max f32, graph_size ImVec2_c)

@[inline]
pub fn plot_histogram_fn_float_ptr(const_label &char, values_getter fn (voidptr, i32) f32, data voidptr, values_count i32, values_offset i32, overlay_text &char, scale_min f32, scale_max f32, graph_size ImVec2_c) {
	C.igPlotHistogram_FnFloatPtr(const_label, values_getter, data, values_count, values_offset,
		overlay_text, scale_min, scale_max, graph_size)
}

@[keep_args_alive]
fn C.igValue_Bool(prefix &char, b bool)

@[inline]
pub fn value_bool(prefix &char, b bool) {
	C.igValue_Bool(prefix, b)
}

@[keep_args_alive]
fn C.igValue_Int(prefix &char, v i32)

@[inline]
pub fn value_int(prefix &char, v i32) {
	C.igValue_Int(prefix, v)
}

@[keep_args_alive]
fn C.igValue_Uint(prefix &char, v u32)

@[inline]
pub fn value_uint(prefix &char, v u32) {
	C.igValue_Uint(prefix, v)
}

@[keep_args_alive]
fn C.igValue_Float(prefix &char, v f32, float_format &char)

@[inline]
pub fn value_float(prefix &char, v f32, float_format &char) {
	C.igValue_Float(prefix, v, float_format)
}

@[keep_args_alive]
fn C.igBeginMenuBar() bool

@[inline]
pub fn begin_menu_bar() bool {
	return C.igBeginMenuBar()
}

@[keep_args_alive]
fn C.igEndMenuBar()

@[inline]
pub fn end_menu_bar() {
	C.igEndMenuBar()
}

@[keep_args_alive]
fn C.igBeginMainMenuBar() bool

@[inline]
pub fn begin_main_menu_bar() bool {
	return C.igBeginMainMenuBar()
}

@[keep_args_alive]
fn C.igEndMainMenuBar()

@[inline]
pub fn end_main_menu_bar() {
	C.igEndMainMenuBar()
}

@[keep_args_alive]
fn C.igBeginMenu(const_label &char, enabled bool) bool

@[inline]
pub fn begin_menu(const_label &char, enabled bool) bool {
	return C.igBeginMenu(const_label, enabled)
}

@[keep_args_alive]
fn C.igEndMenu()

@[inline]
pub fn end_menu() {
	C.igEndMenu()
}

@[keep_args_alive]
fn C.igMenuItem_Bool(const_label &char, const_shortcut &char, selected bool, enabled bool) bool

@[inline]
pub fn menu_item_bool(const_label &char, const_shortcut &char, selected bool, enabled bool) bool {
	return C.igMenuItem_Bool(const_label, const_shortcut, selected, enabled)
}

@[keep_args_alive]
fn C.igMenuItem_BoolPtr(const_label &char, const_shortcut &char, p_selected &bool, enabled bool) bool

@[inline]
pub fn menu_item_bool_ptr(const_label &char, const_shortcut &char, p_selected &bool, enabled bool) bool {
	return C.igMenuItem_BoolPtr(const_label, const_shortcut, p_selected, enabled)
}

@[keep_args_alive]
fn C.igBeginTooltip() bool

@[inline]
pub fn begin_tooltip() bool {
	return C.igBeginTooltip()
}

@[keep_args_alive]
fn C.igEndTooltip()

@[inline]
pub fn end_tooltip() {
	C.igEndTooltip()
}

@[keep_args_alive]
fn C.igSetTooltip(const_fmt &char)

@[inline]
pub fn set_tooltip(const_fmt &char) {
	C.igSetTooltip(const_fmt)
}

@[keep_args_alive]
fn C.igSetTooltipV(const_fmt &char, args Va_list)

@[inline]
pub fn set_tooltip_v(const_fmt &char, args Va_list) {
	C.igSetTooltipV(const_fmt, args)
}

@[keep_args_alive]
fn C.igBeginItemTooltip() bool

@[inline]
pub fn begin_item_tooltip() bool {
	return C.igBeginItemTooltip()
}

@[keep_args_alive]
fn C.igSetItemTooltip(const_fmt &char)

@[inline]
pub fn set_item_tooltip(const_fmt &char) {
	C.igSetItemTooltip(const_fmt)
}

@[keep_args_alive]
fn C.igSetItemTooltipV(const_fmt &char, args Va_list)

@[inline]
pub fn set_item_tooltip_v(const_fmt &char, args Va_list) {
	C.igSetItemTooltipV(const_fmt, args)
}

@[keep_args_alive]
fn C.igBeginPopup(const_str_id &char, flags WindowFlags) bool

@[inline]
pub fn begin_popup(const_str_id &char, flags WindowFlags) bool {
	return C.igBeginPopup(const_str_id, flags)
}

@[keep_args_alive]
fn C.igBeginPopupModal(const_name &char, p_open &bool, flags WindowFlags) bool

@[inline]
pub fn begin_popup_modal(const_name &char, p_open &bool, flags WindowFlags) bool {
	return C.igBeginPopupModal(const_name, p_open, flags)
}

@[keep_args_alive]
fn C.igEndPopup()

@[inline]
pub fn end_popup() {
	C.igEndPopup()
}

@[keep_args_alive]
fn C.igOpenPopup_Str(const_str_id &char, popup_flags PopupFlags)

@[inline]
pub fn open_popup_str(const_str_id &char, popup_flags PopupFlags) {
	C.igOpenPopup_Str(const_str_id, popup_flags)
}

@[keep_args_alive]
fn C.igOpenPopup_ID(id ID, popup_flags PopupFlags)

@[inline]
pub fn open_popup_id(id ID, popup_flags PopupFlags) {
	C.igOpenPopup_ID(id, popup_flags)
}

@[keep_args_alive]
fn C.igOpenPopupOnItemClick(const_str_id &char, popup_flags PopupFlags)

@[inline]
pub fn open_popup_on_item_click(const_str_id &char, popup_flags PopupFlags) {
	C.igOpenPopupOnItemClick(const_str_id, popup_flags)
}

@[keep_args_alive]
fn C.igCloseCurrentPopup()

@[inline]
pub fn close_current_popup() {
	C.igCloseCurrentPopup()
}

@[keep_args_alive]
fn C.igBeginPopupContextItem(const_str_id &char, popup_flags PopupFlags) bool

@[inline]
pub fn begin_popup_context_item(const_str_id &char, popup_flags PopupFlags) bool {
	return C.igBeginPopupContextItem(const_str_id, popup_flags)
}

@[keep_args_alive]
fn C.igBeginPopupContextWindow(const_str_id &char, popup_flags PopupFlags) bool

@[inline]
pub fn begin_popup_context_window(const_str_id &char, popup_flags PopupFlags) bool {
	return C.igBeginPopupContextWindow(const_str_id, popup_flags)
}

@[keep_args_alive]
fn C.igBeginPopupContextVoid(const_str_id &char, popup_flags PopupFlags) bool

@[inline]
pub fn begin_popup_context_void(const_str_id &char, popup_flags PopupFlags) bool {
	return C.igBeginPopupContextVoid(const_str_id, popup_flags)
}

@[keep_args_alive]
fn C.igIsPopupOpen_Str(const_str_id &char, flags PopupFlags) bool

@[inline]
pub fn is_popup_open_str(const_str_id &char, flags PopupFlags) bool {
	return C.igIsPopupOpen_Str(const_str_id, flags)
}

@[keep_args_alive]
fn C.igBeginTable(const_str_id &char, columns i32, flags TableFlags, outer_size ImVec2_c, inner_width f32) bool

@[inline]
pub fn begin_table(const_str_id &char, columns i32, flags TableFlags, outer_size ImVec2_c, inner_width f32) bool {
	return C.igBeginTable(const_str_id, columns, flags, outer_size, inner_width)
}

@[keep_args_alive]
fn C.igEndTable()

@[inline]
pub fn end_table() {
	C.igEndTable()
}

@[keep_args_alive]
fn C.igTableNextRow(row_flags TableRowFlags, min_row_height f32)

@[inline]
pub fn table_next_row(row_flags TableRowFlags, min_row_height f32) {
	C.igTableNextRow(row_flags, min_row_height)
}

@[keep_args_alive]
fn C.igTableNextColumn() bool

@[inline]
pub fn table_next_column() bool {
	return C.igTableNextColumn()
}

@[keep_args_alive]
fn C.igTableSetColumnIndex(column_n i32) bool

@[inline]
pub fn table_set_column_index(column_n i32) bool {
	return C.igTableSetColumnIndex(column_n)
}

@[keep_args_alive]
fn C.igTableSetupColumn(const_label &char, flags TableColumnFlags, init_width_or_weight f32, user_id ID)

@[inline]
pub fn table_setup_column(const_label &char, flags TableColumnFlags, init_width_or_weight f32, user_id ID) {
	C.igTableSetupColumn(const_label, flags, init_width_or_weight, user_id)
}

@[keep_args_alive]
fn C.igTableSetupScrollFreeze(cols i32, rows i32)

@[inline]
pub fn table_setup_scroll_freeze(cols i32, rows i32) {
	C.igTableSetupScrollFreeze(cols, rows)
}

@[keep_args_alive]
fn C.igTableHeader(const_label &char)

@[inline]
pub fn table_header(const_label &char) {
	C.igTableHeader(const_label)
}

@[keep_args_alive]
fn C.igTableHeadersRow()

@[inline]
pub fn table_headers_row() {
	C.igTableHeadersRow()
}

@[keep_args_alive]
fn C.igTableAngledHeadersRow()

@[inline]
pub fn table_angled_headers_row() {
	C.igTableAngledHeadersRow()
}

@[keep_args_alive]
fn C.igTableGetSortSpecs() &TableSortSpecs

@[inline]
pub fn table_get_sort_specs() &TableSortSpecs {
	return C.igTableGetSortSpecs()
}

@[keep_args_alive]
fn C.igTableGetColumnCount() i32

@[inline]
pub fn table_get_column_count() i32 {
	return C.igTableGetColumnCount()
}

@[keep_args_alive]
fn C.igTableGetColumnIndex() i32

@[inline]
pub fn table_get_column_index() i32 {
	return C.igTableGetColumnIndex()
}

@[keep_args_alive]
fn C.igTableGetRowIndex() i32

@[inline]
pub fn table_get_row_index() i32 {
	return C.igTableGetRowIndex()
}

@[keep_args_alive]
fn C.igTableGetColumnName_Int(column_n i32) &char

@[inline]
pub fn table_get_column_name_int(column_n i32) &char {
	return C.igTableGetColumnName_Int(column_n)
}

@[keep_args_alive]
fn C.igTableGetColumnFlags(column_n i32) TableColumnFlags

@[inline]
pub fn table_get_column_flags(column_n i32) TableColumnFlags {
	return C.igTableGetColumnFlags(column_n)
}

@[keep_args_alive]
fn C.igTableSetColumnEnabled(column_n i32, v bool)

@[inline]
pub fn table_set_column_enabled(column_n i32, v bool) {
	C.igTableSetColumnEnabled(column_n, v)
}

@[keep_args_alive]
fn C.igTableGetHoveredColumn() i32

@[inline]
pub fn table_get_hovered_column() i32 {
	return C.igTableGetHoveredColumn()
}

@[keep_args_alive]
fn C.igTableSetBgColor(target TableBgTarget, color ImU32, column_n i32)

@[inline]
pub fn table_set_bg_color(target TableBgTarget, color ImU32, column_n i32) {
	C.igTableSetBgColor(target, color, column_n)
}

@[keep_args_alive]
fn C.igColumns(count i32, id &char, borders bool)

@[inline]
pub fn columns(count i32, id &char, borders bool) {
	C.igColumns(count, id, borders)
}

@[keep_args_alive]
fn C.igNextColumn()

@[inline]
pub fn next_column() {
	C.igNextColumn()
}

@[keep_args_alive]
fn C.igGetColumnIndex() i32

@[inline]
pub fn get_column_index() i32 {
	return C.igGetColumnIndex()
}

@[keep_args_alive]
fn C.igGetColumnWidth(column_index i32) f32

@[inline]
pub fn get_column_width(column_index i32) f32 {
	return C.igGetColumnWidth(column_index)
}

@[keep_args_alive]
fn C.igSetColumnWidth(column_index i32, width f32)

@[inline]
pub fn set_column_width(column_index i32, width f32) {
	C.igSetColumnWidth(column_index, width)
}

@[keep_args_alive]
fn C.igGetColumnOffset(column_index i32) f32

@[inline]
pub fn get_column_offset(column_index i32) f32 {
	return C.igGetColumnOffset(column_index)
}

@[keep_args_alive]
fn C.igSetColumnOffset(column_index i32, offset_x f32)

@[inline]
pub fn set_column_offset(column_index i32, offset_x f32) {
	C.igSetColumnOffset(column_index, offset_x)
}

@[keep_args_alive]
fn C.igGetColumnsCount() i32

@[inline]
pub fn get_columns_count() i32 {
	return C.igGetColumnsCount()
}

@[keep_args_alive]
fn C.igBeginTabBar(const_str_id &char, flags TabBarFlags) bool

@[inline]
pub fn begin_tab_bar(const_str_id &char, flags TabBarFlags) bool {
	return C.igBeginTabBar(const_str_id, flags)
}

@[keep_args_alive]
fn C.igEndTabBar()

@[inline]
pub fn end_tab_bar() {
	C.igEndTabBar()
}

@[keep_args_alive]
fn C.igBeginTabItem(const_label &char, p_open &bool, flags TabItemFlags) bool

@[inline]
pub fn begin_tab_item(const_label &char, p_open &bool, flags TabItemFlags) bool {
	return C.igBeginTabItem(const_label, p_open, flags)
}

@[keep_args_alive]
fn C.igEndTabItem()

@[inline]
pub fn end_tab_item() {
	C.igEndTabItem()
}

@[keep_args_alive]
fn C.igTabItemButton(const_label &char, flags TabItemFlags) bool

@[inline]
pub fn tab_item_button(const_label &char, flags TabItemFlags) bool {
	return C.igTabItemButton(const_label, flags)
}

@[keep_args_alive]
fn C.igSetTabItemClosed(tab_or_docked_window_label &char)

@[inline]
pub fn set_tab_item_closed(tab_or_docked_window_label &char) {
	C.igSetTabItemClosed(tab_or_docked_window_label)
}

@[keep_args_alive]
fn C.igDockSpace(dockspace_id ID, size ImVec2_c, flags DockNodeFlags, window_class &WindowClass) ID

@[inline]
pub fn dock_space(dockspace_id ID, size ImVec2_c, flags DockNodeFlags, window_class &WindowClass) ID {
	return C.igDockSpace(dockspace_id, size, flags, window_class)
}

@[keep_args_alive]
fn C.igDockSpaceOverViewport(dockspace_id ID, viewport &Viewport, flags DockNodeFlags, window_class &WindowClass) ID

@[inline]
pub fn dock_space_over_viewport(dockspace_id ID, viewport &Viewport, flags DockNodeFlags, window_class &WindowClass) ID {
	return C.igDockSpaceOverViewport(dockspace_id, viewport, flags, window_class)
}

@[keep_args_alive]
fn C.igSetNextWindowDockID(dock_id ID, cond Cond)

@[inline]
pub fn set_next_window_dock_id(dock_id ID, cond Cond) {
	C.igSetNextWindowDockID(dock_id, cond)
}

@[keep_args_alive]
fn C.igSetNextWindowClass(window_class &WindowClass)

@[inline]
pub fn set_next_window_class(window_class &WindowClass) {
	C.igSetNextWindowClass(window_class)
}

@[keep_args_alive]
fn C.igGetWindowDockID() ID

@[inline]
pub fn get_window_dock_id() ID {
	return C.igGetWindowDockID()
}

@[keep_args_alive]
fn C.igIsWindowDocked() bool

@[inline]
pub fn is_window_docked() bool {
	return C.igIsWindowDocked()
}

@[keep_args_alive]
fn C.igLogToTTY(auto_open_depth i32)

@[inline]
pub fn log_to_tty(auto_open_depth i32) {
	C.igLogToTTY(auto_open_depth)
}

@[keep_args_alive]
fn C.igLogToFile(auto_open_depth i32, filename &char)

@[inline]
pub fn log_to_file(auto_open_depth i32, filename &char) {
	C.igLogToFile(auto_open_depth, filename)
}

@[keep_args_alive]
fn C.igLogToClipboard(auto_open_depth i32)

@[inline]
pub fn log_to_clipboard(auto_open_depth i32) {
	C.igLogToClipboard(auto_open_depth)
}

@[keep_args_alive]
fn C.igLogFinish()

@[inline]
pub fn log_finish() {
	C.igLogFinish()
}

@[keep_args_alive]
fn C.igLogButtons()

@[inline]
pub fn log_buttons() {
	C.igLogButtons()
}

@[keep_args_alive]
fn C.igLogText(const_fmt &char)

@[inline]
pub fn log_text(const_fmt &char) {
	C.igLogText(const_fmt)
}

@[keep_args_alive]
fn C.igLogTextV(const_fmt &char, args Va_list)

@[inline]
pub fn log_text_v(const_fmt &char, args Va_list) {
	C.igLogTextV(const_fmt, args)
}

@[keep_args_alive]
fn C.igBeginDragDropSource(flags DragDropFlags) bool

@[inline]
pub fn begin_drag_drop_source(flags DragDropFlags) bool {
	return C.igBeginDragDropSource(flags)
}

@[keep_args_alive]
fn C.igSetDragDropPayload(type_ &char, data voidptr, sz usize, cond Cond) bool

@[inline]
pub fn set_drag_drop_payload(type_ &char, data voidptr, sz usize, cond Cond) bool {
	return C.igSetDragDropPayload(type_, data, sz, cond)
}

@[keep_args_alive]
fn C.igEndDragDropSource()

@[inline]
pub fn end_drag_drop_source() {
	C.igEndDragDropSource()
}

@[keep_args_alive]
fn C.igBeginDragDropTarget() bool

@[inline]
pub fn begin_drag_drop_target() bool {
	return C.igBeginDragDropTarget()
}

@[keep_args_alive]
fn C.igAcceptDragDropPayload(type_ &char, flags DragDropFlags) &Payload

@[inline]
pub fn accept_drag_drop_payload(type_ &char, flags DragDropFlags) &Payload {
	return C.igAcceptDragDropPayload(type_, flags)
}

@[keep_args_alive]
fn C.igEndDragDropTarget()

@[inline]
pub fn end_drag_drop_target() {
	C.igEndDragDropTarget()
}

@[keep_args_alive]
fn C.igGetDragDropPayload() &Payload

@[inline]
pub fn get_drag_drop_payload() &Payload {
	return C.igGetDragDropPayload()
}

@[keep_args_alive]
fn C.igBeginDisabled(disabled bool)

@[inline]
pub fn begin_disabled(disabled bool) {
	C.igBeginDisabled(disabled)
}

@[keep_args_alive]
fn C.igEndDisabled()

@[inline]
pub fn end_disabled() {
	C.igEndDisabled()
}

@[keep_args_alive]
fn C.igPushClipRect(clip_rect_min ImVec2_c, clip_rect_max ImVec2_c, intersect_with_current_clip_rect bool)

@[inline]
pub fn push_clip_rect(clip_rect_min ImVec2_c, clip_rect_max ImVec2_c, intersect_with_current_clip_rect bool) {
	C.igPushClipRect(clip_rect_min, clip_rect_max, intersect_with_current_clip_rect)
}

@[keep_args_alive]
fn C.igPopClipRect()

@[inline]
pub fn pop_clip_rect() {
	C.igPopClipRect()
}

@[keep_args_alive]
fn C.igSetItemDefaultFocus()

@[inline]
pub fn set_item_default_focus() {
	C.igSetItemDefaultFocus()
}

@[keep_args_alive]
fn C.igSetKeyboardFocusHere(offset i32)

@[inline]
pub fn set_keyboard_focus_here(offset i32) {
	C.igSetKeyboardFocusHere(offset)
}

@[keep_args_alive]
fn C.igSetNavCursorVisible(visible bool)

@[inline]
pub fn set_nav_cursor_visible(visible bool) {
	C.igSetNavCursorVisible(visible)
}

@[keep_args_alive]
fn C.igSetNextItemAllowOverlap()

@[inline]
pub fn set_next_item_allow_overlap() {
	C.igSetNextItemAllowOverlap()
}

@[keep_args_alive]
fn C.igIsItemHovered(flags HoveredFlags) bool

@[inline]
pub fn is_item_hovered(flags HoveredFlags) bool {
	return C.igIsItemHovered(flags)
}

@[keep_args_alive]
fn C.igIsItemActive() bool

@[inline]
pub fn is_item_active() bool {
	return C.igIsItemActive()
}

@[keep_args_alive]
fn C.igIsItemFocused() bool

@[inline]
pub fn is_item_focused() bool {
	return C.igIsItemFocused()
}

@[keep_args_alive]
fn C.igIsItemClicked(mouse_button MouseButton) bool

@[inline]
pub fn is_item_clicked(mouse_button MouseButton) bool {
	return C.igIsItemClicked(mouse_button)
}

@[keep_args_alive]
fn C.igIsItemVisible() bool

@[inline]
pub fn is_item_visible() bool {
	return C.igIsItemVisible()
}

@[keep_args_alive]
fn C.igIsItemEdited() bool

@[inline]
pub fn is_item_edited() bool {
	return C.igIsItemEdited()
}

@[keep_args_alive]
fn C.igIsItemActivated() bool

@[inline]
pub fn is_item_activated() bool {
	return C.igIsItemActivated()
}

@[keep_args_alive]
fn C.igIsItemDeactivated() bool

@[inline]
pub fn is_item_deactivated() bool {
	return C.igIsItemDeactivated()
}

@[keep_args_alive]
fn C.igIsItemDeactivatedAfterEdit() bool

@[inline]
pub fn is_item_deactivated_after_edit() bool {
	return C.igIsItemDeactivatedAfterEdit()
}

@[keep_args_alive]
fn C.igIsItemToggledOpen() bool

@[inline]
pub fn is_item_toggled_open() bool {
	return C.igIsItemToggledOpen()
}

@[keep_args_alive]
fn C.igIsAnyItemHovered() bool

@[inline]
pub fn is_any_item_hovered() bool {
	return C.igIsAnyItemHovered()
}

@[keep_args_alive]
fn C.igIsAnyItemActive() bool

@[inline]
pub fn is_any_item_active() bool {
	return C.igIsAnyItemActive()
}

@[keep_args_alive]
fn C.igIsAnyItemFocused() bool

@[inline]
pub fn is_any_item_focused() bool {
	return C.igIsAnyItemFocused()
}

@[keep_args_alive]
fn C.igGetItemID() ID

@[inline]
pub fn get_item_id() ID {
	return C.igGetItemID()
}

@[keep_args_alive]
fn C.igGetItemRectMin() ImVec2_c

@[inline]
pub fn get_item_rect_min() ImVec2_c {
	return C.igGetItemRectMin()
}

@[keep_args_alive]
fn C.igGetItemRectMax() ImVec2_c

@[inline]
pub fn get_item_rect_max() ImVec2_c {
	return C.igGetItemRectMax()
}

@[keep_args_alive]
fn C.igGetItemRectSize() ImVec2_c

@[inline]
pub fn get_item_rect_size() ImVec2_c {
	return C.igGetItemRectSize()
}

@[keep_args_alive]
fn C.igGetItemFlags() ItemFlags

@[inline]
pub fn get_item_flags() ItemFlags {
	return C.igGetItemFlags()
}

@[keep_args_alive]
fn C.igGetMainViewport() &Viewport

@[inline]
pub fn get_main_viewport() &Viewport {
	return C.igGetMainViewport()
}

@[keep_args_alive]
fn C.igGetBackgroundDrawList(viewport &Viewport) &ImDrawList

@[inline]
pub fn get_background_draw_list(viewport &Viewport) &ImDrawList {
	return C.igGetBackgroundDrawList(viewport)
}

@[keep_args_alive]
fn C.igGetForegroundDrawList_ViewportPtr(viewport &Viewport) &ImDrawList

@[inline]
pub fn get_foreground_draw_list_viewport_ptr(viewport &Viewport) &ImDrawList {
	return C.igGetForegroundDrawList_ViewportPtr(viewport)
}

@[keep_args_alive]
fn C.igIsRectVisible_Nil(size ImVec2_c) bool

@[inline]
pub fn is_rect_visible_nil(size ImVec2_c) bool {
	return C.igIsRectVisible_Nil(size)
}

@[keep_args_alive]
fn C.igIsRectVisible_Vec2(rect_min ImVec2_c, rect_max ImVec2_c) bool

@[inline]
pub fn is_rect_visible_vec2(rect_min ImVec2_c, rect_max ImVec2_c) bool {
	return C.igIsRectVisible_Vec2(rect_min, rect_max)
}

@[keep_args_alive]
fn C.igGetTime() f64

@[inline]
pub fn get_time() f64 {
	return C.igGetTime()
}

@[keep_args_alive]
fn C.igGetFrameCount() i32

@[inline]
pub fn get_frame_count() i32 {
	return C.igGetFrameCount()
}

@[keep_args_alive]
fn C.igGetDrawListSharedData() &ImDrawListSharedData

@[inline]
pub fn get_draw_list_shared_data() &ImDrawListSharedData {
	return C.igGetDrawListSharedData()
}

@[keep_args_alive]
fn C.igGetStyleColorName(idx Col) &char

@[inline]
pub fn get_style_color_name(idx Col) &char {
	return C.igGetStyleColorName(idx)
}

@[keep_args_alive]
fn C.igSetStateStorage(storage &Storage)

@[inline]
pub fn set_state_storage(storage &Storage) {
	C.igSetStateStorage(storage)
}

@[keep_args_alive]
fn C.igGetStateStorage() &Storage

@[inline]
pub fn get_state_storage() &Storage {
	return C.igGetStateStorage()
}

@[keep_args_alive]
fn C.igCalcTextSize(const_text &char, const_text_end &char, hide_text_after_double_hash bool, wrap_width f32) ImVec2_c

@[inline]
pub fn calc_text_size(const_text &char, const_text_end &char, hide_text_after_double_hash bool, wrap_width f32) ImVec2_c {
	return C.igCalcTextSize(const_text, const_text_end, hide_text_after_double_hash, wrap_width)
}

@[keep_args_alive]
fn C.igColorConvertU32ToFloat4(in_ ImU32) ImVec4_c

@[inline]
pub fn color_convert_u32_to_float4(in_ ImU32) ImVec4_c {
	return C.igColorConvertU32ToFloat4(in_)
}

@[keep_args_alive]
fn C.igColorConvertFloat4ToU32(in_ ImVec4_c) ImU32

@[inline]
pub fn color_convert_float4_to_u32(in_ ImVec4_c) ImU32 {
	return C.igColorConvertFloat4ToU32(in_)
}

@[keep_args_alive]
fn C.igColorConvertRGBtoHSV(r f32, g f32, b f32, out_h &f32, out_s &f32, out_v &f32)

@[inline]
pub fn color_convert_rgb_to_hsv(r f32, g f32, b f32, out_h &f32, out_s &f32, out_v &f32) {
	C.igColorConvertRGBtoHSV(r, g, b, out_h, out_s, out_v)
}

@[keep_args_alive]
fn C.igColorConvertHSVtoRGB(h f32, s f32, v f32, out_r &f32, out_g &f32, out_b &f32)

@[inline]
pub fn color_convert_hsv_to_rgb(h f32, s f32, v f32, out_r &f32, out_g &f32, out_b &f32) {
	C.igColorConvertHSVtoRGB(h, s, v, out_r, out_g, out_b)
}

@[keep_args_alive]
fn C.igIsKeyDown_Nil(key Key) bool

@[inline]
pub fn is_key_down_nil(key Key) bool {
	return C.igIsKeyDown_Nil(key)
}

@[keep_args_alive]
fn C.igIsKeyPressed_Bool(key Key, repeat bool) bool

@[inline]
pub fn is_key_pressed_bool(key Key, repeat bool) bool {
	return C.igIsKeyPressed_Bool(key, repeat)
}

@[keep_args_alive]
fn C.igIsKeyReleased_Nil(key Key) bool

@[inline]
pub fn is_key_released_nil(key Key) bool {
	return C.igIsKeyReleased_Nil(key)
}

@[keep_args_alive]
fn C.igIsKeyChordPressed_Nil(key_chord KeyChord) bool

@[inline]
pub fn is_key_chord_pressed_nil(key_chord KeyChord) bool {
	return C.igIsKeyChordPressed_Nil(key_chord)
}

@[keep_args_alive]
fn C.igGetKeyPressedAmount(key Key, repeat_delay f32, rate f32) i32

@[inline]
pub fn get_key_pressed_amount(key Key, repeat_delay f32, rate f32) i32 {
	return C.igGetKeyPressedAmount(key, repeat_delay, rate)
}

@[keep_args_alive]
fn C.igGetKeyName(key Key) &char

@[inline]
pub fn get_key_name(key Key) &char {
	return C.igGetKeyName(key)
}

@[keep_args_alive]
fn C.igSetNextFrameWantCaptureKeyboard(want_capture_keyboard bool)

@[inline]
pub fn set_next_frame_want_capture_keyboard(want_capture_keyboard bool) {
	C.igSetNextFrameWantCaptureKeyboard(want_capture_keyboard)
}

@[keep_args_alive]
fn C.igShortcut_Nil(key_chord KeyChord, flags InputFlags) bool

@[inline]
pub fn shortcut_nil(key_chord KeyChord, flags InputFlags) bool {
	return C.igShortcut_Nil(key_chord, flags)
}

@[keep_args_alive]
fn C.igSetNextItemShortcut(key_chord KeyChord, flags InputFlags)

@[inline]
pub fn set_next_item_shortcut(key_chord KeyChord, flags InputFlags) {
	C.igSetNextItemShortcut(key_chord, flags)
}

@[keep_args_alive]
fn C.igSetItemKeyOwner_Nil(key Key)

@[inline]
pub fn set_item_key_owner_nil(key Key) {
	C.igSetItemKeyOwner_Nil(key)
}

@[keep_args_alive]
fn C.igIsMouseDown_Nil(button MouseButton) bool

@[inline]
pub fn is_mouse_down_nil(button MouseButton) bool {
	return C.igIsMouseDown_Nil(button)
}

@[keep_args_alive]
fn C.igIsMouseClicked_Bool(button MouseButton, repeat bool) bool

@[inline]
pub fn is_mouse_clicked_bool(button MouseButton, repeat bool) bool {
	return C.igIsMouseClicked_Bool(button, repeat)
}

@[keep_args_alive]
fn C.igIsMouseReleased_Nil(button MouseButton) bool

@[inline]
pub fn is_mouse_released_nil(button MouseButton) bool {
	return C.igIsMouseReleased_Nil(button)
}

@[keep_args_alive]
fn C.igIsMouseDoubleClicked_Nil(button MouseButton) bool

@[inline]
pub fn is_mouse_double_clicked_nil(button MouseButton) bool {
	return C.igIsMouseDoubleClicked_Nil(button)
}

@[keep_args_alive]
fn C.igIsMouseReleasedWithDelay(button MouseButton, delay f32) bool

@[inline]
pub fn is_mouse_released_with_delay(button MouseButton, delay f32) bool {
	return C.igIsMouseReleasedWithDelay(button, delay)
}

@[keep_args_alive]
fn C.igGetMouseClickedCount(button MouseButton) i32

@[inline]
pub fn get_mouse_clicked_count(button MouseButton) i32 {
	return C.igGetMouseClickedCount(button)
}

@[keep_args_alive]
fn C.igIsMouseHoveringRect(r_min ImVec2_c, r_max ImVec2_c, clip bool) bool

@[inline]
pub fn is_mouse_hovering_rect(r_min ImVec2_c, r_max ImVec2_c, clip bool) bool {
	return C.igIsMouseHoveringRect(r_min, r_max, clip)
}

@[keep_args_alive]
fn C.igIsMousePosValid(mouse_pos &ImVec2_c) bool

@[inline]
pub fn is_mouse_pos_valid(mouse_pos &ImVec2_c) bool {
	return C.igIsMousePosValid(mouse_pos)
}

@[keep_args_alive]
fn C.igIsAnyMouseDown() bool

@[inline]
pub fn is_any_mouse_down() bool {
	return C.igIsAnyMouseDown()
}

@[keep_args_alive]
fn C.igGetMousePos() ImVec2_c

@[inline]
pub fn get_mouse_pos() ImVec2_c {
	return C.igGetMousePos()
}

@[keep_args_alive]
fn C.igGetMousePosOnOpeningCurrentPopup() ImVec2_c

@[inline]
pub fn get_mouse_pos_on_opening_current_popup() ImVec2_c {
	return C.igGetMousePosOnOpeningCurrentPopup()
}

@[keep_args_alive]
fn C.igIsMouseDragging(button MouseButton, lock_threshold f32) bool

@[inline]
pub fn is_mouse_dragging(button MouseButton, lock_threshold f32) bool {
	return C.igIsMouseDragging(button, lock_threshold)
}

@[keep_args_alive]
fn C.igGetMouseDragDelta(button MouseButton, lock_threshold f32) ImVec2_c

@[inline]
pub fn get_mouse_drag_delta(button MouseButton, lock_threshold f32) ImVec2_c {
	return C.igGetMouseDragDelta(button, lock_threshold)
}

@[keep_args_alive]
fn C.igResetMouseDragDelta(button MouseButton)

@[inline]
pub fn reset_mouse_drag_delta(button MouseButton) {
	C.igResetMouseDragDelta(button)
}

@[keep_args_alive]
fn C.igGetMouseCursor() MouseCursor

@[inline]
pub fn get_mouse_cursor() MouseCursor {
	return C.igGetMouseCursor()
}

@[keep_args_alive]
fn C.igSetMouseCursor(cursor_type MouseCursor)

@[inline]
pub fn set_mouse_cursor(cursor_type MouseCursor) {
	C.igSetMouseCursor(cursor_type)
}

@[keep_args_alive]
fn C.igSetNextFrameWantCaptureMouse(want_capture_mouse bool)

@[inline]
pub fn set_next_frame_want_capture_mouse(want_capture_mouse bool) {
	C.igSetNextFrameWantCaptureMouse(want_capture_mouse)
}

@[keep_args_alive]
fn C.igGetClipboardText() &char

@[inline]
pub fn get_clipboard_text() &char {
	return C.igGetClipboardText()
}

@[keep_args_alive]
fn C.igSetClipboardText(const_text &char)

@[inline]
pub fn set_clipboard_text(const_text &char) {
	C.igSetClipboardText(const_text)
}

@[keep_args_alive]
fn C.igLoadIniSettingsFromDisk(ini_filename &char)

@[inline]
pub fn load_ini_settings_from_disk(ini_filename &char) {
	C.igLoadIniSettingsFromDisk(ini_filename)
}

@[keep_args_alive]
fn C.igLoadIniSettingsFromMemory(ini_data &char, ini_size usize)

@[inline]
pub fn load_ini_settings_from_memory(ini_data &char, ini_size usize) {
	C.igLoadIniSettingsFromMemory(ini_data, ini_size)
}

@[keep_args_alive]
fn C.igSaveIniSettingsToDisk(ini_filename &char)

@[inline]
pub fn save_ini_settings_to_disk(ini_filename &char) {
	C.igSaveIniSettingsToDisk(ini_filename)
}

@[keep_args_alive]
fn C.igSaveIniSettingsToMemory(out_ini_size &usize) &char

@[inline]
pub fn save_ini_settings_to_memory(out_ini_size &usize) &char {
	return C.igSaveIniSettingsToMemory(out_ini_size)
}

@[keep_args_alive]
fn C.igDebugTextEncoding(const_text &char)

@[inline]
pub fn debug_text_encoding(const_text &char) {
	C.igDebugTextEncoding(const_text)
}

@[keep_args_alive]
fn C.igDebugFlashStyleColor(idx Col)

@[inline]
pub fn debug_flash_style_color(idx Col) {
	C.igDebugFlashStyleColor(idx)
}

@[keep_args_alive]
fn C.igDebugStartItemPicker()

@[inline]
pub fn debug_start_item_picker() {
	C.igDebugStartItemPicker()
}

@[keep_args_alive]
fn C.igDebugCheckVersionAndDataLayout(version_str &char, sz_io usize, sz_style usize, sz_vec2 usize, sz_vec4 usize, sz_drawvert usize, sz_drawidx usize) bool

@[inline]
pub fn debug_check_version_and_data_layout(version_str &char, sz_io usize, sz_style usize, sz_vec2 usize, sz_vec4 usize, sz_drawvert usize, sz_drawidx usize) bool {
	return C.igDebugCheckVersionAndDataLayout(version_str, sz_io, sz_style, sz_vec2, sz_vec4,
		sz_drawvert, sz_drawidx)
}

@[keep_args_alive]
fn C.igDebugLog(const_fmt &char)

@[inline]
pub fn debug_log(const_fmt &char) {
	C.igDebugLog(const_fmt)
}

@[keep_args_alive]
fn C.igDebugLogV(const_fmt &char, args Va_list)

@[inline]
pub fn debug_log_v(const_fmt &char, args Va_list) {
	C.igDebugLogV(const_fmt, args)
}

@[keep_args_alive]
fn C.igSetAllocatorFunctions(alloc_func MemAllocFunc, free_func MemFreeFunc, user_data voidptr)

@[inline]
pub fn set_allocator_functions(alloc_func MemAllocFunc, free_func MemFreeFunc, user_data voidptr) {
	C.igSetAllocatorFunctions(alloc_func, free_func, user_data)
}

@[keep_args_alive]
fn C.igGetAllocatorFunctions(p_alloc_func &MemAllocFunc, p_free_func &MemFreeFunc, p_user_data &voidptr)

@[inline]
pub fn get_allocator_functions(p_alloc_func &MemAllocFunc, p_free_func &MemFreeFunc, p_user_data &voidptr) {
	C.igGetAllocatorFunctions(p_alloc_func, p_free_func, p_user_data)
}

@[keep_args_alive]
fn C.igMemAlloc(size usize) voidptr

@[inline]
pub fn mem_alloc(size usize) voidptr {
	return C.igMemAlloc(size)
}

@[keep_args_alive]
fn C.igMemFree(ptr voidptr)

@[inline]
pub fn mem_free(ptr voidptr) {
	C.igMemFree(ptr)
}

@[keep_args_alive]
fn C.igUpdatePlatformWindows()

@[inline]
pub fn update_platform_windows() {
	C.igUpdatePlatformWindows()
}

@[keep_args_alive]
fn C.igRenderPlatformWindowsDefault(platform_render_arg voidptr, renderer_render_arg voidptr)

@[inline]
pub fn render_platform_windows_default(platform_render_arg voidptr, renderer_render_arg voidptr) {
	C.igRenderPlatformWindowsDefault(platform_render_arg, renderer_render_arg)
}

@[keep_args_alive]
fn C.igDestroyPlatformWindows()

@[inline]
pub fn destroy_platform_windows() {
	C.igDestroyPlatformWindows()
}

@[keep_args_alive]
fn C.igFindViewportByID(viewport_id ID) &Viewport

@[inline]
pub fn find_viewport_by_id(viewport_id ID) &Viewport {
	return C.igFindViewportByID(viewport_id)
}

@[keep_args_alive]
fn C.igFindViewportByPlatformHandle(platform_handle voidptr) &Viewport

@[inline]
pub fn find_viewport_by_platform_handle(platform_handle voidptr) &Viewport {
	return C.igFindViewportByPlatformHandle(platform_handle)
}

@[keep_args_alive]
fn C.ImGuiTableSortSpecs_ImGuiTableSortSpecs() &TableSortSpecs

@[inline]
pub fn table_sort_specs_table_sort_specs() &TableSortSpecs {
	return C.ImGuiTableSortSpecs_ImGuiTableSortSpecs()
}

@[keep_args_alive]
fn C.ImGuiTableSortSpecs_destroy(self &TableSortSpecs)

@[inline]
pub fn table_sort_specs_destroy(self &TableSortSpecs) {
	C.ImGuiTableSortSpecs_destroy(self)
}

@[keep_args_alive]
fn C.ImGuiTableColumnSortSpecs_ImGuiTableColumnSortSpecs() &TableColumnSortSpecs

@[inline]
pub fn table_column_sort_specs_table_column_sort_specs() &TableColumnSortSpecs {
	return C.ImGuiTableColumnSortSpecs_ImGuiTableColumnSortSpecs()
}

@[keep_args_alive]
fn C.ImGuiTableColumnSortSpecs_destroy(self &TableColumnSortSpecs)

@[inline]
pub fn table_column_sort_specs_destroy(self &TableColumnSortSpecs) {
	C.ImGuiTableColumnSortSpecs_destroy(self)
}

@[keep_args_alive]
fn C.ImGuiStyle_ImGuiStyle() &Style

@[inline]
pub fn style_style() &Style {
	return C.ImGuiStyle_ImGuiStyle()
}

@[keep_args_alive]
fn C.ImGuiStyle_destroy(self &Style)

@[inline]
pub fn style_destroy(self &Style) {
	C.ImGuiStyle_destroy(self)
}

@[keep_args_alive]
fn C.ImGuiStyle_ScaleAllSizes(self &Style, scale_factor f32)

@[inline]
pub fn style_scale_all_sizes(self &Style, scale_factor f32) {
	C.ImGuiStyle_ScaleAllSizes(self, scale_factor)
}

@[keep_args_alive]
fn C.ImGuiIO_AddKeyEvent(self &IO, key Key, down bool)

@[inline]
pub fn io_add_key_event(self &IO, key Key, down bool) {
	C.ImGuiIO_AddKeyEvent(self, key, down)
}

@[keep_args_alive]
fn C.ImGuiIO_AddKeyAnalogEvent(self &IO, key Key, down bool, v f32)

@[inline]
pub fn io_add_key_analog_event(self &IO, key Key, down bool, v f32) {
	C.ImGuiIO_AddKeyAnalogEvent(self, key, down, v)
}

@[keep_args_alive]
fn C.ImGuiIO_AddMousePosEvent(self &IO, x f32, y f32)

@[inline]
pub fn io_add_mouse_pos_event(self &IO, x f32, y f32) {
	C.ImGuiIO_AddMousePosEvent(self, x, y)
}

@[keep_args_alive]
fn C.ImGuiIO_AddMouseButtonEvent(self &IO, button i32, down bool)

@[inline]
pub fn io_add_mouse_button_event(self &IO, button i32, down bool) {
	C.ImGuiIO_AddMouseButtonEvent(self, button, down)
}

@[keep_args_alive]
fn C.ImGuiIO_AddMouseWheelEvent(self &IO, wheel_x f32, wheel_y f32)

@[inline]
pub fn io_add_mouse_wheel_event(self &IO, wheel_x f32, wheel_y f32) {
	C.ImGuiIO_AddMouseWheelEvent(self, wheel_x, wheel_y)
}

@[keep_args_alive]
fn C.ImGuiIO_AddMouseSourceEvent(self &IO, source MouseSource)

@[inline]
pub fn io_add_mouse_source_event(self &IO, source MouseSource) {
	C.ImGuiIO_AddMouseSourceEvent(self, source)
}

@[keep_args_alive]
fn C.ImGuiIO_AddMouseViewportEvent(self &IO, id ID)

@[inline]
pub fn io_add_mouse_viewport_event(self &IO, id ID) {
	C.ImGuiIO_AddMouseViewportEvent(self, id)
}

@[keep_args_alive]
fn C.ImGuiIO_AddFocusEvent(self &IO, focused bool)

@[inline]
pub fn io_add_focus_event(self &IO, focused bool) {
	C.ImGuiIO_AddFocusEvent(self, focused)
}

@[keep_args_alive]
fn C.ImGuiIO_AddInputCharacter(self &IO, c u32)

@[inline]
pub fn io_add_input_character(self &IO, c u32) {
	C.ImGuiIO_AddInputCharacter(self, c)
}

@[keep_args_alive]
fn C.ImGuiIO_AddInputCharacterUTF16(self &IO, c ImWchar16)

@[inline]
pub fn io_add_input_character_utf_16(self &IO, c ImWchar16) {
	C.ImGuiIO_AddInputCharacterUTF16(self, c)
}

@[keep_args_alive]
fn C.ImGuiIO_AddInputCharactersUTF8(self &IO, const_str &char)

@[inline]
pub fn io_add_input_characters_utf_8(self &IO, const_str &char) {
	C.ImGuiIO_AddInputCharactersUTF8(self, const_str)
}

@[keep_args_alive]
fn C.ImGuiIO_SetKeyEventNativeData(self &IO, key Key, native_keycode i32, native_scancode i32, native_legacy_index i32)

@[inline]
pub fn io_set_key_event_native_data(self &IO, key Key, native_keycode i32, native_scancode i32, native_legacy_index i32) {
	C.ImGuiIO_SetKeyEventNativeData(self, key, native_keycode, native_scancode, native_legacy_index)
}

@[keep_args_alive]
fn C.ImGuiIO_SetAppAcceptingEvents(self &IO, accepting_events bool)

@[inline]
pub fn io_set_app_accepting_events(self &IO, accepting_events bool) {
	C.ImGuiIO_SetAppAcceptingEvents(self, accepting_events)
}

@[keep_args_alive]
fn C.ImGuiIO_ClearEventsQueue(self &IO)

@[inline]
pub fn io_clear_events_queue(self &IO) {
	C.ImGuiIO_ClearEventsQueue(self)
}

@[keep_args_alive]
fn C.ImGuiIO_ClearInputKeys(self &IO)

@[inline]
pub fn io_clear_input_keys(self &IO) {
	C.ImGuiIO_ClearInputKeys(self)
}

@[keep_args_alive]
fn C.ImGuiIO_ClearInputMouse(self &IO)

@[inline]
pub fn io_clear_input_mouse(self &IO) {
	C.ImGuiIO_ClearInputMouse(self)
}

@[keep_args_alive]
fn C.ImGuiIO_ImGuiIO() &IO

@[inline]
pub fn io_io() &IO {
	return C.ImGuiIO_ImGuiIO()
}

@[keep_args_alive]
fn C.ImGuiIO_destroy(self &IO)

@[inline]
pub fn io_destroy(self &IO) {
	C.ImGuiIO_destroy(self)
}

@[keep_args_alive]
fn C.ImGuiInputTextCallbackData_ImGuiInputTextCallbackData() &InputTextCallbackData

@[inline]
pub fn input_text_callback_data_input_text_callback_data() &InputTextCallbackData {
	return C.ImGuiInputTextCallbackData_ImGuiInputTextCallbackData()
}

@[keep_args_alive]
fn C.ImGuiInputTextCallbackData_destroy(self &InputTextCallbackData)

@[inline]
pub fn input_text_callback_data_destroy(self &InputTextCallbackData) {
	C.ImGuiInputTextCallbackData_destroy(self)
}

@[keep_args_alive]
fn C.ImGuiInputTextCallbackData_DeleteChars(self &InputTextCallbackData, pos i32, bytes_count i32)

@[inline]
pub fn input_text_callback_data_delete_chars(self &InputTextCallbackData, pos i32, bytes_count i32) {
	C.ImGuiInputTextCallbackData_DeleteChars(self, pos, bytes_count)
}

@[keep_args_alive]
fn C.ImGuiInputTextCallbackData_InsertChars(self &InputTextCallbackData, pos i32, const_text &char, const_text_end &char)

@[inline]
pub fn input_text_callback_data_insert_chars(self &InputTextCallbackData, pos i32, const_text &char, const_text_end &char) {
	C.ImGuiInputTextCallbackData_InsertChars(self, pos, const_text, const_text_end)
}

@[keep_args_alive]
fn C.ImGuiInputTextCallbackData_SelectAll(self &InputTextCallbackData)

@[inline]
pub fn input_text_callback_data_select_all(self &InputTextCallbackData) {
	C.ImGuiInputTextCallbackData_SelectAll(self)
}

@[keep_args_alive]
fn C.ImGuiInputTextCallbackData_SetSelection(self &InputTextCallbackData, s i32, e i32)

@[inline]
pub fn input_text_callback_data_set_selection(self &InputTextCallbackData, s i32, e i32) {
	C.ImGuiInputTextCallbackData_SetSelection(self, s, e)
}

@[keep_args_alive]
fn C.ImGuiInputTextCallbackData_ClearSelection(self &InputTextCallbackData)

@[inline]
pub fn input_text_callback_data_clear_selection(self &InputTextCallbackData) {
	C.ImGuiInputTextCallbackData_ClearSelection(self)
}

@[keep_args_alive]
fn C.ImGuiInputTextCallbackData_HasSelection(self &InputTextCallbackData) bool

@[inline]
pub fn input_text_callback_data_has_selection(self &InputTextCallbackData) bool {
	return C.ImGuiInputTextCallbackData_HasSelection(self)
}

@[keep_args_alive]
fn C.ImGuiWindowClass_ImGuiWindowClass() &WindowClass

@[inline]
pub fn window_class_window_class() &WindowClass {
	return C.ImGuiWindowClass_ImGuiWindowClass()
}

@[keep_args_alive]
fn C.ImGuiWindowClass_destroy(self &WindowClass)

@[inline]
pub fn window_class_destroy(self &WindowClass) {
	C.ImGuiWindowClass_destroy(self)
}

@[keep_args_alive]
fn C.ImGuiPayload_ImGuiPayload() &Payload

@[inline]
pub fn payload_payload() &Payload {
	return C.ImGuiPayload_ImGuiPayload()
}

@[keep_args_alive]
fn C.ImGuiPayload_destroy(self &Payload)

@[inline]
pub fn payload_destroy(self &Payload) {
	C.ImGuiPayload_destroy(self)
}

@[keep_args_alive]
fn C.ImGuiPayload_Clear(self &Payload)

@[inline]
pub fn payload_clear(self &Payload) {
	C.ImGuiPayload_Clear(self)
}

@[keep_args_alive]
fn C.ImGuiPayload_IsDataType(self &Payload, type_ &char) bool

@[inline]
pub fn payload_is_data_type(self &Payload, type_ &char) bool {
	return C.ImGuiPayload_IsDataType(self, type_)
}

@[keep_args_alive]
fn C.ImGuiPayload_IsPreview(self &Payload) bool

@[inline]
pub fn payload_is_preview(self &Payload) bool {
	return C.ImGuiPayload_IsPreview(self)
}

@[keep_args_alive]
fn C.ImGuiPayload_IsDelivery(self &Payload) bool

@[inline]
pub fn payload_is_delivery(self &Payload) bool {
	return C.ImGuiPayload_IsDelivery(self)
}

@[keep_args_alive]
fn C.ImGuiOnceUponAFrame_ImGuiOnceUponAFrame() &OnceUponAFrame

@[inline]
pub fn once_upon_af_rame_once_upon_af_rame() &OnceUponAFrame {
	return C.ImGuiOnceUponAFrame_ImGuiOnceUponAFrame()
}

@[keep_args_alive]
fn C.ImGuiOnceUponAFrame_destroy(self &OnceUponAFrame)

@[inline]
pub fn once_upon_af_rame_destroy(self &OnceUponAFrame) {
	C.ImGuiOnceUponAFrame_destroy(self)
}

@[keep_args_alive]
fn C.ImGuiTextFilter_ImGuiTextFilter(default_filter &char) &TextFilter

@[inline]
pub fn text_filter_text_filter(default_filter &char) &TextFilter {
	return C.ImGuiTextFilter_ImGuiTextFilter(default_filter)
}

@[keep_args_alive]
fn C.ImGuiTextFilter_destroy(self &TextFilter)

@[inline]
pub fn text_filter_destroy(self &TextFilter) {
	C.ImGuiTextFilter_destroy(self)
}

@[keep_args_alive]
fn C.ImGuiTextFilter_Draw(self &TextFilter, const_label &char, width f32) bool

@[inline]
pub fn text_filter_draw(self &TextFilter, const_label &char, width f32) bool {
	return C.ImGuiTextFilter_Draw(self, const_label, width)
}

@[keep_args_alive]
fn C.ImGuiTextFilter_PassFilter(self &TextFilter, const_text &char, const_text_end &char) bool

@[inline]
pub fn text_filter_pass_filter(self &TextFilter, const_text &char, const_text_end &char) bool {
	return C.ImGuiTextFilter_PassFilter(self, const_text, const_text_end)
}

@[keep_args_alive]
fn C.ImGuiTextFilter_Build(self &TextFilter)

@[inline]
pub fn text_filter_build(self &TextFilter) {
	C.ImGuiTextFilter_Build(self)
}

@[keep_args_alive]
fn C.ImGuiTextFilter_Clear(self &TextFilter)

@[inline]
pub fn text_filter_clear(self &TextFilter) {
	C.ImGuiTextFilter_Clear(self)
}

@[keep_args_alive]
fn C.ImGuiTextFilter_IsActive(self &TextFilter) bool

@[inline]
pub fn text_filter_is_active(self &TextFilter) bool {
	return C.ImGuiTextFilter_IsActive(self)
}

@[keep_args_alive]
fn C.ImGuiTextRange_ImGuiTextRange_Nil() &TextRange

@[inline]
pub fn text_range_text_range_nil() &TextRange {
	return C.ImGuiTextRange_ImGuiTextRange_Nil()
}

@[keep_args_alive]
fn C.ImGuiTextRange_destroy(self &TextRange)

@[inline]
pub fn text_range_destroy(self &TextRange) {
	C.ImGuiTextRange_destroy(self)
}

@[keep_args_alive]
fn C.ImGuiTextRange_ImGuiTextRange_Str(_b &char, _e &char) &TextRange

@[inline]
pub fn text_range_text_range_str(_b &char, _e &char) &TextRange {
	return C.ImGuiTextRange_ImGuiTextRange_Str(_b, _e)
}

@[keep_args_alive]
fn C.ImGuiTextRange_empty(self &TextRange) bool

@[inline]
pub fn text_range_empty(self &TextRange) bool {
	return C.ImGuiTextRange_empty(self)
}

@[keep_args_alive]
fn C.ImGuiTextRange_split(self &TextRange, separator i8, out &ImVector_TextRange)

@[inline]
pub fn text_range_split(self &TextRange, separator i8, out &ImVector_TextRange) {
	C.ImGuiTextRange_split(self, separator, out)
}

@[keep_args_alive]
fn C.ImGuiTextBuffer_ImGuiTextBuffer() &TextBuffer

@[inline]
pub fn text_buffer_text_buffer() &TextBuffer {
	return C.ImGuiTextBuffer_ImGuiTextBuffer()
}

@[keep_args_alive]
fn C.ImGuiTextBuffer_destroy(self &TextBuffer)

@[inline]
pub fn text_buffer_destroy(self &TextBuffer) {
	C.ImGuiTextBuffer_destroy(self)
}

@[keep_args_alive]
fn C.ImGuiTextBuffer_begin(self &TextBuffer) &char

@[inline]
pub fn text_buffer_begin(self &TextBuffer) &char {
	return C.ImGuiTextBuffer_begin(self)
}

@[keep_args_alive]
fn C.ImGuiTextBuffer_end(self &TextBuffer) &char

@[inline]
pub fn text_buffer_end(self &TextBuffer) &char {
	return C.ImGuiTextBuffer_end(self)
}

@[keep_args_alive]
fn C.ImGuiTextBuffer_size(self &TextBuffer) i32

@[inline]
pub fn text_buffer_size(self &TextBuffer) i32 {
	return C.ImGuiTextBuffer_size(self)
}

@[keep_args_alive]
fn C.ImGuiTextBuffer_empty(self &TextBuffer) bool

@[inline]
pub fn text_buffer_empty(self &TextBuffer) bool {
	return C.ImGuiTextBuffer_empty(self)
}

@[keep_args_alive]
fn C.ImGuiTextBuffer_clear(self &TextBuffer)

@[inline]
pub fn text_buffer_clear(self &TextBuffer) {
	C.ImGuiTextBuffer_clear(self)
}

@[keep_args_alive]
fn C.ImGuiTextBuffer_resize(self &TextBuffer, size i32)

@[inline]
pub fn text_buffer_resize(self &TextBuffer, size i32) {
	C.ImGuiTextBuffer_resize(self, size)
}

@[keep_args_alive]
fn C.ImGuiTextBuffer_reserve(self &TextBuffer, capacity i32)

@[inline]
pub fn text_buffer_reserve(self &TextBuffer, capacity i32) {
	C.ImGuiTextBuffer_reserve(self, capacity)
}

@[keep_args_alive]
fn C.ImGuiTextBuffer_c_str(self &TextBuffer) &char

@[inline]
pub fn text_buffer_c_str(self &TextBuffer) &char {
	return C.ImGuiTextBuffer_c_str(self)
}

@[keep_args_alive]
fn C.ImGuiTextBuffer_append(self &TextBuffer, const_str &char, str_end &char)

@[inline]
pub fn text_buffer_append(self &TextBuffer, const_str &char, str_end &char) {
	C.ImGuiTextBuffer_append(self, const_str, str_end)
}

@[keep_args_alive]
fn C.ImGuiTextBuffer_appendfv(self &TextBuffer, const_fmt &char, args Va_list)

@[inline]
pub fn text_buffer_appendfv(self &TextBuffer, const_fmt &char, args Va_list) {
	C.ImGuiTextBuffer_appendfv(self, const_fmt, args)
}

@[keep_args_alive]
fn C.ImGuiStoragePair_ImGuiStoragePair_Int(_key ID, _val i32) &StoragePair

@[inline]
pub fn storage_pair_storage_pair_int(_key ID, _val i32) &StoragePair {
	return C.ImGuiStoragePair_ImGuiStoragePair_Int(_key, _val)
}

@[keep_args_alive]
fn C.ImGuiStoragePair_destroy(self &StoragePair)

@[inline]
pub fn storage_pair_destroy(self &StoragePair) {
	C.ImGuiStoragePair_destroy(self)
}

@[keep_args_alive]
fn C.ImGuiStoragePair_ImGuiStoragePair_Float(_key ID, _val f32) &StoragePair

@[inline]
pub fn storage_pair_storage_pair_float(_key ID, _val f32) &StoragePair {
	return C.ImGuiStoragePair_ImGuiStoragePair_Float(_key, _val)
}

@[keep_args_alive]
fn C.ImGuiStoragePair_ImGuiStoragePair_Ptr(_key ID, _val voidptr) &StoragePair

@[inline]
pub fn storage_pair_storage_pair_ptr(_key ID, _val voidptr) &StoragePair {
	return C.ImGuiStoragePair_ImGuiStoragePair_Ptr(_key, _val)
}

@[keep_args_alive]
fn C.ImGuiStorage_Clear(self &Storage)

@[inline]
pub fn storage_clear(self &Storage) {
	C.ImGuiStorage_Clear(self)
}

@[keep_args_alive]
fn C.ImGuiStorage_GetInt(self &Storage, key ID, default_val i32) i32

@[inline]
pub fn storage_get_int(self &Storage, key ID, default_val i32) i32 {
	return C.ImGuiStorage_GetInt(self, key, default_val)
}

@[keep_args_alive]
fn C.ImGuiStorage_SetInt(self &Storage, key ID, val i32)

@[inline]
pub fn storage_set_int(self &Storage, key ID, val i32) {
	C.ImGuiStorage_SetInt(self, key, val)
}

@[keep_args_alive]
fn C.ImGuiStorage_GetBool(self &Storage, key ID, default_val bool) bool

@[inline]
pub fn storage_get_bool(self &Storage, key ID, default_val bool) bool {
	return C.ImGuiStorage_GetBool(self, key, default_val)
}

@[keep_args_alive]
fn C.ImGuiStorage_SetBool(self &Storage, key ID, val bool)

@[inline]
pub fn storage_set_bool(self &Storage, key ID, val bool) {
	C.ImGuiStorage_SetBool(self, key, val)
}

@[keep_args_alive]
fn C.ImGuiStorage_GetFloat(self &Storage, key ID, default_val f32) f32

@[inline]
pub fn storage_get_float(self &Storage, key ID, default_val f32) f32 {
	return C.ImGuiStorage_GetFloat(self, key, default_val)
}

@[keep_args_alive]
fn C.ImGuiStorage_SetFloat(self &Storage, key ID, val f32)

@[inline]
pub fn storage_set_float(self &Storage, key ID, val f32) {
	C.ImGuiStorage_SetFloat(self, key, val)
}

@[keep_args_alive]
fn C.ImGuiStorage_GetVoidPtr(self &Storage, key ID) voidptr

@[inline]
pub fn storage_get_void_ptr(self &Storage, key ID) voidptr {
	return C.ImGuiStorage_GetVoidPtr(self, key)
}

@[keep_args_alive]
fn C.ImGuiStorage_SetVoidPtr(self &Storage, key ID, val voidptr)

@[inline]
pub fn storage_set_void_ptr(self &Storage, key ID, val voidptr) {
	C.ImGuiStorage_SetVoidPtr(self, key, val)
}

@[keep_args_alive]
fn C.ImGuiStorage_GetIntRef(self &Storage, key ID, default_val i32) &i32

@[inline]
pub fn storage_get_int_ref(self &Storage, key ID, default_val i32) &i32 {
	return C.ImGuiStorage_GetIntRef(self, key, default_val)
}

@[keep_args_alive]
fn C.ImGuiStorage_GetBoolRef(self &Storage, key ID, default_val bool) &bool

@[inline]
pub fn storage_get_bool_ref(self &Storage, key ID, default_val bool) &bool {
	return C.ImGuiStorage_GetBoolRef(self, key, default_val)
}

@[keep_args_alive]
fn C.ImGuiStorage_GetFloatRef(self &Storage, key ID, default_val f32) &f32

@[inline]
pub fn storage_get_float_ref(self &Storage, key ID, default_val f32) &f32 {
	return C.ImGuiStorage_GetFloatRef(self, key, default_val)
}

@[keep_args_alive]
fn C.ImGuiStorage_GetVoidPtrRef(self &Storage, key ID, default_val voidptr) &voidptr

@[inline]
pub fn storage_get_void_ptr_ref(self &Storage, key ID, default_val voidptr) &voidptr {
	return C.ImGuiStorage_GetVoidPtrRef(self, key, default_val)
}

@[keep_args_alive]
fn C.ImGuiStorage_BuildSortByKey(self &Storage)

@[inline]
pub fn storage_build_sort_by_key(self &Storage) {
	C.ImGuiStorage_BuildSortByKey(self)
}

@[keep_args_alive]
fn C.ImGuiStorage_SetAllInt(self &Storage, val i32)

@[inline]
pub fn storage_set_all_int(self &Storage, val i32) {
	C.ImGuiStorage_SetAllInt(self, val)
}

@[keep_args_alive]
fn C.ImGuiListClipper_ImGuiListClipper() &ListClipper

@[inline]
pub fn list_clipper_list_clipper() &ListClipper {
	return C.ImGuiListClipper_ImGuiListClipper()
}

@[keep_args_alive]
fn C.ImGuiListClipper_destroy(self &ListClipper)

@[inline]
pub fn list_clipper_destroy(self &ListClipper) {
	C.ImGuiListClipper_destroy(self)
}

@[keep_args_alive]
fn C.ImGuiListClipper_Begin(self &ListClipper, items_count i32, items_height f32)

@[inline]
pub fn list_clipper_begin(self &ListClipper, items_count i32, items_height f32) {
	C.ImGuiListClipper_Begin(self, items_count, items_height)
}

@[keep_args_alive]
fn C.ImGuiListClipper_End(self &ListClipper)

@[inline]
pub fn list_clipper_end(self &ListClipper) {
	C.ImGuiListClipper_End(self)
}

@[keep_args_alive]
fn C.ImGuiListClipper_Step(self &ListClipper) bool

@[inline]
pub fn list_clipper_step(self &ListClipper) bool {
	return C.ImGuiListClipper_Step(self)
}

@[keep_args_alive]
fn C.ImGuiListClipper_IncludeItemByIndex(self &ListClipper, item_index i32)

@[inline]
pub fn list_clipper_include_item_by_index(self &ListClipper, item_index i32) {
	C.ImGuiListClipper_IncludeItemByIndex(self, item_index)
}

@[keep_args_alive]
fn C.ImGuiListClipper_IncludeItemsByIndex(self &ListClipper, item_begin i32, item_end i32)

@[inline]
pub fn list_clipper_include_items_by_index(self &ListClipper, item_begin i32, item_end i32) {
	C.ImGuiListClipper_IncludeItemsByIndex(self, item_begin, item_end)
}

@[keep_args_alive]
fn C.ImGuiListClipper_SeekCursorForItem(self &ListClipper, item_index i32)

@[inline]
pub fn list_clipper_seek_cursor_for_item(self &ListClipper, item_index i32) {
	C.ImGuiListClipper_SeekCursorForItem(self, item_index)
}

@[keep_args_alive]
fn C.ImColor_ImColor_Nil() &ImColor

@[inline]
pub fn im_color_im_color_nil() &ImColor {
	return C.ImColor_ImColor_Nil()
}

@[keep_args_alive]
fn C.ImColor_destroy(self &ImColor)

@[inline]
pub fn im_color_destroy(self &ImColor) {
	C.ImColor_destroy(self)
}

@[keep_args_alive]
fn C.ImColor_ImColor_Float(r f32, g f32, b f32, a f32) &ImColor

@[inline]
pub fn im_color_im_color_float(r f32, g f32, b f32, a f32) &ImColor {
	return C.ImColor_ImColor_Float(r, g, b, a)
}

@[keep_args_alive]
fn C.ImColor_ImColor_Vec4(col ImVec4_c) &ImColor

@[inline]
pub fn im_color_im_color_vec4(col ImVec4_c) &ImColor {
	return C.ImColor_ImColor_Vec4(col)
}

@[keep_args_alive]
fn C.ImColor_ImColor_Int(r i32, g i32, b i32, a i32) &ImColor

@[inline]
pub fn im_color_im_color_int(r i32, g i32, b i32, a i32) &ImColor {
	return C.ImColor_ImColor_Int(r, g, b, a)
}

@[keep_args_alive]
fn C.ImColor_ImColor_U32(rgba ImU32) &ImColor

@[inline]
pub fn im_color_im_color_u32(rgba ImU32) &ImColor {
	return C.ImColor_ImColor_U32(rgba)
}

@[keep_args_alive]
fn C.ImColor_SetHSV(self &ImColor, h f32, s f32, v f32, a f32)

@[inline]
pub fn im_color_set_hsv(self &ImColor, h f32, s f32, v f32, a f32) {
	C.ImColor_SetHSV(self, h, s, v, a)
}

@[keep_args_alive]
fn C.ImColor_HSV(h f32, s f32, v f32, a f32) ImColor_c

@[inline]
pub fn im_color_hsv(h f32, s f32, v f32, a f32) ImColor_c {
	return C.ImColor_HSV(h, s, v, a)
}

@[keep_args_alive]
fn C.ImGuiSelectionBasicStorage_ImGuiSelectionBasicStorage() &SelectionBasicStorage

@[inline]
pub fn selection_basic_storage_selection_basic_storage() &SelectionBasicStorage {
	return C.ImGuiSelectionBasicStorage_ImGuiSelectionBasicStorage()
}

@[keep_args_alive]
fn C.ImGuiSelectionBasicStorage_destroy(self &SelectionBasicStorage)

@[inline]
pub fn selection_basic_storage_destroy(self &SelectionBasicStorage) {
	C.ImGuiSelectionBasicStorage_destroy(self)
}

@[keep_args_alive]
fn C.ImGuiSelectionBasicStorage_ApplyRequests(self &SelectionBasicStorage, ms_io &MultiSelectIO)

@[inline]
pub fn selection_basic_storage_apply_requests(self &SelectionBasicStorage, ms_io &MultiSelectIO) {
	C.ImGuiSelectionBasicStorage_ApplyRequests(self, ms_io)
}

@[keep_args_alive]
fn C.ImGuiSelectionBasicStorage_Contains(self &SelectionBasicStorage, id ID) bool

@[inline]
pub fn selection_basic_storage_contains(self &SelectionBasicStorage, id ID) bool {
	return C.ImGuiSelectionBasicStorage_Contains(self, id)
}

@[keep_args_alive]
fn C.ImGuiSelectionBasicStorage_Clear(self &SelectionBasicStorage)

@[inline]
pub fn selection_basic_storage_clear(self &SelectionBasicStorage) {
	C.ImGuiSelectionBasicStorage_Clear(self)
}

@[keep_args_alive]
fn C.ImGuiSelectionBasicStorage_Swap(self &SelectionBasicStorage, r &SelectionBasicStorage)

@[inline]
pub fn selection_basic_storage_swap(self &SelectionBasicStorage, r &SelectionBasicStorage) {
	C.ImGuiSelectionBasicStorage_Swap(self, r)
}

@[keep_args_alive]
fn C.ImGuiSelectionBasicStorage_SetItemSelected(self &SelectionBasicStorage, id ID, selected bool)

@[inline]
pub fn selection_basic_storage_set_item_selected(self &SelectionBasicStorage, id ID, selected bool) {
	C.ImGuiSelectionBasicStorage_SetItemSelected(self, id, selected)
}

@[keep_args_alive]
fn C.ImGuiSelectionBasicStorage_GetNextSelectedItem(self &SelectionBasicStorage, opaque_it &voidptr, out_id &ID) bool

@[inline]
pub fn selection_basic_storage_get_next_selected_item(self &SelectionBasicStorage, opaque_it &voidptr, out_id &ID) bool {
	return C.ImGuiSelectionBasicStorage_GetNextSelectedItem(self, opaque_it, out_id)
}

@[keep_args_alive]
fn C.ImGuiSelectionBasicStorage_GetStorageIdFromIndex(self &SelectionBasicStorage, idx i32) ID

@[inline]
pub fn selection_basic_storage_get_storage_id_from_index(self &SelectionBasicStorage, idx i32) ID {
	return C.ImGuiSelectionBasicStorage_GetStorageIdFromIndex(self, idx)
}

@[keep_args_alive]
fn C.ImGuiSelectionExternalStorage_ImGuiSelectionExternalStorage() &SelectionExternalStorage

@[inline]
pub fn selection_external_storage_selection_external_storage() &SelectionExternalStorage {
	return C.ImGuiSelectionExternalStorage_ImGuiSelectionExternalStorage()
}

@[keep_args_alive]
fn C.ImGuiSelectionExternalStorage_destroy(self &SelectionExternalStorage)

@[inline]
pub fn selection_external_storage_destroy(self &SelectionExternalStorage) {
	C.ImGuiSelectionExternalStorage_destroy(self)
}

@[keep_args_alive]
fn C.ImGuiSelectionExternalStorage_ApplyRequests(self &SelectionExternalStorage, ms_io &MultiSelectIO)

@[inline]
pub fn selection_external_storage_apply_requests(self &SelectionExternalStorage, ms_io &MultiSelectIO) {
	C.ImGuiSelectionExternalStorage_ApplyRequests(self, ms_io)
}

@[keep_args_alive]
fn C.ImDrawCmd_ImDrawCmd() &ImDrawCmd

@[inline]
pub fn im_draw_cmd_im_draw_cmd() &ImDrawCmd {
	return C.ImDrawCmd_ImDrawCmd()
}

@[keep_args_alive]
fn C.ImDrawCmd_destroy(self &ImDrawCmd)

@[inline]
pub fn im_draw_cmd_destroy(self &ImDrawCmd) {
	C.ImDrawCmd_destroy(self)
}

@[keep_args_alive]
fn C.ImDrawCmd_GetTexID(self &ImDrawCmd) ImTextureID

@[inline]
pub fn im_draw_cmd_get_tex_id(self &ImDrawCmd) ImTextureID {
	return C.ImDrawCmd_GetTexID(self)
}

@[keep_args_alive]
fn C.ImDrawListSplitter_ImDrawListSplitter() &ImDrawListSplitter

@[inline]
pub fn im_draw_list_splitter_im_draw_list_splitter() &ImDrawListSplitter {
	return C.ImDrawListSplitter_ImDrawListSplitter()
}

@[keep_args_alive]
fn C.ImDrawListSplitter_destroy(self &ImDrawListSplitter)

@[inline]
pub fn im_draw_list_splitter_destroy(self &ImDrawListSplitter) {
	C.ImDrawListSplitter_destroy(self)
}

@[keep_args_alive]
fn C.ImDrawListSplitter_Clear(self &ImDrawListSplitter)

@[inline]
pub fn im_draw_list_splitter_clear(self &ImDrawListSplitter) {
	C.ImDrawListSplitter_Clear(self)
}

@[keep_args_alive]
fn C.ImDrawListSplitter_ClearFreeMemory(self &ImDrawListSplitter)

@[inline]
pub fn im_draw_list_splitter_clear_free_memory(self &ImDrawListSplitter) {
	C.ImDrawListSplitter_ClearFreeMemory(self)
}

@[keep_args_alive]
fn C.ImDrawListSplitter_Split(self &ImDrawListSplitter, draw_list &ImDrawList, count i32)

@[inline]
pub fn im_draw_list_splitter_split(self &ImDrawListSplitter, draw_list &ImDrawList, count i32) {
	C.ImDrawListSplitter_Split(self, draw_list, count)
}

@[keep_args_alive]
fn C.ImDrawListSplitter_Merge(self &ImDrawListSplitter, draw_list &ImDrawList)

@[inline]
pub fn im_draw_list_splitter_merge(self &ImDrawListSplitter, draw_list &ImDrawList) {
	C.ImDrawListSplitter_Merge(self, draw_list)
}

@[keep_args_alive]
fn C.ImDrawListSplitter_SetCurrentChannel(self &ImDrawListSplitter, draw_list &ImDrawList, channel_idx i32)

@[inline]
pub fn im_draw_list_splitter_set_current_channel(self &ImDrawListSplitter, draw_list &ImDrawList, channel_idx i32) {
	C.ImDrawListSplitter_SetCurrentChannel(self, draw_list, channel_idx)
}

@[keep_args_alive]
fn C.ImDrawList_ImDrawList(shared_data &ImDrawListSharedData) &ImDrawList

@[inline]
pub fn im_draw_list_im_draw_list(shared_data &ImDrawListSharedData) &ImDrawList {
	return C.ImDrawList_ImDrawList(shared_data)
}

@[keep_args_alive]
fn C.ImDrawList_destroy(self &ImDrawList)

@[inline]
pub fn im_draw_list_destroy(self &ImDrawList) {
	C.ImDrawList_destroy(self)
}

@[keep_args_alive]
fn C.ImDrawList_PushClipRect(self &ImDrawList, clip_rect_min ImVec2_c, clip_rect_max ImVec2_c, intersect_with_current_clip_rect bool)

@[inline]
pub fn im_draw_list_push_clip_rect(self &ImDrawList, clip_rect_min ImVec2_c, clip_rect_max ImVec2_c, intersect_with_current_clip_rect bool) {
	C.ImDrawList_PushClipRect(self, clip_rect_min, clip_rect_max, intersect_with_current_clip_rect)
}

@[keep_args_alive]
fn C.ImDrawList_PushClipRectFullScreen(self &ImDrawList)

@[inline]
pub fn im_draw_list_push_clip_rect_full_screen(self &ImDrawList) {
	C.ImDrawList_PushClipRectFullScreen(self)
}

@[keep_args_alive]
fn C.ImDrawList_PopClipRect(self &ImDrawList)

@[inline]
pub fn im_draw_list_pop_clip_rect(self &ImDrawList) {
	C.ImDrawList_PopClipRect(self)
}

@[keep_args_alive]
fn C.ImDrawList_PushTexture(self &ImDrawList, tex_ref ImTextureRef_c)

@[inline]
pub fn im_draw_list_push_texture(self &ImDrawList, tex_ref ImTextureRef_c) {
	C.ImDrawList_PushTexture(self, tex_ref)
}

@[keep_args_alive]
fn C.ImDrawList_PopTexture(self &ImDrawList)

@[inline]
pub fn im_draw_list_pop_texture(self &ImDrawList) {
	C.ImDrawList_PopTexture(self)
}

@[keep_args_alive]
fn C.ImDrawList_GetClipRectMin(self &ImDrawList) ImVec2_c

@[inline]
pub fn im_draw_list_get_clip_rect_min(self &ImDrawList) ImVec2_c {
	return C.ImDrawList_GetClipRectMin(self)
}

@[keep_args_alive]
fn C.ImDrawList_GetClipRectMax(self &ImDrawList) ImVec2_c

@[inline]
pub fn im_draw_list_get_clip_rect_max(self &ImDrawList) ImVec2_c {
	return C.ImDrawList_GetClipRectMax(self)
}

@[keep_args_alive]
fn C.ImDrawList_AddLine(self &ImDrawList, p1 ImVec2_c, p2 ImVec2_c, col ImU32, thickness f32)

@[inline]
pub fn im_draw_list_add_line(self &ImDrawList, p1 ImVec2_c, p2 ImVec2_c, col ImU32, thickness f32) {
	C.ImDrawList_AddLine(self, p1, p2, col, thickness)
}

@[keep_args_alive]
fn C.ImDrawList_AddRect(self &ImDrawList, p_min ImVec2_c, p_max ImVec2_c, col ImU32, rounding f32, flags ImDrawFlags, thickness f32)

@[inline]
pub fn im_draw_list_add_rect(self &ImDrawList, p_min ImVec2_c, p_max ImVec2_c, col ImU32, rounding f32, flags ImDrawFlags, thickness f32) {
	C.ImDrawList_AddRect(self, p_min, p_max, col, rounding, flags, thickness)
}

@[keep_args_alive]
fn C.ImDrawList_AddRectFilled(self &ImDrawList, p_min ImVec2_c, p_max ImVec2_c, col ImU32, rounding f32, flags ImDrawFlags)

@[inline]
pub fn im_draw_list_add_rect_filled(self &ImDrawList, p_min ImVec2_c, p_max ImVec2_c, col ImU32, rounding f32, flags ImDrawFlags) {
	C.ImDrawList_AddRectFilled(self, p_min, p_max, col, rounding, flags)
}

@[keep_args_alive]
fn C.ImDrawList_AddRectFilledMultiColor(self &ImDrawList, p_min ImVec2_c, p_max ImVec2_c, col_upr_left ImU32, col_upr_right ImU32, col_bot_right ImU32, col_bot_left ImU32)

@[inline]
pub fn im_draw_list_add_rect_filled_multi_color(self &ImDrawList, p_min ImVec2_c, p_max ImVec2_c, col_upr_left ImU32, col_upr_right ImU32, col_bot_right ImU32, col_bot_left ImU32) {
	C.ImDrawList_AddRectFilledMultiColor(self, p_min, p_max, col_upr_left, col_upr_right,
		col_bot_right, col_bot_left)
}

@[keep_args_alive]
fn C.ImDrawList_AddQuad(self &ImDrawList, p1 ImVec2_c, p2 ImVec2_c, p3 ImVec2_c, p4 ImVec2_c, col ImU32, thickness f32)

@[inline]
pub fn im_draw_list_add_quad(self &ImDrawList, p1 ImVec2_c, p2 ImVec2_c, p3 ImVec2_c, p4 ImVec2_c, col ImU32, thickness f32) {
	C.ImDrawList_AddQuad(self, p1, p2, p3, p4, col, thickness)
}

@[keep_args_alive]
fn C.ImDrawList_AddQuadFilled(self &ImDrawList, p1 ImVec2_c, p2 ImVec2_c, p3 ImVec2_c, p4 ImVec2_c, col ImU32)

@[inline]
pub fn im_draw_list_add_quad_filled(self &ImDrawList, p1 ImVec2_c, p2 ImVec2_c, p3 ImVec2_c, p4 ImVec2_c, col ImU32) {
	C.ImDrawList_AddQuadFilled(self, p1, p2, p3, p4, col)
}

@[keep_args_alive]
fn C.ImDrawList_AddTriangle(self &ImDrawList, p1 ImVec2_c, p2 ImVec2_c, p3 ImVec2_c, col ImU32, thickness f32)

@[inline]
pub fn im_draw_list_add_triangle(self &ImDrawList, p1 ImVec2_c, p2 ImVec2_c, p3 ImVec2_c, col ImU32, thickness f32) {
	C.ImDrawList_AddTriangle(self, p1, p2, p3, col, thickness)
}

@[keep_args_alive]
fn C.ImDrawList_AddTriangleFilled(self &ImDrawList, p1 ImVec2_c, p2 ImVec2_c, p3 ImVec2_c, col ImU32)

@[inline]
pub fn im_draw_list_add_triangle_filled(self &ImDrawList, p1 ImVec2_c, p2 ImVec2_c, p3 ImVec2_c, col ImU32) {
	C.ImDrawList_AddTriangleFilled(self, p1, p2, p3, col)
}

@[keep_args_alive]
fn C.ImDrawList_AddCircle(self &ImDrawList, center ImVec2_c, radius f32, col ImU32, num_segments i32, thickness f32)

@[inline]
pub fn im_draw_list_add_circle(self &ImDrawList, center ImVec2_c, radius f32, col ImU32, num_segments i32, thickness f32) {
	C.ImDrawList_AddCircle(self, center, radius, col, num_segments, thickness)
}

@[keep_args_alive]
fn C.ImDrawList_AddCircleFilled(self &ImDrawList, center ImVec2_c, radius f32, col ImU32, num_segments i32)

@[inline]
pub fn im_draw_list_add_circle_filled(self &ImDrawList, center ImVec2_c, radius f32, col ImU32, num_segments i32) {
	C.ImDrawList_AddCircleFilled(self, center, radius, col, num_segments)
}

@[keep_args_alive]
fn C.ImDrawList_AddNgon(self &ImDrawList, center ImVec2_c, radius f32, col ImU32, num_segments i32, thickness f32)

@[inline]
pub fn im_draw_list_add_ngon(self &ImDrawList, center ImVec2_c, radius f32, col ImU32, num_segments i32, thickness f32) {
	C.ImDrawList_AddNgon(self, center, radius, col, num_segments, thickness)
}

@[keep_args_alive]
fn C.ImDrawList_AddNgonFilled(self &ImDrawList, center ImVec2_c, radius f32, col ImU32, num_segments i32)

@[inline]
pub fn im_draw_list_add_ngon_filled(self &ImDrawList, center ImVec2_c, radius f32, col ImU32, num_segments i32) {
	C.ImDrawList_AddNgonFilled(self, center, radius, col, num_segments)
}

@[keep_args_alive]
fn C.ImDrawList_AddEllipse(self &ImDrawList, center ImVec2_c, radius ImVec2_c, col ImU32, rot f32, num_segments i32, thickness f32)

@[inline]
pub fn im_draw_list_add_ellipse(self &ImDrawList, center ImVec2_c, radius ImVec2_c, col ImU32, rot f32, num_segments i32, thickness f32) {
	C.ImDrawList_AddEllipse(self, center, radius, col, rot, num_segments, thickness)
}

@[keep_args_alive]
fn C.ImDrawList_AddEllipseFilled(self &ImDrawList, center ImVec2_c, radius ImVec2_c, col ImU32, rot f32, num_segments i32)

@[inline]
pub fn im_draw_list_add_ellipse_filled(self &ImDrawList, center ImVec2_c, radius ImVec2_c, col ImU32, rot f32, num_segments i32) {
	C.ImDrawList_AddEllipseFilled(self, center, radius, col, rot, num_segments)
}

@[keep_args_alive]
fn C.ImDrawList_AddText_Vec2(self &ImDrawList, pos ImVec2_c, col ImU32, text_begin &char, const_text_end &char)

@[inline]
pub fn im_draw_list_add_text_vec2(self &ImDrawList, pos ImVec2_c, col ImU32, text_begin &char, const_text_end &char) {
	C.ImDrawList_AddText_Vec2(self, pos, col, text_begin, const_text_end)
}

@[keep_args_alive]
fn C.ImDrawList_AddText_FontPtr(self &ImDrawList, font &ImFont, font_size f32, pos ImVec2_c, col ImU32, text_begin &char, const_text_end &char, wrap_width f32, cpu_fine_clip_rect &ImVec4)

@[inline]
pub fn im_draw_list_add_text_font_ptr(self &ImDrawList, font &ImFont, font_size f32, pos ImVec2_c, col ImU32, text_begin &char, const_text_end &char, wrap_width f32, cpu_fine_clip_rect &ImVec4) {
	C.ImDrawList_AddText_FontPtr(self, font, font_size, pos, col, text_begin, const_text_end,
		wrap_width, cpu_fine_clip_rect)
}

@[keep_args_alive]
fn C.ImDrawList_AddBezierCubic(self &ImDrawList, p1 ImVec2_c, p2 ImVec2_c, p3 ImVec2_c, p4 ImVec2_c, col ImU32, thickness f32, num_segments i32)

@[inline]
pub fn im_draw_list_add_bezier_cubic(self &ImDrawList, p1 ImVec2_c, p2 ImVec2_c, p3 ImVec2_c, p4 ImVec2_c, col ImU32, thickness f32, num_segments i32) {
	C.ImDrawList_AddBezierCubic(self, p1, p2, p3, p4, col, thickness, num_segments)
}

@[keep_args_alive]
fn C.ImDrawList_AddBezierQuadratic(self &ImDrawList, p1 ImVec2_c, p2 ImVec2_c, p3 ImVec2_c, col ImU32, thickness f32, num_segments i32)

@[inline]
pub fn im_draw_list_add_bezier_quadratic(self &ImDrawList, p1 ImVec2_c, p2 ImVec2_c, p3 ImVec2_c, col ImU32, thickness f32, num_segments i32) {
	C.ImDrawList_AddBezierQuadratic(self, p1, p2, p3, col, thickness, num_segments)
}

@[keep_args_alive]
fn C.ImDrawList_AddPolyline(self &ImDrawList, points &ImVec2_c, num_points i32, col ImU32, flags ImDrawFlags, thickness f32)

@[inline]
pub fn im_draw_list_add_polyline(self &ImDrawList, points &ImVec2_c, num_points i32, col ImU32, flags ImDrawFlags, thickness f32) {
	C.ImDrawList_AddPolyline(self, points, num_points, col, flags, thickness)
}

@[keep_args_alive]
fn C.ImDrawList_AddConvexPolyFilled(self &ImDrawList, points &ImVec2_c, num_points i32, col ImU32)

@[inline]
pub fn im_draw_list_add_convex_poly_filled(self &ImDrawList, points &ImVec2_c, num_points i32, col ImU32) {
	C.ImDrawList_AddConvexPolyFilled(self, points, num_points, col)
}

@[keep_args_alive]
fn C.ImDrawList_AddConcavePolyFilled(self &ImDrawList, points &ImVec2_c, num_points i32, col ImU32)

@[inline]
pub fn im_draw_list_add_concave_poly_filled(self &ImDrawList, points &ImVec2_c, num_points i32, col ImU32) {
	C.ImDrawList_AddConcavePolyFilled(self, points, num_points, col)
}

@[keep_args_alive]
fn C.ImDrawList_AddImage(self &ImDrawList, tex_ref ImTextureRef_c, p_min ImVec2_c, p_max ImVec2_c, uv_min ImVec2_c, uv_max ImVec2_c, col ImU32)

@[inline]
pub fn im_draw_list_add_image(self &ImDrawList, tex_ref ImTextureRef_c, p_min ImVec2_c, p_max ImVec2_c, uv_min ImVec2_c, uv_max ImVec2_c, col ImU32) {
	C.ImDrawList_AddImage(self, tex_ref, p_min, p_max, uv_min, uv_max, col)
}

@[keep_args_alive]
fn C.ImDrawList_AddImageQuad(self &ImDrawList, tex_ref ImTextureRef_c, p1 ImVec2_c, p2 ImVec2_c, p3 ImVec2_c, p4 ImVec2_c, uv1 ImVec2_c, uv2 ImVec2_c, uv3 ImVec2_c, uv4 ImVec2_c, col ImU32)

@[inline]
pub fn im_draw_list_add_image_quad(self &ImDrawList, tex_ref ImTextureRef_c, p1 ImVec2_c, p2 ImVec2_c, p3 ImVec2_c, p4 ImVec2_c, uv1 ImVec2_c, uv2 ImVec2_c, uv3 ImVec2_c, uv4 ImVec2_c, col ImU32) {
	C.ImDrawList_AddImageQuad(self, tex_ref, p1, p2, p3, p4, uv1, uv2, uv3, uv4, col)
}

@[keep_args_alive]
fn C.ImDrawList_AddImageRounded(self &ImDrawList, tex_ref ImTextureRef_c, p_min ImVec2_c, p_max ImVec2_c, uv_min ImVec2_c, uv_max ImVec2_c, col ImU32, rounding f32, flags ImDrawFlags)

@[inline]
pub fn im_draw_list_add_image_rounded(self &ImDrawList, tex_ref ImTextureRef_c, p_min ImVec2_c, p_max ImVec2_c, uv_min ImVec2_c, uv_max ImVec2_c, col ImU32, rounding f32, flags ImDrawFlags) {
	C.ImDrawList_AddImageRounded(self, tex_ref, p_min, p_max, uv_min, uv_max, col, rounding, flags)
}

@[keep_args_alive]
fn C.ImDrawList_PathClear(self &ImDrawList)

@[inline]
pub fn im_draw_list_path_clear(self &ImDrawList) {
	C.ImDrawList_PathClear(self)
}

@[keep_args_alive]
fn C.ImDrawList_PathLineTo(self &ImDrawList, pos ImVec2_c)

@[inline]
pub fn im_draw_list_path_line_to(self &ImDrawList, pos ImVec2_c) {
	C.ImDrawList_PathLineTo(self, pos)
}

@[keep_args_alive]
fn C.ImDrawList_PathLineToMergeDuplicate(self &ImDrawList, pos ImVec2_c)

@[inline]
pub fn im_draw_list_path_line_to_merge_duplicate(self &ImDrawList, pos ImVec2_c) {
	C.ImDrawList_PathLineToMergeDuplicate(self, pos)
}

@[keep_args_alive]
fn C.ImDrawList_PathFillConvex(self &ImDrawList, col ImU32)

@[inline]
pub fn im_draw_list_path_fill_convex(self &ImDrawList, col ImU32) {
	C.ImDrawList_PathFillConvex(self, col)
}

@[keep_args_alive]
fn C.ImDrawList_PathFillConcave(self &ImDrawList, col ImU32)

@[inline]
pub fn im_draw_list_path_fill_concave(self &ImDrawList, col ImU32) {
	C.ImDrawList_PathFillConcave(self, col)
}

@[keep_args_alive]
fn C.ImDrawList_PathStroke(self &ImDrawList, col ImU32, flags ImDrawFlags, thickness f32)

@[inline]
pub fn im_draw_list_path_stroke(self &ImDrawList, col ImU32, flags ImDrawFlags, thickness f32) {
	C.ImDrawList_PathStroke(self, col, flags, thickness)
}

@[keep_args_alive]
fn C.ImDrawList_PathArcTo(self &ImDrawList, center ImVec2_c, radius f32, a_min f32, a_max f32, num_segments i32)

@[inline]
pub fn im_draw_list_path_arc_to(self &ImDrawList, center ImVec2_c, radius f32, a_min f32, a_max f32, num_segments i32) {
	C.ImDrawList_PathArcTo(self, center, radius, a_min, a_max, num_segments)
}

@[keep_args_alive]
fn C.ImDrawList_PathArcToFast(self &ImDrawList, center ImVec2_c, radius f32, a_min_of_12 i32, a_max_of_12 i32)

@[inline]
pub fn im_draw_list_path_arc_to_fast(self &ImDrawList, center ImVec2_c, radius f32, a_min_of_12 i32, a_max_of_12 i32) {
	C.ImDrawList_PathArcToFast(self, center, radius, a_min_of_12, a_max_of_12)
}

@[keep_args_alive]
fn C.ImDrawList_PathEllipticalArcTo(self &ImDrawList, center ImVec2_c, radius ImVec2_c, rot f32, a_min f32, a_max f32, num_segments i32)

@[inline]
pub fn im_draw_list_path_elliptical_arc_to(self &ImDrawList, center ImVec2_c, radius ImVec2_c, rot f32, a_min f32, a_max f32, num_segments i32) {
	C.ImDrawList_PathEllipticalArcTo(self, center, radius, rot, a_min, a_max, num_segments)
}

@[keep_args_alive]
fn C.ImDrawList_PathBezierCubicCurveTo(self &ImDrawList, p2 ImVec2_c, p3 ImVec2_c, p4 ImVec2_c, num_segments i32)

@[inline]
pub fn im_draw_list_path_bezier_cubic_curve_to(self &ImDrawList, p2 ImVec2_c, p3 ImVec2_c, p4 ImVec2_c, num_segments i32) {
	C.ImDrawList_PathBezierCubicCurveTo(self, p2, p3, p4, num_segments)
}

@[keep_args_alive]
fn C.ImDrawList_PathBezierQuadraticCurveTo(self &ImDrawList, p2 ImVec2_c, p3 ImVec2_c, num_segments i32)

@[inline]
pub fn im_draw_list_path_bezier_quadratic_curve_to(self &ImDrawList, p2 ImVec2_c, p3 ImVec2_c, num_segments i32) {
	C.ImDrawList_PathBezierQuadraticCurveTo(self, p2, p3, num_segments)
}

@[keep_args_alive]
fn C.ImDrawList_PathRect(self &ImDrawList, rect_min ImVec2_c, rect_max ImVec2_c, rounding f32, flags ImDrawFlags)

@[inline]
pub fn im_draw_list_path_rect(self &ImDrawList, rect_min ImVec2_c, rect_max ImVec2_c, rounding f32, flags ImDrawFlags) {
	C.ImDrawList_PathRect(self, rect_min, rect_max, rounding, flags)
}

@[keep_args_alive]
fn C.ImDrawList_AddCallback(self &ImDrawList, callback ImDrawCallback, userdata voidptr, userdata_size usize)

@[inline]
pub fn im_draw_list_add_callback(self &ImDrawList, callback ImDrawCallback, userdata voidptr, userdata_size usize) {
	C.ImDrawList_AddCallback(self, callback, userdata, userdata_size)
}

@[keep_args_alive]
fn C.ImDrawList_AddDrawCmd(self &ImDrawList)

@[inline]
pub fn im_draw_list_add_draw_cmd(self &ImDrawList) {
	C.ImDrawList_AddDrawCmd(self)
}

@[keep_args_alive]
fn C.ImDrawList_CloneOutput(self &ImDrawList) &ImDrawList

@[inline]
pub fn im_draw_list_clone_output(self &ImDrawList) &ImDrawList {
	return C.ImDrawList_CloneOutput(self)
}

@[keep_args_alive]
fn C.ImDrawList_ChannelsSplit(self &ImDrawList, count i32)

@[inline]
pub fn im_draw_list_channels_split(self &ImDrawList, count i32) {
	C.ImDrawList_ChannelsSplit(self, count)
}

@[keep_args_alive]
fn C.ImDrawList_ChannelsMerge(self &ImDrawList)

@[inline]
pub fn im_draw_list_channels_merge(self &ImDrawList) {
	C.ImDrawList_ChannelsMerge(self)
}

@[keep_args_alive]
fn C.ImDrawList_ChannelsSetCurrent(self &ImDrawList, n i32)

@[inline]
pub fn im_draw_list_channels_set_current(self &ImDrawList, n i32) {
	C.ImDrawList_ChannelsSetCurrent(self, n)
}

@[keep_args_alive]
fn C.ImDrawList_PrimReserve(self &ImDrawList, idx_count i32, vtx_count i32)

@[inline]
pub fn im_draw_list_prim_reserve(self &ImDrawList, idx_count i32, vtx_count i32) {
	C.ImDrawList_PrimReserve(self, idx_count, vtx_count)
}

@[keep_args_alive]
fn C.ImDrawList_PrimUnreserve(self &ImDrawList, idx_count i32, vtx_count i32)

@[inline]
pub fn im_draw_list_prim_unreserve(self &ImDrawList, idx_count i32, vtx_count i32) {
	C.ImDrawList_PrimUnreserve(self, idx_count, vtx_count)
}

@[keep_args_alive]
fn C.ImDrawList_PrimRect(self &ImDrawList, a ImVec2_c, b ImVec2_c, col ImU32)

@[inline]
pub fn im_draw_list_prim_rect(self &ImDrawList, a ImVec2_c, b ImVec2_c, col ImU32) {
	C.ImDrawList_PrimRect(self, a, b, col)
}

@[keep_args_alive]
fn C.ImDrawList_PrimRectUV(self &ImDrawList, a ImVec2_c, b ImVec2_c, uv_a ImVec2_c, uv_b ImVec2_c, col ImU32)

@[inline]
pub fn im_draw_list_prim_rect_uv(self &ImDrawList, a ImVec2_c, b ImVec2_c, uv_a ImVec2_c, uv_b ImVec2_c, col ImU32) {
	C.ImDrawList_PrimRectUV(self, a, b, uv_a, uv_b, col)
}

@[keep_args_alive]
fn C.ImDrawList_PrimQuadUV(self &ImDrawList, a ImVec2_c, b ImVec2_c, c ImVec2_c, d ImVec2_c, uv_a ImVec2_c, uv_b ImVec2_c, uv_c ImVec2_c, uv_d ImVec2_c, col ImU32)

@[inline]
pub fn im_draw_list_prim_quad_uv(self &ImDrawList, a ImVec2_c, b ImVec2_c, c ImVec2_c, d ImVec2_c, uv_a ImVec2_c, uv_b ImVec2_c, uv_c ImVec2_c, uv_d ImVec2_c, col ImU32) {
	C.ImDrawList_PrimQuadUV(self, a, b, c, d, uv_a, uv_b, uv_c, uv_d, col)
}

@[keep_args_alive]
fn C.ImDrawList_PrimWriteVtx(self &ImDrawList, pos ImVec2_c, uv ImVec2_c, col ImU32)

@[inline]
pub fn im_draw_list_prim_write_vtx(self &ImDrawList, pos ImVec2_c, uv ImVec2_c, col ImU32) {
	C.ImDrawList_PrimWriteVtx(self, pos, uv, col)
}

@[keep_args_alive]
fn C.ImDrawList_PrimWriteIdx(self &ImDrawList, idx ImDrawIdx)

@[inline]
pub fn im_draw_list_prim_write_idx(self &ImDrawList, idx ImDrawIdx) {
	C.ImDrawList_PrimWriteIdx(self, idx)
}

@[keep_args_alive]
fn C.ImDrawList_PrimVtx(self &ImDrawList, pos ImVec2_c, uv ImVec2_c, col ImU32)

@[inline]
pub fn im_draw_list_prim_vtx(self &ImDrawList, pos ImVec2_c, uv ImVec2_c, col ImU32) {
	C.ImDrawList_PrimVtx(self, pos, uv, col)
}

@[keep_args_alive]
fn C.ImDrawList__SetDrawListSharedData(self &ImDrawList, data &ImDrawListSharedData)

@[inline]
pub fn im_draw_list__set_draw_list_shared_data(self &ImDrawList, data &ImDrawListSharedData) {
	C.ImDrawList__SetDrawListSharedData(self, data)
}

@[keep_args_alive]
fn C.ImDrawList__ResetForNewFrame(self &ImDrawList)

@[inline]
pub fn im_draw_list__reset_for_new_frame(self &ImDrawList) {
	C.ImDrawList__ResetForNewFrame(self)
}

@[keep_args_alive]
fn C.ImDrawList__ClearFreeMemory(self &ImDrawList)

@[inline]
pub fn im_draw_list__clear_free_memory(self &ImDrawList) {
	C.ImDrawList__ClearFreeMemory(self)
}

@[keep_args_alive]
fn C.ImDrawList__PopUnusedDrawCmd(self &ImDrawList)

@[inline]
pub fn im_draw_list__pop_unused_draw_cmd(self &ImDrawList) {
	C.ImDrawList__PopUnusedDrawCmd(self)
}

@[keep_args_alive]
fn C.ImDrawList__TryMergeDrawCmds(self &ImDrawList)

@[inline]
pub fn im_draw_list__try_merge_draw_cmds(self &ImDrawList) {
	C.ImDrawList__TryMergeDrawCmds(self)
}

@[keep_args_alive]
fn C.ImDrawList__OnChangedClipRect(self &ImDrawList)

@[inline]
pub fn im_draw_list__on_changed_clip_rect(self &ImDrawList) {
	C.ImDrawList__OnChangedClipRect(self)
}

@[keep_args_alive]
fn C.ImDrawList__OnChangedTexture(self &ImDrawList)

@[inline]
pub fn im_draw_list__on_changed_texture(self &ImDrawList) {
	C.ImDrawList__OnChangedTexture(self)
}

@[keep_args_alive]
fn C.ImDrawList__OnChangedVtxOffset(self &ImDrawList)

@[inline]
pub fn im_draw_list__on_changed_vtx_offset(self &ImDrawList) {
	C.ImDrawList__OnChangedVtxOffset(self)
}

@[keep_args_alive]
fn C.ImDrawList__SetTexture(self &ImDrawList, tex_ref ImTextureRef_c)

@[inline]
pub fn im_draw_list__set_texture(self &ImDrawList, tex_ref ImTextureRef_c) {
	C.ImDrawList__SetTexture(self, tex_ref)
}

@[keep_args_alive]
fn C.ImDrawList__CalcCircleAutoSegmentCount(self &ImDrawList, radius f32) i32

@[inline]
pub fn im_draw_list__calc_circle_auto_segment_count(self &ImDrawList, radius f32) i32 {
	return C.ImDrawList__CalcCircleAutoSegmentCount(self, radius)
}

@[keep_args_alive]
fn C.ImDrawList__PathArcToFastEx(self &ImDrawList, center ImVec2_c, radius f32, a_min_sample i32, a_max_sample i32, a_step i32)

@[inline]
pub fn im_draw_list__path_arc_to_fast_ex(self &ImDrawList, center ImVec2_c, radius f32, a_min_sample i32, a_max_sample i32, a_step i32) {
	C.ImDrawList__PathArcToFastEx(self, center, radius, a_min_sample, a_max_sample, a_step)
}

@[keep_args_alive]
fn C.ImDrawList__PathArcToN(self &ImDrawList, center ImVec2_c, radius f32, a_min f32, a_max f32, num_segments i32)

@[inline]
pub fn im_draw_list__path_arc_to_n(self &ImDrawList, center ImVec2_c, radius f32, a_min f32, a_max f32, num_segments i32) {
	C.ImDrawList__PathArcToN(self, center, radius, a_min, a_max, num_segments)
}

@[keep_args_alive]
fn C.ImDrawData_ImDrawData() &ImDrawData

@[inline]
pub fn im_draw_data_im_draw_data() &ImDrawData {
	return C.ImDrawData_ImDrawData()
}

@[keep_args_alive]
fn C.ImDrawData_destroy(self &ImDrawData)

@[inline]
pub fn im_draw_data_destroy(self &ImDrawData) {
	C.ImDrawData_destroy(self)
}

@[keep_args_alive]
fn C.ImDrawData_Clear(self &ImDrawData)

@[inline]
pub fn im_draw_data_clear(self &ImDrawData) {
	C.ImDrawData_Clear(self)
}

@[keep_args_alive]
fn C.ImDrawData_AddDrawList(self &ImDrawData, draw_list &ImDrawList)

@[inline]
pub fn im_draw_data_add_draw_list(self &ImDrawData, draw_list &ImDrawList) {
	C.ImDrawData_AddDrawList(self, draw_list)
}

@[keep_args_alive]
fn C.ImDrawData_DeIndexAllBuffers(self &ImDrawData)

@[inline]
pub fn im_draw_data_de_index_all_buffers(self &ImDrawData) {
	C.ImDrawData_DeIndexAllBuffers(self)
}

@[keep_args_alive]
fn C.ImDrawData_ScaleClipRects(self &ImDrawData, fb_scale ImVec2_c)

@[inline]
pub fn im_draw_data_scale_clip_rects(self &ImDrawData, fb_scale ImVec2_c) {
	C.ImDrawData_ScaleClipRects(self, fb_scale)
}

@[keep_args_alive]
fn C.ImTextureData_ImTextureData() &ImTextureData

@[inline]
pub fn im_texture_data_im_texture_data() &ImTextureData {
	return C.ImTextureData_ImTextureData()
}

@[keep_args_alive]
fn C.ImTextureData_destroy(self &ImTextureData)

@[inline]
pub fn im_texture_data_destroy(self &ImTextureData) {
	C.ImTextureData_destroy(self)
}

@[keep_args_alive]
fn C.ImTextureData_Create(self &ImTextureData, format ImTextureFormat, w i32, h i32)

@[inline]
pub fn im_texture_data_create(self &ImTextureData, format ImTextureFormat, w i32, h i32) {
	C.ImTextureData_Create(self, format, w, h)
}

@[keep_args_alive]
fn C.ImTextureData_DestroyPixels(self &ImTextureData)

@[inline]
pub fn im_texture_data_destroy_pixels(self &ImTextureData) {
	C.ImTextureData_DestroyPixels(self)
}

@[keep_args_alive]
fn C.ImTextureData_GetPixels(self &ImTextureData) voidptr

@[inline]
pub fn im_texture_data_get_pixels(self &ImTextureData) voidptr {
	return C.ImTextureData_GetPixels(self)
}

@[keep_args_alive]
fn C.ImTextureData_GetPixelsAt(self &ImTextureData, x i32, y i32) voidptr

@[inline]
pub fn im_texture_data_get_pixels_at(self &ImTextureData, x i32, y i32) voidptr {
	return C.ImTextureData_GetPixelsAt(self, x, y)
}

@[keep_args_alive]
fn C.ImTextureData_GetSizeInBytes(self &ImTextureData) i32

@[inline]
pub fn im_texture_data_get_size_in_bytes(self &ImTextureData) i32 {
	return C.ImTextureData_GetSizeInBytes(self)
}

@[keep_args_alive]
fn C.ImTextureData_GetPitch(self &ImTextureData) i32

@[inline]
pub fn im_texture_data_get_pitch(self &ImTextureData) i32 {
	return C.ImTextureData_GetPitch(self)
}

@[keep_args_alive]
fn C.ImTextureData_GetTexRef(self &ImTextureData) ImTextureRef_c

@[inline]
pub fn im_texture_data_get_tex_ref(self &ImTextureData) ImTextureRef_c {
	return C.ImTextureData_GetTexRef(self)
}

@[keep_args_alive]
fn C.ImTextureData_GetTexID(self &ImTextureData) ImTextureID

@[inline]
pub fn im_texture_data_get_tex_id(self &ImTextureData) ImTextureID {
	return C.ImTextureData_GetTexID(self)
}

@[keep_args_alive]
fn C.ImTextureData_SetTexID(self &ImTextureData, tex_id ImTextureID)

@[inline]
pub fn im_texture_data_set_tex_id(self &ImTextureData, tex_id ImTextureID) {
	C.ImTextureData_SetTexID(self, tex_id)
}

@[keep_args_alive]
fn C.ImTextureData_SetStatus(self &ImTextureData, status ImTextureStatus)

@[inline]
pub fn im_texture_data_set_status(self &ImTextureData, status ImTextureStatus) {
	C.ImTextureData_SetStatus(self, status)
}

@[keep_args_alive]
fn C.ImFontConfig_ImFontConfig() &ImFontConfig

@[inline]
pub fn im_font_config_im_font_config() &ImFontConfig {
	return C.ImFontConfig_ImFontConfig()
}

@[keep_args_alive]
fn C.ImFontConfig_destroy(self &ImFontConfig)

@[inline]
pub fn im_font_config_destroy(self &ImFontConfig) {
	C.ImFontConfig_destroy(self)
}

@[keep_args_alive]
fn C.ImFontGlyph_ImFontGlyph() &ImFontGlyph

@[inline]
pub fn im_font_glyph_im_font_glyph() &ImFontGlyph {
	return C.ImFontGlyph_ImFontGlyph()
}

@[keep_args_alive]
fn C.ImFontGlyph_destroy(self &ImFontGlyph)

@[inline]
pub fn im_font_glyph_destroy(self &ImFontGlyph) {
	C.ImFontGlyph_destroy(self)
}

@[keep_args_alive]
fn C.ImFontGlyphRangesBuilder_ImFontGlyphRangesBuilder() &ImFontGlyphRangesBuilder

@[inline]
pub fn im_font_glyph_ranges_builder_im_font_glyph_ranges_builder() &ImFontGlyphRangesBuilder {
	return C.ImFontGlyphRangesBuilder_ImFontGlyphRangesBuilder()
}

@[keep_args_alive]
fn C.ImFontGlyphRangesBuilder_destroy(self &ImFontGlyphRangesBuilder)

@[inline]
pub fn im_font_glyph_ranges_builder_destroy(self &ImFontGlyphRangesBuilder) {
	C.ImFontGlyphRangesBuilder_destroy(self)
}

@[keep_args_alive]
fn C.ImFontGlyphRangesBuilder_Clear(self &ImFontGlyphRangesBuilder)

@[inline]
pub fn im_font_glyph_ranges_builder_clear(self &ImFontGlyphRangesBuilder) {
	C.ImFontGlyphRangesBuilder_Clear(self)
}

@[keep_args_alive]
fn C.ImFontGlyphRangesBuilder_GetBit(self &ImFontGlyphRangesBuilder, n usize) bool

@[inline]
pub fn im_font_glyph_ranges_builder_get_bit(self &ImFontGlyphRangesBuilder, n usize) bool {
	return C.ImFontGlyphRangesBuilder_GetBit(self, n)
}

@[keep_args_alive]
fn C.ImFontGlyphRangesBuilder_SetBit(self &ImFontGlyphRangesBuilder, n usize)

@[inline]
pub fn im_font_glyph_ranges_builder_set_bit(self &ImFontGlyphRangesBuilder, n usize) {
	C.ImFontGlyphRangesBuilder_SetBit(self, n)
}

@[keep_args_alive]
fn C.ImFontGlyphRangesBuilder_AddChar(self &ImFontGlyphRangesBuilder, c ImWchar)

@[inline]
pub fn im_font_glyph_ranges_builder_add_char(self &ImFontGlyphRangesBuilder, c ImWchar) {
	C.ImFontGlyphRangesBuilder_AddChar(self, c)
}

@[keep_args_alive]
fn C.ImFontGlyphRangesBuilder_AddText(self &ImFontGlyphRangesBuilder, const_text &char, const_text_end &char)

@[inline]
pub fn im_font_glyph_ranges_builder_add_text(self &ImFontGlyphRangesBuilder, const_text &char, const_text_end &char) {
	C.ImFontGlyphRangesBuilder_AddText(self, const_text, const_text_end)
}

@[keep_args_alive]
fn C.ImFontGlyphRangesBuilder_AddRanges(self &ImFontGlyphRangesBuilder, ranges &ImWchar)

@[inline]
pub fn im_font_glyph_ranges_builder_add_ranges(self &ImFontGlyphRangesBuilder, ranges &ImWchar) {
	C.ImFontGlyphRangesBuilder_AddRanges(self, ranges)
}

@[keep_args_alive]
fn C.ImFontGlyphRangesBuilder_BuildRanges(self &ImFontGlyphRangesBuilder, out_ranges &ImVector_ImWchar)

@[inline]
pub fn im_font_glyph_ranges_builder_build_ranges(self &ImFontGlyphRangesBuilder, out_ranges &ImVector_ImWchar) {
	C.ImFontGlyphRangesBuilder_BuildRanges(self, out_ranges)
}

@[keep_args_alive]
fn C.ImFontAtlasRect_ImFontAtlasRect() &ImFontAtlasRect

@[inline]
pub fn im_font_atlas_rect_im_font_atlas_rect() &ImFontAtlasRect {
	return C.ImFontAtlasRect_ImFontAtlasRect()
}

@[keep_args_alive]
fn C.ImFontAtlasRect_destroy(self &ImFontAtlasRect)

@[inline]
pub fn im_font_atlas_rect_destroy(self &ImFontAtlasRect) {
	C.ImFontAtlasRect_destroy(self)
}

@[keep_args_alive]
fn C.ImFontAtlas_ImFontAtlas() &ImFontAtlas

@[inline]
pub fn im_font_atlas_im_font_atlas() &ImFontAtlas {
	return C.ImFontAtlas_ImFontAtlas()
}

@[keep_args_alive]
fn C.ImFontAtlas_destroy(self &ImFontAtlas)

@[inline]
pub fn im_font_atlas_destroy(self &ImFontAtlas) {
	C.ImFontAtlas_destroy(self)
}

@[keep_args_alive]
fn C.ImFontAtlas_AddFont(self &ImFontAtlas, font_cfg &ImFontConfig) &ImFont

@[inline]
pub fn im_font_atlas_add_font(self &ImFontAtlas, font_cfg &ImFontConfig) &ImFont {
	return C.ImFontAtlas_AddFont(self, font_cfg)
}

@[keep_args_alive]
fn C.ImFontAtlas_AddFontDefault(self &ImFontAtlas, font_cfg &ImFontConfig) &ImFont

@[inline]
pub fn im_font_atlas_add_font_default(self &ImFontAtlas, font_cfg &ImFontConfig) &ImFont {
	return C.ImFontAtlas_AddFontDefault(self, font_cfg)
}

@[keep_args_alive]
fn C.ImFontAtlas_AddFontDefaultVector(self &ImFontAtlas, font_cfg &ImFontConfig) &ImFont

@[inline]
pub fn im_font_atlas_add_font_default_vector(self &ImFontAtlas, font_cfg &ImFontConfig) &ImFont {
	return C.ImFontAtlas_AddFontDefaultVector(self, font_cfg)
}

@[keep_args_alive]
fn C.ImFontAtlas_AddFontDefaultBitmap(self &ImFontAtlas, font_cfg &ImFontConfig) &ImFont

@[inline]
pub fn im_font_atlas_add_font_default_bitmap(self &ImFontAtlas, font_cfg &ImFontConfig) &ImFont {
	return C.ImFontAtlas_AddFontDefaultBitmap(self, font_cfg)
}

@[keep_args_alive]
fn C.ImFontAtlas_AddFontFromFileTTF(self &ImFontAtlas, filename &char, size_pixels f32, font_cfg &ImFontConfig, glyph_ranges &ImWchar) &ImFont

@[inline]
pub fn im_font_atlas_add_font_from_file_ttf(self &ImFontAtlas, filename &char, size_pixels f32, font_cfg &ImFontConfig, glyph_ranges &ImWchar) &ImFont {
	return C.ImFontAtlas_AddFontFromFileTTF(self, filename, size_pixels, font_cfg, glyph_ranges)
}

@[keep_args_alive]
fn C.ImFontAtlas_AddFontFromMemoryTTF(self &ImFontAtlas, font_data voidptr, font_data_size i32, size_pixels f32, font_cfg &ImFontConfig, glyph_ranges &ImWchar) &ImFont

@[inline]
pub fn im_font_atlas_add_font_from_memory_ttf(self &ImFontAtlas, font_data voidptr, font_data_size i32, size_pixels f32, font_cfg &ImFontConfig, glyph_ranges &ImWchar) &ImFont {
	return C.ImFontAtlas_AddFontFromMemoryTTF(self, font_data, font_data_size, size_pixels,
		font_cfg, glyph_ranges)
}

@[keep_args_alive]
fn C.ImFontAtlas_AddFontFromMemoryCompressedTTF(self &ImFontAtlas, compressed_font_data voidptr, compressed_font_data_size i32, size_pixels f32, font_cfg &ImFontConfig, glyph_ranges &ImWchar) &ImFont

@[inline]
pub fn im_font_atlas_add_font_from_memory_compressed_ttf(self &ImFontAtlas, compressed_font_data voidptr, compressed_font_data_size i32, size_pixels f32, font_cfg &ImFontConfig, glyph_ranges &ImWchar) &ImFont {
	return C.ImFontAtlas_AddFontFromMemoryCompressedTTF(self, compressed_font_data,
		compressed_font_data_size, size_pixels, font_cfg, glyph_ranges)
}

@[keep_args_alive]
fn C.ImFontAtlas_AddFontFromMemoryCompressedBase85TTF(self &ImFontAtlas, compressed_font_data_base85 &char, size_pixels f32, font_cfg &ImFontConfig, glyph_ranges &ImWchar) &ImFont

@[inline]
pub fn im_font_atlas_add_font_from_memory_compressed_base85_ttf(self &ImFontAtlas, compressed_font_data_base85 &char, size_pixels f32, font_cfg &ImFontConfig, glyph_ranges &ImWchar) &ImFont {
	return C.ImFontAtlas_AddFontFromMemoryCompressedBase85TTF(self, compressed_font_data_base85,
		size_pixels, font_cfg, glyph_ranges)
}

@[keep_args_alive]
fn C.ImFontAtlas_RemoveFont(self &ImFontAtlas, font &ImFont)

@[inline]
pub fn im_font_atlas_remove_font(self &ImFontAtlas, font &ImFont) {
	C.ImFontAtlas_RemoveFont(self, font)
}

@[keep_args_alive]
fn C.ImFontAtlas_Clear(self &ImFontAtlas)

@[inline]
pub fn im_font_atlas_clear(self &ImFontAtlas) {
	C.ImFontAtlas_Clear(self)
}

@[keep_args_alive]
fn C.ImFontAtlas_CompactCache(self &ImFontAtlas)

@[inline]
pub fn im_font_atlas_compact_cache(self &ImFontAtlas) {
	C.ImFontAtlas_CompactCache(self)
}

@[keep_args_alive]
fn C.ImFontAtlas_SetFontLoader(self &ImFontAtlas, font_loader &ImFontLoader)

@[inline]
pub fn im_font_atlas_set_font_loader(self &ImFontAtlas, font_loader &ImFontLoader) {
	C.ImFontAtlas_SetFontLoader(self, font_loader)
}

@[keep_args_alive]
fn C.ImFontAtlas_ClearInputData(self &ImFontAtlas)

@[inline]
pub fn im_font_atlas_clear_input_data(self &ImFontAtlas) {
	C.ImFontAtlas_ClearInputData(self)
}

@[keep_args_alive]
fn C.ImFontAtlas_ClearFonts(self &ImFontAtlas)

@[inline]
pub fn im_font_atlas_clear_fonts(self &ImFontAtlas) {
	C.ImFontAtlas_ClearFonts(self)
}

@[keep_args_alive]
fn C.ImFontAtlas_ClearTexData(self &ImFontAtlas)

@[inline]
pub fn im_font_atlas_clear_tex_data(self &ImFontAtlas) {
	C.ImFontAtlas_ClearTexData(self)
}

@[keep_args_alive]
fn C.ImFontAtlas_GetGlyphRangesDefault(self &ImFontAtlas) &ImWchar

@[inline]
pub fn im_font_atlas_get_glyph_ranges_default(self &ImFontAtlas) &ImWchar {
	return C.ImFontAtlas_GetGlyphRangesDefault(self)
}

@[keep_args_alive]
fn C.ImFontAtlas_AddCustomRect(self &ImFontAtlas, width i32, height i32, out_r &ImFontAtlasRect) ImFontAtlasRectId

@[inline]
pub fn im_font_atlas_add_custom_rect(self &ImFontAtlas, width i32, height i32, out_r &ImFontAtlasRect) ImFontAtlasRectId {
	return C.ImFontAtlas_AddCustomRect(self, width, height, out_r)
}

@[keep_args_alive]
fn C.ImFontAtlas_RemoveCustomRect(self &ImFontAtlas, id ImFontAtlasRectId)

@[inline]
pub fn im_font_atlas_remove_custom_rect(self &ImFontAtlas, id ImFontAtlasRectId) {
	C.ImFontAtlas_RemoveCustomRect(self, id)
}

@[keep_args_alive]
fn C.ImFontAtlas_GetCustomRect(self &ImFontAtlas, id ImFontAtlasRectId, out_r &ImFontAtlasRect) bool

@[inline]
pub fn im_font_atlas_get_custom_rect(self &ImFontAtlas, id ImFontAtlasRectId, out_r &ImFontAtlasRect) bool {
	return C.ImFontAtlas_GetCustomRect(self, id, out_r)
}

@[keep_args_alive]
fn C.ImFontBaked_ImFontBaked() &ImFontBaked

@[inline]
pub fn im_font_baked_im_font_baked() &ImFontBaked {
	return C.ImFontBaked_ImFontBaked()
}

@[keep_args_alive]
fn C.ImFontBaked_destroy(self &ImFontBaked)

@[inline]
pub fn im_font_baked_destroy(self &ImFontBaked) {
	C.ImFontBaked_destroy(self)
}

@[keep_args_alive]
fn C.ImFontBaked_ClearOutputData(self &ImFontBaked)

@[inline]
pub fn im_font_baked_clear_output_data(self &ImFontBaked) {
	C.ImFontBaked_ClearOutputData(self)
}

@[keep_args_alive]
fn C.ImFontBaked_FindGlyph(self &ImFontBaked, c ImWchar) &ImFontGlyph

@[inline]
pub fn im_font_baked_find_glyph(self &ImFontBaked, c ImWchar) &ImFontGlyph {
	return C.ImFontBaked_FindGlyph(self, c)
}

@[keep_args_alive]
fn C.ImFontBaked_FindGlyphNoFallback(self &ImFontBaked, c ImWchar) &ImFontGlyph

@[inline]
pub fn im_font_baked_find_glyph_no_fallback(self &ImFontBaked, c ImWchar) &ImFontGlyph {
	return C.ImFontBaked_FindGlyphNoFallback(self, c)
}

@[keep_args_alive]
fn C.ImFontBaked_GetCharAdvance(self &ImFontBaked, c ImWchar) f32

@[inline]
pub fn im_font_baked_get_char_advance(self &ImFontBaked, c ImWchar) f32 {
	return C.ImFontBaked_GetCharAdvance(self, c)
}

@[keep_args_alive]
fn C.ImFontBaked_IsGlyphLoaded(self &ImFontBaked, c ImWchar) bool

@[inline]
pub fn im_font_baked_is_glyph_loaded(self &ImFontBaked, c ImWchar) bool {
	return C.ImFontBaked_IsGlyphLoaded(self, c)
}

@[keep_args_alive]
fn C.ImFont_ImFont() &ImFont

@[inline]
pub fn im_font_im_font() &ImFont {
	return C.ImFont_ImFont()
}

@[keep_args_alive]
fn C.ImFont_destroy(self &ImFont)

@[inline]
pub fn im_font_destroy(self &ImFont) {
	C.ImFont_destroy(self)
}

@[keep_args_alive]
fn C.ImFont_IsGlyphInFont(self &ImFont, c ImWchar) bool

@[inline]
pub fn im_font_is_glyph_in_font(self &ImFont, c ImWchar) bool {
	return C.ImFont_IsGlyphInFont(self, c)
}

@[keep_args_alive]
fn C.ImFont_IsLoaded(self &ImFont) bool

@[inline]
pub fn im_font_is_loaded(self &ImFont) bool {
	return C.ImFont_IsLoaded(self)
}

@[keep_args_alive]
fn C.ImFont_GetDebugName(self &ImFont) &char

@[inline]
pub fn im_font_get_debug_name(self &ImFont) &char {
	return C.ImFont_GetDebugName(self)
}

@[keep_args_alive]
fn C.ImFont_GetFontBaked(self &ImFont, font_size f32, density f32) &ImFontBaked

@[inline]
pub fn im_font_get_font_baked(self &ImFont, font_size f32, density f32) &ImFontBaked {
	return C.ImFont_GetFontBaked(self, font_size, density)
}

@[keep_args_alive]
fn C.ImFont_CalcTextSizeA(self &ImFont, size f32, max_width f32, wrap_width f32, text_begin &char, const_text_end &char, out_remaining &&u8) ImVec2_c

@[inline]
pub fn im_font_calc_text_size_a(self &ImFont, size f32, max_width f32, wrap_width f32, text_begin &char, const_text_end &char, out_remaining &&u8) ImVec2_c {
	return C.ImFont_CalcTextSizeA(self, size, max_width, wrap_width, text_begin, const_text_end,
		out_remaining)
}

@[keep_args_alive]
fn C.ImFont_CalcWordWrapPosition(self &ImFont, size f32, const_text &char, const_text_end &char, wrap_width f32) &char

@[inline]
pub fn im_font_calc_word_wrap_position(self &ImFont, size f32, const_text &char, const_text_end &char, wrap_width f32) &char {
	return C.ImFont_CalcWordWrapPosition(self, size, const_text, const_text_end, wrap_width)
}

@[keep_args_alive]
fn C.ImFont_RenderChar(self &ImFont, draw_list &ImDrawList, size f32, pos ImVec2_c, col ImU32, c ImWchar, cpu_fine_clip &ImVec4)

@[inline]
pub fn im_font_render_char(self &ImFont, draw_list &ImDrawList, size f32, pos ImVec2_c, col ImU32, c ImWchar, cpu_fine_clip &ImVec4) {
	C.ImFont_RenderChar(self, draw_list, size, pos, col, c, cpu_fine_clip)
}

@[keep_args_alive]
fn C.ImFont_RenderText(self &ImFont, draw_list &ImDrawList, size f32, pos ImVec2_c, col ImU32, clip_rect ImVec4_c, text_begin &char, const_text_end &char, wrap_width f32, flags ImDrawTextFlags)

@[inline]
pub fn im_font_render_text(self &ImFont, draw_list &ImDrawList, size f32, pos ImVec2_c, col ImU32, clip_rect ImVec4_c, text_begin &char, const_text_end &char, wrap_width f32, flags ImDrawTextFlags) {
	C.ImFont_RenderText(self, draw_list, size, pos, col, clip_rect, text_begin, const_text_end,
		wrap_width, flags)
}

@[keep_args_alive]
fn C.ImFont_ClearOutputData(self &ImFont)

@[inline]
pub fn im_font_clear_output_data(self &ImFont) {
	C.ImFont_ClearOutputData(self)
}

@[keep_args_alive]
fn C.ImFont_AddRemapChar(self &ImFont, from_codepoint ImWchar, to_codepoint ImWchar)

@[inline]
pub fn im_font_add_remap_char(self &ImFont, from_codepoint ImWchar, to_codepoint ImWchar) {
	C.ImFont_AddRemapChar(self, from_codepoint, to_codepoint)
}

@[keep_args_alive]
fn C.ImFont_IsGlyphRangeUnused(self &ImFont, c_begin u32, c_last u32) bool

@[inline]
pub fn im_font_is_glyph_range_unused(self &ImFont, c_begin u32, c_last u32) bool {
	return C.ImFont_IsGlyphRangeUnused(self, c_begin, c_last)
}

@[keep_args_alive]
fn C.ImGuiViewport_ImGuiViewport() &Viewport

@[inline]
pub fn viewport_viewport() &Viewport {
	return C.ImGuiViewport_ImGuiViewport()
}

@[keep_args_alive]
fn C.ImGuiViewport_destroy(self &Viewport)

@[inline]
pub fn viewport_destroy(self &Viewport) {
	C.ImGuiViewport_destroy(self)
}

@[keep_args_alive]
fn C.ImGuiViewport_GetCenter(self &Viewport) ImVec2_c

@[inline]
pub fn viewport_get_center(self &Viewport) ImVec2_c {
	return C.ImGuiViewport_GetCenter(self)
}

@[keep_args_alive]
fn C.ImGuiViewport_GetWorkCenter(self &Viewport) ImVec2_c

@[inline]
pub fn viewport_get_work_center(self &Viewport) ImVec2_c {
	return C.ImGuiViewport_GetWorkCenter(self)
}

@[keep_args_alive]
fn C.ImGuiViewport_GetDebugName(self &Viewport) &char

@[inline]
pub fn viewport_get_debug_name(self &Viewport) &char {
	return C.ImGuiViewport_GetDebugName(self)
}

@[keep_args_alive]
fn C.ImGuiPlatformIO_ImGuiPlatformIO() &PlatformIO

@[inline]
pub fn platform_io_platform_io() &PlatformIO {
	return C.ImGuiPlatformIO_ImGuiPlatformIO()
}

@[keep_args_alive]
fn C.ImGuiPlatformIO_destroy(self &PlatformIO)

@[inline]
pub fn platform_io_destroy(self &PlatformIO) {
	C.ImGuiPlatformIO_destroy(self)
}

@[keep_args_alive]
fn C.ImGuiPlatformIO_ClearPlatformHandlers(self &PlatformIO)

@[inline]
pub fn platform_io_clear_platform_handlers(self &PlatformIO) {
	C.ImGuiPlatformIO_ClearPlatformHandlers(self)
}

@[keep_args_alive]
fn C.ImGuiPlatformIO_ClearRendererHandlers(self &PlatformIO)

@[inline]
pub fn platform_io_clear_renderer_handlers(self &PlatformIO) {
	C.ImGuiPlatformIO_ClearRendererHandlers(self)
}

@[keep_args_alive]
fn C.ImGuiPlatformMonitor_ImGuiPlatformMonitor() &PlatformMonitor

@[inline]
pub fn platform_monitor_platform_monitor() &PlatformMonitor {
	return C.ImGuiPlatformMonitor_ImGuiPlatformMonitor()
}

@[keep_args_alive]
fn C.ImGuiPlatformMonitor_destroy(self &PlatformMonitor)

@[inline]
pub fn platform_monitor_destroy(self &PlatformMonitor) {
	C.ImGuiPlatformMonitor_destroy(self)
}

@[keep_args_alive]
fn C.ImGuiPlatformImeData_ImGuiPlatformImeData() &PlatformImeData

@[inline]
pub fn platform_ime_data_platform_ime_data() &PlatformImeData {
	return C.ImGuiPlatformImeData_ImGuiPlatformImeData()
}

@[keep_args_alive]
fn C.ImGuiPlatformImeData_destroy(self &PlatformImeData)

@[inline]
pub fn platform_ime_data_destroy(self &PlatformImeData) {
	C.ImGuiPlatformImeData_destroy(self)
}

@[keep_args_alive]
fn C.igImHashData(data voidptr, data_size usize, seed ID) ID

@[inline]
pub fn im_hash_data(data voidptr, data_size usize, seed ID) ID {
	return C.igImHashData(data, data_size, seed)
}

@[keep_args_alive]
fn C.igImHashStr(data &char, data_size usize, seed ID) ID

@[inline]
pub fn im_hash_str(data &char, data_size usize, seed ID) ID {
	return C.igImHashStr(data, data_size, seed)
}

@[keep_args_alive]
fn C.igImHashSkipUncontributingPrefix(const_label &char) &char

@[inline]
pub fn im_hash_skip_uncontributing_prefix(const_label &char) &char {
	return C.igImHashSkipUncontributingPrefix(const_label)
}

@[keep_args_alive]
fn C.igImQsort(base voidptr, count usize, size_of_element usize, compare_func fn (voidptr, voidptr) i32)

@[inline]
pub fn im_qsort(base voidptr, count usize, size_of_element usize, compare_func fn (voidptr, voidptr) i32) {
	C.igImQsort(base, count, size_of_element, compare_func)
}

@[keep_args_alive]
fn C.igImAlphaBlendColors(col_a ImU32, col_b ImU32) ImU32

@[inline]
pub fn im_alpha_blend_colors(col_a ImU32, col_b ImU32) ImU32 {
	return C.igImAlphaBlendColors(col_a, col_b)
}

@[keep_args_alive]
fn C.igImIsPowerOfTwo_Int(v i32) bool

@[inline]
pub fn im_is_power_of_two_int(v i32) bool {
	return C.igImIsPowerOfTwo_Int(v)
}

@[keep_args_alive]
fn C.igImIsPowerOfTwo_U64(v ImU64) bool

@[inline]
pub fn im_is_power_of_two_u64(v ImU64) bool {
	return C.igImIsPowerOfTwo_U64(v)
}

@[keep_args_alive]
fn C.igImUpperPowerOfTwo(v i32) i32

@[inline]
pub fn im_upper_power_of_two(v i32) i32 {
	return C.igImUpperPowerOfTwo(v)
}

@[keep_args_alive]
fn C.igImCountSetBits(v u32) u32

@[inline]
pub fn im_count_set_bits(v u32) u32 {
	return C.igImCountSetBits(v)
}

@[keep_args_alive]
fn C.igImStricmp(str1 &char, str2 &char) i32

@[inline]
pub fn im_stricmp(str1 &char, str2 &char) i32 {
	return C.igImStricmp(str1, str2)
}

@[keep_args_alive]
fn C.igImStrnicmp(str1 &char, str2 &char, count usize) i32

@[inline]
pub fn im_strnicmp(str1 &char, str2 &char, count usize) i32 {
	return C.igImStrnicmp(str1, str2, count)
}

@[keep_args_alive]
fn C.igImStrncpy(dst &char, src &char, count usize)

@[inline]
pub fn im_strncpy(dst &char, src &char, count usize) {
	C.igImStrncpy(dst, src, count)
}

@[keep_args_alive]
fn C.igImStrdup(const_str &char) &char

@[inline]
pub fn im_strdup(const_str &char) &char {
	return C.igImStrdup(const_str)
}

@[keep_args_alive]
fn C.igImMemdup(src voidptr, size usize) voidptr

@[inline]
pub fn im_memdup(src voidptr, size usize) voidptr {
	return C.igImMemdup(src, size)
}

@[keep_args_alive]
fn C.igImStrdupcpy(dst &char, p_dst_size &usize, const_str &char) &char

@[inline]
pub fn im_strdupcpy(dst &char, p_dst_size &usize, const_str &char) &char {
	return C.igImStrdupcpy(dst, p_dst_size, const_str)
}

@[keep_args_alive]
fn C.igImStrchrRange(str_begin &char, str_end &char, c i8) &char

@[inline]
pub fn im_strchr_range(str_begin &char, str_end &char, c i8) &char {
	return C.igImStrchrRange(str_begin, str_end, c)
}

@[keep_args_alive]
fn C.igImStreolRange(const_str &char, str_end &char) &char

@[inline]
pub fn im_streol_range(const_str &char, str_end &char) &char {
	return C.igImStreolRange(const_str, str_end)
}

@[keep_args_alive]
fn C.igImStristr(haystack &char, haystack_end &char, needle &char, needle_end &char) &char

@[inline]
pub fn im_stristr(haystack &char, haystack_end &char, needle &char, needle_end &char) &char {
	return C.igImStristr(haystack, haystack_end, needle, needle_end)
}

@[keep_args_alive]
fn C.igImStrTrimBlanks(const_str &char)

@[inline]
pub fn im_str_trim_blanks(const_str &char) {
	C.igImStrTrimBlanks(const_str)
}

@[keep_args_alive]
fn C.igImStrSkipBlank(const_str &char) &char

@[inline]
pub fn im_str_skip_blank(const_str &char) &char {
	return C.igImStrSkipBlank(const_str)
}

@[keep_args_alive]
fn C.igImStrlenW(str &ImWchar) i32

@[inline]
pub fn im_strlen_w(str &ImWchar) i32 {
	return C.igImStrlenW(str)
}

@[keep_args_alive]
fn C.igImStrbol(buf_mid_line &char, buf_begin &char) &char

@[inline]
pub fn im_strbol(buf_mid_line &char, buf_begin &char) &char {
	return C.igImStrbol(buf_mid_line, buf_begin)
}

@[keep_args_alive]
fn C.igImToUpper(c i8) i8

@[inline]
pub fn im_to_upper(c i8) i8 {
	return C.igImToUpper(c)
}

@[keep_args_alive]
fn C.igImCharIsBlankA(c i8) bool

@[inline]
pub fn im_char_is_blank_a(c i8) bool {
	return C.igImCharIsBlankA(c)
}

@[keep_args_alive]
fn C.igImCharIsBlankW(c u32) bool

@[inline]
pub fn im_char_is_blank_w(c u32) bool {
	return C.igImCharIsBlankW(c)
}

@[keep_args_alive]
fn C.igImCharIsXdigitA(c i8) bool

@[inline]
pub fn im_char_is_xdigit_a(c i8) bool {
	return C.igImCharIsXdigitA(c)
}

@[keep_args_alive]
fn C.igImFormatString(buf &char, buf_size usize, const_fmt &char) i32

@[inline]
pub fn im_format_string(buf &char, buf_size usize, const_fmt &char) i32 {
	return C.igImFormatString(buf, buf_size, const_fmt)
}

@[keep_args_alive]
fn C.igImFormatStringV(buf &char, buf_size usize, const_fmt &char, args Va_list) i32

@[inline]
pub fn im_format_string_v(buf &char, buf_size usize, const_fmt &char, args Va_list) i32 {
	return C.igImFormatStringV(buf, buf_size, const_fmt, args)
}

@[keep_args_alive]
fn C.igImFormatStringToTempBuffer(out_buf &&u8, out_buf_end &&u8, const_fmt &char)

@[inline]
pub fn im_format_string_to_temp_buffer(out_buf &&u8, out_buf_end &&u8, const_fmt &char) {
	C.igImFormatStringToTempBuffer(out_buf, out_buf_end, const_fmt)
}

@[keep_args_alive]
fn C.igImFormatStringToTempBufferV(out_buf &&u8, out_buf_end &&u8, const_fmt &char, args Va_list)

@[inline]
pub fn im_format_string_to_temp_buffer_v(out_buf &&u8, out_buf_end &&u8, const_fmt &char, args Va_list) {
	C.igImFormatStringToTempBufferV(out_buf, out_buf_end, const_fmt, args)
}

@[keep_args_alive]
fn C.igImParseFormatFindStart(format &char) &char

@[inline]
pub fn im_parse_format_find_start(format &char) &char {
	return C.igImParseFormatFindStart(format)
}

@[keep_args_alive]
fn C.igImParseFormatFindEnd(format &char) &char

@[inline]
pub fn im_parse_format_find_end(format &char) &char {
	return C.igImParseFormatFindEnd(format)
}

@[keep_args_alive]
fn C.igImParseFormatTrimDecorations(format &char, buf &char, buf_size usize) &char

@[inline]
pub fn im_parse_format_trim_decorations(format &char, buf &char, buf_size usize) &char {
	return C.igImParseFormatTrimDecorations(format, buf, buf_size)
}

@[keep_args_alive]
fn C.igImParseFormatSanitizeForPrinting(fmt_in &char, fmt_out &char, fmt_out_size usize)

@[inline]
pub fn im_parse_format_sanitize_for_printing(fmt_in &char, fmt_out &char, fmt_out_size usize) {
	C.igImParseFormatSanitizeForPrinting(fmt_in, fmt_out, fmt_out_size)
}

@[keep_args_alive]
fn C.igImParseFormatSanitizeForScanning(fmt_in &char, fmt_out &char, fmt_out_size usize) &char

@[inline]
pub fn im_parse_format_sanitize_for_scanning(fmt_in &char, fmt_out &char, fmt_out_size usize) &char {
	return C.igImParseFormatSanitizeForScanning(fmt_in, fmt_out, fmt_out_size)
}

@[keep_args_alive]
fn C.igImParseFormatPrecision(format &char, default_value i32) i32

@[inline]
pub fn im_parse_format_precision(format &char, default_value i32) i32 {
	return C.igImParseFormatPrecision(format, default_value)
}

@[keep_args_alive]
fn C.igImTextCharToUtf8(out_buf &char, c u32) i32

@[inline]
pub fn im_text_char_to_utf8(out_buf &char, c u32) i32 {
	return C.igImTextCharToUtf8(out_buf, c)
}

@[keep_args_alive]
fn C.igImTextStrToUtf8(out_buf &char, out_buf_size i32, in_text &ImWchar, in_text_end &ImWchar) i32

@[inline]
pub fn im_text_str_to_utf8(out_buf &char, out_buf_size i32, in_text &ImWchar, in_text_end &ImWchar) i32 {
	return C.igImTextStrToUtf8(out_buf, out_buf_size, in_text, in_text_end)
}

@[keep_args_alive]
fn C.igImTextCharFromUtf8(out_char &u32, in_text &char, in_text_end &char) i32

@[inline]
pub fn im_text_char_from_utf8(out_char &u32, in_text &char, in_text_end &char) i32 {
	return C.igImTextCharFromUtf8(out_char, in_text, in_text_end)
}

@[keep_args_alive]
fn C.igImTextStrFromUtf8(out_buf &ImWchar, out_buf_size i32, in_text &char, in_text_end &char, in_remaining &&u8) i32

@[inline]
pub fn im_text_str_from_utf8(out_buf &ImWchar, out_buf_size i32, in_text &char, in_text_end &char, in_remaining &&u8) i32 {
	return C.igImTextStrFromUtf8(out_buf, out_buf_size, in_text, in_text_end, in_remaining)
}

@[keep_args_alive]
fn C.igImTextCountCharsFromUtf8(in_text &char, in_text_end &char) i32

@[inline]
pub fn im_text_count_chars_from_utf8(in_text &char, in_text_end &char) i32 {
	return C.igImTextCountCharsFromUtf8(in_text, in_text_end)
}

@[keep_args_alive]
fn C.igImTextCountUtf8BytesFromChar(in_text &char, in_text_end &char) i32

@[inline]
pub fn im_text_count_utf8_bytes_from_char(in_text &char, in_text_end &char) i32 {
	return C.igImTextCountUtf8BytesFromChar(in_text, in_text_end)
}

@[keep_args_alive]
fn C.igImTextCountUtf8BytesFromStr(in_text &ImWchar, in_text_end &ImWchar) i32

@[inline]
pub fn im_text_count_utf8_bytes_from_str(in_text &ImWchar, in_text_end &ImWchar) i32 {
	return C.igImTextCountUtf8BytesFromStr(in_text, in_text_end)
}

@[keep_args_alive]
fn C.igImTextFindPreviousUtf8Codepoint(in_text_start &char, in_p &char) &char

@[inline]
pub fn im_text_find_previous_utf8_codepoint(in_text_start &char, in_p &char) &char {
	return C.igImTextFindPreviousUtf8Codepoint(in_text_start, in_p)
}

@[keep_args_alive]
fn C.igImTextFindValidUtf8CodepointEnd(in_text_start &char, in_text_end &char, in_p &char) &char

@[inline]
pub fn im_text_find_valid_utf8_codepoint_end(in_text_start &char, in_text_end &char, in_p &char) &char {
	return C.igImTextFindValidUtf8CodepointEnd(in_text_start, in_text_end, in_p)
}

@[keep_args_alive]
fn C.igImTextCountLines(in_text &char, in_text_end &char) i32

@[inline]
pub fn im_text_count_lines(in_text &char, in_text_end &char) i32 {
	return C.igImTextCountLines(in_text, in_text_end)
}

@[keep_args_alive]
fn C.igImFontCalcTextSizeEx(font &ImFont, size f32, max_width f32, wrap_width f32, text_begin &char, text_end_display &char, const_text_end &char, out_remaining &&u8, out_offset &ImVec2_c, flags ImDrawTextFlags) ImVec2_c

@[inline]
pub fn im_font_calc_text_size_ex(font &ImFont, size f32, max_width f32, wrap_width f32, text_begin &char, text_end_display &char, const_text_end &char, out_remaining &&u8, out_offset &ImVec2_c, flags ImDrawTextFlags) ImVec2_c {
	return C.igImFontCalcTextSizeEx(font, size, max_width, wrap_width, text_begin,
		text_end_display, const_text_end, out_remaining, out_offset, flags)
}

@[keep_args_alive]
fn C.igImFontCalcWordWrapPositionEx(font &ImFont, size f32, const_text &char, const_text_end &char, wrap_width f32, flags ImDrawTextFlags) &char

@[inline]
pub fn im_font_calc_word_wrap_position_ex(font &ImFont, size f32, const_text &char, const_text_end &char, wrap_width f32, flags ImDrawTextFlags) &char {
	return C.igImFontCalcWordWrapPositionEx(font, size, const_text, const_text_end, wrap_width,
		flags)
}

@[keep_args_alive]
fn C.igImTextCalcWordWrapNextLineStart(const_text &char, const_text_end &char, flags ImDrawTextFlags) &char

@[inline]
pub fn im_text_calc_word_wrap_next_line_start(const_text &char, const_text_end &char, flags ImDrawTextFlags) &char {
	return C.igImTextCalcWordWrapNextLineStart(const_text, const_text_end, flags)
}

@[keep_args_alive]
fn C.igImTextInitClassifiers()

@[inline]
pub fn im_text_init_classifiers() {
	C.igImTextInitClassifiers()
}

@[keep_args_alive]
fn C.igImTextClassifierClear(bits &ImU32, codepoint_min u32, codepoint_end u32, char_class ImWcharClass)

@[inline]
pub fn im_text_classifier_clear(bits &ImU32, codepoint_min u32, codepoint_end u32, char_class ImWcharClass) {
	C.igImTextClassifierClear(bits, codepoint_min, codepoint_end, char_class)
}

@[keep_args_alive]
fn C.igImTextClassifierSetCharClass(bits &ImU32, codepoint_min u32, codepoint_end u32, char_class ImWcharClass, c u32)

@[inline]
pub fn im_text_classifier_set_char_class(bits &ImU32, codepoint_min u32, codepoint_end u32, char_class ImWcharClass, c u32) {
	C.igImTextClassifierSetCharClass(bits, codepoint_min, codepoint_end, char_class, c)
}

@[keep_args_alive]
fn C.igImTextClassifierSetCharClassFromStr(bits &ImU32, codepoint_min u32, codepoint_end u32, char_class ImWcharClass, s &char)

@[inline]
pub fn im_text_classifier_set_char_class_from_str(bits &ImU32, codepoint_min u32, codepoint_end u32, char_class ImWcharClass, s &char) {
	C.igImTextClassifierSetCharClassFromStr(bits, codepoint_min, codepoint_end, char_class, s)
}

@[keep_args_alive]
fn C.igImFileOpen(filename &char, mode &char) ImFileHandle

@[inline]
pub fn im_file_open(filename &char, mode &char) ImFileHandle {
	return C.igImFileOpen(filename, mode)
}

@[keep_args_alive]
fn C.igImFileClose(file ImFileHandle) bool

@[inline]
pub fn im_file_close(file ImFileHandle) bool {
	return C.igImFileClose(file)
}

@[keep_args_alive]
fn C.igImFileGetSize(file ImFileHandle) ImU64

@[inline]
pub fn im_file_get_size(file ImFileHandle) ImU64 {
	return C.igImFileGetSize(file)
}

@[keep_args_alive]
fn C.igImFileRead(data voidptr, size ImU64, count ImU64, file ImFileHandle) ImU64

@[inline]
pub fn im_file_read(data voidptr, size ImU64, count ImU64, file ImFileHandle) ImU64 {
	return C.igImFileRead(data, size, count, file)
}

@[keep_args_alive]
fn C.igImFileWrite(data voidptr, size ImU64, count ImU64, file ImFileHandle) ImU64

@[inline]
pub fn im_file_write(data voidptr, size ImU64, count ImU64, file ImFileHandle) ImU64 {
	return C.igImFileWrite(data, size, count, file)
}

@[keep_args_alive]
fn C.igImFileLoadToMemory(filename &char, mode &char, out_file_size &usize, padding_bytes i32) voidptr

@[inline]
pub fn im_file_load_to_memory(filename &char, mode &char, out_file_size &usize, padding_bytes i32) voidptr {
	return C.igImFileLoadToMemory(filename, mode, out_file_size, padding_bytes)
}

@[keep_args_alive]
fn C.igImPow_Float(x f32, y f32) f32

@[inline]
pub fn im_pow_float(x f32, y f32) f32 {
	return C.igImPow_Float(x, y)
}

@[keep_args_alive]
fn C.igImPow_double(x f64, y f64) f64

@[inline]
pub fn im_pow_double(x f64, y f64) f64 {
	return C.igImPow_double(x, y)
}

@[keep_args_alive]
fn C.igImLog_Float(x f32) f32

@[inline]
pub fn im_log_float(x f32) f32 {
	return C.igImLog_Float(x)
}

@[keep_args_alive]
fn C.igImLog_double(x f64) f64

@[inline]
pub fn im_log_double(x f64) f64 {
	return C.igImLog_double(x)
}

@[keep_args_alive]
fn C.igImAbs_Int(x i32) i32

@[inline]
pub fn im_abs_int(x i32) i32 {
	return C.igImAbs_Int(x)
}

@[keep_args_alive]
fn C.igImAbs_Float(x f32) f32

@[inline]
pub fn im_abs_float(x f32) f32 {
	return C.igImAbs_Float(x)
}

@[keep_args_alive]
fn C.igImAbs_double(x f64) f64

@[inline]
pub fn im_abs_double(x f64) f64 {
	return C.igImAbs_double(x)
}

@[keep_args_alive]
fn C.igImSign_Float(x f32) f32

@[inline]
pub fn im_sign_float(x f32) f32 {
	return C.igImSign_Float(x)
}

@[keep_args_alive]
fn C.igImSign_double(x f64) f64

@[inline]
pub fn im_sign_double(x f64) f64 {
	return C.igImSign_double(x)
}

@[keep_args_alive]
fn C.igImRsqrt_Float(x f32) f32

@[inline]
pub fn im_rsqrt_float(x f32) f32 {
	return C.igImRsqrt_Float(x)
}

@[keep_args_alive]
fn C.igImRsqrt_double(x f64) f64

@[inline]
pub fn im_rsqrt_double(x f64) f64 {
	return C.igImRsqrt_double(x)
}

@[keep_args_alive]
fn C.igImMin(lhs ImVec2_c, rhs ImVec2_c) ImVec2_c

@[inline]
pub fn im_min(lhs ImVec2_c, rhs ImVec2_c) ImVec2_c {
	return C.igImMin(lhs, rhs)
}

@[keep_args_alive]
fn C.igImMax(lhs ImVec2_c, rhs ImVec2_c) ImVec2_c

@[inline]
pub fn im_max(lhs ImVec2_c, rhs ImVec2_c) ImVec2_c {
	return C.igImMax(lhs, rhs)
}

@[keep_args_alive]
fn C.igImClamp(v ImVec2_c, mn ImVec2_c, mx ImVec2_c) ImVec2_c

@[inline]
pub fn im_clamp(v ImVec2_c, mn ImVec2_c, mx ImVec2_c) ImVec2_c {
	return C.igImClamp(v, mn, mx)
}

@[keep_args_alive]
fn C.igImLerp_Vec2Float(a ImVec2_c, b ImVec2_c, t f32) ImVec2_c

@[inline]
pub fn im_lerp_vec2_float(a ImVec2_c, b ImVec2_c, t f32) ImVec2_c {
	return C.igImLerp_Vec2Float(a, b, t)
}

@[keep_args_alive]
fn C.igImLerp_Vec2Vec2(a ImVec2_c, b ImVec2_c, t ImVec2_c) ImVec2_c

@[inline]
pub fn im_lerp_vec2_vec2(a ImVec2_c, b ImVec2_c, t ImVec2_c) ImVec2_c {
	return C.igImLerp_Vec2Vec2(a, b, t)
}

@[keep_args_alive]
fn C.igImLerp_Vec4(a ImVec4_c, b ImVec4_c, t f32) ImVec4_c

@[inline]
pub fn im_lerp_vec4(a ImVec4_c, b ImVec4_c, t f32) ImVec4_c {
	return C.igImLerp_Vec4(a, b, t)
}

@[keep_args_alive]
fn C.igImSaturate(f f32) f32

@[inline]
pub fn im_saturate(f f32) f32 {
	return C.igImSaturate(f)
}

@[keep_args_alive]
fn C.igImLengthSqr_Vec2(lhs ImVec2_c) f32

@[inline]
pub fn im_length_sqr_vec2(lhs ImVec2_c) f32 {
	return C.igImLengthSqr_Vec2(lhs)
}

@[keep_args_alive]
fn C.igImLengthSqr_Vec4(lhs ImVec4_c) f32

@[inline]
pub fn im_length_sqr_vec4(lhs ImVec4_c) f32 {
	return C.igImLengthSqr_Vec4(lhs)
}

@[keep_args_alive]
fn C.igImInvLength(lhs ImVec2_c, fail_value f32) f32

@[inline]
pub fn im_inv_length(lhs ImVec2_c, fail_value f32) f32 {
	return C.igImInvLength(lhs, fail_value)
}

@[keep_args_alive]
fn C.igImTrunc_Float(f f32) f32

@[inline]
pub fn im_trunc_float(f f32) f32 {
	return C.igImTrunc_Float(f)
}

@[keep_args_alive]
fn C.igImTrunc_Vec2(v ImVec2_c) ImVec2_c

@[inline]
pub fn im_trunc_vec2(v ImVec2_c) ImVec2_c {
	return C.igImTrunc_Vec2(v)
}

@[keep_args_alive]
fn C.igImFloor_Float(f f32) f32

@[inline]
pub fn im_floor_float(f f32) f32 {
	return C.igImFloor_Float(f)
}

@[keep_args_alive]
fn C.igImFloor_Vec2(v ImVec2_c) ImVec2_c

@[inline]
pub fn im_floor_vec2(v ImVec2_c) ImVec2_c {
	return C.igImFloor_Vec2(v)
}

@[keep_args_alive]
fn C.igImTrunc64(f f32) f32

@[inline]
pub fn im_trunc64(f f32) f32 {
	return C.igImTrunc64(f)
}

@[keep_args_alive]
fn C.igImRound64(f f32) f32

@[inline]
pub fn im_round64(f f32) f32 {
	return C.igImRound64(f)
}

@[keep_args_alive]
fn C.igImModPositive(a i32, b i32) i32

@[inline]
pub fn im_mod_positive(a i32, b i32) i32 {
	return C.igImModPositive(a, b)
}

@[keep_args_alive]
fn C.igImDot(a ImVec2_c, b ImVec2_c) f32

@[inline]
pub fn im_dot(a ImVec2_c, b ImVec2_c) f32 {
	return C.igImDot(a, b)
}

@[keep_args_alive]
fn C.igImRotate(v ImVec2_c, cos_a f32, sin_a f32) ImVec2_c

@[inline]
pub fn im_rotate(v ImVec2_c, cos_a f32, sin_a f32) ImVec2_c {
	return C.igImRotate(v, cos_a, sin_a)
}

@[keep_args_alive]
fn C.igImLinearSweep(current f32, target f32, speed f32) f32

@[inline]
pub fn im_linear_sweep(current f32, target f32, speed f32) f32 {
	return C.igImLinearSweep(current, target, speed)
}

@[keep_args_alive]
fn C.igImLinearRemapClamp(s0 f32, s1 f32, d0 f32, d1 f32, x f32) f32

@[inline]
pub fn im_linear_remap_clamp(s0 f32, s1 f32, d0 f32, d1 f32, x f32) f32 {
	return C.igImLinearRemapClamp(s0, s1, d0, d1, x)
}

@[keep_args_alive]
fn C.igImMul(lhs ImVec2_c, rhs ImVec2_c) ImVec2_c

@[inline]
pub fn im_mul(lhs ImVec2_c, rhs ImVec2_c) ImVec2_c {
	return C.igImMul(lhs, rhs)
}

@[keep_args_alive]
fn C.igImIsFloatAboveGuaranteedIntegerPrecision(f f32) bool

@[inline]
pub fn im_is_float_above_guaranteed_integer_precision(f f32) bool {
	return C.igImIsFloatAboveGuaranteedIntegerPrecision(f)
}

@[keep_args_alive]
fn C.igImExponentialMovingAverage(avg f32, sample f32, n i32) f32

@[inline]
pub fn im_exponential_moving_average(avg f32, sample f32, n i32) f32 {
	return C.igImExponentialMovingAverage(avg, sample, n)
}

@[keep_args_alive]
fn C.igImBezierCubicCalc(p1 ImVec2_c, p2 ImVec2_c, p3 ImVec2_c, p4 ImVec2_c, t f32) ImVec2_c

@[inline]
pub fn im_bezier_cubic_calc(p1 ImVec2_c, p2 ImVec2_c, p3 ImVec2_c, p4 ImVec2_c, t f32) ImVec2_c {
	return C.igImBezierCubicCalc(p1, p2, p3, p4, t)
}

@[keep_args_alive]
fn C.igImBezierCubicClosestPoint(p1 ImVec2_c, p2 ImVec2_c, p3 ImVec2_c, p4 ImVec2_c, p ImVec2_c, num_segments i32) ImVec2_c

@[inline]
pub fn im_bezier_cubic_closest_point(p1 ImVec2_c, p2 ImVec2_c, p3 ImVec2_c, p4 ImVec2_c, p ImVec2_c, num_segments i32) ImVec2_c {
	return C.igImBezierCubicClosestPoint(p1, p2, p3, p4, p, num_segments)
}

@[keep_args_alive]
fn C.igImBezierCubicClosestPointCasteljau(p1 ImVec2_c, p2 ImVec2_c, p3 ImVec2_c, p4 ImVec2_c, p ImVec2_c, tess_tol f32) ImVec2_c

@[inline]
pub fn im_bezier_cubic_closest_point_casteljau(p1 ImVec2_c, p2 ImVec2_c, p3 ImVec2_c, p4 ImVec2_c, p ImVec2_c, tess_tol f32) ImVec2_c {
	return C.igImBezierCubicClosestPointCasteljau(p1, p2, p3, p4, p, tess_tol)
}

@[keep_args_alive]
fn C.igImBezierQuadraticCalc(p1 ImVec2_c, p2 ImVec2_c, p3 ImVec2_c, t f32) ImVec2_c

@[inline]
pub fn im_bezier_quadratic_calc(p1 ImVec2_c, p2 ImVec2_c, p3 ImVec2_c, t f32) ImVec2_c {
	return C.igImBezierQuadraticCalc(p1, p2, p3, t)
}

@[keep_args_alive]
fn C.igImLineClosestPoint(a ImVec2_c, b ImVec2_c, p ImVec2_c) ImVec2_c

@[inline]
pub fn im_line_closest_point(a ImVec2_c, b ImVec2_c, p ImVec2_c) ImVec2_c {
	return C.igImLineClosestPoint(a, b, p)
}

@[keep_args_alive]
fn C.igImTriangleContainsPoint(a ImVec2_c, b ImVec2_c, c ImVec2_c, p ImVec2_c) bool

@[inline]
pub fn im_triangle_contains_point(a ImVec2_c, b ImVec2_c, c ImVec2_c, p ImVec2_c) bool {
	return C.igImTriangleContainsPoint(a, b, c, p)
}

@[keep_args_alive]
fn C.igImTriangleClosestPoint(a ImVec2_c, b ImVec2_c, c ImVec2_c, p ImVec2_c) ImVec2_c

@[inline]
pub fn im_triangle_closest_point(a ImVec2_c, b ImVec2_c, c ImVec2_c, p ImVec2_c) ImVec2_c {
	return C.igImTriangleClosestPoint(a, b, c, p)
}

@[keep_args_alive]
fn C.igImTriangleBarycentricCoords(a ImVec2_c, b ImVec2_c, c ImVec2_c, p ImVec2_c, out_u &f32, out_v &f32, out_w &f32)

@[inline]
pub fn im_triangle_barycentric_coords(a ImVec2_c, b ImVec2_c, c ImVec2_c, p ImVec2_c, out_u &f32, out_v &f32, out_w &f32) {
	C.igImTriangleBarycentricCoords(a, b, c, p, out_u, out_v, out_w)
}

@[keep_args_alive]
fn C.igImTriangleArea(a ImVec2_c, b ImVec2_c, c ImVec2_c) f32

@[inline]
pub fn im_triangle_area(a ImVec2_c, b ImVec2_c, c ImVec2_c) f32 {
	return C.igImTriangleArea(a, b, c)
}

@[keep_args_alive]
fn C.igImTriangleIsClockwise(a ImVec2_c, b ImVec2_c, c ImVec2_c) bool

@[inline]
pub fn im_triangle_is_clockwise(a ImVec2_c, b ImVec2_c, c ImVec2_c) bool {
	return C.igImTriangleIsClockwise(a, b, c)
}

@[keep_args_alive]
fn C.ImVec1_ImVec1_Nil() &ImVec1

@[inline]
pub fn im_vec1_im_vec1_nil() &ImVec1 {
	return C.ImVec1_ImVec1_Nil()
}

@[keep_args_alive]
fn C.ImVec1_destroy(self &ImVec1)

@[inline]
pub fn im_vec1_destroy(self &ImVec1) {
	C.ImVec1_destroy(self)
}

@[keep_args_alive]
fn C.ImVec1_ImVec1_Float(_x f32) &ImVec1

@[inline]
pub fn im_vec1_im_vec1_float(_x f32) &ImVec1 {
	return C.ImVec1_ImVec1_Float(_x)
}

@[keep_args_alive]
fn C.ImVec2i_ImVec2i_Nil() &ImVec2i

@[inline]
pub fn im_vec2i_im_vec2i_nil() &ImVec2i {
	return C.ImVec2i_ImVec2i_Nil()
}

@[keep_args_alive]
fn C.ImVec2i_destroy(self &ImVec2i)

@[inline]
pub fn im_vec2i_destroy(self &ImVec2i) {
	C.ImVec2i_destroy(self)
}

@[keep_args_alive]
fn C.ImVec2i_ImVec2i_Int(_x i32, _y i32) &ImVec2i

@[inline]
pub fn im_vec2i_im_vec2i_int(_x i32, _y i32) &ImVec2i {
	return C.ImVec2i_ImVec2i_Int(_x, _y)
}

@[keep_args_alive]
fn C.ImVec2ih_ImVec2ih_Nil() &ImVec2ih

@[inline]
pub fn im_vec2ih_im_vec2ih_nil() &ImVec2ih {
	return C.ImVec2ih_ImVec2ih_Nil()
}

@[keep_args_alive]
fn C.ImVec2ih_destroy(self &ImVec2ih)

@[inline]
pub fn im_vec2ih_destroy(self &ImVec2ih) {
	C.ImVec2ih_destroy(self)
}

@[keep_args_alive]
fn C.ImVec2ih_ImVec2ih_short(_x i16, _y i16) &ImVec2ih

@[inline]
pub fn im_vec2ih_im_vec2ih_short(_x i16, _y i16) &ImVec2ih {
	return C.ImVec2ih_ImVec2ih_short(_x, _y)
}

@[keep_args_alive]
fn C.ImVec2ih_ImVec2ih_Vec2(rhs ImVec2_c) &ImVec2ih

@[inline]
pub fn im_vec2ih_im_vec2ih_vec2(rhs ImVec2_c) &ImVec2ih {
	return C.ImVec2ih_ImVec2ih_Vec2(rhs)
}

@[keep_args_alive]
fn C.ImRect_ImRect_Nil() &ImRect

@[inline]
pub fn im_rect_im_rect_nil() &ImRect {
	return C.ImRect_ImRect_Nil()
}

@[keep_args_alive]
fn C.ImRect_destroy(self &ImRect)

@[inline]
pub fn im_rect_destroy(self &ImRect) {
	C.ImRect_destroy(self)
}

@[keep_args_alive]
fn C.ImRect_ImRect_Vec2(min ImVec2_c, max ImVec2_c) &ImRect

@[inline]
pub fn im_rect_im_rect_vec2(min ImVec2_c, max ImVec2_c) &ImRect {
	return C.ImRect_ImRect_Vec2(min, max)
}

@[keep_args_alive]
fn C.ImRect_ImRect_Vec4(v ImVec4_c) &ImRect

@[inline]
pub fn im_rect_im_rect_vec4(v ImVec4_c) &ImRect {
	return C.ImRect_ImRect_Vec4(v)
}

@[keep_args_alive]
fn C.ImRect_ImRect_Float(x1 f32, y1 f32, x2 f32, y2 f32) &ImRect

@[inline]
pub fn im_rect_im_rect_float(x1 f32, y1 f32, x2 f32, y2 f32) &ImRect {
	return C.ImRect_ImRect_Float(x1, y1, x2, y2)
}

@[keep_args_alive]
fn C.ImRect_GetCenter(self &ImRect) ImVec2_c

@[inline]
pub fn im_rect_get_center(self &ImRect) ImVec2_c {
	return C.ImRect_GetCenter(self)
}

@[keep_args_alive]
fn C.ImRect_GetSize(self &ImRect) ImVec2_c

@[inline]
pub fn im_rect_get_size(self &ImRect) ImVec2_c {
	return C.ImRect_GetSize(self)
}

@[keep_args_alive]
fn C.ImRect_GetWidth(self &ImRect) f32

@[inline]
pub fn im_rect_get_width(self &ImRect) f32 {
	return C.ImRect_GetWidth(self)
}

@[keep_args_alive]
fn C.ImRect_GetHeight(self &ImRect) f32

@[inline]
pub fn im_rect_get_height(self &ImRect) f32 {
	return C.ImRect_GetHeight(self)
}

@[keep_args_alive]
fn C.ImRect_GetArea(self &ImRect) f32

@[inline]
pub fn im_rect_get_area(self &ImRect) f32 {
	return C.ImRect_GetArea(self)
}

@[keep_args_alive]
fn C.ImRect_GetTL(self &ImRect) ImVec2_c

@[inline]
pub fn im_rect_get_tl(self &ImRect) ImVec2_c {
	return C.ImRect_GetTL(self)
}

@[keep_args_alive]
fn C.ImRect_GetTR(self &ImRect) ImVec2_c

@[inline]
pub fn im_rect_get_tr(self &ImRect) ImVec2_c {
	return C.ImRect_GetTR(self)
}

@[keep_args_alive]
fn C.ImRect_GetBL(self &ImRect) ImVec2_c

@[inline]
pub fn im_rect_get_bl(self &ImRect) ImVec2_c {
	return C.ImRect_GetBL(self)
}

@[keep_args_alive]
fn C.ImRect_GetBR(self &ImRect) ImVec2_c

@[inline]
pub fn im_rect_get_br(self &ImRect) ImVec2_c {
	return C.ImRect_GetBR(self)
}

@[keep_args_alive]
fn C.ImRect_Contains_Vec2(self &ImRect, p ImVec2_c) bool

@[inline]
pub fn im_rect_contains_vec2(self &ImRect, p ImVec2_c) bool {
	return C.ImRect_Contains_Vec2(self, p)
}

@[keep_args_alive]
fn C.ImRect_Contains_Rect(self &ImRect, r ImRect_c) bool

@[inline]
pub fn im_rect_contains_rect(self &ImRect, r ImRect_c) bool {
	return C.ImRect_Contains_Rect(self, r)
}

@[keep_args_alive]
fn C.ImRect_ContainsWithPad(self &ImRect, p ImVec2_c, pad ImVec2_c) bool

@[inline]
pub fn im_rect_contains_with_pad(self &ImRect, p ImVec2_c, pad ImVec2_c) bool {
	return C.ImRect_ContainsWithPad(self, p, pad)
}

@[keep_args_alive]
fn C.ImRect_Overlaps(self &ImRect, r ImRect_c) bool

@[inline]
pub fn im_rect_overlaps(self &ImRect, r ImRect_c) bool {
	return C.ImRect_Overlaps(self, r)
}

@[keep_args_alive]
fn C.ImRect_Add_Vec2(self &ImRect, p ImVec2_c)

@[inline]
pub fn im_rect_add_vec2(self &ImRect, p ImVec2_c) {
	C.ImRect_Add_Vec2(self, p)
}

@[keep_args_alive]
fn C.ImRect_Add_Rect(self &ImRect, r ImRect_c)

@[inline]
pub fn im_rect_add_rect(self &ImRect, r ImRect_c) {
	C.ImRect_Add_Rect(self, r)
}

@[keep_args_alive]
fn C.ImRect_Expand_Float(self &ImRect, amount f32)

@[inline]
pub fn im_rect_expand_float(self &ImRect, amount f32) {
	C.ImRect_Expand_Float(self, amount)
}

@[keep_args_alive]
fn C.ImRect_Expand_Vec2(self &ImRect, amount ImVec2_c)

@[inline]
pub fn im_rect_expand_vec2(self &ImRect, amount ImVec2_c) {
	C.ImRect_Expand_Vec2(self, amount)
}

@[keep_args_alive]
fn C.ImRect_Translate(self &ImRect, d ImVec2_c)

@[inline]
pub fn im_rect_translate(self &ImRect, d ImVec2_c) {
	C.ImRect_Translate(self, d)
}

@[keep_args_alive]
fn C.ImRect_TranslateX(self &ImRect, dx f32)

@[inline]
pub fn im_rect_translate_x(self &ImRect, dx f32) {
	C.ImRect_TranslateX(self, dx)
}

@[keep_args_alive]
fn C.ImRect_TranslateY(self &ImRect, dy f32)

@[inline]
pub fn im_rect_translate_y(self &ImRect, dy f32) {
	C.ImRect_TranslateY(self, dy)
}

@[keep_args_alive]
fn C.ImRect_ClipWith(self &ImRect, r ImRect_c)

@[inline]
pub fn im_rect_clip_with(self &ImRect, r ImRect_c) {
	C.ImRect_ClipWith(self, r)
}

@[keep_args_alive]
fn C.ImRect_ClipWithFull(self &ImRect, r ImRect_c)

@[inline]
pub fn im_rect_clip_with_full(self &ImRect, r ImRect_c) {
	C.ImRect_ClipWithFull(self, r)
}

@[keep_args_alive]
fn C.ImRect_IsInverted(self &ImRect) bool

@[inline]
pub fn im_rect_is_inverted(self &ImRect) bool {
	return C.ImRect_IsInverted(self)
}

@[keep_args_alive]
fn C.ImRect_ToVec4(self &ImRect) ImVec4_c

@[inline]
pub fn im_rect_to_vec4(self &ImRect) ImVec4_c {
	return C.ImRect_ToVec4(self)
}

@[keep_args_alive]
fn C.ImRect_AsVec4(self &ImRect) &ImVec4_c

@[inline]
pub fn im_rect_as_vec4(self &ImRect) &ImVec4_c {
	return C.ImRect_AsVec4(self)
}

@[keep_args_alive]
fn C.igImBitArrayGetStorageSizeInBytes(bitcount i32) usize

@[inline]
pub fn im_bit_array_get_storage_size_in_bytes(bitcount i32) usize {
	return C.igImBitArrayGetStorageSizeInBytes(bitcount)
}

@[keep_args_alive]
fn C.igImBitArrayClearAllBits(arr &ImU32, bitcount i32)

@[inline]
pub fn im_bit_array_clear_all_bits(arr &ImU32, bitcount i32) {
	C.igImBitArrayClearAllBits(arr, bitcount)
}

@[keep_args_alive]
fn C.igImBitArrayTestBit(arr &ImU32, n i32) bool

@[inline]
pub fn im_bit_array_test_bit(arr &ImU32, n i32) bool {
	return C.igImBitArrayTestBit(arr, n)
}

@[keep_args_alive]
fn C.igImBitArrayClearBit(arr &ImU32, n i32)

@[inline]
pub fn im_bit_array_clear_bit(arr &ImU32, n i32) {
	C.igImBitArrayClearBit(arr, n)
}

@[keep_args_alive]
fn C.igImBitArraySetBit(arr &ImU32, n i32)

@[inline]
pub fn im_bit_array_set_bit(arr &ImU32, n i32) {
	C.igImBitArraySetBit(arr, n)
}

@[keep_args_alive]
fn C.igImBitArraySetBitRange(arr &ImU32, n i32, n2 i32)

@[inline]
pub fn im_bit_array_set_bit_range(arr &ImU32, n i32, n2 i32) {
	C.igImBitArraySetBitRange(arr, n, n2)
}

@[keep_args_alive]
fn C.ImBitVector_Create(self &ImBitVector, sz i32)

@[inline]
pub fn im_bit_vector_create(self &ImBitVector, sz i32) {
	C.ImBitVector_Create(self, sz)
}

@[keep_args_alive]
fn C.ImBitVector_Clear(self &ImBitVector)

@[inline]
pub fn im_bit_vector_clear(self &ImBitVector) {
	C.ImBitVector_Clear(self)
}

@[keep_args_alive]
fn C.ImBitVector_TestBit(self &ImBitVector, n i32) bool

@[inline]
pub fn im_bit_vector_test_bit(self &ImBitVector, n i32) bool {
	return C.ImBitVector_TestBit(self, n)
}

@[keep_args_alive]
fn C.ImBitVector_SetBit(self &ImBitVector, n i32)

@[inline]
pub fn im_bit_vector_set_bit(self &ImBitVector, n i32) {
	C.ImBitVector_SetBit(self, n)
}

@[keep_args_alive]
fn C.ImBitVector_ClearBit(self &ImBitVector, n i32)

@[inline]
pub fn im_bit_vector_clear_bit(self &ImBitVector, n i32) {
	C.ImBitVector_ClearBit(self, n)
}

@[keep_args_alive]
fn C.ImGuiTextIndex_clear(self &TextIndex)

@[inline]
pub fn text_index_clear(self &TextIndex) {
	C.ImGuiTextIndex_clear(self)
}

@[keep_args_alive]
fn C.ImGuiTextIndex_size(self &TextIndex) i32

@[inline]
pub fn text_index_size(self &TextIndex) i32 {
	return C.ImGuiTextIndex_size(self)
}

@[keep_args_alive]
fn C.ImGuiTextIndex_get_line_begin(self &TextIndex, base &char, n i32) &char

@[inline]
pub fn text_index_get_line_begin(self &TextIndex, base &char, n i32) &char {
	return C.ImGuiTextIndex_get_line_begin(self, base, n)
}

@[keep_args_alive]
fn C.ImGuiTextIndex_get_line_end(self &TextIndex, base &char, n i32) &char

@[inline]
pub fn text_index_get_line_end(self &TextIndex, base &char, n i32) &char {
	return C.ImGuiTextIndex_get_line_end(self, base, n)
}

@[keep_args_alive]
fn C.ImGuiTextIndex_append(self &TextIndex, base &char, old_size i32, new_size i32)

@[inline]
pub fn text_index_append(self &TextIndex, base &char, old_size i32, new_size i32) {
	C.ImGuiTextIndex_append(self, base, old_size, new_size)
}

@[keep_args_alive]
fn C.igImLowerBound(in_begin &StoragePair, in_end &StoragePair, key ID) &StoragePair

@[inline]
pub fn im_lower_bound(in_begin &StoragePair, in_end &StoragePair, key ID) &StoragePair {
	return C.igImLowerBound(in_begin, in_end, key)
}

@[keep_args_alive]
fn C.ImDrawListSharedData_ImDrawListSharedData() &ImDrawListSharedData

@[inline]
pub fn im_draw_list_shared_data_im_draw_list_shared_data() &ImDrawListSharedData {
	return C.ImDrawListSharedData_ImDrawListSharedData()
}

@[keep_args_alive]
fn C.ImDrawListSharedData_destroy(self &ImDrawListSharedData)

@[inline]
pub fn im_draw_list_shared_data_destroy(self &ImDrawListSharedData) {
	C.ImDrawListSharedData_destroy(self)
}

@[keep_args_alive]
fn C.ImDrawListSharedData_SetCircleTessellationMaxError(self &ImDrawListSharedData, max_error f32)

@[inline]
pub fn im_draw_list_shared_data_set_circle_tessellation_max_error(self &ImDrawListSharedData, max_error f32) {
	C.ImDrawListSharedData_SetCircleTessellationMaxError(self, max_error)
}

@[keep_args_alive]
fn C.ImDrawDataBuilder_ImDrawDataBuilder() &ImDrawDataBuilder

@[inline]
pub fn im_draw_data_builder_im_draw_data_builder() &ImDrawDataBuilder {
	return C.ImDrawDataBuilder_ImDrawDataBuilder()
}

@[keep_args_alive]
fn C.ImDrawDataBuilder_destroy(self &ImDrawDataBuilder)

@[inline]
pub fn im_draw_data_builder_destroy(self &ImDrawDataBuilder) {
	C.ImDrawDataBuilder_destroy(self)
}

@[keep_args_alive]
fn C.ImGuiStyleVarInfo_GetVarPtr(self &StyleVarInfo, parent voidptr) voidptr

@[inline]
pub fn style_var_info_get_var_ptr(self &StyleVarInfo, parent voidptr) voidptr {
	return C.ImGuiStyleVarInfo_GetVarPtr(self, parent)
}

@[keep_args_alive]
fn C.ImGuiStyleMod_ImGuiStyleMod_Int(idx StyleVar, v i32) &StyleMod

@[inline]
pub fn style_mod_style_mod_int(idx StyleVar, v i32) &StyleMod {
	return C.ImGuiStyleMod_ImGuiStyleMod_Int(idx, v)
}

@[keep_args_alive]
fn C.ImGuiStyleMod_destroy(self &StyleMod)

@[inline]
pub fn style_mod_destroy(self &StyleMod) {
	C.ImGuiStyleMod_destroy(self)
}

@[keep_args_alive]
fn C.ImGuiStyleMod_ImGuiStyleMod_Float(idx StyleVar, v f32) &StyleMod

@[inline]
pub fn style_mod_style_mod_float(idx StyleVar, v f32) &StyleMod {
	return C.ImGuiStyleMod_ImGuiStyleMod_Float(idx, v)
}

@[keep_args_alive]
fn C.ImGuiStyleMod_ImGuiStyleMod_Vec2(idx StyleVar, v ImVec2_c) &StyleMod

@[inline]
pub fn style_mod_style_mod_vec2(idx StyleVar, v ImVec2_c) &StyleMod {
	return C.ImGuiStyleMod_ImGuiStyleMod_Vec2(idx, v)
}

@[keep_args_alive]
fn C.ImGuiComboPreviewData_ImGuiComboPreviewData() &ComboPreviewData

@[inline]
pub fn combo_preview_data_combo_preview_data() &ComboPreviewData {
	return C.ImGuiComboPreviewData_ImGuiComboPreviewData()
}

@[keep_args_alive]
fn C.ImGuiComboPreviewData_destroy(self &ComboPreviewData)

@[inline]
pub fn combo_preview_data_destroy(self &ComboPreviewData) {
	C.ImGuiComboPreviewData_destroy(self)
}

@[keep_args_alive]
fn C.ImGuiMenuColumns_ImGuiMenuColumns() &MenuColumns

@[inline]
pub fn menu_columns_menu_columns() &MenuColumns {
	return C.ImGuiMenuColumns_ImGuiMenuColumns()
}

@[keep_args_alive]
fn C.ImGuiMenuColumns_destroy(self &MenuColumns)

@[inline]
pub fn menu_columns_destroy(self &MenuColumns) {
	C.ImGuiMenuColumns_destroy(self)
}

@[keep_args_alive]
fn C.ImGuiMenuColumns_Update(self &MenuColumns, spacing f32, window_reappearing bool)

@[inline]
pub fn menu_columns_update(self &MenuColumns, spacing f32, window_reappearing bool) {
	C.ImGuiMenuColumns_Update(self, spacing, window_reappearing)
}

@[keep_args_alive]
fn C.ImGuiMenuColumns_DeclColumns(self &MenuColumns, w_icon f32, w_label f32, w_shortcut f32, w_mark f32) f32

@[inline]
pub fn menu_columns_decl_columns(self &MenuColumns, w_icon f32, w_label f32, w_shortcut f32, w_mark f32) f32 {
	return C.ImGuiMenuColumns_DeclColumns(self, w_icon, w_label, w_shortcut, w_mark)
}

@[keep_args_alive]
fn C.ImGuiMenuColumns_CalcNextTotalWidth(self &MenuColumns, update_offsets bool)

@[inline]
pub fn menu_columns_calc_next_total_width(self &MenuColumns, update_offsets bool) {
	C.ImGuiMenuColumns_CalcNextTotalWidth(self, update_offsets)
}

@[keep_args_alive]
fn C.ImGuiInputTextDeactivatedState_ImGuiInputTextDeactivatedState() &InputTextDeactivatedState

@[inline]
pub fn input_text_deactivated_state_input_text_deactivated_state() &InputTextDeactivatedState {
	return C.ImGuiInputTextDeactivatedState_ImGuiInputTextDeactivatedState()
}

@[keep_args_alive]
fn C.ImGuiInputTextDeactivatedState_destroy(self &InputTextDeactivatedState)

@[inline]
pub fn input_text_deactivated_state_destroy(self &InputTextDeactivatedState) {
	C.ImGuiInputTextDeactivatedState_destroy(self)
}

@[keep_args_alive]
fn C.ImGuiInputTextDeactivatedState_ClearFreeMemory(self &InputTextDeactivatedState)

@[inline]
pub fn input_text_deactivated_state_clear_free_memory(self &InputTextDeactivatedState) {
	C.ImGuiInputTextDeactivatedState_ClearFreeMemory(self)
}

@[keep_args_alive]
fn C.ImGuiInputTextState_ImGuiInputTextState() &InputTextState

@[inline]
pub fn input_text_state_input_text_state() &InputTextState {
	return C.ImGuiInputTextState_ImGuiInputTextState()
}

@[keep_args_alive]
fn C.ImGuiInputTextState_destroy(self &InputTextState)

@[inline]
pub fn input_text_state_destroy(self &InputTextState) {
	C.ImGuiInputTextState_destroy(self)
}

@[keep_args_alive]
fn C.ImGuiInputTextState_ClearText(self &InputTextState)

@[inline]
pub fn input_text_state_clear_text(self &InputTextState) {
	C.ImGuiInputTextState_ClearText(self)
}

@[keep_args_alive]
fn C.ImGuiInputTextState_ClearFreeMemory(self &InputTextState)

@[inline]
pub fn input_text_state_clear_free_memory(self &InputTextState) {
	C.ImGuiInputTextState_ClearFreeMemory(self)
}

@[keep_args_alive]
fn C.ImGuiInputTextState_OnKeyPressed(self &InputTextState, key i32)

@[inline]
pub fn input_text_state_on_key_pressed(self &InputTextState, key i32) {
	C.ImGuiInputTextState_OnKeyPressed(self, key)
}

@[keep_args_alive]
fn C.ImGuiInputTextState_OnCharPressed(self &InputTextState, c u32)

@[inline]
pub fn input_text_state_on_char_pressed(self &InputTextState, c u32) {
	C.ImGuiInputTextState_OnCharPressed(self, c)
}

@[keep_args_alive]
fn C.ImGuiInputTextState_GetPreferredOffsetX(self &InputTextState) f32

@[inline]
pub fn input_text_state_get_preferred_offset_x(self &InputTextState) f32 {
	return C.ImGuiInputTextState_GetPreferredOffsetX(self)
}

@[keep_args_alive]
fn C.ImGuiInputTextState_GetText(self &InputTextState) &char

@[inline]
pub fn input_text_state_get_text(self &InputTextState) &char {
	return C.ImGuiInputTextState_GetText(self)
}

@[keep_args_alive]
fn C.ImGuiInputTextState_CursorAnimReset(self &InputTextState)

@[inline]
pub fn input_text_state_cursor_anim_reset(self &InputTextState) {
	C.ImGuiInputTextState_CursorAnimReset(self)
}

@[keep_args_alive]
fn C.ImGuiInputTextState_CursorClamp(self &InputTextState)

@[inline]
pub fn input_text_state_cursor_clamp(self &InputTextState) {
	C.ImGuiInputTextState_CursorClamp(self)
}

@[keep_args_alive]
fn C.ImGuiInputTextState_HasSelection(self &InputTextState) bool

@[inline]
pub fn input_text_state_has_selection(self &InputTextState) bool {
	return C.ImGuiInputTextState_HasSelection(self)
}

@[keep_args_alive]
fn C.ImGuiInputTextState_ClearSelection(self &InputTextState)

@[inline]
pub fn input_text_state_clear_selection(self &InputTextState) {
	C.ImGuiInputTextState_ClearSelection(self)
}

@[keep_args_alive]
fn C.ImGuiInputTextState_GetCursorPos(self &InputTextState) i32

@[inline]
pub fn input_text_state_get_cursor_pos(self &InputTextState) i32 {
	return C.ImGuiInputTextState_GetCursorPos(self)
}

@[keep_args_alive]
fn C.ImGuiInputTextState_GetSelectionStart(self &InputTextState) i32

@[inline]
pub fn input_text_state_get_selection_start(self &InputTextState) i32 {
	return C.ImGuiInputTextState_GetSelectionStart(self)
}

@[keep_args_alive]
fn C.ImGuiInputTextState_GetSelectionEnd(self &InputTextState) i32

@[inline]
pub fn input_text_state_get_selection_end(self &InputTextState) i32 {
	return C.ImGuiInputTextState_GetSelectionEnd(self)
}

@[keep_args_alive]
fn C.ImGuiInputTextState_SetSelection(self &InputTextState, start i32, end i32)

@[inline]
pub fn input_text_state_set_selection(self &InputTextState, start i32, end i32) {
	C.ImGuiInputTextState_SetSelection(self, start, end)
}

@[keep_args_alive]
fn C.ImGuiInputTextState_SelectAll(self &InputTextState)

@[inline]
pub fn input_text_state_select_all(self &InputTextState) {
	C.ImGuiInputTextState_SelectAll(self)
}

@[keep_args_alive]
fn C.ImGuiInputTextState_ReloadUserBufAndSelectAll(self &InputTextState)

@[inline]
pub fn input_text_state_reload_user_buf_and_select_all(self &InputTextState) {
	C.ImGuiInputTextState_ReloadUserBufAndSelectAll(self)
}

@[keep_args_alive]
fn C.ImGuiInputTextState_ReloadUserBufAndKeepSelection(self &InputTextState)

@[inline]
pub fn input_text_state_reload_user_buf_and_keep_selection(self &InputTextState) {
	C.ImGuiInputTextState_ReloadUserBufAndKeepSelection(self)
}

@[keep_args_alive]
fn C.ImGuiInputTextState_ReloadUserBufAndMoveToEnd(self &InputTextState)

@[inline]
pub fn input_text_state_reload_user_buf_and_move_to_end(self &InputTextState) {
	C.ImGuiInputTextState_ReloadUserBufAndMoveToEnd(self)
}

@[keep_args_alive]
fn C.ImGuiNextWindowData_ImGuiNextWindowData() &NextWindowData

@[inline]
pub fn next_window_data_next_window_data() &NextWindowData {
	return C.ImGuiNextWindowData_ImGuiNextWindowData()
}

@[keep_args_alive]
fn C.ImGuiNextWindowData_destroy(self &NextWindowData)

@[inline]
pub fn next_window_data_destroy(self &NextWindowData) {
	C.ImGuiNextWindowData_destroy(self)
}

@[keep_args_alive]
fn C.ImGuiNextWindowData_ClearFlags(self &NextWindowData)

@[inline]
pub fn next_window_data_clear_flags(self &NextWindowData) {
	C.ImGuiNextWindowData_ClearFlags(self)
}

@[keep_args_alive]
fn C.ImGuiNextItemData_ImGuiNextItemData() &NextItemData

@[inline]
pub fn next_item_data_next_item_data() &NextItemData {
	return C.ImGuiNextItemData_ImGuiNextItemData()
}

@[keep_args_alive]
fn C.ImGuiNextItemData_destroy(self &NextItemData)

@[inline]
pub fn next_item_data_destroy(self &NextItemData) {
	C.ImGuiNextItemData_destroy(self)
}

@[keep_args_alive]
fn C.ImGuiNextItemData_ClearFlags(self &NextItemData)

@[inline]
pub fn next_item_data_clear_flags(self &NextItemData) {
	C.ImGuiNextItemData_ClearFlags(self)
}

@[keep_args_alive]
fn C.ImGuiLastItemData_ImGuiLastItemData() &LastItemData

@[inline]
pub fn last_item_data_last_item_data() &LastItemData {
	return C.ImGuiLastItemData_ImGuiLastItemData()
}

@[keep_args_alive]
fn C.ImGuiLastItemData_destroy(self &LastItemData)

@[inline]
pub fn last_item_data_destroy(self &LastItemData) {
	C.ImGuiLastItemData_destroy(self)
}

@[keep_args_alive]
fn C.ImGuiErrorRecoveryState_ImGuiErrorRecoveryState() &ErrorRecoveryState

@[inline]
pub fn error_recovery_state_error_recovery_state() &ErrorRecoveryState {
	return C.ImGuiErrorRecoveryState_ImGuiErrorRecoveryState()
}

@[keep_args_alive]
fn C.ImGuiErrorRecoveryState_destroy(self &ErrorRecoveryState)

@[inline]
pub fn error_recovery_state_destroy(self &ErrorRecoveryState) {
	C.ImGuiErrorRecoveryState_destroy(self)
}

@[keep_args_alive]
fn C.ImGuiPtrOrIndex_ImGuiPtrOrIndex_Ptr(ptr voidptr) &PtrOrIndex

@[inline]
pub fn ptr_or_index_ptr_or_index_ptr(ptr voidptr) &PtrOrIndex {
	return C.ImGuiPtrOrIndex_ImGuiPtrOrIndex_Ptr(ptr)
}

@[keep_args_alive]
fn C.ImGuiPtrOrIndex_destroy(self &PtrOrIndex)

@[inline]
pub fn ptr_or_index_destroy(self &PtrOrIndex) {
	C.ImGuiPtrOrIndex_destroy(self)
}

@[keep_args_alive]
fn C.ImGuiPtrOrIndex_ImGuiPtrOrIndex_Int(index i32) &PtrOrIndex

@[inline]
pub fn ptr_or_index_ptr_or_index_int(index i32) &PtrOrIndex {
	return C.ImGuiPtrOrIndex_ImGuiPtrOrIndex_Int(index)
}

@[keep_args_alive]
fn C.ImGuiPopupData_ImGuiPopupData() &PopupData

@[inline]
pub fn popup_data_popup_data() &PopupData {
	return C.ImGuiPopupData_ImGuiPopupData()
}

@[keep_args_alive]
fn C.ImGuiPopupData_destroy(self &PopupData)

@[inline]
pub fn popup_data_destroy(self &PopupData) {
	C.ImGuiPopupData_destroy(self)
}

@[keep_args_alive]
fn C.ImGuiInputEvent_ImGuiInputEvent() &InputEvent

@[inline]
pub fn input_event_input_event() &InputEvent {
	return C.ImGuiInputEvent_ImGuiInputEvent()
}

@[keep_args_alive]
fn C.ImGuiInputEvent_destroy(self &InputEvent)

@[inline]
pub fn input_event_destroy(self &InputEvent) {
	C.ImGuiInputEvent_destroy(self)
}

@[keep_args_alive]
fn C.ImGuiKeyRoutingData_ImGuiKeyRoutingData() &KeyRoutingData

@[inline]
pub fn key_routing_data_key_routing_data() &KeyRoutingData {
	return C.ImGuiKeyRoutingData_ImGuiKeyRoutingData()
}

@[keep_args_alive]
fn C.ImGuiKeyRoutingData_destroy(self &KeyRoutingData)

@[inline]
pub fn key_routing_data_destroy(self &KeyRoutingData) {
	C.ImGuiKeyRoutingData_destroy(self)
}

@[keep_args_alive]
fn C.ImGuiKeyRoutingTable_ImGuiKeyRoutingTable() &KeyRoutingTable

@[inline]
pub fn key_routing_table_key_routing_table() &KeyRoutingTable {
	return C.ImGuiKeyRoutingTable_ImGuiKeyRoutingTable()
}

@[keep_args_alive]
fn C.ImGuiKeyRoutingTable_destroy(self &KeyRoutingTable)

@[inline]
pub fn key_routing_table_destroy(self &KeyRoutingTable) {
	C.ImGuiKeyRoutingTable_destroy(self)
}

@[keep_args_alive]
fn C.ImGuiKeyRoutingTable_Clear(self &KeyRoutingTable)

@[inline]
pub fn key_routing_table_clear(self &KeyRoutingTable) {
	C.ImGuiKeyRoutingTable_Clear(self)
}

@[keep_args_alive]
fn C.ImGuiKeyOwnerData_ImGuiKeyOwnerData() &KeyOwnerData

@[inline]
pub fn key_owner_data_key_owner_data() &KeyOwnerData {
	return C.ImGuiKeyOwnerData_ImGuiKeyOwnerData()
}

@[keep_args_alive]
fn C.ImGuiKeyOwnerData_destroy(self &KeyOwnerData)

@[inline]
pub fn key_owner_data_destroy(self &KeyOwnerData) {
	C.ImGuiKeyOwnerData_destroy(self)
}

@[keep_args_alive]
fn C.ImGuiListClipperRange_FromIndices(min i32, max i32) ListClipperRange

@[inline]
pub fn list_clipper_range_from_indices(min i32, max i32) ListClipperRange {
	return C.ImGuiListClipperRange_FromIndices(min, max)
}

@[keep_args_alive]
fn C.ImGuiListClipperRange_FromPositions(y1 f32, y2 f32, off_min i32, off_max i32) ListClipperRange

@[inline]
pub fn list_clipper_range_from_positions(y1 f32, y2 f32, off_min i32, off_max i32) ListClipperRange {
	return C.ImGuiListClipperRange_FromPositions(y1, y2, off_min, off_max)
}

@[keep_args_alive]
fn C.ImGuiListClipperData_ImGuiListClipperData() &ListClipperData

@[inline]
pub fn list_clipper_data_list_clipper_data() &ListClipperData {
	return C.ImGuiListClipperData_ImGuiListClipperData()
}

@[keep_args_alive]
fn C.ImGuiListClipperData_destroy(self &ListClipperData)

@[inline]
pub fn list_clipper_data_destroy(self &ListClipperData) {
	C.ImGuiListClipperData_destroy(self)
}

@[keep_args_alive]
fn C.ImGuiListClipperData_Reset(self &ListClipperData, clipper &ListClipper)

@[inline]
pub fn list_clipper_data_reset(self &ListClipperData, clipper &ListClipper) {
	C.ImGuiListClipperData_Reset(self, clipper)
}

@[keep_args_alive]
fn C.ImGuiNavItemData_ImGuiNavItemData() &NavItemData

@[inline]
pub fn nav_item_data_nav_item_data() &NavItemData {
	return C.ImGuiNavItemData_ImGuiNavItemData()
}

@[keep_args_alive]
fn C.ImGuiNavItemData_destroy(self &NavItemData)

@[inline]
pub fn nav_item_data_destroy(self &NavItemData) {
	C.ImGuiNavItemData_destroy(self)
}

@[keep_args_alive]
fn C.ImGuiNavItemData_Clear(self &NavItemData)

@[inline]
pub fn nav_item_data_clear(self &NavItemData) {
	C.ImGuiNavItemData_Clear(self)
}

@[keep_args_alive]
fn C.ImGuiTypingSelectState_ImGuiTypingSelectState() &TypingSelectState

@[inline]
pub fn typing_select_state_typing_select_state() &TypingSelectState {
	return C.ImGuiTypingSelectState_ImGuiTypingSelectState()
}

@[keep_args_alive]
fn C.ImGuiTypingSelectState_destroy(self &TypingSelectState)

@[inline]
pub fn typing_select_state_destroy(self &TypingSelectState) {
	C.ImGuiTypingSelectState_destroy(self)
}

@[keep_args_alive]
fn C.ImGuiTypingSelectState_Clear(self &TypingSelectState)

@[inline]
pub fn typing_select_state_clear(self &TypingSelectState) {
	C.ImGuiTypingSelectState_Clear(self)
}

@[keep_args_alive]
fn C.ImGuiOldColumnData_ImGuiOldColumnData() &OldColumnData

@[inline]
pub fn old_column_data_old_column_data() &OldColumnData {
	return C.ImGuiOldColumnData_ImGuiOldColumnData()
}

@[keep_args_alive]
fn C.ImGuiOldColumnData_destroy(self &OldColumnData)

@[inline]
pub fn old_column_data_destroy(self &OldColumnData) {
	C.ImGuiOldColumnData_destroy(self)
}

@[keep_args_alive]
fn C.ImGuiOldColumns_ImGuiOldColumns() &OldColumns

@[inline]
pub fn old_columns_old_columns() &OldColumns {
	return C.ImGuiOldColumns_ImGuiOldColumns()
}

@[keep_args_alive]
fn C.ImGuiOldColumns_destroy(self &OldColumns)

@[inline]
pub fn old_columns_destroy(self &OldColumns) {
	C.ImGuiOldColumns_destroy(self)
}

@[keep_args_alive]
fn C.ImGuiBoxSelectState_ImGuiBoxSelectState() &BoxSelectState

@[inline]
pub fn box_select_state_box_select_state() &BoxSelectState {
	return C.ImGuiBoxSelectState_ImGuiBoxSelectState()
}

@[keep_args_alive]
fn C.ImGuiBoxSelectState_destroy(self &BoxSelectState)

@[inline]
pub fn box_select_state_destroy(self &BoxSelectState) {
	C.ImGuiBoxSelectState_destroy(self)
}

@[keep_args_alive]
fn C.ImGuiMultiSelectTempData_ImGuiMultiSelectTempData() &MultiSelectTempData

@[inline]
pub fn multi_select_temp_data_multi_select_temp_data() &MultiSelectTempData {
	return C.ImGuiMultiSelectTempData_ImGuiMultiSelectTempData()
}

@[keep_args_alive]
fn C.ImGuiMultiSelectTempData_destroy(self &MultiSelectTempData)

@[inline]
pub fn multi_select_temp_data_destroy(self &MultiSelectTempData) {
	C.ImGuiMultiSelectTempData_destroy(self)
}

@[keep_args_alive]
fn C.ImGuiMultiSelectTempData_Clear(self &MultiSelectTempData)

@[inline]
pub fn multi_select_temp_data_clear(self &MultiSelectTempData) {
	C.ImGuiMultiSelectTempData_Clear(self)
}

@[keep_args_alive]
fn C.ImGuiMultiSelectTempData_ClearIO(self &MultiSelectTempData)

@[inline]
pub fn multi_select_temp_data_clear_io(self &MultiSelectTempData) {
	C.ImGuiMultiSelectTempData_ClearIO(self)
}

@[keep_args_alive]
fn C.ImGuiMultiSelectState_ImGuiMultiSelectState() &MultiSelectState

@[inline]
pub fn multi_select_state_multi_select_state() &MultiSelectState {
	return C.ImGuiMultiSelectState_ImGuiMultiSelectState()
}

@[keep_args_alive]
fn C.ImGuiMultiSelectState_destroy(self &MultiSelectState)

@[inline]
pub fn multi_select_state_destroy(self &MultiSelectState) {
	C.ImGuiMultiSelectState_destroy(self)
}

@[keep_args_alive]
fn C.ImGuiDockNode_ImGuiDockNode(id ID) &DockNode

@[inline]
pub fn dock_node_dock_node(id ID) &DockNode {
	return C.ImGuiDockNode_ImGuiDockNode(id)
}

@[keep_args_alive]
fn C.ImGuiDockNode_destroy(self &DockNode)

@[inline]
pub fn dock_node_destroy(self &DockNode) {
	C.ImGuiDockNode_destroy(self)
}

@[keep_args_alive]
fn C.ImGuiDockNode_IsRootNode(self &DockNode) bool

@[inline]
pub fn dock_node_is_root_node(self &DockNode) bool {
	return C.ImGuiDockNode_IsRootNode(self)
}

@[keep_args_alive]
fn C.ImGuiDockNode_IsDockSpace(self &DockNode) bool

@[inline]
pub fn dock_node_is_dock_space(self &DockNode) bool {
	return C.ImGuiDockNode_IsDockSpace(self)
}

@[keep_args_alive]
fn C.ImGuiDockNode_IsFloatingNode(self &DockNode) bool

@[inline]
pub fn dock_node_is_floating_node(self &DockNode) bool {
	return C.ImGuiDockNode_IsFloatingNode(self)
}

@[keep_args_alive]
fn C.ImGuiDockNode_IsCentralNode(self &DockNode) bool

@[inline]
pub fn dock_node_is_central_node(self &DockNode) bool {
	return C.ImGuiDockNode_IsCentralNode(self)
}

@[keep_args_alive]
fn C.ImGuiDockNode_IsHiddenTabBar(self &DockNode) bool

@[inline]
pub fn dock_node_is_hidden_tab_bar(self &DockNode) bool {
	return C.ImGuiDockNode_IsHiddenTabBar(self)
}

@[keep_args_alive]
fn C.ImGuiDockNode_IsNoTabBar(self &DockNode) bool

@[inline]
pub fn dock_node_is_no_tab_bar(self &DockNode) bool {
	return C.ImGuiDockNode_IsNoTabBar(self)
}

@[keep_args_alive]
fn C.ImGuiDockNode_IsSplitNode(self &DockNode) bool

@[inline]
pub fn dock_node_is_split_node(self &DockNode) bool {
	return C.ImGuiDockNode_IsSplitNode(self)
}

@[keep_args_alive]
fn C.ImGuiDockNode_IsLeafNode(self &DockNode) bool

@[inline]
pub fn dock_node_is_leaf_node(self &DockNode) bool {
	return C.ImGuiDockNode_IsLeafNode(self)
}

@[keep_args_alive]
fn C.ImGuiDockNode_IsEmpty(self &DockNode) bool

@[inline]
pub fn dock_node_is_empty(self &DockNode) bool {
	return C.ImGuiDockNode_IsEmpty(self)
}

@[keep_args_alive]
fn C.ImGuiDockNode_Rect(self &DockNode) ImRect_c

@[inline]
pub fn dock_node_rect(self &DockNode) ImRect_c {
	return C.ImGuiDockNode_Rect(self)
}

@[keep_args_alive]
fn C.ImGuiDockNode_SetLocalFlags(self &DockNode, flags DockNodeFlags)

@[inline]
pub fn dock_node_set_local_flags(self &DockNode, flags DockNodeFlags) {
	C.ImGuiDockNode_SetLocalFlags(self, flags)
}

@[keep_args_alive]
fn C.ImGuiDockNode_UpdateMergedFlags(self &DockNode)

@[inline]
pub fn dock_node_update_merged_flags(self &DockNode) {
	C.ImGuiDockNode_UpdateMergedFlags(self)
}

@[keep_args_alive]
fn C.ImGuiDockContext_ImGuiDockContext() &DockContext

@[inline]
pub fn dock_context_dock_context() &DockContext {
	return C.ImGuiDockContext_ImGuiDockContext()
}

@[keep_args_alive]
fn C.ImGuiDockContext_destroy(self &DockContext)

@[inline]
pub fn dock_context_destroy(self &DockContext) {
	C.ImGuiDockContext_destroy(self)
}

@[keep_args_alive]
fn C.ImGuiViewportP_ImGuiViewportP() &ViewportP

@[inline]
pub fn viewport_p_viewport_p() &ViewportP {
	return C.ImGuiViewportP_ImGuiViewportP()
}

@[keep_args_alive]
fn C.ImGuiViewportP_destroy(self &ViewportP)

@[inline]
pub fn viewport_p_destroy(self &ViewportP) {
	C.ImGuiViewportP_destroy(self)
}

@[keep_args_alive]
fn C.ImGuiViewportP_ClearRequestFlags(self &ViewportP)

@[inline]
pub fn viewport_p_clear_request_flags(self &ViewportP) {
	C.ImGuiViewportP_ClearRequestFlags(self)
}

@[keep_args_alive]
fn C.ImGuiViewportP_CalcWorkRectPos(self &ViewportP, inset_min ImVec2_c) ImVec2_c

@[inline]
pub fn viewport_p_calc_work_rect_pos(self &ViewportP, inset_min ImVec2_c) ImVec2_c {
	return C.ImGuiViewportP_CalcWorkRectPos(self, inset_min)
}

@[keep_args_alive]
fn C.ImGuiViewportP_CalcWorkRectSize(self &ViewportP, inset_min ImVec2_c, inset_max ImVec2_c) ImVec2_c

@[inline]
pub fn viewport_p_calc_work_rect_size(self &ViewportP, inset_min ImVec2_c, inset_max ImVec2_c) ImVec2_c {
	return C.ImGuiViewportP_CalcWorkRectSize(self, inset_min, inset_max)
}

@[keep_args_alive]
fn C.ImGuiViewportP_UpdateWorkRect(self &ViewportP)

@[inline]
pub fn viewport_p_update_work_rect(self &ViewportP) {
	C.ImGuiViewportP_UpdateWorkRect(self)
}

@[keep_args_alive]
fn C.ImGuiViewportP_GetMainRect(self &ViewportP) ImRect_c

@[inline]
pub fn viewport_p_get_main_rect(self &ViewportP) ImRect_c {
	return C.ImGuiViewportP_GetMainRect(self)
}

@[keep_args_alive]
fn C.ImGuiViewportP_GetWorkRect(self &ViewportP) ImRect_c

@[inline]
pub fn viewport_p_get_work_rect(self &ViewportP) ImRect_c {
	return C.ImGuiViewportP_GetWorkRect(self)
}

@[keep_args_alive]
fn C.ImGuiViewportP_GetBuildWorkRect(self &ViewportP) ImRect_c

@[inline]
pub fn viewport_p_get_build_work_rect(self &ViewportP) ImRect_c {
	return C.ImGuiViewportP_GetBuildWorkRect(self)
}

@[keep_args_alive]
fn C.ImGuiWindowSettings_ImGuiWindowSettings() &WindowSettings

@[inline]
pub fn window_settings_window_settings() &WindowSettings {
	return C.ImGuiWindowSettings_ImGuiWindowSettings()
}

@[keep_args_alive]
fn C.ImGuiWindowSettings_destroy(self &WindowSettings)

@[inline]
pub fn window_settings_destroy(self &WindowSettings) {
	C.ImGuiWindowSettings_destroy(self)
}

@[keep_args_alive]
fn C.ImGuiWindowSettings_GetName(self &WindowSettings) &char

@[inline]
pub fn window_settings_get_name(self &WindowSettings) &char {
	return C.ImGuiWindowSettings_GetName(self)
}

@[keep_args_alive]
fn C.ImGuiSettingsHandler_ImGuiSettingsHandler() &SettingsHandler

@[inline]
pub fn settings_handler_settings_handler() &SettingsHandler {
	return C.ImGuiSettingsHandler_ImGuiSettingsHandler()
}

@[keep_args_alive]
fn C.ImGuiSettingsHandler_destroy(self &SettingsHandler)

@[inline]
pub fn settings_handler_destroy(self &SettingsHandler) {
	C.ImGuiSettingsHandler_destroy(self)
}

@[keep_args_alive]
fn C.ImGuiDebugAllocInfo_ImGuiDebugAllocInfo() &DebugAllocInfo

@[inline]
pub fn debug_alloc_info_debug_alloc_info() &DebugAllocInfo {
	return C.ImGuiDebugAllocInfo_ImGuiDebugAllocInfo()
}

@[keep_args_alive]
fn C.ImGuiDebugAllocInfo_destroy(self &DebugAllocInfo)

@[inline]
pub fn debug_alloc_info_destroy(self &DebugAllocInfo) {
	C.ImGuiDebugAllocInfo_destroy(self)
}

@[keep_args_alive]
fn C.ImGuiStackLevelInfo_ImGuiStackLevelInfo() &StackLevelInfo

@[inline]
pub fn stack_level_info_stack_level_info() &StackLevelInfo {
	return C.ImGuiStackLevelInfo_ImGuiStackLevelInfo()
}

@[keep_args_alive]
fn C.ImGuiStackLevelInfo_destroy(self &StackLevelInfo)

@[inline]
pub fn stack_level_info_destroy(self &StackLevelInfo) {
	C.ImGuiStackLevelInfo_destroy(self)
}

@[keep_args_alive]
fn C.ImGuiDebugItemPathQuery_ImGuiDebugItemPathQuery() &DebugItemPathQuery

@[inline]
pub fn debug_item_path_query_debug_item_path_query() &DebugItemPathQuery {
	return C.ImGuiDebugItemPathQuery_ImGuiDebugItemPathQuery()
}

@[keep_args_alive]
fn C.ImGuiDebugItemPathQuery_destroy(self &DebugItemPathQuery)

@[inline]
pub fn debug_item_path_query_destroy(self &DebugItemPathQuery) {
	C.ImGuiDebugItemPathQuery_destroy(self)
}

@[keep_args_alive]
fn C.ImGuiIDStackTool_ImGuiIDStackTool() &IDStackTool

@[inline]
pub fn ids_tack_tool_ids_tack_tool() &IDStackTool {
	return C.ImGuiIDStackTool_ImGuiIDStackTool()
}

@[keep_args_alive]
fn C.ImGuiIDStackTool_destroy(self &IDStackTool)

@[inline]
pub fn ids_tack_tool_destroy(self &IDStackTool) {
	C.ImGuiIDStackTool_destroy(self)
}

@[keep_args_alive]
fn C.ImGuiContextHook_ImGuiContextHook() &ContextHook

@[inline]
pub fn context_hook_context_hook() &ContextHook {
	return C.ImGuiContextHook_ImGuiContextHook()
}

@[keep_args_alive]
fn C.ImGuiContextHook_destroy(self &ContextHook)

@[inline]
pub fn context_hook_destroy(self &ContextHook) {
	C.ImGuiContextHook_destroy(self)
}

@[keep_args_alive]
fn C.ImGuiContext_ImGuiContext(shared_font_atlas &ImFontAtlas) &Context

@[inline]
pub fn context_context(shared_font_atlas &ImFontAtlas) &Context {
	return C.ImGuiContext_ImGuiContext(shared_font_atlas)
}

@[keep_args_alive]
fn C.ImGuiContext_destroy(self &Context)

@[inline]
pub fn context_destroy(self &Context) {
	C.ImGuiContext_destroy(self)
}

@[keep_args_alive]
fn C.ImGuiWindow_ImGuiWindow(context &Context, const_name &char) &Window

@[inline]
pub fn window_window(context &Context, const_name &char) &Window {
	return C.ImGuiWindow_ImGuiWindow(context, const_name)
}

@[keep_args_alive]
fn C.ImGuiWindow_destroy(self &Window)

@[inline]
pub fn window_destroy(self &Window) {
	C.ImGuiWindow_destroy(self)
}

@[keep_args_alive]
fn C.ImGuiWindow_GetID_Str(self &Window, const_str &char, str_end &char) ID

@[inline]
pub fn window_get_id_str(self &Window, const_str &char, str_end &char) ID {
	return C.ImGuiWindow_GetID_Str(self, const_str, str_end)
}

@[keep_args_alive]
fn C.ImGuiWindow_GetID_Ptr(self &Window, ptr voidptr) ID

@[inline]
pub fn window_get_id_ptr(self &Window, ptr voidptr) ID {
	return C.ImGuiWindow_GetID_Ptr(self, ptr)
}

@[keep_args_alive]
fn C.ImGuiWindow_GetID_Int(self &Window, n i32) ID

@[inline]
pub fn window_get_id_int(self &Window, n i32) ID {
	return C.ImGuiWindow_GetID_Int(self, n)
}

@[keep_args_alive]
fn C.ImGuiWindow_GetIDFromPos(self &Window, p_abs ImVec2_c) ID

@[inline]
pub fn window_get_idf_rom_pos(self &Window, p_abs ImVec2_c) ID {
	return C.ImGuiWindow_GetIDFromPos(self, p_abs)
}

@[keep_args_alive]
fn C.ImGuiWindow_GetIDFromRectangle(self &Window, r_abs ImRect_c) ID

@[inline]
pub fn window_get_idf_rom_rectangle(self &Window, r_abs ImRect_c) ID {
	return C.ImGuiWindow_GetIDFromRectangle(self, r_abs)
}

@[keep_args_alive]
fn C.ImGuiWindow_Rect(self &Window) ImRect_c

@[inline]
pub fn window_rect(self &Window) ImRect_c {
	return C.ImGuiWindow_Rect(self)
}

@[keep_args_alive]
fn C.ImGuiWindow_TitleBarRect(self &Window) ImRect_c

@[inline]
pub fn window_title_bar_rect(self &Window) ImRect_c {
	return C.ImGuiWindow_TitleBarRect(self)
}

@[keep_args_alive]
fn C.ImGuiWindow_MenuBarRect(self &Window) ImRect_c

@[inline]
pub fn window_menu_bar_rect(self &Window) ImRect_c {
	return C.ImGuiWindow_MenuBarRect(self)
}

@[keep_args_alive]
fn C.ImGuiTabItem_ImGuiTabItem() &TabItem

@[inline]
pub fn tab_item_tab_item() &TabItem {
	return C.ImGuiTabItem_ImGuiTabItem()
}

@[keep_args_alive]
fn C.ImGuiTabItem_destroy(self &TabItem)

@[inline]
pub fn tab_item_destroy(self &TabItem) {
	C.ImGuiTabItem_destroy(self)
}

@[keep_args_alive]
fn C.ImGuiTabBar_ImGuiTabBar() &TabBar

@[inline]
pub fn tab_bar_tab_bar() &TabBar {
	return C.ImGuiTabBar_ImGuiTabBar()
}

@[keep_args_alive]
fn C.ImGuiTabBar_destroy(self &TabBar)

@[inline]
pub fn tab_bar_destroy(self &TabBar) {
	C.ImGuiTabBar_destroy(self)
}

@[keep_args_alive]
fn C.ImGuiTableColumn_ImGuiTableColumn() &TableColumn

@[inline]
pub fn table_column_table_column() &TableColumn {
	return C.ImGuiTableColumn_ImGuiTableColumn()
}

@[keep_args_alive]
fn C.ImGuiTableColumn_destroy(self &TableColumn)

@[inline]
pub fn table_column_destroy(self &TableColumn) {
	C.ImGuiTableColumn_destroy(self)
}

@[keep_args_alive]
fn C.ImGuiTableInstanceData_ImGuiTableInstanceData() &TableInstanceData

@[inline]
pub fn table_instance_data_table_instance_data() &TableInstanceData {
	return C.ImGuiTableInstanceData_ImGuiTableInstanceData()
}

@[keep_args_alive]
fn C.ImGuiTableInstanceData_destroy(self &TableInstanceData)

@[inline]
pub fn table_instance_data_destroy(self &TableInstanceData) {
	C.ImGuiTableInstanceData_destroy(self)
}

@[keep_args_alive]
fn C.ImGuiTable_ImGuiTable() &Table

@[inline]
pub fn table_table() &Table {
	return C.ImGuiTable_ImGuiTable()
}

@[keep_args_alive]
fn C.ImGuiTable_destroy(self &Table)

@[inline]
pub fn table_destroy(self &Table) {
	C.ImGuiTable_destroy(self)
}

@[keep_args_alive]
fn C.ImGuiTableTempData_ImGuiTableTempData() &TableTempData

@[inline]
pub fn table_temp_data_table_temp_data() &TableTempData {
	return C.ImGuiTableTempData_ImGuiTableTempData()
}

@[keep_args_alive]
fn C.ImGuiTableTempData_destroy(self &TableTempData)

@[inline]
pub fn table_temp_data_destroy(self &TableTempData) {
	C.ImGuiTableTempData_destroy(self)
}

@[keep_args_alive]
fn C.ImGuiTableColumnSettings_ImGuiTableColumnSettings() &TableColumnSettings

@[inline]
pub fn table_column_settings_table_column_settings() &TableColumnSettings {
	return C.ImGuiTableColumnSettings_ImGuiTableColumnSettings()
}

@[keep_args_alive]
fn C.ImGuiTableColumnSettings_destroy(self &TableColumnSettings)

@[inline]
pub fn table_column_settings_destroy(self &TableColumnSettings) {
	C.ImGuiTableColumnSettings_destroy(self)
}

@[keep_args_alive]
fn C.ImGuiTableSettings_ImGuiTableSettings() &TableSettings

@[inline]
pub fn table_settings_table_settings() &TableSettings {
	return C.ImGuiTableSettings_ImGuiTableSettings()
}

@[keep_args_alive]
fn C.ImGuiTableSettings_destroy(self &TableSettings)

@[inline]
pub fn table_settings_destroy(self &TableSettings) {
	C.ImGuiTableSettings_destroy(self)
}

@[keep_args_alive]
fn C.ImGuiTableSettings_GetColumnSettings(self &TableSettings) &TableColumnSettings

@[inline]
pub fn table_settings_get_column_settings(self &TableSettings) &TableColumnSettings {
	return C.ImGuiTableSettings_GetColumnSettings(self)
}

@[keep_args_alive]
fn C.igGetIO_ContextPtr(ctx &Context) &IO

@[inline]
pub fn get_io_context_ptr(ctx &Context) &IO {
	return C.igGetIO_ContextPtr(ctx)
}

@[keep_args_alive]
fn C.igGetPlatformIO_ContextPtr(ctx &Context) &PlatformIO

@[inline]
pub fn get_platform_io_context_ptr(ctx &Context) &PlatformIO {
	return C.igGetPlatformIO_ContextPtr(ctx)
}

@[keep_args_alive]
fn C.igGetScale() f32

@[inline]
pub fn get_scale() f32 {
	return C.igGetScale()
}

@[keep_args_alive]
fn C.igGetCurrentWindowRead() &Window

@[inline]
pub fn get_current_window_read() &Window {
	return C.igGetCurrentWindowRead()
}

@[keep_args_alive]
fn C.igGetCurrentWindow() &Window

@[inline]
pub fn get_current_window() &Window {
	return C.igGetCurrentWindow()
}

@[keep_args_alive]
fn C.igFindWindowByID(id ID) &Window

@[inline]
pub fn find_window_by_id(id ID) &Window {
	return C.igFindWindowByID(id)
}

@[keep_args_alive]
fn C.igFindWindowByName(const_name &char) &Window

@[inline]
pub fn find_window_by_name(const_name &char) &Window {
	return C.igFindWindowByName(const_name)
}

@[keep_args_alive]
fn C.igUpdateWindowParentAndRootLinks(window &Window, flags WindowFlags, parent_window &Window)

@[inline]
pub fn update_window_parent_and_root_links(window &Window, flags WindowFlags, parent_window &Window) {
	C.igUpdateWindowParentAndRootLinks(window, flags, parent_window)
}

@[keep_args_alive]
fn C.igUpdateWindowSkipRefresh(window &Window)

@[inline]
pub fn update_window_skip_refresh(window &Window) {
	C.igUpdateWindowSkipRefresh(window)
}

@[keep_args_alive]
fn C.igCalcWindowNextAutoFitSize(window &Window) ImVec2_c

@[inline]
pub fn calc_window_next_auto_fit_size(window &Window) ImVec2_c {
	return C.igCalcWindowNextAutoFitSize(window)
}

@[keep_args_alive]
fn C.igIsWindowChildOf(window &Window, potential_parent &Window, popup_hierarchy bool, dock_hierarchy bool) bool

@[inline]
pub fn is_window_child_of(window &Window, potential_parent &Window, popup_hierarchy bool, dock_hierarchy bool) bool {
	return C.igIsWindowChildOf(window, potential_parent, popup_hierarchy, dock_hierarchy)
}

@[keep_args_alive]
fn C.igIsWindowInBeginStack(window &Window) bool

@[inline]
pub fn is_window_in_begin_stack(window &Window) bool {
	return C.igIsWindowInBeginStack(window)
}

@[keep_args_alive]
fn C.igIsWindowWithinBeginStackOf(window &Window, potential_parent &Window) bool

@[inline]
pub fn is_window_within_begin_stack_of(window &Window, potential_parent &Window) bool {
	return C.igIsWindowWithinBeginStackOf(window, potential_parent)
}

@[keep_args_alive]
fn C.igIsWindowAbove(potential_above &Window, potential_below &Window) bool

@[inline]
pub fn is_window_above(potential_above &Window, potential_below &Window) bool {
	return C.igIsWindowAbove(potential_above, potential_below)
}

@[keep_args_alive]
fn C.igIsWindowNavFocusable(window &Window) bool

@[inline]
pub fn is_window_nav_focusable(window &Window) bool {
	return C.igIsWindowNavFocusable(window)
}

@[keep_args_alive]
fn C.igSetWindowPos_WindowPtr(window &Window, pos ImVec2_c, cond Cond)

@[inline]
pub fn set_window_pos_window_ptr(window &Window, pos ImVec2_c, cond Cond) {
	C.igSetWindowPos_WindowPtr(window, pos, cond)
}

@[keep_args_alive]
fn C.igSetWindowSize_WindowPtr(window &Window, size ImVec2_c, cond Cond)

@[inline]
pub fn set_window_size_window_ptr(window &Window, size ImVec2_c, cond Cond) {
	C.igSetWindowSize_WindowPtr(window, size, cond)
}

@[keep_args_alive]
fn C.igSetWindowCollapsed_WindowPtr(window &Window, collapsed bool, cond Cond)

@[inline]
pub fn set_window_collapsed_window_ptr(window &Window, collapsed bool, cond Cond) {
	C.igSetWindowCollapsed_WindowPtr(window, collapsed, cond)
}

@[keep_args_alive]
fn C.igSetWindowHitTestHole(window &Window, pos ImVec2_c, size ImVec2_c)

@[inline]
pub fn set_window_hit_test_hole(window &Window, pos ImVec2_c, size ImVec2_c) {
	C.igSetWindowHitTestHole(window, pos, size)
}

@[keep_args_alive]
fn C.igSetWindowHiddenAndSkipItemsForCurrentFrame(window &Window)

@[inline]
pub fn set_window_hidden_and_skip_items_for_current_frame(window &Window) {
	C.igSetWindowHiddenAndSkipItemsForCurrentFrame(window)
}

@[keep_args_alive]
fn C.igSetWindowParentWindowForFocusRoute(window &Window, parent_window &Window)

@[inline]
pub fn set_window_parent_window_for_focus_route(window &Window, parent_window &Window) {
	C.igSetWindowParentWindowForFocusRoute(window, parent_window)
}

@[keep_args_alive]
fn C.igWindowRectAbsToRel(window &Window, r ImRect_c) ImRect_c

@[inline]
pub fn window_rect_abs_to_rel(window &Window, r ImRect_c) ImRect_c {
	return C.igWindowRectAbsToRel(window, r)
}

@[keep_args_alive]
fn C.igWindowRectRelToAbs(window &Window, r ImRect_c) ImRect_c

@[inline]
pub fn window_rect_rel_to_abs(window &Window, r ImRect_c) ImRect_c {
	return C.igWindowRectRelToAbs(window, r)
}

@[keep_args_alive]
fn C.igWindowPosAbsToRel(window &Window, p ImVec2_c) ImVec2_c

@[inline]
pub fn window_pos_abs_to_rel(window &Window, p ImVec2_c) ImVec2_c {
	return C.igWindowPosAbsToRel(window, p)
}

@[keep_args_alive]
fn C.igWindowPosRelToAbs(window &Window, p ImVec2_c) ImVec2_c

@[inline]
pub fn window_pos_rel_to_abs(window &Window, p ImVec2_c) ImVec2_c {
	return C.igWindowPosRelToAbs(window, p)
}

@[keep_args_alive]
fn C.igFocusWindow(window &Window, flags FocusRequestFlags)

@[inline]
pub fn focus_window(window &Window, flags FocusRequestFlags) {
	C.igFocusWindow(window, flags)
}

@[keep_args_alive]
fn C.igFocusTopMostWindowUnderOne(under_this_window &Window, ignore_window &Window, filter_viewport &Viewport, flags FocusRequestFlags)

@[inline]
pub fn focus_top_most_window_under_one(under_this_window &Window, ignore_window &Window, filter_viewport &Viewport, flags FocusRequestFlags) {
	C.igFocusTopMostWindowUnderOne(under_this_window, ignore_window, filter_viewport, flags)
}

@[keep_args_alive]
fn C.igBringWindowToFocusFront(window &Window)

@[inline]
pub fn bring_window_to_focus_front(window &Window) {
	C.igBringWindowToFocusFront(window)
}

@[keep_args_alive]
fn C.igBringWindowToDisplayFront(window &Window)

@[inline]
pub fn bring_window_to_display_front(window &Window) {
	C.igBringWindowToDisplayFront(window)
}

@[keep_args_alive]
fn C.igBringWindowToDisplayBack(window &Window)

@[inline]
pub fn bring_window_to_display_back(window &Window) {
	C.igBringWindowToDisplayBack(window)
}

@[keep_args_alive]
fn C.igBringWindowToDisplayBehind(window &Window, above_window &Window)

@[inline]
pub fn bring_window_to_display_behind(window &Window, above_window &Window) {
	C.igBringWindowToDisplayBehind(window, above_window)
}

@[keep_args_alive]
fn C.igFindWindowDisplayIndex(window &Window) i32

@[inline]
pub fn find_window_display_index(window &Window) i32 {
	return C.igFindWindowDisplayIndex(window)
}

@[keep_args_alive]
fn C.igFindBottomMostVisibleWindowWithinBeginStack(window &Window) &Window

@[inline]
pub fn find_bottom_most_visible_window_within_begin_stack(window &Window) &Window {
	return C.igFindBottomMostVisibleWindowWithinBeginStack(window)
}

@[keep_args_alive]
fn C.igSetNextWindowRefreshPolicy(flags WindowRefreshFlags)

@[inline]
pub fn set_next_window_refresh_policy(flags WindowRefreshFlags) {
	C.igSetNextWindowRefreshPolicy(flags)
}

@[keep_args_alive]
fn C.igRegisterUserTexture(tex &ImTextureData)

@[inline]
pub fn register_user_texture(tex &ImTextureData) {
	C.igRegisterUserTexture(tex)
}

@[keep_args_alive]
fn C.igUnregisterUserTexture(tex &ImTextureData)

@[inline]
pub fn unregister_user_texture(tex &ImTextureData) {
	C.igUnregisterUserTexture(tex)
}

@[keep_args_alive]
fn C.igRegisterFontAtlas(atlas &ImFontAtlas)

@[inline]
pub fn register_font_atlas(atlas &ImFontAtlas) {
	C.igRegisterFontAtlas(atlas)
}

@[keep_args_alive]
fn C.igUnregisterFontAtlas(atlas &ImFontAtlas)

@[inline]
pub fn unregister_font_atlas(atlas &ImFontAtlas) {
	C.igUnregisterFontAtlas(atlas)
}

@[keep_args_alive]
fn C.igSetCurrentFont(font &ImFont, font_size_before_scaling f32, font_size_after_scaling f32)

@[inline]
pub fn set_current_font(font &ImFont, font_size_before_scaling f32, font_size_after_scaling f32) {
	C.igSetCurrentFont(font, font_size_before_scaling, font_size_after_scaling)
}

@[keep_args_alive]
fn C.igUpdateCurrentFontSize(restore_font_size_after_scaling f32)

@[inline]
pub fn update_current_font_size(restore_font_size_after_scaling f32) {
	C.igUpdateCurrentFontSize(restore_font_size_after_scaling)
}

@[keep_args_alive]
fn C.igSetFontRasterizerDensity(rasterizer_density f32)

@[inline]
pub fn set_font_rasterizer_density(rasterizer_density f32) {
	C.igSetFontRasterizerDensity(rasterizer_density)
}

@[keep_args_alive]
fn C.igGetFontRasterizerDensity() f32

@[inline]
pub fn get_font_rasterizer_density() f32 {
	return C.igGetFontRasterizerDensity()
}

@[keep_args_alive]
fn C.igGetRoundedFontSize(size f32) f32

@[inline]
pub fn get_rounded_font_size(size f32) f32 {
	return C.igGetRoundedFontSize(size)
}

@[keep_args_alive]
fn C.igGetDefaultFont() &ImFont

@[inline]
pub fn get_default_font() &ImFont {
	return C.igGetDefaultFont()
}

@[keep_args_alive]
fn C.igPushPasswordFont()

@[inline]
pub fn push_password_font() {
	C.igPushPasswordFont()
}

@[keep_args_alive]
fn C.igPopPasswordFont()

@[inline]
pub fn pop_password_font() {
	C.igPopPasswordFont()
}

@[keep_args_alive]
fn C.igGetForegroundDrawList_WindowPtr(window &Window) &ImDrawList

@[inline]
pub fn get_foreground_draw_list_window_ptr(window &Window) &ImDrawList {
	return C.igGetForegroundDrawList_WindowPtr(window)
}

@[keep_args_alive]
fn C.igAddDrawListToDrawDataEx(draw_data &ImDrawData, out_list &ImVector_ImDrawListPtr, draw_list &ImDrawList)

@[inline]
pub fn add_draw_list_to_draw_data_ex(draw_data &ImDrawData, out_list &ImVector_ImDrawListPtr, draw_list &ImDrawList) {
	C.igAddDrawListToDrawDataEx(draw_data, out_list, draw_list)
}

@[keep_args_alive]
fn C.igInitialize()

@[inline]
pub fn initialize() {
	C.igInitialize()
}

@[keep_args_alive]
fn C.igShutdown()

@[inline]
pub fn shutdown() {
	C.igShutdown()
}

@[keep_args_alive]
fn C.igSetContextName(ctx &Context, const_name &char)

@[inline]
pub fn set_context_name(ctx &Context, const_name &char) {
	C.igSetContextName(ctx, const_name)
}

@[keep_args_alive]
fn C.igAddContextHook(ctx &Context, hook &ContextHook) ID

@[inline]
pub fn add_context_hook(ctx &Context, hook &ContextHook) ID {
	return C.igAddContextHook(ctx, hook)
}

@[keep_args_alive]
fn C.igRemoveContextHook(ctx &Context, hook_to_remove ID)

@[inline]
pub fn remove_context_hook(ctx &Context, hook_to_remove ID) {
	C.igRemoveContextHook(ctx, hook_to_remove)
}

@[keep_args_alive]
fn C.igCallContextHooks(ctx &Context, type_ ContextHookType)

@[inline]
pub fn call_context_hooks(ctx &Context, type_ ContextHookType) {
	C.igCallContextHooks(ctx, type_)
}

@[keep_args_alive]
fn C.igUpdateInputEvents(trickle_fast_inputs bool)

@[inline]
pub fn update_input_events(trickle_fast_inputs bool) {
	C.igUpdateInputEvents(trickle_fast_inputs)
}

@[keep_args_alive]
fn C.igUpdateHoveredWindowAndCaptureFlags(mouse_pos ImVec2_c)

@[inline]
pub fn update_hovered_window_and_capture_flags(mouse_pos ImVec2_c) {
	C.igUpdateHoveredWindowAndCaptureFlags(mouse_pos)
}

@[keep_args_alive]
fn C.igFindHoveredWindowEx(pos ImVec2_c, find_first_and_in_any_viewport bool, out_hovered_window &&Window, out_hovered_window_under_moving_window &&Window)

@[inline]
pub fn find_hovered_window_ex(pos ImVec2_c, find_first_and_in_any_viewport bool, out_hovered_window &&Window, out_hovered_window_under_moving_window &&Window) {
	C.igFindHoveredWindowEx(pos, find_first_and_in_any_viewport, out_hovered_window,
		out_hovered_window_under_moving_window)
}

@[keep_args_alive]
fn C.igStartMouseMovingWindow(window &Window)

@[inline]
pub fn start_mouse_moving_window(window &Window) {
	C.igStartMouseMovingWindow(window)
}

@[keep_args_alive]
fn C.igStartMouseMovingWindowOrNode(window &Window, node &DockNode, undock bool)

@[inline]
pub fn start_mouse_moving_window_or_node(window &Window, node &DockNode, undock bool) {
	C.igStartMouseMovingWindowOrNode(window, node, undock)
}

@[keep_args_alive]
fn C.igStopMouseMovingWindow()

@[inline]
pub fn stop_mouse_moving_window() {
	C.igStopMouseMovingWindow()
}

@[keep_args_alive]
fn C.igUpdateMouseMovingWindowNewFrame()

@[inline]
pub fn update_mouse_moving_window_new_frame() {
	C.igUpdateMouseMovingWindowNewFrame()
}

@[keep_args_alive]
fn C.igUpdateMouseMovingWindowEndFrame()

@[inline]
pub fn update_mouse_moving_window_end_frame() {
	C.igUpdateMouseMovingWindowEndFrame()
}

@[keep_args_alive]
fn C.igTranslateWindowsInViewport(viewport &ViewportP, old_pos ImVec2_c, new_pos ImVec2_c, old_size ImVec2_c, new_size ImVec2_c)

@[inline]
pub fn translate_windows_in_viewport(viewport &ViewportP, old_pos ImVec2_c, new_pos ImVec2_c, old_size ImVec2_c, new_size ImVec2_c) {
	C.igTranslateWindowsInViewport(viewport, old_pos, new_pos, old_size, new_size)
}

@[keep_args_alive]
fn C.igScaleWindowsInViewport(viewport &ViewportP, scale f32)

@[inline]
pub fn scale_windows_in_viewport(viewport &ViewportP, scale f32) {
	C.igScaleWindowsInViewport(viewport, scale)
}

@[keep_args_alive]
fn C.igDestroyPlatformWindow(viewport &ViewportP)

@[inline]
pub fn destroy_platform_window(viewport &ViewportP) {
	C.igDestroyPlatformWindow(viewport)
}

@[keep_args_alive]
fn C.igSetWindowViewport(window &Window, viewport &ViewportP)

@[inline]
pub fn set_window_viewport(window &Window, viewport &ViewportP) {
	C.igSetWindowViewport(window, viewport)
}

@[keep_args_alive]
fn C.igSetCurrentViewport(window &Window, viewport &ViewportP)

@[inline]
pub fn set_current_viewport(window &Window, viewport &ViewportP) {
	C.igSetCurrentViewport(window, viewport)
}

@[keep_args_alive]
fn C.igGetViewportPlatformMonitor(viewport &Viewport) &PlatformMonitor

@[inline]
pub fn get_viewport_platform_monitor(viewport &Viewport) &PlatformMonitor {
	return C.igGetViewportPlatformMonitor(viewport)
}

@[keep_args_alive]
fn C.igFindHoveredViewportFromPlatformWindowStack(mouse_platform_pos ImVec2_c) &ViewportP

@[inline]
pub fn find_hovered_viewport_from_platform_window_stack(mouse_platform_pos ImVec2_c) &ViewportP {
	return C.igFindHoveredViewportFromPlatformWindowStack(mouse_platform_pos)
}

@[keep_args_alive]
fn C.igMarkIniSettingsDirty_Nil()

@[inline]
pub fn mark_ini_settings_dirty_nil() {
	C.igMarkIniSettingsDirty_Nil()
}

@[keep_args_alive]
fn C.igMarkIniSettingsDirty_WindowPtr(window &Window)

@[inline]
pub fn mark_ini_settings_dirty_window_ptr(window &Window) {
	C.igMarkIniSettingsDirty_WindowPtr(window)
}

@[keep_args_alive]
fn C.igClearIniSettings()

@[inline]
pub fn clear_ini_settings() {
	C.igClearIniSettings()
}

@[keep_args_alive]
fn C.igAddSettingsHandler(handler &SettingsHandler)

@[inline]
pub fn add_settings_handler(handler &SettingsHandler) {
	C.igAddSettingsHandler(handler)
}

@[keep_args_alive]
fn C.igRemoveSettingsHandler(type_name &char)

@[inline]
pub fn remove_settings_handler(type_name &char) {
	C.igRemoveSettingsHandler(type_name)
}

@[keep_args_alive]
fn C.igFindSettingsHandler(type_name &char) &SettingsHandler

@[inline]
pub fn find_settings_handler(type_name &char) &SettingsHandler {
	return C.igFindSettingsHandler(type_name)
}

@[keep_args_alive]
fn C.igCreateNewWindowSettings(const_name &char) &WindowSettings

@[inline]
pub fn create_new_window_settings(const_name &char) &WindowSettings {
	return C.igCreateNewWindowSettings(const_name)
}

@[keep_args_alive]
fn C.igFindWindowSettingsByID(id ID) &WindowSettings

@[inline]
pub fn find_window_settings_by_id(id ID) &WindowSettings {
	return C.igFindWindowSettingsByID(id)
}

@[keep_args_alive]
fn C.igFindWindowSettingsByWindow(window &Window) &WindowSettings

@[inline]
pub fn find_window_settings_by_window(window &Window) &WindowSettings {
	return C.igFindWindowSettingsByWindow(window)
}

@[keep_args_alive]
fn C.igClearWindowSettings(const_name &char)

@[inline]
pub fn clear_window_settings(const_name &char) {
	C.igClearWindowSettings(const_name)
}

@[keep_args_alive]
fn C.igLocalizeRegisterEntries(entries &LocEntry, count i32)

@[inline]
pub fn localize_register_entries(entries &LocEntry, count i32) {
	C.igLocalizeRegisterEntries(entries, count)
}

@[keep_args_alive]
fn C.igLocalizeGetMsg(key LocKey) &char

@[inline]
pub fn localize_get_msg(key LocKey) &char {
	return C.igLocalizeGetMsg(key)
}

@[keep_args_alive]
fn C.igSetScrollX_WindowPtr(window &Window, scroll_x f32)

@[inline]
pub fn set_scroll_x_window_ptr(window &Window, scroll_x f32) {
	C.igSetScrollX_WindowPtr(window, scroll_x)
}

@[keep_args_alive]
fn C.igSetScrollY_WindowPtr(window &Window, scroll_y f32)

@[inline]
pub fn set_scroll_y_window_ptr(window &Window, scroll_y f32) {
	C.igSetScrollY_WindowPtr(window, scroll_y)
}

@[keep_args_alive]
fn C.igSetScrollFromPosX_WindowPtr(window &Window, local_x f32, center_x_ratio f32)

@[inline]
pub fn set_scroll_from_pos_x_window_ptr(window &Window, local_x f32, center_x_ratio f32) {
	C.igSetScrollFromPosX_WindowPtr(window, local_x, center_x_ratio)
}

@[keep_args_alive]
fn C.igSetScrollFromPosY_WindowPtr(window &Window, local_y f32, center_y_ratio f32)

@[inline]
pub fn set_scroll_from_pos_y_window_ptr(window &Window, local_y f32, center_y_ratio f32) {
	C.igSetScrollFromPosY_WindowPtr(window, local_y, center_y_ratio)
}

@[keep_args_alive]
fn C.igScrollToItem(flags ScrollFlags)

@[inline]
pub fn scroll_to_item(flags ScrollFlags) {
	C.igScrollToItem(flags)
}

@[keep_args_alive]
fn C.igScrollToRect(window &Window, rect ImRect_c, flags ScrollFlags)

@[inline]
pub fn scroll_to_rect(window &Window, rect ImRect_c, flags ScrollFlags) {
	C.igScrollToRect(window, rect, flags)
}

@[keep_args_alive]
fn C.igScrollToRectEx(window &Window, rect ImRect_c, flags ScrollFlags) ImVec2_c

@[inline]
pub fn scroll_to_rect_ex(window &Window, rect ImRect_c, flags ScrollFlags) ImVec2_c {
	return C.igScrollToRectEx(window, rect, flags)
}

@[keep_args_alive]
fn C.igScrollToBringRectIntoView(window &Window, rect ImRect_c)

@[inline]
pub fn scroll_to_bring_rect_into_view(window &Window, rect ImRect_c) {
	C.igScrollToBringRectIntoView(window, rect)
}

@[keep_args_alive]
fn C.igGetItemStatusFlags() ItemStatusFlags

@[inline]
pub fn get_item_status_flags() ItemStatusFlags {
	return C.igGetItemStatusFlags()
}

@[keep_args_alive]
fn C.igGetActiveID() ID

@[inline]
pub fn get_active_id() ID {
	return C.igGetActiveID()
}

@[keep_args_alive]
fn C.igGetFocusID() ID

@[inline]
pub fn get_focus_id() ID {
	return C.igGetFocusID()
}

@[keep_args_alive]
fn C.igSetActiveID(id ID, window &Window)

@[inline]
pub fn set_active_id(id ID, window &Window) {
	C.igSetActiveID(id, window)
}

@[keep_args_alive]
fn C.igSetFocusID(id ID, window &Window)

@[inline]
pub fn set_focus_id(id ID, window &Window) {
	C.igSetFocusID(id, window)
}

@[keep_args_alive]
fn C.igClearActiveID()

@[inline]
pub fn clear_active_id() {
	C.igClearActiveID()
}

@[keep_args_alive]
fn C.igGetHoveredID() ID

@[inline]
pub fn get_hovered_id() ID {
	return C.igGetHoveredID()
}

@[keep_args_alive]
fn C.igSetHoveredID(id ID)

@[inline]
pub fn set_hovered_id(id ID) {
	C.igSetHoveredID(id)
}

@[keep_args_alive]
fn C.igKeepAliveID(id ID)

@[inline]
pub fn keep_alive_id(id ID) {
	C.igKeepAliveID(id)
}

@[keep_args_alive]
fn C.igMarkItemEdited(id ID)

@[inline]
pub fn mark_item_edited(id ID) {
	C.igMarkItemEdited(id)
}

@[keep_args_alive]
fn C.igPushOverrideID(id ID)

@[inline]
pub fn push_override_id(id ID) {
	C.igPushOverrideID(id)
}

@[keep_args_alive]
fn C.igGetIDWithSeed_Str(str_id_begin &char, str_id_end &char, seed ID) ID

@[inline]
pub fn get_idw_ith_seed_str(str_id_begin &char, str_id_end &char, seed ID) ID {
	return C.igGetIDWithSeed_Str(str_id_begin, str_id_end, seed)
}

@[keep_args_alive]
fn C.igGetIDWithSeed_Int(n i32, seed ID) ID

@[inline]
pub fn get_idw_ith_seed_int(n i32, seed ID) ID {
	return C.igGetIDWithSeed_Int(n, seed)
}

@[keep_args_alive]
fn C.igItemSize_Vec2(size ImVec2_c, text_baseline_y f32)

@[inline]
pub fn item_size_vec2(size ImVec2_c, text_baseline_y f32) {
	C.igItemSize_Vec2(size, text_baseline_y)
}

@[keep_args_alive]
fn C.igItemSize_Rect(bb ImRect_c, text_baseline_y f32)

@[inline]
pub fn item_size_rect(bb ImRect_c, text_baseline_y f32) {
	C.igItemSize_Rect(bb, text_baseline_y)
}

@[keep_args_alive]
fn C.igItemAdd(bb ImRect_c, id ID, nav_bb &ImRect, extra_flags ItemFlags) bool

@[inline]
pub fn item_add(bb ImRect_c, id ID, nav_bb &ImRect, extra_flags ItemFlags) bool {
	return C.igItemAdd(bb, id, nav_bb, extra_flags)
}

@[keep_args_alive]
fn C.igItemHoverable(bb ImRect_c, id ID, item_flags ItemFlags) bool

@[inline]
pub fn item_hoverable(bb ImRect_c, id ID, item_flags ItemFlags) bool {
	return C.igItemHoverable(bb, id, item_flags)
}

@[keep_args_alive]
fn C.igIsWindowContentHoverable(window &Window, flags HoveredFlags) bool

@[inline]
pub fn is_window_content_hoverable(window &Window, flags HoveredFlags) bool {
	return C.igIsWindowContentHoverable(window, flags)
}

@[keep_args_alive]
fn C.igIsClippedEx(bb ImRect_c, id ID) bool

@[inline]
pub fn is_clipped_ex(bb ImRect_c, id ID) bool {
	return C.igIsClippedEx(bb, id)
}

@[keep_args_alive]
fn C.igSetLastItemData(item_id ID, item_flags ItemFlags, status_flags ItemStatusFlags, item_rect ImRect_c)

@[inline]
pub fn set_last_item_data(item_id ID, item_flags ItemFlags, status_flags ItemStatusFlags, item_rect ImRect_c) {
	C.igSetLastItemData(item_id, item_flags, status_flags, item_rect)
}

@[keep_args_alive]
fn C.igCalcItemSize(size ImVec2_c, default_w f32, default_h f32) ImVec2_c

@[inline]
pub fn calc_item_size(size ImVec2_c, default_w f32, default_h f32) ImVec2_c {
	return C.igCalcItemSize(size, default_w, default_h)
}

@[keep_args_alive]
fn C.igCalcWrapWidthForPos(pos ImVec2_c, wrap_pos_x f32) f32

@[inline]
pub fn calc_wrap_width_for_pos(pos ImVec2_c, wrap_pos_x f32) f32 {
	return C.igCalcWrapWidthForPos(pos, wrap_pos_x)
}

@[keep_args_alive]
fn C.igPushMultiItemsWidths(components i32, width_full f32)

@[inline]
pub fn push_multi_items_widths(components i32, width_full f32) {
	C.igPushMultiItemsWidths(components, width_full)
}

@[keep_args_alive]
fn C.igShrinkWidths(items &ShrinkWidthItem, count i32, width_excess f32, width_min f32)

@[inline]
pub fn shrink_widths(items &ShrinkWidthItem, count i32, width_excess f32, width_min f32) {
	C.igShrinkWidths(items, count, width_excess, width_min)
}

@[keep_args_alive]
fn C.igCalcClipRectVisibleItemsY(clip_rect ImRect_c, pos ImVec2_c, items_height f32, out_visible_start &i32, out_visible_end &i32)

@[inline]
pub fn calc_clip_rect_visible_items_y(clip_rect ImRect_c, pos ImVec2_c, items_height f32, out_visible_start &i32, out_visible_end &i32) {
	C.igCalcClipRectVisibleItemsY(clip_rect, pos, items_height, out_visible_start, out_visible_end)
}

@[keep_args_alive]
fn C.igGetStyleVarInfo(idx StyleVar) &StyleVarInfo

@[inline]
pub fn get_style_var_info(idx StyleVar) &StyleVarInfo {
	return C.igGetStyleVarInfo(idx)
}

@[keep_args_alive]
fn C.igBeginDisabledOverrideReenable()

@[inline]
pub fn begin_disabled_override_reenable() {
	C.igBeginDisabledOverrideReenable()
}

@[keep_args_alive]
fn C.igEndDisabledOverrideReenable()

@[inline]
pub fn end_disabled_override_reenable() {
	C.igEndDisabledOverrideReenable()
}

@[keep_args_alive]
fn C.igLogBegin(flags LogFlags, auto_open_depth i32)

@[inline]
pub fn log_begin(flags LogFlags, auto_open_depth i32) {
	C.igLogBegin(flags, auto_open_depth)
}

@[keep_args_alive]
fn C.igLogToBuffer(auto_open_depth i32)

@[inline]
pub fn log_to_buffer(auto_open_depth i32) {
	C.igLogToBuffer(auto_open_depth)
}

@[keep_args_alive]
fn C.igLogRenderedText(ref_pos &ImVec2_c, const_text &char, const_text_end &char)

@[inline]
pub fn log_rendered_text(ref_pos &ImVec2_c, const_text &char, const_text_end &char) {
	C.igLogRenderedText(ref_pos, const_text, const_text_end)
}

@[keep_args_alive]
fn C.igLogSetNextTextDecoration(prefix &char, suffix &char)

@[inline]
pub fn log_set_next_text_decoration(prefix &char, suffix &char) {
	C.igLogSetNextTextDecoration(prefix, suffix)
}

@[keep_args_alive]
fn C.igBeginChildEx(const_name &char, id ID, size_arg ImVec2_c, child_flags ChildFlags, window_flags WindowFlags) bool

@[inline]
pub fn begin_child_ex(const_name &char, id ID, size_arg ImVec2_c, child_flags ChildFlags, window_flags WindowFlags) bool {
	return C.igBeginChildEx(const_name, id, size_arg, child_flags, window_flags)
}

@[keep_args_alive]
fn C.igBeginPopupEx(id ID, extra_window_flags WindowFlags) bool

@[inline]
pub fn begin_popup_ex(id ID, extra_window_flags WindowFlags) bool {
	return C.igBeginPopupEx(id, extra_window_flags)
}

@[keep_args_alive]
fn C.igBeginPopupMenuEx(id ID, const_label &char, extra_window_flags WindowFlags) bool

@[inline]
pub fn begin_popup_menu_ex(id ID, const_label &char, extra_window_flags WindowFlags) bool {
	return C.igBeginPopupMenuEx(id, const_label, extra_window_flags)
}

@[keep_args_alive]
fn C.igOpenPopupEx(id ID, popup_flags PopupFlags)

@[inline]
pub fn open_popup_ex(id ID, popup_flags PopupFlags) {
	C.igOpenPopupEx(id, popup_flags)
}

@[keep_args_alive]
fn C.igClosePopupToLevel(remaining i32, restore_focus_to_window_under_popup bool)

@[inline]
pub fn close_popup_to_level(remaining i32, restore_focus_to_window_under_popup bool) {
	C.igClosePopupToLevel(remaining, restore_focus_to_window_under_popup)
}

@[keep_args_alive]
fn C.igClosePopupsOverWindow(ref_window &Window, restore_focus_to_window_under_popup bool)

@[inline]
pub fn close_popups_over_window(ref_window &Window, restore_focus_to_window_under_popup bool) {
	C.igClosePopupsOverWindow(ref_window, restore_focus_to_window_under_popup)
}

@[keep_args_alive]
fn C.igClosePopupsExceptModals()

@[inline]
pub fn close_popups_except_modals() {
	C.igClosePopupsExceptModals()
}

@[keep_args_alive]
fn C.igIsPopupOpen_ID(id ID, popup_flags PopupFlags) bool

@[inline]
pub fn is_popup_open_id(id ID, popup_flags PopupFlags) bool {
	return C.igIsPopupOpen_ID(id, popup_flags)
}

@[keep_args_alive]
fn C.igGetPopupAllowedExtentRect(window &Window) ImRect_c

@[inline]
pub fn get_popup_allowed_extent_rect(window &Window) ImRect_c {
	return C.igGetPopupAllowedExtentRect(window)
}

@[keep_args_alive]
fn C.igGetTopMostPopupModal() &Window

@[inline]
pub fn get_top_most_popup_modal() &Window {
	return C.igGetTopMostPopupModal()
}

@[keep_args_alive]
fn C.igGetTopMostAndVisiblePopupModal() &Window

@[inline]
pub fn get_top_most_and_visible_popup_modal() &Window {
	return C.igGetTopMostAndVisiblePopupModal()
}

@[keep_args_alive]
fn C.igFindBlockingModal(window &Window) &Window

@[inline]
pub fn find_blocking_modal(window &Window) &Window {
	return C.igFindBlockingModal(window)
}

@[keep_args_alive]
fn C.igFindBestWindowPosForPopup(window &Window) ImVec2_c

@[inline]
pub fn find_best_window_pos_for_popup(window &Window) ImVec2_c {
	return C.igFindBestWindowPosForPopup(window)
}

@[keep_args_alive]
fn C.igFindBestWindowPosForPopupEx(ref_pos ImVec2_c, size ImVec2_c, last_dir &Dir, r_outer ImRect_c, r_avoid ImRect_c, policy PopupPositionPolicy) ImVec2_c

@[inline]
pub fn find_best_window_pos_for_popup_ex(ref_pos ImVec2_c, size ImVec2_c, last_dir &Dir, r_outer ImRect_c, r_avoid ImRect_c, policy PopupPositionPolicy) ImVec2_c {
	return C.igFindBestWindowPosForPopupEx(ref_pos, size, last_dir, r_outer, r_avoid, policy)
}

@[keep_args_alive]
fn C.igGetMouseButtonFromPopupFlags(flags PopupFlags) MouseButton

@[inline]
pub fn get_mouse_button_from_popup_flags(flags PopupFlags) MouseButton {
	return C.igGetMouseButtonFromPopupFlags(flags)
}

@[keep_args_alive]
fn C.igIsPopupOpenRequestForItem(flags PopupFlags, id ID) bool

@[inline]
pub fn is_popup_open_request_for_item(flags PopupFlags, id ID) bool {
	return C.igIsPopupOpenRequestForItem(flags, id)
}

@[keep_args_alive]
fn C.igIsPopupOpenRequestForWindow(flags PopupFlags) bool

@[inline]
pub fn is_popup_open_request_for_window(flags PopupFlags) bool {
	return C.igIsPopupOpenRequestForWindow(flags)
}

@[keep_args_alive]
fn C.igBeginTooltipEx(tooltip_flags TooltipFlags, extra_window_flags WindowFlags) bool

@[inline]
pub fn begin_tooltip_ex(tooltip_flags TooltipFlags, extra_window_flags WindowFlags) bool {
	return C.igBeginTooltipEx(tooltip_flags, extra_window_flags)
}

@[keep_args_alive]
fn C.igBeginTooltipHidden() bool

@[inline]
pub fn begin_tooltip_hidden() bool {
	return C.igBeginTooltipHidden()
}

@[keep_args_alive]
fn C.igBeginViewportSideBar(const_name &char, viewport &Viewport, dir Dir, size f32, window_flags WindowFlags) bool

@[inline]
pub fn begin_viewport_side_bar(const_name &char, viewport &Viewport, dir Dir, size f32, window_flags WindowFlags) bool {
	return C.igBeginViewportSideBar(const_name, viewport, dir, size, window_flags)
}

@[keep_args_alive]
fn C.igBeginMenuEx(const_label &char, icon &char, enabled bool) bool

@[inline]
pub fn begin_menu_ex(const_label &char, icon &char, enabled bool) bool {
	return C.igBeginMenuEx(const_label, icon, enabled)
}

@[keep_args_alive]
fn C.igMenuItemEx(const_label &char, icon &char, const_shortcut &char, selected bool, enabled bool) bool

@[inline]
pub fn menu_item_ex(const_label &char, icon &char, const_shortcut &char, selected bool, enabled bool) bool {
	return C.igMenuItemEx(const_label, icon, const_shortcut, selected, enabled)
}

@[keep_args_alive]
fn C.igBeginComboPopup(popup_id ID, bb ImRect_c, flags ComboFlags) bool

@[inline]
pub fn begin_combo_popup(popup_id ID, bb ImRect_c, flags ComboFlags) bool {
	return C.igBeginComboPopup(popup_id, bb, flags)
}

@[keep_args_alive]
fn C.igBeginComboPreview() bool

@[inline]
pub fn begin_combo_preview() bool {
	return C.igBeginComboPreview()
}

@[keep_args_alive]
fn C.igEndComboPreview()

@[inline]
pub fn end_combo_preview() {
	C.igEndComboPreview()
}

@[keep_args_alive]
fn C.igNavInitWindow(window &Window, force_reinit bool)

@[inline]
pub fn nav_init_window(window &Window, force_reinit bool) {
	C.igNavInitWindow(window, force_reinit)
}

@[keep_args_alive]
fn C.igNavInitRequestApplyResult()

@[inline]
pub fn nav_init_request_apply_result() {
	C.igNavInitRequestApplyResult()
}

@[keep_args_alive]
fn C.igNavMoveRequestButNoResultYet() bool

@[inline]
pub fn nav_move_request_but_no_result_yet() bool {
	return C.igNavMoveRequestButNoResultYet()
}

@[keep_args_alive]
fn C.igNavMoveRequestSubmit(move_dir Dir, clip_dir Dir, move_flags NavMoveFlags, scroll_flags ScrollFlags)

@[inline]
pub fn nav_move_request_submit(move_dir Dir, clip_dir Dir, move_flags NavMoveFlags, scroll_flags ScrollFlags) {
	C.igNavMoveRequestSubmit(move_dir, clip_dir, move_flags, scroll_flags)
}

@[keep_args_alive]
fn C.igNavMoveRequestForward(move_dir Dir, clip_dir Dir, move_flags NavMoveFlags, scroll_flags ScrollFlags)

@[inline]
pub fn nav_move_request_forward(move_dir Dir, clip_dir Dir, move_flags NavMoveFlags, scroll_flags ScrollFlags) {
	C.igNavMoveRequestForward(move_dir, clip_dir, move_flags, scroll_flags)
}

@[keep_args_alive]
fn C.igNavMoveRequestResolveWithLastItem(result &NavItemData)

@[inline]
pub fn nav_move_request_resolve_with_last_item(result &NavItemData) {
	C.igNavMoveRequestResolveWithLastItem(result)
}

@[keep_args_alive]
fn C.igNavMoveRequestResolveWithPastTreeNode(result &NavItemData, tree_node_data &TreeNodeStackData)

@[inline]
pub fn nav_move_request_resolve_with_past_tree_node(result &NavItemData, tree_node_data &TreeNodeStackData) {
	C.igNavMoveRequestResolveWithPastTreeNode(result, tree_node_data)
}

@[keep_args_alive]
fn C.igNavMoveRequestCancel()

@[inline]
pub fn nav_move_request_cancel() {
	C.igNavMoveRequestCancel()
}

@[keep_args_alive]
fn C.igNavMoveRequestApplyResult()

@[inline]
pub fn nav_move_request_apply_result() {
	C.igNavMoveRequestApplyResult()
}

@[keep_args_alive]
fn C.igNavMoveRequestTryWrapping(window &Window, move_flags NavMoveFlags)

@[inline]
pub fn nav_move_request_try_wrapping(window &Window, move_flags NavMoveFlags) {
	C.igNavMoveRequestTryWrapping(window, move_flags)
}

@[keep_args_alive]
fn C.igNavHighlightActivated(id ID)

@[inline]
pub fn nav_highlight_activated(id ID) {
	C.igNavHighlightActivated(id)
}

@[keep_args_alive]
fn C.igNavClearPreferredPosForAxis(axis Axis)

@[inline]
pub fn nav_clear_preferred_pos_for_axis(axis Axis) {
	C.igNavClearPreferredPosForAxis(axis)
}

@[keep_args_alive]
fn C.igSetNavCursorVisibleAfterMove()

@[inline]
pub fn set_nav_cursor_visible_after_move() {
	C.igSetNavCursorVisibleAfterMove()
}

@[keep_args_alive]
fn C.igNavUpdateCurrentWindowIsScrollPushableX()

@[inline]
pub fn nav_update_current_window_is_scroll_pushable_x() {
	C.igNavUpdateCurrentWindowIsScrollPushableX()
}

@[keep_args_alive]
fn C.igSetNavWindow(window &Window)

@[inline]
pub fn set_nav_window(window &Window) {
	C.igSetNavWindow(window)
}

@[keep_args_alive]
fn C.igSetNavID(id ID, nav_layer NavLayer, focus_scope_id ID, rect_rel ImRect_c)

@[inline]
pub fn set_nav_id(id ID, nav_layer NavLayer, focus_scope_id ID, rect_rel ImRect_c) {
	C.igSetNavID(id, nav_layer, focus_scope_id, rect_rel)
}

@[keep_args_alive]
fn C.igSetNavFocusScope(focus_scope_id ID)

@[inline]
pub fn set_nav_focus_scope(focus_scope_id ID) {
	C.igSetNavFocusScope(focus_scope_id)
}

@[keep_args_alive]
fn C.igFocusItem()

@[inline]
pub fn focus_item() {
	C.igFocusItem()
}

@[keep_args_alive]
fn C.igActivateItemByID(id ID)

@[inline]
pub fn activate_item_by_id(id ID) {
	C.igActivateItemByID(id)
}

@[keep_args_alive]
fn C.igIsNamedKey(key Key) bool

@[inline]
pub fn is_named_key(key Key) bool {
	return C.igIsNamedKey(key)
}

@[keep_args_alive]
fn C.igIsNamedKeyOrMod(key Key) bool

@[inline]
pub fn is_named_key_or_mod(key Key) bool {
	return C.igIsNamedKeyOrMod(key)
}

@[keep_args_alive]
fn C.igIsLegacyKey(key Key) bool

@[inline]
pub fn is_legacy_key(key Key) bool {
	return C.igIsLegacyKey(key)
}

@[keep_args_alive]
fn C.igIsKeyboardKey(key Key) bool

@[inline]
pub fn is_keyboard_key(key Key) bool {
	return C.igIsKeyboardKey(key)
}

@[keep_args_alive]
fn C.igIsGamepadKey(key Key) bool

@[inline]
pub fn is_gamepad_key(key Key) bool {
	return C.igIsGamepadKey(key)
}

@[keep_args_alive]
fn C.igIsMouseKey(key Key) bool

@[inline]
pub fn is_mouse_key(key Key) bool {
	return C.igIsMouseKey(key)
}

@[keep_args_alive]
fn C.igIsAliasKey(key Key) bool

@[inline]
pub fn is_alias_key(key Key) bool {
	return C.igIsAliasKey(key)
}

@[keep_args_alive]
fn C.igIsLRModKey(key Key) bool

@[inline]
pub fn is_lrm_od_key(key Key) bool {
	return C.igIsLRModKey(key)
}

@[keep_args_alive]
fn C.igFixupKeyChord(key_chord KeyChord) KeyChord

@[inline]
pub fn fixup_key_chord(key_chord KeyChord) KeyChord {
	return C.igFixupKeyChord(key_chord)
}

@[keep_args_alive]
fn C.igConvertSingleModFlagToKey(key Key) Key

@[inline]
pub fn convert_single_mod_flag_to_key(key Key) Key {
	return C.igConvertSingleModFlagToKey(key)
}

@[keep_args_alive]
fn C.igGetKeyData_ContextPtr(ctx &Context, key Key) &KeyData

@[inline]
pub fn get_key_data_context_ptr(ctx &Context, key Key) &KeyData {
	return C.igGetKeyData_ContextPtr(ctx, key)
}

@[keep_args_alive]
fn C.igGetKeyData_Key(key Key) &KeyData

@[inline]
pub fn get_key_data_key(key Key) &KeyData {
	return C.igGetKeyData_Key(key)
}

@[keep_args_alive]
fn C.igGetKeyChordName(key_chord KeyChord) &char

@[inline]
pub fn get_key_chord_name(key_chord KeyChord) &char {
	return C.igGetKeyChordName(key_chord)
}

@[keep_args_alive]
fn C.igMouseButtonToKey(button MouseButton) Key

@[inline]
pub fn mouse_button_to_key(button MouseButton) Key {
	return C.igMouseButtonToKey(button)
}

@[keep_args_alive]
fn C.igIsMouseDragPastThreshold(button MouseButton, lock_threshold f32) bool

@[inline]
pub fn is_mouse_drag_past_threshold(button MouseButton, lock_threshold f32) bool {
	return C.igIsMouseDragPastThreshold(button, lock_threshold)
}

@[keep_args_alive]
fn C.igGetKeyMagnitude2d(key_left Key, key_right Key, key_up Key, key_down Key) ImVec2_c

@[inline]
pub fn get_key_magnitude2d(key_left Key, key_right Key, key_up Key, key_down Key) ImVec2_c {
	return C.igGetKeyMagnitude2d(key_left, key_right, key_up, key_down)
}

@[keep_args_alive]
fn C.igGetNavTweakPressedAmount(axis Axis) f32

@[inline]
pub fn get_nav_tweak_pressed_amount(axis Axis) f32 {
	return C.igGetNavTweakPressedAmount(axis)
}

@[keep_args_alive]
fn C.igCalcTypematicRepeatAmount(t0 f32, t1 f32, repeat_delay f32, repeat_rate f32) i32

@[inline]
pub fn calc_typematic_repeat_amount(t0 f32, t1 f32, repeat_delay f32, repeat_rate f32) i32 {
	return C.igCalcTypematicRepeatAmount(t0, t1, repeat_delay, repeat_rate)
}

@[keep_args_alive]
fn C.igGetTypematicRepeatRate(flags InputFlags, repeat_delay &f32, repeat_rate &f32)

@[inline]
pub fn get_typematic_repeat_rate(flags InputFlags, repeat_delay &f32, repeat_rate &f32) {
	C.igGetTypematicRepeatRate(flags, repeat_delay, repeat_rate)
}

@[keep_args_alive]
fn C.igTeleportMousePos(pos ImVec2_c)

@[inline]
pub fn teleport_mouse_pos(pos ImVec2_c) {
	C.igTeleportMousePos(pos)
}

@[keep_args_alive]
fn C.igSetActiveIdUsingAllKeyboardKeys()

@[inline]
pub fn set_active_id_using_all_keyboard_keys() {
	C.igSetActiveIdUsingAllKeyboardKeys()
}

@[keep_args_alive]
fn C.igIsActiveIdUsingNavDir(dir Dir) bool

@[inline]
pub fn is_active_id_using_nav_dir(dir Dir) bool {
	return C.igIsActiveIdUsingNavDir(dir)
}

@[keep_args_alive]
fn C.igGetKeyOwner(key Key) ID

@[inline]
pub fn get_key_owner(key Key) ID {
	return C.igGetKeyOwner(key)
}

@[keep_args_alive]
fn C.igSetKeyOwner(key Key, owner_id ID, flags InputFlags)

@[inline]
pub fn set_key_owner(key Key, owner_id ID, flags InputFlags) {
	C.igSetKeyOwner(key, owner_id, flags)
}

@[keep_args_alive]
fn C.igSetKeyOwnersForKeyChord(key KeyChord, owner_id ID, flags InputFlags)

@[inline]
pub fn set_key_owners_for_key_chord(key KeyChord, owner_id ID, flags InputFlags) {
	C.igSetKeyOwnersForKeyChord(key, owner_id, flags)
}

@[keep_args_alive]
fn C.igSetItemKeyOwner_InputFlags(key Key, flags InputFlags)

@[inline]
pub fn set_item_key_owner_input_flags(key Key, flags InputFlags) {
	C.igSetItemKeyOwner_InputFlags(key, flags)
}

@[keep_args_alive]
fn C.igTestKeyOwner(key Key, owner_id ID) bool

@[inline]
pub fn test_key_owner(key Key, owner_id ID) bool {
	return C.igTestKeyOwner(key, owner_id)
}

@[keep_args_alive]
fn C.igGetKeyOwnerData(ctx &Context, key Key) &KeyOwnerData

@[inline]
pub fn get_key_owner_data(ctx &Context, key Key) &KeyOwnerData {
	return C.igGetKeyOwnerData(ctx, key)
}

@[keep_args_alive]
fn C.igIsKeyDown_ID(key Key, owner_id ID) bool

@[inline]
pub fn is_key_down_id(key Key, owner_id ID) bool {
	return C.igIsKeyDown_ID(key, owner_id)
}

@[keep_args_alive]
fn C.igIsKeyPressed_InputFlags(key Key, flags InputFlags, owner_id ID) bool

@[inline]
pub fn is_key_pressed_input_flags(key Key, flags InputFlags, owner_id ID) bool {
	return C.igIsKeyPressed_InputFlags(key, flags, owner_id)
}

@[keep_args_alive]
fn C.igIsKeyReleased_ID(key Key, owner_id ID) bool

@[inline]
pub fn is_key_released_id(key Key, owner_id ID) bool {
	return C.igIsKeyReleased_ID(key, owner_id)
}

@[keep_args_alive]
fn C.igIsKeyChordPressed_InputFlags(key_chord KeyChord, flags InputFlags, owner_id ID) bool

@[inline]
pub fn is_key_chord_pressed_input_flags(key_chord KeyChord, flags InputFlags, owner_id ID) bool {
	return C.igIsKeyChordPressed_InputFlags(key_chord, flags, owner_id)
}

@[keep_args_alive]
fn C.igIsMouseDown_ID(button MouseButton, owner_id ID) bool

@[inline]
pub fn is_mouse_down_id(button MouseButton, owner_id ID) bool {
	return C.igIsMouseDown_ID(button, owner_id)
}

@[keep_args_alive]
fn C.igIsMouseClicked_InputFlags(button MouseButton, flags InputFlags, owner_id ID) bool

@[inline]
pub fn is_mouse_clicked_input_flags(button MouseButton, flags InputFlags, owner_id ID) bool {
	return C.igIsMouseClicked_InputFlags(button, flags, owner_id)
}

@[keep_args_alive]
fn C.igIsMouseReleased_ID(button MouseButton, owner_id ID) bool

@[inline]
pub fn is_mouse_released_id(button MouseButton, owner_id ID) bool {
	return C.igIsMouseReleased_ID(button, owner_id)
}

@[keep_args_alive]
fn C.igIsMouseDoubleClicked_ID(button MouseButton, owner_id ID) bool

@[inline]
pub fn is_mouse_double_clicked_id(button MouseButton, owner_id ID) bool {
	return C.igIsMouseDoubleClicked_ID(button, owner_id)
}

@[keep_args_alive]
fn C.igShortcut_ID(key_chord KeyChord, flags InputFlags, owner_id ID) bool

@[inline]
pub fn shortcut_id(key_chord KeyChord, flags InputFlags, owner_id ID) bool {
	return C.igShortcut_ID(key_chord, flags, owner_id)
}

@[keep_args_alive]
fn C.igSetShortcutRouting(key_chord KeyChord, flags InputFlags, owner_id ID) bool

@[inline]
pub fn set_shortcut_routing(key_chord KeyChord, flags InputFlags, owner_id ID) bool {
	return C.igSetShortcutRouting(key_chord, flags, owner_id)
}

@[keep_args_alive]
fn C.igTestShortcutRouting(key_chord KeyChord, owner_id ID) bool

@[inline]
pub fn test_shortcut_routing(key_chord KeyChord, owner_id ID) bool {
	return C.igTestShortcutRouting(key_chord, owner_id)
}

@[keep_args_alive]
fn C.igGetShortcutRoutingData(key_chord KeyChord) &KeyRoutingData

@[inline]
pub fn get_shortcut_routing_data(key_chord KeyChord) &KeyRoutingData {
	return C.igGetShortcutRoutingData(key_chord)
}

@[keep_args_alive]
fn C.igDockContextInitialize(ctx &Context)

@[inline]
pub fn dock_context_initialize(ctx &Context) {
	C.igDockContextInitialize(ctx)
}

@[keep_args_alive]
fn C.igDockContextShutdown(ctx &Context)

@[inline]
pub fn dock_context_shutdown(ctx &Context) {
	C.igDockContextShutdown(ctx)
}

@[keep_args_alive]
fn C.igDockContextClearNodes(ctx &Context, root_id ID, clear_settings_refs bool)

@[inline]
pub fn dock_context_clear_nodes(ctx &Context, root_id ID, clear_settings_refs bool) {
	C.igDockContextClearNodes(ctx, root_id, clear_settings_refs)
}

@[keep_args_alive]
fn C.igDockContextRebuildNodes(ctx &Context)

@[inline]
pub fn dock_context_rebuild_nodes(ctx &Context) {
	C.igDockContextRebuildNodes(ctx)
}

@[keep_args_alive]
fn C.igDockContextNewFrameUpdateUndocking(ctx &Context)

@[inline]
pub fn dock_context_new_frame_update_undocking(ctx &Context) {
	C.igDockContextNewFrameUpdateUndocking(ctx)
}

@[keep_args_alive]
fn C.igDockContextNewFrameUpdateDocking(ctx &Context)

@[inline]
pub fn dock_context_new_frame_update_docking(ctx &Context) {
	C.igDockContextNewFrameUpdateDocking(ctx)
}

@[keep_args_alive]
fn C.igDockContextEndFrame(ctx &Context)

@[inline]
pub fn dock_context_end_frame(ctx &Context) {
	C.igDockContextEndFrame(ctx)
}

@[keep_args_alive]
fn C.igDockContextGenNodeID(ctx &Context) ID

@[inline]
pub fn dock_context_gen_node_id(ctx &Context) ID {
	return C.igDockContextGenNodeID(ctx)
}

@[keep_args_alive]
fn C.igDockContextQueueDock(ctx &Context, target &Window, target_node &DockNode, payload &Window, split_dir Dir, split_ratio f32, split_outer bool)

@[inline]
pub fn dock_context_queue_dock(ctx &Context, target &Window, target_node &DockNode, payload &Window, split_dir Dir, split_ratio f32, split_outer bool) {
	C.igDockContextQueueDock(ctx, target, target_node, payload, split_dir, split_ratio, split_outer)
}

@[keep_args_alive]
fn C.igDockContextQueueUndockWindow(ctx &Context, window &Window)

@[inline]
pub fn dock_context_queue_undock_window(ctx &Context, window &Window) {
	C.igDockContextQueueUndockWindow(ctx, window)
}

@[keep_args_alive]
fn C.igDockContextQueueUndockNode(ctx &Context, node &DockNode)

@[inline]
pub fn dock_context_queue_undock_node(ctx &Context, node &DockNode) {
	C.igDockContextQueueUndockNode(ctx, node)
}

@[keep_args_alive]
fn C.igDockContextProcessUndockWindow(ctx &Context, window &Window, clear_persistent_docking_ref bool)

@[inline]
pub fn dock_context_process_undock_window(ctx &Context, window &Window, clear_persistent_docking_ref bool) {
	C.igDockContextProcessUndockWindow(ctx, window, clear_persistent_docking_ref)
}

@[keep_args_alive]
fn C.igDockContextProcessUndockNode(ctx &Context, node &DockNode)

@[inline]
pub fn dock_context_process_undock_node(ctx &Context, node &DockNode) {
	C.igDockContextProcessUndockNode(ctx, node)
}

@[keep_args_alive]
fn C.igDockContextCalcDropPosForDocking(target &Window, target_node &DockNode, payload_window &Window, payload_node &DockNode, split_dir Dir, split_outer bool, out_pos &ImVec2_c) bool

@[inline]
pub fn dock_context_calc_drop_pos_for_docking(target &Window, target_node &DockNode, payload_window &Window, payload_node &DockNode, split_dir Dir, split_outer bool, out_pos &ImVec2_c) bool {
	return C.igDockContextCalcDropPosForDocking(target, target_node, payload_window, payload_node,
		split_dir, split_outer, out_pos)
}

@[keep_args_alive]
fn C.igDockContextFindNodeByID(ctx &Context, id ID) &DockNode

@[inline]
pub fn dock_context_find_node_by_id(ctx &Context, id ID) &DockNode {
	return C.igDockContextFindNodeByID(ctx, id)
}

@[keep_args_alive]
fn C.igDockNodeWindowMenuHandler_Default(ctx &Context, node &DockNode, tab_bar &TabBar)

@[inline]
pub fn dock_node_window_menu_handler_default(ctx &Context, node &DockNode, tab_bar &TabBar) {
	C.igDockNodeWindowMenuHandler_Default(ctx, node, tab_bar)
}

@[keep_args_alive]
fn C.igDockNodeBeginAmendTabBar(node &DockNode) bool

@[inline]
pub fn dock_node_begin_amend_tab_bar(node &DockNode) bool {
	return C.igDockNodeBeginAmendTabBar(node)
}

@[keep_args_alive]
fn C.igDockNodeEndAmendTabBar()

@[inline]
pub fn dock_node_end_amend_tab_bar() {
	C.igDockNodeEndAmendTabBar()
}

@[keep_args_alive]
fn C.igDockNodeGetRootNode(node &DockNode) &DockNode

@[inline]
pub fn dock_node_get_root_node(node &DockNode) &DockNode {
	return C.igDockNodeGetRootNode(node)
}

@[keep_args_alive]
fn C.igDockNodeIsInHierarchyOf(node &DockNode, parent &DockNode) bool

@[inline]
pub fn dock_node_is_in_hierarchy_of(node &DockNode, parent &DockNode) bool {
	return C.igDockNodeIsInHierarchyOf(node, parent)
}

@[keep_args_alive]
fn C.igDockNodeGetDepth(node &DockNode) i32

@[inline]
pub fn dock_node_get_depth(node &DockNode) i32 {
	return C.igDockNodeGetDepth(node)
}

@[keep_args_alive]
fn C.igDockNodeGetWindowMenuButtonId(node &DockNode) ID

@[inline]
pub fn dock_node_get_window_menu_button_id(node &DockNode) ID {
	return C.igDockNodeGetWindowMenuButtonId(node)
}

@[keep_args_alive]
fn C.igGetWindowDockNode() &DockNode

@[inline]
pub fn get_window_dock_node() &DockNode {
	return C.igGetWindowDockNode()
}

@[keep_args_alive]
fn C.igGetWindowAlwaysWantOwnTabBar(window &Window) bool

@[inline]
pub fn get_window_always_want_own_tab_bar(window &Window) bool {
	return C.igGetWindowAlwaysWantOwnTabBar(window)
}

@[keep_args_alive]
fn C.igBeginDocked(window &Window, p_open &bool)

@[inline]
pub fn begin_docked(window &Window, p_open &bool) {
	C.igBeginDocked(window, p_open)
}

@[keep_args_alive]
fn C.igBeginDockableDragDropSource(window &Window)

@[inline]
pub fn begin_dockable_drag_drop_source(window &Window) {
	C.igBeginDockableDragDropSource(window)
}

@[keep_args_alive]
fn C.igBeginDockableDragDropTarget(window &Window)

@[inline]
pub fn begin_dockable_drag_drop_target(window &Window) {
	C.igBeginDockableDragDropTarget(window)
}

@[keep_args_alive]
fn C.igSetWindowDock(window &Window, dock_id ID, cond Cond)

@[inline]
pub fn set_window_dock(window &Window, dock_id ID, cond Cond) {
	C.igSetWindowDock(window, dock_id, cond)
}

@[keep_args_alive]
fn C.igDockBuilderDockWindow(window_name &char, node_id ID)

@[inline]
pub fn dock_builder_dock_window(window_name &char, node_id ID) {
	C.igDockBuilderDockWindow(window_name, node_id)
}

@[keep_args_alive]
fn C.igDockBuilderGetNode(node_id ID) &DockNode

@[inline]
pub fn dock_builder_get_node(node_id ID) &DockNode {
	return C.igDockBuilderGetNode(node_id)
}

@[keep_args_alive]
fn C.igDockBuilderGetCentralNode(node_id ID) &DockNode

@[inline]
pub fn dock_builder_get_central_node(node_id ID) &DockNode {
	return C.igDockBuilderGetCentralNode(node_id)
}

@[keep_args_alive]
fn C.igDockBuilderAddNode(node_id ID, flags DockNodeFlags) ID

@[inline]
pub fn dock_builder_add_node(node_id ID, flags DockNodeFlags) ID {
	return C.igDockBuilderAddNode(node_id, flags)
}

@[keep_args_alive]
fn C.igDockBuilderRemoveNode(node_id ID)

@[inline]
pub fn dock_builder_remove_node(node_id ID) {
	C.igDockBuilderRemoveNode(node_id)
}

@[keep_args_alive]
fn C.igDockBuilderRemoveNodeDockedWindows(node_id ID, clear_settings_refs bool)

@[inline]
pub fn dock_builder_remove_node_docked_windows(node_id ID, clear_settings_refs bool) {
	C.igDockBuilderRemoveNodeDockedWindows(node_id, clear_settings_refs)
}

@[keep_args_alive]
fn C.igDockBuilderRemoveNodeChildNodes(node_id ID)

@[inline]
pub fn dock_builder_remove_node_child_nodes(node_id ID) {
	C.igDockBuilderRemoveNodeChildNodes(node_id)
}

@[keep_args_alive]
fn C.igDockBuilderSetNodePos(node_id ID, pos ImVec2_c)

@[inline]
pub fn dock_builder_set_node_pos(node_id ID, pos ImVec2_c) {
	C.igDockBuilderSetNodePos(node_id, pos)
}

@[keep_args_alive]
fn C.igDockBuilderSetNodeSize(node_id ID, size ImVec2_c)

@[inline]
pub fn dock_builder_set_node_size(node_id ID, size ImVec2_c) {
	C.igDockBuilderSetNodeSize(node_id, size)
}

@[keep_args_alive]
fn C.igDockBuilderSplitNode(node_id ID, split_dir Dir, size_ratio_for_node_at_dir f32, out_id_at_dir &ID, out_id_at_opposite_dir &ID) ID

@[inline]
pub fn dock_builder_split_node(node_id ID, split_dir Dir, size_ratio_for_node_at_dir f32, out_id_at_dir &ID, out_id_at_opposite_dir &ID) ID {
	return C.igDockBuilderSplitNode(node_id, split_dir, size_ratio_for_node_at_dir, out_id_at_dir,
		out_id_at_opposite_dir)
}

@[keep_args_alive]
fn C.igDockBuilderCopyDockSpace(src_dockspace_id ID, dst_dockspace_id ID, in_window_remap_pairs &ImVector_const_charPtr)

@[inline]
pub fn dock_builder_copy_dock_space(src_dockspace_id ID, dst_dockspace_id ID, in_window_remap_pairs &ImVector_const_charPtr) {
	C.igDockBuilderCopyDockSpace(src_dockspace_id, dst_dockspace_id, in_window_remap_pairs)
}

@[keep_args_alive]
fn C.igDockBuilderCopyNode(src_node_id ID, dst_node_id ID, out_node_remap_pairs &ImVector_ID)

@[inline]
pub fn dock_builder_copy_node(src_node_id ID, dst_node_id ID, out_node_remap_pairs &ImVector_ID) {
	C.igDockBuilderCopyNode(src_node_id, dst_node_id, out_node_remap_pairs)
}

@[keep_args_alive]
fn C.igDockBuilderCopyWindowSettings(src_name &char, dst_name &char)

@[inline]
pub fn dock_builder_copy_window_settings(src_name &char, dst_name &char) {
	C.igDockBuilderCopyWindowSettings(src_name, dst_name)
}

@[keep_args_alive]
fn C.igDockBuilderFinish(node_id ID)

@[inline]
pub fn dock_builder_finish(node_id ID) {
	C.igDockBuilderFinish(node_id)
}

@[keep_args_alive]
fn C.igPushFocusScope(id ID)

@[inline]
pub fn push_focus_scope(id ID) {
	C.igPushFocusScope(id)
}

@[keep_args_alive]
fn C.igPopFocusScope()

@[inline]
pub fn pop_focus_scope() {
	C.igPopFocusScope()
}

@[keep_args_alive]
fn C.igGetCurrentFocusScope() ID

@[inline]
pub fn get_current_focus_scope() ID {
	return C.igGetCurrentFocusScope()
}

@[keep_args_alive]
fn C.igIsDragDropActive() bool

@[inline]
pub fn is_drag_drop_active() bool {
	return C.igIsDragDropActive()
}

@[keep_args_alive]
fn C.igBeginDragDropTargetCustom(bb ImRect_c, id ID) bool

@[inline]
pub fn begin_drag_drop_target_custom(bb ImRect_c, id ID) bool {
	return C.igBeginDragDropTargetCustom(bb, id)
}

@[keep_args_alive]
fn C.igBeginDragDropTargetViewport(viewport &Viewport, p_bb &ImRect) bool

@[inline]
pub fn begin_drag_drop_target_viewport(viewport &Viewport, p_bb &ImRect) bool {
	return C.igBeginDragDropTargetViewport(viewport, p_bb)
}

@[keep_args_alive]
fn C.igClearDragDrop()

@[inline]
pub fn clear_drag_drop() {
	C.igClearDragDrop()
}

@[keep_args_alive]
fn C.igIsDragDropPayloadBeingAccepted() bool

@[inline]
pub fn is_drag_drop_payload_being_accepted() bool {
	return C.igIsDragDropPayloadBeingAccepted()
}

@[keep_args_alive]
fn C.igRenderDragDropTargetRectForItem(bb ImRect_c)

@[inline]
pub fn render_drag_drop_target_rect_for_item(bb ImRect_c) {
	C.igRenderDragDropTargetRectForItem(bb)
}

@[keep_args_alive]
fn C.igRenderDragDropTargetRectEx(draw_list &ImDrawList, bb ImRect_c)

@[inline]
pub fn render_drag_drop_target_rect_ex(draw_list &ImDrawList, bb ImRect_c) {
	C.igRenderDragDropTargetRectEx(draw_list, bb)
}

@[keep_args_alive]
fn C.igGetTypingSelectRequest(flags TypingSelectFlags) &TypingSelectRequest

@[inline]
pub fn get_typing_select_request(flags TypingSelectFlags) &TypingSelectRequest {
	return C.igGetTypingSelectRequest(flags)
}

@[keep_args_alive]
fn C.igTypingSelectFindMatch(req &TypingSelectRequest, items_count i32, get_item_name_func fn (voidptr, i32) &char, user_data voidptr, nav_item_idx i32) i32

@[inline]
pub fn typing_select_find_match(req &TypingSelectRequest, items_count i32, get_item_name_func fn (voidptr, i32) &char, user_data voidptr, nav_item_idx i32) i32 {
	return C.igTypingSelectFindMatch(req, items_count, get_item_name_func, user_data, nav_item_idx)
}

@[keep_args_alive]
fn C.igTypingSelectFindNextSingleCharMatch(req &TypingSelectRequest, items_count i32, get_item_name_func fn (voidptr, i32) &char, user_data voidptr, nav_item_idx i32) i32

@[inline]
pub fn typing_select_find_next_single_char_match(req &TypingSelectRequest, items_count i32, get_item_name_func fn (voidptr, i32) &char, user_data voidptr, nav_item_idx i32) i32 {
	return C.igTypingSelectFindNextSingleCharMatch(req, items_count, get_item_name_func, user_data,
		nav_item_idx)
}

@[keep_args_alive]
fn C.igTypingSelectFindBestLeadingMatch(req &TypingSelectRequest, items_count i32, get_item_name_func fn (voidptr, i32) &char, user_data voidptr) i32

@[inline]
pub fn typing_select_find_best_leading_match(req &TypingSelectRequest, items_count i32, get_item_name_func fn (voidptr, i32) &char, user_data voidptr) i32 {
	return C.igTypingSelectFindBestLeadingMatch(req, items_count, get_item_name_func, user_data)
}

@[keep_args_alive]
fn C.igBeginBoxSelect(scope_rect ImRect_c, window &Window, box_select_id ID, ms_flags MultiSelectFlags) bool

@[inline]
pub fn begin_box_select(scope_rect ImRect_c, window &Window, box_select_id ID, ms_flags MultiSelectFlags) bool {
	return C.igBeginBoxSelect(scope_rect, window, box_select_id, ms_flags)
}

@[keep_args_alive]
fn C.igEndBoxSelect(scope_rect ImRect_c, ms_flags MultiSelectFlags)

@[inline]
pub fn end_box_select(scope_rect ImRect_c, ms_flags MultiSelectFlags) {
	C.igEndBoxSelect(scope_rect, ms_flags)
}

@[keep_args_alive]
fn C.igMultiSelectItemHeader(id ID, p_selected &bool, p_button_flags &ButtonFlags)

@[inline]
pub fn multi_select_item_header(id ID, p_selected &bool, p_button_flags &ButtonFlags) {
	C.igMultiSelectItemHeader(id, p_selected, p_button_flags)
}

@[keep_args_alive]
fn C.igMultiSelectItemFooter(id ID, p_selected &bool, p_pressed &bool)

@[inline]
pub fn multi_select_item_footer(id ID, p_selected &bool, p_pressed &bool) {
	C.igMultiSelectItemFooter(id, p_selected, p_pressed)
}

@[keep_args_alive]
fn C.igMultiSelectAddSetAll(ms &MultiSelectTempData, selected bool)

@[inline]
pub fn multi_select_add_set_all(ms &MultiSelectTempData, selected bool) {
	C.igMultiSelectAddSetAll(ms, selected)
}

@[keep_args_alive]
fn C.igMultiSelectAddSetRange(ms &MultiSelectTempData, selected bool, range_dir i32, first_item SelectionUserData, last_item SelectionUserData)

@[inline]
pub fn multi_select_add_set_range(ms &MultiSelectTempData, selected bool, range_dir i32, first_item SelectionUserData, last_item SelectionUserData) {
	C.igMultiSelectAddSetRange(ms, selected, range_dir, first_item, last_item)
}

@[keep_args_alive]
fn C.igGetBoxSelectState(id ID) &BoxSelectState

@[inline]
pub fn get_box_select_state(id ID) &BoxSelectState {
	return C.igGetBoxSelectState(id)
}

@[keep_args_alive]
fn C.igGetMultiSelectState(id ID) &MultiSelectState

@[inline]
pub fn get_multi_select_state(id ID) &MultiSelectState {
	return C.igGetMultiSelectState(id)
}

@[keep_args_alive]
fn C.igSetWindowClipRectBeforeSetChannel(window &Window, clip_rect ImRect_c)

@[inline]
pub fn set_window_clip_rect_before_set_channel(window &Window, clip_rect ImRect_c) {
	C.igSetWindowClipRectBeforeSetChannel(window, clip_rect)
}

@[keep_args_alive]
fn C.igBeginColumns(const_str_id &char, count i32, flags OldColumnFlags)

@[inline]
pub fn begin_columns(const_str_id &char, count i32, flags OldColumnFlags) {
	C.igBeginColumns(const_str_id, count, flags)
}

@[keep_args_alive]
fn C.igEndColumns()

@[inline]
pub fn end_columns() {
	C.igEndColumns()
}

@[keep_args_alive]
fn C.igPushColumnClipRect(column_index i32)

@[inline]
pub fn push_column_clip_rect(column_index i32) {
	C.igPushColumnClipRect(column_index)
}

@[keep_args_alive]
fn C.igPushColumnsBackground()

@[inline]
pub fn push_columns_background() {
	C.igPushColumnsBackground()
}

@[keep_args_alive]
fn C.igPopColumnsBackground()

@[inline]
pub fn pop_columns_background() {
	C.igPopColumnsBackground()
}

@[keep_args_alive]
fn C.igGetColumnsID(const_str_id &char, count i32) ID

@[inline]
pub fn get_columns_id(const_str_id &char, count i32) ID {
	return C.igGetColumnsID(const_str_id, count)
}

@[keep_args_alive]
fn C.igFindOrCreateColumns(window &Window, id ID) &OldColumns

@[inline]
pub fn find_or_create_columns(window &Window, id ID) &OldColumns {
	return C.igFindOrCreateColumns(window, id)
}

@[keep_args_alive]
fn C.igGetColumnOffsetFromNorm(columns &OldColumns, offset_norm f32) f32

@[inline]
pub fn get_column_offset_from_norm(columns &OldColumns, offset_norm f32) f32 {
	return C.igGetColumnOffsetFromNorm(columns, offset_norm)
}

@[keep_args_alive]
fn C.igGetColumnNormFromOffset(columns &OldColumns, offset f32) f32

@[inline]
pub fn get_column_norm_from_offset(columns &OldColumns, offset f32) f32 {
	return C.igGetColumnNormFromOffset(columns, offset)
}

@[keep_args_alive]
fn C.igTableOpenContextMenu(column_n i32)

@[inline]
pub fn table_open_context_menu(column_n i32) {
	C.igTableOpenContextMenu(column_n)
}

@[keep_args_alive]
fn C.igTableSetColumnWidth(column_n i32, width f32)

@[inline]
pub fn table_set_column_width(column_n i32, width f32) {
	C.igTableSetColumnWidth(column_n, width)
}

@[keep_args_alive]
fn C.igTableSetColumnSortDirection(column_n i32, sort_direction SortDirection, append_to_sort_specs bool)

@[inline]
pub fn table_set_column_sort_direction(column_n i32, sort_direction SortDirection, append_to_sort_specs bool) {
	C.igTableSetColumnSortDirection(column_n, sort_direction, append_to_sort_specs)
}

@[keep_args_alive]
fn C.igTableGetHoveredRow() i32

@[inline]
pub fn table_get_hovered_row() i32 {
	return C.igTableGetHoveredRow()
}

@[keep_args_alive]
fn C.igTableGetHeaderRowHeight() f32

@[inline]
pub fn table_get_header_row_height() f32 {
	return C.igTableGetHeaderRowHeight()
}

@[keep_args_alive]
fn C.igTableGetHeaderAngledMaxLabelWidth() f32

@[inline]
pub fn table_get_header_angled_max_label_width() f32 {
	return C.igTableGetHeaderAngledMaxLabelWidth()
}

@[keep_args_alive]
fn C.igTablePushBackgroundChannel()

@[inline]
pub fn table_push_background_channel() {
	C.igTablePushBackgroundChannel()
}

@[keep_args_alive]
fn C.igTablePopBackgroundChannel()

@[inline]
pub fn table_pop_background_channel() {
	C.igTablePopBackgroundChannel()
}

@[keep_args_alive]
fn C.igTablePushColumnChannel(column_n i32)

@[inline]
pub fn table_push_column_channel(column_n i32) {
	C.igTablePushColumnChannel(column_n)
}

@[keep_args_alive]
fn C.igTablePopColumnChannel()

@[inline]
pub fn table_pop_column_channel() {
	C.igTablePopColumnChannel()
}

@[keep_args_alive]
fn C.igTableAngledHeadersRowEx(row_id ID, angle f32, max_label_width f32, data &TableHeaderData, data_count i32)

@[inline]
pub fn table_angled_headers_row_ex(row_id ID, angle f32, max_label_width f32, data &TableHeaderData, data_count i32) {
	C.igTableAngledHeadersRowEx(row_id, angle, max_label_width, data, data_count)
}

@[keep_args_alive]
fn C.igGetCurrentTable() &Table

@[inline]
pub fn get_current_table() &Table {
	return C.igGetCurrentTable()
}

@[keep_args_alive]
fn C.igTableFindByID(id ID) &Table

@[inline]
pub fn table_find_by_id(id ID) &Table {
	return C.igTableFindByID(id)
}

@[keep_args_alive]
fn C.igBeginTableEx(const_name &char, id ID, columns_count i32, flags TableFlags, outer_size ImVec2_c, inner_width f32) bool

@[inline]
pub fn begin_table_ex(const_name &char, id ID, columns_count i32, flags TableFlags, outer_size ImVec2_c, inner_width f32) bool {
	return C.igBeginTableEx(const_name, id, columns_count, flags, outer_size, inner_width)
}

@[keep_args_alive]
fn C.igTableBeginInitMemory(table &Table, columns_count i32)

@[inline]
pub fn table_begin_init_memory(table &Table, columns_count i32) {
	C.igTableBeginInitMemory(table, columns_count)
}

@[keep_args_alive]
fn C.igTableBeginApplyRequests(table &Table)

@[inline]
pub fn table_begin_apply_requests(table &Table) {
	C.igTableBeginApplyRequests(table)
}

@[keep_args_alive]
fn C.igTableSetupDrawChannels(table &Table)

@[inline]
pub fn table_setup_draw_channels(table &Table) {
	C.igTableSetupDrawChannels(table)
}

@[keep_args_alive]
fn C.igTableUpdateLayout(table &Table)

@[inline]
pub fn table_update_layout(table &Table) {
	C.igTableUpdateLayout(table)
}

@[keep_args_alive]
fn C.igTableUpdateBorders(table &Table)

@[inline]
pub fn table_update_borders(table &Table) {
	C.igTableUpdateBorders(table)
}

@[keep_args_alive]
fn C.igTableUpdateColumnsWeightFromWidth(table &Table)

@[inline]
pub fn table_update_columns_weight_from_width(table &Table) {
	C.igTableUpdateColumnsWeightFromWidth(table)
}

@[keep_args_alive]
fn C.igTableDrawBorders(table &Table)

@[inline]
pub fn table_draw_borders(table &Table) {
	C.igTableDrawBorders(table)
}

@[keep_args_alive]
fn C.igTableDrawDefaultContextMenu(table &Table, flags_for_section_to_display TableFlags)

@[inline]
pub fn table_draw_default_context_menu(table &Table, flags_for_section_to_display TableFlags) {
	C.igTableDrawDefaultContextMenu(table, flags_for_section_to_display)
}

@[keep_args_alive]
fn C.igTableBeginContextMenuPopup(table &Table) bool

@[inline]
pub fn table_begin_context_menu_popup(table &Table) bool {
	return C.igTableBeginContextMenuPopup(table)
}

@[keep_args_alive]
fn C.igTableMergeDrawChannels(table &Table)

@[inline]
pub fn table_merge_draw_channels(table &Table) {
	C.igTableMergeDrawChannels(table)
}

@[keep_args_alive]
fn C.igTableGetInstanceData(table &Table, instance_no i32) &TableInstanceData

@[inline]
pub fn table_get_instance_data(table &Table, instance_no i32) &TableInstanceData {
	return C.igTableGetInstanceData(table, instance_no)
}

@[keep_args_alive]
fn C.igTableGetInstanceID(table &Table, instance_no i32) ID

@[inline]
pub fn table_get_instance_id(table &Table, instance_no i32) ID {
	return C.igTableGetInstanceID(table, instance_no)
}

@[keep_args_alive]
fn C.igTableFixDisplayOrder(table &Table)

@[inline]
pub fn table_fix_display_order(table &Table) {
	C.igTableFixDisplayOrder(table)
}

@[keep_args_alive]
fn C.igTableSortSpecsSanitize(table &Table)

@[inline]
pub fn table_sort_specs_sanitize(table &Table) {
	C.igTableSortSpecsSanitize(table)
}

@[keep_args_alive]
fn C.igTableSortSpecsBuild(table &Table)

@[inline]
pub fn table_sort_specs_build(table &Table) {
	C.igTableSortSpecsBuild(table)
}

@[keep_args_alive]
fn C.igTableGetColumnNextSortDirection(column &TableColumn) SortDirection

@[inline]
pub fn table_get_column_next_sort_direction(column &TableColumn) SortDirection {
	return C.igTableGetColumnNextSortDirection(column)
}

@[keep_args_alive]
fn C.igTableFixColumnSortDirection(table &Table, column &TableColumn)

@[inline]
pub fn table_fix_column_sort_direction(table &Table, column &TableColumn) {
	C.igTableFixColumnSortDirection(table, column)
}

@[keep_args_alive]
fn C.igTableGetColumnWidthAuto(table &Table, column &TableColumn) f32

@[inline]
pub fn table_get_column_width_auto(table &Table, column &TableColumn) f32 {
	return C.igTableGetColumnWidthAuto(table, column)
}

@[keep_args_alive]
fn C.igTableBeginRow(table &Table)

@[inline]
pub fn table_begin_row(table &Table) {
	C.igTableBeginRow(table)
}

@[keep_args_alive]
fn C.igTableEndRow(table &Table)

@[inline]
pub fn table_end_row(table &Table) {
	C.igTableEndRow(table)
}

@[keep_args_alive]
fn C.igTableBeginCell(table &Table, column_n i32)

@[inline]
pub fn table_begin_cell(table &Table, column_n i32) {
	C.igTableBeginCell(table, column_n)
}

@[keep_args_alive]
fn C.igTableEndCell(table &Table)

@[inline]
pub fn table_end_cell(table &Table) {
	C.igTableEndCell(table)
}

@[keep_args_alive]
fn C.igTableGetCellBgRect(table &Table, column_n i32) ImRect_c

@[inline]
pub fn table_get_cell_bg_rect(table &Table, column_n i32) ImRect_c {
	return C.igTableGetCellBgRect(table, column_n)
}

@[keep_args_alive]
fn C.igTableGetColumnName_TablePtr(table &Table, column_n i32) &char

@[inline]
pub fn table_get_column_name_table_ptr(table &Table, column_n i32) &char {
	return C.igTableGetColumnName_TablePtr(table, column_n)
}

@[keep_args_alive]
fn C.igTableGetColumnResizeID(table &Table, column_n i32, instance_no i32) ID

@[inline]
pub fn table_get_column_resize_id(table &Table, column_n i32, instance_no i32) ID {
	return C.igTableGetColumnResizeID(table, column_n, instance_no)
}

@[keep_args_alive]
fn C.igTableCalcMaxColumnWidth(table &Table, column_n i32) f32

@[inline]
pub fn table_calc_max_column_width(table &Table, column_n i32) f32 {
	return C.igTableCalcMaxColumnWidth(table, column_n)
}

@[keep_args_alive]
fn C.igTableSetColumnWidthAutoSingle(table &Table, column_n i32)

@[inline]
pub fn table_set_column_width_auto_single(table &Table, column_n i32) {
	C.igTableSetColumnWidthAutoSingle(table, column_n)
}

@[keep_args_alive]
fn C.igTableSetColumnWidthAutoAll(table &Table)

@[inline]
pub fn table_set_column_width_auto_all(table &Table) {
	C.igTableSetColumnWidthAutoAll(table)
}

@[keep_args_alive]
fn C.igTableSetColumnDisplayOrder(table &Table, column_n i32, dst_order i32)

@[inline]
pub fn table_set_column_display_order(table &Table, column_n i32, dst_order i32) {
	C.igTableSetColumnDisplayOrder(table, column_n, dst_order)
}

@[keep_args_alive]
fn C.igTableQueueSetColumnDisplayOrder(table &Table, column_n i32, dst_order i32)

@[inline]
pub fn table_queue_set_column_display_order(table &Table, column_n i32, dst_order i32) {
	C.igTableQueueSetColumnDisplayOrder(table, column_n, dst_order)
}

@[keep_args_alive]
fn C.igTableRemove(table &Table)

@[inline]
pub fn table_remove(table &Table) {
	C.igTableRemove(table)
}

@[keep_args_alive]
fn C.igTableGcCompactTransientBuffers_TablePtr(table &Table)

@[inline]
pub fn table_gc_compact_transient_buffers_table_ptr(table &Table) {
	C.igTableGcCompactTransientBuffers_TablePtr(table)
}

@[keep_args_alive]
fn C.igTableGcCompactTransientBuffers_TableTempDataPtr(table &TableTempData)

@[inline]
pub fn table_gc_compact_transient_buffers_table_temp_data_ptr(table &TableTempData) {
	C.igTableGcCompactTransientBuffers_TableTempDataPtr(table)
}

@[keep_args_alive]
fn C.igTableGcCompactSettings()

@[inline]
pub fn table_gc_compact_settings() {
	C.igTableGcCompactSettings()
}

@[keep_args_alive]
fn C.igTableLoadSettings(table &Table)

@[inline]
pub fn table_load_settings(table &Table) {
	C.igTableLoadSettings(table)
}

@[keep_args_alive]
fn C.igTableSaveSettings(table &Table)

@[inline]
pub fn table_save_settings(table &Table) {
	C.igTableSaveSettings(table)
}

@[keep_args_alive]
fn C.igTableResetSettings(table &Table)

@[inline]
pub fn table_reset_settings(table &Table) {
	C.igTableResetSettings(table)
}

@[keep_args_alive]
fn C.igTableGetBoundSettings(table &Table) &TableSettings

@[inline]
pub fn table_get_bound_settings(table &Table) &TableSettings {
	return C.igTableGetBoundSettings(table)
}

@[keep_args_alive]
fn C.igTableSettingsAddSettingsHandler()

@[inline]
pub fn table_settings_add_settings_handler() {
	C.igTableSettingsAddSettingsHandler()
}

@[keep_args_alive]
fn C.igTableSettingsCreate(id ID, columns_count i32) &TableSettings

@[inline]
pub fn table_settings_create(id ID, columns_count i32) &TableSettings {
	return C.igTableSettingsCreate(id, columns_count)
}

@[keep_args_alive]
fn C.igTableSettingsFindByID(id ID) &TableSettings

@[inline]
pub fn table_settings_find_by_id(id ID) &TableSettings {
	return C.igTableSettingsFindByID(id)
}

@[keep_args_alive]
fn C.igGetCurrentTabBar() &TabBar

@[inline]
pub fn get_current_tab_bar() &TabBar {
	return C.igGetCurrentTabBar()
}

@[keep_args_alive]
fn C.igTabBarFindByID(id ID) &TabBar

@[inline]
pub fn tab_bar_find_by_id(id ID) &TabBar {
	return C.igTabBarFindByID(id)
}

@[keep_args_alive]
fn C.igTabBarRemove(tab_bar &TabBar)

@[inline]
pub fn tab_bar_remove(tab_bar &TabBar) {
	C.igTabBarRemove(tab_bar)
}

@[keep_args_alive]
fn C.igBeginTabBarEx(tab_bar &TabBar, bb ImRect_c, flags TabBarFlags) bool

@[inline]
pub fn begin_tab_bar_ex(tab_bar &TabBar, bb ImRect_c, flags TabBarFlags) bool {
	return C.igBeginTabBarEx(tab_bar, bb, flags)
}

@[keep_args_alive]
fn C.igTabBarFindTabByID(tab_bar &TabBar, tab_id ID) &TabItem

@[inline]
pub fn tab_bar_find_tab_by_id(tab_bar &TabBar, tab_id ID) &TabItem {
	return C.igTabBarFindTabByID(tab_bar, tab_id)
}

@[keep_args_alive]
fn C.igTabBarFindTabByOrder(tab_bar &TabBar, order i32) &TabItem

@[inline]
pub fn tab_bar_find_tab_by_order(tab_bar &TabBar, order i32) &TabItem {
	return C.igTabBarFindTabByOrder(tab_bar, order)
}

@[keep_args_alive]
fn C.igTabBarFindMostRecentlySelectedTabForActiveWindow(tab_bar &TabBar) &TabItem

@[inline]
pub fn tab_bar_find_most_recently_selected_tab_for_active_window(tab_bar &TabBar) &TabItem {
	return C.igTabBarFindMostRecentlySelectedTabForActiveWindow(tab_bar)
}

@[keep_args_alive]
fn C.igTabBarGetCurrentTab(tab_bar &TabBar) &TabItem

@[inline]
pub fn tab_bar_get_current_tab(tab_bar &TabBar) &TabItem {
	return C.igTabBarGetCurrentTab(tab_bar)
}

@[keep_args_alive]
fn C.igTabBarGetTabOrder(tab_bar &TabBar, tab &TabItem) i32

@[inline]
pub fn tab_bar_get_tab_order(tab_bar &TabBar, tab &TabItem) i32 {
	return C.igTabBarGetTabOrder(tab_bar, tab)
}

@[keep_args_alive]
fn C.igTabBarGetTabName(tab_bar &TabBar, tab &TabItem) &char

@[inline]
pub fn tab_bar_get_tab_name(tab_bar &TabBar, tab &TabItem) &char {
	return C.igTabBarGetTabName(tab_bar, tab)
}

@[keep_args_alive]
fn C.igTabBarAddTab(tab_bar &TabBar, tab_flags TabItemFlags, window &Window)

@[inline]
pub fn tab_bar_add_tab(tab_bar &TabBar, tab_flags TabItemFlags, window &Window) {
	C.igTabBarAddTab(tab_bar, tab_flags, window)
}

@[keep_args_alive]
fn C.igTabBarRemoveTab(tab_bar &TabBar, tab_id ID)

@[inline]
pub fn tab_bar_remove_tab(tab_bar &TabBar, tab_id ID) {
	C.igTabBarRemoveTab(tab_bar, tab_id)
}

@[keep_args_alive]
fn C.igTabBarCloseTab(tab_bar &TabBar, tab &TabItem)

@[inline]
pub fn tab_bar_close_tab(tab_bar &TabBar, tab &TabItem) {
	C.igTabBarCloseTab(tab_bar, tab)
}

@[keep_args_alive]
fn C.igTabBarQueueFocus_TabItemPtr(tab_bar &TabBar, tab &TabItem)

@[inline]
pub fn tab_bar_queue_focus_tab_item_ptr(tab_bar &TabBar, tab &TabItem) {
	C.igTabBarQueueFocus_TabItemPtr(tab_bar, tab)
}

@[keep_args_alive]
fn C.igTabBarQueueFocus_Str(tab_bar &TabBar, tab_name &char)

@[inline]
pub fn tab_bar_queue_focus_str(tab_bar &TabBar, tab_name &char) {
	C.igTabBarQueueFocus_Str(tab_bar, tab_name)
}

@[keep_args_alive]
fn C.igTabBarQueueReorder(tab_bar &TabBar, tab &TabItem, offset i32)

@[inline]
pub fn tab_bar_queue_reorder(tab_bar &TabBar, tab &TabItem, offset i32) {
	C.igTabBarQueueReorder(tab_bar, tab, offset)
}

@[keep_args_alive]
fn C.igTabBarQueueReorderFromMousePos(tab_bar &TabBar, tab &TabItem, mouse_pos ImVec2_c)

@[inline]
pub fn tab_bar_queue_reorder_from_mouse_pos(tab_bar &TabBar, tab &TabItem, mouse_pos ImVec2_c) {
	C.igTabBarQueueReorderFromMousePos(tab_bar, tab, mouse_pos)
}

@[keep_args_alive]
fn C.igTabBarProcessReorder(tab_bar &TabBar) bool

@[inline]
pub fn tab_bar_process_reorder(tab_bar &TabBar) bool {
	return C.igTabBarProcessReorder(tab_bar)
}

@[keep_args_alive]
fn C.igTabItemEx(tab_bar &TabBar, const_label &char, p_open &bool, flags TabItemFlags, docked_window &Window) bool

@[inline]
pub fn tab_item_ex(tab_bar &TabBar, const_label &char, p_open &bool, flags TabItemFlags, docked_window &Window) bool {
	return C.igTabItemEx(tab_bar, const_label, p_open, flags, docked_window)
}

@[keep_args_alive]
fn C.igTabItemSpacing(const_str_id &char, flags TabItemFlags, width f32)

@[inline]
pub fn tab_item_spacing(const_str_id &char, flags TabItemFlags, width f32) {
	C.igTabItemSpacing(const_str_id, flags, width)
}

@[keep_args_alive]
fn C.igTabItemCalcSize_Str(const_label &char, has_close_button_or_unsaved_marker bool) ImVec2_c

@[inline]
pub fn tab_item_calc_size_str(const_label &char, has_close_button_or_unsaved_marker bool) ImVec2_c {
	return C.igTabItemCalcSize_Str(const_label, has_close_button_or_unsaved_marker)
}

@[keep_args_alive]
fn C.igTabItemCalcSize_WindowPtr(window &Window) ImVec2_c

@[inline]
pub fn tab_item_calc_size_window_ptr(window &Window) ImVec2_c {
	return C.igTabItemCalcSize_WindowPtr(window)
}

@[keep_args_alive]
fn C.igTabItemBackground(draw_list &ImDrawList, bb ImRect_c, flags TabItemFlags, col ImU32)

@[inline]
pub fn tab_item_background(draw_list &ImDrawList, bb ImRect_c, flags TabItemFlags, col ImU32) {
	C.igTabItemBackground(draw_list, bb, flags, col)
}

@[keep_args_alive]
fn C.igTabItemLabelAndCloseButton(draw_list &ImDrawList, bb ImRect_c, flags TabItemFlags, frame_padding ImVec2_c, const_label &char, tab_id ID, close_button_id ID, is_contents_visible bool, out_just_closed &bool, out_text_clipped &bool)

@[inline]
pub fn tab_item_label_and_close_button(draw_list &ImDrawList, bb ImRect_c, flags TabItemFlags, frame_padding ImVec2_c, const_label &char, tab_id ID, close_button_id ID, is_contents_visible bool, out_just_closed &bool, out_text_clipped &bool) {
	C.igTabItemLabelAndCloseButton(draw_list, bb, flags, frame_padding, const_label, tab_id,
		close_button_id, is_contents_visible, out_just_closed, out_text_clipped)
}

@[keep_args_alive]
fn C.igRenderText(pos ImVec2_c, const_text &char, const_text_end &char, hide_text_after_hash bool)

@[inline]
pub fn render_text(pos ImVec2_c, const_text &char, const_text_end &char, hide_text_after_hash bool) {
	C.igRenderText(pos, const_text, const_text_end, hide_text_after_hash)
}

@[keep_args_alive]
fn C.igRenderTextWrapped(pos ImVec2_c, const_text &char, const_text_end &char, wrap_width f32)

@[inline]
pub fn render_text_wrapped(pos ImVec2_c, const_text &char, const_text_end &char, wrap_width f32) {
	C.igRenderTextWrapped(pos, const_text, const_text_end, wrap_width)
}

@[keep_args_alive]
fn C.igRenderTextClipped(pos_min ImVec2_c, pos_max ImVec2_c, const_text &char, const_text_end &char, text_size_if_known &ImVec2_c, align ImVec2_c, clip_rect &ImRect)

@[inline]
pub fn render_text_clipped(pos_min ImVec2_c, pos_max ImVec2_c, const_text &char, const_text_end &char, text_size_if_known &ImVec2_c, align ImVec2_c, clip_rect &ImRect) {
	C.igRenderTextClipped(pos_min, pos_max, const_text, const_text_end, text_size_if_known, align,
		clip_rect)
}

@[keep_args_alive]
fn C.igRenderTextClippedEx(draw_list &ImDrawList, pos_min ImVec2_c, pos_max ImVec2_c, const_text &char, const_text_end &char, text_size_if_known &ImVec2_c, align ImVec2_c, clip_rect &ImRect)

@[inline]
pub fn render_text_clipped_ex(draw_list &ImDrawList, pos_min ImVec2_c, pos_max ImVec2_c, const_text &char, const_text_end &char, text_size_if_known &ImVec2_c, align ImVec2_c, clip_rect &ImRect) {
	C.igRenderTextClippedEx(draw_list, pos_min, pos_max, const_text, const_text_end,
		text_size_if_known, align, clip_rect)
}

@[keep_args_alive]
fn C.igRenderTextEllipsis(draw_list &ImDrawList, pos_min ImVec2_c, pos_max ImVec2_c, ellipsis_max_x f32, const_text &char, const_text_end &char, text_size_if_known &ImVec2_c)

@[inline]
pub fn render_text_ellipsis(draw_list &ImDrawList, pos_min ImVec2_c, pos_max ImVec2_c, ellipsis_max_x f32, const_text &char, const_text_end &char, text_size_if_known &ImVec2_c) {
	C.igRenderTextEllipsis(draw_list, pos_min, pos_max, ellipsis_max_x, const_text, const_text_end,
		text_size_if_known)
}

@[keep_args_alive]
fn C.igRenderFrame(p_min ImVec2_c, p_max ImVec2_c, fill_col ImU32, borders bool, rounding f32)

@[inline]
pub fn render_frame(p_min ImVec2_c, p_max ImVec2_c, fill_col ImU32, borders bool, rounding f32) {
	C.igRenderFrame(p_min, p_max, fill_col, borders, rounding)
}

@[keep_args_alive]
fn C.igRenderFrameBorder(p_min ImVec2_c, p_max ImVec2_c, rounding f32)

@[inline]
pub fn render_frame_border(p_min ImVec2_c, p_max ImVec2_c, rounding f32) {
	C.igRenderFrameBorder(p_min, p_max, rounding)
}

@[keep_args_alive]
fn C.igRenderColorComponentMarker(bb ImRect_c, col ImU32, rounding f32)

@[inline]
pub fn render_color_component_marker(bb ImRect_c, col ImU32, rounding f32) {
	C.igRenderColorComponentMarker(bb, col, rounding)
}

@[keep_args_alive]
fn C.igRenderColorRectWithAlphaCheckerboard(draw_list &ImDrawList, p_min ImVec2_c, p_max ImVec2_c, fill_col ImU32, grid_step f32, grid_off ImVec2_c, rounding f32, flags ImDrawFlags)

@[inline]
pub fn render_color_rect_with_alpha_checkerboard(draw_list &ImDrawList, p_min ImVec2_c, p_max ImVec2_c, fill_col ImU32, grid_step f32, grid_off ImVec2_c, rounding f32, flags ImDrawFlags) {
	C.igRenderColorRectWithAlphaCheckerboard(draw_list, p_min, p_max, fill_col, grid_step,
		grid_off, rounding, flags)
}

@[keep_args_alive]
fn C.igRenderNavCursor(bb ImRect_c, id ID, flags NavRenderCursorFlags)

@[inline]
pub fn render_nav_cursor(bb ImRect_c, id ID, flags NavRenderCursorFlags) {
	C.igRenderNavCursor(bb, id, flags)
}

@[keep_args_alive]
fn C.igFindRenderedTextEnd(const_text &char, const_text_end &char) &char

@[inline]
pub fn find_rendered_text_end(const_text &char, const_text_end &char) &char {
	return C.igFindRenderedTextEnd(const_text, const_text_end)
}

@[keep_args_alive]
fn C.igRenderMouseCursor(pos ImVec2_c, scale f32, mouse_cursor MouseCursor, col_fill ImU32, col_border ImU32, col_shadow ImU32)

@[inline]
pub fn render_mouse_cursor(pos ImVec2_c, scale f32, mouse_cursor MouseCursor, col_fill ImU32, col_border ImU32, col_shadow ImU32) {
	C.igRenderMouseCursor(pos, scale, mouse_cursor, col_fill, col_border, col_shadow)
}

@[keep_args_alive]
fn C.igRenderArrow(draw_list &ImDrawList, pos ImVec2_c, col ImU32, dir Dir, scale f32)

@[inline]
pub fn render_arrow(draw_list &ImDrawList, pos ImVec2_c, col ImU32, dir Dir, scale f32) {
	C.igRenderArrow(draw_list, pos, col, dir, scale)
}

@[keep_args_alive]
fn C.igRenderBullet(draw_list &ImDrawList, pos ImVec2_c, col ImU32)

@[inline]
pub fn render_bullet(draw_list &ImDrawList, pos ImVec2_c, col ImU32) {
	C.igRenderBullet(draw_list, pos, col)
}

@[keep_args_alive]
fn C.igRenderCheckMark(draw_list &ImDrawList, pos ImVec2_c, col ImU32, sz f32)

@[inline]
pub fn render_check_mark(draw_list &ImDrawList, pos ImVec2_c, col ImU32, sz f32) {
	C.igRenderCheckMark(draw_list, pos, col, sz)
}

@[keep_args_alive]
fn C.igRenderArrowPointingAt(draw_list &ImDrawList, pos ImVec2_c, half_sz ImVec2_c, direction Dir, col ImU32)

@[inline]
pub fn render_arrow_pointing_at(draw_list &ImDrawList, pos ImVec2_c, half_sz ImVec2_c, direction Dir, col ImU32) {
	C.igRenderArrowPointingAt(draw_list, pos, half_sz, direction, col)
}

@[keep_args_alive]
fn C.igRenderArrowDockMenu(draw_list &ImDrawList, p_min ImVec2_c, sz f32, col ImU32)

@[inline]
pub fn render_arrow_dock_menu(draw_list &ImDrawList, p_min ImVec2_c, sz f32, col ImU32) {
	C.igRenderArrowDockMenu(draw_list, p_min, sz, col)
}

@[keep_args_alive]
fn C.igRenderRectFilledInRangeH(draw_list &ImDrawList, rect ImRect_c, col ImU32, fill_x0 f32, fill_x1 f32, rounding f32)

@[inline]
pub fn render_rect_filled_in_range_h(draw_list &ImDrawList, rect ImRect_c, col ImU32, fill_x0 f32, fill_x1 f32, rounding f32) {
	C.igRenderRectFilledInRangeH(draw_list, rect, col, fill_x0, fill_x1, rounding)
}

@[keep_args_alive]
fn C.igRenderRectFilledWithHole(draw_list &ImDrawList, outer ImRect_c, inner ImRect_c, col ImU32, rounding f32)

@[inline]
pub fn render_rect_filled_with_hole(draw_list &ImDrawList, outer ImRect_c, inner ImRect_c, col ImU32, rounding f32) {
	C.igRenderRectFilledWithHole(draw_list, outer, inner, col, rounding)
}

@[keep_args_alive]
fn C.igCalcRoundingFlagsForRectInRect(r_in ImRect_c, r_outer ImRect_c, threshold f32) ImDrawFlags

@[inline]
pub fn calc_rounding_flags_for_rect_in_rect(r_in ImRect_c, r_outer ImRect_c, threshold f32) ImDrawFlags {
	return C.igCalcRoundingFlagsForRectInRect(r_in, r_outer, threshold)
}

@[keep_args_alive]
fn C.igTextEx(const_text &char, const_text_end &char, flags TextFlags)

@[inline]
pub fn text_ex(const_text &char, const_text_end &char, flags TextFlags) {
	C.igTextEx(const_text, const_text_end, flags)
}

@[keep_args_alive]
fn C.igTextAligned(align_x f32, size_x f32, const_fmt &char)

@[inline]
pub fn text_aligned(align_x f32, size_x f32, const_fmt &char) {
	C.igTextAligned(align_x, size_x, const_fmt)
}

@[keep_args_alive]
fn C.igTextAlignedV(align_x f32, size_x f32, const_fmt &char, args Va_list)

@[inline]
pub fn text_aligned_v(align_x f32, size_x f32, const_fmt &char, args Va_list) {
	C.igTextAlignedV(align_x, size_x, const_fmt, args)
}

@[keep_args_alive]
fn C.igButtonEx(const_label &char, size_arg ImVec2_c, flags ButtonFlags) bool

@[inline]
pub fn button_ex(const_label &char, size_arg ImVec2_c, flags ButtonFlags) bool {
	return C.igButtonEx(const_label, size_arg, flags)
}

@[keep_args_alive]
fn C.igArrowButtonEx(const_str_id &char, dir Dir, size_arg ImVec2_c, flags ButtonFlags) bool

@[inline]
pub fn arrow_button_ex(const_str_id &char, dir Dir, size_arg ImVec2_c, flags ButtonFlags) bool {
	return C.igArrowButtonEx(const_str_id, dir, size_arg, flags)
}

@[keep_args_alive]
fn C.igImageButtonEx(id ID, tex_ref ImTextureRef_c, image_size ImVec2_c, uv0 ImVec2_c, uv1 ImVec2_c, bg_col ImVec4_c, tint_col ImVec4_c, flags ButtonFlags) bool

@[inline]
pub fn image_button_ex(id ID, tex_ref ImTextureRef_c, image_size ImVec2_c, uv0 ImVec2_c, uv1 ImVec2_c, bg_col ImVec4_c, tint_col ImVec4_c, flags ButtonFlags) bool {
	return C.igImageButtonEx(id, tex_ref, image_size, uv0, uv1, bg_col, tint_col, flags)
}

@[keep_args_alive]
fn C.igSeparatorEx(flags SeparatorFlags, thickness f32)

@[inline]
pub fn separator_ex(flags SeparatorFlags, thickness f32) {
	C.igSeparatorEx(flags, thickness)
}

@[keep_args_alive]
fn C.igSeparatorTextEx(id ID, const_label &char, label_end &char, extra_width f32)

@[inline]
pub fn separator_text_ex(id ID, const_label &char, label_end &char, extra_width f32) {
	C.igSeparatorTextEx(id, const_label, label_end, extra_width)
}

@[keep_args_alive]
fn C.igCheckboxFlags_S64Ptr(const_label &char, flags &ImS64, flags_value ImS64) bool

@[inline]
pub fn checkbox_flags_s64_ptr(const_label &char, flags &ImS64, flags_value ImS64) bool {
	return C.igCheckboxFlags_S64Ptr(const_label, flags, flags_value)
}

@[keep_args_alive]
fn C.igCheckboxFlags_U64Ptr(const_label &char, flags &ImU64, flags_value ImU64) bool

@[inline]
pub fn checkbox_flags_u64_ptr(const_label &char, flags &ImU64, flags_value ImU64) bool {
	return C.igCheckboxFlags_U64Ptr(const_label, flags, flags_value)
}

@[keep_args_alive]
fn C.igCloseButton(id ID, pos ImVec2_c) bool

@[inline]
pub fn close_button(id ID, pos ImVec2_c) bool {
	return C.igCloseButton(id, pos)
}

@[keep_args_alive]
fn C.igCollapseButton(id ID, pos ImVec2_c, dock_node &DockNode) bool

@[inline]
pub fn collapse_button(id ID, pos ImVec2_c, dock_node &DockNode) bool {
	return C.igCollapseButton(id, pos, dock_node)
}

@[keep_args_alive]
fn C.igScrollbar(axis Axis)

@[inline]
pub fn scrollbar(axis Axis) {
	C.igScrollbar(axis)
}

@[keep_args_alive]
fn C.igScrollbarEx(bb ImRect_c, id ID, axis Axis, p_scroll_v &ImS64, avail_v ImS64, contents_v ImS64, draw_rounding_flags ImDrawFlags) bool

@[inline]
pub fn scrollbar_ex(bb ImRect_c, id ID, axis Axis, p_scroll_v &ImS64, avail_v ImS64, contents_v ImS64, draw_rounding_flags ImDrawFlags) bool {
	return C.igScrollbarEx(bb, id, axis, p_scroll_v, avail_v, contents_v, draw_rounding_flags)
}

@[keep_args_alive]
fn C.igGetWindowScrollbarRect(window &Window, axis Axis) ImRect_c

@[inline]
pub fn get_window_scrollbar_rect(window &Window, axis Axis) ImRect_c {
	return C.igGetWindowScrollbarRect(window, axis)
}

@[keep_args_alive]
fn C.igGetWindowScrollbarID(window &Window, axis Axis) ID

@[inline]
pub fn get_window_scrollbar_id(window &Window, axis Axis) ID {
	return C.igGetWindowScrollbarID(window, axis)
}

@[keep_args_alive]
fn C.igGetWindowResizeCornerID(window &Window, n i32) ID

@[inline]
pub fn get_window_resize_corner_id(window &Window, n i32) ID {
	return C.igGetWindowResizeCornerID(window, n)
}

@[keep_args_alive]
fn C.igGetWindowResizeBorderID(window &Window, dir Dir) ID

@[inline]
pub fn get_window_resize_border_id(window &Window, dir Dir) ID {
	return C.igGetWindowResizeBorderID(window, dir)
}

@[keep_args_alive]
fn C.igExtendHitBoxWhenNearViewportEdge(window &Window, bb &ImRect, threshold f32, axis Axis)

@[inline]
pub fn extend_hit_box_when_near_viewport_edge(window &Window, bb &ImRect, threshold f32, axis Axis) {
	C.igExtendHitBoxWhenNearViewportEdge(window, bb, threshold, axis)
}

@[keep_args_alive]
fn C.igButtonBehavior(bb ImRect_c, id ID, out_hovered &bool, out_held &bool, flags ButtonFlags) bool

@[inline]
pub fn button_behavior(bb ImRect_c, id ID, out_hovered &bool, out_held &bool, flags ButtonFlags) bool {
	return C.igButtonBehavior(bb, id, out_hovered, out_held, flags)
}

@[keep_args_alive]
fn C.igDragBehavior(id ID, data_type DataType, p_v voidptr, v_speed f32, p_min voidptr, p_max voidptr, format &char, flags SliderFlags) bool

@[inline]
pub fn drag_behavior(id ID, data_type DataType, p_v voidptr, v_speed f32, p_min voidptr, p_max voidptr, format &char, flags SliderFlags) bool {
	return C.igDragBehavior(id, data_type, p_v, v_speed, p_min, p_max, format, flags)
}

@[keep_args_alive]
fn C.igSliderBehavior(bb ImRect_c, id ID, data_type DataType, p_v voidptr, p_min voidptr, p_max voidptr, format &char, flags SliderFlags, out_grab_bb &ImRect) bool

@[inline]
pub fn slider_behavior(bb ImRect_c, id ID, data_type DataType, p_v voidptr, p_min voidptr, p_max voidptr, format &char, flags SliderFlags, out_grab_bb &ImRect) bool {
	return C.igSliderBehavior(bb, id, data_type, p_v, p_min, p_max, format, flags, out_grab_bb)
}

@[keep_args_alive]
fn C.igSplitterBehavior(bb ImRect_c, id ID, axis Axis, size1 &f32, size2 &f32, min_size1 f32, min_size2 f32, hover_extend f32, hover_visibility_delay f32, bg_col ImU32) bool

@[inline]
pub fn splitter_behavior(bb ImRect_c, id ID, axis Axis, size1 &f32, size2 &f32, min_size1 f32, min_size2 f32, hover_extend f32, hover_visibility_delay f32, bg_col ImU32) bool {
	return C.igSplitterBehavior(bb, id, axis, size1, size2, min_size1, min_size2, hover_extend,
		hover_visibility_delay, bg_col)
}

@[keep_args_alive]
fn C.igTreeNodeBehavior(id ID, flags TreeNodeFlags, const_label &char, label_end &char) bool

@[inline]
pub fn tree_node_behavior(id ID, flags TreeNodeFlags, const_label &char, label_end &char) bool {
	return C.igTreeNodeBehavior(id, flags, const_label, label_end)
}

@[keep_args_alive]
fn C.igTreeNodeDrawLineToChildNode(target_pos ImVec2_c)

@[inline]
pub fn tree_node_draw_line_to_child_node(target_pos ImVec2_c) {
	C.igTreeNodeDrawLineToChildNode(target_pos)
}

@[keep_args_alive]
fn C.igTreeNodeDrawLineToTreePop(data &TreeNodeStackData)

@[inline]
pub fn tree_node_draw_line_to_tree_pop(data &TreeNodeStackData) {
	C.igTreeNodeDrawLineToTreePop(data)
}

@[keep_args_alive]
fn C.igTreePushOverrideID(id ID)

@[inline]
pub fn tree_push_override_id(id ID) {
	C.igTreePushOverrideID(id)
}

@[keep_args_alive]
fn C.igTreeNodeSetOpen(storage_id ID, open bool)

@[inline]
pub fn tree_node_set_open(storage_id ID, open bool) {
	C.igTreeNodeSetOpen(storage_id, open)
}

@[keep_args_alive]
fn C.igTreeNodeUpdateNextOpen(storage_id ID, flags TreeNodeFlags) bool

@[inline]
pub fn tree_node_update_next_open(storage_id ID, flags TreeNodeFlags) bool {
	return C.igTreeNodeUpdateNextOpen(storage_id, flags)
}

@[keep_args_alive]
fn C.igDataTypeGetInfo(data_type DataType) &DataTypeInfo

@[inline]
pub fn data_type_get_info(data_type DataType) &DataTypeInfo {
	return C.igDataTypeGetInfo(data_type)
}

@[keep_args_alive]
fn C.igDataTypeFormatString(buf &char, buf_size i32, data_type DataType, p_data voidptr, format &char) i32

@[inline]
pub fn data_type_format_string(buf &char, buf_size i32, data_type DataType, p_data voidptr, format &char) i32 {
	return C.igDataTypeFormatString(buf, buf_size, data_type, p_data, format)
}

@[keep_args_alive]
fn C.igDataTypeApplyOp(data_type DataType, op i32, output voidptr, arg_1 voidptr, arg_2 voidptr)

@[inline]
pub fn data_type_apply_op(data_type DataType, op i32, output voidptr, arg_1 voidptr, arg_2 voidptr) {
	C.igDataTypeApplyOp(data_type, op, output, arg_1, arg_2)
}

@[keep_args_alive]
fn C.igDataTypeApplyFromText(buf &char, data_type DataType, p_data voidptr, format &char, p_data_when_empty voidptr) bool

@[inline]
pub fn data_type_apply_from_text(buf &char, data_type DataType, p_data voidptr, format &char, p_data_when_empty voidptr) bool {
	return C.igDataTypeApplyFromText(buf, data_type, p_data, format, p_data_when_empty)
}

@[keep_args_alive]
fn C.igDataTypeCompare(data_type DataType, arg_1 voidptr, arg_2 voidptr) i32

@[inline]
pub fn data_type_compare(data_type DataType, arg_1 voidptr, arg_2 voidptr) i32 {
	return C.igDataTypeCompare(data_type, arg_1, arg_2)
}

@[keep_args_alive]
fn C.igDataTypeClamp(data_type DataType, p_data voidptr, p_min voidptr, p_max voidptr) bool

@[inline]
pub fn data_type_clamp(data_type DataType, p_data voidptr, p_min voidptr, p_max voidptr) bool {
	return C.igDataTypeClamp(data_type, p_data, p_min, p_max)
}

@[keep_args_alive]
fn C.igDataTypeIsZero(data_type DataType, p_data voidptr) bool

@[inline]
pub fn data_type_is_zero(data_type DataType, p_data voidptr) bool {
	return C.igDataTypeIsZero(data_type, p_data)
}

@[keep_args_alive]
fn C.igInputTextEx(const_label &char, hint &char, buf &char, buf_size i32, size_arg ImVec2_c, flags InputTextFlags, callback InputTextCallback, user_data voidptr) bool

@[inline]
pub fn input_text_ex(const_label &char, hint &char, buf &char, buf_size i32, size_arg ImVec2_c, flags InputTextFlags, callback InputTextCallback, user_data voidptr) bool {
	return C.igInputTextEx(const_label, hint, buf, buf_size, size_arg, flags, callback, user_data)
}

@[keep_args_alive]
fn C.igInputTextDeactivateHook(id ID)

@[inline]
pub fn input_text_deactivate_hook(id ID) {
	C.igInputTextDeactivateHook(id)
}

@[keep_args_alive]
fn C.igTempInputText(bb ImRect_c, id ID, const_label &char, buf &char, buf_size usize, flags InputTextFlags, callback InputTextCallback, user_data voidptr) bool

@[inline]
pub fn temp_input_text(bb ImRect_c, id ID, const_label &char, buf &char, buf_size usize, flags InputTextFlags, callback InputTextCallback, user_data voidptr) bool {
	return C.igTempInputText(bb, id, const_label, buf, buf_size, flags, callback, user_data)
}

@[keep_args_alive]
fn C.igTempInputScalar(bb ImRect_c, id ID, const_label &char, data_type DataType, p_data voidptr, format &char, p_clamp_min voidptr, p_clamp_max voidptr) bool

@[inline]
pub fn temp_input_scalar(bb ImRect_c, id ID, const_label &char, data_type DataType, p_data voidptr, format &char, p_clamp_min voidptr, p_clamp_max voidptr) bool {
	return C.igTempInputScalar(bb, id, const_label, data_type, p_data, format, p_clamp_min,
		p_clamp_max)
}

@[keep_args_alive]
fn C.igTempInputIsActive(id ID) bool

@[inline]
pub fn temp_input_is_active(id ID) bool {
	return C.igTempInputIsActive(id)
}

@[keep_args_alive]
fn C.igGetInputTextState(id ID) &InputTextState

@[inline]
pub fn get_input_text_state(id ID) &InputTextState {
	return C.igGetInputTextState(id)
}

@[keep_args_alive]
fn C.igSetNextItemRefVal(data_type DataType, p_data voidptr)

@[inline]
pub fn set_next_item_ref_val(data_type DataType, p_data voidptr) {
	C.igSetNextItemRefVal(data_type, p_data)
}

@[keep_args_alive]
fn C.igIsItemActiveAsInputText() bool

@[inline]
pub fn is_item_active_as_input_text() bool {
	return C.igIsItemActiveAsInputText()
}

@[keep_args_alive]
fn C.igColorTooltip(const_text &char, col &f32, flags ColorEditFlags)

@[inline]
pub fn color_tooltip(const_text &char, col &f32, flags ColorEditFlags) {
	C.igColorTooltip(const_text, col, flags)
}

@[keep_args_alive]
fn C.igColorEditOptionsPopup(col &f32, flags ColorEditFlags)

@[inline]
pub fn color_edit_options_popup(col &f32, flags ColorEditFlags) {
	C.igColorEditOptionsPopup(col, flags)
}

@[keep_args_alive]
fn C.igColorPickerOptionsPopup(ref_col &f32, flags ColorEditFlags)

@[inline]
pub fn color_picker_options_popup(ref_col &f32, flags ColorEditFlags) {
	C.igColorPickerOptionsPopup(ref_col, flags)
}

@[keep_args_alive]
fn C.igSetNextItemColorMarker(col ImU32)

@[inline]
pub fn set_next_item_color_marker(col ImU32) {
	C.igSetNextItemColorMarker(col)
}

@[keep_args_alive]
fn C.igPlotEx(plot_type PlotType, const_label &char, values_getter fn (voidptr, i32) f32, data voidptr, values_count i32, values_offset i32, overlay_text &char, scale_min f32, scale_max f32, size_arg ImVec2_c) i32

@[inline]
pub fn plot_ex(plot_type PlotType, const_label &char, values_getter fn (voidptr, i32) f32, data voidptr, values_count i32, values_offset i32, overlay_text &char, scale_min f32, scale_max f32, size_arg ImVec2_c) i32 {
	return C.igPlotEx(plot_type, const_label, values_getter, data, values_count, values_offset,
		overlay_text, scale_min, scale_max, size_arg)
}

@[keep_args_alive]
fn C.igShadeVertsLinearColorGradientKeepAlpha(draw_list &ImDrawList, vert_start_idx i32, vert_end_idx i32, gradient_p0 ImVec2_c, gradient_p1 ImVec2_c, col0 ImU32, col1 ImU32)

@[inline]
pub fn shade_verts_linear_color_gradient_keep_alpha(draw_list &ImDrawList, vert_start_idx i32, vert_end_idx i32, gradient_p0 ImVec2_c, gradient_p1 ImVec2_c, col0 ImU32, col1 ImU32) {
	C.igShadeVertsLinearColorGradientKeepAlpha(draw_list, vert_start_idx, vert_end_idx,
		gradient_p0, gradient_p1, col0, col1)
}

@[keep_args_alive]
fn C.igShadeVertsLinearUV(draw_list &ImDrawList, vert_start_idx i32, vert_end_idx i32, a ImVec2_c, b ImVec2_c, uv_a ImVec2_c, uv_b ImVec2_c, clamp bool)

@[inline]
pub fn shade_verts_linear_uv(draw_list &ImDrawList, vert_start_idx i32, vert_end_idx i32, a ImVec2_c, b ImVec2_c, uv_a ImVec2_c, uv_b ImVec2_c, clamp bool) {
	C.igShadeVertsLinearUV(draw_list, vert_start_idx, vert_end_idx, a, b, uv_a, uv_b, clamp)
}

@[keep_args_alive]
fn C.igShadeVertsTransformPos(draw_list &ImDrawList, vert_start_idx i32, vert_end_idx i32, pivot_in ImVec2_c, cos_a f32, sin_a f32, pivot_out ImVec2_c)

@[inline]
pub fn shade_verts_transform_pos(draw_list &ImDrawList, vert_start_idx i32, vert_end_idx i32, pivot_in ImVec2_c, cos_a f32, sin_a f32, pivot_out ImVec2_c) {
	C.igShadeVertsTransformPos(draw_list, vert_start_idx, vert_end_idx, pivot_in, cos_a, sin_a,
		pivot_out)
}

@[keep_args_alive]
fn C.igGcCompactTransientMiscBuffers()

@[inline]
pub fn gc_compact_transient_misc_buffers() {
	C.igGcCompactTransientMiscBuffers()
}

@[keep_args_alive]
fn C.igGcCompactTransientWindowBuffers(window &Window)

@[inline]
pub fn gc_compact_transient_window_buffers(window &Window) {
	C.igGcCompactTransientWindowBuffers(window)
}

@[keep_args_alive]
fn C.igGcAwakeTransientWindowBuffers(window &Window)

@[inline]
pub fn gc_awake_transient_window_buffers(window &Window) {
	C.igGcAwakeTransientWindowBuffers(window)
}

@[keep_args_alive]
fn C.igErrorLog(msg &char) bool

@[inline]
pub fn error_log(msg &char) bool {
	return C.igErrorLog(msg)
}

@[keep_args_alive]
fn C.igErrorRecoveryStoreState(state_out &ErrorRecoveryState)

@[inline]
pub fn error_recovery_store_state(state_out &ErrorRecoveryState) {
	C.igErrorRecoveryStoreState(state_out)
}

@[keep_args_alive]
fn C.igErrorRecoveryTryToRecoverState(state_in &ErrorRecoveryState)

@[inline]
pub fn error_recovery_try_to_recover_state(state_in &ErrorRecoveryState) {
	C.igErrorRecoveryTryToRecoverState(state_in)
}

@[keep_args_alive]
fn C.igErrorRecoveryTryToRecoverWindowState(state_in &ErrorRecoveryState)

@[inline]
pub fn error_recovery_try_to_recover_window_state(state_in &ErrorRecoveryState) {
	C.igErrorRecoveryTryToRecoverWindowState(state_in)
}

@[keep_args_alive]
fn C.igErrorCheckUsingSetCursorPosToExtendParentBoundaries()

@[inline]
pub fn error_check_using_set_cursor_pos_to_extend_parent_boundaries() {
	C.igErrorCheckUsingSetCursorPosToExtendParentBoundaries()
}

@[keep_args_alive]
fn C.igErrorCheckEndFrameFinalizeErrorTooltip()

@[inline]
pub fn error_check_end_frame_finalize_error_tooltip() {
	C.igErrorCheckEndFrameFinalizeErrorTooltip()
}

@[keep_args_alive]
fn C.igBeginErrorTooltip() bool

@[inline]
pub fn begin_error_tooltip() bool {
	return C.igBeginErrorTooltip()
}

@[keep_args_alive]
fn C.igEndErrorTooltip()

@[inline]
pub fn end_error_tooltip() {
	C.igEndErrorTooltip()
}

@[keep_args_alive]
fn C.igDemoMarker(file &char, line i32, section &char)

@[inline]
pub fn demo_marker(file &char, line i32, section &char) {
	C.igDemoMarker(file, line, section)
}

@[keep_args_alive]
fn C.igDebugAllocHook(info &DebugAllocInfo, frame_count i32, ptr voidptr, size usize)

@[inline]
pub fn debug_alloc_hook(info &DebugAllocInfo, frame_count i32, ptr voidptr, size usize) {
	C.igDebugAllocHook(info, frame_count, ptr, size)
}

@[keep_args_alive]
fn C.igDebugDrawCursorPos(col ImU32)

@[inline]
pub fn debug_draw_cursor_pos(col ImU32) {
	C.igDebugDrawCursorPos(col)
}

@[keep_args_alive]
fn C.igDebugDrawLineExtents(col ImU32)

@[inline]
pub fn debug_draw_line_extents(col ImU32) {
	C.igDebugDrawLineExtents(col)
}

@[keep_args_alive]
fn C.igDebugDrawItemRect(col ImU32)

@[inline]
pub fn debug_draw_item_rect(col ImU32) {
	C.igDebugDrawItemRect(col)
}

@[keep_args_alive]
fn C.igDebugTextUnformattedWithLocateItem(line_begin &char, line_end &char)

@[inline]
pub fn debug_text_unformatted_with_locate_item(line_begin &char, line_end &char) {
	C.igDebugTextUnformattedWithLocateItem(line_begin, line_end)
}

@[keep_args_alive]
fn C.igDebugLocateItem(target_id ID)

@[inline]
pub fn debug_locate_item(target_id ID) {
	C.igDebugLocateItem(target_id)
}

@[keep_args_alive]
fn C.igDebugLocateItemOnHover(target_id ID)

@[inline]
pub fn debug_locate_item_on_hover(target_id ID) {
	C.igDebugLocateItemOnHover(target_id)
}

@[keep_args_alive]
fn C.igDebugLocateItemResolveWithLastItem()

@[inline]
pub fn debug_locate_item_resolve_with_last_item() {
	C.igDebugLocateItemResolveWithLastItem()
}

@[keep_args_alive]
fn C.igDebugBreakClearData()

@[inline]
pub fn debug_break_clear_data() {
	C.igDebugBreakClearData()
}

@[keep_args_alive]
fn C.igDebugBreakButton(const_label &char, description_of_location &char) bool

@[inline]
pub fn debug_break_button(const_label &char, description_of_location &char) bool {
	return C.igDebugBreakButton(const_label, description_of_location)
}

@[keep_args_alive]
fn C.igDebugBreakButtonTooltip(keyboard_only bool, description_of_location &char)

@[inline]
pub fn debug_break_button_tooltip(keyboard_only bool, description_of_location &char) {
	C.igDebugBreakButtonTooltip(keyboard_only, description_of_location)
}

@[keep_args_alive]
fn C.igShowFontAtlas(atlas &ImFontAtlas)

@[inline]
pub fn show_font_atlas(atlas &ImFontAtlas) {
	C.igShowFontAtlas(atlas)
}

@[keep_args_alive]
fn C.igDebugTextureIDToU64(tex_id ImTextureID) ImU64

@[inline]
pub fn debug_texture_idt_o_u64(tex_id ImTextureID) ImU64 {
	return C.igDebugTextureIDToU64(tex_id)
}

@[keep_args_alive]
fn C.igDebugHookIdInfo(id ID, data_type DataType, data_id voidptr, data_id_end voidptr)

@[inline]
pub fn debug_hook_id_info(id ID, data_type DataType, data_id voidptr, data_id_end voidptr) {
	C.igDebugHookIdInfo(id, data_type, data_id, data_id_end)
}

@[keep_args_alive]
fn C.igDebugNodeColumns(columns &OldColumns)

@[inline]
pub fn debug_node_columns(columns &OldColumns) {
	C.igDebugNodeColumns(columns)
}

@[keep_args_alive]
fn C.igDebugNodeDockNode(node &DockNode, const_label &char)

@[inline]
pub fn debug_node_dock_node(node &DockNode, const_label &char) {
	C.igDebugNodeDockNode(node, const_label)
}

@[keep_args_alive]
fn C.igDebugNodeDrawList(window &Window, viewport &ViewportP, draw_list &ImDrawList, const_label &char)

@[inline]
pub fn debug_node_draw_list(window &Window, viewport &ViewportP, draw_list &ImDrawList, const_label &char) {
	C.igDebugNodeDrawList(window, viewport, draw_list, const_label)
}

@[keep_args_alive]
fn C.igDebugNodeDrawCmdShowMeshAndBoundingBox(out_draw_list &ImDrawList, draw_list &ImDrawList, draw_cmd &ImDrawCmd, show_mesh bool, show_aabb bool)

@[inline]
pub fn debug_node_draw_cmd_show_mesh_and_bounding_box(out_draw_list &ImDrawList, draw_list &ImDrawList, draw_cmd &ImDrawCmd, show_mesh bool, show_aabb bool) {
	C.igDebugNodeDrawCmdShowMeshAndBoundingBox(out_draw_list, draw_list, draw_cmd, show_mesh,
		show_aabb)
}

@[keep_args_alive]
fn C.igDebugNodeFont(font &ImFont)

@[inline]
pub fn debug_node_font(font &ImFont) {
	C.igDebugNodeFont(font)
}

@[keep_args_alive]
fn C.igDebugNodeFontGlyphsForSrcMask(font &ImFont, baked &ImFontBaked, src_mask i32)

@[inline]
pub fn debug_node_font_glyphs_for_src_mask(font &ImFont, baked &ImFontBaked, src_mask i32) {
	C.igDebugNodeFontGlyphsForSrcMask(font, baked, src_mask)
}

@[keep_args_alive]
fn C.igDebugNodeFontGlyph(font &ImFont, glyph &ImFontGlyph)

@[inline]
pub fn debug_node_font_glyph(font &ImFont, glyph &ImFontGlyph) {
	C.igDebugNodeFontGlyph(font, glyph)
}

@[keep_args_alive]
fn C.igDebugNodeTexture(tex &ImTextureData, int_id i32, highlight_rect &ImFontAtlasRect)

@[inline]
pub fn debug_node_texture(tex &ImTextureData, int_id i32, highlight_rect &ImFontAtlasRect) {
	C.igDebugNodeTexture(tex, int_id, highlight_rect)
}

@[keep_args_alive]
fn C.igDebugNodeStorage(storage &Storage, const_label &char)

@[inline]
pub fn debug_node_storage(storage &Storage, const_label &char) {
	C.igDebugNodeStorage(storage, const_label)
}

@[keep_args_alive]
fn C.igDebugNodeTabBar(tab_bar &TabBar, const_label &char)

@[inline]
pub fn debug_node_tab_bar(tab_bar &TabBar, const_label &char) {
	C.igDebugNodeTabBar(tab_bar, const_label)
}

@[keep_args_alive]
fn C.igDebugNodeTable(table &Table)

@[inline]
pub fn debug_node_table(table &Table) {
	C.igDebugNodeTable(table)
}

@[keep_args_alive]
fn C.igDebugNodeTableSettings(settings &TableSettings)

@[inline]
pub fn debug_node_table_settings(settings &TableSettings) {
	C.igDebugNodeTableSettings(settings)
}

@[keep_args_alive]
fn C.igDebugNodeInputTextState(state &InputTextState)

@[inline]
pub fn debug_node_input_text_state(state &InputTextState) {
	C.igDebugNodeInputTextState(state)
}

@[keep_args_alive]
fn C.igDebugNodeTypingSelectState(state &TypingSelectState)

@[inline]
pub fn debug_node_typing_select_state(state &TypingSelectState) {
	C.igDebugNodeTypingSelectState(state)
}

@[keep_args_alive]
fn C.igDebugNodeMultiSelectState(state &MultiSelectState)

@[inline]
pub fn debug_node_multi_select_state(state &MultiSelectState) {
	C.igDebugNodeMultiSelectState(state)
}

@[keep_args_alive]
fn C.igDebugNodeWindow(window &Window, const_label &char)

@[inline]
pub fn debug_node_window(window &Window, const_label &char) {
	C.igDebugNodeWindow(window, const_label)
}

@[keep_args_alive]
fn C.igDebugNodeWindowSettings(settings &WindowSettings)

@[inline]
pub fn debug_node_window_settings(settings &WindowSettings) {
	C.igDebugNodeWindowSettings(settings)
}

@[keep_args_alive]
fn C.igDebugNodeWindowsList(windows &ImVector_WindowPtr, const_label &char)

@[inline]
pub fn debug_node_windows_list(windows &ImVector_WindowPtr, const_label &char) {
	C.igDebugNodeWindowsList(windows, const_label)
}

@[keep_args_alive]
fn C.igDebugNodeWindowsListByBeginStackParent(windows &&Window, windows_size i32, parent_in_begin_stack &Window)

@[inline]
pub fn debug_node_windows_list_by_begin_stack_parent(windows &&Window, windows_size i32, parent_in_begin_stack &Window) {
	C.igDebugNodeWindowsListByBeginStackParent(windows, windows_size, parent_in_begin_stack)
}

@[keep_args_alive]
fn C.igDebugNodeViewport(viewport &ViewportP)

@[inline]
pub fn debug_node_viewport(viewport &ViewportP) {
	C.igDebugNodeViewport(viewport)
}

@[keep_args_alive]
fn C.igDebugNodePlatformMonitor(monitor &PlatformMonitor, const_label &char, idx i32)

@[inline]
pub fn debug_node_platform_monitor(monitor &PlatformMonitor, const_label &char, idx i32) {
	C.igDebugNodePlatformMonitor(monitor, const_label, idx)
}

@[keep_args_alive]
fn C.igDebugRenderKeyboardPreview(draw_list &ImDrawList)

@[inline]
pub fn debug_render_keyboard_preview(draw_list &ImDrawList) {
	C.igDebugRenderKeyboardPreview(draw_list)
}

@[keep_args_alive]
fn C.igDebugRenderViewportThumbnail(draw_list &ImDrawList, viewport &ViewportP, bb ImRect_c)

@[inline]
pub fn debug_render_viewport_thumbnail(draw_list &ImDrawList, viewport &ViewportP, bb ImRect_c) {
	C.igDebugRenderViewportThumbnail(draw_list, viewport, bb)
}

@[keep_args_alive]
fn C.ImFontLoader_ImFontLoader() &ImFontLoader

@[inline]
pub fn im_font_loader_im_font_loader() &ImFontLoader {
	return C.ImFontLoader_ImFontLoader()
}

@[keep_args_alive]
fn C.ImFontLoader_destroy(self &ImFontLoader)

@[inline]
pub fn im_font_loader_destroy(self &ImFontLoader) {
	C.ImFontLoader_destroy(self)
}

@[keep_args_alive]
fn C.igImFontAtlasGetFontLoaderForStbTruetype() &ImFontLoader

@[inline]
pub fn im_font_atlas_get_font_loader_for_stb_truetype() &ImFontLoader {
	return C.igImFontAtlasGetFontLoaderForStbTruetype()
}

@[keep_args_alive]
fn C.igImFontAtlasRectId_GetIndex(id ImFontAtlasRectId) i32

@[inline]
pub fn im_font_atlas_rect_id_get_index(id ImFontAtlasRectId) i32 {
	return C.igImFontAtlasRectId_GetIndex(id)
}

@[keep_args_alive]
fn C.igImFontAtlasRectId_GetGeneration(id ImFontAtlasRectId) u32

@[inline]
pub fn im_font_atlas_rect_id_get_generation(id ImFontAtlasRectId) u32 {
	return C.igImFontAtlasRectId_GetGeneration(id)
}

@[keep_args_alive]
fn C.igImFontAtlasRectId_Make(index_idx i32, gen_idx i32) ImFontAtlasRectId

@[inline]
pub fn im_font_atlas_rect_id_make(index_idx i32, gen_idx i32) ImFontAtlasRectId {
	return C.igImFontAtlasRectId_Make(index_idx, gen_idx)
}

@[keep_args_alive]
fn C.ImFontAtlasBuilder_ImFontAtlasBuilder() &ImFontAtlasBuilder

@[inline]
pub fn im_font_atlas_builder_im_font_atlas_builder() &ImFontAtlasBuilder {
	return C.ImFontAtlasBuilder_ImFontAtlasBuilder()
}

@[keep_args_alive]
fn C.ImFontAtlasBuilder_destroy(self &ImFontAtlasBuilder)

@[inline]
pub fn im_font_atlas_builder_destroy(self &ImFontAtlasBuilder) {
	C.ImFontAtlasBuilder_destroy(self)
}

@[keep_args_alive]
fn C.igImFontAtlasBuildInit(atlas &ImFontAtlas)

@[inline]
pub fn im_font_atlas_build_init(atlas &ImFontAtlas) {
	C.igImFontAtlasBuildInit(atlas)
}

@[keep_args_alive]
fn C.igImFontAtlasBuildDestroy(atlas &ImFontAtlas)

@[inline]
pub fn im_font_atlas_build_destroy(atlas &ImFontAtlas) {
	C.igImFontAtlasBuildDestroy(atlas)
}

@[keep_args_alive]
fn C.igImFontAtlasBuildMain(atlas &ImFontAtlas)

@[inline]
pub fn im_font_atlas_build_main(atlas &ImFontAtlas) {
	C.igImFontAtlasBuildMain(atlas)
}

@[keep_args_alive]
fn C.igImFontAtlasBuildSetupFontLoader(atlas &ImFontAtlas, font_loader &ImFontLoader)

@[inline]
pub fn im_font_atlas_build_setup_font_loader(atlas &ImFontAtlas, font_loader &ImFontLoader) {
	C.igImFontAtlasBuildSetupFontLoader(atlas, font_loader)
}

@[keep_args_alive]
fn C.igImFontAtlasBuildNotifySetFont(atlas &ImFontAtlas, old_font &ImFont, new_font &ImFont)

@[inline]
pub fn im_font_atlas_build_notify_set_font(atlas &ImFontAtlas, old_font &ImFont, new_font &ImFont) {
	C.igImFontAtlasBuildNotifySetFont(atlas, old_font, new_font)
}

@[keep_args_alive]
fn C.igImFontAtlasBuildUpdatePointers(atlas &ImFontAtlas)

@[inline]
pub fn im_font_atlas_build_update_pointers(atlas &ImFontAtlas) {
	C.igImFontAtlasBuildUpdatePointers(atlas)
}

@[keep_args_alive]
fn C.igImFontAtlasBuildRenderBitmapFromString(atlas &ImFontAtlas, x i32, y i32, w i32, h i32, in_str &char, in_marker_char i8)

@[inline]
pub fn im_font_atlas_build_render_bitmap_from_string(atlas &ImFontAtlas, x i32, y i32, w i32, h i32, in_str &char, in_marker_char i8) {
	C.igImFontAtlasBuildRenderBitmapFromString(atlas, x, y, w, h, in_str, in_marker_char)
}

@[keep_args_alive]
fn C.igImFontAtlasBuildClear(atlas &ImFontAtlas)

@[inline]
pub fn im_font_atlas_build_clear(atlas &ImFontAtlas) {
	C.igImFontAtlasBuildClear(atlas)
}

@[keep_args_alive]
fn C.igImFontAtlasTextureAdd(atlas &ImFontAtlas, w i32, h i32) &ImTextureData

@[inline]
pub fn im_font_atlas_texture_add(atlas &ImFontAtlas, w i32, h i32) &ImTextureData {
	return C.igImFontAtlasTextureAdd(atlas, w, h)
}

@[keep_args_alive]
fn C.igImFontAtlasTextureMakeSpace(atlas &ImFontAtlas)

@[inline]
pub fn im_font_atlas_texture_make_space(atlas &ImFontAtlas) {
	C.igImFontAtlasTextureMakeSpace(atlas)
}

@[keep_args_alive]
fn C.igImFontAtlasTextureRepack(atlas &ImFontAtlas, w i32, h i32)

@[inline]
pub fn im_font_atlas_texture_repack(atlas &ImFontAtlas, w i32, h i32) {
	C.igImFontAtlasTextureRepack(atlas, w, h)
}

@[keep_args_alive]
fn C.igImFontAtlasTextureGrow(atlas &ImFontAtlas, old_w i32, old_h i32)

@[inline]
pub fn im_font_atlas_texture_grow(atlas &ImFontAtlas, old_w i32, old_h i32) {
	C.igImFontAtlasTextureGrow(atlas, old_w, old_h)
}

@[keep_args_alive]
fn C.igImFontAtlasTextureCompact(atlas &ImFontAtlas)

@[inline]
pub fn im_font_atlas_texture_compact(atlas &ImFontAtlas) {
	C.igImFontAtlasTextureCompact(atlas)
}

@[keep_args_alive]
fn C.igImFontAtlasTextureGetSizeEstimate(atlas &ImFontAtlas) ImVec2i_c

@[inline]
pub fn im_font_atlas_texture_get_size_estimate(atlas &ImFontAtlas) ImVec2i_c {
	return C.igImFontAtlasTextureGetSizeEstimate(atlas)
}

@[keep_args_alive]
fn C.igImFontAtlasBuildSetupFontSpecialGlyphs(atlas &ImFontAtlas, font &ImFont, src &ImFontConfig)

@[inline]
pub fn im_font_atlas_build_setup_font_special_glyphs(atlas &ImFontAtlas, font &ImFont, src &ImFontConfig) {
	C.igImFontAtlasBuildSetupFontSpecialGlyphs(atlas, font, src)
}

@[keep_args_alive]
fn C.igImFontAtlasBuildLegacyPreloadAllGlyphRanges(atlas &ImFontAtlas)

@[inline]
pub fn im_font_atlas_build_legacy_preload_all_glyph_ranges(atlas &ImFontAtlas) {
	C.igImFontAtlasBuildLegacyPreloadAllGlyphRanges(atlas)
}

@[keep_args_alive]
fn C.igImFontAtlasBuildGetOversampleFactors(src &ImFontConfig, baked &ImFontBaked, out_oversample_h &i32, out_oversample_v &i32)

@[inline]
pub fn im_font_atlas_build_get_oversample_factors(src &ImFontConfig, baked &ImFontBaked, out_oversample_h &i32, out_oversample_v &i32) {
	C.igImFontAtlasBuildGetOversampleFactors(src, baked, out_oversample_h, out_oversample_v)
}

@[keep_args_alive]
fn C.igImFontAtlasBuildDiscardBakes(atlas &ImFontAtlas, unused_frames i32)

@[inline]
pub fn im_font_atlas_build_discard_bakes(atlas &ImFontAtlas, unused_frames i32) {
	C.igImFontAtlasBuildDiscardBakes(atlas, unused_frames)
}

@[keep_args_alive]
fn C.igImFontAtlasFontSourceInit(atlas &ImFontAtlas, src &ImFontConfig) bool

@[inline]
pub fn im_font_atlas_font_source_init(atlas &ImFontAtlas, src &ImFontConfig) bool {
	return C.igImFontAtlasFontSourceInit(atlas, src)
}

@[keep_args_alive]
fn C.igImFontAtlasFontSourceAddToFont(atlas &ImFontAtlas, font &ImFont, src &ImFontConfig)

@[inline]
pub fn im_font_atlas_font_source_add_to_font(atlas &ImFontAtlas, font &ImFont, src &ImFontConfig) {
	C.igImFontAtlasFontSourceAddToFont(atlas, font, src)
}

@[keep_args_alive]
fn C.igImFontAtlasFontDestroySourceData(atlas &ImFontAtlas, src &ImFontConfig)

@[inline]
pub fn im_font_atlas_font_destroy_source_data(atlas &ImFontAtlas, src &ImFontConfig) {
	C.igImFontAtlasFontDestroySourceData(atlas, src)
}

@[keep_args_alive]
fn C.igImFontAtlasFontInitOutput(atlas &ImFontAtlas, font &ImFont) bool

@[inline]
pub fn im_font_atlas_font_init_output(atlas &ImFontAtlas, font &ImFont) bool {
	return C.igImFontAtlasFontInitOutput(atlas, font)
}

@[keep_args_alive]
fn C.igImFontAtlasFontDestroyOutput(atlas &ImFontAtlas, font &ImFont)

@[inline]
pub fn im_font_atlas_font_destroy_output(atlas &ImFontAtlas, font &ImFont) {
	C.igImFontAtlasFontDestroyOutput(atlas, font)
}

@[keep_args_alive]
fn C.igImFontAtlasFontRebuildOutput(atlas &ImFontAtlas, font &ImFont)

@[inline]
pub fn im_font_atlas_font_rebuild_output(atlas &ImFontAtlas, font &ImFont) {
	C.igImFontAtlasFontRebuildOutput(atlas, font)
}

@[keep_args_alive]
fn C.igImFontAtlasFontDiscardBakes(atlas &ImFontAtlas, font &ImFont, unused_frames i32)

@[inline]
pub fn im_font_atlas_font_discard_bakes(atlas &ImFontAtlas, font &ImFont, unused_frames i32) {
	C.igImFontAtlasFontDiscardBakes(atlas, font, unused_frames)
}

@[keep_args_alive]
fn C.igImFontAtlasBakedGetId(font_id ID, baked_size f32, rasterizer_density f32) ID

@[inline]
pub fn im_font_atlas_baked_get_id(font_id ID, baked_size f32, rasterizer_density f32) ID {
	return C.igImFontAtlasBakedGetId(font_id, baked_size, rasterizer_density)
}

@[keep_args_alive]
fn C.igImFontAtlasBakedGetOrAdd(atlas &ImFontAtlas, font &ImFont, font_size f32, font_rasterizer_density f32) &ImFontBaked

@[inline]
pub fn im_font_atlas_baked_get_or_add(atlas &ImFontAtlas, font &ImFont, font_size f32, font_rasterizer_density f32) &ImFontBaked {
	return C.igImFontAtlasBakedGetOrAdd(atlas, font, font_size, font_rasterizer_density)
}

@[keep_args_alive]
fn C.igImFontAtlasBakedGetClosestMatch(atlas &ImFontAtlas, font &ImFont, font_size f32, font_rasterizer_density f32) &ImFontBaked

@[inline]
pub fn im_font_atlas_baked_get_closest_match(atlas &ImFontAtlas, font &ImFont, font_size f32, font_rasterizer_density f32) &ImFontBaked {
	return C.igImFontAtlasBakedGetClosestMatch(atlas, font, font_size, font_rasterizer_density)
}

@[keep_args_alive]
fn C.igImFontAtlasBakedAdd(atlas &ImFontAtlas, font &ImFont, font_size f32, font_rasterizer_density f32, baked_id ID) &ImFontBaked

@[inline]
pub fn im_font_atlas_baked_add(atlas &ImFontAtlas, font &ImFont, font_size f32, font_rasterizer_density f32, baked_id ID) &ImFontBaked {
	return C.igImFontAtlasBakedAdd(atlas, font, font_size, font_rasterizer_density, baked_id)
}

@[keep_args_alive]
fn C.igImFontAtlasBakedDiscard(atlas &ImFontAtlas, font &ImFont, baked &ImFontBaked)

@[inline]
pub fn im_font_atlas_baked_discard(atlas &ImFontAtlas, font &ImFont, baked &ImFontBaked) {
	C.igImFontAtlasBakedDiscard(atlas, font, baked)
}

@[keep_args_alive]
fn C.igImFontAtlasBakedAddFontGlyph(atlas &ImFontAtlas, baked &ImFontBaked, src &ImFontConfig, in_glyph &ImFontGlyph) &ImFontGlyph

@[inline]
pub fn im_font_atlas_baked_add_font_glyph(atlas &ImFontAtlas, baked &ImFontBaked, src &ImFontConfig, in_glyph &ImFontGlyph) &ImFontGlyph {
	return C.igImFontAtlasBakedAddFontGlyph(atlas, baked, src, in_glyph)
}

@[keep_args_alive]
fn C.igImFontAtlasBakedAddFontGlyphAdvancedX(atlas &ImFontAtlas, baked &ImFontBaked, src &ImFontConfig, codepoint ImWchar, advance_x f32)

@[inline]
pub fn im_font_atlas_baked_add_font_glyph_advanced_x(atlas &ImFontAtlas, baked &ImFontBaked, src &ImFontConfig, codepoint ImWchar, advance_x f32) {
	C.igImFontAtlasBakedAddFontGlyphAdvancedX(atlas, baked, src, codepoint, advance_x)
}

@[keep_args_alive]
fn C.igImFontAtlasBakedDiscardFontGlyph(atlas &ImFontAtlas, font &ImFont, baked &ImFontBaked, glyph &ImFontGlyph)

@[inline]
pub fn im_font_atlas_baked_discard_font_glyph(atlas &ImFontAtlas, font &ImFont, baked &ImFontBaked, glyph &ImFontGlyph) {
	C.igImFontAtlasBakedDiscardFontGlyph(atlas, font, baked, glyph)
}

@[keep_args_alive]
fn C.igImFontAtlasBakedSetFontGlyphBitmap(atlas &ImFontAtlas, baked &ImFontBaked, src &ImFontConfig, glyph &ImFontGlyph, r &ImTextureRect, src_pixels &u8, src_fmt ImTextureFormat, src_pitch i32)

@[inline]
pub fn im_font_atlas_baked_set_font_glyph_bitmap(atlas &ImFontAtlas, baked &ImFontBaked, src &ImFontConfig, glyph &ImFontGlyph, r &ImTextureRect, src_pixels &u8, src_fmt ImTextureFormat, src_pitch i32) {
	C.igImFontAtlasBakedSetFontGlyphBitmap(atlas, baked, src, glyph, r, src_pixels, src_fmt,
		src_pitch)
}

@[keep_args_alive]
fn C.igImFontAtlasPackInit(atlas &ImFontAtlas)

@[inline]
pub fn im_font_atlas_pack_init(atlas &ImFontAtlas) {
	C.igImFontAtlasPackInit(atlas)
}

@[keep_args_alive]
fn C.igImFontAtlasPackAddRect(atlas &ImFontAtlas, w i32, h i32, overwrite_entry &ImFontAtlasRectEntry) ImFontAtlasRectId

@[inline]
pub fn im_font_atlas_pack_add_rect(atlas &ImFontAtlas, w i32, h i32, overwrite_entry &ImFontAtlasRectEntry) ImFontAtlasRectId {
	return C.igImFontAtlasPackAddRect(atlas, w, h, overwrite_entry)
}

@[keep_args_alive]
fn C.igImFontAtlasPackGetRect(atlas &ImFontAtlas, id ImFontAtlasRectId) &ImTextureRect

@[inline]
pub fn im_font_atlas_pack_get_rect(atlas &ImFontAtlas, id ImFontAtlasRectId) &ImTextureRect {
	return C.igImFontAtlasPackGetRect(atlas, id)
}

@[keep_args_alive]
fn C.igImFontAtlasPackGetRectSafe(atlas &ImFontAtlas, id ImFontAtlasRectId) &ImTextureRect

@[inline]
pub fn im_font_atlas_pack_get_rect_safe(atlas &ImFontAtlas, id ImFontAtlasRectId) &ImTextureRect {
	return C.igImFontAtlasPackGetRectSafe(atlas, id)
}

@[keep_args_alive]
fn C.igImFontAtlasPackDiscardRect(atlas &ImFontAtlas, id ImFontAtlasRectId)

@[inline]
pub fn im_font_atlas_pack_discard_rect(atlas &ImFontAtlas, id ImFontAtlasRectId) {
	C.igImFontAtlasPackDiscardRect(atlas, id)
}

@[keep_args_alive]
fn C.igImFontAtlasUpdateNewFrame(atlas &ImFontAtlas, frame_count i32, renderer_has_textures bool)

@[inline]
pub fn im_font_atlas_update_new_frame(atlas &ImFontAtlas, frame_count i32, renderer_has_textures bool) {
	C.igImFontAtlasUpdateNewFrame(atlas, frame_count, renderer_has_textures)
}

@[keep_args_alive]
fn C.igImFontAtlasAddDrawListSharedData(atlas &ImFontAtlas, data &ImDrawListSharedData)

@[inline]
pub fn im_font_atlas_add_draw_list_shared_data(atlas &ImFontAtlas, data &ImDrawListSharedData) {
	C.igImFontAtlasAddDrawListSharedData(atlas, data)
}

@[keep_args_alive]
fn C.igImFontAtlasRemoveDrawListSharedData(atlas &ImFontAtlas, data &ImDrawListSharedData)

@[inline]
pub fn im_font_atlas_remove_draw_list_shared_data(atlas &ImFontAtlas, data &ImDrawListSharedData) {
	C.igImFontAtlasRemoveDrawListSharedData(atlas, data)
}

@[keep_args_alive]
fn C.igImFontAtlasUpdateDrawListsTextures(atlas &ImFontAtlas, old_tex ImTextureRef_c, new_tex ImTextureRef_c)

@[inline]
pub fn im_font_atlas_update_draw_lists_textures(atlas &ImFontAtlas, old_tex ImTextureRef_c, new_tex ImTextureRef_c) {
	C.igImFontAtlasUpdateDrawListsTextures(atlas, old_tex, new_tex)
}

@[keep_args_alive]
fn C.igImFontAtlasUpdateDrawListsSharedData(atlas &ImFontAtlas)

@[inline]
pub fn im_font_atlas_update_draw_lists_shared_data(atlas &ImFontAtlas) {
	C.igImFontAtlasUpdateDrawListsSharedData(atlas)
}

@[keep_args_alive]
fn C.igImFontAtlasTextureBlockConvert(src_pixels &u8, src_fmt ImTextureFormat, src_pitch i32, dst_pixels &u8, dst_fmt ImTextureFormat, dst_pitch i32, w i32, h i32)

@[inline]
pub fn im_font_atlas_texture_block_convert(src_pixels &u8, src_fmt ImTextureFormat, src_pitch i32, dst_pixels &u8, dst_fmt ImTextureFormat, dst_pitch i32, w i32, h i32) {
	C.igImFontAtlasTextureBlockConvert(src_pixels, src_fmt, src_pitch, dst_pixels, dst_fmt,
		dst_pitch, w, h)
}

@[keep_args_alive]
fn C.igImFontAtlasTextureBlockPostProcess(data &ImFontAtlasPostProcessData)

@[inline]
pub fn im_font_atlas_texture_block_post_process(data &ImFontAtlasPostProcessData) {
	C.igImFontAtlasTextureBlockPostProcess(data)
}

@[keep_args_alive]
fn C.igImFontAtlasTextureBlockPostProcessMultiply(data &ImFontAtlasPostProcessData, multiply_factor f32)

@[inline]
pub fn im_font_atlas_texture_block_post_process_multiply(data &ImFontAtlasPostProcessData, multiply_factor f32) {
	C.igImFontAtlasTextureBlockPostProcessMultiply(data, multiply_factor)
}

@[keep_args_alive]
fn C.igImFontAtlasTextureBlockFill(dst_tex &ImTextureData, dst_x i32, dst_y i32, w i32, h i32, col ImU32)

@[inline]
pub fn im_font_atlas_texture_block_fill(dst_tex &ImTextureData, dst_x i32, dst_y i32, w i32, h i32, col ImU32) {
	C.igImFontAtlasTextureBlockFill(dst_tex, dst_x, dst_y, w, h, col)
}

@[keep_args_alive]
fn C.igImFontAtlasTextureBlockCopy(src_tex &ImTextureData, src_x i32, src_y i32, dst_tex &ImTextureData, dst_x i32, dst_y i32, w i32, h i32)

@[inline]
pub fn im_font_atlas_texture_block_copy(src_tex &ImTextureData, src_x i32, src_y i32, dst_tex &ImTextureData, dst_x i32, dst_y i32, w i32, h i32) {
	C.igImFontAtlasTextureBlockCopy(src_tex, src_x, src_y, dst_tex, dst_x, dst_y, w, h)
}

@[keep_args_alive]
fn C.igImFontAtlasTextureBlockQueueUpload(atlas &ImFontAtlas, tex &ImTextureData, x i32, y i32, w i32, h i32)

@[inline]
pub fn im_font_atlas_texture_block_queue_upload(atlas &ImFontAtlas, tex &ImTextureData, x i32, y i32, w i32, h i32) {
	C.igImFontAtlasTextureBlockQueueUpload(atlas, tex, x, y, w, h)
}

@[keep_args_alive]
fn C.igImTextureDataGetFormatBytesPerPixel(format ImTextureFormat) i32

@[inline]
pub fn im_texture_data_get_format_bytes_per_pixel(format ImTextureFormat) i32 {
	return C.igImTextureDataGetFormatBytesPerPixel(format)
}

@[keep_args_alive]
fn C.igImTextureDataGetStatusName(status ImTextureStatus) &char

@[inline]
pub fn im_texture_data_get_status_name(status ImTextureStatus) &char {
	return C.igImTextureDataGetStatusName(status)
}

@[keep_args_alive]
fn C.igImTextureDataGetFormatName(format ImTextureFormat) &char

@[inline]
pub fn im_texture_data_get_format_name(format ImTextureFormat) &char {
	return C.igImTextureDataGetFormatName(format)
}

@[keep_args_alive]
fn C.igImFontAtlasDebugLogTextureRequests(atlas &ImFontAtlas)

@[inline]
pub fn im_font_atlas_debug_log_texture_requests(atlas &ImFontAtlas) {
	C.igImFontAtlasDebugLogTextureRequests(atlas)
}

@[keep_args_alive]
fn C.igImFontAtlasGetMouseCursorTexData(atlas &ImFontAtlas, cursor_type MouseCursor, out_offset &ImVec2_c, out_size &ImVec2_c, out_uv_border &ImVec2, out_uv_fill &ImVec2) bool

@[inline]
pub fn im_font_atlas_get_mouse_cursor_tex_data(atlas &ImFontAtlas, cursor_type MouseCursor, out_offset &ImVec2_c, out_size &ImVec2_c, out_uv_border &ImVec2, out_uv_fill &ImVec2) bool {
	return C.igImFontAtlasGetMouseCursorTexData(atlas, cursor_type, out_offset, out_size,
		out_uv_border, out_uv_fill)
}

/////////////////////////hand written functions
// no appendfV

@[keep_args_alive]
fn C.ImGuiTextBuffer_appendf(self &TextBuffer, const_fmt &char)

@[inline]
pub fn text_buffer_appendf(self &TextBuffer, const_fmt &char) {
	C.ImGuiTextBuffer_appendf(self, const_fmt)
}

// for getting FLT_MAX in bindings

@[keep_args_alive]
fn C.igGET_FLT_MAX() f32

@[inline]
pub fn get_flt_max() f32 {
	return C.igGET_FLT_MAX()
}

// for getting FLT_MIN in bindings

@[keep_args_alive]
fn C.igGET_FLT_MIN() f32

@[inline]
pub fn get_flt_min() f32 {
	return C.igGET_FLT_MIN()
}

@[keep_args_alive]
fn C.ImVector_ImWchar_create() &ImVector_ImWchar

@[inline]
pub fn im_vector_im_wchar_create() &ImVector_ImWchar {
	return C.ImVector_ImWchar_create()
}

@[keep_args_alive]
fn C.ImVector_ImWchar_destroy(self &ImVector_ImWchar)

@[inline]
pub fn im_vector_im_wchar_destroy(self &ImVector_ImWchar) {
	C.ImVector_ImWchar_destroy(self)
}

@[keep_args_alive]
fn C.ImVector_ImWchar_Init(p &ImVector_ImWchar)

@[inline]
pub fn im_vector_im_wchar_init(p &ImVector_ImWchar) {
	C.ImVector_ImWchar_Init(p)
}

@[keep_args_alive]
fn C.ImVector_ImWchar_UnInit(p &ImVector_ImWchar)

@[inline]
pub fn im_vector_im_wchar_un_init(p &ImVector_ImWchar) {
	C.ImVector_ImWchar_UnInit(p)
}

@[keep_args_alive]
fn C.ImGuiPlatformIO_Set_Platform_GetWindowPos(platform_io &PlatformIO, user_callback fn (&Viewport, &ImVec2))

@[inline]
pub fn platform_io_set_platform_get_window_pos(platform_io &PlatformIO, user_callback fn (&Viewport, &ImVec2)) {
	C.ImGuiPlatformIO_Set_Platform_GetWindowPos(platform_io, user_callback)
}

@[keep_args_alive]
fn C.ImGuiPlatformIO_Set_Platform_GetWindowSize(platform_io &PlatformIO, user_callback fn (&Viewport, &ImVec2))

@[inline]
pub fn platform_io_set_platform_get_window_size(platform_io &PlatformIO, user_callback fn (&Viewport, &ImVec2)) {
	C.ImGuiPlatformIO_Set_Platform_GetWindowSize(platform_io, user_callback)
}

// CIMGUI_INCLUDED
