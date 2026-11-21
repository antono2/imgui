# Compatibility entry point for the V smoke check.
[CmdletBinding()]
param(
    [string]$DemoDirectory = '',
    [int]$Frames,
    [int]$TimeoutSeconds,
    [string]$CacheDirectory = ''
)
$ErrorActionPreference = 'Stop'
$Compiler = $env:V_BIN
if (-not $Compiler) {
    $Installed = Get-Command v.exe -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($Installed) { $Compiler = $Installed.Source }
}
if (-not $Compiler) {
    & (Join-Path $PSScriptRoot 'setup_windows.ps1') -PrepareOnly -CacheDirectory $CacheDirectory
    $Compiler = $env:V_BIN
}
$Arguments = @('run', (Join-Path $PSScriptRoot 'smoke_windows_demo.vsh'))
if ($DemoDirectory) { $Arguments += @('--demo-directory', $DemoDirectory) }
if ($PSBoundParameters.ContainsKey('Frames')) { $Arguments += @('--frames', $Frames.ToString()) }
if ($PSBoundParameters.ContainsKey('TimeoutSeconds')) { $Arguments += @('--timeout-seconds', $TimeoutSeconds.ToString()) }
& $Compiler @Arguments
if ($LASTEXITCODE -ne 0) { throw "Demo smoke check failed with exit code $LASTEXITCODE." }
