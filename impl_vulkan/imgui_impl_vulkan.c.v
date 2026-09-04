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

fn C.ImGui_ImplVulkan_LoadFunctions(api_version u32, loader_func PFN_LoaderFunc, user_data voidptr) bool

@[inline]
pub fn load_functions(api_version u32, loader_func PFN_LoaderFunc, user_data voidptr) bool {
	return C.ImGui_ImplVulkan_LoadFunctions(api_version, loader_func, user_data)
}

pub type PFN_CheckVkResult = fn (err vk.Result)

pub struct DynamicStateVector {
pub mut:
	size     int
	capacity int
	data     &vk.DynamicState = unsafe { nil }
}

pub struct PipelineInfo {
pub mut:
	render_pass                    vk.RenderPass
	subpass                        u32
	msaa_samples                   vk.SampleCountFlagBits
	extra_dynamic_states           DynamicStateVector
	pipeline_rendering_create_info vk.PipelineRenderingCreateInfoKHR
	swap_chain_image_usage         vk.ImageUsageFlags
}

pub struct InitInfo {
pub mut:
	api_version                    u32
	instance                       vk.Instance
	physical_device                vk.PhysicalDevice
	device                         vk.Device
	queue_family                   u32
	queue                          vk.Queue
	descriptor_pool                vk.DescriptorPool
	descriptor_pool_size           u32
	min_image_count                u32
	image_count                    u32
	pipeline_cache                 vk.PipelineCache
	pipeline_info_main             PipelineInfo
	pipeline_info_for_viewports    PipelineInfo
	use_dynamic_rendering          bool
	allocator                      &vk.AllocationCallbacks = unsafe { nil }
	check_vk_result_fn             PFN_CheckVkResult       = unsafe { nil }
	min_allocation_size            vk.DeviceSize
	custom_shader_vert_create_info vk.ShaderModuleCreateInfo
	custom_shader_frag_create_info vk.ShaderModuleCreateInfo
}

fn C.ImGui_ImplVulkan_Init(init &InitInfo) bool

@[inline]
pub fn vkinit(init &InitInfo) bool {
	return C.ImGui_ImplVulkan_Init(init)
}

fn C.ImGui_ImplVulkan_NewFrame()

@[inline]
pub fn new_frame() {
	C.ImGui_ImplVulkan_NewFrame()
}

fn C.ImGui_ImplVulkan_RenderDrawData(draw_data &imgui.ImDrawData, command_buffer vk.CommandBuffer, pipeline vk.Pipeline)

@[inline]
pub fn render_draw_data(draw_data &imgui.ImDrawData, command_buffer vk.CommandBuffer, pipeline vk.Pipeline) {
	C.ImGui_ImplVulkan_RenderDrawData(draw_data, command_buffer, pipeline)
}

// Helper structure to hold the data needed by one rendering frame
// (Used by example. Used by multi-viewport features. Probably NOT used by your own engine/app.)
// [Please zero-clear before use!]
/*
pub type Frame = C.ImGui_ImplVulkanH_Frame
//@[typedef]
pub struct C.ImGui_ImplVulkanH_Frame {
pub mut:
  CommandPool vk.CommandPool
  CommandBuffer vk.CommandBuffer
  Fence vk.Fence
  Backbuffer vk.Image
  BackbufferView vk.ImageView
  Framebuffer vk.Framebuffer
}

pub type FrameSemaphores = C.ImGui_ImplVulkanH_FrameSemaphores
//@[typedef]
pub struct C.ImGui_ImplVulkanH_FrameSemaphores {
pub mut:
  ImageAcquiredSemaphore vk.Semaphore
  RenderCompleteSemaphore vk.Semaphore
}


pub struct ImVector_Frame {
pub mut:
  size i32
  capacity i32
  data &Frame = unsafe{nil}
}

pub struct ImVector_FrameSemaphores {
pub mut:
  size i32
  capacity i32
  data &FrameSemaphores = unsafe{nil}
}
*/
// Helper structure to hold the data needed by one rendering context into one OS window
// (Used by example. Used by multi-viewport features. Probably NOT used by your own engine/app.)
/*
pub type Window = C.ImGui_ImplVulkanH_Window
//@[typedef]
pub struct C.ImGui_ImplVulkanH_Window {
pub mut:
  Width i32
  Height i32
  Swapchain vk.SwapchainKHR
  Surface vk.SurfaceKHR
  SurfaceFormat vk.SurfaceFormatKHR
  PresentMode vk.PresentModeKHR
  RenderPass vk.RenderPass
  UseDynamicRendering u8
  ClearEnable u8
  ClearValue vk.ClearValue
  FrameIndex u32                            // Current frame being rendered to (0 <= FrameIndex < FrameInFlightCount)
  ImageCount u32                            // Number of simultaneous in-flight frames (returned by vkGetSwapchainImagesKHR, usually derived from min_image_count)
  SemaphoreCount u32                        // Number of simultaneous in-flight frames + 1, to be able to use it in vkAcquireNextImageKHR
  SemaphoreIndex u32                        // Current set of swapchain wait semaphores we're using (needs to be distinct from per frame data)
  Frames ImVector_Frame
  FrameSemaphores ImVector_FrameSemaphores
}

@[c:'ImGui_ImplVulkanH_DestroyFrame']
pub fn destroy_frame(device vk.Device, fd &Frame, const_allocator &vk.AllocationCallbacks)

@[c:'ImGui_ImplVulkanH_CreateOrResizeWindow']
pub fn create_or_resize_window(instance vk.Instance, physical_device vk.PhysicalDevice, device vk.Device, wd &Window, queue_family u32, allocator &vk.AllocationCallbacks, w i32, h i32, min_image_count u32)
*/

