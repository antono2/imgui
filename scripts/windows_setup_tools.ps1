# Checked Git checkouts used by the isolated Windows bootstrap.
function Invoke-WindowsSetupCommand([string]$Command, [string[]]$Arguments) {
    & $Command @Arguments
    if ($LASTEXITCODE -ne 0) { throw "$Command failed with exit code ${LASTEXITCODE}: $($Arguments -join ' ')" }
}

function Get-WindowsSetupCheckout([string]$Url, [string]$Revision, [string]$Directory) {
    if (-not (Test-Path -LiteralPath $Directory)) {
        $Staging = "$Directory.setup-$([Guid]::NewGuid().ToString('N'))"
        New-Item -ItemType Directory -Force -Path ([IO.Path]::GetDirectoryName([IO.Path]::GetFullPath($Directory))) | Out-Null
        try {
            Invoke-WindowsSetupCommand git @('-c', 'core.longpaths=true', 'clone', '--filter=blob:none', '--no-checkout', $Url, $Staging)
            Invoke-WindowsSetupCommand git @('-C', $Staging, 'fetch', '--depth', '1', 'origin', $Revision)
            Invoke-WindowsSetupCommand git @('-C', $Staging, 'checkout', '--detach', $Revision)
            [IO.Directory]::Move([IO.Path]::GetFullPath($Staging), [IO.Path]::GetFullPath($Directory))
        } catch {
            throw "Could not prepare ${Directory}. Retry setup; existing caches are preserved. $($_.Exception.Message)"
        } finally {
            Remove-WindowsSetupStagingDirectory $Staging $Directory
        }
    }
    if (-not (Test-Path -LiteralPath (Join-Path $Directory '.git'))) {
        throw "Existing directory is not a managed Git checkout: $Directory. Choose another -CacheDirectory."
    }
    $Head = & git -C $Directory rev-parse HEAD
    if ($LASTEXITCODE -ne 0) { throw "Cannot inspect checkout: $Directory" }
    $Expected = & git -C $Directory rev-parse --verify "$Revision^{commit}"
    if ($LASTEXITCODE -ne 0 -or $Head -ne $Expected) {
        throw "Checkout is not at the tested revision ${Revision}: $Directory. Choose another -CacheDirectory."
    }
    $Changes = & git -C $Directory status --porcelain
    if ($LASTEXITCODE -ne 0 -or $Changes) {
        throw "Preserve local changes in $Directory, or choose another -CacheDirectory."
    }
}

function Remove-WindowsSetupStagingDirectory([string]$Staging, [string]$Destination) {
    $Resolved = [IO.Path]::GetFullPath($Staging)
    $Target = [IO.Path]::GetFullPath($Destination)
    if ([IO.Path]::GetDirectoryName($Resolved) -ne [IO.Path]::GetDirectoryName($Target) -or
        -not ([IO.Path]::GetFileName($Resolved) -match ('^' + [regex]::Escape([IO.Path]::GetFileName($Target)) + '\.setup-[0-9a-f]{32}$'))) {
        throw "Refusing staging cleanup outside the tool cache: $Resolved"
    }
    if (Test-Path -LiteralPath $Resolved) { Remove-Item -LiteralPath $Resolved -Recurse -Force }
}
