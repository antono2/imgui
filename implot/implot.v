module implot

import imgui
// C.tm is used by translated callback signatures. Keep the import explicitly.
import time as _

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
5. Remove self-module prefixes: imgui.v must not refer to imgui.Type; implot.v
   must not refer to Type, because each file is already inside that module.
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

pub type Axis = C.ImPlotAxis_c

pub type Point = C.ImPlotPoint_c

pub type Range = C.ImPlotRange_c

pub type Rect = C.ImPlotRect_c

pub type Spec = C.ImPlotSpec_c

pub type Tick = C.ImPlotTick_c

pub type Time = C.ImPlotTime_c

pub type Va_list = imgui.Va_list

// docking branch
pub type ImVector_const_charPtr = imgui.ImVector_const_charPtr

pub type ImGuiID = u32

pub type ImS8 = i8

pub type ImU8 = u8

pub type ImS16 = i16

pub type ImU16 = u16

pub type ImS32 = i32

pub type ImU32 = u32

pub type ImS64 = i64

pub type ImU64 = i64

pub type ImGuiCol = i32

pub type ImGuiCond = i32

pub type ImGuiDataType = i32

pub type ImGuiMouseButton = i32

pub type ImGuiMouseCursor = i32

pub type ImGuiStyleVar = i32

pub type ImGuiTableBgTarget = i32

pub type ImDrawFlags = i32

pub type ImDrawListFlags = i32

pub type ImDrawTextFlags = i32

pub type ImFontFlags = i32

pub type ImFontAtlasFlags = i32

pub type ImGuiBackendFlags = i32

pub type ImGuiButtonFlags = i32

pub type ImGuiChildFlags = i32

pub type ImGuiColorEditFlags = i32

pub type ImGuiConfigFlags = i32

pub type ImGuiComboFlags = i32

pub type ImGuiDockNodeFlags = i32

pub type ImGuiDragDropFlags = i32

pub type ImGuiFocusedFlags = i32

pub type ImGuiHoveredFlags = i32

pub type ImGuiInputFlags = i32

pub type ImGuiInputTextFlags = i32

pub type ImGuiItemFlags = i32

pub type ImGuiKeyChord = i32

pub type ImGuiListClipperFlags = i32

pub type ImGuiPopupFlags = i32

pub type ImGuiMultiSelectFlags = i32

pub type ImGuiSelectableFlags = i32

pub type ImGuiSliderFlags = i32

pub type ImGuiTabBarFlags = i32

pub type ImGuiTabItemFlags = i32

pub type ImGuiTableFlags = i32

pub type ImGuiTableColumnFlags = i32

pub type ImGuiTableRowFlags = i32

pub type ImGuiTreeNodeFlags = i32

pub type ImGuiViewportFlags = i32

pub type ImGuiWindowFlags = i32

pub type ImWchar32 = u32

pub type ImWchar16 = u16

pub type ImGuiSelectionUserData = i64

pub type ImGuiMemAllocFunc = fn(usize, voidptr) voidptr

pub type ImGuiMemFreeFunc = fn(voidptr, voidptr)

pub type ImVec2_c = imgui.ImVec2_c

pub type ImVec4_c = imgui.ImVec4_c

pub type ImTextureID = i64

pub type ImTextureRef_c = imgui.ImTextureRef_c


pub enum ImGuiWindowFlags_ {
 none                               = 0
 no_title_bar                       = 1 << 0
 no_resize                          = 1 << 1
 no_move                            = 1 << 2
 no_scrollbar                       = 1 << 3
 no_scroll_with_mouse               = 1 << 4
 no_collapse                        = 1 << 5
 always_auto_resize                 = 1 << 6
 no_background                      = 1 << 7
 no_saved_settings                  = 1 << 8
 no_mouse_inputs                    = 1 << 9
 menu_bar                           = 1 << 10
 horizontal_scrollbar               = 1 << 11
 no_focus_on_appearing              = 1 << 12
 no_bring_to_front_on_focus         = 1 << 13
 always_vertical_scrollbar          = 1 << 14
 always_horizontal_scrollbar        = 1 << 15
 no_nav_inputs                      = 1 << 16
 no_nav_focus                       = 1 << 17
 unsaved_document                   = 1 << 18
 no_docking                         = 1 << 19
 no_nav                             = 1 << 16 | 1 << 17
 no_decoration                      = 1 << 0 | 1 << 1 | 1 << 3 | 1 << 5
 no_inputs                          = 1 << 9 | 1 << 16 | 1 << 17
 dock_node_host                     = 1 << 23
 child_window                       = 1 << 24
 tooltip                            = 1 << 25
 popup                              = 1 << 26
 modal                              = 1 << 27
 child_menu                         = 1 << 28
}


pub enum ImGuiChildFlags_ {
 none                               = 0
 borders                            = 1 << 0
 always_use_window_padding          = 1 << 1
 resize_x                           = 1 << 2
 resize_y                           = 1 << 3
 auto_resize_x                      = 1 << 4
 auto_resize_y                      = 1 << 5
 always_auto_resize                 = 1 << 6
 frame_style                        = 1 << 7
 nav_flattened                      = 1 << 8
}


pub enum ImGuiItemFlags_ {
 none                               = 0
 no_tab_stop                        = 1 << 0
 no_nav                             = 1 << 1
 no_nav_default_focus               = 1 << 2
 button_repeat                      = 1 << 3
 auto_close_popups                  = 1 << 4
 allow_duplicate_id                 = 1 << 5
 disabled                           = 1 << 6
}


pub enum ImGuiInputTextFlags_ {
 none                               = 0
 chars_decimal                      = 1 << 0
 chars_hexadecimal                  = 1 << 1
 chars_scientific                   = 1 << 2
 chars_uppercase                    = 1 << 3
 chars_no_blank                     = 1 << 4
 allow_tab_input                    = 1 << 5
 enter_returns_true                 = 1 << 6
 escape_clears_all                  = 1 << 7
 ctrl_enter_for_new_line            = 1 << 8
 read_only                          = 1 << 9
 password                           = 1 << 10
 always_overwrite                   = 1 << 11
 auto_select_all                    = 1 << 12
 parse_empty_ref_val                = 1 << 13
 display_empty_ref_val              = 1 << 14
 no_horizontal_scroll               = 1 << 15
 no_undo_redo                       = 1 << 16
 elide_left                         = 1 << 17
 callback_completion                = 1 << 18
 callback_history                   = 1 << 19
 callback_always                    = 1 << 20
 callback_char_filter               = 1 << 21
 callback_resize                    = 1 << 22
 callback_edit                      = 1 << 23
 word_wrap                          = 1 << 24
}


pub enum ImGuiTreeNodeFlags_ {
 none                               = 0
 selected                           = 1 << 0
 framed                             = 1 << 1
 allow_overlap                      = 1 << 2
 no_tree_push_on_open               = 1 << 3
 no_auto_open_on_log                = 1 << 4
 default_open                       = 1 << 5
 open_on_double_click               = 1 << 6
 open_on_arrow                      = 1 << 7
 leaf                               = 1 << 8
 bullet                             = 1 << 9
 frame_padding                      = 1 << 10
 span_avail_width                   = 1 << 11
 span_full_width                    = 1 << 12
 span_label_width                   = 1 << 13
 span_all_columns                   = 1 << 14
 label_span_all_columns             = 1 << 15
 nav_left_jumps_to_parent           = 1 << 17
 collapsing_header                  = 1 << 1 | 1 << 3 | 1 << 4
 draw_lines_none                    = 1 << 18
 draw_lines_full                    = 1 << 19
 draw_lines_to_nodes                = 1 << 20
}


pub enum ImGuiPopupFlags_ {
 none                               = 0
 mouse_button_left                  = 1 << 2
 mouse_button_right                 = 1 << 3
 mouse_button_middle                = 1 << 2 | 1 << 3
 no_reopen                          = 1 << 5
 no_open_over_existing_popup        = 1 << 7
 no_open_over_items                 = 1 << 8
 any_popup_id                       = 1 << 10
 any_popup_level                    = 1 << 11
 any_popup                          = 1 << 10 | 1 << 11
 mouse_button_shift_                = 1 << 1
 //mouse_button_mask_ = 1 << 2 | 1 << 3
 invalid_mask_                      = 1 << 0 | 1 << 1
}


pub enum ImGuiSelectableFlags_ {
 none                               = 0
 no_auto_close_popups               = 1 << 0
 span_all_columns                   = 1 << 1
 allow_double_click                 = 1 << 2
 disabled                           = 1 << 3
 allow_overlap                      = 1 << 4
 highlight                          = 1 << 5
 select_on_nav                      = 1 << 6
}


pub enum ImGuiComboFlags_ {
 none                               = 0
 popup_align_left                   = 1 << 0
 height_small                       = 1 << 1
 height_regular                     = 1 << 2
 height_large                       = 1 << 3
 height_largest                     = 1 << 4
 no_arrow_button                    = 1 << 5
 no_preview                         = 1 << 6
 width_fit_preview                  = 1 << 7
 height_mask_                       = 1 << 1 | 1 << 2 | 1 << 3 | 1 << 4
}


pub enum ImGuiTabBarFlags_ {
 none                               = 0
 reorderable                        = 1 << 0
 auto_select_new_tabs               = 1 << 1
 tab_list_popup_button              = 1 << 2
 no_close_with_middle_mouse_button  = 1 << 3
 no_tab_list_scrolling_buttons      = 1 << 4
 no_tooltip                         = 1 << 5
 draw_selected_overline             = 1 << 6
 fitting_policy_mixed               = 1 << 7
 fitting_policy_shrink              = 1 << 8
 fitting_policy_scroll              = 1 << 9
 fitting_policy_mask_               = 1 << 7 | 1 << 8 | 1 << 9
 //fitting_policy_default_ = 1 << 7
}


pub enum ImGuiTabItemFlags_ {
 none                               = 0
 unsaved_document                   = 1 << 0
 set_selected                       = 1 << 1
 no_close_with_middle_mouse_button  = 1 << 2
 no_push_id                         = 1 << 3
 no_tooltip                         = 1 << 4
 no_reorder                         = 1 << 5
 leading                            = 1 << 6
 trailing                           = 1 << 7
 no_assumed_closure                 = 1 << 8
}


pub enum ImGuiFocusedFlags_ {
 none                               = 0
 child_windows                      = 1 << 0
 root_window                        = 1 << 1
 any_window                         = 1 << 2
 no_popup_hierarchy                 = 1 << 3
 dock_hierarchy                     = 1 << 4
 root_and_child_windows             = 1 << 0 | 1 << 1
}


pub enum ImGuiHoveredFlags_ {
 none                               = 0
 child_windows                      = 1 << 0
 root_window                        = 1 << 1
 any_window                         = 1 << 2
 no_popup_hierarchy                 = 1 << 3
 dock_hierarchy                     = 1 << 4
 allow_when_blocked_by_popup        = 1 << 5
 allow_when_blocked_by_active_item  = 1 << 7
 allow_when_overlapped_by_item      = 1 << 8
 allow_when_overlapped_by_window    = 1 << 9
 allow_when_disabled                = 1 << 10
 no_nav_override                    = 1 << 11
 allow_when_overlapped              = 1 << 8 | 1 << 9
 rect_only                          = 1 << 5 | 1 << 7 | 1 << 8 | 1 << 9
 root_and_child_windows             = 1 << 0 | 1 << 1
 for_tooltip                        = 1 << 12
 stationary                         = 1 << 13
 delay_none                         = 1 << 14
 delay_short                        = 1 << 15
 delay_normal                       = 1 << 16
 no_shared_delay                    = 1 << 17
}


pub enum ImGuiDockNodeFlags_ {
 none                               = 0
 keep_alive_only                    = 1 << 0
 no_docking_over_central_node       = 1 << 2
 passthru_central_node              = 1 << 3
 no_docking_split                   = 1 << 4
 no_resize                          = 1 << 5
 auto_hide_tab_bar                  = 1 << 6
 no_undocking                       = 1 << 7
}


pub enum ImGuiDragDropFlags_ {
 none                               = 0
 source_no_preview_tooltip          = 1 << 0
 source_no_disable_hover            = 1 << 1
 source_no_hold_to_open_others      = 1 << 2
 source_allow_null_id               = 1 << 3
 source_extern                      = 1 << 4
 payload_auto_expire                = 1 << 5
 payload_no_cross_context           = 1 << 6
 payload_no_cross_process           = 1 << 7
 accept_before_delivery             = 1 << 10
 accept_no_draw_default_rect        = 1 << 11
 accept_no_preview_tooltip          = 1 << 12
 accept_draw_as_hovered             = 1 << 13
 accept_peek_only                   = 1 << 10 | 1 << 11
}


pub enum ImGuiDataType_ {
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


pub enum ImGuiDir {
 none                               = -1
 left                               = 0
 right                              = 1
 up                                 = 2
 down                               = 3
 count                              = 4
}


pub enum ImGuiSortDirection {
 none                               = 0
 ascending                          = 1
 descending                         = 2
}


pub enum ImGuiKey {
 none                               = 0
 named_key_begin                    = 512
 //tab = 512
 left_arrow                         = 513
 right_arrow                        = 514
 up_arrow                           = 515
 down_arrow                         = 516
 page_up                            = 517
 page_down                          = 518
 home                               = 519
 end                                = 520
 insert                             = 521
 delete                             = 522
 backspace                          = 523
 space                              = 524
 enter                              = 525
 escape                             = 526
 left_ctrl                          = 527
 left_shift                         = 528
 left_alt                           = 529
 left_super                         = 530
 right_ctrl                         = 531
 right_shift                        = 532
 right_alt                          = 533
 right_super                        = 534
 menu                               = 535
 _0                                 = 536
 _1                                 = 537
 _2                                 = 538
 _3                                 = 539
 _4                                 = 540
 _5                                 = 541
 _6                                 = 542
 _7                                 = 543
 _8                                 = 544
 _9                                 = 545
 a                                  = 546
 b                                  = 547
 c                                  = 548
 d                                  = 549
 e                                  = 550
 f                                  = 551
 g                                  = 552
 h                                  = 553
 i                                  = 554
 j                                  = 555
 k                                  = 556
 l                                  = 557
 m                                  = 558
 n                                  = 559
 o                                  = 560
 p                                  = 561
 q                                  = 562
 r                                  = 563
 s                                  = 564
 t                                  = 565
 u                                  = 566
 v                                  = 567
 w                                  = 568
 x                                  = 569
 y                                  = 570
 z                                  = 571
 f1                                 = 572
 f2                                 = 573
 f3                                 = 574
 f4                                 = 575
 f5                                 = 576
 f6                                 = 577
 f7                                 = 578
 f8                                 = 579
 f9                                 = 580
 f10                                = 581
 f11                                = 582
 f12                                = 583
 f13                                = 584
 f14                                = 585
 f15                                = 586
 f16                                = 587
 f17                                = 588
 f18                                = 589
 f19                                = 590
 f20                                = 591
 f21                                = 592
 f22                                = 593
 f23                                = 594
 f24                                = 595
 apostrophe                         = 596
 comma                              = 597
 minus                              = 598
 period                             = 599
 slash                              = 600
 semicolon                          = 601
 equal                              = 602
 left_bracket                       = 603
 backslash                          = 604
 right_bracket                      = 605
 grave_accent                       = 606
 caps_lock                          = 607
 scroll_lock                        = 608
 num_lock                           = 609
 print_screen                       = 610
 pause                              = 611
 keypad0                            = 612
 keypad1                            = 613
 keypad2                            = 614
 keypad3                            = 615
 keypad4                            = 616
 keypad5                            = 617
 keypad6                            = 618
 keypad7                            = 619
 keypad8                            = 620
 keypad9                            = 621
 keypad_decimal                     = 622
 keypad_divide                      = 623
 keypad_multiply                    = 624
 keypad_subtract                    = 625
 keypad_add                         = 626
 keypad_enter                       = 627
 keypad_equal                       = 628
 app_back                           = 629
 app_forward                        = 630
 oem102                             = 631
 gamepad_start                      = 632
 gamepad_back                       = 633
 gamepad_face_left                  = 634
 gamepad_face_right                 = 635
 gamepad_face_up                    = 636
 gamepad_face_down                  = 637
 gamepad_dpad_left                  = 638
 gamepad_dpad_right                 = 639
 gamepad_dpad_up                    = 640
 gamepad_dpad_down                  = 641
 gamepad_l1                         = 642
 gamepad_r1                         = 643
 gamepad_l2                         = 644
 gamepad_r2                         = 645
 gamepad_l3                         = 646
 gamepad_r3                         = 647
 gamepad_ls_tick_left               = 648
 gamepad_ls_tick_right              = 649
 gamepad_ls_tick_up                 = 650
 gamepad_ls_tick_down               = 651
 gamepad_rs_tick_left               = 652
 gamepad_rs_tick_right              = 653
 gamepad_rs_tick_up                 = 654
 gamepad_rs_tick_down               = 655
 mouse_left                         = 656
 mouse_right                        = 657
 mouse_middle                       = 658
 mouse_x1                           = 659
 mouse_x2                           = 660
 mouse_wheel_x                      = 661
 mouse_wheel_y                      = 662
 reserved_for_mod_ctrl              = 663
 reserved_for_mod_shift             = 664
 reserved_for_mod_alt               = 665
 reserved_for_mod_super             = 666
 named_key_end                      = 667
 named_key_count                    = 155
 //im_gui_mod_none = 0
 im_gui_mod_ctrl                    = 4096
 im_gui_mod_shift                   = 8192
 im_gui_mod_alt                     = 16384
 im_gui_mod_super                   = 32768
 im_gui_mod_mask_                   = 61440
}


pub enum ImGuiInputFlags_ {
 none                               = 0
 repeat                             = 1 << 0
 route_active                       = 1 << 10
 route_focused                      = 1 << 11
 route_global                       = 1 << 12
 route_always                       = 1 << 13
 route_over_focused                 = 1 << 14
 route_over_active                  = 1 << 15
 route_unless_bg_focused            = 1 << 16
 route_from_root_window             = 1 << 17
 tooltip                            = 1 << 18
}


pub enum ImGuiConfigFlags_ {
 none                               = 0
 nav_enable_keyboard                = 1 << 0
 nav_enable_gamepad                 = 1 << 1
 no_mouse                           = 1 << 4
 no_mouse_cursor_change             = 1 << 5
 no_keyboard                        = 1 << 6
 docking_enable                     = 1 << 7
 viewports_enable                   = 1 << 10
 is_srgb                            = 1 << 20
 is_touch_screen                    = 1 << 21
}


pub enum ImGuiBackendFlags_ {
 none                               = 0
 has_gamepad                        = 1 << 0
 has_mouse_cursors                  = 1 << 1
 has_set_mouse_pos                  = 1 << 2
 renderer_has_vtx_offset            = 1 << 3
 renderer_has_textures              = 1 << 4
 renderer_has_viewports             = 1 << 10
 platform_has_viewports             = 1 << 11
 has_mouse_hovered_viewport         = 1 << 12
 has_parent_viewport                = 1 << 13
}


pub enum ImGuiCol_ {
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


pub enum ImGuiStyleVar_ {
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


pub enum ImGuiButtonFlags_ {
 none                               = 0
 mouse_button_left                  = 1 << 0
 mouse_button_right                 = 1 << 1
 mouse_button_middle                = 1 << 2
 mouse_button_mask_                 = 1 << 0 | 1 << 1 | 1 << 2
 enable_nav                         = 1 << 3
 allow_overlap                      = 1 << 12
}


pub enum ImGuiColorEditFlags_ {
 none                               = 0
 no_alpha                           = 1 << 1
 no_picker                          = 1 << 2
 no_options                         = 1 << 3
 no_small_preview                   = 1 << 4
 no_inputs                          = 1 << 5
 no_tooltip                         = 1 << 6
 no_label                           = 1 << 7
 no_side_preview                    = 1 << 8
 no_drag_drop                       = 1 << 9
 no_border                          = 1 << 10
 no_color_markers                   = 1 << 11
 alpha_opaque                       = 1 << 12
 alpha_no_bg                        = 1 << 13
 alpha_preview_half                 = 1 << 14
 alpha_bar                          = 1 << 18
 hdr                                = 1 << 19
 display_rgb                        = 1 << 20
 display_hsv                        = 1 << 21
 display_hex                        = 1 << 22
 uint8                              = 1 << 23
 float                              = 1 << 24
 picker_hue_bar                     = 1 << 25
 picker_hue_wheel                   = 1 << 26
 input_rgb                          = 1 << 27
 input_hsv                          = 1 << 28
 default_options_                   = 1 << 20 | 1 << 23 | 1 << 25 | 1 << 27
 alpha_mask_                        = 1 << 1 | 1 << 12 | 1 << 13 | 1 << 14
 display_mask_                      = 1 << 20 | 1 << 21 | 1 << 22
 data_type_mask_                    = 1 << 23 | 1 << 24
 picker_mask_                       = 1 << 25 | 1 << 26
 input_mask_                        = 1 << 27 | 1 << 28
}


pub enum ImGuiSliderFlags_ {
 none                               = 0
 logarithmic                        = 1 << 5
 no_round_to_format                 = 1 << 6
 no_input                           = 1 << 7
 wrap_around                        = 1 << 8
 clamp_on_input                     = 1 << 9
 clamp_zero_range                   = 1 << 10
 no_speed_tweaks                    = 1 << 11
 color_markers                      = 1 << 12
 always_clamp                       = 1 << 9 | 1 << 10
 invalid_mask_                      = 1 << 0 | 1 << 1 | 1 << 2 | 1 << 3 | 1 << 28 | 1 << 29 | 1 << 30
}


pub enum ImGuiMouseButton_ {
 left                               = 0
 right                              = 1
 middle                             = 2
 count                              = 5
}


pub enum ImGuiMouseCursor_ {
 none                               = -1
 arrow                              = 0
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


pub enum ImGuiMouseSource {
 mouse                              = 0
 touch_screen                       = 1
 pen                                = 2
 count                              = 3
}


pub enum ImGuiCond_ {
 none                               = 0
 always                             = 1
 once                               = 2
 first_use_ever                     = 4
 appearing                          = 8
}


pub enum ImGuiTableFlags_ {
 none                               = 0
 resizable                          = 1 << 0
 reorderable                        = 1 << 1
 hideable                           = 1 << 2
 sortable                           = 1 << 3
 no_saved_settings                  = 1 << 4
 context_menu_in_body               = 1 << 5
 row_bg                             = 1 << 6
 borders_inner_h                    = 1 << 7
 borders_outer_h                    = 1 << 8
 borders_inner_v                    = 1 << 9
 borders_outer_v                    = 1 << 10
 borders_h                          = 1 << 7 | 1 << 8
 borders_v                          = 1 << 9 | 1 << 10
 borders_inner                      = 1 << 7 | 1 << 9
 borders_outer                      = 1 << 8 | 1 << 10
 borders                            = 1 << 7 | 1 << 8 | 1 << 9 | 1 << 10
 no_borders_in_body                 = 1 << 11
 no_borders_in_body_until_resize    = 1 << 12
 sizing_fixed_fit                   = 1 << 13
 sizing_fixed_same                  = 1 << 14
 sizing_stretch_prop                = 1 << 13 | 1 << 14
 sizing_stretch_same                = 1 << 15
 no_host_extend_x                   = 1 << 16
 no_host_extend_y                   = 1 << 17
 no_keep_columns_visible            = 1 << 18
 precise_widths                     = 1 << 19
 no_clip                            = 1 << 20
 pad_outer_x                        = 1 << 21
 no_pad_outer_x                     = 1 << 22
 no_pad_inner_x                     = 1 << 23
 scroll_x                           = 1 << 24
 scroll_y                           = 1 << 25
 sort_multi                         = 1 << 26
 sort_tristate                      = 1 << 27
 highlight_hovered_column           = 1 << 28
 sizing_mask_                       = 1 << 13 | 1 << 14 | 1 << 15
}


pub enum ImGuiTableColumnFlags_ {
 none                               = 0
 disabled                           = 1 << 0
 default_hide                       = 1 << 1
 default_sort                       = 1 << 2
 width_stretch                      = 1 << 3
 width_fixed                        = 1 << 4
 no_resize                          = 1 << 5
 no_reorder                         = 1 << 6
 no_hide                            = 1 << 7
 no_clip                            = 1 << 8
 no_sort                            = 1 << 9
 no_sort_ascending                  = 1 << 10
 no_sort_descending                 = 1 << 11
 no_header_label                    = 1 << 12
 no_header_width                    = 1 << 13
 prefer_sort_ascending              = 1 << 14
 prefer_sort_descending             = 1 << 15
 indent_enable                      = 1 << 16
 indent_disable                     = 1 << 17
 angled_header                      = 1 << 18
 is_enabled                         = 1 << 24
 is_visible                         = 1 << 25
 is_sorted                          = 1 << 26
 is_hovered                         = 1 << 27
 width_mask_                        = 1 << 3 | 1 << 4
 indent_mask_                       = 1 << 16 | 1 << 17
 status_mask_                       = 1 << 24 | 1 << 25 | 1 << 26 | 1 << 27
 no_direct_resize_                  = 1 << 30
}


pub enum ImGuiTableRowFlags_ {
 none                               = 0
 headers                            = 1 << 0
}


pub enum ImGuiTableBgTarget_ {
 none                               = 0
 row_bg0                            = 1
 row_bg1                            = 2
 cell_bg                            = 3
}

pub type ImGuiTableSortSpecs = imgui.TableSortSpecs

pub type ImGuiTableColumnSortSpecs = imgui.TableColumnSortSpecs

pub type ImGuiStyle = imgui.Style

pub type ImGuiKeyData = imgui.KeyData

pub type ImVector_ImWchar = imgui.ImVector_ImWchar

pub type ImGuiIO = imgui.IO

pub type ImGuiInputTextCallbackData = imgui.InputTextCallbackData

pub type ImGuiSizeCallbackData = imgui.SizeCallbackData

pub type ImGuiWindowClass = imgui.WindowClass

pub type ImGuiPayload = imgui.Payload

pub type ImGuiOnceUponAFrame = imgui.OnceUponAFrame

pub type ImGuiTextRange = imgui.TextRange

pub type ImVector_ImGuiTextRange = imgui.ImVector_TextRange

pub type ImVector_char = imgui.ImVector_char

pub type ImGuiTextBuffer = imgui.TextBuffer

pub type ImGuiStoragePair = imgui.StoragePair

pub type ImVector_ImGuiStoragePair = imgui.ImVector_StoragePair

pub type ImGuiStorage = imgui.Storage


pub enum ImGuiListClipperFlags_ {
 none                               = 0
 no_set_table_row_counters          = 1 << 0
}

pub type ImGuiListClipper = imgui.ListClipper

pub type ImColor_c = imgui.ImColor_c


pub enum ImGuiMultiSelectFlags_ {
 none                               = 0
 single_select                      = 1 << 0
 no_select_all                      = 1 << 1
 no_range_select                    = 1 << 2
 no_auto_select                     = 1 << 3
 no_auto_clear                      = 1 << 4
 no_auto_clear_on_reselect          = 1 << 5
 box_select1d                       = 1 << 6
 box_select2d                       = 1 << 7
 box_select_no_scroll               = 1 << 8
 clear_on_escape                    = 1 << 9
 clear_on_click_void                = 1 << 10
 scope_window                       = 1 << 11
 scope_rect                         = 1 << 12
 select_on_auto                     = 1 << 13
 select_on_click_always             = 1 << 14
 select_on_click_release            = 1 << 15
 nav_wrap_x                         = 1 << 16
 no_select_on_right_click           = 1 << 17
 select_on_mask_                    = 1 << 13 | 1 << 14 | 1 << 15
}

pub type ImVector_ImGuiSelectionRequest = imgui.ImVector_SelectionRequest

pub type ImGuiMultiSelectIO = imgui.MultiSelectIO


pub enum ImGuiSelectionRequestType {
 none                               = 0
 set_all
 set_range
}

pub type ImGuiSelectionRequest = imgui.SelectionRequest

pub type ImGuiSelectionBasicStorage = imgui.SelectionBasicStorage

pub type ImGuiSelectionExternalStorage = imgui.SelectionExternalStorage

pub type ImDrawIdx = u16

pub type ImDrawCallback = fn(&imgui.ImDrawList, &imgui.ImDrawCmd)

pub type ImDrawCmd = imgui.ImDrawCmd

pub type ImDrawVert = imgui.ImDrawVert

pub type ImDrawCmdHeader = imgui.ImDrawCmdHeader

pub type ImVector_ImDrawCmd = imgui.ImVector_ImDrawCmd

pub type ImVector_ImDrawIdx = imgui.ImVector_ImDrawIdx

pub type ImDrawChannel = imgui.ImDrawChannel

pub type ImVector_ImDrawChannel = imgui.ImVector_ImDrawChannel

pub type ImDrawListSplitter = imgui.ImDrawListSplitter


pub enum ImDrawFlags_ {
 none                               = 0
 closed                             = 1 << 0
 round_corners_top_left             = 1 << 4
 round_corners_top_right            = 1 << 5
 round_corners_bottom_left          = 1 << 6
 round_corners_bottom_right         = 1 << 7
 round_corners_none                 = 1 << 8
 round_corners_top                  = 1 << 4 | 1 << 5
 round_corners_bottom               = 1 << 6 | 1 << 7
 round_corners_left                 = 1 << 4 | 1 << 6
 round_corners_right                = 1 << 5 | 1 << 7
 round_corners_all                  = 1 << 4 | 1 << 5 | 1 << 6 | 1 << 7
 //round_corners_default_ = 1 << 4 | 1 << 5 | 1 << 6 | 1 << 7
 round_corners_mask_                = 1 << 4 | 1 << 5 | 1 << 6 | 1 << 7 | 1 << 8
}


pub enum ImDrawListFlags_ {
 none                               = 0
 anti_aliased_lines                 = 1 << 0
 anti_aliased_lines_use_tex         = 1 << 1
 anti_aliased_fill                  = 1 << 2
 allow_vtx_offset                   = 1 << 3
}

pub type ImVector_ImDrawVert = imgui.ImVector_ImDrawVert

pub type ImVector_ImVec2 = imgui.ImVector_ImVec2

pub type ImVector_ImVec4 = imgui.ImVector_ImVec4

pub type ImVector_ImTextureRef = imgui.ImVector_ImTextureRef

pub type ImVector_ImU8 = imgui.ImVector_ImU8

pub type ImDrawList = imgui.ImDrawList

pub type ImVector_ImDrawListPtr = imgui.ImVector_ImDrawListPtr

pub type ImVector_ImTextureDataPtr = imgui.ImVector_ImTextureDataPtr

pub type ImDrawData = imgui.ImDrawData


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

pub type ImTextureRect = imgui.ImTextureRect

pub type ImVector_ImTextureRect = imgui.ImVector_ImTextureRect

pub type ImTextureData = imgui.ImTextureData

pub type ImFontConfig = imgui.ImFontConfig

pub type ImFontGlyph = imgui.ImFontGlyph

pub type ImVector_ImU32 = imgui.ImVector_ImU32

pub type ImFontGlyphRangesBuilder = imgui.ImFontGlyphRangesBuilder

pub type ImFontAtlasRectId = i32

pub type ImFontAtlasRect = imgui.ImFontAtlasRect


pub enum ImFontAtlasFlags_ {
 none                               = 0
 no_power_of_two_height             = 1 << 0
 no_mouse_cursors                   = 1 << 1
 no_baked_lines                     = 1 << 2
}

pub type ImVector_ImFontPtr = imgui.ImVector_ImFontPtr

pub type ImVector_ImFontConfig = imgui.ImVector_ImFontConfig

pub type ImVector_ImDrawListSharedDataPtr = imgui.ImVector_ImDrawListSharedDataPtr

pub type ImFontAtlas = imgui.ImFontAtlas

pub type ImVector_float = imgui.ImVector_float

pub type ImVector_ImU16 = imgui.ImVector_ImU16

pub type ImVector_ImFontGlyph = imgui.ImVector_ImFontGlyph

pub type ImFontBaked = imgui.ImFontBaked


pub enum ImFontFlags_ {
 none                               = 0
 no_load_error                      = 1 << 1
 no_load_glyphs                     = 1 << 2
 lock_baked_sizes                   = 1 << 3
}

pub type ImVector_ImFontConfigPtr = imgui.ImVector_ImFontConfigPtr

pub type ImFont = imgui.ImFont


pub enum ImGuiViewportFlags_ {
 none                               = 0
 is_platform_window                 = 1 << 0
 is_platform_monitor                = 1 << 1
 owned_by_app                       = 1 << 2
 no_decoration                      = 1 << 3
 no_task_bar_icon                   = 1 << 4
 no_focus_on_appearing              = 1 << 5
 no_focus_on_click                  = 1 << 6
 no_inputs                          = 1 << 7
 no_renderer_clear                  = 1 << 8
 no_auto_merge                      = 1 << 9
 top_most                           = 1 << 10
 can_host_other_windows             = 1 << 11
 is_minimized                       = 1 << 12
 is_focused                         = 1 << 13
}

pub type ImGuiViewport = imgui.Viewport

pub type ImVector_ImGuiPlatformMonitor = imgui.ImVector_PlatformMonitor

pub type ImVector_ImGuiViewportPtr = imgui.ImVector_ViewportPtr

pub type ImGuiPlatformIO = imgui.PlatformIO

pub type ImGuiPlatformMonitor = imgui.PlatformMonitor

pub type ImGuiPlatformImeData = imgui.PlatformImeData

pub type ImGuiDataAuthority = i32

pub type ImGuiLayoutType = i32

pub type ImGuiActivateFlags = i32

pub type ImGuiDebugLogFlags = i32

pub type ImGuiFocusRequestFlags = i32

pub type ImGuiItemStatusFlags = i32

pub type ImGuiOldColumnFlags = i32

pub type ImGuiLogFlags = i32

pub type ImGuiNavRenderCursorFlags = i32

pub type ImGuiNavMoveFlags = i32

pub type ImGuiNextItemDataFlags = i32

pub type ImGuiNextWindowDataFlags = i32

pub type ImGuiScrollFlags = i32

pub type ImGuiSeparatorFlags = i32

pub type ImGuiTextFlags = i32

pub type ImGuiTooltipFlags = i32

pub type ImGuiTypingSelectFlags = i32

pub type ImGuiWindowBgClickFlags = i32

pub type ImGuiWindowRefreshFlags = i32

pub type ImGuiTableColumnIdx = i16

pub type ImGuiTableDrawChannelIdx = u16


pub enum ImDrawTextFlags_ {
 none                               = 0
 cpu_fine_clip                      = 1 << 0
 wrap_keep_blanks                   = 1 << 1
 stop_on_new_line                   = 1 << 2
}


pub enum ImWcharClass {
 blank
 punct
 other
}

pub type ImFileHandle = &C.FILE

pub type ImVec1 = imgui.ImVec1

pub type ImVec2i_c = imgui.ImVec2i_c

pub type ImVec2ih = imgui.ImVec2ih

pub type ImRect_c = imgui.ImRect_c

pub type ImBitArrayPtr = &u32

pub type ImBitVector = imgui.ImBitVector

pub type ImPoolIdx = i32

pub type ImVector_int = imgui.ImVector_int

pub type ImGuiTextIndex = imgui.TextIndex

pub type ImDrawListSharedData = imgui.ImDrawListSharedData

pub type ImDrawDataBuilder = imgui.ImDrawDataBuilder

pub type ImFontStackData = imgui.ImFontStackData

pub type ImGuiStyleVarInfo = imgui.StyleVarInfo

pub type ImGuiColorMod = imgui.ColorMod

pub type ImGuiStyleMod = imgui.StyleMod

pub type ImGuiDataTypeStorage = imgui.DataTypeStorage

pub type ImGuiDataTypeInfo = imgui.DataTypeInfo


pub enum ImGuiDataTypePrivate_ {
 pointer                            = 12
 id
}


pub enum ImGuiItemFlagsPrivate_ {
 read_only                          = 1 << 11
 mixed_value                        = 1 << 12
 no_window_hoverable_check          = 1 << 13
 allow_overlap                      = 1 << 14
 no_nav_disable_mouse_hover         = 1 << 15
 no_mark_edited                     = 1 << 16
 no_focus                           = 1 << 17
 inputable                          = 1 << 20
 has_selection_user_data            = 1 << 21
 is_multi_select                    = 1 << 22
 default_                           = 1 << 4
}


pub enum ImGuiItemStatusFlags_ {
 none                               = 0
 hovered_rect                       = 1 << 0
 has_display_rect                   = 1 << 1
 edited                             = 1 << 2
 toggled_selection                  = 1 << 3
 toggled_open                       = 1 << 4
 has_deactivated                    = 1 << 5
 deactivated                        = 1 << 6
 hovered_window                     = 1 << 7
 visible                            = 1 << 8
 has_clip_rect                      = 1 << 9
 has_shortcut                       = 1 << 10
}


pub enum ImGuiHoveredFlagsPrivate_ {
 delay_mask_                        = 1 << 14 | 1 << 15 | 1 << 16 | 1 << 17
 allowed_mask_for_is_window_hovered = 1 << 0 | 1 << 1 | 1 << 2 | 1 << 3 | 1 << 4 | 1 << 5 | 1 << 7 | 1 << 12 | 1 << 13
 allowed_mask_for_is_item_hovered   = 1 << 5 | 1 << 7 | 1 << 8 | 1 << 9 | 1 << 10 | 1 << 11 | 1 << 12 | 1 << 13 | 1 << 14 | 1 << 15 | 1 << 16 | 1 << 17
}


pub enum ImGuiInputTextFlagsPrivate_ {
 multiline                          = 1 << 26
 temp_input                         = 1 << 27
 localize_decimal_point             = 1 << 28
}


pub enum ImGuiButtonFlagsPrivate_ {
 pressed_on_click                   = 1 << 4
 pressed_on_click_release           = 1 << 5
 pressed_on_click_release_anywhere  = 1 << 6
 pressed_on_release                 = 1 << 7
 pressed_on_double_click            = 1 << 8
 pressed_on_drag_drop_hold          = 1 << 9
 flatten_children                   = 1 << 11
 align_text_base_line               = 1 << 15
 no_key_mods_allowed                = 1 << 16
 no_holding_active_id               = 1 << 17
 no_nav_focus                       = 1 << 18
 no_hovered_on_focus                = 1 << 19
 no_set_key_owner                   = 1 << 20
 no_test_key_owner                  = 1 << 21
 no_focus                           = 1 << 22
 pressed_on_mask_                   = 1 << 4 | 1 << 5 | 1 << 6 | 1 << 7 | 1 << 8 | 1 << 9
 //pressed_on_default_ = 1 << 5
}


pub enum ImGuiComboFlagsPrivate_ {
 custom_preview                     = 1 << 20
}


pub enum ImGuiSliderFlagsPrivate_ {
 vertical                           = 1 << 20
 read_only                          = 1 << 21
}


pub enum ImGuiSelectableFlagsPrivate_ {
 no_holding_active_id               = 1 << 20
 select_on_click                    = 1 << 22
 select_on_release                  = 1 << 23
 span_avail_width                   = 1 << 24
 set_nav_id_on_hover                = 1 << 25
 no_pad_with_half_spacing           = 1 << 26
 no_set_key_owner                   = 1 << 27
}


pub enum ImGuiTreeNodeFlagsPrivate_ {
 no_nav_focus                       = 1 << 27
 clip_label_for_trailing_button     = 1 << 28
 upside_down_arrow                  = 1 << 29
 open_on_mask_                      = 1 << 6 | 1 << 7
 draw_lines_mask_                   = 1 << 18 | 1 << 19 | 1 << 20
}


pub enum ImGuiSeparatorFlags_ {
 none                               = 0
 horizontal                         = 1 << 0
 vertical                           = 1 << 1
 span_all_columns                   = 1 << 2
}


pub enum ImGuiFocusRequestFlags_ {
 none                               = 0
 restore_focused_child              = 1 << 0
 unless_below_modal                 = 1 << 1
}


pub enum ImGuiTextFlags_ {
 none                               = 0
 no_width_for_large_clipped_text    = 1 << 0
}


pub enum ImGuiTooltipFlags_ {
 none                               = 0
 override_previous                  = 1 << 1
}


pub enum ImGuiLayoutType_ {
 horizontal                         = 0
 vertical                           = 1
}


pub enum ImGuiLogFlags_ {
 none                               = 0
 output_tty                         = 1 << 0
 output_file                        = 1 << 1
 output_buffer                      = 1 << 2
 output_clipboard                   = 1 << 3
 output_mask_                       = 1 << 0 | 1 << 1 | 1 << 2 | 1 << 3
}


pub enum ImGuiAxis {
 none                               = -1
 x                                  = 0
 y                                  = 1
}


pub enum ImGuiPlotType {
 lines
 histogram
}

pub type ImGuiComboPreviewData = imgui.ComboPreviewData

pub type ImGuiGroupData = imgui.GroupData

pub type ImGuiMenuColumns = imgui.MenuColumns

pub type ImGuiInputTextDeactivatedState = imgui.InputTextDeactivatedState

pub type ImStbTexteditState = C.STB_TexteditState

pub type ImGuiInputTextState = imgui.InputTextState


pub enum ImGuiWindowRefreshFlags_ {
 none                               = 0
 try_to_avoid_refresh               = 1 << 0
 refresh_on_hover                   = 1 << 1
 refresh_on_focus                   = 1 << 2
}


pub enum ImGuiWindowBgClickFlags_ {
 none                               = 0
 move                               = 1 << 0
}


pub enum ImGuiNextWindowDataFlags_ {
 none                               = 0
 has_pos                            = 1 << 0
 has_size                           = 1 << 1
 has_content_size                   = 1 << 2
 has_collapsed                      = 1 << 3
 has_size_constraint                = 1 << 4
 has_focus                          = 1 << 5
 has_bg_alpha                       = 1 << 6
 has_scroll                         = 1 << 7
 has_window_flags                   = 1 << 8
 has_child_flags                    = 1 << 9
 has_refresh_policy                 = 1 << 10
 has_viewport                       = 1 << 11
 has_dock                           = 1 << 12
 has_window_class                   = 1 << 13
}

pub type ImGuiNextWindowData = imgui.NextWindowData


pub enum ImGuiNextItemDataFlags_ {
 none                               = 0
 has_width                          = 1 << 0
 has_open                           = 1 << 1
 has_shortcut                       = 1 << 2
 has_ref_val                        = 1 << 3
 has_storage_id                     = 1 << 4
 has_color_marker                   = 1 << 5
}

pub type ImGuiNextItemData = imgui.NextItemData

pub type ImGuiLastItemData = imgui.LastItemData

pub type ImGuiTreeNodeStackData = imgui.TreeNodeStackData

pub type ImGuiErrorRecoveryState = imgui.ErrorRecoveryState

pub type ImGuiWindowStackData = imgui.WindowStackData

pub type ImGuiShrinkWidthItem = imgui.ShrinkWidthItem

pub type ImGuiPtrOrIndex = imgui.PtrOrIndex

pub type ImGuiDeactivatedItemData = imgui.DeactivatedItemData


pub enum ImGuiPopupPositionPolicy {
 default
 combo_box
 tooltip
}

pub type ImGuiPopupData = imgui.PopupData

pub type ImBitArray_ImGuiKey_NamedKey_COUNT__lessImGuiKey_NamedKey_BEGIN = imgui.ImBitArrayForNamedKeys

pub type ImBitArrayForNamedKeys = C.ImBitArray_ImGuiKey_NamedKey_COUNT__lessImGuiKey_NamedKey_BEGIN


pub enum ImGuiInputEventType {
 none                               = 0
 mouse_pos
 mouse_wheel
 mouse_button
 mouse_viewport
 key
 text
 focus
 count
}


pub enum ImGuiInputSource {
 none                               = 0
 mouse                              = 1
 keyboard                           = 2
 gamepad                            = 3
 count                              = 4
}

pub type ImGuiInputEventMousePos = imgui.InputEventMousePos

pub type ImGuiInputEventMouseWheel = imgui.InputEventMouseWheel

pub type ImGuiInputEventMouseButton = imgui.InputEventMouseButton

pub type ImGuiInputEventMouseViewport = imgui.InputEventMouseViewport

pub type ImGuiInputEventKey = imgui.InputEventKey

pub type ImGuiInputEventText = imgui.InputEventText

pub type ImGuiInputEventAppFocused = imgui.InputEventAppFocused

pub type ImGuiInputEvent = imgui.InputEvent

pub type ImGuiKeyRoutingIndex = i16

pub type ImGuiKeyRoutingData = imgui.KeyRoutingData

pub type ImVector_ImGuiKeyRoutingData = imgui.ImVector_KeyRoutingData

pub type ImGuiKeyRoutingTable = imgui.KeyRoutingTable

pub type ImGuiKeyOwnerData = imgui.KeyOwnerData


pub enum ImGuiInputFlagsPrivate_ {
 repeat_rate_default                = 1 << 1
 repeat_rate_nav_move               = 1 << 2
 repeat_rate_nav_tweak              = 1 << 3
 repeat_until_release               = 1 << 4
 repeat_until_key_mods_change       = 1 << 5
 repeat_until_key_mods_change_from_none = 1 << 6
 repeat_until_other_key_press       = 1 << 7
 lock_this_frame                    = 1 << 20
 lock_until_release                 = 1 << 21
 cond_hovered                       = 1 << 22
 cond_active                        = 1 << 23
 cond_default_                      = 1 << 22 | 1 << 23
 repeat_rate_mask_                  = 1 << 1 | 1 << 2 | 1 << 3
 repeat_until_mask_                 = 1 << 4 | 1 << 5 | 1 << 6 | 1 << 7
 repeat_mask_                       = 1 << 0 | 1 << 1 | 1 << 2 | 1 << 3 | 1 << 4 | 1 << 5 | 1 << 6 | 1 << 7
 //cond_mask_ = 1 << 22 | 1 << 23
 route_type_mask_                   = 1 << 10 | 1 << 11 | 1 << 12 | 1 << 13
 route_options_mask_                = 1 << 14 | 1 << 15 | 1 << 16 | 1 << 17
 //supported_by_is_key_pressed = 1 << 0 | 1 << 1 | 1 << 2 | 1 << 3 | 1 << 4 | 1 << 5 | 1 << 6 | 1 << 7
 supported_by_is_mouse_clicked      = 1 << 0
 supported_by_shortcut              = 1 << 0 | 1 << 1 | 1 << 2 | 1 << 3 | 1 << 4 | 1 << 5 | 1 << 6 | 1 << 7 | 1 << 10 | 1 << 11 | 1 << 12 | 1 << 13 | 1 << 14 | 1 << 15 | 1 << 16 | 1 << 17
 supported_by_set_next_item_shortcut = 1 << 0 | 1 << 1 | 1 << 2 | 1 << 3 | 1 << 4 | 1 << 5 | 1 << 6 | 1 << 7 | 1 << 10 | 1 << 11 | 1 << 12 | 1 << 13 | 1 << 14 | 1 << 15 | 1 << 16 | 1 << 17 | 1 << 18
 supported_by_set_key_owner         = 1 << 20 | 1 << 21
 supported_by_set_item_key_owner    = 1 << 20 | 1 << 21 | 1 << 22 | 1 << 23
}

pub type ImGuiListClipperRange = imgui.ListClipperRange

pub type ImVector_ImGuiListClipperRange = imgui.ImVector_ListClipperRange

pub type ImGuiListClipperData = imgui.ListClipperData


pub enum ImGuiActivateFlags_ {
 none                               = 0
 prefer_input                       = 1 << 0
 prefer_tweak                       = 1 << 1
 try_to_preserve_state              = 1 << 2
 from_tabbing                       = 1 << 3
 from_shortcut                      = 1 << 4
 from_focus_api                     = 1 << 5
}


pub enum ImGuiScrollFlags_ {
 none                               = 0
 keep_visible_edge_x                = 1 << 0
 keep_visible_edge_y                = 1 << 1
 keep_visible_center_x              = 1 << 2
 keep_visible_center_y              = 1 << 3
 always_center_x                    = 1 << 4
 always_center_y                    = 1 << 5
 no_scroll_parent                   = 1 << 6
 mask_x_                            = 1 << 0 | 1 << 2 | 1 << 4
 mask_y_                            = 1 << 1 | 1 << 3 | 1 << 5
}


pub enum ImGuiNavRenderCursorFlags_ {
 none                               = 0
 compact                            = 1 << 1
 always_draw                        = 1 << 2
 no_rounding                        = 1 << 3
}


pub enum ImGuiNavMoveFlags_ {
 none                               = 0
 loop_x                             = 1 << 0
 loop_y                             = 1 << 1
 wrap_x                             = 1 << 2
 wrap_y                             = 1 << 3
 wrap_mask_                         = 1 << 0 | 1 << 1 | 1 << 2 | 1 << 3
 allow_current_nav_id               = 1 << 4
 also_score_visible_set             = 1 << 5
 scroll_to_edge_y                   = 1 << 6
 forwarded                          = 1 << 7
 debug_no_result                    = 1 << 8
 focus_api                          = 1 << 9
 is_tabbing                         = 1 << 10
 is_page_move                       = 1 << 11
 activate                           = 1 << 12
 no_select                          = 1 << 13
 no_set_nav_cursor_visible          = 1 << 14
 no_clear_active_id                 = 1 << 15
}


pub enum ImGuiNavLayer {
 main                               = 0
 menu                               = 1
 count
}

pub type ImGuiNavItemData = imgui.NavItemData

pub type ImGuiFocusScopeData = imgui.FocusScopeData


pub enum ImGuiTypingSelectFlags_ {
 none                               = 0
 allow_backspace                    = 1 << 0
 allow_single_char_mode             = 1 << 1
}

pub type ImGuiTypingSelectRequest = imgui.TypingSelectRequest

pub type ImGuiTypingSelectState = imgui.TypingSelectState


pub enum ImGuiOldColumnFlags_ {
 none                               = 0
 no_border                          = 1 << 0
 no_resize                          = 1 << 1
 no_preserve_widths                 = 1 << 2
 no_force_within_window             = 1 << 3
 grow_parent_contents_size          = 1 << 4
}

pub type ImGuiOldColumnData = imgui.OldColumnData

pub type ImVector_ImGuiOldColumnData = imgui.ImVector_OldColumnData

pub type ImGuiOldColumns = imgui.OldColumns

pub type ImGuiBoxSelectState = imgui.BoxSelectState

pub type ImGuiMultiSelectTempData = imgui.MultiSelectTempData

pub type ImGuiMultiSelectState = imgui.MultiSelectState


pub enum ImGuiDockNodeFlagsPrivate_ {
 dock_space                         = 1 << 10
 central_node                       = 1 << 11
 no_tab_bar                         = 1 << 12
 hidden_tab_bar                     = 1 << 13
 no_window_menu_button              = 1 << 14
 no_close_button                    = 1 << 15
 no_resize_x                        = 1 << 16
 no_resize_y                        = 1 << 17
 docked_windows_in_focus_route      = 1 << 18
 no_docking_split_other             = 1 << 19
 no_docking_over_me                 = 1 << 20
 no_docking_over_other              = 1 << 21
 no_docking_over_empty              = 1 << 22
 no_docking                         = 1 << 4 | 1 << 19 | 1 << 20 | 1 << 21 | 1 << 22
 shared_flags_inherit_mask_         = -1
 no_resize_flags_mask_              = 1 << 5 | 1 << 16 | 1 << 17
 local_flags_transfer_mask_         = 1 << 4 | 1 << 5 | 1 << 6 | 1 << 11 | 1 << 12 | 1 << 13 | 1 << 14 | 1 << 15 | 1 << 16 | 1 << 17
 saved_flags_mask_                  = 1 << 5 | 1 << 10 | 1 << 11 | 1 << 12 | 1 << 13 | 1 << 14 | 1 << 15 | 1 << 16 | 1 << 17
}


pub enum ImGuiDataAuthority_ {
 auto
 dock_node
 window
}


pub enum ImGuiDockNodeState {
 unknown
 host_window_hidden_because_single_window
 host_window_hidden_because_windows_are_resizing
 host_window_visible
}

pub type ImVector_ImGuiWindowPtr = imgui.ImVector_WindowPtr

pub type ImGuiDockNode = imgui.DockNode


pub enum ImGuiWindowDockStyleCol {
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

pub type ImGuiWindowDockStyle = imgui.WindowDockStyle

pub type ImVector_ImGuiDockRequest = imgui.ImVector_DockRequest

pub type ImVector_ImGuiDockNodeSettings = imgui.ImVector_DockNodeSettings

pub type ImGuiDockContext = imgui.DockContext

pub type ImGuiViewportP = imgui.ViewportP

pub type ImGuiWindowSettings = imgui.WindowSettings

pub type ImGuiSettingsHandler = imgui.SettingsHandler


pub enum ImGuiLocKey {
 version_str                        = 0
 table_size_one                     = 1
 table_size_all_fit                 = 2
 table_size_all_default             = 3
 table_reset_order                  = 4
 windowing_main_menu_bar            = 5
 windowing_popup                    = 6
 windowing_untitled                 = 7
 open_link_s                        = 8
 copy_link                          = 9
 docking_hide_tab_bar               = 10
 docking_hold_shift_to_dock         = 11
 docking_drag_to_undock_or_move_node = 12
 count                              = 13
}

pub type ImGuiLocEntry = imgui.LocEntry

pub type ImGuiErrorCallback = fn(&imgui.Context, voidptr, &char)


pub enum ImGuiDebugLogFlags_ {
 none                               = 0
 event_error                        = 1 << 0
 event_active_id                    = 1 << 1
 event_focus                        = 1 << 2
 event_popup                        = 1 << 3
 event_nav                          = 1 << 4
 event_clipper                      = 1 << 5
 event_selection                    = 1 << 6
 event_io                           = 1 << 7
 event_font                         = 1 << 8
 event_input_routing                = 1 << 9
 event_docking                      = 1 << 10
 event_viewport                     = 1 << 11
 event_mask_                        = 1 << 0 | 1 << 1 | 1 << 2 | 1 << 3 | 1 << 4 | 1 << 5 | 1 << 6 | 1 << 7 | 1 << 8 | 1 << 9 | 1 << 10 | 1 << 11
 output_to_tty                      = 1 << 20
 output_to_debugger                 = 1 << 21
 output_to_test_engine              = 1 << 22
}

pub type ImGuiDebugAllocEntry = imgui.DebugAllocEntry

pub type ImGuiDebugAllocInfo = imgui.DebugAllocInfo

pub type ImGuiMetricsConfig = imgui.MetricsConfig

pub type ImGuiStackLevelInfo = imgui.StackLevelInfo

pub type ImVector_ImGuiStackLevelInfo = imgui.ImVector_StackLevelInfo

pub type ImGuiDebugItemPathQuery = imgui.DebugItemPathQuery

pub type ImGuiIDStackTool = imgui.IDStackTool

pub type ImGuiContextHookCallback = fn(&imgui.Context, &imgui.ContextHook)


pub enum ImGuiContextHookType {
 new_frame_pre
 new_frame_post
 end_frame_pre
 end_frame_post
 render_pre
 render_post
 shutdown
 pending_removal_
}

pub type ImGuiContextHook = imgui.ContextHook

pub type ImGuiDemoMarkerCallback = fn(&char, i32, &char)

pub type ImVector_ImFontAtlasPtr = imgui.ImVector_ImFontAtlasPtr

pub type ImVector_ImGuiInputEvent = imgui.ImVector_InputEvent

pub type ImVector_ImGuiWindowStackData = imgui.ImVector_WindowStackData

pub type ImVector_ImGuiColorMod = imgui.ImVector_ColorMod

pub type ImVector_ImGuiStyleMod = imgui.ImVector_StyleMod

pub type ImVector_ImFontStackData = imgui.ImVector_ImFontStackData

pub type ImVector_ImGuiFocusScopeData = imgui.ImVector_FocusScopeData

pub type ImVector_ImGuiItemFlags = imgui.ImVector_ItemFlags

pub type ImVector_ImGuiGroupData = imgui.ImVector_GroupData

pub type ImVector_ImGuiPopupData = imgui.ImVector_PopupData

pub type ImVector_ImGuiTreeNodeStackData = imgui.ImVector_TreeNodeStackData

pub type ImVector_ImGuiViewportPPtr = imgui.ImVector_ViewportPPtr

pub type ImVector_unsigned_char = imgui.ImVector_unsigned_char

pub type ImVector_ImGuiListClipperData = imgui.ImVector_ListClipperData

pub type ImVector_ImGuiTableTempData = imgui.ImVector_TableTempData

pub type ImVector_ImGuiTable = imgui.ImVector_Table

pub type ImPool_ImGuiTable = imgui.ImPool_Table

pub type ImVector_ImGuiTabBar = imgui.ImVector_TabBar

pub type ImPool_ImGuiTabBar = imgui.ImPool_TabBar

pub type ImVector_ImGuiPtrOrIndex = imgui.ImVector_PtrOrIndex

pub type ImVector_ImGuiShrinkWidthItem = imgui.ImVector_ShrinkWidthItem

pub type ImVector_ImGuiMultiSelectTempData = imgui.ImVector_MultiSelectTempData

pub type ImVector_ImGuiMultiSelectState = imgui.ImVector_MultiSelectState

pub type ImPool_ImGuiMultiSelectState = imgui.ImPool_MultiSelectState

pub type ImVector_ImGuiID = imgui.ImVector_ID

pub type ImVector_ImGuiSettingsHandler = imgui.ImVector_SettingsHandler

pub type ImChunkStream_ImGuiWindowSettings = imgui.ImChunkStream_WindowSettings

pub type ImChunkStream_ImGuiTableSettings = imgui.ImChunkStream_TableSettings

pub type ImVector_ImGuiContextHook = imgui.ImVector_ContextHook

pub type ImGuiContext = imgui.Context

pub type ImGuiWindowTempData = imgui.WindowTempData

pub type ImVector_ImGuiOldColumns = imgui.ImVector_OldColumns

pub type ImGuiWindow = imgui.Window


pub enum ImGuiTabBarFlagsPrivate_ {
 dock_node                          = 1 << 20
 is_focused                         = 1 << 21
 save_settings                      = 1 << 22
}


pub enum ImGuiTabItemFlagsPrivate_ {
 section_mask_                      = 1 << 6 | 1 << 7
 no_close_button                    = 1 << 20
 button                             = 1 << 21
 invisible                          = 1 << 22
 unsorted                           = 1 << 23
}

pub type ImGuiTabItem = imgui.TabItem

pub type ImVector_ImGuiTabItem = imgui.ImVector_TabItem

pub type ImGuiTabBar = imgui.TabBar

pub type ImGuiTableColumn = imgui.TableColumn

pub type ImGuiTableCellData = imgui.TableCellData

pub type ImGuiTableHeaderData = imgui.TableHeaderData

pub type ImGuiTableInstanceData = imgui.TableInstanceData

pub type ImSpan_ImGuiTableColumn = imgui.ImSpan_TableColumn

pub type ImSpan_ImGuiTableColumnIdx = imgui.ImSpan_TableColumnIdx

pub type ImSpan_ImGuiTableCellData = imgui.ImSpan_TableCellData

pub type ImVector_ImGuiTableInstanceData = imgui.ImVector_TableInstanceData

pub type ImVector_ImGuiTableColumnSortSpecs = imgui.ImVector_TableColumnSortSpecs

pub type ImGuiTable = imgui.Table

pub type ImVector_ImGuiTableHeaderData = imgui.ImVector_TableHeaderData

pub type ImGuiTableTempData = imgui.TableTempData

pub type ImGuiTableColumnSettings = imgui.TableColumnSettings

pub type ImGuiTableSettings = imgui.TableSettings

pub type ImFontLoader = imgui.ImFontLoader

pub type ImFontAtlasRectEntry = imgui.ImFontAtlasRectEntry

pub type ImFontAtlasPostProcessData = imgui.ImFontAtlasPostProcessData

pub type Stbrp_node_im = C.stbrp_node

pub type Stbrp_context_opaque = imgui.Stbrp_context_opaque

pub type ImVector_stbrp_node_im = imgui.ImVector_stbrp_node_im

pub type ImVector_ImFontAtlasRectEntry = imgui.ImVector_ImFontAtlasRectEntry

pub type ImVector_ImFontBakedPtr = imgui.ImVector_ImFontBakedPtr

pub type ImStableVector_ImFontBaked__32 = imgui.ImStableVector_ImFontBaked__32

pub type ImTextureRef = imgui.ImTextureRef

/////////////////////////hand written functions
// no appendfV
// for getting FLT_MAX in bindings
// for getting FLT_MIN in bindings
// CIMGUI_INCLUDED


pub type ImVector_ImS16 = C.ImVector_ImS16
@[typedef]
pub struct C.ImVector_ImS16 {
pub mut:
	Size i32
	Capacity i32
	Data &i16
}


pub type ImVector_ImS32 = C.ImVector_ImS32
@[typedef]
pub struct C.ImVector_ImS32 {
pub mut:
	Size i32
	Capacity i32
	Data &i32
}


pub type ImVector_ImS64 = C.ImVector_ImS64
@[typedef]
pub struct C.ImVector_ImS64 {
pub mut:
	Size i32
	Capacity i32
	Data &i64
}


pub type ImVector_ImS8 = C.ImVector_ImS8
@[typedef]
pub struct C.ImVector_ImS8 {
pub mut:
	Size i32
	Capacity i32
	Data &char
}


pub type ImVector_ImU64 = C.ImVector_ImU64
@[typedef]
pub struct C.ImVector_ImU64 {
pub mut:
	Size i32
	Capacity i32
	Data &u64
}

pub const implot_auto = -1

pub type ImAxis = i32

pub type Prop = i32

pub type Flags = i32

pub type AxisFlags = i32

pub type SubplotFlags = i32

pub type LegendFlags = i32

pub type MouseTextFlags = i32

pub type DragToolFlags = i32

pub type ColormapScaleFlags = i32

pub type ItemFlags = i32

pub type LineFlags = i32

pub type ScatterFlags = i32

pub type BubblesFlags = i32

pub type PolygonFlags = i32

pub type StairsFlags = i32

pub type ShadedFlags = i32

pub type BarsFlags = i32

pub type BarGroupsFlags = i32

pub type ErrorBarsFlags = i32

pub type StemsFlags = i32

pub type InfLinesFlags = i32

pub type PieChartFlags = i32

pub type HeatmapFlags = i32

pub type HistogramFlags = i32

pub type DigitalFlags = i32

pub type ImageFlags = i32

pub type TextFlags = i32

pub type DummyFlags = i32

pub type Cond = i32

pub type Col = i32

pub type StyleVar = i32

pub type Scale = i32

pub type Marker = i32

pub type Colormap = i32

pub type Location = i32

pub type Bin = i32


pub enum ImAxis_ {
 x1                                 = 0
 x2
 x3
 y1
 y2
 y3
 count
}


pub enum Prop_ {
 line_color
 line_colors
 line_weight
 fill_color
 fill_colors
 fill_alpha
 marker
 marker_size
 marker_sizes
 marker_line_color
 marker_line_colors
 marker_fill_color
 marker_fill_colors
 size
 offset
 stride
 flags
}


pub enum Flags_ {
 none                               = 0
 no_title                           = 1 << 0
 no_legend                          = 1 << 1
 no_mouse_text                      = 1 << 2
 no_inputs                          = 1 << 3
 no_menus                           = 1 << 4
 no_box_select                      = 1 << 5
 no_frame                           = 1 << 6
 equal                              = 1 << 7
 crosshairs                         = 1 << 8
 canvas_only                        = 1 << 0 | 1 << 1 | 1 << 2 | 1 << 4 | 1 << 5
}


pub enum AxisFlags_ {
 none                               = 0
 no_label                           = 1 << 0
 no_grid_lines                      = 1 << 1
 no_tick_marks                      = 1 << 2
 no_tick_labels                     = 1 << 3
 no_initial_fit                     = 1 << 4
 no_menus                           = 1 << 5
 no_side_switch                     = 1 << 6
 no_highlight                       = 1 << 7
 opposite                           = 1 << 8
 foreground                         = 1 << 9
 invert                             = 1 << 10
 auto_fit                           = 1 << 11
 range_fit                          = 1 << 12
 pan_stretch                        = 1 << 13
 lock_min                           = 1 << 14
 lock_max                           = 1 << 15
 lock                               = 1 << 14 | 1 << 15
 no_decorations                     = 1 << 0 | 1 << 1 | 1 << 2 | 1 << 3
 aux_default                        = 1 << 1 | 1 << 8
}


pub enum SubplotFlags_ {
 none                               = 0
 no_title                           = 1 << 0
 no_legend                          = 1 << 1
 no_menus                           = 1 << 2
 no_resize                          = 1 << 3
 no_align                           = 1 << 4
 share_items                        = 1 << 5
 link_rows                          = 1 << 6
 link_cols                          = 1 << 7
 link_all_x                         = 1 << 8
 link_all_y                         = 1 << 9
 col_major                          = 1 << 10
}


pub enum LegendFlags_ {
 none                               = 0
 no_buttons                         = 1 << 0
 no_highlight_item                  = 1 << 1
 no_highlight_axis                  = 1 << 2
 no_menus                           = 1 << 3
 outside                            = 1 << 4
 horizontal                         = 1 << 5
 sort                               = 1 << 6
 reverse                            = 1 << 7
}


pub enum MouseTextFlags_ {
 none                               = 0
 no_aux_axes                        = 1 << 0
 no_format                          = 1 << 1
 show_always                        = 1 << 2
}


pub enum DragToolFlags_ {
 none                               = 0
 no_cursors                         = 1 << 0
 no_fit                             = 1 << 1
 no_inputs                          = 1 << 2
 delayed                            = 1 << 3
}


pub enum ColormapScaleFlags_ {
 none                               = 0
 no_label                           = 1 << 0
 opposite                           = 1 << 1
 invert                             = 1 << 2
}


pub enum ItemFlags_ {
 none                               = 0
 no_legend                          = 1 << 0
 no_fit                             = 1 << 1
}


pub enum LineFlags_ {
 none                               = 0
 segments                           = 1 << 10
 loop                               = 1 << 11
 skip_na_n                          = 1 << 12
 no_clip                            = 1 << 13
 shaded                             = 1 << 14
}


pub enum ScatterFlags_ {
 none                               = 0
 no_clip                            = 1 << 10
}


pub enum BubblesFlags_ {
 none                               = 0
}


pub enum PolygonFlags_ {
 none                               = 0
 concave                            = 1 << 10
}


pub enum StairsFlags_ {
 none                               = 0
 pre_step                           = 1 << 10
 shaded                             = 1 << 11
}


pub enum ShadedFlags_ {
 none                               = 0
}


pub enum BarsFlags_ {
 none                               = 0
 horizontal                         = 1 << 10
}


pub enum BarGroupsFlags_ {
 none                               = 0
 horizontal                         = 1 << 10
 stacked                            = 1 << 11
}


pub enum ErrorBarsFlags_ {
 none                               = 0
 horizontal                         = 1 << 10
}


pub enum StemsFlags_ {
 none                               = 0
 horizontal                         = 1 << 10
}


pub enum InfLinesFlags_ {
 none                               = 0
 horizontal                         = 1 << 10
}


pub enum PieChartFlags_ {
 none                               = 0
 normalize                          = 1 << 10
 ignore_hidden                      = 1 << 11
 exploding                          = 1 << 12
 no_slice_border                    = 1 << 13
}


pub enum HeatmapFlags_ {
 none                               = 0
 col_major                          = 1 << 10
}


pub enum HistogramFlags_ {
 none                               = 0
 horizontal                         = 1 << 10
 cumulative                         = 1 << 11
 density                            = 1 << 12
 no_outliers                        = 1 << 13
 col_major                          = 1 << 14
}


pub enum DigitalFlags_ {
 none                               = 0
}


pub enum ImageFlags_ {
 none                               = 0
}


pub enum TextFlags_ {
 none                               = 0
 vertical                           = 1 << 10
}


pub enum DummyFlags_ {
 none                               = 0
}


pub enum Cond_ {
 none                               = 0
 always                             = 1
 once                               = 2
}


pub enum Col_ {
 frame_bg
 plot_bg
 plot_border
 legend_bg
 legend_border
 legend_text
 title_text
 inlay_text
 axis_text
 axis_grid
 axis_tick
 axis_bg
 axis_bg_hovered
 axis_bg_active
 selection
 crosshairs
 count
}


pub enum StyleVar_ {
 plot_default_size
 plot_min_size
 plot_border_size
 minor_alpha
 major_tick_len
 minor_tick_len
 major_tick_size
 minor_tick_size
 major_grid_size
 minor_grid_size
 plot_padding
 label_padding
 legend_padding
 legend_inner_padding
 legend_spacing
 mouse_pos_padding
 annotation_padding
 fit_padding
 digital_padding
 digital_spacing
 count
}


pub enum Scale_ {
 linear                             = 0
 time
 log10
 sym_log
}


pub enum Marker_ {
 none                               = -2
 auto                               = -1
 circle
 square
 diamond
 up
 down
 left
 right
 cross
 plus
 asterisk
 count
}


pub enum Colormap_ {
 deep                               = 0
 dark                               = 1
 pastel                             = 2
 paired                             = 3
 viridis                            = 4
 plasma                             = 5
 hot                                = 6
 cool                               = 7
 pink                               = 8
 jet                                = 9
 twilight                           = 10
 rd_bu                              = 11
 br_bg                              = 12
 pi_yg                              = 13
 spectral                           = 14
 greys                              = 15
}


pub enum Location_ {
 center                             = 0
 north                              = 1
 south                              = 2
 west                               = 4
 east                               = 8
 north_west                         = 5
 north_east                         = 9
 south_west                         = 6
 south_east                         = 10
}


pub enum Bin_ {
 sqrt                               = -1
 sturges                            = -2
 rice                               = -3
 scott                              = -4
}


pub type Spec_c = C.ImPlotSpec_c
@[typedef]
pub struct C.ImPlotSpec_c {
pub mut:
	LineColor ImVec4_c
	LineColors &u32
	LineWeight f32
	FillColor ImVec4_c
	FillColors &u32
	FillAlpha f32
	Marker Marker
	MarkerSize f32
	MarkerSizes &f32
	MarkerLineColor ImVec4_c
	MarkerLineColors &u32
	MarkerFillColor ImVec4_c
	MarkerFillColors &u32
	Size f32
	Offset i32
	Stride i32
	Flags ItemFlags
}


pub type Point_c = C.ImPlotPoint_c
@[typedef]
pub struct C.ImPlotPoint_c {
pub mut:
	X f64
	Y f64
}


pub type Range_c = C.ImPlotRange_c
@[typedef]
pub struct C.ImPlotRange_c {
pub mut:
	Min f64
	Max f64
}


pub type Rect_c = C.ImPlotRect_c
@[typedef]
pub struct C.ImPlotRect_c {
pub mut:
	X Range_c
	Y Range_c
}


pub type Style = C.ImPlotStyle
@[typedef]
pub struct C.ImPlotStyle {
pub mut:
	PlotDefaultSize ImVec2_c
	PlotMinSize ImVec2_c
	PlotBorderSize f32
	MinorAlpha f32
	MajorTickLen ImVec2_c
	MinorTickLen ImVec2_c
	MajorTickSize ImVec2_c
	MinorTickSize ImVec2_c
	MajorGridSize ImVec2_c
	MinorGridSize ImVec2_c
	PlotPadding ImVec2_c
	LabelPadding ImVec2_c
	LegendPadding ImVec2_c
	LegendInnerPadding ImVec2_c
	LegendSpacing ImVec2_c
	MousePosPadding ImVec2_c
	AnnotationPadding ImVec2_c
	FitPadding ImVec2_c
	DigitalPadding f32
	DigitalSpacing f32
	Colors [16]ImVec4_c
	Colormap Colormap
	UseLocalTime bool
	UseISO8601 bool
	Use24HourClock bool
}


pub type InputMap = C.ImPlotInputMap
@[typedef]
pub struct C.ImPlotInputMap {
pub mut:
	Pan imgui.MouseButton
	PanMod i32
	Fit imgui.MouseButton
	Select imgui.MouseButton
	SelectCancel imgui.MouseButton
	SelectMod i32
	SelectHorzMod i32
	SelectVertMod i32
	Menu imgui.MouseButton
	OverrideMod i32
	ZoomMod i32
	ZoomRate f32
}

pub type Formatter = fn(f64, &char, i32, voidptr) i32

pub type Getter = fn(i32, voidptr) Point_c

pub type Transform = fn(f64, voidptr) f64

pub const implot_min_time = f64(0)

pub const implot_max_time = f64(32503680000)

pub const implot_label_max_size = 32

pub type TimeUnit = i32

pub type DateFmt = i32

pub type TimeFmt = i32

pub type MarkerInternal = i32


pub enum TimeUnit_ {
 us
 ms
 s
 min
 hr
 day
 mo
 yr
 count
}


pub enum DateFmt_ {
 none                               = 0
 day_mo
 day_mo_yr
 mo_yr
 mo
 yr
}


pub enum TimeFmt_ {
 none                               = 0
 us
 su_s
 sm_s
 s
 min_sm_s
 hr_min_sm_s
 hr_min_s
 hr_min
 hr
}


pub enum MarkerInternal_ {
 marker_invalid                     = -3
}

pub type Locator = fn(&Ticker, Range_c, f32, bool, Formatter, voidptr)


pub type DateTimeSpec_c = C.ImPlotDateTimeSpec_c
@[typedef]
pub struct C.ImPlotDateTimeSpec_c {
pub mut:
	Date DateFmt
	Time TimeFmt
	UseISO8601 bool
	Use24HourClock bool
}


pub type Time_c = C.ImPlotTime_c
@[typedef]
pub struct C.ImPlotTime_c {
pub mut:
	S i64
	Us i32
}


pub type ImVector_bool = C.ImVector_bool
@[typedef]
pub struct C.ImVector_bool {
pub mut:
	Size i32
	Capacity i32
	Data &bool
}


pub type ColormapData = C.ImPlotColormapData
@[typedef]
pub struct C.ImPlotColormapData {
pub mut:
	Keys ImVector_ImU32
	KeyCounts ImVector_int
	KeyOffsets ImVector_int
	Tables ImVector_ImU32
	TableSizes ImVector_int
	TableOffsets ImVector_int
	Text imgui.TextBuffer
	TextOffsets ImVector_int
	Quals ImVector_bool
	Map imgui.Storage
	Count i32
}


pub type PointError = C.ImPlotPointError
@[typedef]
pub struct C.ImPlotPointError {
pub mut:
	X f64
	Y f64
	Neg f64
	Pos f64
}


pub type Annotation = C.ImPlotAnnotation
@[typedef]
pub struct C.ImPlotAnnotation {
pub mut:
	Pos ImVec2_c
	Offset ImVec2_c
	ColorBg u32
	ColorFg u32
	TextOffset i32
	Clamp bool
}


pub type ImVector_Annotation = C.ImVector_ImPlotAnnotation
@[typedef]
pub struct C.ImVector_ImPlotAnnotation {
pub mut:
	Size i32
	Capacity i32
	Data &Annotation
}


pub type AnnotationCollection = C.ImPlotAnnotationCollection
@[typedef]
pub struct C.ImPlotAnnotationCollection {
pub mut:
	Annotations ImVector_Annotation
	TextBuffer imgui.TextBuffer
	Size i32
}


pub type Tag = C.ImPlotTag
@[typedef]
pub struct C.ImPlotTag {
pub mut:
	Axis ImAxis
	Value f64
	ColorBg u32
	ColorFg u32
	TextOffset i32
}


pub type ImVector_Tag = C.ImVector_ImPlotTag
@[typedef]
pub struct C.ImVector_ImPlotTag {
pub mut:
	Size i32
	Capacity i32
	Data &Tag
}


pub type TagCollection = C.ImPlotTagCollection
@[typedef]
pub struct C.ImPlotTagCollection {
pub mut:
	Tags ImVector_Tag
	TextBuffer imgui.TextBuffer
	Size i32
}


pub type Tick_c = C.ImPlotTick_c
@[typedef]
pub struct C.ImPlotTick_c {
pub mut:
	PlotPos f64
	PixelPos f32
	LabelSize ImVec2_c
	TextOffset i32
	Major bool
	ShowLabel bool
	Level i32
	Idx i32
}


pub type ImVector_Tick = C.ImVector_ImPlotTick
@[typedef]
pub struct C.ImVector_ImPlotTick {
pub mut:
	Size i32
	Capacity i32
	Data &Tick_c
}


pub type Ticker = C.ImPlotTicker
@[typedef]
pub struct C.ImPlotTicker {
pub mut:
	Ticks ImVector_Tick
	TextBuffer imgui.TextBuffer
	MaxSize ImVec2_c
	LateSize ImVec2_c
	Levels i32
}


pub type Axis_c = C.ImPlotAxis_c
@[typedef]
pub struct C.ImPlotAxis_c {
pub mut:
	ID imgui.ID
	Flags AxisFlags
	PreviousFlags AxisFlags
	Range Range_c
	RangeCond Cond
	Scale Scale
	FitExtents Range_c
	OrthoAxis &Axis_c
	ConstraintRange Range_c
	ConstraintZoom Range_c
	Ticker Ticker
	Formatter Formatter
	FormatterData voidptr
	FormatSpec [16]i8
	Locator Locator
	LinkedMin &f64
	LinkedMax &f64
	PickerLevel i32
	PickerTimeMin Time_c
	PickerTimeMax Time_c
	TransformForward Transform
	TransformInverse Transform
	TransformData voidptr
	PixelMin f32
	PixelMax f32
	ScaleMin f64
	ScaleMax f64
	ScaleToPixel f64
	Datum1 f32
	Datum2 f32
	HoverRect ImRect_c
	LabelOffset i32
	ColorMaj u32
	ColorMin u32
	ColorTick u32
	ColorTxt u32
	ColorBg u32
	ColorHov u32
	ColorAct u32
	ColorHiLi u32
	Enabled bool
	Vertical bool
	FitThisFrame bool
	HasRange bool
	HasFormatSpec bool
	ShowDefaultTicks bool
	Hovered bool
	Held bool
}


pub type AlignmentData = C.ImPlotAlignmentData
@[typedef]
pub struct C.ImPlotAlignmentData {
pub mut:
	Vertical bool
	PadA f32
	PadB f32
	PadAMax f32
	PadBMax f32
}


pub type Item = C.ImPlotItem
@[typedef]
pub struct C.ImPlotItem {
pub mut:
	ID imgui.ID
	Color u32
	Marker Marker
	LegendHoverRect ImRect_c
	NameOffset i32
	Show bool
	LegendHovered bool
	SeenThisFrame bool
}


pub type Legend = C.ImPlotLegend
@[typedef]
pub struct C.ImPlotLegend {
pub mut:
	Flags LegendFlags
	PreviousFlags LegendFlags
	Location Location
	PreviousLocation Location
	Scroll ImVec2_c
	Indices ImVector_int
	Labels imgui.TextBuffer
	Rect ImRect_c
	RectClamped ImRect_c
	Hovered bool
	Held bool
	CanGoInside bool
}


pub type ImVector_Item = C.ImVector_ImPlotItem
@[typedef]
pub struct C.ImVector_ImPlotItem {
pub mut:
	Size i32
	Capacity i32
	Data &Item
}


pub type ImPool_Item = C.ImPool_ImPlotItem
@[typedef]
pub struct C.ImPool_ImPlotItem {
pub mut:
	Buf ImVector_Item
	Map imgui.Storage
	FreeIdx ImPoolIdx
	AliveCount ImPoolIdx
}


pub type ItemGroup = C.ImPlotItemGroup
@[typedef]
pub struct C.ImPlotItemGroup {
pub mut:
	ID imgui.ID
	Legend Legend
	ItemPool ImPool_Item
	ColormapIdx i32
	MarkerIdx Marker
}


pub type Plot = C.ImPlotPlot
@[typedef]
pub struct C.ImPlotPlot {
pub mut:
	ID imgui.ID
	Flags Flags
	PreviousFlags Flags
	MouseTextLocation Location
	MouseTextFlags MouseTextFlags
	Axes [6]Axis_c
	TextBuffer imgui.TextBuffer
	Items ItemGroup
	CurrentX ImAxis
	CurrentY ImAxis
	FrameRect ImRect_c
	CanvasRect ImRect_c
	PlotRect ImRect_c
	AxesRect ImRect_c
	SelectRect ImRect_c
	SelectStart ImVec2_c
	TitleOffset i32
	JustCreated bool
	Initialized bool
	SetupLocked bool
	FitThisFrame bool
	Hovered bool
	Held bool
	Selecting bool
	Selected bool
	ContextLocked bool
}


pub type ImVector_AlignmentData = C.ImVector_ImPlotAlignmentData
@[typedef]
pub struct C.ImVector_ImPlotAlignmentData {
pub mut:
	Size i32
	Capacity i32
	Data &AlignmentData
}


pub type ImVector_Range = C.ImVector_ImPlotRange
@[typedef]
pub struct C.ImVector_ImPlotRange {
pub mut:
	Size i32
	Capacity i32
	Data &Range_c
}


pub type Subplot = C.ImPlotSubplot
@[typedef]
pub struct C.ImPlotSubplot {
pub mut:
	ID imgui.ID
	Flags SubplotFlags
	PreviousFlags SubplotFlags
	Items ItemGroup
	Rows i32
	Cols i32
	CurrentIdx i32
	FrameRect ImRect_c
	GridRect ImRect_c
	CellSize ImVec2_c
	RowAlignmentData ImVector_AlignmentData
	ColAlignmentData ImVector_AlignmentData
	RowRatios ImVector_float
	ColRatios ImVector_float
	RowLinkData ImVector_Range
	ColLinkData ImVector_Range
	TempSizes [2]f32
	FrameHovered bool
	HasTitle bool
}


pub type NextPlotData = C.ImPlotNextPlotData
@[typedef]
pub struct C.ImPlotNextPlotData {
pub mut:
	RangeCond [6]Cond
	Range [6]Range_c
	HasRange [6]bool
	Fit [6]bool
	LinkedMin [6]&f64
	LinkedMax [6]&f64
}


pub type NextItemData = C.ImPlotNextItemData
@[typedef]
pub struct C.ImPlotNextItemData {
pub mut:
	Spec Spec_c
	RenderLine bool
	RenderFill bool
	RenderMarkerLine bool
	RenderMarkerFill bool
	RenderMarkers bool
	HasHidden bool
	Hidden bool
	HiddenCond Cond
}


pub type ImVector_Plot = C.ImVector_ImPlotPlot
@[typedef]
pub struct C.ImVector_ImPlotPlot {
pub mut:
	Size i32
	Capacity i32
	Data &Plot
}


pub type ImPool_Plot = C.ImPool_ImPlotPlot
@[typedef]
pub struct C.ImPool_ImPlotPlot {
pub mut:
	Buf ImVector_Plot
	Map imgui.Storage
	FreeIdx ImPoolIdx
	AliveCount ImPoolIdx
}


pub type ImVector_Subplot = C.ImVector_ImPlotSubplot
@[typedef]
pub struct C.ImVector_ImPlotSubplot {
pub mut:
	Size i32
	Capacity i32
	Data &Subplot
}


pub type ImPool_Subplot = C.ImPool_ImPlotSubplot
@[typedef]
pub struct C.ImPool_ImPlotSubplot {
pub mut:
	Buf ImVector_Subplot
	Map imgui.Storage
	FreeIdx ImPoolIdx
	AliveCount ImPoolIdx
}


pub type ImVector_Colormap = C.ImVector_ImPlotColormap
@[typedef]
pub struct C.ImVector_ImPlotColormap {
pub mut:
	Size i32
	Capacity i32
	Data &Colormap
}


pub type ImVector_double = C.ImVector_double
@[typedef]
pub struct C.ImVector_double {
pub mut:
	Size i32
	Capacity i32
	Data &f64
}


pub type ImPool_AlignmentData = C.ImPool_ImPlotAlignmentData
@[typedef]
pub struct C.ImPool_ImPlotAlignmentData {
pub mut:
	Buf ImVector_AlignmentData
	Map imgui.Storage
	FreeIdx ImPoolIdx
	AliveCount ImPoolIdx
}


pub type Context = C.ImPlotContext
@[typedef]
pub struct C.ImPlotContext {
pub mut:
	Plots ImPool_Plot
	Subplots ImPool_Subplot
	CurrentPlot &Plot
	CurrentSubplot &Subplot
	CurrentItems &ItemGroup
	CurrentItem &Item
	PreviousItem &Item
	CTicker Ticker
	Annotations AnnotationCollection
	Tags TagCollection
	Style Style
	ColorModifiers ImVector_ImGuiColorMod
	StyleModifiers ImVector_ImGuiStyleMod
	ColormapData ColormapData
	ColormapModifiers ImVector_Colormap
	Tm C.tm
	TempDouble1 ImVector_double
	TempDouble2 ImVector_double
	TempInt1 ImVector_int
	DigitalPlotItemCnt i32
	DigitalPlotOffset i32
	NextPlotData NextPlotData
	NextItemData NextItemData
	InputMap InputMap
	OpenContextThisFrame bool
	MousePosStringBuilder imgui.TextBuffer
	SortItems &ItemGroup
	AlignmentData ImPool_AlignmentData
	CurrentAlignmentH &AlignmentData
	CurrentAlignmentV &AlignmentData
}


pub type DateTimeSpec = C.ImPlotDateTimeSpec
@[typedef]
pub struct C.ImPlotDateTimeSpec {
pub mut:
	Time Time_c
	Spec DateTimeSpec_c
	UserFormatter Formatter
	UserFormatterData voidptr
}

// Point getters manually wrapped use this
pub type Point_getter = fn(voidptr, i32, &Point_c) voidptr


@[keep_args_alive]
fn C.ImPlotSpec_ImPlotSpec() &Spec

@[inline]
pub fn spec_spec() &Spec {
	return C.ImPlotSpec_ImPlotSpec()
}


@[keep_args_alive]
fn C.ImPlotSpec_destroy(self &Spec)

@[inline]
pub fn spec_destroy(self &Spec) {
	C.ImPlotSpec_destroy(self)
}


@[keep_args_alive]
fn C.ImPlotSpec_SetProp_Float(self &Spec, prop Prop, v f32)

@[inline]
pub fn spec_set_prop_float(self &Spec, prop Prop, v f32) {
	C.ImPlotSpec_SetProp_Float(self, prop, v)
}


@[keep_args_alive]
fn C.ImPlotSpec_SetProp_double(self &Spec, prop Prop, v f64)

@[inline]
pub fn spec_set_prop_double(self &Spec, prop Prop, v f64) {
	C.ImPlotSpec_SetProp_double(self, prop, v)
}


@[keep_args_alive]
fn C.ImPlotSpec_SetProp_S8(self &Spec, prop Prop, v i8)

@[inline]
pub fn spec_set_prop_s8(self &Spec, prop Prop, v i8) {
	C.ImPlotSpec_SetProp_S8(self, prop, v)
}


@[keep_args_alive]
fn C.ImPlotSpec_SetProp_U8(self &Spec, prop Prop, v u8)

@[inline]
pub fn spec_set_prop_u8(self &Spec, prop Prop, v u8) {
	C.ImPlotSpec_SetProp_U8(self, prop, v)
}


@[keep_args_alive]
fn C.ImPlotSpec_SetProp_S16(self &Spec, prop Prop, v i16)

@[inline]
pub fn spec_set_prop_s16(self &Spec, prop Prop, v i16) {
	C.ImPlotSpec_SetProp_S16(self, prop, v)
}


@[keep_args_alive]
fn C.ImPlotSpec_SetProp_U16(self &Spec, prop Prop, v u16)

@[inline]
pub fn spec_set_prop_u16(self &Spec, prop Prop, v u16) {
	C.ImPlotSpec_SetProp_U16(self, prop, v)
}


@[keep_args_alive]
fn C.ImPlotSpec_SetProp_S32(self &Spec, prop Prop, v i32)

@[inline]
pub fn spec_set_prop_s32(self &Spec, prop Prop, v i32) {
	C.ImPlotSpec_SetProp_S32(self, prop, v)
}


@[keep_args_alive]
fn C.ImPlotSpec_SetProp_U32(self &Spec, prop Prop, v u32)

@[inline]
pub fn spec_set_prop_u32(self &Spec, prop Prop, v u32) {
	C.ImPlotSpec_SetProp_U32(self, prop, v)
}


@[keep_args_alive]
fn C.ImPlotSpec_SetProp_S64(self &Spec, prop Prop, v i64)

@[inline]
pub fn spec_set_prop_s64(self &Spec, prop Prop, v i64) {
	C.ImPlotSpec_SetProp_S64(self, prop, v)
}


@[keep_args_alive]
fn C.ImPlotSpec_SetProp_U64(self &Spec, prop Prop, v u64)

@[inline]
pub fn spec_set_prop_u64(self &Spec, prop Prop, v u64) {
	C.ImPlotSpec_SetProp_U64(self, prop, v)
}


@[keep_args_alive]
fn C.ImPlotSpec_SetProp_U32Ptr(self &Spec, prop Prop, v &u32)

@[inline]
pub fn spec_set_prop_u32_ptr(self &Spec, prop Prop, v &u32) {
	C.ImPlotSpec_SetProp_U32Ptr(self, prop, v)
}


@[keep_args_alive]
fn C.ImPlotSpec_SetProp_FloatPtr(self &Spec, prop Prop, v &f32)

@[inline]
pub fn spec_set_prop_float_ptr(self &Spec, prop Prop, v &f32) {
	C.ImPlotSpec_SetProp_FloatPtr(self, prop, v)
}


@[keep_args_alive]
fn C.ImPlotSpec_SetProp_Vec4(self &Spec, prop Prop, v ImVec4_c)

@[inline]
pub fn spec_set_prop_vec4(self &Spec, prop Prop, v ImVec4_c) {
	C.ImPlotSpec_SetProp_Vec4(self, prop, v)
}


@[keep_args_alive]
fn C.ImPlotPoint_ImPlotPoint_Nil() &Point

@[inline]
pub fn point_point_nil() &Point {
	return C.ImPlotPoint_ImPlotPoint_Nil()
}


@[keep_args_alive]
fn C.ImPlotPoint_destroy(self &Point)

@[inline]
pub fn point_destroy(self &Point) {
	C.ImPlotPoint_destroy(self)
}


@[keep_args_alive]
fn C.ImPlotPoint_ImPlotPoint_double(_x f64, _y f64) &Point

@[inline]
pub fn point_point_double(_x f64, _y f64) &Point {
	return C.ImPlotPoint_ImPlotPoint_double(_x, _y)
}


@[keep_args_alive]
fn C.ImPlotPoint_ImPlotPoint_Vec2(p ImVec2_c) &Point

@[inline]
pub fn point_point_vec2(p ImVec2_c) &Point {
	return C.ImPlotPoint_ImPlotPoint_Vec2(p)
}


@[keep_args_alive]
fn C.ImPlotRange_ImPlotRange_Nil() &Range

@[inline]
pub fn range_range_nil() &Range {
	return C.ImPlotRange_ImPlotRange_Nil()
}


@[keep_args_alive]
fn C.ImPlotRange_destroy(self &Range)

@[inline]
pub fn range_destroy(self &Range) {
	C.ImPlotRange_destroy(self)
}


@[keep_args_alive]
fn C.ImPlotRange_ImPlotRange_double(_min f64, _max f64) &Range

@[inline]
pub fn range_range_double(_min f64, _max f64) &Range {
	return C.ImPlotRange_ImPlotRange_double(_min, _max)
}


@[keep_args_alive]
fn C.ImPlotRange_Contains(self &Range, value f64) bool

@[inline]
pub fn range_contains(self &Range, value f64) bool {
	return C.ImPlotRange_Contains(self, value)
}


@[keep_args_alive]
fn C.ImPlotRange_Size(self &Range) f64

@[inline]
pub fn range_size(self &Range) f64 {
	return C.ImPlotRange_Size(self)
}


@[keep_args_alive]
fn C.ImPlotRange_Clamp(self &Range, value f64) f64

@[inline]
pub fn range_clamp(self &Range, value f64) f64 {
	return C.ImPlotRange_Clamp(self, value)
}


@[keep_args_alive]
fn C.ImPlotRect_ImPlotRect_Nil() &Rect

@[inline]
pub fn rect_rect_nil() &Rect {
	return C.ImPlotRect_ImPlotRect_Nil()
}


@[keep_args_alive]
fn C.ImPlotRect_destroy(self &Rect)

@[inline]
pub fn rect_destroy(self &Rect) {
	C.ImPlotRect_destroy(self)
}


@[keep_args_alive]
fn C.ImPlotRect_ImPlotRect_double(x_min f64, x_max f64, y_min f64, y_max f64) &Rect

@[inline]
pub fn rect_rect_double(x_min f64, x_max f64, y_min f64, y_max f64) &Rect {
	return C.ImPlotRect_ImPlotRect_double(x_min, x_max, y_min, y_max)
}


@[keep_args_alive]
fn C.ImPlotRect_Contains_PlotPoint(self &Rect, p Point_c) bool

@[inline]
pub fn rect_contains_plot_point(self &Rect, p Point_c) bool {
	return C.ImPlotRect_Contains_PlotPoint(self, p)
}


@[keep_args_alive]
fn C.ImPlotRect_Contains_double(self &Rect, x f64, y f64) bool

@[inline]
pub fn rect_contains_double(self &Rect, x f64, y f64) bool {
	return C.ImPlotRect_Contains_double(self, x, y)
}


@[keep_args_alive]
fn C.ImPlotRect_Size(self &Rect) Point_c

@[inline]
pub fn rect_size(self &Rect) Point_c {
	return C.ImPlotRect_Size(self)
}


@[keep_args_alive]
fn C.ImPlotRect_Clamp_PlotPoint(self &Rect, p Point_c) Point_c

@[inline]
pub fn rect_clamp_plot_point(self &Rect, p Point_c) Point_c {
	return C.ImPlotRect_Clamp_PlotPoint(self, p)
}


@[keep_args_alive]
fn C.ImPlotRect_Clamp_double(self &Rect, x f64, y f64) Point_c

@[inline]
pub fn rect_clamp_double(self &Rect, x f64, y f64) Point_c {
	return C.ImPlotRect_Clamp_double(self, x, y)
}


@[keep_args_alive]
fn C.ImPlotRect_Min(self &Rect) Point_c

@[inline]
pub fn rect_min(self &Rect) Point_c {
	return C.ImPlotRect_Min(self)
}


@[keep_args_alive]
fn C.ImPlotRect_Max(self &Rect) Point_c

@[inline]
pub fn rect_max(self &Rect) Point_c {
	return C.ImPlotRect_Max(self)
}


@[keep_args_alive]
fn C.ImPlotStyle_ImPlotStyle() &Style

@[inline]
pub fn style_style() &Style {
	return C.ImPlotStyle_ImPlotStyle()
}


@[keep_args_alive]
fn C.ImPlotStyle_destroy(self &Style)

@[inline]
pub fn style_destroy(self &Style) {
	C.ImPlotStyle_destroy(self)
}


@[keep_args_alive]
fn C.ImPlotInputMap_ImPlotInputMap() &InputMap

@[inline]
pub fn input_map_input_map() &InputMap {
	return C.ImPlotInputMap_ImPlotInputMap()
}


@[keep_args_alive]
fn C.ImPlotInputMap_destroy(self &InputMap)

@[inline]
pub fn input_map_destroy(self &InputMap) {
	C.ImPlotInputMap_destroy(self)
}


@[keep_args_alive]
fn C.ImPlot_CreateContext() &imgui.Context

@[inline]
pub fn create_context() &imgui.Context {
	return C.ImPlot_CreateContext()
}


@[keep_args_alive]
fn C.ImPlot_DestroyContext(ctx &imgui.Context)

@[inline]
pub fn destroy_context(ctx &imgui.Context) {
	C.ImPlot_DestroyContext(ctx)
}


@[keep_args_alive]
fn C.ImPlot_GetCurrentContext() &imgui.Context

@[inline]
pub fn get_current_context() &imgui.Context {
	return C.ImPlot_GetCurrentContext()
}


@[keep_args_alive]
fn C.ImPlot_SetCurrentContext(ctx &imgui.Context)

@[inline]
pub fn set_current_context(ctx &imgui.Context) {
	C.ImPlot_SetCurrentContext(ctx)
}


@[keep_args_alive]
fn C.ImPlot_SetImGuiContext(ctx &imgui.Context)

@[inline]
pub fn set_im_gui_context(ctx &imgui.Context) {
	C.ImPlot_SetImGuiContext(ctx)
}


@[keep_args_alive]
fn C.ImPlot_BeginPlot(title_id &char, size ImVec2_c, flags Flags) bool

@[inline]
pub fn begin_plot(title_id &char, size ImVec2_c, flags Flags) bool {
	return C.ImPlot_BeginPlot(title_id, size, flags)
}


@[keep_args_alive]
fn C.ImPlot_EndPlot()

@[inline]
pub fn end_plot() {
	C.ImPlot_EndPlot()
}


@[keep_args_alive]
fn C.ImPlot_BeginSubplots(title_id &char, rows i32, cols i32, size ImVec2_c, flags SubplotFlags, row_ratios &f32, col_ratios &f32) bool

@[inline]
pub fn begin_subplots(title_id &char, rows i32, cols i32, size ImVec2_c, flags SubplotFlags, row_ratios &f32, col_ratios &f32) bool {
	return C.ImPlot_BeginSubplots(title_id, rows, cols, size, flags, row_ratios, col_ratios)
}


@[keep_args_alive]
fn C.ImPlot_EndSubplots()

@[inline]
pub fn end_subplots() {
	C.ImPlot_EndSubplots()
}


@[keep_args_alive]
fn C.ImPlot_SetupAxis(axis ImAxis, const_label &char, flags AxisFlags)

@[inline]
pub fn setup_axis(axis ImAxis, const_label &char, flags AxisFlags) {
	C.ImPlot_SetupAxis(axis, const_label, flags)
}


@[keep_args_alive]
fn C.ImPlot_SetupAxisLimits(axis ImAxis, v_min f64, v_max f64, cond Cond)

@[inline]
pub fn setup_axis_limits(axis ImAxis, v_min f64, v_max f64, cond Cond) {
	C.ImPlot_SetupAxisLimits(axis, v_min, v_max, cond)
}


@[keep_args_alive]
fn C.ImPlot_SetupAxisLinks(axis ImAxis, link_min &f64, link_max &f64)

@[inline]
pub fn setup_axis_links(axis ImAxis, link_min &f64, link_max &f64) {
	C.ImPlot_SetupAxisLinks(axis, link_min, link_max)
}


@[keep_args_alive]
fn C.ImPlot_SetupAxisFormat_Str(axis ImAxis, const_fmt &char)

@[inline]
pub fn setup_axis_format_str(axis ImAxis, const_fmt &char) {
	C.ImPlot_SetupAxisFormat_Str(axis, const_fmt)
}


@[keep_args_alive]
fn C.ImPlot_SetupAxisFormat_PlotFormatter(axis ImAxis, formatter Formatter, data voidptr)

@[inline]
pub fn setup_axis_format_plot_formatter(axis ImAxis, formatter Formatter, data voidptr) {
	C.ImPlot_SetupAxisFormat_PlotFormatter(axis, formatter, data)
}


@[keep_args_alive]
fn C.ImPlot_SetupAxisTicks_doublePtr(axis ImAxis, values &f64, n_ticks i32, labels &&u8, keep_default bool)

@[inline]
pub fn setup_axis_ticks_double_ptr(axis ImAxis, values &f64, n_ticks i32, labels &&u8, keep_default bool) {
	C.ImPlot_SetupAxisTicks_doublePtr(axis, values, n_ticks, labels, keep_default)
}


@[keep_args_alive]
fn C.ImPlot_SetupAxisTicks_double(axis ImAxis, v_min f64, v_max f64, n_ticks i32, labels &&u8, keep_default bool)

@[inline]
pub fn setup_axis_ticks_double(axis ImAxis, v_min f64, v_max f64, n_ticks i32, labels &&u8, keep_default bool) {
	C.ImPlot_SetupAxisTicks_double(axis, v_min, v_max, n_ticks, labels, keep_default)
}


@[keep_args_alive]
fn C.ImPlot_SetupAxisScale_PlotScale(axis ImAxis, scale Scale)

@[inline]
pub fn setup_axis_scale_plot_scale(axis ImAxis, scale Scale) {
	C.ImPlot_SetupAxisScale_PlotScale(axis, scale)
}


@[keep_args_alive]
fn C.ImPlot_SetupAxisScale_PlotTransform(axis ImAxis, forward Transform, inverse Transform, data voidptr)

@[inline]
pub fn setup_axis_scale_plot_transform(axis ImAxis, forward Transform, inverse Transform, data voidptr) {
	C.ImPlot_SetupAxisScale_PlotTransform(axis, forward, inverse, data)
}


@[keep_args_alive]
fn C.ImPlot_SetupAxisLimitsConstraints(axis ImAxis, v_min f64, v_max f64)

@[inline]
pub fn setup_axis_limits_constraints(axis ImAxis, v_min f64, v_max f64) {
	C.ImPlot_SetupAxisLimitsConstraints(axis, v_min, v_max)
}


@[keep_args_alive]
fn C.ImPlot_SetupAxisZoomConstraints(axis ImAxis, z_min f64, z_max f64)

@[inline]
pub fn setup_axis_zoom_constraints(axis ImAxis, z_min f64, z_max f64) {
	C.ImPlot_SetupAxisZoomConstraints(axis, z_min, z_max)
}


@[keep_args_alive]
fn C.ImPlot_SetupAxes(x_label &char, y_label &char, x_flags AxisFlags, y_flags AxisFlags)

@[inline]
pub fn setup_axes(x_label &char, y_label &char, x_flags AxisFlags, y_flags AxisFlags) {
	C.ImPlot_SetupAxes(x_label, y_label, x_flags, y_flags)
}


@[keep_args_alive]
fn C.ImPlot_SetupAxesLimits(x_min f64, x_max f64, y_min f64, y_max f64, cond Cond)

@[inline]
pub fn setup_axes_limits(x_min f64, x_max f64, y_min f64, y_max f64, cond Cond) {
	C.ImPlot_SetupAxesLimits(x_min, x_max, y_min, y_max, cond)
}


@[keep_args_alive]
fn C.ImPlot_SetupLegend(location Location, flags LegendFlags)

@[inline]
pub fn setup_legend(location Location, flags LegendFlags) {
	C.ImPlot_SetupLegend(location, flags)
}


@[keep_args_alive]
fn C.ImPlot_SetupMouseText(location Location, flags MouseTextFlags)

@[inline]
pub fn setup_mouse_text(location Location, flags MouseTextFlags) {
	C.ImPlot_SetupMouseText(location, flags)
}


@[keep_args_alive]
fn C.ImPlot_SetupFinish()

@[inline]
pub fn setup_finish() {
	C.ImPlot_SetupFinish()
}


@[keep_args_alive]
fn C.ImPlot_SetNextAxisLimits(axis ImAxis, v_min f64, v_max f64, cond Cond)

@[inline]
pub fn set_next_axis_limits(axis ImAxis, v_min f64, v_max f64, cond Cond) {
	C.ImPlot_SetNextAxisLimits(axis, v_min, v_max, cond)
}


@[keep_args_alive]
fn C.ImPlot_SetNextAxisLinks(axis ImAxis, link_min &f64, link_max &f64)

@[inline]
pub fn set_next_axis_links(axis ImAxis, link_min &f64, link_max &f64) {
	C.ImPlot_SetNextAxisLinks(axis, link_min, link_max)
}


@[keep_args_alive]
fn C.ImPlot_SetNextAxisToFit(axis ImAxis)

@[inline]
pub fn set_next_axis_to_fit(axis ImAxis) {
	C.ImPlot_SetNextAxisToFit(axis)
}


@[keep_args_alive]
fn C.ImPlot_SetNextAxesLimits(x_min f64, x_max f64, y_min f64, y_max f64, cond Cond)

@[inline]
pub fn set_next_axes_limits(x_min f64, x_max f64, y_min f64, y_max f64, cond Cond) {
	C.ImPlot_SetNextAxesLimits(x_min, x_max, y_min, y_max, cond)
}


@[keep_args_alive]
fn C.ImPlot_SetNextAxesToFit()

@[inline]
pub fn set_next_axes_to_fit() {
	C.ImPlot_SetNextAxesToFit()
}


@[keep_args_alive]
fn C.ImPlot_PlotLine_FloatPtrInt(label_id &char, values &f32, count i32, xscale f64, xstart f64, spec Spec_c)

@[inline]
pub fn plot_line_float_ptr_int(label_id &char, values &f32, count i32, xscale f64, xstart f64, spec Spec_c) {
	C.ImPlot_PlotLine_FloatPtrInt(label_id, values, count, xscale, xstart, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotLine_doublePtrInt(label_id &char, values &f64, count i32, xscale f64, xstart f64, spec Spec_c)

@[inline]
pub fn plot_line_double_ptr_int(label_id &char, values &f64, count i32, xscale f64, xstart f64, spec Spec_c) {
	C.ImPlot_PlotLine_doublePtrInt(label_id, values, count, xscale, xstart, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotLine_S8PtrInt(label_id &char, values &char, count i32, xscale f64, xstart f64, spec Spec_c)

@[inline]
pub fn plot_line_s8_ptr_int(label_id &char, values &char, count i32, xscale f64, xstart f64, spec Spec_c) {
	C.ImPlot_PlotLine_S8PtrInt(label_id, values, count, xscale, xstart, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotLine_U8PtrInt(label_id &char, values &u8, count i32, xscale f64, xstart f64, spec Spec_c)

@[inline]
pub fn plot_line_u8_ptr_int(label_id &char, values &u8, count i32, xscale f64, xstart f64, spec Spec_c) {
	C.ImPlot_PlotLine_U8PtrInt(label_id, values, count, xscale, xstart, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotLine_S16PtrInt(label_id &char, values &i16, count i32, xscale f64, xstart f64, spec Spec_c)

@[inline]
pub fn plot_line_s16_ptr_int(label_id &char, values &i16, count i32, xscale f64, xstart f64, spec Spec_c) {
	C.ImPlot_PlotLine_S16PtrInt(label_id, values, count, xscale, xstart, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotLine_U16PtrInt(label_id &char, values &u16, count i32, xscale f64, xstart f64, spec Spec_c)

@[inline]
pub fn plot_line_u16_ptr_int(label_id &char, values &u16, count i32, xscale f64, xstart f64, spec Spec_c) {
	C.ImPlot_PlotLine_U16PtrInt(label_id, values, count, xscale, xstart, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotLine_S32PtrInt(label_id &char, values &i32, count i32, xscale f64, xstart f64, spec Spec_c)

@[inline]
pub fn plot_line_s32_ptr_int(label_id &char, values &i32, count i32, xscale f64, xstart f64, spec Spec_c) {
	C.ImPlot_PlotLine_S32PtrInt(label_id, values, count, xscale, xstart, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotLine_U32PtrInt(label_id &char, values &u32, count i32, xscale f64, xstart f64, spec Spec_c)

@[inline]
pub fn plot_line_u32_ptr_int(label_id &char, values &u32, count i32, xscale f64, xstart f64, spec Spec_c) {
	C.ImPlot_PlotLine_U32PtrInt(label_id, values, count, xscale, xstart, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotLine_S64PtrInt(label_id &char, values &i64, count i32, xscale f64, xstart f64, spec Spec_c)

@[inline]
pub fn plot_line_s64_ptr_int(label_id &char, values &i64, count i32, xscale f64, xstart f64, spec Spec_c) {
	C.ImPlot_PlotLine_S64PtrInt(label_id, values, count, xscale, xstart, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotLine_U64PtrInt(label_id &char, values &u64, count i32, xscale f64, xstart f64, spec Spec_c)

@[inline]
pub fn plot_line_u64_ptr_int(label_id &char, values &u64, count i32, xscale f64, xstart f64, spec Spec_c) {
	C.ImPlot_PlotLine_U64PtrInt(label_id, values, count, xscale, xstart, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotLine_FloatPtrFloatPtr(label_id &char, xs &f32, ys &f32, count i32, spec Spec_c)

@[inline]
pub fn plot_line_float_ptr_float_ptr(label_id &char, xs &f32, ys &f32, count i32, spec Spec_c) {
	C.ImPlot_PlotLine_FloatPtrFloatPtr(label_id, xs, ys, count, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotLine_doublePtrdoublePtr(label_id &char, xs &f64, ys &f64, count i32, spec Spec_c)

@[inline]
pub fn plot_line_double_ptrdouble_ptr(label_id &char, xs &f64, ys &f64, count i32, spec Spec_c) {
	C.ImPlot_PlotLine_doublePtrdoublePtr(label_id, xs, ys, count, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotLine_S8PtrS8Ptr(label_id &char, xs &char, ys &char, count i32, spec Spec_c)

@[inline]
pub fn plot_line_s8_ptr_s8_ptr(label_id &char, xs &char, ys &char, count i32, spec Spec_c) {
	C.ImPlot_PlotLine_S8PtrS8Ptr(label_id, xs, ys, count, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotLine_U8PtrU8Ptr(label_id &char, xs &u8, ys &u8, count i32, spec Spec_c)

@[inline]
pub fn plot_line_u8_ptr_u8_ptr(label_id &char, xs &u8, ys &u8, count i32, spec Spec_c) {
	C.ImPlot_PlotLine_U8PtrU8Ptr(label_id, xs, ys, count, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotLine_S16PtrS16Ptr(label_id &char, xs &i16, ys &i16, count i32, spec Spec_c)

@[inline]
pub fn plot_line_s16_ptr_s16_ptr(label_id &char, xs &i16, ys &i16, count i32, spec Spec_c) {
	C.ImPlot_PlotLine_S16PtrS16Ptr(label_id, xs, ys, count, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotLine_U16PtrU16Ptr(label_id &char, xs &u16, ys &u16, count i32, spec Spec_c)

@[inline]
pub fn plot_line_u16_ptr_u16_ptr(label_id &char, xs &u16, ys &u16, count i32, spec Spec_c) {
	C.ImPlot_PlotLine_U16PtrU16Ptr(label_id, xs, ys, count, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotLine_S32PtrS32Ptr(label_id &char, xs &i32, ys &i32, count i32, spec Spec_c)

@[inline]
pub fn plot_line_s32_ptr_s32_ptr(label_id &char, xs &i32, ys &i32, count i32, spec Spec_c) {
	C.ImPlot_PlotLine_S32PtrS32Ptr(label_id, xs, ys, count, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotLine_U32PtrU32Ptr(label_id &char, xs &u32, ys &u32, count i32, spec Spec_c)

@[inline]
pub fn plot_line_u32_ptr_u32_ptr(label_id &char, xs &u32, ys &u32, count i32, spec Spec_c) {
	C.ImPlot_PlotLine_U32PtrU32Ptr(label_id, xs, ys, count, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotLine_S64PtrS64Ptr(label_id &char, xs &i64, ys &i64, count i32, spec Spec_c)

@[inline]
pub fn plot_line_s64_ptr_s64_ptr(label_id &char, xs &i64, ys &i64, count i32, spec Spec_c) {
	C.ImPlot_PlotLine_S64PtrS64Ptr(label_id, xs, ys, count, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotLine_U64PtrU64Ptr(label_id &char, xs &u64, ys &u64, count i32, spec Spec_c)

@[inline]
pub fn plot_line_u64_ptr_u64_ptr(label_id &char, xs &u64, ys &u64, count i32, spec Spec_c) {
	C.ImPlot_PlotLine_U64PtrU64Ptr(label_id, xs, ys, count, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotLineG_LJ(label_id &char, getter Point_getter, data voidptr, count i32, spec Spec_c)

@[inline]
pub fn plot_line_g_lj(label_id &char, getter Point_getter, data voidptr, count i32, spec Spec_c) {
	C.ImPlot_PlotLineG_LJ(label_id, getter, data, count, spec)
}

// custom generation

@[keep_args_alive]
fn C.ImPlot_PlotLineG(label_id &char, getter Getter, data voidptr, count i32, spec Spec_c)

@[inline]
pub fn plot_line_g(label_id &char, getter Getter, data voidptr, count i32, spec Spec_c) {
	C.ImPlot_PlotLineG(label_id, getter, data, count, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotScatter_FloatPtrInt(label_id &char, values &f32, count i32, xscale f64, xstart f64, spec Spec_c)

@[inline]
pub fn plot_scatter_float_ptr_int(label_id &char, values &f32, count i32, xscale f64, xstart f64, spec Spec_c) {
	C.ImPlot_PlotScatter_FloatPtrInt(label_id, values, count, xscale, xstart, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotScatter_doublePtrInt(label_id &char, values &f64, count i32, xscale f64, xstart f64, spec Spec_c)

@[inline]
pub fn plot_scatter_double_ptr_int(label_id &char, values &f64, count i32, xscale f64, xstart f64, spec Spec_c) {
	C.ImPlot_PlotScatter_doublePtrInt(label_id, values, count, xscale, xstart, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotScatter_S8PtrInt(label_id &char, values &char, count i32, xscale f64, xstart f64, spec Spec_c)

@[inline]
pub fn plot_scatter_s8_ptr_int(label_id &char, values &char, count i32, xscale f64, xstart f64, spec Spec_c) {
	C.ImPlot_PlotScatter_S8PtrInt(label_id, values, count, xscale, xstart, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotScatter_U8PtrInt(label_id &char, values &u8, count i32, xscale f64, xstart f64, spec Spec_c)

@[inline]
pub fn plot_scatter_u8_ptr_int(label_id &char, values &u8, count i32, xscale f64, xstart f64, spec Spec_c) {
	C.ImPlot_PlotScatter_U8PtrInt(label_id, values, count, xscale, xstart, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotScatter_S16PtrInt(label_id &char, values &i16, count i32, xscale f64, xstart f64, spec Spec_c)

@[inline]
pub fn plot_scatter_s16_ptr_int(label_id &char, values &i16, count i32, xscale f64, xstart f64, spec Spec_c) {
	C.ImPlot_PlotScatter_S16PtrInt(label_id, values, count, xscale, xstart, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotScatter_U16PtrInt(label_id &char, values &u16, count i32, xscale f64, xstart f64, spec Spec_c)

@[inline]
pub fn plot_scatter_u16_ptr_int(label_id &char, values &u16, count i32, xscale f64, xstart f64, spec Spec_c) {
	C.ImPlot_PlotScatter_U16PtrInt(label_id, values, count, xscale, xstart, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotScatter_S32PtrInt(label_id &char, values &i32, count i32, xscale f64, xstart f64, spec Spec_c)

@[inline]
pub fn plot_scatter_s32_ptr_int(label_id &char, values &i32, count i32, xscale f64, xstart f64, spec Spec_c) {
	C.ImPlot_PlotScatter_S32PtrInt(label_id, values, count, xscale, xstart, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotScatter_U32PtrInt(label_id &char, values &u32, count i32, xscale f64, xstart f64, spec Spec_c)

@[inline]
pub fn plot_scatter_u32_ptr_int(label_id &char, values &u32, count i32, xscale f64, xstart f64, spec Spec_c) {
	C.ImPlot_PlotScatter_U32PtrInt(label_id, values, count, xscale, xstart, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotScatter_S64PtrInt(label_id &char, values &i64, count i32, xscale f64, xstart f64, spec Spec_c)

@[inline]
pub fn plot_scatter_s64_ptr_int(label_id &char, values &i64, count i32, xscale f64, xstart f64, spec Spec_c) {
	C.ImPlot_PlotScatter_S64PtrInt(label_id, values, count, xscale, xstart, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotScatter_U64PtrInt(label_id &char, values &u64, count i32, xscale f64, xstart f64, spec Spec_c)

@[inline]
pub fn plot_scatter_u64_ptr_int(label_id &char, values &u64, count i32, xscale f64, xstart f64, spec Spec_c) {
	C.ImPlot_PlotScatter_U64PtrInt(label_id, values, count, xscale, xstart, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotScatter_FloatPtrFloatPtr(label_id &char, xs &f32, ys &f32, count i32, spec Spec_c)

@[inline]
pub fn plot_scatter_float_ptr_float_ptr(label_id &char, xs &f32, ys &f32, count i32, spec Spec_c) {
	C.ImPlot_PlotScatter_FloatPtrFloatPtr(label_id, xs, ys, count, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotScatter_doublePtrdoublePtr(label_id &char, xs &f64, ys &f64, count i32, spec Spec_c)

@[inline]
pub fn plot_scatter_double_ptrdouble_ptr(label_id &char, xs &f64, ys &f64, count i32, spec Spec_c) {
	C.ImPlot_PlotScatter_doublePtrdoublePtr(label_id, xs, ys, count, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotScatter_S8PtrS8Ptr(label_id &char, xs &char, ys &char, count i32, spec Spec_c)

@[inline]
pub fn plot_scatter_s8_ptr_s8_ptr(label_id &char, xs &char, ys &char, count i32, spec Spec_c) {
	C.ImPlot_PlotScatter_S8PtrS8Ptr(label_id, xs, ys, count, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotScatter_U8PtrU8Ptr(label_id &char, xs &u8, ys &u8, count i32, spec Spec_c)

@[inline]
pub fn plot_scatter_u8_ptr_u8_ptr(label_id &char, xs &u8, ys &u8, count i32, spec Spec_c) {
	C.ImPlot_PlotScatter_U8PtrU8Ptr(label_id, xs, ys, count, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotScatter_S16PtrS16Ptr(label_id &char, xs &i16, ys &i16, count i32, spec Spec_c)

@[inline]
pub fn plot_scatter_s16_ptr_s16_ptr(label_id &char, xs &i16, ys &i16, count i32, spec Spec_c) {
	C.ImPlot_PlotScatter_S16PtrS16Ptr(label_id, xs, ys, count, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotScatter_U16PtrU16Ptr(label_id &char, xs &u16, ys &u16, count i32, spec Spec_c)

@[inline]
pub fn plot_scatter_u16_ptr_u16_ptr(label_id &char, xs &u16, ys &u16, count i32, spec Spec_c) {
	C.ImPlot_PlotScatter_U16PtrU16Ptr(label_id, xs, ys, count, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotScatter_S32PtrS32Ptr(label_id &char, xs &i32, ys &i32, count i32, spec Spec_c)

@[inline]
pub fn plot_scatter_s32_ptr_s32_ptr(label_id &char, xs &i32, ys &i32, count i32, spec Spec_c) {
	C.ImPlot_PlotScatter_S32PtrS32Ptr(label_id, xs, ys, count, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotScatter_U32PtrU32Ptr(label_id &char, xs &u32, ys &u32, count i32, spec Spec_c)

@[inline]
pub fn plot_scatter_u32_ptr_u32_ptr(label_id &char, xs &u32, ys &u32, count i32, spec Spec_c) {
	C.ImPlot_PlotScatter_U32PtrU32Ptr(label_id, xs, ys, count, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotScatter_S64PtrS64Ptr(label_id &char, xs &i64, ys &i64, count i32, spec Spec_c)

@[inline]
pub fn plot_scatter_s64_ptr_s64_ptr(label_id &char, xs &i64, ys &i64, count i32, spec Spec_c) {
	C.ImPlot_PlotScatter_S64PtrS64Ptr(label_id, xs, ys, count, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotScatter_U64PtrU64Ptr(label_id &char, xs &u64, ys &u64, count i32, spec Spec_c)

@[inline]
pub fn plot_scatter_u64_ptr_u64_ptr(label_id &char, xs &u64, ys &u64, count i32, spec Spec_c) {
	C.ImPlot_PlotScatter_U64PtrU64Ptr(label_id, xs, ys, count, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotScatterG_LJ(label_id &char, getter Point_getter, data voidptr, count i32, spec Spec_c)

@[inline]
pub fn plot_scatter_g_lj(label_id &char, getter Point_getter, data voidptr, count i32, spec Spec_c) {
	C.ImPlot_PlotScatterG_LJ(label_id, getter, data, count, spec)
}

// custom generation

@[keep_args_alive]
fn C.ImPlot_PlotScatterG(label_id &char, getter Getter, data voidptr, count i32, spec Spec_c)

@[inline]
pub fn plot_scatter_g(label_id &char, getter Getter, data voidptr, count i32, spec Spec_c) {
	C.ImPlot_PlotScatterG(label_id, getter, data, count, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotBubbles_FloatPtrFloatPtrInt(label_id &char, values &f32, szs &f32, count i32, xscale f64, xstart f64, spec Spec_c)

@[inline]
pub fn plot_bubbles_float_ptr_float_ptr_int(label_id &char, values &f32, szs &f32, count i32, xscale f64, xstart f64, spec Spec_c) {
	C.ImPlot_PlotBubbles_FloatPtrFloatPtrInt(label_id, values, szs, count, xscale, xstart, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotBubbles_doublePtrdoublePtrInt(label_id &char, values &f64, szs &f64, count i32, xscale f64, xstart f64, spec Spec_c)

@[inline]
pub fn plot_bubbles_double_ptrdouble_ptr_int(label_id &char, values &f64, szs &f64, count i32, xscale f64, xstart f64, spec Spec_c) {
	C.ImPlot_PlotBubbles_doublePtrdoublePtrInt(label_id, values, szs, count, xscale, xstart, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotBubbles_S8PtrS8PtrInt(label_id &char, values &char, szs &char, count i32, xscale f64, xstart f64, spec Spec_c)

@[inline]
pub fn plot_bubbles_s8_ptr_s8_ptr_int(label_id &char, values &char, szs &char, count i32, xscale f64, xstart f64, spec Spec_c) {
	C.ImPlot_PlotBubbles_S8PtrS8PtrInt(label_id, values, szs, count, xscale, xstart, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotBubbles_U8PtrU8PtrInt(label_id &char, values &u8, szs &u8, count i32, xscale f64, xstart f64, spec Spec_c)

@[inline]
pub fn plot_bubbles_u8_ptr_u8_ptr_int(label_id &char, values &u8, szs &u8, count i32, xscale f64, xstart f64, spec Spec_c) {
	C.ImPlot_PlotBubbles_U8PtrU8PtrInt(label_id, values, szs, count, xscale, xstart, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotBubbles_S16PtrS16PtrInt(label_id &char, values &i16, szs &i16, count i32, xscale f64, xstart f64, spec Spec_c)

@[inline]
pub fn plot_bubbles_s16_ptr_s16_ptr_int(label_id &char, values &i16, szs &i16, count i32, xscale f64, xstart f64, spec Spec_c) {
	C.ImPlot_PlotBubbles_S16PtrS16PtrInt(label_id, values, szs, count, xscale, xstart, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotBubbles_U16PtrU16PtrInt(label_id &char, values &u16, szs &u16, count i32, xscale f64, xstart f64, spec Spec_c)

@[inline]
pub fn plot_bubbles_u16_ptr_u16_ptr_int(label_id &char, values &u16, szs &u16, count i32, xscale f64, xstart f64, spec Spec_c) {
	C.ImPlot_PlotBubbles_U16PtrU16PtrInt(label_id, values, szs, count, xscale, xstart, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotBubbles_S32PtrS32PtrInt(label_id &char, values &i32, szs &i32, count i32, xscale f64, xstart f64, spec Spec_c)

@[inline]
pub fn plot_bubbles_s32_ptr_s32_ptr_int(label_id &char, values &i32, szs &i32, count i32, xscale f64, xstart f64, spec Spec_c) {
	C.ImPlot_PlotBubbles_S32PtrS32PtrInt(label_id, values, szs, count, xscale, xstart, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotBubbles_U32PtrU32PtrInt(label_id &char, values &u32, szs &u32, count i32, xscale f64, xstart f64, spec Spec_c)

@[inline]
pub fn plot_bubbles_u32_ptr_u32_ptr_int(label_id &char, values &u32, szs &u32, count i32, xscale f64, xstart f64, spec Spec_c) {
	C.ImPlot_PlotBubbles_U32PtrU32PtrInt(label_id, values, szs, count, xscale, xstart, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotBubbles_S64PtrS64PtrInt(label_id &char, values &i64, szs &i64, count i32, xscale f64, xstart f64, spec Spec_c)

@[inline]
pub fn plot_bubbles_s64_ptr_s64_ptr_int(label_id &char, values &i64, szs &i64, count i32, xscale f64, xstart f64, spec Spec_c) {
	C.ImPlot_PlotBubbles_S64PtrS64PtrInt(label_id, values, szs, count, xscale, xstart, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotBubbles_U64PtrU64PtrInt(label_id &char, values &u64, szs &u64, count i32, xscale f64, xstart f64, spec Spec_c)

@[inline]
pub fn plot_bubbles_u64_ptr_u64_ptr_int(label_id &char, values &u64, szs &u64, count i32, xscale f64, xstart f64, spec Spec_c) {
	C.ImPlot_PlotBubbles_U64PtrU64PtrInt(label_id, values, szs, count, xscale, xstart, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotBubbles_FloatPtrFloatPtrFloatPtr(label_id &char, xs &f32, ys &f32, szs &f32, count i32, spec Spec_c)

@[inline]
pub fn plot_bubbles_float_ptr_float_ptr_float_ptr(label_id &char, xs &f32, ys &f32, szs &f32, count i32, spec Spec_c) {
	C.ImPlot_PlotBubbles_FloatPtrFloatPtrFloatPtr(label_id, xs, ys, szs, count, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotBubbles_doublePtrdoublePtrdoublePtr(label_id &char, xs &f64, ys &f64, szs &f64, count i32, spec Spec_c)

@[inline]
pub fn plot_bubbles_double_ptrdouble_ptrdouble_ptr(label_id &char, xs &f64, ys &f64, szs &f64, count i32, spec Spec_c) {
	C.ImPlot_PlotBubbles_doublePtrdoublePtrdoublePtr(label_id, xs, ys, szs, count, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotBubbles_S8PtrS8PtrS8Ptr(label_id &char, xs &char, ys &char, szs &char, count i32, spec Spec_c)

@[inline]
pub fn plot_bubbles_s8_ptr_s8_ptr_s8_ptr(label_id &char, xs &char, ys &char, szs &char, count i32, spec Spec_c) {
	C.ImPlot_PlotBubbles_S8PtrS8PtrS8Ptr(label_id, xs, ys, szs, count, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotBubbles_U8PtrU8PtrU8Ptr(label_id &char, xs &u8, ys &u8, szs &u8, count i32, spec Spec_c)

@[inline]
pub fn plot_bubbles_u8_ptr_u8_ptr_u8_ptr(label_id &char, xs &u8, ys &u8, szs &u8, count i32, spec Spec_c) {
	C.ImPlot_PlotBubbles_U8PtrU8PtrU8Ptr(label_id, xs, ys, szs, count, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotBubbles_S16PtrS16PtrS16Ptr(label_id &char, xs &i16, ys &i16, szs &i16, count i32, spec Spec_c)

@[inline]
pub fn plot_bubbles_s16_ptr_s16_ptr_s16_ptr(label_id &char, xs &i16, ys &i16, szs &i16, count i32, spec Spec_c) {
	C.ImPlot_PlotBubbles_S16PtrS16PtrS16Ptr(label_id, xs, ys, szs, count, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotBubbles_U16PtrU16PtrU16Ptr(label_id &char, xs &u16, ys &u16, szs &u16, count i32, spec Spec_c)

@[inline]
pub fn plot_bubbles_u16_ptr_u16_ptr_u16_ptr(label_id &char, xs &u16, ys &u16, szs &u16, count i32, spec Spec_c) {
	C.ImPlot_PlotBubbles_U16PtrU16PtrU16Ptr(label_id, xs, ys, szs, count, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotBubbles_S32PtrS32PtrS32Ptr(label_id &char, xs &i32, ys &i32, szs &i32, count i32, spec Spec_c)

@[inline]
pub fn plot_bubbles_s32_ptr_s32_ptr_s32_ptr(label_id &char, xs &i32, ys &i32, szs &i32, count i32, spec Spec_c) {
	C.ImPlot_PlotBubbles_S32PtrS32PtrS32Ptr(label_id, xs, ys, szs, count, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotBubbles_U32PtrU32PtrU32Ptr(label_id &char, xs &u32, ys &u32, szs &u32, count i32, spec Spec_c)

@[inline]
pub fn plot_bubbles_u32_ptr_u32_ptr_u32_ptr(label_id &char, xs &u32, ys &u32, szs &u32, count i32, spec Spec_c) {
	C.ImPlot_PlotBubbles_U32PtrU32PtrU32Ptr(label_id, xs, ys, szs, count, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotBubbles_S64PtrS64PtrS64Ptr(label_id &char, xs &i64, ys &i64, szs &i64, count i32, spec Spec_c)

@[inline]
pub fn plot_bubbles_s64_ptr_s64_ptr_s64_ptr(label_id &char, xs &i64, ys &i64, szs &i64, count i32, spec Spec_c) {
	C.ImPlot_PlotBubbles_S64PtrS64PtrS64Ptr(label_id, xs, ys, szs, count, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotBubbles_U64PtrU64PtrU64Ptr(label_id &char, xs &u64, ys &u64, szs &u64, count i32, spec Spec_c)

@[inline]
pub fn plot_bubbles_u64_ptr_u64_ptr_u64_ptr(label_id &char, xs &u64, ys &u64, szs &u64, count i32, spec Spec_c) {
	C.ImPlot_PlotBubbles_U64PtrU64PtrU64Ptr(label_id, xs, ys, szs, count, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotPolygon_FloatPtr(label_id &char, xs &f32, ys &f32, count i32, spec Spec_c)

@[inline]
pub fn plot_polygon_float_ptr(label_id &char, xs &f32, ys &f32, count i32, spec Spec_c) {
	C.ImPlot_PlotPolygon_FloatPtr(label_id, xs, ys, count, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotPolygon_doublePtr(label_id &char, xs &f64, ys &f64, count i32, spec Spec_c)

@[inline]
pub fn plot_polygon_double_ptr(label_id &char, xs &f64, ys &f64, count i32, spec Spec_c) {
	C.ImPlot_PlotPolygon_doublePtr(label_id, xs, ys, count, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotPolygon_S8Ptr(label_id &char, xs &char, ys &char, count i32, spec Spec_c)

@[inline]
pub fn plot_polygon_s8_ptr(label_id &char, xs &char, ys &char, count i32, spec Spec_c) {
	C.ImPlot_PlotPolygon_S8Ptr(label_id, xs, ys, count, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotPolygon_U8Ptr(label_id &char, xs &u8, ys &u8, count i32, spec Spec_c)

@[inline]
pub fn plot_polygon_u8_ptr(label_id &char, xs &u8, ys &u8, count i32, spec Spec_c) {
	C.ImPlot_PlotPolygon_U8Ptr(label_id, xs, ys, count, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotPolygon_S16Ptr(label_id &char, xs &i16, ys &i16, count i32, spec Spec_c)

@[inline]
pub fn plot_polygon_s16_ptr(label_id &char, xs &i16, ys &i16, count i32, spec Spec_c) {
	C.ImPlot_PlotPolygon_S16Ptr(label_id, xs, ys, count, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotPolygon_U16Ptr(label_id &char, xs &u16, ys &u16, count i32, spec Spec_c)

@[inline]
pub fn plot_polygon_u16_ptr(label_id &char, xs &u16, ys &u16, count i32, spec Spec_c) {
	C.ImPlot_PlotPolygon_U16Ptr(label_id, xs, ys, count, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotPolygon_S32Ptr(label_id &char, xs &i32, ys &i32, count i32, spec Spec_c)

@[inline]
pub fn plot_polygon_s32_ptr(label_id &char, xs &i32, ys &i32, count i32, spec Spec_c) {
	C.ImPlot_PlotPolygon_S32Ptr(label_id, xs, ys, count, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotPolygon_U32Ptr(label_id &char, xs &u32, ys &u32, count i32, spec Spec_c)

@[inline]
pub fn plot_polygon_u32_ptr(label_id &char, xs &u32, ys &u32, count i32, spec Spec_c) {
	C.ImPlot_PlotPolygon_U32Ptr(label_id, xs, ys, count, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotPolygon_S64Ptr(label_id &char, xs &i64, ys &i64, count i32, spec Spec_c)

@[inline]
pub fn plot_polygon_s64_ptr(label_id &char, xs &i64, ys &i64, count i32, spec Spec_c) {
	C.ImPlot_PlotPolygon_S64Ptr(label_id, xs, ys, count, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotPolygon_U64Ptr(label_id &char, xs &u64, ys &u64, count i32, spec Spec_c)

@[inline]
pub fn plot_polygon_u64_ptr(label_id &char, xs &u64, ys &u64, count i32, spec Spec_c) {
	C.ImPlot_PlotPolygon_U64Ptr(label_id, xs, ys, count, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotStairs_FloatPtrInt(label_id &char, values &f32, count i32, xscale f64, xstart f64, spec Spec_c)

@[inline]
pub fn plot_stairs_float_ptr_int(label_id &char, values &f32, count i32, xscale f64, xstart f64, spec Spec_c) {
	C.ImPlot_PlotStairs_FloatPtrInt(label_id, values, count, xscale, xstart, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotStairs_doublePtrInt(label_id &char, values &f64, count i32, xscale f64, xstart f64, spec Spec_c)

@[inline]
pub fn plot_stairs_double_ptr_int(label_id &char, values &f64, count i32, xscale f64, xstart f64, spec Spec_c) {
	C.ImPlot_PlotStairs_doublePtrInt(label_id, values, count, xscale, xstart, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotStairs_S8PtrInt(label_id &char, values &char, count i32, xscale f64, xstart f64, spec Spec_c)

@[inline]
pub fn plot_stairs_s8_ptr_int(label_id &char, values &char, count i32, xscale f64, xstart f64, spec Spec_c) {
	C.ImPlot_PlotStairs_S8PtrInt(label_id, values, count, xscale, xstart, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotStairs_U8PtrInt(label_id &char, values &u8, count i32, xscale f64, xstart f64, spec Spec_c)

@[inline]
pub fn plot_stairs_u8_ptr_int(label_id &char, values &u8, count i32, xscale f64, xstart f64, spec Spec_c) {
	C.ImPlot_PlotStairs_U8PtrInt(label_id, values, count, xscale, xstart, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotStairs_S16PtrInt(label_id &char, values &i16, count i32, xscale f64, xstart f64, spec Spec_c)

@[inline]
pub fn plot_stairs_s16_ptr_int(label_id &char, values &i16, count i32, xscale f64, xstart f64, spec Spec_c) {
	C.ImPlot_PlotStairs_S16PtrInt(label_id, values, count, xscale, xstart, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotStairs_U16PtrInt(label_id &char, values &u16, count i32, xscale f64, xstart f64, spec Spec_c)

@[inline]
pub fn plot_stairs_u16_ptr_int(label_id &char, values &u16, count i32, xscale f64, xstart f64, spec Spec_c) {
	C.ImPlot_PlotStairs_U16PtrInt(label_id, values, count, xscale, xstart, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotStairs_S32PtrInt(label_id &char, values &i32, count i32, xscale f64, xstart f64, spec Spec_c)

@[inline]
pub fn plot_stairs_s32_ptr_int(label_id &char, values &i32, count i32, xscale f64, xstart f64, spec Spec_c) {
	C.ImPlot_PlotStairs_S32PtrInt(label_id, values, count, xscale, xstart, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotStairs_U32PtrInt(label_id &char, values &u32, count i32, xscale f64, xstart f64, spec Spec_c)

@[inline]
pub fn plot_stairs_u32_ptr_int(label_id &char, values &u32, count i32, xscale f64, xstart f64, spec Spec_c) {
	C.ImPlot_PlotStairs_U32PtrInt(label_id, values, count, xscale, xstart, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotStairs_S64PtrInt(label_id &char, values &i64, count i32, xscale f64, xstart f64, spec Spec_c)

@[inline]
pub fn plot_stairs_s64_ptr_int(label_id &char, values &i64, count i32, xscale f64, xstart f64, spec Spec_c) {
	C.ImPlot_PlotStairs_S64PtrInt(label_id, values, count, xscale, xstart, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotStairs_U64PtrInt(label_id &char, values &u64, count i32, xscale f64, xstart f64, spec Spec_c)

@[inline]
pub fn plot_stairs_u64_ptr_int(label_id &char, values &u64, count i32, xscale f64, xstart f64, spec Spec_c) {
	C.ImPlot_PlotStairs_U64PtrInt(label_id, values, count, xscale, xstart, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotStairs_FloatPtrFloatPtr(label_id &char, xs &f32, ys &f32, count i32, spec Spec_c)

@[inline]
pub fn plot_stairs_float_ptr_float_ptr(label_id &char, xs &f32, ys &f32, count i32, spec Spec_c) {
	C.ImPlot_PlotStairs_FloatPtrFloatPtr(label_id, xs, ys, count, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotStairs_doublePtrdoublePtr(label_id &char, xs &f64, ys &f64, count i32, spec Spec_c)

@[inline]
pub fn plot_stairs_double_ptrdouble_ptr(label_id &char, xs &f64, ys &f64, count i32, spec Spec_c) {
	C.ImPlot_PlotStairs_doublePtrdoublePtr(label_id, xs, ys, count, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotStairs_S8PtrS8Ptr(label_id &char, xs &char, ys &char, count i32, spec Spec_c)

@[inline]
pub fn plot_stairs_s8_ptr_s8_ptr(label_id &char, xs &char, ys &char, count i32, spec Spec_c) {
	C.ImPlot_PlotStairs_S8PtrS8Ptr(label_id, xs, ys, count, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotStairs_U8PtrU8Ptr(label_id &char, xs &u8, ys &u8, count i32, spec Spec_c)

@[inline]
pub fn plot_stairs_u8_ptr_u8_ptr(label_id &char, xs &u8, ys &u8, count i32, spec Spec_c) {
	C.ImPlot_PlotStairs_U8PtrU8Ptr(label_id, xs, ys, count, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotStairs_S16PtrS16Ptr(label_id &char, xs &i16, ys &i16, count i32, spec Spec_c)

@[inline]
pub fn plot_stairs_s16_ptr_s16_ptr(label_id &char, xs &i16, ys &i16, count i32, spec Spec_c) {
	C.ImPlot_PlotStairs_S16PtrS16Ptr(label_id, xs, ys, count, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotStairs_U16PtrU16Ptr(label_id &char, xs &u16, ys &u16, count i32, spec Spec_c)

@[inline]
pub fn plot_stairs_u16_ptr_u16_ptr(label_id &char, xs &u16, ys &u16, count i32, spec Spec_c) {
	C.ImPlot_PlotStairs_U16PtrU16Ptr(label_id, xs, ys, count, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotStairs_S32PtrS32Ptr(label_id &char, xs &i32, ys &i32, count i32, spec Spec_c)

@[inline]
pub fn plot_stairs_s32_ptr_s32_ptr(label_id &char, xs &i32, ys &i32, count i32, spec Spec_c) {
	C.ImPlot_PlotStairs_S32PtrS32Ptr(label_id, xs, ys, count, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotStairs_U32PtrU32Ptr(label_id &char, xs &u32, ys &u32, count i32, spec Spec_c)

@[inline]
pub fn plot_stairs_u32_ptr_u32_ptr(label_id &char, xs &u32, ys &u32, count i32, spec Spec_c) {
	C.ImPlot_PlotStairs_U32PtrU32Ptr(label_id, xs, ys, count, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotStairs_S64PtrS64Ptr(label_id &char, xs &i64, ys &i64, count i32, spec Spec_c)

@[inline]
pub fn plot_stairs_s64_ptr_s64_ptr(label_id &char, xs &i64, ys &i64, count i32, spec Spec_c) {
	C.ImPlot_PlotStairs_S64PtrS64Ptr(label_id, xs, ys, count, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotStairs_U64PtrU64Ptr(label_id &char, xs &u64, ys &u64, count i32, spec Spec_c)

@[inline]
pub fn plot_stairs_u64_ptr_u64_ptr(label_id &char, xs &u64, ys &u64, count i32, spec Spec_c) {
	C.ImPlot_PlotStairs_U64PtrU64Ptr(label_id, xs, ys, count, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotStairsG_LJ(label_id &char, getter Point_getter, data voidptr, count i32, spec Spec_c)

@[inline]
pub fn plot_stairs_g_lj(label_id &char, getter Point_getter, data voidptr, count i32, spec Spec_c) {
	C.ImPlot_PlotStairsG_LJ(label_id, getter, data, count, spec)
}

// custom generation

@[keep_args_alive]
fn C.ImPlot_PlotStairsG(label_id &char, getter Getter, data voidptr, count i32, spec Spec_c)

@[inline]
pub fn plot_stairs_g(label_id &char, getter Getter, data voidptr, count i32, spec Spec_c) {
	C.ImPlot_PlotStairsG(label_id, getter, data, count, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotShaded_FloatPtrInt(label_id &char, values &f32, count i32, yref f64, xscale f64, xstart f64, spec Spec_c)

@[inline]
pub fn plot_shaded_float_ptr_int(label_id &char, values &f32, count i32, yref f64, xscale f64, xstart f64, spec Spec_c) {
	C.ImPlot_PlotShaded_FloatPtrInt(label_id, values, count, yref, xscale, xstart, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotShaded_doublePtrInt(label_id &char, values &f64, count i32, yref f64, xscale f64, xstart f64, spec Spec_c)

@[inline]
pub fn plot_shaded_double_ptr_int(label_id &char, values &f64, count i32, yref f64, xscale f64, xstart f64, spec Spec_c) {
	C.ImPlot_PlotShaded_doublePtrInt(label_id, values, count, yref, xscale, xstart, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotShaded_S8PtrInt(label_id &char, values &char, count i32, yref f64, xscale f64, xstart f64, spec Spec_c)

@[inline]
pub fn plot_shaded_s8_ptr_int(label_id &char, values &char, count i32, yref f64, xscale f64, xstart f64, spec Spec_c) {
	C.ImPlot_PlotShaded_S8PtrInt(label_id, values, count, yref, xscale, xstart, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotShaded_U8PtrInt(label_id &char, values &u8, count i32, yref f64, xscale f64, xstart f64, spec Spec_c)

@[inline]
pub fn plot_shaded_u8_ptr_int(label_id &char, values &u8, count i32, yref f64, xscale f64, xstart f64, spec Spec_c) {
	C.ImPlot_PlotShaded_U8PtrInt(label_id, values, count, yref, xscale, xstart, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotShaded_S16PtrInt(label_id &char, values &i16, count i32, yref f64, xscale f64, xstart f64, spec Spec_c)

@[inline]
pub fn plot_shaded_s16_ptr_int(label_id &char, values &i16, count i32, yref f64, xscale f64, xstart f64, spec Spec_c) {
	C.ImPlot_PlotShaded_S16PtrInt(label_id, values, count, yref, xscale, xstart, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotShaded_U16PtrInt(label_id &char, values &u16, count i32, yref f64, xscale f64, xstart f64, spec Spec_c)

@[inline]
pub fn plot_shaded_u16_ptr_int(label_id &char, values &u16, count i32, yref f64, xscale f64, xstart f64, spec Spec_c) {
	C.ImPlot_PlotShaded_U16PtrInt(label_id, values, count, yref, xscale, xstart, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotShaded_S32PtrInt(label_id &char, values &i32, count i32, yref f64, xscale f64, xstart f64, spec Spec_c)

@[inline]
pub fn plot_shaded_s32_ptr_int(label_id &char, values &i32, count i32, yref f64, xscale f64, xstart f64, spec Spec_c) {
	C.ImPlot_PlotShaded_S32PtrInt(label_id, values, count, yref, xscale, xstart, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotShaded_U32PtrInt(label_id &char, values &u32, count i32, yref f64, xscale f64, xstart f64, spec Spec_c)

@[inline]
pub fn plot_shaded_u32_ptr_int(label_id &char, values &u32, count i32, yref f64, xscale f64, xstart f64, spec Spec_c) {
	C.ImPlot_PlotShaded_U32PtrInt(label_id, values, count, yref, xscale, xstart, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotShaded_S64PtrInt(label_id &char, values &i64, count i32, yref f64, xscale f64, xstart f64, spec Spec_c)

@[inline]
pub fn plot_shaded_s64_ptr_int(label_id &char, values &i64, count i32, yref f64, xscale f64, xstart f64, spec Spec_c) {
	C.ImPlot_PlotShaded_S64PtrInt(label_id, values, count, yref, xscale, xstart, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotShaded_U64PtrInt(label_id &char, values &u64, count i32, yref f64, xscale f64, xstart f64, spec Spec_c)

@[inline]
pub fn plot_shaded_u64_ptr_int(label_id &char, values &u64, count i32, yref f64, xscale f64, xstart f64, spec Spec_c) {
	C.ImPlot_PlotShaded_U64PtrInt(label_id, values, count, yref, xscale, xstart, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotShaded_FloatPtrFloatPtrInt(label_id &char, xs &f32, ys &f32, count i32, yref f64, spec Spec_c)

@[inline]
pub fn plot_shaded_float_ptr_float_ptr_int(label_id &char, xs &f32, ys &f32, count i32, yref f64, spec Spec_c) {
	C.ImPlot_PlotShaded_FloatPtrFloatPtrInt(label_id, xs, ys, count, yref, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotShaded_doublePtrdoublePtrInt(label_id &char, xs &f64, ys &f64, count i32, yref f64, spec Spec_c)

@[inline]
pub fn plot_shaded_double_ptrdouble_ptr_int(label_id &char, xs &f64, ys &f64, count i32, yref f64, spec Spec_c) {
	C.ImPlot_PlotShaded_doublePtrdoublePtrInt(label_id, xs, ys, count, yref, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotShaded_S8PtrS8PtrInt(label_id &char, xs &char, ys &char, count i32, yref f64, spec Spec_c)

@[inline]
pub fn plot_shaded_s8_ptr_s8_ptr_int(label_id &char, xs &char, ys &char, count i32, yref f64, spec Spec_c) {
	C.ImPlot_PlotShaded_S8PtrS8PtrInt(label_id, xs, ys, count, yref, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotShaded_U8PtrU8PtrInt(label_id &char, xs &u8, ys &u8, count i32, yref f64, spec Spec_c)

@[inline]
pub fn plot_shaded_u8_ptr_u8_ptr_int(label_id &char, xs &u8, ys &u8, count i32, yref f64, spec Spec_c) {
	C.ImPlot_PlotShaded_U8PtrU8PtrInt(label_id, xs, ys, count, yref, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotShaded_S16PtrS16PtrInt(label_id &char, xs &i16, ys &i16, count i32, yref f64, spec Spec_c)

@[inline]
pub fn plot_shaded_s16_ptr_s16_ptr_int(label_id &char, xs &i16, ys &i16, count i32, yref f64, spec Spec_c) {
	C.ImPlot_PlotShaded_S16PtrS16PtrInt(label_id, xs, ys, count, yref, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotShaded_U16PtrU16PtrInt(label_id &char, xs &u16, ys &u16, count i32, yref f64, spec Spec_c)

@[inline]
pub fn plot_shaded_u16_ptr_u16_ptr_int(label_id &char, xs &u16, ys &u16, count i32, yref f64, spec Spec_c) {
	C.ImPlot_PlotShaded_U16PtrU16PtrInt(label_id, xs, ys, count, yref, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotShaded_S32PtrS32PtrInt(label_id &char, xs &i32, ys &i32, count i32, yref f64, spec Spec_c)

@[inline]
pub fn plot_shaded_s32_ptr_s32_ptr_int(label_id &char, xs &i32, ys &i32, count i32, yref f64, spec Spec_c) {
	C.ImPlot_PlotShaded_S32PtrS32PtrInt(label_id, xs, ys, count, yref, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotShaded_U32PtrU32PtrInt(label_id &char, xs &u32, ys &u32, count i32, yref f64, spec Spec_c)

@[inline]
pub fn plot_shaded_u32_ptr_u32_ptr_int(label_id &char, xs &u32, ys &u32, count i32, yref f64, spec Spec_c) {
	C.ImPlot_PlotShaded_U32PtrU32PtrInt(label_id, xs, ys, count, yref, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotShaded_S64PtrS64PtrInt(label_id &char, xs &i64, ys &i64, count i32, yref f64, spec Spec_c)

@[inline]
pub fn plot_shaded_s64_ptr_s64_ptr_int(label_id &char, xs &i64, ys &i64, count i32, yref f64, spec Spec_c) {
	C.ImPlot_PlotShaded_S64PtrS64PtrInt(label_id, xs, ys, count, yref, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotShaded_U64PtrU64PtrInt(label_id &char, xs &u64, ys &u64, count i32, yref f64, spec Spec_c)

@[inline]
pub fn plot_shaded_u64_ptr_u64_ptr_int(label_id &char, xs &u64, ys &u64, count i32, yref f64, spec Spec_c) {
	C.ImPlot_PlotShaded_U64PtrU64PtrInt(label_id, xs, ys, count, yref, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotShaded_FloatPtrFloatPtrFloatPtr(label_id &char, xs &f32, ys1 &f32, ys2 &f32, count i32, spec Spec_c)

@[inline]
pub fn plot_shaded_float_ptr_float_ptr_float_ptr(label_id &char, xs &f32, ys1 &f32, ys2 &f32, count i32, spec Spec_c) {
	C.ImPlot_PlotShaded_FloatPtrFloatPtrFloatPtr(label_id, xs, ys1, ys2, count, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotShaded_doublePtrdoublePtrdoublePtr(label_id &char, xs &f64, ys1 &f64, ys2 &f64, count i32, spec Spec_c)

@[inline]
pub fn plot_shaded_double_ptrdouble_ptrdouble_ptr(label_id &char, xs &f64, ys1 &f64, ys2 &f64, count i32, spec Spec_c) {
	C.ImPlot_PlotShaded_doublePtrdoublePtrdoublePtr(label_id, xs, ys1, ys2, count, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotShaded_S8PtrS8PtrS8Ptr(label_id &char, xs &char, ys1 &char, ys2 &char, count i32, spec Spec_c)

@[inline]
pub fn plot_shaded_s8_ptr_s8_ptr_s8_ptr(label_id &char, xs &char, ys1 &char, ys2 &char, count i32, spec Spec_c) {
	C.ImPlot_PlotShaded_S8PtrS8PtrS8Ptr(label_id, xs, ys1, ys2, count, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotShaded_U8PtrU8PtrU8Ptr(label_id &char, xs &u8, ys1 &u8, ys2 &u8, count i32, spec Spec_c)

@[inline]
pub fn plot_shaded_u8_ptr_u8_ptr_u8_ptr(label_id &char, xs &u8, ys1 &u8, ys2 &u8, count i32, spec Spec_c) {
	C.ImPlot_PlotShaded_U8PtrU8PtrU8Ptr(label_id, xs, ys1, ys2, count, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotShaded_S16PtrS16PtrS16Ptr(label_id &char, xs &i16, ys1 &i16, ys2 &i16, count i32, spec Spec_c)

@[inline]
pub fn plot_shaded_s16_ptr_s16_ptr_s16_ptr(label_id &char, xs &i16, ys1 &i16, ys2 &i16, count i32, spec Spec_c) {
	C.ImPlot_PlotShaded_S16PtrS16PtrS16Ptr(label_id, xs, ys1, ys2, count, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotShaded_U16PtrU16PtrU16Ptr(label_id &char, xs &u16, ys1 &u16, ys2 &u16, count i32, spec Spec_c)

@[inline]
pub fn plot_shaded_u16_ptr_u16_ptr_u16_ptr(label_id &char, xs &u16, ys1 &u16, ys2 &u16, count i32, spec Spec_c) {
	C.ImPlot_PlotShaded_U16PtrU16PtrU16Ptr(label_id, xs, ys1, ys2, count, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotShaded_S32PtrS32PtrS32Ptr(label_id &char, xs &i32, ys1 &i32, ys2 &i32, count i32, spec Spec_c)

@[inline]
pub fn plot_shaded_s32_ptr_s32_ptr_s32_ptr(label_id &char, xs &i32, ys1 &i32, ys2 &i32, count i32, spec Spec_c) {
	C.ImPlot_PlotShaded_S32PtrS32PtrS32Ptr(label_id, xs, ys1, ys2, count, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotShaded_U32PtrU32PtrU32Ptr(label_id &char, xs &u32, ys1 &u32, ys2 &u32, count i32, spec Spec_c)

@[inline]
pub fn plot_shaded_u32_ptr_u32_ptr_u32_ptr(label_id &char, xs &u32, ys1 &u32, ys2 &u32, count i32, spec Spec_c) {
	C.ImPlot_PlotShaded_U32PtrU32PtrU32Ptr(label_id, xs, ys1, ys2, count, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotShaded_S64PtrS64PtrS64Ptr(label_id &char, xs &i64, ys1 &i64, ys2 &i64, count i32, spec Spec_c)

@[inline]
pub fn plot_shaded_s64_ptr_s64_ptr_s64_ptr(label_id &char, xs &i64, ys1 &i64, ys2 &i64, count i32, spec Spec_c) {
	C.ImPlot_PlotShaded_S64PtrS64PtrS64Ptr(label_id, xs, ys1, ys2, count, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotShaded_U64PtrU64PtrU64Ptr(label_id &char, xs &u64, ys1 &u64, ys2 &u64, count i32, spec Spec_c)

@[inline]
pub fn plot_shaded_u64_ptr_u64_ptr_u64_ptr(label_id &char, xs &u64, ys1 &u64, ys2 &u64, count i32, spec Spec_c) {
	C.ImPlot_PlotShaded_U64PtrU64PtrU64Ptr(label_id, xs, ys1, ys2, count, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotShadedG_LJ(label_id &char, getter1 Point_getter, data1 voidptr, getter2 Point_getter, data2 voidptr, count i32, spec Spec_c)

@[inline]
pub fn plot_shaded_g_lj(label_id &char, getter1 Point_getter, data1 voidptr, getter2 Point_getter, data2 voidptr, count i32, spec Spec_c) {
	C.ImPlot_PlotShadedG_LJ(label_id, getter1, data1, getter2, data2, count, spec)
}

// custom generation

@[keep_args_alive]
fn C.ImPlot_PlotShadedG(label_id &char, getter1 Getter, data1 voidptr, getter2 Getter, data2 voidptr, count i32, spec Spec_c)

@[inline]
pub fn plot_shaded_g(label_id &char, getter1 Getter, data1 voidptr, getter2 Getter, data2 voidptr, count i32, spec Spec_c) {
	C.ImPlot_PlotShadedG(label_id, getter1, data1, getter2, data2, count, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotBars_FloatPtrInt(label_id &char, values &f32, count i32, bar_size f64, shift f64, spec Spec_c)

@[inline]
pub fn plot_bars_float_ptr_int(label_id &char, values &f32, count i32, bar_size f64, shift f64, spec Spec_c) {
	C.ImPlot_PlotBars_FloatPtrInt(label_id, values, count, bar_size, shift, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotBars_doublePtrInt(label_id &char, values &f64, count i32, bar_size f64, shift f64, spec Spec_c)

@[inline]
pub fn plot_bars_double_ptr_int(label_id &char, values &f64, count i32, bar_size f64, shift f64, spec Spec_c) {
	C.ImPlot_PlotBars_doublePtrInt(label_id, values, count, bar_size, shift, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotBars_S8PtrInt(label_id &char, values &char, count i32, bar_size f64, shift f64, spec Spec_c)

@[inline]
pub fn plot_bars_s8_ptr_int(label_id &char, values &char, count i32, bar_size f64, shift f64, spec Spec_c) {
	C.ImPlot_PlotBars_S8PtrInt(label_id, values, count, bar_size, shift, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotBars_U8PtrInt(label_id &char, values &u8, count i32, bar_size f64, shift f64, spec Spec_c)

@[inline]
pub fn plot_bars_u8_ptr_int(label_id &char, values &u8, count i32, bar_size f64, shift f64, spec Spec_c) {
	C.ImPlot_PlotBars_U8PtrInt(label_id, values, count, bar_size, shift, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotBars_S16PtrInt(label_id &char, values &i16, count i32, bar_size f64, shift f64, spec Spec_c)

@[inline]
pub fn plot_bars_s16_ptr_int(label_id &char, values &i16, count i32, bar_size f64, shift f64, spec Spec_c) {
	C.ImPlot_PlotBars_S16PtrInt(label_id, values, count, bar_size, shift, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotBars_U16PtrInt(label_id &char, values &u16, count i32, bar_size f64, shift f64, spec Spec_c)

@[inline]
pub fn plot_bars_u16_ptr_int(label_id &char, values &u16, count i32, bar_size f64, shift f64, spec Spec_c) {
	C.ImPlot_PlotBars_U16PtrInt(label_id, values, count, bar_size, shift, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotBars_S32PtrInt(label_id &char, values &i32, count i32, bar_size f64, shift f64, spec Spec_c)

@[inline]
pub fn plot_bars_s32_ptr_int(label_id &char, values &i32, count i32, bar_size f64, shift f64, spec Spec_c) {
	C.ImPlot_PlotBars_S32PtrInt(label_id, values, count, bar_size, shift, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotBars_U32PtrInt(label_id &char, values &u32, count i32, bar_size f64, shift f64, spec Spec_c)

@[inline]
pub fn plot_bars_u32_ptr_int(label_id &char, values &u32, count i32, bar_size f64, shift f64, spec Spec_c) {
	C.ImPlot_PlotBars_U32PtrInt(label_id, values, count, bar_size, shift, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotBars_S64PtrInt(label_id &char, values &i64, count i32, bar_size f64, shift f64, spec Spec_c)

@[inline]
pub fn plot_bars_s64_ptr_int(label_id &char, values &i64, count i32, bar_size f64, shift f64, spec Spec_c) {
	C.ImPlot_PlotBars_S64PtrInt(label_id, values, count, bar_size, shift, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotBars_U64PtrInt(label_id &char, values &u64, count i32, bar_size f64, shift f64, spec Spec_c)

@[inline]
pub fn plot_bars_u64_ptr_int(label_id &char, values &u64, count i32, bar_size f64, shift f64, spec Spec_c) {
	C.ImPlot_PlotBars_U64PtrInt(label_id, values, count, bar_size, shift, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotBars_FloatPtrFloatPtr(label_id &char, xs &f32, ys &f32, count i32, bar_size f64, spec Spec_c)

@[inline]
pub fn plot_bars_float_ptr_float_ptr(label_id &char, xs &f32, ys &f32, count i32, bar_size f64, spec Spec_c) {
	C.ImPlot_PlotBars_FloatPtrFloatPtr(label_id, xs, ys, count, bar_size, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotBars_doublePtrdoublePtr(label_id &char, xs &f64, ys &f64, count i32, bar_size f64, spec Spec_c)

@[inline]
pub fn plot_bars_double_ptrdouble_ptr(label_id &char, xs &f64, ys &f64, count i32, bar_size f64, spec Spec_c) {
	C.ImPlot_PlotBars_doublePtrdoublePtr(label_id, xs, ys, count, bar_size, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotBars_S8PtrS8Ptr(label_id &char, xs &char, ys &char, count i32, bar_size f64, spec Spec_c)

@[inline]
pub fn plot_bars_s8_ptr_s8_ptr(label_id &char, xs &char, ys &char, count i32, bar_size f64, spec Spec_c) {
	C.ImPlot_PlotBars_S8PtrS8Ptr(label_id, xs, ys, count, bar_size, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotBars_U8PtrU8Ptr(label_id &char, xs &u8, ys &u8, count i32, bar_size f64, spec Spec_c)

@[inline]
pub fn plot_bars_u8_ptr_u8_ptr(label_id &char, xs &u8, ys &u8, count i32, bar_size f64, spec Spec_c) {
	C.ImPlot_PlotBars_U8PtrU8Ptr(label_id, xs, ys, count, bar_size, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotBars_S16PtrS16Ptr(label_id &char, xs &i16, ys &i16, count i32, bar_size f64, spec Spec_c)

@[inline]
pub fn plot_bars_s16_ptr_s16_ptr(label_id &char, xs &i16, ys &i16, count i32, bar_size f64, spec Spec_c) {
	C.ImPlot_PlotBars_S16PtrS16Ptr(label_id, xs, ys, count, bar_size, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotBars_U16PtrU16Ptr(label_id &char, xs &u16, ys &u16, count i32, bar_size f64, spec Spec_c)

@[inline]
pub fn plot_bars_u16_ptr_u16_ptr(label_id &char, xs &u16, ys &u16, count i32, bar_size f64, spec Spec_c) {
	C.ImPlot_PlotBars_U16PtrU16Ptr(label_id, xs, ys, count, bar_size, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotBars_S32PtrS32Ptr(label_id &char, xs &i32, ys &i32, count i32, bar_size f64, spec Spec_c)

@[inline]
pub fn plot_bars_s32_ptr_s32_ptr(label_id &char, xs &i32, ys &i32, count i32, bar_size f64, spec Spec_c) {
	C.ImPlot_PlotBars_S32PtrS32Ptr(label_id, xs, ys, count, bar_size, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotBars_U32PtrU32Ptr(label_id &char, xs &u32, ys &u32, count i32, bar_size f64, spec Spec_c)

@[inline]
pub fn plot_bars_u32_ptr_u32_ptr(label_id &char, xs &u32, ys &u32, count i32, bar_size f64, spec Spec_c) {
	C.ImPlot_PlotBars_U32PtrU32Ptr(label_id, xs, ys, count, bar_size, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotBars_S64PtrS64Ptr(label_id &char, xs &i64, ys &i64, count i32, bar_size f64, spec Spec_c)

@[inline]
pub fn plot_bars_s64_ptr_s64_ptr(label_id &char, xs &i64, ys &i64, count i32, bar_size f64, spec Spec_c) {
	C.ImPlot_PlotBars_S64PtrS64Ptr(label_id, xs, ys, count, bar_size, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotBars_U64PtrU64Ptr(label_id &char, xs &u64, ys &u64, count i32, bar_size f64, spec Spec_c)

@[inline]
pub fn plot_bars_u64_ptr_u64_ptr(label_id &char, xs &u64, ys &u64, count i32, bar_size f64, spec Spec_c) {
	C.ImPlot_PlotBars_U64PtrU64Ptr(label_id, xs, ys, count, bar_size, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotBarsG_LJ(label_id &char, getter Point_getter, data voidptr, count i32, bar_size f64, spec Spec_c)

@[inline]
pub fn plot_bars_g_lj(label_id &char, getter Point_getter, data voidptr, count i32, bar_size f64, spec Spec_c) {
	C.ImPlot_PlotBarsG_LJ(label_id, getter, data, count, bar_size, spec)
}

// custom generation

@[keep_args_alive]
fn C.ImPlot_PlotBarsG(label_id &char, getter Getter, data voidptr, count i32, bar_size f64, spec Spec_c)

@[inline]
pub fn plot_bars_g(label_id &char, getter Getter, data voidptr, count i32, bar_size f64, spec Spec_c) {
	C.ImPlot_PlotBarsG(label_id, getter, data, count, bar_size, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotBarGroups_FloatPtr(label_ids &&u8, values &f32, item_count i32, group_count i32, group_size f64, shift f64, spec Spec_c)

@[inline]
pub fn plot_bar_groups_float_ptr(label_ids &&u8, values &f32, item_count i32, group_count i32, group_size f64, shift f64, spec Spec_c) {
	C.ImPlot_PlotBarGroups_FloatPtr(label_ids, values, item_count, group_count, group_size, shift, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotBarGroups_doublePtr(label_ids &&u8, values &f64, item_count i32, group_count i32, group_size f64, shift f64, spec Spec_c)

@[inline]
pub fn plot_bar_groups_double_ptr(label_ids &&u8, values &f64, item_count i32, group_count i32, group_size f64, shift f64, spec Spec_c) {
	C.ImPlot_PlotBarGroups_doublePtr(label_ids, values, item_count, group_count, group_size, shift, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotBarGroups_S8Ptr(label_ids &&u8, values &char, item_count i32, group_count i32, group_size f64, shift f64, spec Spec_c)

@[inline]
pub fn plot_bar_groups_s8_ptr(label_ids &&u8, values &char, item_count i32, group_count i32, group_size f64, shift f64, spec Spec_c) {
	C.ImPlot_PlotBarGroups_S8Ptr(label_ids, values, item_count, group_count, group_size, shift, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotBarGroups_U8Ptr(label_ids &&u8, values &u8, item_count i32, group_count i32, group_size f64, shift f64, spec Spec_c)

@[inline]
pub fn plot_bar_groups_u8_ptr(label_ids &&u8, values &u8, item_count i32, group_count i32, group_size f64, shift f64, spec Spec_c) {
	C.ImPlot_PlotBarGroups_U8Ptr(label_ids, values, item_count, group_count, group_size, shift, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotBarGroups_S16Ptr(label_ids &&u8, values &i16, item_count i32, group_count i32, group_size f64, shift f64, spec Spec_c)

@[inline]
pub fn plot_bar_groups_s16_ptr(label_ids &&u8, values &i16, item_count i32, group_count i32, group_size f64, shift f64, spec Spec_c) {
	C.ImPlot_PlotBarGroups_S16Ptr(label_ids, values, item_count, group_count, group_size, shift, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotBarGroups_U16Ptr(label_ids &&u8, values &u16, item_count i32, group_count i32, group_size f64, shift f64, spec Spec_c)

@[inline]
pub fn plot_bar_groups_u16_ptr(label_ids &&u8, values &u16, item_count i32, group_count i32, group_size f64, shift f64, spec Spec_c) {
	C.ImPlot_PlotBarGroups_U16Ptr(label_ids, values, item_count, group_count, group_size, shift, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotBarGroups_S32Ptr(label_ids &&u8, values &i32, item_count i32, group_count i32, group_size f64, shift f64, spec Spec_c)

@[inline]
pub fn plot_bar_groups_s32_ptr(label_ids &&u8, values &i32, item_count i32, group_count i32, group_size f64, shift f64, spec Spec_c) {
	C.ImPlot_PlotBarGroups_S32Ptr(label_ids, values, item_count, group_count, group_size, shift, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotBarGroups_U32Ptr(label_ids &&u8, values &u32, item_count i32, group_count i32, group_size f64, shift f64, spec Spec_c)

@[inline]
pub fn plot_bar_groups_u32_ptr(label_ids &&u8, values &u32, item_count i32, group_count i32, group_size f64, shift f64, spec Spec_c) {
	C.ImPlot_PlotBarGroups_U32Ptr(label_ids, values, item_count, group_count, group_size, shift, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotBarGroups_S64Ptr(label_ids &&u8, values &i64, item_count i32, group_count i32, group_size f64, shift f64, spec Spec_c)

@[inline]
pub fn plot_bar_groups_s64_ptr(label_ids &&u8, values &i64, item_count i32, group_count i32, group_size f64, shift f64, spec Spec_c) {
	C.ImPlot_PlotBarGroups_S64Ptr(label_ids, values, item_count, group_count, group_size, shift, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotBarGroups_U64Ptr(label_ids &&u8, values &u64, item_count i32, group_count i32, group_size f64, shift f64, spec Spec_c)

@[inline]
pub fn plot_bar_groups_u64_ptr(label_ids &&u8, values &u64, item_count i32, group_count i32, group_size f64, shift f64, spec Spec_c) {
	C.ImPlot_PlotBarGroups_U64Ptr(label_ids, values, item_count, group_count, group_size, shift, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotErrorBars_FloatPtrFloatPtrFloatPtrInt(label_id &char, xs &f32, ys &f32, err &f32, count i32, spec Spec_c)

@[inline]
pub fn plot_error_bars_float_ptr_float_ptr_float_ptr_int(label_id &char, xs &f32, ys &f32, err &f32, count i32, spec Spec_c) {
	C.ImPlot_PlotErrorBars_FloatPtrFloatPtrFloatPtrInt(label_id, xs, ys, err, count, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotErrorBars_doublePtrdoublePtrdoublePtrInt(label_id &char, xs &f64, ys &f64, err &f64, count i32, spec Spec_c)

@[inline]
pub fn plot_error_bars_double_ptrdouble_ptrdouble_ptr_int(label_id &char, xs &f64, ys &f64, err &f64, count i32, spec Spec_c) {
	C.ImPlot_PlotErrorBars_doublePtrdoublePtrdoublePtrInt(label_id, xs, ys, err, count, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotErrorBars_S8PtrS8PtrS8PtrInt(label_id &char, xs &char, ys &char, err &char, count i32, spec Spec_c)

@[inline]
pub fn plot_error_bars_s8_ptr_s8_ptr_s8_ptr_int(label_id &char, xs &char, ys &char, err &char, count i32, spec Spec_c) {
	C.ImPlot_PlotErrorBars_S8PtrS8PtrS8PtrInt(label_id, xs, ys, err, count, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotErrorBars_U8PtrU8PtrU8PtrInt(label_id &char, xs &u8, ys &u8, err &u8, count i32, spec Spec_c)

@[inline]
pub fn plot_error_bars_u8_ptr_u8_ptr_u8_ptr_int(label_id &char, xs &u8, ys &u8, err &u8, count i32, spec Spec_c) {
	C.ImPlot_PlotErrorBars_U8PtrU8PtrU8PtrInt(label_id, xs, ys, err, count, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotErrorBars_S16PtrS16PtrS16PtrInt(label_id &char, xs &i16, ys &i16, err &i16, count i32, spec Spec_c)

@[inline]
pub fn plot_error_bars_s16_ptr_s16_ptr_s16_ptr_int(label_id &char, xs &i16, ys &i16, err &i16, count i32, spec Spec_c) {
	C.ImPlot_PlotErrorBars_S16PtrS16PtrS16PtrInt(label_id, xs, ys, err, count, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotErrorBars_U16PtrU16PtrU16PtrInt(label_id &char, xs &u16, ys &u16, err &u16, count i32, spec Spec_c)

@[inline]
pub fn plot_error_bars_u16_ptr_u16_ptr_u16_ptr_int(label_id &char, xs &u16, ys &u16, err &u16, count i32, spec Spec_c) {
	C.ImPlot_PlotErrorBars_U16PtrU16PtrU16PtrInt(label_id, xs, ys, err, count, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotErrorBars_S32PtrS32PtrS32PtrInt(label_id &char, xs &i32, ys &i32, err &i32, count i32, spec Spec_c)

@[inline]
pub fn plot_error_bars_s32_ptr_s32_ptr_s32_ptr_int(label_id &char, xs &i32, ys &i32, err &i32, count i32, spec Spec_c) {
	C.ImPlot_PlotErrorBars_S32PtrS32PtrS32PtrInt(label_id, xs, ys, err, count, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotErrorBars_U32PtrU32PtrU32PtrInt(label_id &char, xs &u32, ys &u32, err &u32, count i32, spec Spec_c)

@[inline]
pub fn plot_error_bars_u32_ptr_u32_ptr_u32_ptr_int(label_id &char, xs &u32, ys &u32, err &u32, count i32, spec Spec_c) {
	C.ImPlot_PlotErrorBars_U32PtrU32PtrU32PtrInt(label_id, xs, ys, err, count, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotErrorBars_S64PtrS64PtrS64PtrInt(label_id &char, xs &i64, ys &i64, err &i64, count i32, spec Spec_c)

@[inline]
pub fn plot_error_bars_s64_ptr_s64_ptr_s64_ptr_int(label_id &char, xs &i64, ys &i64, err &i64, count i32, spec Spec_c) {
	C.ImPlot_PlotErrorBars_S64PtrS64PtrS64PtrInt(label_id, xs, ys, err, count, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotErrorBars_U64PtrU64PtrU64PtrInt(label_id &char, xs &u64, ys &u64, err &u64, count i32, spec Spec_c)

@[inline]
pub fn plot_error_bars_u64_ptr_u64_ptr_u64_ptr_int(label_id &char, xs &u64, ys &u64, err &u64, count i32, spec Spec_c) {
	C.ImPlot_PlotErrorBars_U64PtrU64PtrU64PtrInt(label_id, xs, ys, err, count, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotErrorBars_FloatPtrFloatPtrFloatPtrFloatPtr(label_id &char, xs &f32, ys &f32, neg &f32, pos &f32, count i32, spec Spec_c)

@[inline]
pub fn plot_error_bars_float_ptr_float_ptr_float_ptr_float_ptr(label_id &char, xs &f32, ys &f32, neg &f32, pos &f32, count i32, spec Spec_c) {
	C.ImPlot_PlotErrorBars_FloatPtrFloatPtrFloatPtrFloatPtr(label_id, xs, ys, neg, pos, count, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotErrorBars_doublePtrdoublePtrdoublePtrdoublePtr(label_id &char, xs &f64, ys &f64, neg &f64, pos &f64, count i32, spec Spec_c)

@[inline]
pub fn plot_error_bars_double_ptrdouble_ptrdouble_ptrdouble_ptr(label_id &char, xs &f64, ys &f64, neg &f64, pos &f64, count i32, spec Spec_c) {
	C.ImPlot_PlotErrorBars_doublePtrdoublePtrdoublePtrdoublePtr(label_id, xs, ys, neg, pos, count, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotErrorBars_S8PtrS8PtrS8PtrS8Ptr(label_id &char, xs &char, ys &char, neg &char, pos &char, count i32, spec Spec_c)

@[inline]
pub fn plot_error_bars_s8_ptr_s8_ptr_s8_ptr_s8_ptr(label_id &char, xs &char, ys &char, neg &char, pos &char, count i32, spec Spec_c) {
	C.ImPlot_PlotErrorBars_S8PtrS8PtrS8PtrS8Ptr(label_id, xs, ys, neg, pos, count, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotErrorBars_U8PtrU8PtrU8PtrU8Ptr(label_id &char, xs &u8, ys &u8, neg &u8, pos &u8, count i32, spec Spec_c)

@[inline]
pub fn plot_error_bars_u8_ptr_u8_ptr_u8_ptr_u8_ptr(label_id &char, xs &u8, ys &u8, neg &u8, pos &u8, count i32, spec Spec_c) {
	C.ImPlot_PlotErrorBars_U8PtrU8PtrU8PtrU8Ptr(label_id, xs, ys, neg, pos, count, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotErrorBars_S16PtrS16PtrS16PtrS16Ptr(label_id &char, xs &i16, ys &i16, neg &i16, pos &i16, count i32, spec Spec_c)

@[inline]
pub fn plot_error_bars_s16_ptr_s16_ptr_s16_ptr_s16_ptr(label_id &char, xs &i16, ys &i16, neg &i16, pos &i16, count i32, spec Spec_c) {
	C.ImPlot_PlotErrorBars_S16PtrS16PtrS16PtrS16Ptr(label_id, xs, ys, neg, pos, count, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotErrorBars_U16PtrU16PtrU16PtrU16Ptr(label_id &char, xs &u16, ys &u16, neg &u16, pos &u16, count i32, spec Spec_c)

@[inline]
pub fn plot_error_bars_u16_ptr_u16_ptr_u16_ptr_u16_ptr(label_id &char, xs &u16, ys &u16, neg &u16, pos &u16, count i32, spec Spec_c) {
	C.ImPlot_PlotErrorBars_U16PtrU16PtrU16PtrU16Ptr(label_id, xs, ys, neg, pos, count, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotErrorBars_S32PtrS32PtrS32PtrS32Ptr(label_id &char, xs &i32, ys &i32, neg &i32, pos &i32, count i32, spec Spec_c)

@[inline]
pub fn plot_error_bars_s32_ptr_s32_ptr_s32_ptr_s32_ptr(label_id &char, xs &i32, ys &i32, neg &i32, pos &i32, count i32, spec Spec_c) {
	C.ImPlot_PlotErrorBars_S32PtrS32PtrS32PtrS32Ptr(label_id, xs, ys, neg, pos, count, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotErrorBars_U32PtrU32PtrU32PtrU32Ptr(label_id &char, xs &u32, ys &u32, neg &u32, pos &u32, count i32, spec Spec_c)

@[inline]
pub fn plot_error_bars_u32_ptr_u32_ptr_u32_ptr_u32_ptr(label_id &char, xs &u32, ys &u32, neg &u32, pos &u32, count i32, spec Spec_c) {
	C.ImPlot_PlotErrorBars_U32PtrU32PtrU32PtrU32Ptr(label_id, xs, ys, neg, pos, count, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotErrorBars_S64PtrS64PtrS64PtrS64Ptr(label_id &char, xs &i64, ys &i64, neg &i64, pos &i64, count i32, spec Spec_c)

@[inline]
pub fn plot_error_bars_s64_ptr_s64_ptr_s64_ptr_s64_ptr(label_id &char, xs &i64, ys &i64, neg &i64, pos &i64, count i32, spec Spec_c) {
	C.ImPlot_PlotErrorBars_S64PtrS64PtrS64PtrS64Ptr(label_id, xs, ys, neg, pos, count, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotErrorBars_U64PtrU64PtrU64PtrU64Ptr(label_id &char, xs &u64, ys &u64, neg &u64, pos &u64, count i32, spec Spec_c)

@[inline]
pub fn plot_error_bars_u64_ptr_u64_ptr_u64_ptr_u64_ptr(label_id &char, xs &u64, ys &u64, neg &u64, pos &u64, count i32, spec Spec_c) {
	C.ImPlot_PlotErrorBars_U64PtrU64PtrU64PtrU64Ptr(label_id, xs, ys, neg, pos, count, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotStems_FloatPtrInt(label_id &char, values &f32, count i32, ref f64, scale f64, start f64, spec Spec_c)

@[inline]
pub fn plot_stems_float_ptr_int(label_id &char, values &f32, count i32, ref f64, scale f64, start f64, spec Spec_c) {
	C.ImPlot_PlotStems_FloatPtrInt(label_id, values, count, ref, scale, start, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotStems_doublePtrInt(label_id &char, values &f64, count i32, ref f64, scale f64, start f64, spec Spec_c)

@[inline]
pub fn plot_stems_double_ptr_int(label_id &char, values &f64, count i32, ref f64, scale f64, start f64, spec Spec_c) {
	C.ImPlot_PlotStems_doublePtrInt(label_id, values, count, ref, scale, start, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotStems_S8PtrInt(label_id &char, values &char, count i32, ref f64, scale f64, start f64, spec Spec_c)

@[inline]
pub fn plot_stems_s8_ptr_int(label_id &char, values &char, count i32, ref f64, scale f64, start f64, spec Spec_c) {
	C.ImPlot_PlotStems_S8PtrInt(label_id, values, count, ref, scale, start, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotStems_U8PtrInt(label_id &char, values &u8, count i32, ref f64, scale f64, start f64, spec Spec_c)

@[inline]
pub fn plot_stems_u8_ptr_int(label_id &char, values &u8, count i32, ref f64, scale f64, start f64, spec Spec_c) {
	C.ImPlot_PlotStems_U8PtrInt(label_id, values, count, ref, scale, start, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotStems_S16PtrInt(label_id &char, values &i16, count i32, ref f64, scale f64, start f64, spec Spec_c)

@[inline]
pub fn plot_stems_s16_ptr_int(label_id &char, values &i16, count i32, ref f64, scale f64, start f64, spec Spec_c) {
	C.ImPlot_PlotStems_S16PtrInt(label_id, values, count, ref, scale, start, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotStems_U16PtrInt(label_id &char, values &u16, count i32, ref f64, scale f64, start f64, spec Spec_c)

@[inline]
pub fn plot_stems_u16_ptr_int(label_id &char, values &u16, count i32, ref f64, scale f64, start f64, spec Spec_c) {
	C.ImPlot_PlotStems_U16PtrInt(label_id, values, count, ref, scale, start, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotStems_S32PtrInt(label_id &char, values &i32, count i32, ref f64, scale f64, start f64, spec Spec_c)

@[inline]
pub fn plot_stems_s32_ptr_int(label_id &char, values &i32, count i32, ref f64, scale f64, start f64, spec Spec_c) {
	C.ImPlot_PlotStems_S32PtrInt(label_id, values, count, ref, scale, start, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotStems_U32PtrInt(label_id &char, values &u32, count i32, ref f64, scale f64, start f64, spec Spec_c)

@[inline]
pub fn plot_stems_u32_ptr_int(label_id &char, values &u32, count i32, ref f64, scale f64, start f64, spec Spec_c) {
	C.ImPlot_PlotStems_U32PtrInt(label_id, values, count, ref, scale, start, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotStems_S64PtrInt(label_id &char, values &i64, count i32, ref f64, scale f64, start f64, spec Spec_c)

@[inline]
pub fn plot_stems_s64_ptr_int(label_id &char, values &i64, count i32, ref f64, scale f64, start f64, spec Spec_c) {
	C.ImPlot_PlotStems_S64PtrInt(label_id, values, count, ref, scale, start, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotStems_U64PtrInt(label_id &char, values &u64, count i32, ref f64, scale f64, start f64, spec Spec_c)

@[inline]
pub fn plot_stems_u64_ptr_int(label_id &char, values &u64, count i32, ref f64, scale f64, start f64, spec Spec_c) {
	C.ImPlot_PlotStems_U64PtrInt(label_id, values, count, ref, scale, start, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotStems_FloatPtrFloatPtr(label_id &char, xs &f32, ys &f32, count i32, ref f64, spec Spec_c)

@[inline]
pub fn plot_stems_float_ptr_float_ptr(label_id &char, xs &f32, ys &f32, count i32, ref f64, spec Spec_c) {
	C.ImPlot_PlotStems_FloatPtrFloatPtr(label_id, xs, ys, count, ref, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotStems_doublePtrdoublePtr(label_id &char, xs &f64, ys &f64, count i32, ref f64, spec Spec_c)

@[inline]
pub fn plot_stems_double_ptrdouble_ptr(label_id &char, xs &f64, ys &f64, count i32, ref f64, spec Spec_c) {
	C.ImPlot_PlotStems_doublePtrdoublePtr(label_id, xs, ys, count, ref, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotStems_S8PtrS8Ptr(label_id &char, xs &char, ys &char, count i32, ref f64, spec Spec_c)

@[inline]
pub fn plot_stems_s8_ptr_s8_ptr(label_id &char, xs &char, ys &char, count i32, ref f64, spec Spec_c) {
	C.ImPlot_PlotStems_S8PtrS8Ptr(label_id, xs, ys, count, ref, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotStems_U8PtrU8Ptr(label_id &char, xs &u8, ys &u8, count i32, ref f64, spec Spec_c)

@[inline]
pub fn plot_stems_u8_ptr_u8_ptr(label_id &char, xs &u8, ys &u8, count i32, ref f64, spec Spec_c) {
	C.ImPlot_PlotStems_U8PtrU8Ptr(label_id, xs, ys, count, ref, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotStems_S16PtrS16Ptr(label_id &char, xs &i16, ys &i16, count i32, ref f64, spec Spec_c)

@[inline]
pub fn plot_stems_s16_ptr_s16_ptr(label_id &char, xs &i16, ys &i16, count i32, ref f64, spec Spec_c) {
	C.ImPlot_PlotStems_S16PtrS16Ptr(label_id, xs, ys, count, ref, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotStems_U16PtrU16Ptr(label_id &char, xs &u16, ys &u16, count i32, ref f64, spec Spec_c)

@[inline]
pub fn plot_stems_u16_ptr_u16_ptr(label_id &char, xs &u16, ys &u16, count i32, ref f64, spec Spec_c) {
	C.ImPlot_PlotStems_U16PtrU16Ptr(label_id, xs, ys, count, ref, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotStems_S32PtrS32Ptr(label_id &char, xs &i32, ys &i32, count i32, ref f64, spec Spec_c)

@[inline]
pub fn plot_stems_s32_ptr_s32_ptr(label_id &char, xs &i32, ys &i32, count i32, ref f64, spec Spec_c) {
	C.ImPlot_PlotStems_S32PtrS32Ptr(label_id, xs, ys, count, ref, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotStems_U32PtrU32Ptr(label_id &char, xs &u32, ys &u32, count i32, ref f64, spec Spec_c)

@[inline]
pub fn plot_stems_u32_ptr_u32_ptr(label_id &char, xs &u32, ys &u32, count i32, ref f64, spec Spec_c) {
	C.ImPlot_PlotStems_U32PtrU32Ptr(label_id, xs, ys, count, ref, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotStems_S64PtrS64Ptr(label_id &char, xs &i64, ys &i64, count i32, ref f64, spec Spec_c)

@[inline]
pub fn plot_stems_s64_ptr_s64_ptr(label_id &char, xs &i64, ys &i64, count i32, ref f64, spec Spec_c) {
	C.ImPlot_PlotStems_S64PtrS64Ptr(label_id, xs, ys, count, ref, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotStems_U64PtrU64Ptr(label_id &char, xs &u64, ys &u64, count i32, ref f64, spec Spec_c)

@[inline]
pub fn plot_stems_u64_ptr_u64_ptr(label_id &char, xs &u64, ys &u64, count i32, ref f64, spec Spec_c) {
	C.ImPlot_PlotStems_U64PtrU64Ptr(label_id, xs, ys, count, ref, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotInfLines_FloatPtr(label_id &char, values &f32, count i32, spec Spec_c)

@[inline]
pub fn plot_inf_lines_float_ptr(label_id &char, values &f32, count i32, spec Spec_c) {
	C.ImPlot_PlotInfLines_FloatPtr(label_id, values, count, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotInfLines_doublePtr(label_id &char, values &f64, count i32, spec Spec_c)

@[inline]
pub fn plot_inf_lines_double_ptr(label_id &char, values &f64, count i32, spec Spec_c) {
	C.ImPlot_PlotInfLines_doublePtr(label_id, values, count, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotInfLines_S8Ptr(label_id &char, values &char, count i32, spec Spec_c)

@[inline]
pub fn plot_inf_lines_s8_ptr(label_id &char, values &char, count i32, spec Spec_c) {
	C.ImPlot_PlotInfLines_S8Ptr(label_id, values, count, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotInfLines_U8Ptr(label_id &char, values &u8, count i32, spec Spec_c)

@[inline]
pub fn plot_inf_lines_u8_ptr(label_id &char, values &u8, count i32, spec Spec_c) {
	C.ImPlot_PlotInfLines_U8Ptr(label_id, values, count, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotInfLines_S16Ptr(label_id &char, values &i16, count i32, spec Spec_c)

@[inline]
pub fn plot_inf_lines_s16_ptr(label_id &char, values &i16, count i32, spec Spec_c) {
	C.ImPlot_PlotInfLines_S16Ptr(label_id, values, count, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotInfLines_U16Ptr(label_id &char, values &u16, count i32, spec Spec_c)

@[inline]
pub fn plot_inf_lines_u16_ptr(label_id &char, values &u16, count i32, spec Spec_c) {
	C.ImPlot_PlotInfLines_U16Ptr(label_id, values, count, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotInfLines_S32Ptr(label_id &char, values &i32, count i32, spec Spec_c)

@[inline]
pub fn plot_inf_lines_s32_ptr(label_id &char, values &i32, count i32, spec Spec_c) {
	C.ImPlot_PlotInfLines_S32Ptr(label_id, values, count, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotInfLines_U32Ptr(label_id &char, values &u32, count i32, spec Spec_c)

@[inline]
pub fn plot_inf_lines_u32_ptr(label_id &char, values &u32, count i32, spec Spec_c) {
	C.ImPlot_PlotInfLines_U32Ptr(label_id, values, count, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotInfLines_S64Ptr(label_id &char, values &i64, count i32, spec Spec_c)

@[inline]
pub fn plot_inf_lines_s64_ptr(label_id &char, values &i64, count i32, spec Spec_c) {
	C.ImPlot_PlotInfLines_S64Ptr(label_id, values, count, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotInfLines_U64Ptr(label_id &char, values &u64, count i32, spec Spec_c)

@[inline]
pub fn plot_inf_lines_u64_ptr(label_id &char, values &u64, count i32, spec Spec_c) {
	C.ImPlot_PlotInfLines_U64Ptr(label_id, values, count, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotPieChart_FloatPtrPlotFormatter(label_ids &&u8, values &f32, count i32, x f64, y f64, radius f64, fmt Formatter, fmt_data voidptr, angle0 f64, spec Spec_c)

@[inline]
pub fn plot_pie_chart_float_ptr_plot_formatter(label_ids &&u8, values &f32, count i32, x f64, y f64, radius f64, fmt Formatter, fmt_data voidptr, angle0 f64, spec Spec_c) {
	C.ImPlot_PlotPieChart_FloatPtrPlotFormatter(label_ids, values, count, x, y, radius, fmt, fmt_data, angle0, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotPieChart_doublePtrPlotFormatter(label_ids &&u8, values &f64, count i32, x f64, y f64, radius f64, fmt Formatter, fmt_data voidptr, angle0 f64, spec Spec_c)

@[inline]
pub fn plot_pie_chart_double_ptr_plot_formatter(label_ids &&u8, values &f64, count i32, x f64, y f64, radius f64, fmt Formatter, fmt_data voidptr, angle0 f64, spec Spec_c) {
	C.ImPlot_PlotPieChart_doublePtrPlotFormatter(label_ids, values, count, x, y, radius, fmt, fmt_data, angle0, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotPieChart_S8PtrPlotFormatter(label_ids &&u8, values &char, count i32, x f64, y f64, radius f64, fmt Formatter, fmt_data voidptr, angle0 f64, spec Spec_c)

@[inline]
pub fn plot_pie_chart_s8_ptr_plot_formatter(label_ids &&u8, values &char, count i32, x f64, y f64, radius f64, fmt Formatter, fmt_data voidptr, angle0 f64, spec Spec_c) {
	C.ImPlot_PlotPieChart_S8PtrPlotFormatter(label_ids, values, count, x, y, radius, fmt, fmt_data, angle0, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotPieChart_U8PtrPlotFormatter(label_ids &&u8, values &u8, count i32, x f64, y f64, radius f64, fmt Formatter, fmt_data voidptr, angle0 f64, spec Spec_c)

@[inline]
pub fn plot_pie_chart_u8_ptr_plot_formatter(label_ids &&u8, values &u8, count i32, x f64, y f64, radius f64, fmt Formatter, fmt_data voidptr, angle0 f64, spec Spec_c) {
	C.ImPlot_PlotPieChart_U8PtrPlotFormatter(label_ids, values, count, x, y, radius, fmt, fmt_data, angle0, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotPieChart_S16PtrPlotFormatter(label_ids &&u8, values &i16, count i32, x f64, y f64, radius f64, fmt Formatter, fmt_data voidptr, angle0 f64, spec Spec_c)

@[inline]
pub fn plot_pie_chart_s16_ptr_plot_formatter(label_ids &&u8, values &i16, count i32, x f64, y f64, radius f64, fmt Formatter, fmt_data voidptr, angle0 f64, spec Spec_c) {
	C.ImPlot_PlotPieChart_S16PtrPlotFormatter(label_ids, values, count, x, y, radius, fmt, fmt_data, angle0, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotPieChart_U16PtrPlotFormatter(label_ids &&u8, values &u16, count i32, x f64, y f64, radius f64, fmt Formatter, fmt_data voidptr, angle0 f64, spec Spec_c)

@[inline]
pub fn plot_pie_chart_u16_ptr_plot_formatter(label_ids &&u8, values &u16, count i32, x f64, y f64, radius f64, fmt Formatter, fmt_data voidptr, angle0 f64, spec Spec_c) {
	C.ImPlot_PlotPieChart_U16PtrPlotFormatter(label_ids, values, count, x, y, radius, fmt, fmt_data, angle0, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotPieChart_S32PtrPlotFormatter(label_ids &&u8, values &i32, count i32, x f64, y f64, radius f64, fmt Formatter, fmt_data voidptr, angle0 f64, spec Spec_c)

@[inline]
pub fn plot_pie_chart_s32_ptr_plot_formatter(label_ids &&u8, values &i32, count i32, x f64, y f64, radius f64, fmt Formatter, fmt_data voidptr, angle0 f64, spec Spec_c) {
	C.ImPlot_PlotPieChart_S32PtrPlotFormatter(label_ids, values, count, x, y, radius, fmt, fmt_data, angle0, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotPieChart_U32PtrPlotFormatter(label_ids &&u8, values &u32, count i32, x f64, y f64, radius f64, fmt Formatter, fmt_data voidptr, angle0 f64, spec Spec_c)

@[inline]
pub fn plot_pie_chart_u32_ptr_plot_formatter(label_ids &&u8, values &u32, count i32, x f64, y f64, radius f64, fmt Formatter, fmt_data voidptr, angle0 f64, spec Spec_c) {
	C.ImPlot_PlotPieChart_U32PtrPlotFormatter(label_ids, values, count, x, y, radius, fmt, fmt_data, angle0, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotPieChart_S64PtrPlotFormatter(label_ids &&u8, values &i64, count i32, x f64, y f64, radius f64, fmt Formatter, fmt_data voidptr, angle0 f64, spec Spec_c)

@[inline]
pub fn plot_pie_chart_s64_ptr_plot_formatter(label_ids &&u8, values &i64, count i32, x f64, y f64, radius f64, fmt Formatter, fmt_data voidptr, angle0 f64, spec Spec_c) {
	C.ImPlot_PlotPieChart_S64PtrPlotFormatter(label_ids, values, count, x, y, radius, fmt, fmt_data, angle0, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotPieChart_U64PtrPlotFormatter(label_ids &&u8, values &u64, count i32, x f64, y f64, radius f64, fmt Formatter, fmt_data voidptr, angle0 f64, spec Spec_c)

@[inline]
pub fn plot_pie_chart_u64_ptr_plot_formatter(label_ids &&u8, values &u64, count i32, x f64, y f64, radius f64, fmt Formatter, fmt_data voidptr, angle0 f64, spec Spec_c) {
	C.ImPlot_PlotPieChart_U64PtrPlotFormatter(label_ids, values, count, x, y, radius, fmt, fmt_data, angle0, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotPieChart_FloatPtrStr(label_ids &&u8, values &f32, count i32, x f64, y f64, radius f64, label_fmt &char, angle0 f64, spec Spec_c)

@[inline]
pub fn plot_pie_chart_float_ptr_str(label_ids &&u8, values &f32, count i32, x f64, y f64, radius f64, label_fmt &char, angle0 f64, spec Spec_c) {
	C.ImPlot_PlotPieChart_FloatPtrStr(label_ids, values, count, x, y, radius, label_fmt, angle0, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotPieChart_doublePtrStr(label_ids &&u8, values &f64, count i32, x f64, y f64, radius f64, label_fmt &char, angle0 f64, spec Spec_c)

@[inline]
pub fn plot_pie_chart_double_ptr_str(label_ids &&u8, values &f64, count i32, x f64, y f64, radius f64, label_fmt &char, angle0 f64, spec Spec_c) {
	C.ImPlot_PlotPieChart_doublePtrStr(label_ids, values, count, x, y, radius, label_fmt, angle0, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotPieChart_S8PtrStr(label_ids &&u8, values &char, count i32, x f64, y f64, radius f64, label_fmt &char, angle0 f64, spec Spec_c)

@[inline]
pub fn plot_pie_chart_s8_ptr_str(label_ids &&u8, values &char, count i32, x f64, y f64, radius f64, label_fmt &char, angle0 f64, spec Spec_c) {
	C.ImPlot_PlotPieChart_S8PtrStr(label_ids, values, count, x, y, radius, label_fmt, angle0, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotPieChart_U8PtrStr(label_ids &&u8, values &u8, count i32, x f64, y f64, radius f64, label_fmt &char, angle0 f64, spec Spec_c)

@[inline]
pub fn plot_pie_chart_u8_ptr_str(label_ids &&u8, values &u8, count i32, x f64, y f64, radius f64, label_fmt &char, angle0 f64, spec Spec_c) {
	C.ImPlot_PlotPieChart_U8PtrStr(label_ids, values, count, x, y, radius, label_fmt, angle0, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotPieChart_S16PtrStr(label_ids &&u8, values &i16, count i32, x f64, y f64, radius f64, label_fmt &char, angle0 f64, spec Spec_c)

@[inline]
pub fn plot_pie_chart_s16_ptr_str(label_ids &&u8, values &i16, count i32, x f64, y f64, radius f64, label_fmt &char, angle0 f64, spec Spec_c) {
	C.ImPlot_PlotPieChart_S16PtrStr(label_ids, values, count, x, y, radius, label_fmt, angle0, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotPieChart_U16PtrStr(label_ids &&u8, values &u16, count i32, x f64, y f64, radius f64, label_fmt &char, angle0 f64, spec Spec_c)

@[inline]
pub fn plot_pie_chart_u16_ptr_str(label_ids &&u8, values &u16, count i32, x f64, y f64, radius f64, label_fmt &char, angle0 f64, spec Spec_c) {
	C.ImPlot_PlotPieChart_U16PtrStr(label_ids, values, count, x, y, radius, label_fmt, angle0, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotPieChart_S32PtrStr(label_ids &&u8, values &i32, count i32, x f64, y f64, radius f64, label_fmt &char, angle0 f64, spec Spec_c)

@[inline]
pub fn plot_pie_chart_s32_ptr_str(label_ids &&u8, values &i32, count i32, x f64, y f64, radius f64, label_fmt &char, angle0 f64, spec Spec_c) {
	C.ImPlot_PlotPieChart_S32PtrStr(label_ids, values, count, x, y, radius, label_fmt, angle0, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotPieChart_U32PtrStr(label_ids &&u8, values &u32, count i32, x f64, y f64, radius f64, label_fmt &char, angle0 f64, spec Spec_c)

@[inline]
pub fn plot_pie_chart_u32_ptr_str(label_ids &&u8, values &u32, count i32, x f64, y f64, radius f64, label_fmt &char, angle0 f64, spec Spec_c) {
	C.ImPlot_PlotPieChart_U32PtrStr(label_ids, values, count, x, y, radius, label_fmt, angle0, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotPieChart_S64PtrStr(label_ids &&u8, values &i64, count i32, x f64, y f64, radius f64, label_fmt &char, angle0 f64, spec Spec_c)

@[inline]
pub fn plot_pie_chart_s64_ptr_str(label_ids &&u8, values &i64, count i32, x f64, y f64, radius f64, label_fmt &char, angle0 f64, spec Spec_c) {
	C.ImPlot_PlotPieChart_S64PtrStr(label_ids, values, count, x, y, radius, label_fmt, angle0, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotPieChart_U64PtrStr(label_ids &&u8, values &u64, count i32, x f64, y f64, radius f64, label_fmt &char, angle0 f64, spec Spec_c)

@[inline]
pub fn plot_pie_chart_u64_ptr_str(label_ids &&u8, values &u64, count i32, x f64, y f64, radius f64, label_fmt &char, angle0 f64, spec Spec_c) {
	C.ImPlot_PlotPieChart_U64PtrStr(label_ids, values, count, x, y, radius, label_fmt, angle0, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotHeatmap_FloatPtr(label_id &char, values &f32, rows i32, cols i32, scale_min f64, scale_max f64, label_fmt &char, bounds_min Point_c, bounds_max Point_c, spec Spec_c)

@[inline]
pub fn plot_heatmap_float_ptr(label_id &char, values &f32, rows i32, cols i32, scale_min f64, scale_max f64, label_fmt &char, bounds_min Point_c, bounds_max Point_c, spec Spec_c) {
	C.ImPlot_PlotHeatmap_FloatPtr(label_id, values, rows, cols, scale_min, scale_max, label_fmt, bounds_min, bounds_max, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotHeatmap_doublePtr(label_id &char, values &f64, rows i32, cols i32, scale_min f64, scale_max f64, label_fmt &char, bounds_min Point_c, bounds_max Point_c, spec Spec_c)

@[inline]
pub fn plot_heatmap_double_ptr(label_id &char, values &f64, rows i32, cols i32, scale_min f64, scale_max f64, label_fmt &char, bounds_min Point_c, bounds_max Point_c, spec Spec_c) {
	C.ImPlot_PlotHeatmap_doublePtr(label_id, values, rows, cols, scale_min, scale_max, label_fmt, bounds_min, bounds_max, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotHeatmap_S8Ptr(label_id &char, values &char, rows i32, cols i32, scale_min f64, scale_max f64, label_fmt &char, bounds_min Point_c, bounds_max Point_c, spec Spec_c)

@[inline]
pub fn plot_heatmap_s8_ptr(label_id &char, values &char, rows i32, cols i32, scale_min f64, scale_max f64, label_fmt &char, bounds_min Point_c, bounds_max Point_c, spec Spec_c) {
	C.ImPlot_PlotHeatmap_S8Ptr(label_id, values, rows, cols, scale_min, scale_max, label_fmt, bounds_min, bounds_max, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotHeatmap_U8Ptr(label_id &char, values &u8, rows i32, cols i32, scale_min f64, scale_max f64, label_fmt &char, bounds_min Point_c, bounds_max Point_c, spec Spec_c)

@[inline]
pub fn plot_heatmap_u8_ptr(label_id &char, values &u8, rows i32, cols i32, scale_min f64, scale_max f64, label_fmt &char, bounds_min Point_c, bounds_max Point_c, spec Spec_c) {
	C.ImPlot_PlotHeatmap_U8Ptr(label_id, values, rows, cols, scale_min, scale_max, label_fmt, bounds_min, bounds_max, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotHeatmap_S16Ptr(label_id &char, values &i16, rows i32, cols i32, scale_min f64, scale_max f64, label_fmt &char, bounds_min Point_c, bounds_max Point_c, spec Spec_c)

@[inline]
pub fn plot_heatmap_s16_ptr(label_id &char, values &i16, rows i32, cols i32, scale_min f64, scale_max f64, label_fmt &char, bounds_min Point_c, bounds_max Point_c, spec Spec_c) {
	C.ImPlot_PlotHeatmap_S16Ptr(label_id, values, rows, cols, scale_min, scale_max, label_fmt, bounds_min, bounds_max, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotHeatmap_U16Ptr(label_id &char, values &u16, rows i32, cols i32, scale_min f64, scale_max f64, label_fmt &char, bounds_min Point_c, bounds_max Point_c, spec Spec_c)

@[inline]
pub fn plot_heatmap_u16_ptr(label_id &char, values &u16, rows i32, cols i32, scale_min f64, scale_max f64, label_fmt &char, bounds_min Point_c, bounds_max Point_c, spec Spec_c) {
	C.ImPlot_PlotHeatmap_U16Ptr(label_id, values, rows, cols, scale_min, scale_max, label_fmt, bounds_min, bounds_max, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotHeatmap_S32Ptr(label_id &char, values &i32, rows i32, cols i32, scale_min f64, scale_max f64, label_fmt &char, bounds_min Point_c, bounds_max Point_c, spec Spec_c)

@[inline]
pub fn plot_heatmap_s32_ptr(label_id &char, values &i32, rows i32, cols i32, scale_min f64, scale_max f64, label_fmt &char, bounds_min Point_c, bounds_max Point_c, spec Spec_c) {
	C.ImPlot_PlotHeatmap_S32Ptr(label_id, values, rows, cols, scale_min, scale_max, label_fmt, bounds_min, bounds_max, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotHeatmap_U32Ptr(label_id &char, values &u32, rows i32, cols i32, scale_min f64, scale_max f64, label_fmt &char, bounds_min Point_c, bounds_max Point_c, spec Spec_c)

@[inline]
pub fn plot_heatmap_u32_ptr(label_id &char, values &u32, rows i32, cols i32, scale_min f64, scale_max f64, label_fmt &char, bounds_min Point_c, bounds_max Point_c, spec Spec_c) {
	C.ImPlot_PlotHeatmap_U32Ptr(label_id, values, rows, cols, scale_min, scale_max, label_fmt, bounds_min, bounds_max, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotHeatmap_S64Ptr(label_id &char, values &i64, rows i32, cols i32, scale_min f64, scale_max f64, label_fmt &char, bounds_min Point_c, bounds_max Point_c, spec Spec_c)

@[inline]
pub fn plot_heatmap_s64_ptr(label_id &char, values &i64, rows i32, cols i32, scale_min f64, scale_max f64, label_fmt &char, bounds_min Point_c, bounds_max Point_c, spec Spec_c) {
	C.ImPlot_PlotHeatmap_S64Ptr(label_id, values, rows, cols, scale_min, scale_max, label_fmt, bounds_min, bounds_max, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotHeatmap_U64Ptr(label_id &char, values &u64, rows i32, cols i32, scale_min f64, scale_max f64, label_fmt &char, bounds_min Point_c, bounds_max Point_c, spec Spec_c)

@[inline]
pub fn plot_heatmap_u64_ptr(label_id &char, values &u64, rows i32, cols i32, scale_min f64, scale_max f64, label_fmt &char, bounds_min Point_c, bounds_max Point_c, spec Spec_c) {
	C.ImPlot_PlotHeatmap_U64Ptr(label_id, values, rows, cols, scale_min, scale_max, label_fmt, bounds_min, bounds_max, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotHistogram_FloatPtr(label_id &char, values &f32, count i32, bins i32, bar_scale f64, range Range_c, spec Spec_c) f64

@[inline]
pub fn plot_histogram_float_ptr(label_id &char, values &f32, count i32, bins i32, bar_scale f64, range Range_c, spec Spec_c) f64 {
	return C.ImPlot_PlotHistogram_FloatPtr(label_id, values, count, bins, bar_scale, range, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotHistogram_doublePtr(label_id &char, values &f64, count i32, bins i32, bar_scale f64, range Range_c, spec Spec_c) f64

@[inline]
pub fn plot_histogram_double_ptr(label_id &char, values &f64, count i32, bins i32, bar_scale f64, range Range_c, spec Spec_c) f64 {
	return C.ImPlot_PlotHistogram_doublePtr(label_id, values, count, bins, bar_scale, range, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotHistogram_S8Ptr(label_id &char, values &char, count i32, bins i32, bar_scale f64, range Range_c, spec Spec_c) f64

@[inline]
pub fn plot_histogram_s8_ptr(label_id &char, values &char, count i32, bins i32, bar_scale f64, range Range_c, spec Spec_c) f64 {
	return C.ImPlot_PlotHistogram_S8Ptr(label_id, values, count, bins, bar_scale, range, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotHistogram_U8Ptr(label_id &char, values &u8, count i32, bins i32, bar_scale f64, range Range_c, spec Spec_c) f64

@[inline]
pub fn plot_histogram_u8_ptr(label_id &char, values &u8, count i32, bins i32, bar_scale f64, range Range_c, spec Spec_c) f64 {
	return C.ImPlot_PlotHistogram_U8Ptr(label_id, values, count, bins, bar_scale, range, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotHistogram_S16Ptr(label_id &char, values &i16, count i32, bins i32, bar_scale f64, range Range_c, spec Spec_c) f64

@[inline]
pub fn plot_histogram_s16_ptr(label_id &char, values &i16, count i32, bins i32, bar_scale f64, range Range_c, spec Spec_c) f64 {
	return C.ImPlot_PlotHistogram_S16Ptr(label_id, values, count, bins, bar_scale, range, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotHistogram_U16Ptr(label_id &char, values &u16, count i32, bins i32, bar_scale f64, range Range_c, spec Spec_c) f64

@[inline]
pub fn plot_histogram_u16_ptr(label_id &char, values &u16, count i32, bins i32, bar_scale f64, range Range_c, spec Spec_c) f64 {
	return C.ImPlot_PlotHistogram_U16Ptr(label_id, values, count, bins, bar_scale, range, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotHistogram_S32Ptr(label_id &char, values &i32, count i32, bins i32, bar_scale f64, range Range_c, spec Spec_c) f64

@[inline]
pub fn plot_histogram_s32_ptr(label_id &char, values &i32, count i32, bins i32, bar_scale f64, range Range_c, spec Spec_c) f64 {
	return C.ImPlot_PlotHistogram_S32Ptr(label_id, values, count, bins, bar_scale, range, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotHistogram_U32Ptr(label_id &char, values &u32, count i32, bins i32, bar_scale f64, range Range_c, spec Spec_c) f64

@[inline]
pub fn plot_histogram_u32_ptr(label_id &char, values &u32, count i32, bins i32, bar_scale f64, range Range_c, spec Spec_c) f64 {
	return C.ImPlot_PlotHistogram_U32Ptr(label_id, values, count, bins, bar_scale, range, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotHistogram_S64Ptr(label_id &char, values &i64, count i32, bins i32, bar_scale f64, range Range_c, spec Spec_c) f64

@[inline]
pub fn plot_histogram_s64_ptr(label_id &char, values &i64, count i32, bins i32, bar_scale f64, range Range_c, spec Spec_c) f64 {
	return C.ImPlot_PlotHistogram_S64Ptr(label_id, values, count, bins, bar_scale, range, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotHistogram_U64Ptr(label_id &char, values &u64, count i32, bins i32, bar_scale f64, range Range_c, spec Spec_c) f64

@[inline]
pub fn plot_histogram_u64_ptr(label_id &char, values &u64, count i32, bins i32, bar_scale f64, range Range_c, spec Spec_c) f64 {
	return C.ImPlot_PlotHistogram_U64Ptr(label_id, values, count, bins, bar_scale, range, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotHistogram2D_FloatPtr(label_id &char, xs &f32, ys &f32, count i32, x_bins i32, y_bins i32, range Rect_c, spec Spec_c) f64

@[inline]
pub fn plot_histogram2_d_float_ptr(label_id &char, xs &f32, ys &f32, count i32, x_bins i32, y_bins i32, range Rect_c, spec Spec_c) f64 {
	return C.ImPlot_PlotHistogram2D_FloatPtr(label_id, xs, ys, count, x_bins, y_bins, range, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotHistogram2D_doublePtr(label_id &char, xs &f64, ys &f64, count i32, x_bins i32, y_bins i32, range Rect_c, spec Spec_c) f64

@[inline]
pub fn plot_histogram2_d_double_ptr(label_id &char, xs &f64, ys &f64, count i32, x_bins i32, y_bins i32, range Rect_c, spec Spec_c) f64 {
	return C.ImPlot_PlotHistogram2D_doublePtr(label_id, xs, ys, count, x_bins, y_bins, range, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotHistogram2D_S8Ptr(label_id &char, xs &char, ys &char, count i32, x_bins i32, y_bins i32, range Rect_c, spec Spec_c) f64

@[inline]
pub fn plot_histogram2_d_s8_ptr(label_id &char, xs &char, ys &char, count i32, x_bins i32, y_bins i32, range Rect_c, spec Spec_c) f64 {
	return C.ImPlot_PlotHistogram2D_S8Ptr(label_id, xs, ys, count, x_bins, y_bins, range, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotHistogram2D_U8Ptr(label_id &char, xs &u8, ys &u8, count i32, x_bins i32, y_bins i32, range Rect_c, spec Spec_c) f64

@[inline]
pub fn plot_histogram2_d_u8_ptr(label_id &char, xs &u8, ys &u8, count i32, x_bins i32, y_bins i32, range Rect_c, spec Spec_c) f64 {
	return C.ImPlot_PlotHistogram2D_U8Ptr(label_id, xs, ys, count, x_bins, y_bins, range, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotHistogram2D_S16Ptr(label_id &char, xs &i16, ys &i16, count i32, x_bins i32, y_bins i32, range Rect_c, spec Spec_c) f64

@[inline]
pub fn plot_histogram2_d_s16_ptr(label_id &char, xs &i16, ys &i16, count i32, x_bins i32, y_bins i32, range Rect_c, spec Spec_c) f64 {
	return C.ImPlot_PlotHistogram2D_S16Ptr(label_id, xs, ys, count, x_bins, y_bins, range, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotHistogram2D_U16Ptr(label_id &char, xs &u16, ys &u16, count i32, x_bins i32, y_bins i32, range Rect_c, spec Spec_c) f64

@[inline]
pub fn plot_histogram2_d_u16_ptr(label_id &char, xs &u16, ys &u16, count i32, x_bins i32, y_bins i32, range Rect_c, spec Spec_c) f64 {
	return C.ImPlot_PlotHistogram2D_U16Ptr(label_id, xs, ys, count, x_bins, y_bins, range, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotHistogram2D_S32Ptr(label_id &char, xs &i32, ys &i32, count i32, x_bins i32, y_bins i32, range Rect_c, spec Spec_c) f64

@[inline]
pub fn plot_histogram2_d_s32_ptr(label_id &char, xs &i32, ys &i32, count i32, x_bins i32, y_bins i32, range Rect_c, spec Spec_c) f64 {
	return C.ImPlot_PlotHistogram2D_S32Ptr(label_id, xs, ys, count, x_bins, y_bins, range, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotHistogram2D_U32Ptr(label_id &char, xs &u32, ys &u32, count i32, x_bins i32, y_bins i32, range Rect_c, spec Spec_c) f64

@[inline]
pub fn plot_histogram2_d_u32_ptr(label_id &char, xs &u32, ys &u32, count i32, x_bins i32, y_bins i32, range Rect_c, spec Spec_c) f64 {
	return C.ImPlot_PlotHistogram2D_U32Ptr(label_id, xs, ys, count, x_bins, y_bins, range, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotHistogram2D_S64Ptr(label_id &char, xs &i64, ys &i64, count i32, x_bins i32, y_bins i32, range Rect_c, spec Spec_c) f64

@[inline]
pub fn plot_histogram2_d_s64_ptr(label_id &char, xs &i64, ys &i64, count i32, x_bins i32, y_bins i32, range Rect_c, spec Spec_c) f64 {
	return C.ImPlot_PlotHistogram2D_S64Ptr(label_id, xs, ys, count, x_bins, y_bins, range, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotHistogram2D_U64Ptr(label_id &char, xs &u64, ys &u64, count i32, x_bins i32, y_bins i32, range Rect_c, spec Spec_c) f64

@[inline]
pub fn plot_histogram2_d_u64_ptr(label_id &char, xs &u64, ys &u64, count i32, x_bins i32, y_bins i32, range Rect_c, spec Spec_c) f64 {
	return C.ImPlot_PlotHistogram2D_U64Ptr(label_id, xs, ys, count, x_bins, y_bins, range, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotDigital_FloatPtr(label_id &char, xs &f32, ys &f32, count i32, spec Spec_c)

@[inline]
pub fn plot_digital_float_ptr(label_id &char, xs &f32, ys &f32, count i32, spec Spec_c) {
	C.ImPlot_PlotDigital_FloatPtr(label_id, xs, ys, count, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotDigital_doublePtr(label_id &char, xs &f64, ys &f64, count i32, spec Spec_c)

@[inline]
pub fn plot_digital_double_ptr(label_id &char, xs &f64, ys &f64, count i32, spec Spec_c) {
	C.ImPlot_PlotDigital_doublePtr(label_id, xs, ys, count, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotDigital_S8Ptr(label_id &char, xs &char, ys &char, count i32, spec Spec_c)

@[inline]
pub fn plot_digital_s8_ptr(label_id &char, xs &char, ys &char, count i32, spec Spec_c) {
	C.ImPlot_PlotDigital_S8Ptr(label_id, xs, ys, count, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotDigital_U8Ptr(label_id &char, xs &u8, ys &u8, count i32, spec Spec_c)

@[inline]
pub fn plot_digital_u8_ptr(label_id &char, xs &u8, ys &u8, count i32, spec Spec_c) {
	C.ImPlot_PlotDigital_U8Ptr(label_id, xs, ys, count, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotDigital_S16Ptr(label_id &char, xs &i16, ys &i16, count i32, spec Spec_c)

@[inline]
pub fn plot_digital_s16_ptr(label_id &char, xs &i16, ys &i16, count i32, spec Spec_c) {
	C.ImPlot_PlotDigital_S16Ptr(label_id, xs, ys, count, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotDigital_U16Ptr(label_id &char, xs &u16, ys &u16, count i32, spec Spec_c)

@[inline]
pub fn plot_digital_u16_ptr(label_id &char, xs &u16, ys &u16, count i32, spec Spec_c) {
	C.ImPlot_PlotDigital_U16Ptr(label_id, xs, ys, count, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotDigital_S32Ptr(label_id &char, xs &i32, ys &i32, count i32, spec Spec_c)

@[inline]
pub fn plot_digital_s32_ptr(label_id &char, xs &i32, ys &i32, count i32, spec Spec_c) {
	C.ImPlot_PlotDigital_S32Ptr(label_id, xs, ys, count, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotDigital_U32Ptr(label_id &char, xs &u32, ys &u32, count i32, spec Spec_c)

@[inline]
pub fn plot_digital_u32_ptr(label_id &char, xs &u32, ys &u32, count i32, spec Spec_c) {
	C.ImPlot_PlotDigital_U32Ptr(label_id, xs, ys, count, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotDigital_S64Ptr(label_id &char, xs &i64, ys &i64, count i32, spec Spec_c)

@[inline]
pub fn plot_digital_s64_ptr(label_id &char, xs &i64, ys &i64, count i32, spec Spec_c) {
	C.ImPlot_PlotDigital_S64Ptr(label_id, xs, ys, count, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotDigital_U64Ptr(label_id &char, xs &u64, ys &u64, count i32, spec Spec_c)

@[inline]
pub fn plot_digital_u64_ptr(label_id &char, xs &u64, ys &u64, count i32, spec Spec_c) {
	C.ImPlot_PlotDigital_U64Ptr(label_id, xs, ys, count, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotDigitalG_LJ(label_id &char, getter Point_getter, data voidptr, count i32, spec Spec_c)

@[inline]
pub fn plot_digital_g_lj(label_id &char, getter Point_getter, data voidptr, count i32, spec Spec_c) {
	C.ImPlot_PlotDigitalG_LJ(label_id, getter, data, count, spec)
}

// custom generation

@[keep_args_alive]
fn C.ImPlot_PlotDigitalG(label_id &char, getter Getter, data voidptr, count i32, spec Spec_c)

@[inline]
pub fn plot_digital_g(label_id &char, getter Getter, data voidptr, count i32, spec Spec_c) {
	C.ImPlot_PlotDigitalG(label_id, getter, data, count, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotImage(label_id &char, tex_ref ImTextureRef_c, bounds_min Point_c, bounds_max Point_c, uv0 ImVec2_c, uv1 ImVec2_c, tint_col ImVec4_c, spec Spec_c)

@[inline]
pub fn plot_image(label_id &char, tex_ref ImTextureRef_c, bounds_min Point_c, bounds_max Point_c, uv0 ImVec2_c, uv1 ImVec2_c, tint_col ImVec4_c, spec Spec_c) {
	C.ImPlot_PlotImage(label_id, tex_ref, bounds_min, bounds_max, uv0, uv1, tint_col, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotText(const_text &char, x f64, y f64, pix_offset ImVec2_c, spec Spec_c)

@[inline]
pub fn plot_text(const_text &char, x f64, y f64, pix_offset ImVec2_c, spec Spec_c) {
	C.ImPlot_PlotText(const_text, x, y, pix_offset, spec)
}


@[keep_args_alive]
fn C.ImPlot_PlotDummy(label_id &char, spec Spec_c)

@[inline]
pub fn plot_dummy(label_id &char, spec Spec_c) {
	C.ImPlot_PlotDummy(label_id, spec)
}


@[keep_args_alive]
fn C.ImPlot_DragPoint(id i32, x &f64, y &f64, col ImVec4_c, size f32, flags DragToolFlags, out_clicked &bool, out_hovered &bool, out_held &bool) bool

@[inline]
pub fn drag_point(id i32, x &f64, y &f64, col ImVec4_c, size f32, flags DragToolFlags, out_clicked &bool, out_hovered &bool, out_held &bool) bool {
	return C.ImPlot_DragPoint(id, x, y, col, size, flags, out_clicked, out_hovered, out_held)
}


@[keep_args_alive]
fn C.ImPlot_DragLineX(id i32, x &f64, col ImVec4_c, thickness f32, flags DragToolFlags, out_clicked &bool, out_hovered &bool, out_held &bool) bool

@[inline]
pub fn drag_line_x(id i32, x &f64, col ImVec4_c, thickness f32, flags DragToolFlags, out_clicked &bool, out_hovered &bool, out_held &bool) bool {
	return C.ImPlot_DragLineX(id, x, col, thickness, flags, out_clicked, out_hovered, out_held)
}


@[keep_args_alive]
fn C.ImPlot_DragLineY(id i32, y &f64, col ImVec4_c, thickness f32, flags DragToolFlags, out_clicked &bool, out_hovered &bool, out_held &bool) bool

@[inline]
pub fn drag_line_y(id i32, y &f64, col ImVec4_c, thickness f32, flags DragToolFlags, out_clicked &bool, out_hovered &bool, out_held &bool) bool {
	return C.ImPlot_DragLineY(id, y, col, thickness, flags, out_clicked, out_hovered, out_held)
}


@[keep_args_alive]
fn C.ImPlot_DragRect(id i32, x1 &f64, y1 &f64, x2 &f64, y2 &f64, col ImVec4_c, flags DragToolFlags, out_clicked &bool, out_hovered &bool, out_held &bool) bool

@[inline]
pub fn drag_rect(id i32, x1 &f64, y1 &f64, x2 &f64, y2 &f64, col ImVec4_c, flags DragToolFlags, out_clicked &bool, out_hovered &bool, out_held &bool) bool {
	return C.ImPlot_DragRect(id, x1, y1, x2, y2, col, flags, out_clicked, out_hovered, out_held)
}


@[keep_args_alive]
fn C.ImPlot_Annotation_Bool(x f64, y f64, col ImVec4_c, pix_offset ImVec2_c, clamp bool, round bool)

@[inline]
pub fn annotation_bool(x f64, y f64, col ImVec4_c, pix_offset ImVec2_c, clamp bool, round bool) {
	C.ImPlot_Annotation_Bool(x, y, col, pix_offset, clamp, round)
}


@[keep_args_alive]
fn C.ImPlot_Annotation_Str(x f64, y f64, col ImVec4_c, pix_offset ImVec2_c, clamp bool, const_fmt &char)

@[inline]
pub fn annotation_str(x f64, y f64, col ImVec4_c, pix_offset ImVec2_c, clamp bool, const_fmt &char) {
	C.ImPlot_Annotation_Str(x, y, col, pix_offset, clamp, const_fmt)
}


@[keep_args_alive]
fn C.ImPlot_AnnotationV(x f64, y f64, col ImVec4_c, pix_offset ImVec2_c, clamp bool, const_fmt &char, args Va_list)

@[inline]
pub fn annotation_v(x f64, y f64, col ImVec4_c, pix_offset ImVec2_c, clamp bool, const_fmt &char, args Va_list) {
	C.ImPlot_AnnotationV(x, y, col, pix_offset, clamp, const_fmt, args)
}


@[keep_args_alive]
fn C.ImPlot_TagX_Bool(x f64, col ImVec4_c, round bool)

@[inline]
pub fn tag_x_bool(x f64, col ImVec4_c, round bool) {
	C.ImPlot_TagX_Bool(x, col, round)
}


@[keep_args_alive]
fn C.ImPlot_TagX_Str(x f64, col ImVec4_c, const_fmt &char)

@[inline]
pub fn tag_x_str(x f64, col ImVec4_c, const_fmt &char) {
	C.ImPlot_TagX_Str(x, col, const_fmt)
}


@[keep_args_alive]
fn C.ImPlot_TagXV(x f64, col ImVec4_c, const_fmt &char, args Va_list)

@[inline]
pub fn tag_xv(x f64, col ImVec4_c, const_fmt &char, args Va_list) {
	C.ImPlot_TagXV(x, col, const_fmt, args)
}


@[keep_args_alive]
fn C.ImPlot_TagY_Bool(y f64, col ImVec4_c, round bool)

@[inline]
pub fn tag_y_bool(y f64, col ImVec4_c, round bool) {
	C.ImPlot_TagY_Bool(y, col, round)
}


@[keep_args_alive]
fn C.ImPlot_TagY_Str(y f64, col ImVec4_c, const_fmt &char)

@[inline]
pub fn tag_y_str(y f64, col ImVec4_c, const_fmt &char) {
	C.ImPlot_TagY_Str(y, col, const_fmt)
}


@[keep_args_alive]
fn C.ImPlot_TagYV(y f64, col ImVec4_c, const_fmt &char, args Va_list)

@[inline]
pub fn tag_yv(y f64, col ImVec4_c, const_fmt &char, args Va_list) {
	C.ImPlot_TagYV(y, col, const_fmt, args)
}


@[keep_args_alive]
fn C.ImPlot_SetAxis(axis ImAxis)

@[inline]
pub fn set_axis(axis ImAxis) {
	C.ImPlot_SetAxis(axis)
}


@[keep_args_alive]
fn C.ImPlot_SetAxes(x_axis ImAxis, y_axis ImAxis)

@[inline]
pub fn set_axes(x_axis ImAxis, y_axis ImAxis) {
	C.ImPlot_SetAxes(x_axis, y_axis)
}


@[keep_args_alive]
fn C.ImPlot_PixelsToPlot_Vec2(pix ImVec2_c, x_axis ImAxis, y_axis ImAxis) Point_c

@[inline]
pub fn pixels_to_plot_vec2(pix ImVec2_c, x_axis ImAxis, y_axis ImAxis) Point_c {
	return C.ImPlot_PixelsToPlot_Vec2(pix, x_axis, y_axis)
}


@[keep_args_alive]
fn C.ImPlot_PixelsToPlot_Float(x f32, y f32, x_axis ImAxis, y_axis ImAxis) Point_c

@[inline]
pub fn pixels_to_plot_float(x f32, y f32, x_axis ImAxis, y_axis ImAxis) Point_c {
	return C.ImPlot_PixelsToPlot_Float(x, y, x_axis, y_axis)
}


@[keep_args_alive]
fn C.ImPlot_PlotToPixels_PlotPoint(plt Point_c, x_axis ImAxis, y_axis ImAxis) ImVec2_c

@[inline]
pub fn plot_to_pixels_plot_point(plt Point_c, x_axis ImAxis, y_axis ImAxis) ImVec2_c {
	return C.ImPlot_PlotToPixels_PlotPoint(plt, x_axis, y_axis)
}


@[keep_args_alive]
fn C.ImPlot_PlotToPixels_double(x f64, y f64, x_axis ImAxis, y_axis ImAxis) ImVec2_c

@[inline]
pub fn plot_to_pixels_double(x f64, y f64, x_axis ImAxis, y_axis ImAxis) ImVec2_c {
	return C.ImPlot_PlotToPixels_double(x, y, x_axis, y_axis)
}


@[keep_args_alive]
fn C.ImPlot_GetPlotPos() ImVec2_c

@[inline]
pub fn get_plot_pos() ImVec2_c {
	return C.ImPlot_GetPlotPos()
}


@[keep_args_alive]
fn C.ImPlot_GetPlotSize() ImVec2_c

@[inline]
pub fn get_plot_size() ImVec2_c {
	return C.ImPlot_GetPlotSize()
}


@[keep_args_alive]
fn C.ImPlot_GetPlotMousePos(x_axis ImAxis, y_axis ImAxis) Point_c

@[inline]
pub fn get_plot_mouse_pos(x_axis ImAxis, y_axis ImAxis) Point_c {
	return C.ImPlot_GetPlotMousePos(x_axis, y_axis)
}


@[keep_args_alive]
fn C.ImPlot_GetPlotLimits(x_axis ImAxis, y_axis ImAxis) Rect_c

@[inline]
pub fn get_plot_limits(x_axis ImAxis, y_axis ImAxis) Rect_c {
	return C.ImPlot_GetPlotLimits(x_axis, y_axis)
}


@[keep_args_alive]
fn C.ImPlot_IsPlotHovered() bool

@[inline]
pub fn is_plot_hovered() bool {
	return C.ImPlot_IsPlotHovered()
}


@[keep_args_alive]
fn C.ImPlot_IsAxisHovered(axis ImAxis) bool

@[inline]
pub fn is_axis_hovered(axis ImAxis) bool {
	return C.ImPlot_IsAxisHovered(axis)
}


@[keep_args_alive]
fn C.ImPlot_IsSubplotsHovered() bool

@[inline]
pub fn is_subplots_hovered() bool {
	return C.ImPlot_IsSubplotsHovered()
}


@[keep_args_alive]
fn C.ImPlot_IsPlotSelected() bool

@[inline]
pub fn is_plot_selected() bool {
	return C.ImPlot_IsPlotSelected()
}


@[keep_args_alive]
fn C.ImPlot_GetPlotSelection(x_axis ImAxis, y_axis ImAxis) Rect_c

@[inline]
pub fn get_plot_selection(x_axis ImAxis, y_axis ImAxis) Rect_c {
	return C.ImPlot_GetPlotSelection(x_axis, y_axis)
}


@[keep_args_alive]
fn C.ImPlot_CancelPlotSelection()

@[inline]
pub fn cancel_plot_selection() {
	C.ImPlot_CancelPlotSelection()
}


@[keep_args_alive]
fn C.ImPlot_HideNextItem(hidden bool, cond Cond)

@[inline]
pub fn hide_next_item(hidden bool, cond Cond) {
	C.ImPlot_HideNextItem(hidden, cond)
}


@[keep_args_alive]
fn C.ImPlot_BeginAlignedPlots(group_id &char, vertical bool) bool

@[inline]
pub fn begin_aligned_plots(group_id &char, vertical bool) bool {
	return C.ImPlot_BeginAlignedPlots(group_id, vertical)
}


@[keep_args_alive]
fn C.ImPlot_EndAlignedPlots()

@[inline]
pub fn end_aligned_plots() {
	C.ImPlot_EndAlignedPlots()
}


@[keep_args_alive]
fn C.ImPlot_BeginLegendPopup(label_id &char, mouse_button imgui.MouseButton) bool

@[inline]
pub fn begin_legend_popup(label_id &char, mouse_button imgui.MouseButton) bool {
	return C.ImPlot_BeginLegendPopup(label_id, mouse_button)
}


@[keep_args_alive]
fn C.ImPlot_EndLegendPopup()

@[inline]
pub fn end_legend_popup() {
	C.ImPlot_EndLegendPopup()
}


@[keep_args_alive]
fn C.ImPlot_IsLegendEntryHovered(label_id &char) bool

@[inline]
pub fn is_legend_entry_hovered(label_id &char) bool {
	return C.ImPlot_IsLegendEntryHovered(label_id)
}


@[keep_args_alive]
fn C.ImPlot_BeginDragDropTargetPlot() bool

@[inline]
pub fn begin_drag_drop_target_plot() bool {
	return C.ImPlot_BeginDragDropTargetPlot()
}


@[keep_args_alive]
fn C.ImPlot_BeginDragDropTargetAxis(axis ImAxis) bool

@[inline]
pub fn begin_drag_drop_target_axis(axis ImAxis) bool {
	return C.ImPlot_BeginDragDropTargetAxis(axis)
}


@[keep_args_alive]
fn C.ImPlot_BeginDragDropTargetLegend() bool

@[inline]
pub fn begin_drag_drop_target_legend() bool {
	return C.ImPlot_BeginDragDropTargetLegend()
}


@[keep_args_alive]
fn C.ImPlot_EndDragDropTarget()

@[inline]
pub fn end_drag_drop_target() {
	C.ImPlot_EndDragDropTarget()
}


@[keep_args_alive]
fn C.ImPlot_BeginDragDropSourcePlot(flags imgui.DragDropFlags) bool

@[inline]
pub fn begin_drag_drop_source_plot(flags imgui.DragDropFlags) bool {
	return C.ImPlot_BeginDragDropSourcePlot(flags)
}


@[keep_args_alive]
fn C.ImPlot_BeginDragDropSourceAxis(axis ImAxis, flags imgui.DragDropFlags) bool

@[inline]
pub fn begin_drag_drop_source_axis(axis ImAxis, flags imgui.DragDropFlags) bool {
	return C.ImPlot_BeginDragDropSourceAxis(axis, flags)
}


@[keep_args_alive]
fn C.ImPlot_BeginDragDropSourceItem(label_id &char, flags imgui.DragDropFlags) bool

@[inline]
pub fn begin_drag_drop_source_item(label_id &char, flags imgui.DragDropFlags) bool {
	return C.ImPlot_BeginDragDropSourceItem(label_id, flags)
}


@[keep_args_alive]
fn C.ImPlot_EndDragDropSource()

@[inline]
pub fn end_drag_drop_source() {
	C.ImPlot_EndDragDropSource()
}


@[keep_args_alive]
fn C.ImPlot_GetStyle() &Style

@[inline]
pub fn get_style() &Style {
	return C.ImPlot_GetStyle()
}


@[keep_args_alive]
fn C.ImPlot_StyleColorsAuto(dst &Style)

@[inline]
pub fn style_colors_auto(dst &Style) {
	C.ImPlot_StyleColorsAuto(dst)
}


@[keep_args_alive]
fn C.ImPlot_StyleColorsClassic(dst &Style)

@[inline]
pub fn style_colors_classic(dst &Style) {
	C.ImPlot_StyleColorsClassic(dst)
}


@[keep_args_alive]
fn C.ImPlot_StyleColorsDark(dst &Style)

@[inline]
pub fn style_colors_dark(dst &Style) {
	C.ImPlot_StyleColorsDark(dst)
}


@[keep_args_alive]
fn C.ImPlot_StyleColorsLight(dst &Style)

@[inline]
pub fn style_colors_light(dst &Style) {
	C.ImPlot_StyleColorsLight(dst)
}


@[keep_args_alive]
fn C.ImPlot_PushStyleColor_U32(idx Col, col u32)

@[inline]
pub fn push_style_color_u32(idx Col, col u32) {
	C.ImPlot_PushStyleColor_U32(idx, col)
}


@[keep_args_alive]
fn C.ImPlot_PushStyleColor_Vec4(idx Col, col ImVec4_c)

@[inline]
pub fn push_style_color_vec4(idx Col, col ImVec4_c) {
	C.ImPlot_PushStyleColor_Vec4(idx, col)
}


@[keep_args_alive]
fn C.ImPlot_PopStyleColor(count i32)

@[inline]
pub fn pop_style_color(count i32) {
	C.ImPlot_PopStyleColor(count)
}


@[keep_args_alive]
fn C.ImPlot_PushStyleVar_Float(idx StyleVar, val f32)

@[inline]
pub fn push_style_var_float(idx StyleVar, val f32) {
	C.ImPlot_PushStyleVar_Float(idx, val)
}


@[keep_args_alive]
fn C.ImPlot_PushStyleVar_Int(idx StyleVar, val i32)

@[inline]
pub fn push_style_var_int(idx StyleVar, val i32) {
	C.ImPlot_PushStyleVar_Int(idx, val)
}


@[keep_args_alive]
fn C.ImPlot_PushStyleVar_Vec2(idx StyleVar, val ImVec2_c)

@[inline]
pub fn push_style_var_vec2(idx StyleVar, val ImVec2_c) {
	C.ImPlot_PushStyleVar_Vec2(idx, val)
}


@[keep_args_alive]
fn C.ImPlot_PopStyleVar(count i32)

@[inline]
pub fn pop_style_var(count i32) {
	C.ImPlot_PopStyleVar(count)
}


@[keep_args_alive]
fn C.ImPlot_GetLastItemColor() ImVec4_c

@[inline]
pub fn get_last_item_color() ImVec4_c {
	return C.ImPlot_GetLastItemColor()
}


@[keep_args_alive]
fn C.ImPlot_GetStyleColorName(idx Col) &char

@[inline]
pub fn get_style_color_name(idx Col) &char {
	return C.ImPlot_GetStyleColorName(idx)
}


@[keep_args_alive]
fn C.ImPlot_GetMarkerName(idx Marker) &char

@[inline]
pub fn get_marker_name(idx Marker) &char {
	return C.ImPlot_GetMarkerName(idx)
}


@[keep_args_alive]
fn C.ImPlot_NextMarker() Marker

@[inline]
pub fn next_marker() Marker {
	return C.ImPlot_NextMarker()
}


@[keep_args_alive]
fn C.ImPlot_AddColormap_Vec4Ptr(const_name &char, cols &imgui.ImVec4, size i32, qual bool) Colormap

@[inline]
pub fn add_colormap_vec4_ptr(const_name &char, cols &imgui.ImVec4, size i32, qual bool) Colormap {
	return C.ImPlot_AddColormap_Vec4Ptr(const_name, cols, size, qual)
}


@[keep_args_alive]
fn C.ImPlot_AddColormap_U32Ptr(const_name &char, cols &u32, size i32, qual bool) Colormap

@[inline]
pub fn add_colormap_u32_ptr(const_name &char, cols &u32, size i32, qual bool) Colormap {
	return C.ImPlot_AddColormap_U32Ptr(const_name, cols, size, qual)
}


@[keep_args_alive]
fn C.ImPlot_GetColormapCount() i32

@[inline]
pub fn get_colormap_count() i32 {
	return C.ImPlot_GetColormapCount()
}


@[keep_args_alive]
fn C.ImPlot_GetColormapName(cmap Colormap) &char

@[inline]
pub fn get_colormap_name(cmap Colormap) &char {
	return C.ImPlot_GetColormapName(cmap)
}


@[keep_args_alive]
fn C.ImPlot_GetColormapIndex(const_name &char) Colormap

@[inline]
pub fn get_colormap_index(const_name &char) Colormap {
	return C.ImPlot_GetColormapIndex(const_name)
}


@[keep_args_alive]
fn C.ImPlot_PushColormap_PlotColormap(cmap Colormap)

@[inline]
pub fn push_colormap_plot_colormap(cmap Colormap) {
	C.ImPlot_PushColormap_PlotColormap(cmap)
}


@[keep_args_alive]
fn C.ImPlot_PushColormap_Str(const_name &char)

@[inline]
pub fn push_colormap_str(const_name &char) {
	C.ImPlot_PushColormap_Str(const_name)
}


@[keep_args_alive]
fn C.ImPlot_PopColormap(count i32)

@[inline]
pub fn pop_colormap(count i32) {
	C.ImPlot_PopColormap(count)
}


@[keep_args_alive]
fn C.ImPlot_NextColormapColor() ImVec4_c

@[inline]
pub fn next_colormap_color() ImVec4_c {
	return C.ImPlot_NextColormapColor()
}


@[keep_args_alive]
fn C.ImPlot_GetColormapSize(cmap Colormap) i32

@[inline]
pub fn get_colormap_size(cmap Colormap) i32 {
	return C.ImPlot_GetColormapSize(cmap)
}


@[keep_args_alive]
fn C.ImPlot_GetColormapColor(idx i32, cmap Colormap) ImVec4_c

@[inline]
pub fn get_colormap_color(idx i32, cmap Colormap) ImVec4_c {
	return C.ImPlot_GetColormapColor(idx, cmap)
}


@[keep_args_alive]
fn C.ImPlot_SampleColormap(t f32, cmap Colormap) ImVec4_c

@[inline]
pub fn sample_colormap(t f32, cmap Colormap) ImVec4_c {
	return C.ImPlot_SampleColormap(t, cmap)
}


@[keep_args_alive]
fn C.ImPlot_ColormapScale(const_label &char, scale_min f64, scale_max f64, size ImVec2_c, format &char, flags ColormapScaleFlags, cmap Colormap)

@[inline]
pub fn colormap_scale(const_label &char, scale_min f64, scale_max f64, size ImVec2_c, format &char, flags ColormapScaleFlags, cmap Colormap) {
	C.ImPlot_ColormapScale(const_label, scale_min, scale_max, size, format, flags, cmap)
}


@[keep_args_alive]
fn C.ImPlot_ColormapSlider(const_label &char, t &f32, out &imgui.ImVec4, format &char, cmap Colormap) bool

@[inline]
pub fn colormap_slider(const_label &char, t &f32, out &imgui.ImVec4, format &char, cmap Colormap) bool {
	return C.ImPlot_ColormapSlider(const_label, t, out, format, cmap)
}


@[keep_args_alive]
fn C.ImPlot_ColormapButton(const_label &char, size ImVec2_c, cmap Colormap) bool

@[inline]
pub fn colormap_button(const_label &char, size ImVec2_c, cmap Colormap) bool {
	return C.ImPlot_ColormapButton(const_label, size, cmap)
}


@[keep_args_alive]
fn C.ImPlot_BustColorCache(plot_title_id &char)

@[inline]
pub fn bust_color_cache(plot_title_id &char) {
	C.ImPlot_BustColorCache(plot_title_id)
}


@[keep_args_alive]
fn C.ImPlot_GetInputMap() &InputMap

@[inline]
pub fn get_input_map() &InputMap {
	return C.ImPlot_GetInputMap()
}


@[keep_args_alive]
fn C.ImPlot_MapInputDefault(dst &InputMap)

@[inline]
pub fn map_input_default(dst &InputMap) {
	C.ImPlot_MapInputDefault(dst)
}


@[keep_args_alive]
fn C.ImPlot_MapInputReverse(dst &InputMap)

@[inline]
pub fn map_input_reverse(dst &InputMap) {
	C.ImPlot_MapInputReverse(dst)
}


@[keep_args_alive]
fn C.ImPlot_ItemIcon_Vec4(col ImVec4_c)

@[inline]
pub fn item_icon_vec4(col ImVec4_c) {
	C.ImPlot_ItemIcon_Vec4(col)
}


@[keep_args_alive]
fn C.ImPlot_ItemIcon_U32(col u32)

@[inline]
pub fn item_icon_u32(col u32) {
	C.ImPlot_ItemIcon_U32(col)
}


@[keep_args_alive]
fn C.ImPlot_ColormapIcon(cmap Colormap)

@[inline]
pub fn colormap_icon(cmap Colormap) {
	C.ImPlot_ColormapIcon(cmap)
}


@[keep_args_alive]
fn C.ImPlot_GetPlotDrawList() &imgui.ImDrawList

@[inline]
pub fn get_plot_draw_list() &imgui.ImDrawList {
	return C.ImPlot_GetPlotDrawList()
}


@[keep_args_alive]
fn C.ImPlot_PushPlotClipRect(expand f32)

@[inline]
pub fn push_plot_clip_rect(expand f32) {
	C.ImPlot_PushPlotClipRect(expand)
}


@[keep_args_alive]
fn C.ImPlot_PopPlotClipRect()

@[inline]
pub fn pop_plot_clip_rect() {
	C.ImPlot_PopPlotClipRect()
}


@[keep_args_alive]
fn C.ImPlot_ShowStyleSelector(const_label &char) bool

@[inline]
pub fn show_style_selector(const_label &char) bool {
	return C.ImPlot_ShowStyleSelector(const_label)
}


@[keep_args_alive]
fn C.ImPlot_ShowColormapSelector(const_label &char) bool

@[inline]
pub fn show_colormap_selector(const_label &char) bool {
	return C.ImPlot_ShowColormapSelector(const_label)
}


@[keep_args_alive]
fn C.ImPlot_ShowInputMapSelector(const_label &char) bool

@[inline]
pub fn show_input_map_selector(const_label &char) bool {
	return C.ImPlot_ShowInputMapSelector(const_label)
}


@[keep_args_alive]
fn C.ImPlot_ShowStyleEditor(ref &Style)

@[inline]
pub fn show_style_editor(ref &Style) {
	C.ImPlot_ShowStyleEditor(ref)
}


@[keep_args_alive]
fn C.ImPlot_ShowUserGuide()

@[inline]
pub fn show_user_guide() {
	C.ImPlot_ShowUserGuide()
}


@[keep_args_alive]
fn C.ImPlot_ShowMetricsWindow(p_popen &bool)

@[inline]
pub fn show_metrics_window(p_popen &bool) {
	C.ImPlot_ShowMetricsWindow(p_popen)
}


@[keep_args_alive]
fn C.ImPlot_ShowDemoWindow(p_open &bool)

@[inline]
pub fn show_demo_window(p_open &bool) {
	C.ImPlot_ShowDemoWindow(p_open)
}


@[keep_args_alive]
fn C.ImPlot_ImLog10_Float(x f32) f32

@[inline]
pub fn im_log10_float(x f32) f32 {
	return C.ImPlot_ImLog10_Float(x)
}


@[keep_args_alive]
fn C.ImPlot_ImLog10_double(x f64) f64

@[inline]
pub fn im_log10_double(x f64) f64 {
	return C.ImPlot_ImLog10_double(x)
}


@[keep_args_alive]
fn C.ImPlot_ImSinh_Float(x f32) f32

@[inline]
pub fn im_sinh_float(x f32) f32 {
	return C.ImPlot_ImSinh_Float(x)
}


@[keep_args_alive]
fn C.ImPlot_ImSinh_double(x f64) f64

@[inline]
pub fn im_sinh_double(x f64) f64 {
	return C.ImPlot_ImSinh_double(x)
}


@[keep_args_alive]
fn C.ImPlot_ImAsinh_Float(x f32) f32

@[inline]
pub fn im_asinh_float(x f32) f32 {
	return C.ImPlot_ImAsinh_Float(x)
}


@[keep_args_alive]
fn C.ImPlot_ImAsinh_double(x f64) f64

@[inline]
pub fn im_asinh_double(x f64) f64 {
	return C.ImPlot_ImAsinh_double(x)
}


@[keep_args_alive]
fn C.ImPlot_ImRemap_Float(x f32, x0 f32, x1 f32, y0 f32, y1 f32) f32

@[inline]
pub fn im_remap_float(x f32, x0 f32, x1 f32, y0 f32, y1 f32) f32 {
	return C.ImPlot_ImRemap_Float(x, x0, x1, y0, y1)
}


@[keep_args_alive]
fn C.ImPlot_ImRemap_double(x f64, x0 f64, x1 f64, y0 f64, y1 f64) f64

@[inline]
pub fn im_remap_double(x f64, x0 f64, x1 f64, y0 f64, y1 f64) f64 {
	return C.ImPlot_ImRemap_double(x, x0, x1, y0, y1)
}


@[keep_args_alive]
fn C.ImPlot_ImRemap_S8(x i8, x0 i8, x1 i8, y0 i8, y1 i8) i8

@[inline]
pub fn im_remap_s8(x i8, x0 i8, x1 i8, y0 i8, y1 i8) i8 {
	return C.ImPlot_ImRemap_S8(x, x0, x1, y0, y1)
}


@[keep_args_alive]
fn C.ImPlot_ImRemap_U8(x u8, x0 u8, x1 u8, y0 u8, y1 u8) u8

@[inline]
pub fn im_remap_u8(x u8, x0 u8, x1 u8, y0 u8, y1 u8) u8 {
	return C.ImPlot_ImRemap_U8(x, x0, x1, y0, y1)
}


@[keep_args_alive]
fn C.ImPlot_ImRemap_S16(x i16, x0 i16, x1 i16, y0 i16, y1 i16) i16

@[inline]
pub fn im_remap_s16(x i16, x0 i16, x1 i16, y0 i16, y1 i16) i16 {
	return C.ImPlot_ImRemap_S16(x, x0, x1, y0, y1)
}


@[keep_args_alive]
fn C.ImPlot_ImRemap_U16(x u16, x0 u16, x1 u16, y0 u16, y1 u16) u16

@[inline]
pub fn im_remap_u16(x u16, x0 u16, x1 u16, y0 u16, y1 u16) u16 {
	return C.ImPlot_ImRemap_U16(x, x0, x1, y0, y1)
}


@[keep_args_alive]
fn C.ImPlot_ImRemap_S32(x i32, x0 i32, x1 i32, y0 i32, y1 i32) i32

@[inline]
pub fn im_remap_s32(x i32, x0 i32, x1 i32, y0 i32, y1 i32) i32 {
	return C.ImPlot_ImRemap_S32(x, x0, x1, y0, y1)
}


@[keep_args_alive]
fn C.ImPlot_ImRemap_U32(x u32, x0 u32, x1 u32, y0 u32, y1 u32) u32

@[inline]
pub fn im_remap_u32(x u32, x0 u32, x1 u32, y0 u32, y1 u32) u32 {
	return C.ImPlot_ImRemap_U32(x, x0, x1, y0, y1)
}


@[keep_args_alive]
fn C.ImPlot_ImRemap_S64(x i64, x0 i64, x1 i64, y0 i64, y1 i64) i64

@[inline]
pub fn im_remap_s64(x i64, x0 i64, x1 i64, y0 i64, y1 i64) i64 {
	return C.ImPlot_ImRemap_S64(x, x0, x1, y0, y1)
}


@[keep_args_alive]
fn C.ImPlot_ImRemap_U64(x u64, x0 u64, x1 u64, y0 u64, y1 u64) u64

@[inline]
pub fn im_remap_u64(x u64, x0 u64, x1 u64, y0 u64, y1 u64) u64 {
	return C.ImPlot_ImRemap_U64(x, x0, x1, y0, y1)
}


@[keep_args_alive]
fn C.ImPlot_ImRemap01_Float(x f32, x0 f32, x1 f32) f32

@[inline]
pub fn im_remap01_float(x f32, x0 f32, x1 f32) f32 {
	return C.ImPlot_ImRemap01_Float(x, x0, x1)
}


@[keep_args_alive]
fn C.ImPlot_ImRemap01_double(x f64, x0 f64, x1 f64) f64

@[inline]
pub fn im_remap01_double(x f64, x0 f64, x1 f64) f64 {
	return C.ImPlot_ImRemap01_double(x, x0, x1)
}


@[keep_args_alive]
fn C.ImPlot_ImRemap01_S8(x i8, x0 i8, x1 i8) i8

@[inline]
pub fn im_remap01_s8(x i8, x0 i8, x1 i8) i8 {
	return C.ImPlot_ImRemap01_S8(x, x0, x1)
}


@[keep_args_alive]
fn C.ImPlot_ImRemap01_U8(x u8, x0 u8, x1 u8) u8

@[inline]
pub fn im_remap01_u8(x u8, x0 u8, x1 u8) u8 {
	return C.ImPlot_ImRemap01_U8(x, x0, x1)
}


@[keep_args_alive]
fn C.ImPlot_ImRemap01_S16(x i16, x0 i16, x1 i16) i16

@[inline]
pub fn im_remap01_s16(x i16, x0 i16, x1 i16) i16 {
	return C.ImPlot_ImRemap01_S16(x, x0, x1)
}


@[keep_args_alive]
fn C.ImPlot_ImRemap01_U16(x u16, x0 u16, x1 u16) u16

@[inline]
pub fn im_remap01_u16(x u16, x0 u16, x1 u16) u16 {
	return C.ImPlot_ImRemap01_U16(x, x0, x1)
}


@[keep_args_alive]
fn C.ImPlot_ImRemap01_S32(x i32, x0 i32, x1 i32) i32

@[inline]
pub fn im_remap01_s32(x i32, x0 i32, x1 i32) i32 {
	return C.ImPlot_ImRemap01_S32(x, x0, x1)
}


@[keep_args_alive]
fn C.ImPlot_ImRemap01_U32(x u32, x0 u32, x1 u32) u32

@[inline]
pub fn im_remap01_u32(x u32, x0 u32, x1 u32) u32 {
	return C.ImPlot_ImRemap01_U32(x, x0, x1)
}


@[keep_args_alive]
fn C.ImPlot_ImRemap01_S64(x i64, x0 i64, x1 i64) i64

@[inline]
pub fn im_remap01_s64(x i64, x0 i64, x1 i64) i64 {
	return C.ImPlot_ImRemap01_S64(x, x0, x1)
}


@[keep_args_alive]
fn C.ImPlot_ImRemap01_U64(x u64, x0 u64, x1 u64) u64

@[inline]
pub fn im_remap01_u64(x u64, x0 u64, x1 u64) u64 {
	return C.ImPlot_ImRemap01_U64(x, x0, x1)
}


@[keep_args_alive]
fn C.ImPlot_ImPosMod(l i32, r i32) i32

@[inline]
pub fn im_pos_mod(l i32, r i32) i32 {
	return C.ImPlot_ImPosMod(l, r)
}


@[keep_args_alive]
fn C.ImPlot_ImNan(val f64) bool

@[inline]
pub fn im_nan(val f64) bool {
	return C.ImPlot_ImNan(val)
}


@[keep_args_alive]
fn C.ImPlot_ImNanOrInf(val f64) bool

@[inline]
pub fn im_nan_or_inf(val f64) bool {
	return C.ImPlot_ImNanOrInf(val)
}


@[keep_args_alive]
fn C.ImPlot_ImConstrainNan(val f64) f64

@[inline]
pub fn im_constrain_nan(val f64) f64 {
	return C.ImPlot_ImConstrainNan(val)
}


@[keep_args_alive]
fn C.ImPlot_ImConstrainInf(val f64) f64

@[inline]
pub fn im_constrain_inf(val f64) f64 {
	return C.ImPlot_ImConstrainInf(val)
}


@[keep_args_alive]
fn C.ImPlot_ImConstrainLog(val f64) f64

@[inline]
pub fn im_constrain_log(val f64) f64 {
	return C.ImPlot_ImConstrainLog(val)
}


@[keep_args_alive]
fn C.ImPlot_ImConstrainTime(val f64) f64

@[inline]
pub fn im_constrain_time(val f64) f64 {
	return C.ImPlot_ImConstrainTime(val)
}


@[keep_args_alive]
fn C.ImPlot_ImAlmostEqual(v1 f64, v2 f64, ulp i32) bool

@[inline]
pub fn im_almost_equal(v1 f64, v2 f64, ulp i32) bool {
	return C.ImPlot_ImAlmostEqual(v1, v2, ulp)
}


@[keep_args_alive]
fn C.ImPlot_ImMinArray_FloatPtr(values &f32, count i32) f32

@[inline]
pub fn im_min_array_float_ptr(values &f32, count i32) f32 {
	return C.ImPlot_ImMinArray_FloatPtr(values, count)
}


@[keep_args_alive]
fn C.ImPlot_ImMinArray_doublePtr(values &f64, count i32) f64

@[inline]
pub fn im_min_array_double_ptr(values &f64, count i32) f64 {
	return C.ImPlot_ImMinArray_doublePtr(values, count)
}


@[keep_args_alive]
fn C.ImPlot_ImMinArray_S8Ptr(values &char, count i32) i8

@[inline]
pub fn im_min_array_s8_ptr(values &char, count i32) i8 {
	return C.ImPlot_ImMinArray_S8Ptr(values, count)
}


@[keep_args_alive]
fn C.ImPlot_ImMinArray_U8Ptr(values &u8, count i32) u8

@[inline]
pub fn im_min_array_u8_ptr(values &u8, count i32) u8 {
	return C.ImPlot_ImMinArray_U8Ptr(values, count)
}


@[keep_args_alive]
fn C.ImPlot_ImMinArray_S16Ptr(values &i16, count i32) i16

@[inline]
pub fn im_min_array_s16_ptr(values &i16, count i32) i16 {
	return C.ImPlot_ImMinArray_S16Ptr(values, count)
}


@[keep_args_alive]
fn C.ImPlot_ImMinArray_U16Ptr(values &u16, count i32) u16

@[inline]
pub fn im_min_array_u16_ptr(values &u16, count i32) u16 {
	return C.ImPlot_ImMinArray_U16Ptr(values, count)
}


@[keep_args_alive]
fn C.ImPlot_ImMinArray_S32Ptr(values &i32, count i32) i32

@[inline]
pub fn im_min_array_s32_ptr(values &i32, count i32) i32 {
	return C.ImPlot_ImMinArray_S32Ptr(values, count)
}


@[keep_args_alive]
fn C.ImPlot_ImMinArray_U32Ptr(values &u32, count i32) u32

@[inline]
pub fn im_min_array_u32_ptr(values &u32, count i32) u32 {
	return C.ImPlot_ImMinArray_U32Ptr(values, count)
}


@[keep_args_alive]
fn C.ImPlot_ImMinArray_S64Ptr(values &i64, count i32) i64

@[inline]
pub fn im_min_array_s64_ptr(values &i64, count i32) i64 {
	return C.ImPlot_ImMinArray_S64Ptr(values, count)
}


@[keep_args_alive]
fn C.ImPlot_ImMinArray_U64Ptr(values &u64, count i32) u64

@[inline]
pub fn im_min_array_u64_ptr(values &u64, count i32) u64 {
	return C.ImPlot_ImMinArray_U64Ptr(values, count)
}


@[keep_args_alive]
fn C.ImPlot_ImMaxArray_FloatPtr(values &f32, count i32) f32

@[inline]
pub fn im_max_array_float_ptr(values &f32, count i32) f32 {
	return C.ImPlot_ImMaxArray_FloatPtr(values, count)
}


@[keep_args_alive]
fn C.ImPlot_ImMaxArray_doublePtr(values &f64, count i32) f64

@[inline]
pub fn im_max_array_double_ptr(values &f64, count i32) f64 {
	return C.ImPlot_ImMaxArray_doublePtr(values, count)
}


@[keep_args_alive]
fn C.ImPlot_ImMaxArray_S8Ptr(values &char, count i32) i8

@[inline]
pub fn im_max_array_s8_ptr(values &char, count i32) i8 {
	return C.ImPlot_ImMaxArray_S8Ptr(values, count)
}


@[keep_args_alive]
fn C.ImPlot_ImMaxArray_U8Ptr(values &u8, count i32) u8

@[inline]
pub fn im_max_array_u8_ptr(values &u8, count i32) u8 {
	return C.ImPlot_ImMaxArray_U8Ptr(values, count)
}


@[keep_args_alive]
fn C.ImPlot_ImMaxArray_S16Ptr(values &i16, count i32) i16

@[inline]
pub fn im_max_array_s16_ptr(values &i16, count i32) i16 {
	return C.ImPlot_ImMaxArray_S16Ptr(values, count)
}


@[keep_args_alive]
fn C.ImPlot_ImMaxArray_U16Ptr(values &u16, count i32) u16

@[inline]
pub fn im_max_array_u16_ptr(values &u16, count i32) u16 {
	return C.ImPlot_ImMaxArray_U16Ptr(values, count)
}


@[keep_args_alive]
fn C.ImPlot_ImMaxArray_S32Ptr(values &i32, count i32) i32

@[inline]
pub fn im_max_array_s32_ptr(values &i32, count i32) i32 {
	return C.ImPlot_ImMaxArray_S32Ptr(values, count)
}


@[keep_args_alive]
fn C.ImPlot_ImMaxArray_U32Ptr(values &u32, count i32) u32

@[inline]
pub fn im_max_array_u32_ptr(values &u32, count i32) u32 {
	return C.ImPlot_ImMaxArray_U32Ptr(values, count)
}


@[keep_args_alive]
fn C.ImPlot_ImMaxArray_S64Ptr(values &i64, count i32) i64

@[inline]
pub fn im_max_array_s64_ptr(values &i64, count i32) i64 {
	return C.ImPlot_ImMaxArray_S64Ptr(values, count)
}


@[keep_args_alive]
fn C.ImPlot_ImMaxArray_U64Ptr(values &u64, count i32) u64

@[inline]
pub fn im_max_array_u64_ptr(values &u64, count i32) u64 {
	return C.ImPlot_ImMaxArray_U64Ptr(values, count)
}


@[keep_args_alive]
fn C.ImPlot_ImMinMaxArray_FloatPtr(values &f32, count i32, min_out &f32, max_out &f32)

@[inline]
pub fn im_min_max_array_float_ptr(values &f32, count i32, min_out &f32, max_out &f32) {
	C.ImPlot_ImMinMaxArray_FloatPtr(values, count, min_out, max_out)
}


@[keep_args_alive]
fn C.ImPlot_ImMinMaxArray_doublePtr(values &f64, count i32, min_out &f64, max_out &f64)

@[inline]
pub fn im_min_max_array_double_ptr(values &f64, count i32, min_out &f64, max_out &f64) {
	C.ImPlot_ImMinMaxArray_doublePtr(values, count, min_out, max_out)
}


@[keep_args_alive]
fn C.ImPlot_ImMinMaxArray_S8Ptr(values &char, count i32, min_out &char, max_out &char)

@[inline]
pub fn im_min_max_array_s8_ptr(values &char, count i32, min_out &char, max_out &char) {
	C.ImPlot_ImMinMaxArray_S8Ptr(values, count, min_out, max_out)
}


@[keep_args_alive]
fn C.ImPlot_ImMinMaxArray_U8Ptr(values &u8, count i32, min_out &u8, max_out &u8)

@[inline]
pub fn im_min_max_array_u8_ptr(values &u8, count i32, min_out &u8, max_out &u8) {
	C.ImPlot_ImMinMaxArray_U8Ptr(values, count, min_out, max_out)
}


@[keep_args_alive]
fn C.ImPlot_ImMinMaxArray_S16Ptr(values &i16, count i32, min_out &i16, max_out &i16)

@[inline]
pub fn im_min_max_array_s16_ptr(values &i16, count i32, min_out &i16, max_out &i16) {
	C.ImPlot_ImMinMaxArray_S16Ptr(values, count, min_out, max_out)
}


@[keep_args_alive]
fn C.ImPlot_ImMinMaxArray_U16Ptr(values &u16, count i32, min_out &u16, max_out &u16)

@[inline]
pub fn im_min_max_array_u16_ptr(values &u16, count i32, min_out &u16, max_out &u16) {
	C.ImPlot_ImMinMaxArray_U16Ptr(values, count, min_out, max_out)
}


@[keep_args_alive]
fn C.ImPlot_ImMinMaxArray_S32Ptr(values &i32, count i32, min_out &i32, max_out &i32)

@[inline]
pub fn im_min_max_array_s32_ptr(values &i32, count i32, min_out &i32, max_out &i32) {
	C.ImPlot_ImMinMaxArray_S32Ptr(values, count, min_out, max_out)
}


@[keep_args_alive]
fn C.ImPlot_ImMinMaxArray_U32Ptr(values &u32, count i32, min_out &u32, max_out &u32)

@[inline]
pub fn im_min_max_array_u32_ptr(values &u32, count i32, min_out &u32, max_out &u32) {
	C.ImPlot_ImMinMaxArray_U32Ptr(values, count, min_out, max_out)
}


@[keep_args_alive]
fn C.ImPlot_ImMinMaxArray_S64Ptr(values &i64, count i32, min_out &i64, max_out &i64)

@[inline]
pub fn im_min_max_array_s64_ptr(values &i64, count i32, min_out &i64, max_out &i64) {
	C.ImPlot_ImMinMaxArray_S64Ptr(values, count, min_out, max_out)
}


@[keep_args_alive]
fn C.ImPlot_ImMinMaxArray_U64Ptr(values &u64, count i32, min_out &u64, max_out &u64)

@[inline]
pub fn im_min_max_array_u64_ptr(values &u64, count i32, min_out &u64, max_out &u64) {
	C.ImPlot_ImMinMaxArray_U64Ptr(values, count, min_out, max_out)
}


@[keep_args_alive]
fn C.ImPlot_ImSum_FloatPtr(values &f32, count i32) f32

@[inline]
pub fn im_sum_float_ptr(values &f32, count i32) f32 {
	return C.ImPlot_ImSum_FloatPtr(values, count)
}


@[keep_args_alive]
fn C.ImPlot_ImSum_doublePtr(values &f64, count i32) f64

@[inline]
pub fn im_sum_double_ptr(values &f64, count i32) f64 {
	return C.ImPlot_ImSum_doublePtr(values, count)
}


@[keep_args_alive]
fn C.ImPlot_ImSum_S8Ptr(values &char, count i32) i8

@[inline]
pub fn im_sum_s8_ptr(values &char, count i32) i8 {
	return C.ImPlot_ImSum_S8Ptr(values, count)
}


@[keep_args_alive]
fn C.ImPlot_ImSum_U8Ptr(values &u8, count i32) u8

@[inline]
pub fn im_sum_u8_ptr(values &u8, count i32) u8 {
	return C.ImPlot_ImSum_U8Ptr(values, count)
}


@[keep_args_alive]
fn C.ImPlot_ImSum_S16Ptr(values &i16, count i32) i16

@[inline]
pub fn im_sum_s16_ptr(values &i16, count i32) i16 {
	return C.ImPlot_ImSum_S16Ptr(values, count)
}


@[keep_args_alive]
fn C.ImPlot_ImSum_U16Ptr(values &u16, count i32) u16

@[inline]
pub fn im_sum_u16_ptr(values &u16, count i32) u16 {
	return C.ImPlot_ImSum_U16Ptr(values, count)
}


@[keep_args_alive]
fn C.ImPlot_ImSum_S32Ptr(values &i32, count i32) i32

@[inline]
pub fn im_sum_s32_ptr(values &i32, count i32) i32 {
	return C.ImPlot_ImSum_S32Ptr(values, count)
}


@[keep_args_alive]
fn C.ImPlot_ImSum_U32Ptr(values &u32, count i32) u32

@[inline]
pub fn im_sum_u32_ptr(values &u32, count i32) u32 {
	return C.ImPlot_ImSum_U32Ptr(values, count)
}


@[keep_args_alive]
fn C.ImPlot_ImSum_S64Ptr(values &i64, count i32) i64

@[inline]
pub fn im_sum_s64_ptr(values &i64, count i32) i64 {
	return C.ImPlot_ImSum_S64Ptr(values, count)
}


@[keep_args_alive]
fn C.ImPlot_ImSum_U64Ptr(values &u64, count i32) u64

@[inline]
pub fn im_sum_u64_ptr(values &u64, count i32) u64 {
	return C.ImPlot_ImSum_U64Ptr(values, count)
}


@[keep_args_alive]
fn C.ImPlot_ImMean_FloatPtr(values &f32, count i32) f64

@[inline]
pub fn im_mean_float_ptr(values &f32, count i32) f64 {
	return C.ImPlot_ImMean_FloatPtr(values, count)
}


@[keep_args_alive]
fn C.ImPlot_ImMean_doublePtr(values &f64, count i32) f64

@[inline]
pub fn im_mean_double_ptr(values &f64, count i32) f64 {
	return C.ImPlot_ImMean_doublePtr(values, count)
}


@[keep_args_alive]
fn C.ImPlot_ImMean_S8Ptr(values &char, count i32) f64

@[inline]
pub fn im_mean_s8_ptr(values &char, count i32) f64 {
	return C.ImPlot_ImMean_S8Ptr(values, count)
}


@[keep_args_alive]
fn C.ImPlot_ImMean_U8Ptr(values &u8, count i32) f64

@[inline]
pub fn im_mean_u8_ptr(values &u8, count i32) f64 {
	return C.ImPlot_ImMean_U8Ptr(values, count)
}


@[keep_args_alive]
fn C.ImPlot_ImMean_S16Ptr(values &i16, count i32) f64

@[inline]
pub fn im_mean_s16_ptr(values &i16, count i32) f64 {
	return C.ImPlot_ImMean_S16Ptr(values, count)
}


@[keep_args_alive]
fn C.ImPlot_ImMean_U16Ptr(values &u16, count i32) f64

@[inline]
pub fn im_mean_u16_ptr(values &u16, count i32) f64 {
	return C.ImPlot_ImMean_U16Ptr(values, count)
}


@[keep_args_alive]
fn C.ImPlot_ImMean_S32Ptr(values &i32, count i32) f64

@[inline]
pub fn im_mean_s32_ptr(values &i32, count i32) f64 {
	return C.ImPlot_ImMean_S32Ptr(values, count)
}


@[keep_args_alive]
fn C.ImPlot_ImMean_U32Ptr(values &u32, count i32) f64

@[inline]
pub fn im_mean_u32_ptr(values &u32, count i32) f64 {
	return C.ImPlot_ImMean_U32Ptr(values, count)
}


@[keep_args_alive]
fn C.ImPlot_ImMean_S64Ptr(values &i64, count i32) f64

@[inline]
pub fn im_mean_s64_ptr(values &i64, count i32) f64 {
	return C.ImPlot_ImMean_S64Ptr(values, count)
}


@[keep_args_alive]
fn C.ImPlot_ImMean_U64Ptr(values &u64, count i32) f64

@[inline]
pub fn im_mean_u64_ptr(values &u64, count i32) f64 {
	return C.ImPlot_ImMean_U64Ptr(values, count)
}


@[keep_args_alive]
fn C.ImPlot_ImStdDev_FloatPtr(values &f32, count i32) f64

@[inline]
pub fn im_std_dev_float_ptr(values &f32, count i32) f64 {
	return C.ImPlot_ImStdDev_FloatPtr(values, count)
}


@[keep_args_alive]
fn C.ImPlot_ImStdDev_doublePtr(values &f64, count i32) f64

@[inline]
pub fn im_std_dev_double_ptr(values &f64, count i32) f64 {
	return C.ImPlot_ImStdDev_doublePtr(values, count)
}


@[keep_args_alive]
fn C.ImPlot_ImStdDev_S8Ptr(values &char, count i32) f64

@[inline]
pub fn im_std_dev_s8_ptr(values &char, count i32) f64 {
	return C.ImPlot_ImStdDev_S8Ptr(values, count)
}


@[keep_args_alive]
fn C.ImPlot_ImStdDev_U8Ptr(values &u8, count i32) f64

@[inline]
pub fn im_std_dev_u8_ptr(values &u8, count i32) f64 {
	return C.ImPlot_ImStdDev_U8Ptr(values, count)
}


@[keep_args_alive]
fn C.ImPlot_ImStdDev_S16Ptr(values &i16, count i32) f64

@[inline]
pub fn im_std_dev_s16_ptr(values &i16, count i32) f64 {
	return C.ImPlot_ImStdDev_S16Ptr(values, count)
}


@[keep_args_alive]
fn C.ImPlot_ImStdDev_U16Ptr(values &u16, count i32) f64

@[inline]
pub fn im_std_dev_u16_ptr(values &u16, count i32) f64 {
	return C.ImPlot_ImStdDev_U16Ptr(values, count)
}


@[keep_args_alive]
fn C.ImPlot_ImStdDev_S32Ptr(values &i32, count i32) f64

@[inline]
pub fn im_std_dev_s32_ptr(values &i32, count i32) f64 {
	return C.ImPlot_ImStdDev_S32Ptr(values, count)
}


@[keep_args_alive]
fn C.ImPlot_ImStdDev_U32Ptr(values &u32, count i32) f64

@[inline]
pub fn im_std_dev_u32_ptr(values &u32, count i32) f64 {
	return C.ImPlot_ImStdDev_U32Ptr(values, count)
}


@[keep_args_alive]
fn C.ImPlot_ImStdDev_S64Ptr(values &i64, count i32) f64

@[inline]
pub fn im_std_dev_s64_ptr(values &i64, count i32) f64 {
	return C.ImPlot_ImStdDev_S64Ptr(values, count)
}


@[keep_args_alive]
fn C.ImPlot_ImStdDev_U64Ptr(values &u64, count i32) f64

@[inline]
pub fn im_std_dev_u64_ptr(values &u64, count i32) f64 {
	return C.ImPlot_ImStdDev_U64Ptr(values, count)
}


@[keep_args_alive]
fn C.ImPlot_ImMixU32(a u32, b u32, s u32) u32

@[inline]
pub fn im_mix_u32(a u32, b u32, s u32) u32 {
	return C.ImPlot_ImMixU32(a, b, s)
}


@[keep_args_alive]
fn C.ImPlot_ImLerpU32(colors &u32, size i32, t f32) u32

@[inline]
pub fn im_lerp_u32(colors &u32, size i32, t f32) u32 {
	return C.ImPlot_ImLerpU32(colors, size, t)
}


@[keep_args_alive]
fn C.ImPlot_ImAlphaU32(col u32, alpha f32) u32

@[inline]
pub fn im_alpha_u32(col u32, alpha f32) u32 {
	return C.ImPlot_ImAlphaU32(col, alpha)
}


@[keep_args_alive]
fn C.ImPlot_ImOverlaps_Float(min_a f32, max_a f32, min_b f32, max_b f32) bool

@[inline]
pub fn im_overlaps_float(min_a f32, max_a f32, min_b f32, max_b f32) bool {
	return C.ImPlot_ImOverlaps_Float(min_a, max_a, min_b, max_b)
}


@[keep_args_alive]
fn C.ImPlot_ImOverlaps_double(min_a f64, max_a f64, min_b f64, max_b f64) bool

@[inline]
pub fn im_overlaps_double(min_a f64, max_a f64, min_b f64, max_b f64) bool {
	return C.ImPlot_ImOverlaps_double(min_a, max_a, min_b, max_b)
}


@[keep_args_alive]
fn C.ImPlot_ImOverlaps_S8(min_a i8, max_a i8, min_b i8, max_b i8) bool

@[inline]
pub fn im_overlaps_s8(min_a i8, max_a i8, min_b i8, max_b i8) bool {
	return C.ImPlot_ImOverlaps_S8(min_a, max_a, min_b, max_b)
}


@[keep_args_alive]
fn C.ImPlot_ImOverlaps_U8(min_a u8, max_a u8, min_b u8, max_b u8) bool

@[inline]
pub fn im_overlaps_u8(min_a u8, max_a u8, min_b u8, max_b u8) bool {
	return C.ImPlot_ImOverlaps_U8(min_a, max_a, min_b, max_b)
}


@[keep_args_alive]
fn C.ImPlot_ImOverlaps_S16(min_a i16, max_a i16, min_b i16, max_b i16) bool

@[inline]
pub fn im_overlaps_s16(min_a i16, max_a i16, min_b i16, max_b i16) bool {
	return C.ImPlot_ImOverlaps_S16(min_a, max_a, min_b, max_b)
}


@[keep_args_alive]
fn C.ImPlot_ImOverlaps_U16(min_a u16, max_a u16, min_b u16, max_b u16) bool

@[inline]
pub fn im_overlaps_u16(min_a u16, max_a u16, min_b u16, max_b u16) bool {
	return C.ImPlot_ImOverlaps_U16(min_a, max_a, min_b, max_b)
}


@[keep_args_alive]
fn C.ImPlot_ImOverlaps_S32(min_a i32, max_a i32, min_b i32, max_b i32) bool

@[inline]
pub fn im_overlaps_s32(min_a i32, max_a i32, min_b i32, max_b i32) bool {
	return C.ImPlot_ImOverlaps_S32(min_a, max_a, min_b, max_b)
}


@[keep_args_alive]
fn C.ImPlot_ImOverlaps_U32(min_a u32, max_a u32, min_b u32, max_b u32) bool

@[inline]
pub fn im_overlaps_u32(min_a u32, max_a u32, min_b u32, max_b u32) bool {
	return C.ImPlot_ImOverlaps_U32(min_a, max_a, min_b, max_b)
}


@[keep_args_alive]
fn C.ImPlot_ImOverlaps_S64(min_a i64, max_a i64, min_b i64, max_b i64) bool

@[inline]
pub fn im_overlaps_s64(min_a i64, max_a i64, min_b i64, max_b i64) bool {
	return C.ImPlot_ImOverlaps_S64(min_a, max_a, min_b, max_b)
}


@[keep_args_alive]
fn C.ImPlot_ImOverlaps_U64(min_a u64, max_a u64, min_b u64, max_b u64) bool

@[inline]
pub fn im_overlaps_u64(min_a u64, max_a u64, min_b u64, max_b u64) bool {
	return C.ImPlot_ImOverlaps_U64(min_a, max_a, min_b, max_b)
}


@[keep_args_alive]
fn C.ImPlotDateTimeSpec_ImPlotDateTimeSpec_Nil() &DateTimeSpec

@[inline]
pub fn date_time_spec_date_time_spec_nil() &DateTimeSpec {
	return C.ImPlotDateTimeSpec_ImPlotDateTimeSpec_Nil()
}


@[keep_args_alive]
fn C.ImPlotDateTimeSpec_destroy(self &DateTimeSpec)

@[inline]
pub fn date_time_spec_destroy(self &DateTimeSpec) {
	C.ImPlotDateTimeSpec_destroy(self)
}


@[keep_args_alive]
fn C.ImPlotDateTimeSpec_ImPlotDateTimeSpec_PlotDateFmt(date_fmt DateFmt, time_fmt TimeFmt, use_24_hr_clk bool, use_iso_8601 bool) &DateTimeSpec

@[inline]
pub fn date_time_spec_date_time_spec_plot_date_fmt(date_fmt DateFmt, time_fmt TimeFmt, use_24_hr_clk bool, use_iso_8601 bool) &DateTimeSpec {
	return C.ImPlotDateTimeSpec_ImPlotDateTimeSpec_PlotDateFmt(date_fmt, time_fmt, use_24_hr_clk, use_iso_8601)
}


@[keep_args_alive]
fn C.ImPlotTime_ImPlotTime_Nil() &Time

@[inline]
pub fn time_time_nil() &Time {
	return C.ImPlotTime_ImPlotTime_Nil()
}


@[keep_args_alive]
fn C.ImPlotTime_destroy(self &Time)

@[inline]
pub fn time_destroy(self &Time) {
	C.ImPlotTime_destroy(self)
}


@[keep_args_alive]
fn C.ImPlotTime_ImPlotTime_time_t(s i64, us i32) &Time

@[inline]
pub fn time_time_time_t(s i64, us i32) &Time {
	return C.ImPlotTime_ImPlotTime_time_t(s, us)
}


@[keep_args_alive]
fn C.ImPlotTime_RollOver(self &Time)

@[inline]
pub fn time_roll_over(self &Time) {
	C.ImPlotTime_RollOver(self)
}


@[keep_args_alive]
fn C.ImPlotTime_ToDouble(self &Time) f64

@[inline]
pub fn time_to_double(self &Time) f64 {
	return C.ImPlotTime_ToDouble(self)
}


@[keep_args_alive]
fn C.ImPlotTime_FromDouble(t f64) Time_c

@[inline]
pub fn time_from_double(t f64) Time_c {
	return C.ImPlotTime_FromDouble(t)
}


@[keep_args_alive]
fn C.ImPlotColormapData_ImPlotColormapData() &ColormapData

@[inline]
pub fn colormap_data_colormap_data() &ColormapData {
	return C.ImPlotColormapData_ImPlotColormapData()
}


@[keep_args_alive]
fn C.ImPlotColormapData_destroy(self &ColormapData)

@[inline]
pub fn colormap_data_destroy(self &ColormapData) {
	C.ImPlotColormapData_destroy(self)
}


@[keep_args_alive]
fn C.ImPlotColormapData_Append(self &ColormapData, const_name &char, keys &u32, count i32, qual bool) i32

@[inline]
pub fn colormap_data_append(self &ColormapData, const_name &char, keys &u32, count i32, qual bool) i32 {
	return C.ImPlotColormapData_Append(self, const_name, keys, count, qual)
}


@[keep_args_alive]
fn C.ImPlotColormapData__AppendTable(self &ColormapData, cmap Colormap)

@[inline]
pub fn colormap_data__append_table(self &ColormapData, cmap Colormap) {
	C.ImPlotColormapData__AppendTable(self, cmap)
}


@[keep_args_alive]
fn C.ImPlotColormapData_RebuildTables(self &ColormapData)

@[inline]
pub fn colormap_data_rebuild_tables(self &ColormapData) {
	C.ImPlotColormapData_RebuildTables(self)
}


@[keep_args_alive]
fn C.ImPlotColormapData_IsQual(self &ColormapData, cmap Colormap) bool

@[inline]
pub fn colormap_data_is_qual(self &ColormapData, cmap Colormap) bool {
	return C.ImPlotColormapData_IsQual(self, cmap)
}


@[keep_args_alive]
fn C.ImPlotColormapData_GetName(self &ColormapData, cmap Colormap) &char

@[inline]
pub fn colormap_data_get_name(self &ColormapData, cmap Colormap) &char {
	return C.ImPlotColormapData_GetName(self, cmap)
}


@[keep_args_alive]
fn C.ImPlotColormapData_GetIndex(self &ColormapData, const_name &char) Colormap

@[inline]
pub fn colormap_data_get_index(self &ColormapData, const_name &char) Colormap {
	return C.ImPlotColormapData_GetIndex(self, const_name)
}


@[keep_args_alive]
fn C.ImPlotColormapData_GetKeys(self &ColormapData, cmap Colormap) &u32

@[inline]
pub fn colormap_data_get_keys(self &ColormapData, cmap Colormap) &u32 {
	return C.ImPlotColormapData_GetKeys(self, cmap)
}


@[keep_args_alive]
fn C.ImPlotColormapData_GetKeyCount(self &ColormapData, cmap Colormap) i32

@[inline]
pub fn colormap_data_get_key_count(self &ColormapData, cmap Colormap) i32 {
	return C.ImPlotColormapData_GetKeyCount(self, cmap)
}


@[keep_args_alive]
fn C.ImPlotColormapData_GetKeyColor(self &ColormapData, cmap Colormap, idx i32) u32

@[inline]
pub fn colormap_data_get_key_color(self &ColormapData, cmap Colormap, idx i32) u32 {
	return C.ImPlotColormapData_GetKeyColor(self, cmap, idx)
}


@[keep_args_alive]
fn C.ImPlotColormapData_SetKeyColor(self &ColormapData, cmap Colormap, idx i32, value u32)

@[inline]
pub fn colormap_data_set_key_color(self &ColormapData, cmap Colormap, idx i32, value u32) {
	C.ImPlotColormapData_SetKeyColor(self, cmap, idx, value)
}


@[keep_args_alive]
fn C.ImPlotColormapData_GetTable(self &ColormapData, cmap Colormap) &u32

@[inline]
pub fn colormap_data_get_table(self &ColormapData, cmap Colormap) &u32 {
	return C.ImPlotColormapData_GetTable(self, cmap)
}


@[keep_args_alive]
fn C.ImPlotColormapData_GetTableSize(self &ColormapData, cmap Colormap) i32

@[inline]
pub fn colormap_data_get_table_size(self &ColormapData, cmap Colormap) i32 {
	return C.ImPlotColormapData_GetTableSize(self, cmap)
}


@[keep_args_alive]
fn C.ImPlotColormapData_GetTableColor(self &ColormapData, cmap Colormap, idx i32) u32

@[inline]
pub fn colormap_data_get_table_color(self &ColormapData, cmap Colormap, idx i32) u32 {
	return C.ImPlotColormapData_GetTableColor(self, cmap, idx)
}


@[keep_args_alive]
fn C.ImPlotColormapData_LerpTable(self &ColormapData, cmap Colormap, t f32) u32

@[inline]
pub fn colormap_data_lerp_table(self &ColormapData, cmap Colormap, t f32) u32 {
	return C.ImPlotColormapData_LerpTable(self, cmap, t)
}


@[keep_args_alive]
fn C.ImPlotPointError_ImPlotPointError_Nil() &PointError

@[inline]
pub fn point_error_point_error_nil() &PointError {
	return C.ImPlotPointError_ImPlotPointError_Nil()
}


@[keep_args_alive]
fn C.ImPlotPointError_destroy(self &PointError)

@[inline]
pub fn point_error_destroy(self &PointError) {
	C.ImPlotPointError_destroy(self)
}


@[keep_args_alive]
fn C.ImPlotPointError_ImPlotPointError_double(x f64, y f64, neg f64, pos f64) &PointError

@[inline]
pub fn point_error_point_error_double(x f64, y f64, neg f64, pos f64) &PointError {
	return C.ImPlotPointError_ImPlotPointError_double(x, y, neg, pos)
}


@[keep_args_alive]
fn C.ImPlotAnnotation_ImPlotAnnotation() &Annotation

@[inline]
pub fn annotation_annotation() &Annotation {
	return C.ImPlotAnnotation_ImPlotAnnotation()
}


@[keep_args_alive]
fn C.ImPlotAnnotation_destroy(self &Annotation)

@[inline]
pub fn annotation_destroy(self &Annotation) {
	C.ImPlotAnnotation_destroy(self)
}


@[keep_args_alive]
fn C.ImPlotAnnotationCollection_ImPlotAnnotationCollection() &AnnotationCollection

@[inline]
pub fn annotation_collection_annotation_collection() &AnnotationCollection {
	return C.ImPlotAnnotationCollection_ImPlotAnnotationCollection()
}


@[keep_args_alive]
fn C.ImPlotAnnotationCollection_destroy(self &AnnotationCollection)

@[inline]
pub fn annotation_collection_destroy(self &AnnotationCollection) {
	C.ImPlotAnnotationCollection_destroy(self)
}


@[keep_args_alive]
fn C.ImPlotAnnotationCollection_AppendV(self &AnnotationCollection, pos ImVec2_c, off ImVec2_c, bg u32, fg u32, clamp bool, const_fmt &char, args Va_list)

@[inline]
pub fn annotation_collection_append_v(self &AnnotationCollection, pos ImVec2_c, off ImVec2_c, bg u32, fg u32, clamp bool, const_fmt &char, args Va_list) {
	C.ImPlotAnnotationCollection_AppendV(self, pos, off, bg, fg, clamp, const_fmt, args)
}


@[keep_args_alive]
fn C.ImPlotAnnotationCollection_Append(self &AnnotationCollection, pos ImVec2_c, off ImVec2_c, bg u32, fg u32, clamp bool, const_fmt &char)

@[inline]
pub fn annotation_collection_append(self &AnnotationCollection, pos ImVec2_c, off ImVec2_c, bg u32, fg u32, clamp bool, const_fmt &char) {
	C.ImPlotAnnotationCollection_Append(self, pos, off, bg, fg, clamp, const_fmt)
}


@[keep_args_alive]
fn C.ImPlotAnnotationCollection_GetText(self &AnnotationCollection, idx i32) &char

@[inline]
pub fn annotation_collection_get_text(self &AnnotationCollection, idx i32) &char {
	return C.ImPlotAnnotationCollection_GetText(self, idx)
}


@[keep_args_alive]
fn C.ImPlotAnnotationCollection_Reset(self &AnnotationCollection)

@[inline]
pub fn annotation_collection_reset(self &AnnotationCollection) {
	C.ImPlotAnnotationCollection_Reset(self)
}


@[keep_args_alive]
fn C.ImPlotTag_ImPlotTag() &Tag

@[inline]
pub fn tag_tag() &Tag {
	return C.ImPlotTag_ImPlotTag()
}


@[keep_args_alive]
fn C.ImPlotTag_destroy(self &Tag)

@[inline]
pub fn tag_destroy(self &Tag) {
	C.ImPlotTag_destroy(self)
}


@[keep_args_alive]
fn C.ImPlotTagCollection_ImPlotTagCollection() &TagCollection

@[inline]
pub fn tag_collection_tag_collection() &TagCollection {
	return C.ImPlotTagCollection_ImPlotTagCollection()
}


@[keep_args_alive]
fn C.ImPlotTagCollection_destroy(self &TagCollection)

@[inline]
pub fn tag_collection_destroy(self &TagCollection) {
	C.ImPlotTagCollection_destroy(self)
}


@[keep_args_alive]
fn C.ImPlotTagCollection_AppendV(self &TagCollection, axis ImAxis, value f64, bg u32, fg u32, const_fmt &char, args Va_list)

@[inline]
pub fn tag_collection_append_v(self &TagCollection, axis ImAxis, value f64, bg u32, fg u32, const_fmt &char, args Va_list) {
	C.ImPlotTagCollection_AppendV(self, axis, value, bg, fg, const_fmt, args)
}


@[keep_args_alive]
fn C.ImPlotTagCollection_Append(self &TagCollection, axis ImAxis, value f64, bg u32, fg u32, const_fmt &char)

@[inline]
pub fn tag_collection_append(self &TagCollection, axis ImAxis, value f64, bg u32, fg u32, const_fmt &char) {
	C.ImPlotTagCollection_Append(self, axis, value, bg, fg, const_fmt)
}


@[keep_args_alive]
fn C.ImPlotTagCollection_GetText(self &TagCollection, idx i32) &char

@[inline]
pub fn tag_collection_get_text(self &TagCollection, idx i32) &char {
	return C.ImPlotTagCollection_GetText(self, idx)
}


@[keep_args_alive]
fn C.ImPlotTagCollection_Reset(self &TagCollection)

@[inline]
pub fn tag_collection_reset(self &TagCollection) {
	C.ImPlotTagCollection_Reset(self)
}


@[keep_args_alive]
fn C.ImPlotTick_ImPlotTick_Nil() &Tick

@[inline]
pub fn tick_tick_nil() &Tick {
	return C.ImPlotTick_ImPlotTick_Nil()
}


@[keep_args_alive]
fn C.ImPlotTick_destroy(self &Tick)

@[inline]
pub fn tick_destroy(self &Tick) {
	C.ImPlotTick_destroy(self)
}


@[keep_args_alive]
fn C.ImPlotTick_ImPlotTick_double(value f64, major bool, level i32, show_label bool) &Tick

@[inline]
pub fn tick_tick_double(value f64, major bool, level i32, show_label bool) &Tick {
	return C.ImPlotTick_ImPlotTick_double(value, major, level, show_label)
}


@[keep_args_alive]
fn C.ImPlotTicker_ImPlotTicker() &Ticker

@[inline]
pub fn ticker_ticker() &Ticker {
	return C.ImPlotTicker_ImPlotTicker()
}


@[keep_args_alive]
fn C.ImPlotTicker_destroy(self &Ticker)

@[inline]
pub fn ticker_destroy(self &Ticker) {
	C.ImPlotTicker_destroy(self)
}


@[keep_args_alive]
fn C.ImPlotTicker_AddTick_doubleStr(self &Ticker, value f64, major bool, level i32, show_label bool, const_label &char) &Tick

@[inline]
pub fn ticker_add_tick_double_str(self &Ticker, value f64, major bool, level i32, show_label bool, const_label &char) &Tick {
	return C.ImPlotTicker_AddTick_doubleStr(self, value, major, level, show_label, const_label)
}


@[keep_args_alive]
fn C.ImPlotTicker_AddTick_doublePlotFormatter(self &Ticker, value f64, major bool, level i32, show_label bool, formatter Formatter, data voidptr) &Tick

@[inline]
pub fn ticker_add_tick_double_plot_formatter(self &Ticker, value f64, major bool, level i32, show_label bool, formatter Formatter, data voidptr) &Tick {
	return C.ImPlotTicker_AddTick_doublePlotFormatter(self, value, major, level, show_label, formatter, data)
}


@[keep_args_alive]
fn C.ImPlotTicker_AddTick_PlotTick(self &Ticker, tick Tick_c) &Tick

@[inline]
pub fn ticker_add_tick_plot_tick(self &Ticker, tick Tick_c) &Tick {
	return C.ImPlotTicker_AddTick_PlotTick(self, tick)
}


@[keep_args_alive]
fn C.ImPlotTicker_GetText_Int(self &Ticker, idx i32) &char

@[inline]
pub fn ticker_get_text_int(self &Ticker, idx i32) &char {
	return C.ImPlotTicker_GetText_Int(self, idx)
}


@[keep_args_alive]
fn C.ImPlotTicker_GetText_PlotTick(self &Ticker, tick Tick_c) &char

@[inline]
pub fn ticker_get_text_plot_tick(self &Ticker, tick Tick_c) &char {
	return C.ImPlotTicker_GetText_PlotTick(self, tick)
}


@[keep_args_alive]
fn C.ImPlotTicker_OverrideSizeLate(self &Ticker, size ImVec2_c)

@[inline]
pub fn ticker_override_size_late(self &Ticker, size ImVec2_c) {
	C.ImPlotTicker_OverrideSizeLate(self, size)
}


@[keep_args_alive]
fn C.ImPlotTicker_Reset(self &Ticker)

@[inline]
pub fn ticker_reset(self &Ticker) {
	C.ImPlotTicker_Reset(self)
}


@[keep_args_alive]
fn C.ImPlotTicker_TickCount(self &Ticker) i32

@[inline]
pub fn ticker_tick_count(self &Ticker) i32 {
	return C.ImPlotTicker_TickCount(self)
}


@[keep_args_alive]
fn C.ImPlotAxis_ImPlotAxis() &Axis

@[inline]
pub fn axis_axis() &Axis {
	return C.ImPlotAxis_ImPlotAxis()
}


@[keep_args_alive]
fn C.ImPlotAxis_destroy(self &Axis)

@[inline]
pub fn axis_destroy(self &Axis) {
	C.ImPlotAxis_destroy(self)
}


@[keep_args_alive]
fn C.ImPlotAxis_Reset(self &Axis)

@[inline]
pub fn axis_reset(self &Axis) {
	C.ImPlotAxis_Reset(self)
}


@[keep_args_alive]
fn C.ImPlotAxis_SetMin(self &Axis, _min f64, force bool) bool

@[inline]
pub fn axis_set_min(self &Axis, _min f64, force bool) bool {
	return C.ImPlotAxis_SetMin(self, _min, force)
}


@[keep_args_alive]
fn C.ImPlotAxis_SetMax(self &Axis, _max f64, force bool) bool

@[inline]
pub fn axis_set_max(self &Axis, _max f64, force bool) bool {
	return C.ImPlotAxis_SetMax(self, _max, force)
}


@[keep_args_alive]
fn C.ImPlotAxis_SetRange_double(self &Axis, v1 f64, v2 f64)

@[inline]
pub fn axis_set_range_double(self &Axis, v1 f64, v2 f64) {
	C.ImPlotAxis_SetRange_double(self, v1, v2)
}


@[keep_args_alive]
fn C.ImPlotAxis_SetRange_PlotRange(self &Axis, range Range_c)

@[inline]
pub fn axis_set_range_plot_range(self &Axis, range Range_c) {
	C.ImPlotAxis_SetRange_PlotRange(self, range)
}


@[keep_args_alive]
fn C.ImPlotAxis_SetAspect(self &Axis, unit_per_pix f64)

@[inline]
pub fn axis_set_aspect(self &Axis, unit_per_pix f64) {
	C.ImPlotAxis_SetAspect(self, unit_per_pix)
}


@[keep_args_alive]
fn C.ImPlotAxis_PixelSize(self &Axis) f32

@[inline]
pub fn axis_pixel_size(self &Axis) f32 {
	return C.ImPlotAxis_PixelSize(self)
}


@[keep_args_alive]
fn C.ImPlotAxis_GetAspect(self &Axis) f64

@[inline]
pub fn axis_get_aspect(self &Axis) f64 {
	return C.ImPlotAxis_GetAspect(self)
}


@[keep_args_alive]
fn C.ImPlotAxis_Constrain(self &Axis)

@[inline]
pub fn axis_constrain(self &Axis) {
	C.ImPlotAxis_Constrain(self)
}


@[keep_args_alive]
fn C.ImPlotAxis_UpdateTransformCache(self &Axis)

@[inline]
pub fn axis_update_transform_cache(self &Axis) {
	C.ImPlotAxis_UpdateTransformCache(self)
}


@[keep_args_alive]
fn C.ImPlotAxis_PlotToPixels(self &Axis, plt f64) f32

@[inline]
pub fn axis_plot_to_pixels(self &Axis, plt f64) f32 {
	return C.ImPlotAxis_PlotToPixels(self, plt)
}


@[keep_args_alive]
fn C.ImPlotAxis_PixelsToPlot(self &Axis, pix f32) f64

@[inline]
pub fn axis_pixels_to_plot(self &Axis, pix f32) f64 {
	return C.ImPlotAxis_PixelsToPlot(self, pix)
}


@[keep_args_alive]
fn C.ImPlotAxis_ExtendFit(self &Axis, v f64)

@[inline]
pub fn axis_extend_fit(self &Axis, v f64) {
	C.ImPlotAxis_ExtendFit(self, v)
}


@[keep_args_alive]
fn C.ImPlotAxis_ExtendFitWith(self &Axis, alt &Axis, v f64, v_alt f64)

@[inline]
pub fn axis_extend_fit_with(self &Axis, alt &Axis, v f64, v_alt f64) {
	C.ImPlotAxis_ExtendFitWith(self, alt, v, v_alt)
}


@[keep_args_alive]
fn C.ImPlotAxis_ApplyFit(self &Axis, padding f32)

@[inline]
pub fn axis_apply_fit(self &Axis, padding f32) {
	C.ImPlotAxis_ApplyFit(self, padding)
}


@[keep_args_alive]
fn C.ImPlotAxis_HasLabel(self &Axis) bool

@[inline]
pub fn axis_has_label(self &Axis) bool {
	return C.ImPlotAxis_HasLabel(self)
}


@[keep_args_alive]
fn C.ImPlotAxis_HasGridLines(self &Axis) bool

@[inline]
pub fn axis_has_grid_lines(self &Axis) bool {
	return C.ImPlotAxis_HasGridLines(self)
}


@[keep_args_alive]
fn C.ImPlotAxis_HasTickLabels(self &Axis) bool

@[inline]
pub fn axis_has_tick_labels(self &Axis) bool {
	return C.ImPlotAxis_HasTickLabels(self)
}


@[keep_args_alive]
fn C.ImPlotAxis_HasTickMarks(self &Axis) bool

@[inline]
pub fn axis_has_tick_marks(self &Axis) bool {
	return C.ImPlotAxis_HasTickMarks(self)
}


@[keep_args_alive]
fn C.ImPlotAxis_WillRender(self &Axis) bool

@[inline]
pub fn axis_will_render(self &Axis) bool {
	return C.ImPlotAxis_WillRender(self)
}


@[keep_args_alive]
fn C.ImPlotAxis_IsOpposite(self &Axis) bool

@[inline]
pub fn axis_is_opposite(self &Axis) bool {
	return C.ImPlotAxis_IsOpposite(self)
}


@[keep_args_alive]
fn C.ImPlotAxis_IsInverted(self &Axis) bool

@[inline]
pub fn axis_is_inverted(self &Axis) bool {
	return C.ImPlotAxis_IsInverted(self)
}


@[keep_args_alive]
fn C.ImPlotAxis_IsForeground(self &Axis) bool

@[inline]
pub fn axis_is_foreground(self &Axis) bool {
	return C.ImPlotAxis_IsForeground(self)
}


@[keep_args_alive]
fn C.ImPlotAxis_IsAutoFitting(self &Axis) bool

@[inline]
pub fn axis_is_auto_fitting(self &Axis) bool {
	return C.ImPlotAxis_IsAutoFitting(self)
}


@[keep_args_alive]
fn C.ImPlotAxis_CanInitFit(self &Axis) bool

@[inline]
pub fn axis_can_init_fit(self &Axis) bool {
	return C.ImPlotAxis_CanInitFit(self)
}


@[keep_args_alive]
fn C.ImPlotAxis_IsRangeLocked(self &Axis) bool

@[inline]
pub fn axis_is_range_locked(self &Axis) bool {
	return C.ImPlotAxis_IsRangeLocked(self)
}


@[keep_args_alive]
fn C.ImPlotAxis_IsLockedMin(self &Axis) bool

@[inline]
pub fn axis_is_locked_min(self &Axis) bool {
	return C.ImPlotAxis_IsLockedMin(self)
}


@[keep_args_alive]
fn C.ImPlotAxis_IsLockedMax(self &Axis) bool

@[inline]
pub fn axis_is_locked_max(self &Axis) bool {
	return C.ImPlotAxis_IsLockedMax(self)
}


@[keep_args_alive]
fn C.ImPlotAxis_IsLocked(self &Axis) bool

@[inline]
pub fn axis_is_locked(self &Axis) bool {
	return C.ImPlotAxis_IsLocked(self)
}


@[keep_args_alive]
fn C.ImPlotAxis_IsInputLockedMin(self &Axis) bool

@[inline]
pub fn axis_is_input_locked_min(self &Axis) bool {
	return C.ImPlotAxis_IsInputLockedMin(self)
}


@[keep_args_alive]
fn C.ImPlotAxis_IsInputLockedMax(self &Axis) bool

@[inline]
pub fn axis_is_input_locked_max(self &Axis) bool {
	return C.ImPlotAxis_IsInputLockedMax(self)
}


@[keep_args_alive]
fn C.ImPlotAxis_IsInputLocked(self &Axis) bool

@[inline]
pub fn axis_is_input_locked(self &Axis) bool {
	return C.ImPlotAxis_IsInputLocked(self)
}


@[keep_args_alive]
fn C.ImPlotAxis_HasMenus(self &Axis) bool

@[inline]
pub fn axis_has_menus(self &Axis) bool {
	return C.ImPlotAxis_HasMenus(self)
}


@[keep_args_alive]
fn C.ImPlotAxis_IsPanLocked(self &Axis, increasing bool) bool

@[inline]
pub fn axis_is_pan_locked(self &Axis, increasing bool) bool {
	return C.ImPlotAxis_IsPanLocked(self, increasing)
}


@[keep_args_alive]
fn C.ImPlotAxis_PushLinks(self &Axis)

@[inline]
pub fn axis_push_links(self &Axis) {
	C.ImPlotAxis_PushLinks(self)
}


@[keep_args_alive]
fn C.ImPlotAxis_PullLinks(self &Axis)

@[inline]
pub fn axis_pull_links(self &Axis) {
	C.ImPlotAxis_PullLinks(self)
}


@[keep_args_alive]
fn C.ImPlotAlignmentData_ImPlotAlignmentData() &AlignmentData

@[inline]
pub fn alignment_data_alignment_data() &AlignmentData {
	return C.ImPlotAlignmentData_ImPlotAlignmentData()
}


@[keep_args_alive]
fn C.ImPlotAlignmentData_destroy(self &AlignmentData)

@[inline]
pub fn alignment_data_destroy(self &AlignmentData) {
	C.ImPlotAlignmentData_destroy(self)
}


@[keep_args_alive]
fn C.ImPlotAlignmentData_Begin(self &AlignmentData)

@[inline]
pub fn alignment_data_begin(self &AlignmentData) {
	C.ImPlotAlignmentData_Begin(self)
}


@[keep_args_alive]
fn C.ImPlotAlignmentData_Update(self &AlignmentData, pad_a &f32, pad_b &f32, delta_a &f32, delta_b &f32)

@[inline]
pub fn alignment_data_update(self &AlignmentData, pad_a &f32, pad_b &f32, delta_a &f32, delta_b &f32) {
	C.ImPlotAlignmentData_Update(self, pad_a, pad_b, delta_a, delta_b)
}


@[keep_args_alive]
fn C.ImPlotAlignmentData_End(self &AlignmentData)

@[inline]
pub fn alignment_data_end(self &AlignmentData) {
	C.ImPlotAlignmentData_End(self)
}


@[keep_args_alive]
fn C.ImPlotAlignmentData_Reset(self &AlignmentData)

@[inline]
pub fn alignment_data_reset(self &AlignmentData) {
	C.ImPlotAlignmentData_Reset(self)
}


@[keep_args_alive]
fn C.ImPlotItem_ImPlotItem() &Item

@[inline]
pub fn item_item() &Item {
	return C.ImPlotItem_ImPlotItem()
}


@[keep_args_alive]
fn C.ImPlotItem_destroy(self &Item)

@[inline]
pub fn item_destroy(self &Item) {
	C.ImPlotItem_destroy(self)
}


@[keep_args_alive]
fn C.ImPlotLegend_ImPlotLegend() &Legend

@[inline]
pub fn legend_legend() &Legend {
	return C.ImPlotLegend_ImPlotLegend()
}


@[keep_args_alive]
fn C.ImPlotLegend_destroy(self &Legend)

@[inline]
pub fn legend_destroy(self &Legend) {
	C.ImPlotLegend_destroy(self)
}


@[keep_args_alive]
fn C.ImPlotLegend_Reset(self &Legend)

@[inline]
pub fn legend_reset(self &Legend) {
	C.ImPlotLegend_Reset(self)
}


@[keep_args_alive]
fn C.ImPlotItemGroup_ImPlotItemGroup() &ItemGroup

@[inline]
pub fn item_group_item_group() &ItemGroup {
	return C.ImPlotItemGroup_ImPlotItemGroup()
}


@[keep_args_alive]
fn C.ImPlotItemGroup_destroy(self &ItemGroup)

@[inline]
pub fn item_group_destroy(self &ItemGroup) {
	C.ImPlotItemGroup_destroy(self)
}


@[keep_args_alive]
fn C.ImPlotItemGroup_GetItemCount(self &ItemGroup) i32

@[inline]
pub fn item_group_get_item_count(self &ItemGroup) i32 {
	return C.ImPlotItemGroup_GetItemCount(self)
}


@[keep_args_alive]
fn C.ImPlotItemGroup_GetItemID(self &ItemGroup, label_id &char) imgui.ID

@[inline]
pub fn item_group_get_item_id(self &ItemGroup, label_id &char) imgui.ID {
	return C.ImPlotItemGroup_GetItemID(self, label_id)
}


@[keep_args_alive]
fn C.ImPlotItemGroup_GetItem_ID(self &ItemGroup, id imgui.ID) &Item

@[inline]
pub fn item_group_get_item_id_vdup0(self &ItemGroup, id imgui.ID) &Item {
	return C.ImPlotItemGroup_GetItem_ID(self, id)
}


@[keep_args_alive]
fn C.ImPlotItemGroup_GetItem_Str(self &ItemGroup, label_id &char) &Item

@[inline]
pub fn item_group_get_item_str(self &ItemGroup, label_id &char) &Item {
	return C.ImPlotItemGroup_GetItem_Str(self, label_id)
}


@[keep_args_alive]
fn C.ImPlotItemGroup_GetOrAddItem(self &ItemGroup, id imgui.ID) &Item

@[inline]
pub fn item_group_get_or_add_item(self &ItemGroup, id imgui.ID) &Item {
	return C.ImPlotItemGroup_GetOrAddItem(self, id)
}


@[keep_args_alive]
fn C.ImPlotItemGroup_GetItemByIndex(self &ItemGroup, i i32) &Item

@[inline]
pub fn item_group_get_item_by_index(self &ItemGroup, i i32) &Item {
	return C.ImPlotItemGroup_GetItemByIndex(self, i)
}


@[keep_args_alive]
fn C.ImPlotItemGroup_GetItemIndex(self &ItemGroup, item &Item) i32

@[inline]
pub fn item_group_get_item_index(self &ItemGroup, item &Item) i32 {
	return C.ImPlotItemGroup_GetItemIndex(self, item)
}


@[keep_args_alive]
fn C.ImPlotItemGroup_GetLegendCount(self &ItemGroup) i32

@[inline]
pub fn item_group_get_legend_count(self &ItemGroup) i32 {
	return C.ImPlotItemGroup_GetLegendCount(self)
}


@[keep_args_alive]
fn C.ImPlotItemGroup_GetLegendItem(self &ItemGroup, i i32) &Item

@[inline]
pub fn item_group_get_legend_item(self &ItemGroup, i i32) &Item {
	return C.ImPlotItemGroup_GetLegendItem(self, i)
}


@[keep_args_alive]
fn C.ImPlotItemGroup_GetLegendLabel(self &ItemGroup, i i32) &char

@[inline]
pub fn item_group_get_legend_label(self &ItemGroup, i i32) &char {
	return C.ImPlotItemGroup_GetLegendLabel(self, i)
}


@[keep_args_alive]
fn C.ImPlotItemGroup_Reset(self &ItemGroup)

@[inline]
pub fn item_group_reset(self &ItemGroup) {
	C.ImPlotItemGroup_Reset(self)
}


@[keep_args_alive]
fn C.ImPlotPlot_ImPlotPlot() &Plot

@[inline]
pub fn plot_plot() &Plot {
	return C.ImPlotPlot_ImPlotPlot()
}


@[keep_args_alive]
fn C.ImPlotPlot_destroy(self &Plot)

@[inline]
pub fn plot_destroy(self &Plot) {
	C.ImPlotPlot_destroy(self)
}


@[keep_args_alive]
fn C.ImPlotPlot_IsInputLocked(self &Plot) bool

@[inline]
pub fn plot_is_input_locked(self &Plot) bool {
	return C.ImPlotPlot_IsInputLocked(self)
}


@[keep_args_alive]
fn C.ImPlotPlot_ClearTextBuffer(self &Plot)

@[inline]
pub fn plot_clear_text_buffer(self &Plot) {
	C.ImPlotPlot_ClearTextBuffer(self)
}


@[keep_args_alive]
fn C.ImPlotPlot_SetTitle(self &Plot, title &char)

@[inline]
pub fn plot_set_title(self &Plot, title &char) {
	C.ImPlotPlot_SetTitle(self, title)
}


@[keep_args_alive]
fn C.ImPlotPlot_HasTitle(self &Plot) bool

@[inline]
pub fn plot_has_title(self &Plot) bool {
	return C.ImPlotPlot_HasTitle(self)
}


@[keep_args_alive]
fn C.ImPlotPlot_GetTitle(self &Plot) &char

@[inline]
pub fn plot_get_title(self &Plot) &char {
	return C.ImPlotPlot_GetTitle(self)
}


@[keep_args_alive]
fn C.ImPlotPlot_XAxis_Nil(self &Plot, i i32) &Axis

@[inline]
pub fn plot_xa_xis_nil(self &Plot, i i32) &Axis {
	return C.ImPlotPlot_XAxis_Nil(self, i)
}


@[keep_args_alive]
fn C.ImPlotPlot_XAxis__const(self &Plot, i i32) &Axis

@[inline]
pub fn plot_xa_xis__const(self &Plot, i i32) &Axis {
	return C.ImPlotPlot_XAxis__const(self, i)
}


@[keep_args_alive]
fn C.ImPlotPlot_YAxis_Nil(self &Plot, i i32) &Axis

@[inline]
pub fn plot_ya_xis_nil(self &Plot, i i32) &Axis {
	return C.ImPlotPlot_YAxis_Nil(self, i)
}


@[keep_args_alive]
fn C.ImPlotPlot_YAxis__const(self &Plot, i i32) &Axis

@[inline]
pub fn plot_ya_xis__const(self &Plot, i i32) &Axis {
	return C.ImPlotPlot_YAxis__const(self, i)
}


@[keep_args_alive]
fn C.ImPlotPlot_EnabledAxesX(self &Plot) i32

@[inline]
pub fn plot_enabled_axes_x(self &Plot) i32 {
	return C.ImPlotPlot_EnabledAxesX(self)
}


@[keep_args_alive]
fn C.ImPlotPlot_EnabledAxesY(self &Plot) i32

@[inline]
pub fn plot_enabled_axes_y(self &Plot) i32 {
	return C.ImPlotPlot_EnabledAxesY(self)
}


@[keep_args_alive]
fn C.ImPlotPlot_SetAxisLabel(self &Plot, axis &Axis, const_label &char)

@[inline]
pub fn plot_set_axis_label(self &Plot, axis &Axis, const_label &char) {
	C.ImPlotPlot_SetAxisLabel(self, axis, const_label)
}


@[keep_args_alive]
fn C.ImPlotPlot_GetAxisLabel(self &Plot, axis Axis_c) &char

@[inline]
pub fn plot_get_axis_label(self &Plot, axis Axis_c) &char {
	return C.ImPlotPlot_GetAxisLabel(self, axis)
}


@[keep_args_alive]
fn C.ImPlotSubplot_ImPlotSubplot() &Subplot

@[inline]
pub fn subplot_subplot() &Subplot {
	return C.ImPlotSubplot_ImPlotSubplot()
}


@[keep_args_alive]
fn C.ImPlotSubplot_destroy(self &Subplot)

@[inline]
pub fn subplot_destroy(self &Subplot) {
	C.ImPlotSubplot_destroy(self)
}


@[keep_args_alive]
fn C.ImPlotNextPlotData_ImPlotNextPlotData() &NextPlotData

@[inline]
pub fn next_plot_data_next_plot_data() &NextPlotData {
	return C.ImPlotNextPlotData_ImPlotNextPlotData()
}


@[keep_args_alive]
fn C.ImPlotNextPlotData_destroy(self &NextPlotData)

@[inline]
pub fn next_plot_data_destroy(self &NextPlotData) {
	C.ImPlotNextPlotData_destroy(self)
}


@[keep_args_alive]
fn C.ImPlotNextPlotData_Reset(self &NextPlotData)

@[inline]
pub fn next_plot_data_reset(self &NextPlotData) {
	C.ImPlotNextPlotData_Reset(self)
}


@[keep_args_alive]
fn C.ImPlotNextItemData_ImPlotNextItemData() &NextItemData

@[inline]
pub fn next_item_data_next_item_data() &NextItemData {
	return C.ImPlotNextItemData_ImPlotNextItemData()
}


@[keep_args_alive]
fn C.ImPlotNextItemData_destroy(self &NextItemData)

@[inline]
pub fn next_item_data_destroy(self &NextItemData) {
	C.ImPlotNextItemData_destroy(self)
}


@[keep_args_alive]
fn C.ImPlotNextItemData_Reset(self &NextItemData)

@[inline]
pub fn next_item_data_reset(self &NextItemData) {
	C.ImPlotNextItemData_Reset(self)
}


@[keep_args_alive]
fn C.ImPlot_Initialize(ctx &imgui.Context)

@[inline]
pub fn initialize(ctx &imgui.Context) {
	C.ImPlot_Initialize(ctx)
}


@[keep_args_alive]
fn C.ImPlot_ResetCtxForNextPlot(ctx &imgui.Context)

@[inline]
pub fn reset_ctx_for_next_plot(ctx &imgui.Context) {
	C.ImPlot_ResetCtxForNextPlot(ctx)
}


@[keep_args_alive]
fn C.ImPlot_ResetCtxForNextAlignedPlots(ctx &imgui.Context)

@[inline]
pub fn reset_ctx_for_next_aligned_plots(ctx &imgui.Context) {
	C.ImPlot_ResetCtxForNextAlignedPlots(ctx)
}


@[keep_args_alive]
fn C.ImPlot_ResetCtxForNextSubplot(ctx &imgui.Context)

@[inline]
pub fn reset_ctx_for_next_subplot(ctx &imgui.Context) {
	C.ImPlot_ResetCtxForNextSubplot(ctx)
}


@[keep_args_alive]
fn C.ImPlot_GetPlot(title &char) &Plot

@[inline]
pub fn get_plot(title &char) &Plot {
	return C.ImPlot_GetPlot(title)
}


@[keep_args_alive]
fn C.ImPlot_GetCurrentPlot() &Plot

@[inline]
pub fn get_current_plot() &Plot {
	return C.ImPlot_GetCurrentPlot()
}


@[keep_args_alive]
fn C.ImPlot_BustPlotCache()

@[inline]
pub fn bust_plot_cache() {
	C.ImPlot_BustPlotCache()
}


@[keep_args_alive]
fn C.ImPlot_ShowPlotContextMenu(plot &Plot)

@[inline]
pub fn show_plot_context_menu(plot &Plot) {
	C.ImPlot_ShowPlotContextMenu(plot)
}


@[keep_args_alive]
fn C.ImPlot_SetupLock()

@[inline]
pub fn setup_lock() {
	C.ImPlot_SetupLock()
}


@[keep_args_alive]
fn C.ImPlot_SubplotNextCell()

@[inline]
pub fn subplot_next_cell() {
	C.ImPlot_SubplotNextCell()
}


@[keep_args_alive]
fn C.ImPlot_ShowSubplotsContextMenu(subplot &Subplot)

@[inline]
pub fn show_subplots_context_menu(subplot &Subplot) {
	C.ImPlot_ShowSubplotsContextMenu(subplot)
}


@[keep_args_alive]
fn C.ImPlot_BeginItem(label_id &char, spec Spec_c, item_col ImVec4_c, item_mkr Marker) bool

@[inline]
pub fn begin_item(label_id &char, spec Spec_c, item_col ImVec4_c, item_mkr Marker) bool {
	return C.ImPlot_BeginItem(label_id, spec, item_col, item_mkr)
}


@[keep_args_alive]
fn C.ImPlot_EndItem()

@[inline]
pub fn end_item() {
	C.ImPlot_EndItem()
}


@[keep_args_alive]
fn C.ImPlot_RegisterOrGetItem(label_id &char, flags ItemFlags, just_created &bool) &Item

@[inline]
pub fn register_or_get_item(label_id &char, flags ItemFlags, just_created &bool) &Item {
	return C.ImPlot_RegisterOrGetItem(label_id, flags, just_created)
}


@[keep_args_alive]
fn C.ImPlot_GetItem(label_id &char) &Item

@[inline]
pub fn get_item(label_id &char) &Item {
	return C.ImPlot_GetItem(label_id)
}


@[keep_args_alive]
fn C.ImPlot_GetCurrentItem() &Item

@[inline]
pub fn get_current_item() &Item {
	return C.ImPlot_GetCurrentItem()
}


@[keep_args_alive]
fn C.ImPlot_BustItemCache()

@[inline]
pub fn bust_item_cache() {
	C.ImPlot_BustItemCache()
}


@[keep_args_alive]
fn C.ImPlot_AnyAxesInputLocked(axes &Axis, count i32) bool

@[inline]
pub fn any_axes_input_locked(axes &Axis, count i32) bool {
	return C.ImPlot_AnyAxesInputLocked(axes, count)
}


@[keep_args_alive]
fn C.ImPlot_AllAxesInputLocked(axes &Axis, count i32) bool

@[inline]
pub fn all_axes_input_locked(axes &Axis, count i32) bool {
	return C.ImPlot_AllAxesInputLocked(axes, count)
}


@[keep_args_alive]
fn C.ImPlot_AnyAxesHeld(axes &Axis, count i32) bool

@[inline]
pub fn any_axes_held(axes &Axis, count i32) bool {
	return C.ImPlot_AnyAxesHeld(axes, count)
}


@[keep_args_alive]
fn C.ImPlot_AnyAxesHovered(axes &Axis, count i32) bool

@[inline]
pub fn any_axes_hovered(axes &Axis, count i32) bool {
	return C.ImPlot_AnyAxesHovered(axes, count)
}


@[keep_args_alive]
fn C.ImPlot_FitThisFrame() bool

@[inline]
pub fn fit_this_frame() bool {
	return C.ImPlot_FitThisFrame()
}


@[keep_args_alive]
fn C.ImPlot_FitPointX(x f64)

@[inline]
pub fn fit_point_x(x f64) {
	C.ImPlot_FitPointX(x)
}


@[keep_args_alive]
fn C.ImPlot_FitPointY(y f64)

@[inline]
pub fn fit_point_y(y f64) {
	C.ImPlot_FitPointY(y)
}


@[keep_args_alive]
fn C.ImPlot_FitPoint(p Point_c)

@[inline]
pub fn fit_point(p Point_c) {
	C.ImPlot_FitPoint(p)
}


@[keep_args_alive]
fn C.ImPlot_RangesOverlap(r1 Range_c, r2 Range_c) bool

@[inline]
pub fn ranges_overlap(r1 Range_c, r2 Range_c) bool {
	return C.ImPlot_RangesOverlap(r1, r2)
}


@[keep_args_alive]
fn C.ImPlot_ShowAxisContextMenu(axis &Axis, equal_axis &Axis, time_allowed bool)

@[inline]
pub fn show_axis_context_menu(axis &Axis, equal_axis &Axis, time_allowed bool) {
	C.ImPlot_ShowAxisContextMenu(axis, equal_axis, time_allowed)
}


@[keep_args_alive]
fn C.ImPlot_GetLocationPos(outer_rect ImRect_c, inner_size ImVec2_c, location Location, pad ImVec2_c) ImVec2_c

@[inline]
pub fn get_location_pos(outer_rect ImRect_c, inner_size ImVec2_c, location Location, pad ImVec2_c) ImVec2_c {
	return C.ImPlot_GetLocationPos(outer_rect, inner_size, location, pad)
}


@[keep_args_alive]
fn C.ImPlot_CalcLegendSize(items &ItemGroup, pad ImVec2_c, spacing ImVec2_c, vertical bool) ImVec2_c

@[inline]
pub fn calc_legend_size(items &ItemGroup, pad ImVec2_c, spacing ImVec2_c, vertical bool) ImVec2_c {
	return C.ImPlot_CalcLegendSize(items, pad, spacing, vertical)
}


@[keep_args_alive]
fn C.ImPlot_ClampLegendRect(legend_rect &ImRect, outer_rect ImRect_c, pad ImVec2_c) bool

@[inline]
pub fn clamp_legend_rect(legend_rect &ImRect, outer_rect ImRect_c, pad ImVec2_c) bool {
	return C.ImPlot_ClampLegendRect(legend_rect, outer_rect, pad)
}


@[keep_args_alive]
fn C.ImPlot_ShowLegendEntries(items &ItemGroup, legend_bb ImRect_c, interactable bool, pad ImVec2_c, spacing ImVec2_c, vertical bool, draw_list &imgui.ImDrawList) bool

@[inline]
pub fn show_legend_entries(items &ItemGroup, legend_bb ImRect_c, interactable bool, pad ImVec2_c, spacing ImVec2_c, vertical bool, draw_list &imgui.ImDrawList) bool {
	return C.ImPlot_ShowLegendEntries(items, legend_bb, interactable, pad, spacing, vertical, draw_list)
}


@[keep_args_alive]
fn C.ImPlot_ShowAltLegend(title_id &char, vertical bool, size ImVec2_c, interactable bool)

@[inline]
pub fn show_alt_legend(title_id &char, vertical bool, size ImVec2_c, interactable bool) {
	C.ImPlot_ShowAltLegend(title_id, vertical, size, interactable)
}


@[keep_args_alive]
fn C.ImPlot_ShowLegendContextMenu(legend &Legend, visible bool) bool

@[inline]
pub fn show_legend_context_menu(legend &Legend, visible bool) bool {
	return C.ImPlot_ShowLegendContextMenu(legend, visible)
}


@[keep_args_alive]
fn C.ImPlot_LabelAxisValue(axis Axis_c, value f64, buff &char, size i32, round bool)

@[inline]
pub fn label_axis_value(axis Axis_c, value f64, buff &char, size i32, round bool) {
	C.ImPlot_LabelAxisValue(axis, value, buff, size, round)
}


@[keep_args_alive]
fn C.ImPlot_GetItemData() &NextItemData

@[inline]
pub fn get_item_data() &NextItemData {
	return C.ImPlot_GetItemData()
}


@[keep_args_alive]
fn C.ImPlot_IsColorAuto_Vec4(col ImVec4_c) bool

@[inline]
pub fn is_color_auto_vec4(col ImVec4_c) bool {
	return C.ImPlot_IsColorAuto_Vec4(col)
}


@[keep_args_alive]
fn C.ImPlot_IsColorAuto_PlotCol(idx Col) bool

@[inline]
pub fn is_color_auto_plot_col(idx Col) bool {
	return C.ImPlot_IsColorAuto_PlotCol(idx)
}


@[keep_args_alive]
fn C.ImPlot_GetAutoColor(idx Col) ImVec4_c

@[inline]
pub fn get_auto_color(idx Col) ImVec4_c {
	return C.ImPlot_GetAutoColor(idx)
}


@[keep_args_alive]
fn C.ImPlot_GetStyleColorVec4(idx Col) ImVec4_c

@[inline]
pub fn get_style_color_vec4(idx Col) ImVec4_c {
	return C.ImPlot_GetStyleColorVec4(idx)
}


@[keep_args_alive]
fn C.ImPlot_GetStyleColorU32(idx Col) u32

@[inline]
pub fn get_style_color_u32(idx Col) u32 {
	return C.ImPlot_GetStyleColorU32(idx)
}


@[keep_args_alive]
fn C.ImPlot_AddTextVertical(draw_list &imgui.ImDrawList, pos ImVec2_c, col u32, text_begin &char, const_text_end &char)

@[inline]
pub fn add_text_vertical(draw_list &imgui.ImDrawList, pos ImVec2_c, col u32, text_begin &char, const_text_end &char) {
	C.ImPlot_AddTextVertical(draw_list, pos, col, text_begin, const_text_end)
}


@[keep_args_alive]
fn C.ImPlot_AddTextCentered(draw_list &imgui.ImDrawList, top_center ImVec2_c, col u32, text_begin &char, const_text_end &char)

@[inline]
pub fn add_text_centered(draw_list &imgui.ImDrawList, top_center ImVec2_c, col u32, text_begin &char, const_text_end &char) {
	C.ImPlot_AddTextCentered(draw_list, top_center, col, text_begin, const_text_end)
}


@[keep_args_alive]
fn C.ImPlot_CalcTextSizeVertical(const_text &char) ImVec2_c

@[inline]
pub fn calc_text_size_vertical(const_text &char) ImVec2_c {
	return C.ImPlot_CalcTextSizeVertical(const_text)
}


@[keep_args_alive]
fn C.ImPlot_CalcTextColor_Vec4(bg ImVec4_c) u32

@[inline]
pub fn calc_text_color_vec4(bg ImVec4_c) u32 {
	return C.ImPlot_CalcTextColor_Vec4(bg)
}


@[keep_args_alive]
fn C.ImPlot_CalcTextColor_U32(bg u32) u32

@[inline]
pub fn calc_text_color_u32(bg u32) u32 {
	return C.ImPlot_CalcTextColor_U32(bg)
}


@[keep_args_alive]
fn C.ImPlot_CalcHoverColor(col u32) u32

@[inline]
pub fn calc_hover_color(col u32) u32 {
	return C.ImPlot_CalcHoverColor(col)
}


@[keep_args_alive]
fn C.ImPlot_ClampLabelPos(pos ImVec2_c, size ImVec2_c, min ImVec2_c, max ImVec2_c) ImVec2_c

@[inline]
pub fn clamp_label_pos(pos ImVec2_c, size ImVec2_c, min ImVec2_c, max ImVec2_c) ImVec2_c {
	return C.ImPlot_ClampLabelPos(pos, size, min, max)
}


@[keep_args_alive]
fn C.ImPlot_GetColormapColorU32(idx i32, cmap Colormap) u32

@[inline]
pub fn get_colormap_color_u32(idx i32, cmap Colormap) u32 {
	return C.ImPlot_GetColormapColorU32(idx, cmap)
}


@[keep_args_alive]
fn C.ImPlot_NextColormapColorU32() u32

@[inline]
pub fn next_colormap_color_u32() u32 {
	return C.ImPlot_NextColormapColorU32()
}


@[keep_args_alive]
fn C.ImPlot_SampleColormapU32(t f32, cmap Colormap) u32

@[inline]
pub fn sample_colormap_u32(t f32, cmap Colormap) u32 {
	return C.ImPlot_SampleColormapU32(t, cmap)
}


@[keep_args_alive]
fn C.ImPlot_RenderColorBar(colors &u32, size i32, draw_list &imgui.ImDrawList, bounds ImRect_c, vert bool, reversed bool, continuous bool)

@[inline]
pub fn render_color_bar(colors &u32, size i32, draw_list &imgui.ImDrawList, bounds ImRect_c, vert bool, reversed bool, continuous bool) {
	C.ImPlot_RenderColorBar(colors, size, draw_list, bounds, vert, reversed, continuous)
}


@[keep_args_alive]
fn C.ImPlot_NiceNum(x f64, round bool) f64

@[inline]
pub fn nice_num(x f64, round bool) f64 {
	return C.ImPlot_NiceNum(x, round)
}


@[keep_args_alive]
fn C.ImPlot_OrderOfMagnitude(val f64) i32

@[inline]
pub fn order_of_magnitude(val f64) i32 {
	return C.ImPlot_OrderOfMagnitude(val)
}


@[keep_args_alive]
fn C.ImPlot_OrderToPrecision(order i32) i32

@[inline]
pub fn order_to_precision(order i32) i32 {
	return C.ImPlot_OrderToPrecision(order)
}


@[keep_args_alive]
fn C.ImPlot_Precision(val f64) i32

@[inline]
pub fn precision(val f64) i32 {
	return C.ImPlot_Precision(val)
}


@[keep_args_alive]
fn C.ImPlot_RoundTo(val f64, prec i32) f64

@[inline]
pub fn round_to(val f64, prec i32) f64 {
	return C.ImPlot_RoundTo(val, prec)
}


@[keep_args_alive]
fn C.ImPlot_Intersection(a1 ImVec2_c, a2 ImVec2_c, b1 ImVec2_c, b2 ImVec2_c) ImVec2_c

@[inline]
pub fn intersection(a1 ImVec2_c, a2 ImVec2_c, b1 ImVec2_c, b2 ImVec2_c) ImVec2_c {
	return C.ImPlot_Intersection(a1, a2, b1, b2)
}


@[keep_args_alive]
fn C.ImPlot_FillRange_Vector_Float_Ptr(buffer &ImVector_float, n i32, vmin f32, vmax f32)

@[inline]
pub fn fill_range_vector_float_ptr(buffer &ImVector_float, n i32, vmin f32, vmax f32) {
	C.ImPlot_FillRange_Vector_Float_Ptr(buffer, n, vmin, vmax)
}


@[keep_args_alive]
fn C.ImPlot_FillRange_Vector_double_Ptr(buffer &ImVector_double, n i32, vmin f64, vmax f64)

@[inline]
pub fn fill_range_vector_double_ptr(buffer &ImVector_double, n i32, vmin f64, vmax f64) {
	C.ImPlot_FillRange_Vector_double_Ptr(buffer, n, vmin, vmax)
}


@[keep_args_alive]
fn C.ImPlot_FillRange_Vector_S8_Ptr(buffer &ImVector_ImS8, n i32, vmin i8, vmax i8)

@[inline]
pub fn fill_range_vector_s8_ptr(buffer &ImVector_ImS8, n i32, vmin i8, vmax i8) {
	C.ImPlot_FillRange_Vector_S8_Ptr(buffer, n, vmin, vmax)
}


@[keep_args_alive]
fn C.ImPlot_FillRange_Vector_U8_Ptr(buffer &ImVector_ImU8, n i32, vmin u8, vmax u8)

@[inline]
pub fn fill_range_vector_u8_ptr(buffer &ImVector_ImU8, n i32, vmin u8, vmax u8) {
	C.ImPlot_FillRange_Vector_U8_Ptr(buffer, n, vmin, vmax)
}


@[keep_args_alive]
fn C.ImPlot_FillRange_Vector_S16_Ptr(buffer &ImVector_ImS16, n i32, vmin i16, vmax i16)

@[inline]
pub fn fill_range_vector_s16_ptr(buffer &ImVector_ImS16, n i32, vmin i16, vmax i16) {
	C.ImPlot_FillRange_Vector_S16_Ptr(buffer, n, vmin, vmax)
}


@[keep_args_alive]
fn C.ImPlot_FillRange_Vector_U16_Ptr(buffer &ImVector_ImU16, n i32, vmin u16, vmax u16)

@[inline]
pub fn fill_range_vector_u16_ptr(buffer &ImVector_ImU16, n i32, vmin u16, vmax u16) {
	C.ImPlot_FillRange_Vector_U16_Ptr(buffer, n, vmin, vmax)
}


@[keep_args_alive]
fn C.ImPlot_FillRange_Vector_S32_Ptr(buffer &ImVector_ImS32, n i32, vmin i32, vmax i32)

@[inline]
pub fn fill_range_vector_s32_ptr(buffer &ImVector_ImS32, n i32, vmin i32, vmax i32) {
	C.ImPlot_FillRange_Vector_S32_Ptr(buffer, n, vmin, vmax)
}


@[keep_args_alive]
fn C.ImPlot_FillRange_Vector_U32_Ptr(buffer &ImVector_ImU32, n i32, vmin u32, vmax u32)

@[inline]
pub fn fill_range_vector_u32_ptr(buffer &ImVector_ImU32, n i32, vmin u32, vmax u32) {
	C.ImPlot_FillRange_Vector_U32_Ptr(buffer, n, vmin, vmax)
}


@[keep_args_alive]
fn C.ImPlot_FillRange_Vector_S64_Ptr(buffer &ImVector_ImS64, n i32, vmin i64, vmax i64)

@[inline]
pub fn fill_range_vector_s64_ptr(buffer &ImVector_ImS64, n i32, vmin i64, vmax i64) {
	C.ImPlot_FillRange_Vector_S64_Ptr(buffer, n, vmin, vmax)
}


@[keep_args_alive]
fn C.ImPlot_FillRange_Vector_U64_Ptr(buffer &ImVector_ImU64, n i32, vmin u64, vmax u64)

@[inline]
pub fn fill_range_vector_u64_ptr(buffer &ImVector_ImU64, n i32, vmin u64, vmax u64) {
	C.ImPlot_FillRange_Vector_U64_Ptr(buffer, n, vmin, vmax)
}


@[keep_args_alive]
fn C.ImPlot_IsLeapYear(year i32) bool

@[inline]
pub fn is_leap_year(year i32) bool {
	return C.ImPlot_IsLeapYear(year)
}


@[keep_args_alive]
fn C.ImPlot_GetDaysInMonth(year i32, month i32) i32

@[inline]
pub fn get_days_in_month(year i32, month i32) i32 {
	return C.ImPlot_GetDaysInMonth(year, month)
}


@[keep_args_alive]
fn C.ImPlot_MkGmtTime(ptm &C.tm) Time_c

@[inline]
pub fn mk_gmt_time(ptm &C.tm) Time_c {
	return C.ImPlot_MkGmtTime(ptm)
}


@[keep_args_alive]
fn C.ImPlot_GetGmtTime(t Time_c, ptm &C.tm) &C.tm

@[inline]
pub fn get_gmt_time(t Time_c, ptm &C.tm) &C.tm {
	return C.ImPlot_GetGmtTime(t, ptm)
}


@[keep_args_alive]
fn C.ImPlot_MkLocTime(ptm &C.tm) Time_c

@[inline]
pub fn mk_loc_time(ptm &C.tm) Time_c {
	return C.ImPlot_MkLocTime(ptm)
}


@[keep_args_alive]
fn C.ImPlot_GetLocTime(t Time_c, ptm &C.tm) &C.tm

@[inline]
pub fn get_loc_time(t Time_c, ptm &C.tm) &C.tm {
	return C.ImPlot_GetLocTime(t, ptm)
}


@[keep_args_alive]
fn C.ImPlot_MkTime(ptm &C.tm) Time_c

@[inline]
pub fn mk_time(ptm &C.tm) Time_c {
	return C.ImPlot_MkTime(ptm)
}


@[keep_args_alive]
fn C.ImPlot_GetTime(t Time_c, ptm &C.tm) &C.tm

@[inline]
pub fn get_time(t Time_c, ptm &C.tm) &C.tm {
	return C.ImPlot_GetTime(t, ptm)
}


@[keep_args_alive]
fn C.ImPlot_MakeTime(year i32, month i32, day i32, hour i32, min i32, sec i32, us i32) Time_c

@[inline]
pub fn make_time(year i32, month i32, day i32, hour i32, min i32, sec i32, us i32) Time_c {
	return C.ImPlot_MakeTime(year, month, day, hour, min, sec, us)
}


@[keep_args_alive]
fn C.ImPlot_GetYear(t Time_c) i32

@[inline]
pub fn get_year(t Time_c) i32 {
	return C.ImPlot_GetYear(t)
}


@[keep_args_alive]
fn C.ImPlot_GetMonth(t Time_c) i32

@[inline]
pub fn get_month(t Time_c) i32 {
	return C.ImPlot_GetMonth(t)
}


@[keep_args_alive]
fn C.ImPlot_AddTime(t Time_c, unit TimeUnit, count i32) Time_c

@[inline]
pub fn add_time(t Time_c, unit TimeUnit, count i32) Time_c {
	return C.ImPlot_AddTime(t, unit, count)
}


@[keep_args_alive]
fn C.ImPlot_FloorTime(t Time_c, unit TimeUnit) Time_c

@[inline]
pub fn floor_time(t Time_c, unit TimeUnit) Time_c {
	return C.ImPlot_FloorTime(t, unit)
}


@[keep_args_alive]
fn C.ImPlot_CeilTime(t Time_c, unit TimeUnit) Time_c

@[inline]
pub fn ceil_time(t Time_c, unit TimeUnit) Time_c {
	return C.ImPlot_CeilTime(t, unit)
}


@[keep_args_alive]
fn C.ImPlot_RoundTime(t Time_c, unit TimeUnit) Time_c

@[inline]
pub fn round_time(t Time_c, unit TimeUnit) Time_c {
	return C.ImPlot_RoundTime(t, unit)
}


@[keep_args_alive]
fn C.ImPlot_CombineDateTime(date_part Time_c, time_part Time_c) Time_c

@[inline]
pub fn combine_date_time(date_part Time_c, time_part Time_c) Time_c {
	return C.ImPlot_CombineDateTime(date_part, time_part)
}


@[keep_args_alive]
fn C.ImPlot_Now() Time_c

@[inline]
pub fn now() Time_c {
	return C.ImPlot_Now()
}


@[keep_args_alive]
fn C.ImPlot_Today() Time_c

@[inline]
pub fn today() Time_c {
	return C.ImPlot_Today()
}


@[keep_args_alive]
fn C.ImPlot_FormatTime(t Time_c, buffer &char, size i32, fmt TimeFmt, use_24_hr_clk bool) i32

@[inline]
pub fn format_time(t Time_c, buffer &char, size i32, fmt TimeFmt, use_24_hr_clk bool) i32 {
	return C.ImPlot_FormatTime(t, buffer, size, fmt, use_24_hr_clk)
}


@[keep_args_alive]
fn C.ImPlot_FormatDate(t Time_c, buffer &char, size i32, fmt DateFmt, use_iso_8601 bool) i32

@[inline]
pub fn format_date(t Time_c, buffer &char, size i32, fmt DateFmt, use_iso_8601 bool) i32 {
	return C.ImPlot_FormatDate(t, buffer, size, fmt, use_iso_8601)
}


@[keep_args_alive]
fn C.ImPlot_FormatDateTime(t Time_c, buffer &char, size i32, fmt DateTimeSpec_c) i32

@[inline]
pub fn format_date_time(t Time_c, buffer &char, size i32, fmt DateTimeSpec_c) i32 {
	return C.ImPlot_FormatDateTime(t, buffer, size, fmt)
}


@[keep_args_alive]
fn C.ImPlot_ShowDatePicker(id &char, level &i32, t &Time, t1 &Time, t2 &Time) bool

@[inline]
pub fn show_date_picker(id &char, level &i32, t &Time, t1 &Time, t2 &Time) bool {
	return C.ImPlot_ShowDatePicker(id, level, t, t1, t2)
}


@[keep_args_alive]
fn C.ImPlot_ShowTimePicker(id &char, t &Time) bool

@[inline]
pub fn show_time_picker(id &char, t &Time) bool {
	return C.ImPlot_ShowTimePicker(id, t)
}


@[keep_args_alive]
fn C.ImPlot_TransformForward_Log10(v f64, noname1 voidptr) f64

@[inline]
pub fn transform_forward_log10(v f64, noname1 voidptr) f64 {
	return C.ImPlot_TransformForward_Log10(v, noname1)
}


@[keep_args_alive]
fn C.ImPlot_TransformInverse_Log10(v f64, noname1 voidptr) f64

@[inline]
pub fn transform_inverse_log10(v f64, noname1 voidptr) f64 {
	return C.ImPlot_TransformInverse_Log10(v, noname1)
}


@[keep_args_alive]
fn C.ImPlot_TransformForward_SymLog(v f64, noname1 voidptr) f64

@[inline]
pub fn transform_forward_sym_log(v f64, noname1 voidptr) f64 {
	return C.ImPlot_TransformForward_SymLog(v, noname1)
}


@[keep_args_alive]
fn C.ImPlot_TransformInverse_SymLog(v f64, noname1 voidptr) f64

@[inline]
pub fn transform_inverse_sym_log(v f64, noname1 voidptr) f64 {
	return C.ImPlot_TransformInverse_SymLog(v, noname1)
}


@[keep_args_alive]
fn C.ImPlot_TransformForward_Logit(v f64, noname1 voidptr) f64

@[inline]
pub fn transform_forward_logit(v f64, noname1 voidptr) f64 {
	return C.ImPlot_TransformForward_Logit(v, noname1)
}


@[keep_args_alive]
fn C.ImPlot_TransformInverse_Logit(v f64, noname1 voidptr) f64

@[inline]
pub fn transform_inverse_logit(v f64, noname1 voidptr) f64 {
	return C.ImPlot_TransformInverse_Logit(v, noname1)
}


@[keep_args_alive]
fn C.ImPlot_Formatter_Default(value f64, buff &char, size i32, data voidptr) i32

@[inline]
pub fn formatter_default(value f64, buff &char, size i32, data voidptr) i32 {
	return C.ImPlot_Formatter_Default(value, buff, size, data)
}


@[keep_args_alive]
fn C.ImPlot_Formatter_Logit(value f64, buff &char, size i32, noname1 voidptr) i32

@[inline]
pub fn formatter_logit(value f64, buff &char, size i32, noname1 voidptr) i32 {
	return C.ImPlot_Formatter_Logit(value, buff, size, noname1)
}


@[keep_args_alive]
fn C.ImPlot_Formatter_Time(noname1 f64, buff &char, size i32, data voidptr) i32

@[inline]
pub fn formatter_time(noname1 f64, buff &char, size i32, data voidptr) i32 {
	return C.ImPlot_Formatter_Time(noname1, buff, size, data)
}


@[keep_args_alive]
fn C.ImPlot_Locator_Default(ticker &Ticker, range Range_c, pixels f32, vertical bool, formatter Formatter, formatter_data voidptr)

@[inline]
pub fn locator_default(ticker &Ticker, range Range_c, pixels f32, vertical bool, formatter Formatter, formatter_data voidptr) {
	C.ImPlot_Locator_Default(ticker, range, pixels, vertical, formatter, formatter_data)
}


@[keep_args_alive]
fn C.ImPlot_Locator_Time(ticker &Ticker, range Range_c, pixels f32, vertical bool, formatter Formatter, formatter_data voidptr)

@[inline]
pub fn locator_time(ticker &Ticker, range Range_c, pixels f32, vertical bool, formatter Formatter, formatter_data voidptr) {
	C.ImPlot_Locator_Time(ticker, range, pixels, vertical, formatter, formatter_data)
}


@[keep_args_alive]
fn C.ImPlot_Locator_Log10(ticker &Ticker, range Range_c, pixels f32, vertical bool, formatter Formatter, formatter_data voidptr)

@[inline]
pub fn locator_log10(ticker &Ticker, range Range_c, pixels f32, vertical bool, formatter Formatter, formatter_data voidptr) {
	C.ImPlot_Locator_Log10(ticker, range, pixels, vertical, formatter, formatter_data)
}


@[keep_args_alive]
fn C.ImPlot_Locator_SymLog(ticker &Ticker, range Range_c, pixels f32, vertical bool, formatter Formatter, formatter_data voidptr)

@[inline]
pub fn locator_sym_log(ticker &Ticker, range Range_c, pixels f32, vertical bool, formatter Formatter, formatter_data voidptr) {
	C.ImPlot_Locator_SymLog(ticker, range, pixels, vertical, formatter, formatter_data)
}

// CIMGUIPLOT_INCLUDED
