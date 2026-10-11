# Renders a bounded GLFW/Vulkan demo and checks its exit status and diagnostics.
[CmdletBinding()]
param(
    [string]$DemoDirectory = '',
    [ValidateRange(1, 10000)][int]$Frames = 60,
    [ValidateRange(1, 300)][int]$TimeoutSeconds = 60
)
$ErrorActionPreference = 'Stop'
if (-not $DemoDirectory) { $DemoDirectory = Join-Path (Split-Path -Parent $PSScriptRoot) 'build\windows-demo' }
$DemoDirectory = [IO.Path]::GetFullPath($DemoDirectory)
$Executable = Join-Path $DemoDirectory 'v_imgui_demo.exe'
if (-not (Test-Path -LiteralPath $Executable)) { throw "Build the demo first with scripts\setup_windows.ps1: $Executable" }
$OutputLog = Join-Path $DemoDirectory 'smoke-stdout.log'
$ErrorLog = Join-Path $DemoDirectory 'smoke-stderr.log'
$PreviousFrames = $env:VIMGUI_SMOKE_FRAMES
try {
    $env:VIMGUI_SMOKE_FRAMES = $Frames.ToString()
    $DemoProcess = Start-Process -FilePath $Executable -WorkingDirectory $DemoDirectory -WindowStyle Hidden -PassThru -RedirectStandardOutput $OutputLog -RedirectStandardError $ErrorLog
    # Retain the process handle before exit; Windows PowerShell 5 otherwise
    # sometimes loses ExitCode when Start-Process redirects output.
    $null = $DemoProcess.Handle
    if (-not $DemoProcess.WaitForExit($TimeoutSeconds * 1000)) {
        Stop-Process -Id $DemoProcess.Id -Force
        throw "Windows demo rendering timed out; inspect $OutputLog and $ErrorLog."
    }
    $Diagnostics = (Get-Content -LiteralPath $OutputLog, $ErrorLog -Raw) -join "`n"
    if ($Diagnostics) { Write-Host $Diagnostics }
    if ($DemoProcess.ExitCode -ne 0 -or $Diagnostics -match '(?i)VUID-|validation error|segmentation|assert|fatal') {
        throw "Windows demo rendering failed (exit $($DemoProcess.ExitCode)); inspect the smoke logs."
    }
    Write-Host "Windows GLFW/Vulkan demo rendered and shut down after $Frames frames."
} finally {
    $env:VIMGUI_SMOKE_FRAMES = $PreviousFrames
}
