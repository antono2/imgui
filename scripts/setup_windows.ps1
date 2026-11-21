# Prepares the tested upstream V compiler and native environment before building the demo.
[CmdletBinding()]
param(
    [string]$CacheDirectory = '',
    [switch]$Check,
    [switch]$PrepareOnly,
    [switch]$Run
)
$ErrorActionPreference = 'Stop'
if (-not [Environment]::Is64BitProcess) { throw 'Use 64-bit PowerShell.' }
if (($Check -and ($PrepareOnly -or $Run)) -or ($PrepareOnly -and $Run)) {
    throw 'Choose one of -Check, -PrepareOnly or -Run.'
}
$ProjectDirectory = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot 'windows_setup_tools.ps1')
foreach ($Command in @('git', 'cmake')) {
    if (-not (Get-Command $Command -ErrorAction SilentlyContinue)) {
        throw "Install $Command and add it to PATH, then rerun setup."
    }
}
if (-not (Get-Command cl -ErrorAction SilentlyContinue) -or $env:VSCMD_ARG_TGT_ARCH -ne 'x64') {
    $VsWhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
    if (-not (Test-Path -LiteralPath $VsWhere)) {
        throw 'Install Visual Studio Build Tools with Desktop development with C++, then rerun setup.'
    }
    $InstallPath = & $VsWhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
    if ($LASTEXITCODE -ne 0 -or -not $InstallPath) { throw 'Visual Studio C++ tools were not found.' }
    Import-Module (Join-Path $InstallPath 'Common7\Tools\Microsoft.VisualStudio.DevShell.dll')
    Enter-VsDevShell -VsInstallPath $InstallPath -SkipAutomaticLocation -DevCmdArguments '-arch=x64 -host_arch=x64'
}
if (-not $env:VULKAN_SDK) {
    foreach ($Scope in @('User', 'Machine')) {
        $Sdk = [Environment]::GetEnvironmentVariable('VULKAN_SDK', $Scope)
        if ($Sdk) { $env:VULKAN_SDK = $Sdk; break }
    }
}
if (-not $env:VULKAN_SDK -or -not (Test-Path -LiteralPath (Join-Path $env:VULKAN_SDK 'Include\vulkan\vulkan.h'))) {
    throw 'Install the LunarG Vulkan SDK and set VULKAN_SDK to its directory.'
}
if ($Check) {
    Write-Host 'Native build prerequisites found. Setup will prepare the CI-tested upstream V compiler.'
    Write-Host 'Compiling ImGui/ImPlot bindings may require about 11 GiB of memory.'
    return
}
$PinFile = Join-Path $ProjectDirectory 'compatibility.json'
$Pins = Get-Content -LiteralPath $PinFile -Raw | ConvertFrom-Json
if ($Pins.schema_version -ne 1) { throw 'Unsupported compatibility manifest schema.' }
foreach ($Match in [regex]::Matches((Get-Content (Join-Path $ProjectDirectory 'v.mod') -Raw), "'antono2\.([a-z0-9_]+)@([^']+)'")) {
    if ($Pins.modules.($Match.Groups[1].Value) -ne $Match.Groups[2].Value) { throw 'v.mod and compatibility.json disagree.' }
}
if (-not $CacheDirectory) {
    $CacheKey = (Get-FileHash -LiteralPath $PinFile -Algorithm SHA256).Hash.Substring(0, 12).ToLowerInvariant()
    $CacheDirectory = Join-Path $env:LOCALAPPDATA "antono2\imgui\windows\$CacheKey"
}
$CacheDirectory = [IO.Path]::GetFullPath($CacheDirectory)
New-Item -ItemType Directory -Force -Path $CacheDirectory | Out-Null
$VDirectory = Join-Path $CacheDirectory 'v'
Get-WindowsSetupCheckout 'https://github.com/vlang/v.git' $Pins.v $VDirectory
Get-WindowsSetupCheckout 'https://github.com/vlang/vc.git' $Pins.vc (Join-Path $VDirectory 'vc')
Get-WindowsSetupCheckout 'https://github.com/vlang/tccbin.git' $Pins.tcc (Join-Path $VDirectory 'thirdparty\tcc')
$VExecutable = Join-Path $VDirectory 'v.exe'
if (-not (Test-Path -LiteralPath $VExecutable)) {
    Push-Location $VDirectory
    # Use the pinned bootstrap compiler, regardless of unrelated Clang/GCC
    # installations on PATH. The demo itself is compiled with MSVC below.
    try { Invoke-WindowsSetupCommand (Join-Path $VDirectory 'makev.bat') @('-tcc', '--local') } finally { Pop-Location }
}
$env:V_BIN = $VExecutable
$env:Path = "$VDirectory;$(Join-Path $env:VULKAN_SDK 'Bin');$env:Path"
if ($PrepareOnly) {
    Write-Host "Prepared upstream V compiler: $VExecutable"
    return
}
$Options = @('-cc', 'msvc', 'run', (Join-Path $PSScriptRoot 'setup_windows_demo.vsh'))
if ($Run) { $Options += '--run' }
Invoke-WindowsSetupCommand $VExecutable $Options