pub struct Frame {
pub mut:
	command_pool    vk.CommandPool
	command_buffer  vk.CommandBuffer
	fence           vk.Fence
	backbuffer      vk.Image
	backbuffer_view vk.ImageView
	framebuffer     vk.Framebuffer
}

pub struct FrameSemaphores {
pub mut:
	image_acquired_semaphore  vk.Semaphore
	render_complete_semaphore vk.Semaphore
}

pub struct Window {
pub mut:
	width                 i32
	height                i32
	swapchain             vk.SwapchainKHR
	surface               vk.SurfaceKHR
	surface_format        vk.SurfaceFormatKHR
	present_mode          vk.PresentModeKHR
	render_pass           vk.RenderPass
	use_dynamic_rendering bool
	clear_enable          bool
	clear_value           vk.ClearValue
	frame_index           u32 // Current frame being rendered to (0 <= FrameIndex < FrameInFlightCount)
	image_count           u32 // Number of simultaneous in-flight frames (returned by vkGetSwapchainImagesKHR, usually derived from min_image_count)
	semaphore_count       u32 // Number of simultaneous in-flight frames + 1, to be able to use it in vkAcquireNextImageKHR
	semaphore_index       u32 // Current set of swapchain wait semaphores we're using (needs to be distinct from per frame data)
	frames                []Frame
	frame_semaphores      []FrameSemaphores
}

fn C.ImGui_ImplVulkanH_SelectPhysicalDevice(instance vk.Instance) vk.PhysicalDevice

@[inline]
pub fn select_physical_device(instance vk.Instance) vk.PhysicalDevice {
	return C.ImGui_ImplVulkanH_SelectPhysicalDevice(instance)
}

fn C.ImGui_ImplVulkanH_SelectQueueFamilyIndex(physical_device vk.PhysicalDevice) u32

@[inline]
pub fn select_queue_family_index(physical_device vk.PhysicalDevice) u32 {
	return C.ImGui_ImplVulkanH_SelectQueueFamilyIndex(physical_device)
}

fn C.ImGui_ImplVulkanH_SelectSurfaceFormat(physical_device vk.PhysicalDevice, surface vk.SurfaceKHR, const_request_formats &vk.Format, request_formats_count i32, request_color_space vk.ColorSpaceKHR) vk.SurfaceFormatKHR

@[inline]
pub fn select_surface_format(physical_device vk.PhysicalDevice, surface vk.SurfaceKHR, const_request_formats &vk.Format, request_formats_count i32, request_color_space vk.ColorSpaceKHR) vk.SurfaceFormatKHR {
	return C.ImGui_ImplVulkanH_SelectSurfaceFormat(physical_device, surface, const_request_formats,
		request_formats_count, request_color_space)
}

fn C.ImGui_ImplVulkanH_SelectPresentMode(physical_device vk.PhysicalDevice, surface vk.SurfaceKHR, const_request_modes &vk.PresentModeKHR, request_modes_count i32) vk.PresentModeKHR

@[inline]
pub fn select_present_mode(physical_device vk.PhysicalDevice, surface vk.SurfaceKHR, const_request_modes &vk.PresentModeKHR, request_modes_count i32) vk.PresentModeKHR {
	return C.ImGui_ImplVulkanH_SelectPresentMode(physical_device, surface, const_request_modes,
		request_modes_count)
}

fn C.ImGui_ImplVulkan_SetMinImageCount(min_image_count u32)

