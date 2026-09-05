$ErrorActionPreference = "Stop"
$Missing = $false

foreach ($Command in @("v", "git", "cmake", "cl", "vulkaninfo")) {
    if (Get-Command $Command -ErrorAction SilentlyContinue) {
        Write-Host "[ok]      $Command"
    } else {
        Write-Host "[missing] $Command"
        $Missing = $true
    }
}

if (-not $env:VULKAN_SDK) {
    Write-Host "[missing] VULKAN_SDK environment variable"
    $Missing = $true
} elseif (-not (Test-Path (Join-Path $env:VULKAN_SDK "Include\vulkan\vulkan.h"))) {
    Write-Host "[failed]  Vulkan headers not found under VULKAN_SDK"
    $Missing = $true
} else {
    Write-Host "[ok]      VULKAN_SDK=$env:VULKAN_SDK"
}

if (-not $env:GLFW_INCLUDE) {
    Write-Host "[missing] GLFW_INCLUDE environment variable"
    $Missing = $true
} else {
    Write-Host "[ok]      GLFW_INCLUDE=$env:GLFW_INCLUDE"
}

if (-not $env:GLFW_LIB) {
    Write-Host "[missing] GLFW_LIB environment variable"
    $Missing = $true
} else {
    Write-Host "[ok]      GLFW_LIB=$env:GLFW_LIB"
}

if ($Missing) {
    throw "One or more requirements are unavailable. See QUICKSTART.md."
}
Write-Host "Dear ImGui build prerequisites look usable."
