# Uses local Git and ZIP fixtures to verify cache reuse, data preservation and hash checks.
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'windows_setup_tools.ps1')
$TestRoot = Join-Path ([IO.Path]::GetTempPath()) ('torus setup tests ' + [Guid]::NewGuid().ToString('N'))
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

    $ArchiveFile = Join-Path $TestRoot 'fixture.zip'
    $Payload = Join-Path $TestRoot 'tool.exe'
    'fixture executable' | Set-Content $Payload
    Compress-Archive -LiteralPath $Payload -DestinationPath $ArchiveFile
    $Extracted = Join-Path $TestRoot 'extracted'
    $Caught = ''
    try { Expand-WindowsSetupVerifiedArchive $ArchiveFile ('0' * 64) $Extracted } catch { $Caught = $_.Exception.Message }
    Assert-TT ($Caught.StartsWith('Download checksum mismatch')) 'Setup accepted a bad checksum.'
    Assert-TT (-not (Test-Path -LiteralPath $Extracted)) 'Bad download was extracted.'
    $Hash = (Get-FileHash -LiteralPath $ArchiveFile -Algorithm SHA256).Hash
    Get-WindowsSetupArchive 'https://example.invalid/not-downloaded' $Hash $ArchiveFile $Extracted 'tool.exe'
    Get-WindowsSetupArchive 'https://example.invalid/not-downloaded' $Hash $ArchiveFile $Extracted 'tool.exe'
    Assert-TT (Test-Path -LiteralPath (Join-Path $Extracted 'tool.exe')) 'Verified archive was not prepared.'

    $Unverified = Join-Path $TestRoot 'unverified extraction'
    New-Item -ItemType Directory $Unverified | Out-Null
    'keep me' | Set-Content (Join-Path $Unverified 'personal.txt')
    $Caught = ''
    try { Get-WindowsSetupArchive 'unused' $Hash $ArchiveFile $Unverified 'tool.exe' } catch { $Caught = $_.Exception.Message }
    Assert-TT ($Caught.StartsWith('Unverified tool directory')) 'Setup accepted an unverified directory.'
    Assert-TT ((Get-Content (Join-Path $Unverified 'personal.txt') -Raw).Trim() -eq 'keep me') 'Setup overwrote user files.'

    $MissingTool = Join-Path $TestRoot 'missing executable'
    $Caught = ''
    try { Get-WindowsSetupArchive 'unused' $Hash $ArchiveFile $MissingTool 'missing.exe' } catch { $Caught = $_.Exception.Message }
    Assert-TT ($Caught.StartsWith('Downloaded tool is missing')) 'Missing executable was accepted.'
    Assert-TT (-not (Test-Path -LiteralPath $MissingTool)) 'Failed extraction committed an incomplete cache.'
    Get-WindowsSetupArchive 'unused' $Hash $ArchiveFile $MissingTool 'tool.exe'

    Remove-Item -LiteralPath (Join-Path $Extracted 'tool.exe')
    $Caught = ''
    try { Get-WindowsSetupArchive 'unused' $Hash $ArchiveFile $Extracted 'tool.exe' } catch { $Caught = $_.Exception.Message }
    Assert-TT ($Caught.StartsWith('Incomplete or mismatched tool cache')) 'Damaged verified cache was reused.'
    Assert-TT (Test-Path -LiteralPath (Join-Path $MissingTool 'tool.exe')) 'Damaged-cache recovery changed a working cache.'

    $RetryArchive = Join-Path $TestRoot 'retry.zip'
    $RetryTool = Join-Path $TestRoot 'retry tool'
    function curl.exe {
        param([Parameter(ValueFromRemainingArguments = $true)] [string[]]$DownloadArguments)
        $OutputIndex = [Array]::IndexOf($DownloadArguments, '--output')
        [IO.File]::WriteAllText($DownloadArguments[$OutputIndex + 1], 'interrupted download')
        $global:LASTEXITCODE = 7
    }
    try {
        $Caught = ''
        try { Get-WindowsSetupArchive 'fixture' $Hash $RetryArchive $RetryTool 'tool.exe' } catch { $Caught = $_.Exception.Message }
        Assert-TT ($Caught -like '*failed with exit code 7*') 'Download failure was ignored.'
        Assert-TT (-not (Test-Path -LiteralPath $RetryArchive)) 'Partial download became a cached archive.'
        Assert-TT (-not (Test-Path -LiteralPath $RetryTool)) 'Partial download created an installed tool.'
        function curl.exe {
            param([Parameter(ValueFromRemainingArguments = $true)] [string[]]$DownloadArguments)
            $OutputIndex = [Array]::IndexOf($DownloadArguments, '--output')
            Copy-Item -LiteralPath $ArchiveFile -Destination $DownloadArguments[$OutputIndex + 1] -Force
            $global:LASTEXITCODE = 0
        }
        Get-WindowsSetupArchive 'fixture' $Hash $RetryArchive $RetryTool 'tool.exe'
        Assert-TT (Test-Path -LiteralPath (Join-Path $RetryTool 'tool.exe')) 'Retry did not recover an interrupted download.'
    } finally { Remove-Item -LiteralPath Function:curl.exe }

    $SavedPath = $env:PATH
    try {
        $env:PATH = ''
        $Caught = ''
        try { & (Join-Path $PSScriptRoot 'setup_windows.ps1') -Check } catch { $Caught = $_.Exception.Message }
        Assert-TT ($Caught -like 'Install git*rerun setup*') 'Missing Git did not explain recovery.'
    } finally { $env:PATH = $SavedPath }
    Write-Host 'Windows setup cache and checksum tests passed.'
} finally {
    $ResolvedTestRoot = [IO.Path]::GetFullPath($TestRoot)
    $TemporaryPrefix = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\') + '\'
    if (-not $ResolvedTestRoot.StartsWith($TemporaryPrefix, [StringComparison]::OrdinalIgnoreCase) -or
        [IO.Path]::GetFileName($ResolvedTestRoot) -notlike 'torus setup tests *') {
        throw "Refusing cleanup outside the test fixture: $ResolvedTestRoot"
    }
    if (Test-Path -LiteralPath $ResolvedTestRoot) { Remove-Item -LiteralPath $ResolvedTestRoot -Recurse -Force }
}