@[inline]
pub fn set_min_image_count(min_image_count u32) {
	C.ImGui_ImplVulkan_SetMinImageCount(min_image_count)
}

fn C.ImGui_ImplVulkan_Shutdown()

@[inline]
pub fn shutdown() {
	C.ImGui_ImplVulkan_Shutdown()
}

pub fn create_or_resize_window(instance vk.Instance, physical_device vk.PhysicalDevice, device vk.Device, wd &Window, queue_family u32, allocator &vk.AllocationCallbacks, width i32, height i32, min_image_count u32) {
	create_window_swap_chain(physical_device, device, mut wd, allocator, width, height,
		min_image_count)
	create_window_command_buffers(physical_device, device, wd, queue_family, allocator)
}

// ImGui_ImplVulkanH_DestroyFrame
pub fn destroy_frame(device vk.Device, fd &Frame, const_allocator &vk.AllocationCallbacks) {
	vk.destroy_fence(device, fd.fence, const_allocator)
	vk.free_command_buffers(device, fd.command_pool, 1, &fd.command_buffer)
	vk.destroy_command_pool(device, fd.command_pool, const_allocator)
	fd.command_buffer = unsafe { nil }
	fd.command_pool = unsafe { nil }

	vk.destroy_image_view(device, fd.backbuffer_view, const_allocator)
	vk.destroy_framebuffer(device, fd.framebuffer, const_allocator)
}

// ImGui_ImplVulkanH_DestroyFrameSemaphores
pub fn destroy_frame_semaphores(device vk.Device, fsd &FrameSemaphores, const_allocator &vk.AllocationCallbacks) {
	vk.destroy_semaphore(device, fsd.image_acquired_semaphore, const_allocator)
	vk.destroy_semaphore(device, fsd.render_complete_semaphore, const_allocator)
	fsd.image_acquired_semaphore = unsafe { nil }
	fsd.render_complete_semaphore = unsafe { nil }
}

// ImGui_ImplVulkanH_GetMinImageCountFromPresentMode
pub fn get_min_image_count_from_present_mode(present_mode vk.PresentModeKHR) u32 {
	match present_mode {
		.mailbox {
			return 3
		}
		.fifo || .fifo_relaxed {
			return 2
		}
		.immediate {
			return 1
		}
		else {}
	}

	assert false
	return 1
}

