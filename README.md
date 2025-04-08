
# [WIP] [V](https://vlang.io) binding generator for [Dear ImGui](https://github.com/ocornut/imgui)

This is an automated process to generate `src/imgui.v` and `implot.v`
 - generate C for imgui using [cimgui](https://github.com/cimgui/cimgui)
 - generate C for implot using [cimplot](https://github.com/cimgui/cimplot)
 - `v translate` C to V
 - `cleanup_imgui.perl` and `cleanup_implot.perl` to fix some errors
 
 ## Install
`v install https://github.com/antono2/imgui`


## Generate
On `Ubuntu 24.04`
```bash
sudo apt install -y python3-ply
v install https://github.com/antono2/imgui
~/.vmodules/imgui/generate_v.sh
```

## Examples
TODO

## Contributors
Thank you [@ryoskzypu](https://github.com/ryoskzypu) - from  #regex on [libera.chat](https://libera.chat/) - for loving perl and helping people out.


