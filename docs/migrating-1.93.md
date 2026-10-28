# Dear ImGui 1.93 standard bindings

`v0.4.0-standard` updates the **standard** variant to Dear ImGui 1.93.0.
It is an API/ABI update, not a drop-in native-library replacement. The docking
variant remains on 1.92.9b; do not switch variants or reuse its native library
implicitly.

```sh
v install antono2.imgui@v0.4.0-standard
cd ~/.vmodules/antono2/imgui
v install
v run build_vimgui.vsh --linkage shared --glfw system
```

Rebuild your application and its native libraries together. Do not mix old
generated V structures with a new `libvimgui`, or the reverse.

Notable source changes include:

- `ImDrawListFlags`/`ImDrawListFlags_` are replaced by the new draw flags API.
- Draw-list methods such as `im_draw_list_add_line` and
  `im_draw_list_add_circle` gain an explicit flags argument. Review the new
  signature and desired stroke/cap/join behavior rather than copying old bits.
- `Style.AntiAliasedLinesUseTex` is removed because the new line renderer
  always uses textures. `AntiAliasedLineEnds` controls line-ending anti-aliasing;
  it is not a replacement texture toggle.
- `CurveTessellationTol` used squared-pixel units; `CurveTessellationMaxError`
  uses pixels. Convert a customized old threshold with `sqrt(old_threshold)`
  rather than copying the old value unchanged.
- Font remapping uses `im_font_add_remap_codepoint` instead of
  `im_font_add_remap_char`.
- Text-filter, draw-list and other generated structures have changed layouts.
  Treat fixed-array helper aliases as generated implementation details.

These are highlights, not a complete API diff. Compare `imgui.v`,
`implot/implot.v` and the bundled upstream changelog for APIs your project uses.
Update the generator/normalizer when a binding fix is needed; never patch
generated declarations independently of their matching C API.

Consumers using only the unchanged widget/frame/backend calls may need no
source edits, but still need a rebuilt native library, installation checks and
runtime validation. `v_vulkan_video --imgui-demo` exercises actual UI rendering
and input over hardware video playback; the examples cover GLFW/Vulkan,
widgets, native application UI and ImPlot. Docking and platform-viewports
helpers remain safe no-ops on the standard variant.
