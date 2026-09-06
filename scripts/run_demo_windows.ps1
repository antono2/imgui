param(
    [switch]$BuildOnly,
    [switch]$NativeOnly
)

$ErrorActionPreference = "Stop"
$RepositoryDirectory = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
$RepositoryParent = Split-Path -Parent $RepositoryDirectory
$DemoRevision = "5673324866e9825e217dfd1927145250d60f9e84"
$DemoDirectory = Join-Path $RepositoryDirectory "build\v_imgui_examples"
$NativeBuildDirectory = Join-Path $RepositoryDirectory "build\shared-bundled-3.4"
$RuntimeDirectory = Join-Path $RepositoryDirectory "build\windows-demo"

& (Join-Path $RepositoryDirectory "scripts\check_windows.ps1") -BundledGlfw

if (Test-Path (Join-Path $RepositoryDirectory ".git")) {
    & git -C $RepositoryDirectory submodule update --init --recursive
    if ($LASTEXITCODE -ne 0) { throw "Could not initialise ImGui submodules." }
}

& v run (Join-Path $RepositoryDirectory "build_vimgui.vsh") --linkage shared --glfw bundled --glfw-version 3.4
if ($LASTEXITCODE -ne 0) { throw "Could not build the native ImGui library." }

if ($NativeOnly) {
    Write-Host "Built and checked the Windows native libraries."
    exit 0
}

foreach ($Module in @("vulkan", "glfw")) {
    & v install "https://github.com/antono2/$Module"
    if ($LASTEXITCODE -ne 0) { throw "Could not install the $Module V module." }
}

if (-not (Test-Path (Join-Path $DemoDirectory ".git"))) {
    & git clone https://github.com/antono2/v_imgui_examples.git $DemoDirectory
    if ($LASTEXITCODE -ne 0) { throw "Could not clone v_imgui_examples." }
}
& git -C $DemoDirectory fetch --quiet origin $DemoRevision
if ($LASTEXITCODE -ne 0) { throw "Could not fetch the tested demo revision." }
& git -C $DemoDirectory checkout --quiet --detach $DemoRevision
if ($LASTEXITCODE -ne 0) { throw "Could not check out the tested demo revision." }

$GlfwHeader = Get-ChildItem $NativeBuildDirectory -Recurse -Filter "glfw3.h" |
    Where-Object { $_.FullName -match "glfw-src.*include.GLFW" } | Select-Object -First 1
$GlfwImportLibrary = Get-ChildItem $NativeBuildDirectory -Recurse -Include "glfw3dll.lib", "glfw3.lib" |
    Select-Object -First 1
$GlfwDll = Get-ChildItem $NativeBuildDirectory -Recurse -Filter "glfw3.dll" | Select-Object -First 1
$VimguiDll = Get-ChildItem (Join-Path $RepositoryDirectory "lib") -Recurse -Filter "vimgui.dll" |
    Select-Object -First 1
$VimguiImportLibrary = Get-ChildItem (Join-Path $RepositoryDirectory "lib") -Recurse -Filter "vimgui.lib" |
    Select-Object -First 1

foreach ($Artifact in @{
    "GLFW header" = $GlfwHeader
    "GLFW import library" = $GlfwImportLibrary
    "GLFW DLL" = $GlfwDll
    "vimgui import library" = $VimguiImportLibrary
    "vimgui DLL" = $VimguiDll
}.GetEnumerator()) {
    if (-not $Artifact.Value) { throw "The native build did not produce $($Artifact.Key)." }
}

$LinkDirectory = Join-Path $RuntimeDirectory "link"
New-Item -ItemType Directory -Force $LinkDirectory | Out-Null
Copy-Item $GlfwImportLibrary.FullName (Join-Path $LinkDirectory "glfw3.lib") -Force
$env:GLFW_INCLUDE = Split-Path -Parent (Split-Path -Parent $GlfwHeader.FullName)
$env:GLFW_LIB = $LinkDirectory

$Executable = Join-Path $RuntimeDirectory "v_imgui_demo.exe"
$ModulePath = "$RepositoryParent|@vlib|@vmodules"
& v -no-memory-limit -path $ModulePath -cc msvc -cflags /MT -o $Executable $DemoDirectory
if ($LASTEXITCODE -ne 0) {
    throw "The demo did not compile. Update V and review QUICKSTART.md for current requirements."
}

Copy-Item $VimguiDll.FullName $RuntimeDirectory -Force
Copy-Item $GlfwDll.FullName $RuntimeDirectory -Force
Write-Host "Built $Executable"

if (-not $BuildOnly) {
    & $Executable
    if ($LASTEXITCODE -ne 0) { throw "The demo exited with code $LASTEXITCODE." }
}
