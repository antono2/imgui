# Uses local Git fixtures to verify compiler-cache reuse and data preservation.
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'windows_setup_tools.ps1')
$TestRoot = Join-Path ([IO.Path]::GetTempPath()) ('imgui setup tests ' + [Guid]::NewGuid().ToString('N'))
function Assert-TT([bool]$Condition, [string]$Message) {
    if (-not $Condition) { throw $Message }
}
try {
    New-Item -ItemType Directory -Path $TestRoot | Out-Null
    $Origin = Join-Path $TestRoot 'local origin'
    Invoke-WindowsSetupCommand git @('init', $Origin)
    'first revision' | Set-Content (Join-Path $Origin 'sample.txt')
    Invoke-WindowsSetupCommand git @('-C', $Origin, 'add', 'sample.txt')
    Invoke-WindowsSetupCommand git @('-C', $Origin, '-c', 'user.name=Setup Test', '-c', 'user.email=test@example.invalid', 'commit', '-m', 'fixture')
    $Revision = & git -C $Origin rev-parse HEAD
    $Checkout = Join-Path $TestRoot 'cache with spaces'
    Get-WindowsSetupCheckout $Origin $Revision $Checkout
    Get-WindowsSetupCheckout $Origin $Revision $Checkout
    'local changes' | Set-Content (Join-Path $Checkout 'sample.txt')
    $Caught = ''
    try { Get-WindowsSetupCheckout $Origin $Revision $Checkout } catch { $Caught = $_.Exception.Message }
    Assert-TT ($Caught.StartsWith('Preserve local changes')) 'Setup did not reject local changes.'
    Assert-TT ((Get-Content (Join-Path $Checkout 'sample.txt') -Raw).Trim() -eq 'local changes') 'Setup overwrote local changes.'
    $Caught = ''
    try { Get-WindowsSetupCheckout $Origin '0000000000000000000000000000000000000000' $Checkout } catch { $Caught = $_.Exception.Message }
    Assert-TT ($Caught.StartsWith('Checkout is not at the tested revision')) 'Setup accepted the wrong revision.'
    Assert-TT ((& git -C $Checkout rev-parse HEAD) -eq $Revision) 'Wrong-revision check moved HEAD.'

    $RetryCheckout = Join-Path $TestRoot 'retry checkout'
    $Caught = ''
    try { Get-WindowsSetupCheckout (Join-Path $TestRoot 'missing origin') $Revision $RetryCheckout } catch { $Caught = $_.Exception.Message }
    Assert-TT ($Caught -like '*Retry setup*') 'Failed clone did not explain recovery.'
    Assert-TT (-not (Test-Path -LiteralPath $RetryCheckout)) 'Failed clone committed an incomplete cache.'
    Get-WindowsSetupCheckout $Origin $Revision $RetryCheckout

    $SavedPath = $env:PATH
    try {
        $env:PATH = ''
        $Caught = ''
        try { & (Join-Path $PSScriptRoot 'setup_windows.ps1') -Check } catch { $Caught = $_.Exception.Message }
        Assert-TT ($Caught -like 'Install git*rerun setup*') 'Missing Git did not explain recovery.'
    } finally { $env:PATH = $SavedPath }
    Write-Host 'Windows compiler-cache tests passed.'
} finally {
    $ResolvedTestRoot = [IO.Path]::GetFullPath($TestRoot)
    $TemporaryPrefix = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\') + '\'
    if (-not $ResolvedTestRoot.StartsWith($TemporaryPrefix, [StringComparison]::OrdinalIgnoreCase) -or
        [IO.Path]::GetFileName($ResolvedTestRoot) -notlike 'imgui setup tests *') {
        throw "Refusing cleanup outside the test fixture: $ResolvedTestRoot"
    }
    if (Test-Path -LiteralPath $ResolvedTestRoot) { Remove-Item -LiteralPath $ResolvedTestRoot -Recurse -Force }
}