// Also destroy old swap chain and in-flight frames data, if any.
// ImGui_ImplVulkanH_CreateWindowSwapChain
pub fn create_window_swap_chain(physical_device vk.PhysicalDevice, device vk.Device, mut wd &Window, const_allocator &vk.AllocationCallbacks, w i32, h i32, min_image_count u32) {
	mut res := vk.Result.error_unknown
	old_swapchain := wd.swapchain
	wd.swapchain = unsafe { nil }
	res = vk.device_wait_idle(device)
	assert res == vk.Result.success
	// We don't use ImGui_ImplVulkanH_DestroyWindow() because we want to preserve the old swapchain to create the new one.
	// Destroy old Framebuffer
	for i in 0 .. wd.image_count {
		destroy_frame(device, &wd.frames[i], const_allocator)
	}
	for i in 0 .. wd.semaphore_count {
		destroy_frame_semaphores(device, &wd.frame_semaphores[i], const_allocator)
	}
	// Clears the array without deallocating the allocated data. It does it by setting the array length to 0.
	// C++ clear() does destroy the elements as well.
	wd.frames.clear()
	wd.frame_semaphores.clear()
	wd.image_count = 0
	if !isnil(wd.render_pass) {
		vk.destroy_render_pass(device, wd.render_pass, const_allocator)
	}

	// If min image count was not specified, request different count of images dependent on selected present mode
	if min_image_count == 0 {
		min_image_count = get_min_image_count_from_present_mode(wd.present_mode)
	}

	// Create Swapchain
	mut cap := vk.SurfaceCapabilitiesKHR{}
	res = vk.get_physical_device_surface_capabilities_khr(physical_device, wd.surface, mut &cap)
	assert res == vk.Result.success

	mut swapchain_ci := vk.SwapchainCreateInfoKHR{}
	swapchain_ci.surface = wd.surface
	swapchain_ci.minImageCount = min_image_count
	swapchain_ci.imageFormat = wd.surface_format.format
	swapchain_ci.imageColorSpace = wd.surface_format.colorSpace
	swapchain_ci.imageArrayLayers = 1
	swapchain_ci.imageUsage = vk.ImageUsageFlags(vk.ImageUsageFlagBits.color_attachment)
	// Assume that graphics family == present family
	swapchain_ci.imageSharingMode = vk.SharingMode.exclusive
	if u32(cap.supportedTransforms) & u32(vk.SurfaceTransformFlagBitsKHR.identity) > 0 {
		swapchain_ci.preTransform = vk.SurfaceTransformFlagBitsKHR.identity
	} else {
		swapchain_ci.preTransform = cap.currentTransform
	}
	swapchain_ci.compositeAlpha = vk.CompositeAlphaFlagBitsKHR.opaque
	swapchain_ci.presentMode = wd.present_mode
	swapchain_ci.clipped = vk._true
	swapchain_ci.oldSwapchain = old_swapchain
	if swapchain_ci.minImageCount < cap.minImageCount {
		swapchain_ci.minImageCount = cap.minImageCount
	} else if cap.maxImageCount != 0 && swapchain_ci.minImageCount > cap.maxImageCount {
		swapchain_ci.minImageCount = cap.maxImageCount
	}
	if cap.currentExtent.width == 0xffffffff {
		swapchain_ci.imageExtent.width = w
		wd.width = w
		swapchain_ci.imageExtent.height = h
		wd.height = h
	} else {
		swapchain_ci.imageExtent.width = cap.currentExtent.width
		wd.width = cap.currentExtent.width
		swapchain_ci.imageExtent.height = cap.currentExtent.height
		wd.height = cap.currentExtent.height
	}
	res = vk.create_swapchain_khr(device, &swapchain_ci, const_allocator, &wd.swapchain)
	assert res == vk.Result.success
	// Value initialization to 0
	res = vk.get_swapchain_images_khr(device, wd.swapchain, &wd.image_count, unsafe { nil })
	assert res == vk.Result.success
	mut backbuffers := []vk.Image{len: int(wd.image_count + 1), init: unsafe { nil }}
	assert wd.image_count >= min_image_count
	res = vk.get_swapchain_images_khr(device, wd.swapchain, &wd.image_count, backbuffers.data)
	assert res == vk.Result.success

	wd.semaphore_count = wd.image_count + 1
	wd.frames = []Frame{len: int(wd.image_count), init: Frame{}}
	wd.frame_semaphores = []FrameSemaphores{len: int(wd.semaphore_count), init: FrameSemaphores{}}
	for i in 0 .. wd.image_count {
		wd.frames[i].backbuffer = backbuffers[i]
	}
	if !isnil(old_swapchain) {
		vk.destroy_swapchain_khr(device, old_swapchain, const_allocator)
	}

	// Create the Render Pass
	if wd.use_dynamic_rendering == false {
		mut description_att := vk.AttachmentDescription{}
		description_att.format = wd.surface_format.format
		description_att.samples = vk.SampleCountFlags(vk.SampleCountFlagBits._1)
		if wd.clear_enable {
			description_att.loadOp = vk.AttachmentLoadOp.clear
		} else {
			description_att.loadOp = vk.AttachmentLoadOp.dont_care
		}
		description_att.storeOp = vk.AttachmentStoreOp.store
		description_att.stencilLoadOp = vk.AttachmentLoadOp.dont_care
		description_att.initialLayout = vk.ImageLayout.undefined
		description_att.finalLayout = vk.ImageLayout.present_src_khr

		mut color_att := vk.AttachmentReference{}
		color_att.attachment = 0
		color_att.layout = vk.ImageLayout.color_attachment_optimal

		mut subpass := vk.SubpassDescription{}
		subpass.pipelineBindPoint = vk.PipelineBindPoint.graphics
		subpass.colorAttachmentCount = 1
		subpass.pColorAttachments = &color_att

		mut dependency := vk.SubpassDependency{}
		dependency.srcSubpass = vk.subpass_external
		dependency.dstSubpass = 0
		dependency.srcStageMask = vk.PipelineStageFlags(vk.PipelineStageFlagBits.color_attachment_output)
		dependency.dstStageMask = vk.PipelineStageFlags(vk.PipelineStageFlagBits.color_attachment_output)
		dependency.srcAccessMask = 0
		dependency.dstAccessMask = vk.AccessFlags(vk.AccessFlagBits.color_attachment_write)

		mut render_pass_ci := vk.RenderPassCreateInfo{}
		render_pass_ci.attachmentCount = 1
		render_pass_ci.pAttachments = &description_att
		render_pass_ci.subpassCount = 1
		render_pass_ci.pSubpasses = &subpass
		render_pass_ci.dependencyCount = 1
		render_pass_ci.pDependencies = &dependency

		res = vk.create_render_pass(device, &render_pass_ci, const_allocator, &wd.render_pass)
		assert res == vk.Result.success
	}

	// Create The Image Views
	mut image_view_ci := vk.ImageViewCreateInfo{}
	image_view_ci.viewType = vk.ImageViewType._2d
	image_view_ci.format = wd.surface_format.format
	image_view_ci.components.r = vk.ComponentSwizzle.r
	image_view_ci.components.g = vk.ComponentSwizzle.g
	image_view_ci.components.b = vk.ComponentSwizzle.b
	image_view_ci.components.a = vk.ComponentSwizzle.a
	image_range := vk.ImageSubresourceRange{
		aspectMask:     vk.ImageAspectFlags(vk.ImageAspectFlagBits.color)
		baseMipLevel:   0
		levelCount:     1
		baseArrayLayer: 0
		layerCount:     1
	}
	image_view_ci.subresourceRange = image_range
	for i in 0 .. wd.image_count {
		image_view_ci.image = wd.frames[i].backbuffer
		res = vk.create_image_view(device, &image_view_ci, const_allocator,
			&wd.frames[i].backbuffer_view)
		assert res == vk.Result.success
	}

	// Create Framebuffer
	if wd.use_dynamic_rendering == false {
		mut image_view_att := vk.ImageView(0)
		mut frame_buffer_ci := vk.FramebufferCreateInfo{}
		frame_buffer_ci.renderPass = wd.render_pass
		frame_buffer_ci.attachmentCount = 1
		frame_buffer_ci.pAttachments = &image_view_att
		frame_buffer_ci.width = wd.width
		frame_buffer_ci.height = wd.height
		frame_buffer_ci.layers = 1
		for i in 0 .. wd.image_count {
			image_view_att = wd.frames[i].backbuffer_view
			res = vk.create_framebuffer(device, &frame_buffer_ci, const_allocator,
				&wd.frames[i].framebuffer)
			assert res == vk.Result.success
		}
	}
}

