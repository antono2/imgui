// Select Mesa's CPU Vulkan driver for deterministic Linux render checks.
module tooling

import arrays
import os

const lavapipe_manifests = ['/usr/share/vulkan/icd.d/lvp_icd.x86_64.json',
	'/usr/share/vulkan/icd.d/lvp_icd.json']

pub fn use_lavapipe() ! {
	icd := arrays.find_first(lavapipe_manifests, os.is_file) or {
		return error('Install Mesa Lavapipe to run the Vulkan rendering check.')
	}
	os.setenv('VK_DRIVER_FILES', icd, true)
	os.setenv('VK_ICD_FILENAMES', icd, true)
}
