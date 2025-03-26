
# [WIP] [V](https://vlang.io) binding generator for [Dear ImGui](https://github.com/ocornut/imgui)

This is an automated process to generate `src/imgui.v`
 - generate C using [dear_bindings](https://github.com/dearimgui/dear_bindings)
 - `v translate` C to V
 - `cleanup_imgui.perl` to fix some errors
 
 ## Install
`v install https://github.com/antono2/imgui`


## Generate
On `Ubuntu 24.04`
```bash
sudo apt install -y python3-ply
v install https://github.com/antono2/imgui
cd ~/.vmodules/imgui
git submodule update --init
./generate_imgui_v.sh
```

## Examples
TODO

## Contributors
Thank you [@ryoskzypu](https://github.com/ryoskzypu) - from  #regex on [libera.chat](https://libera.chat/) - for loving perl and helping people out.