// ImGui_ImplVulkanH_CreateWindowCommandBuffers
pub fn create_window_command_buffers(physical_device vk.PhysicalDevice, device vk.Device, wd &Window, queue_family u32, const_allocator &vk.AllocationCallbacks) {
	// Create Command Buffers
	mut res := vk.Result.error_unknown
	for i in 0 .. wd.image_count {
		mut command_pool_ci := vk.CommandPoolCreateInfo{}
		command_pool_ci.flags = 0
		command_pool_ci.queueFamilyIndex = queue_family
		res = vk.create_command_pool(device, &command_pool_ci, const_allocator,
			&wd.frames[i].command_pool)
		assert res == vk.Result.success

		mut command_buffer_ci := vk.CommandBufferAllocateInfo{}
		command_buffer_ci.commandPool = wd.frames[i].command_pool
		command_buffer_ci.level = vk.CommandBufferLevel.primary
		command_buffer_ci.commandBufferCount = 1
		res = vk.allocate_command_buffers(device, &command_buffer_ci, &wd.frames[i].command_buffer)
		assert res == vk.Result.success

		mut fence_ci := vk.FenceCreateInfo{}
		fence_ci.flags = vk.FenceCreateFlags(vk.FenceCreateFlagBits.signaled)
		res = vk.create_fence(device, &fence_ci, const_allocator, &wd.frames[i].fence)
		assert res == vk.Result.success
	}

	for i in 0 .. wd.semaphore_count {
		mut semaphore_ci := vk.SemaphoreCreateInfo{}
		res = vk.create_semaphore(device, &semaphore_ci, const_allocator,
			&wd.frame_semaphores[i].image_acquired_semaphore)
		assert res == vk.Result.success
		res = vk.create_semaphore(device, &semaphore_ci, const_allocator,
			&wd.frame_semaphores[i].render_complete_semaphore)
		assert res == vk.Result.success
	}
}

pub fn destroy_window(instance vk.Instance, device vk.Device, mut wd Window, const_allocator &vk.AllocationCallbacks) {
	vk.device_wait_idle(device)
	// Could wait on the Queue if we had the queue in wd-> (otherwise VulkanH functions can't use globals)
	// vk.queue_wait_idle(wd.queue)

	for i in 0 .. wd.image_count {
		destroy_frame(device, &wd.frames[i], const_allocator)
	}
	for i in 0 .. wd.semaphore_count {
		destroy_frame_semaphores(device, &wd.frame_semaphores[i], const_allocator)
	}
	wd.frames.clear()
	wd.frame_semaphores.clear()
	vk.destroy_render_pass(device, wd.render_pass, const_allocator)
	vk.destroy_swapchain_khr(device, wd.swapchain, const_allocator)
	vk.destroy_surface_khr(instance, wd.surface, const_allocator)

	wd = Window{}
}
