@[translated]
module impl_vulkan

import vulkan as vk
import imgui

#flag -I @VMODROOT/include/imgui/backends
#define IMGUI_DISABLE
#define IMGUI_IMPL_VULKAN_USE_VOLK

//#define IMGUI_IMPL_VULKAN_HAS_DYNAMIC_RENDERING
#define IMGUI_IMPL_VULKAN_USE_LOADER
#include "imgui_impl_vulkan.h"

pub type PFN_LoaderFunc = fn (function_name &char, user_data voidptr) voidptr

@[c:'ImGui_ImplVulkan_LoadFunctions']
pub fn load_functions(api_version u32, loader_func PFN_LoaderFunc, user_data voidptr) bool

pub type PFN_CheckVkResult = fn(err vk.Result)

pub type InitInfo = C.ImGui_ImplVulkan_InitInfo

@[typedef]
pub struct C.ImGui_ImplVulkan_InitInfo {
//pub struct InitInfo {
pub mut:
  ApiVersion u32
  Instance vk.Instance
  PhysicalDevice vk.PhysicalDevice
  Device vk.Device
  QueueFamily u32
  Queue vk.Queue
  DescriptorPool vk.DescriptorPool
  RenderPass vk.RenderPass
  MinImageCount u32
  ImageCount u32
  MSAASamples vk.SampleCountFlagBits = vk.SampleCountFlagBits(0)
  // (Optional)
  PipelineCache vk.PipelineCache
  Subpass u32
  // (Optional) Set to create internal descriptor pool instead of using DescriptorPool
  DescriptorPoolSize u32
  // (Optional) Dynamic Rendering
  // Need to explicitly enable VK_KHR_dynamic_rendering extension to use this, even for Vulkan 1.3.
  UseDynamicRendering bool
  //$if d('IMGUI_IMPL_VULKAN_HAS_DYNAMIC_RENDERING')? {
    PipelineRenderingCreateInfo vk.PipelineRenderingCreateInfoKHR //= vk.PipelineRenderingCreateInfoKHR(vk.PipelineRenderingCreateInfo{})
  //}
  // (Optional) Allocation, Debugging
  Allocator &vk.AllocationCallbacks = unsafe{nil}
  CheckVkResultFn PFN_CheckVkResult = unsafe{nil}
  MinAllocationSize vk.DeviceSize
}

@[c:'ImGui_ImplVulkan_Init']
pub fn vkinit(init &InitInfo) bool

@[c:'ImGui_ImplVulkan_NewFrame']
pub fn new_frame()

@[c: 'ImGui_ImplVulkan_RenderDrawData']
pub fn render_draw_data(draw_data &imgui.ImDrawData, command_buffer vk.CommandBuffer, pipeline vk.Pipeline)
