

# [V](https://vlang.io) binding generator for [Dear ImGui](https://github.com/ocornut/imgui)

This is an automated process to generate `imgui.v` and `implot.v`
 - generate C for imgui using [cimgui](https://github.com/cimgui/cimgui)
 - generate C for implot using [cimplot](https://github.com/cimgui/cimplot)
 - `v translate` C to V
 - `cleanup_imgui.perl` and `cleanup_implot.perl` to fix some errors

## Dependencies
`v install https://github.com/antono2/vulkan`<br>
`v install https://github.com/antono2/glfw`

## Install
```bash
v install https://github.com/antono2/imgui
# Build vimgui lib
cd ~/.vmodules/imgui
cmake .
make
```


## Generate
On `Ubuntu`
```bash
sudo apt install -y luajit
~/.vmodules/imgui/generate_v.sh
```

Or
```bash
# Install luajit for your OS
# Go to vmodules/imgui
v generate.vsh
```

## Thanks
Thank you [@ryoskzypu](https://github.com/ryoskzypu) - from  #regex on [libera.chat](https://libera.chat/) - for loving perl and helping people out.


