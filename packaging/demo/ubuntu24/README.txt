V + Dear ImGui GLFW/Vulkan Demo - Ubuntu 24.04 x86-64
======================================================

Extract the complete archive and run:

    ./run.sh

The package contains the compiled V example, libvimgui, GLFW, and the required
C++ runtime libraries. A graphical session and a Vulkan-capable display driver
are still required. The Vulkan loader and GPU driver come from the operating
system and are not bundled.

This first prebuilt package avoids compiling the large generated ImGui and
ImPlot V bindings locally. Developers can build from source with
scripts/run_demo.sh in the antono2/imgui repository.
