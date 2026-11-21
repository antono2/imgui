# Checked downloads and Git checkouts used by the isolated Windows bootstrap.
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

function Expand-WindowsSetupVerifiedArchive([string]$Archive, [string]$Hash, [string]$Directory) {
    if ((Get-FileHash -LiteralPath $Archive -Algorithm SHA256).Hash -ne $Hash) {
        throw "Download checksum mismatch: $Archive. Remove this cached archive and retry."
    }
    Expand-Archive -LiteralPath $Archive -DestinationPath $Directory -Force
}

function Get-WindowsSetupArchive([string]$Url, [string]$Hash, [string]$Archive, [string]$Directory, [string]$Executable) {
    $ProgressPreference = 'SilentlyContinue'
    $Marker = Join-Path $Directory '.archive-sha256'
    if (Test-Path -LiteralPath $Marker) {
        if ((Get-Content -LiteralPath $Marker -Raw).Trim() -ne $Hash -or
            -not (Test-Path -LiteralPath (Join-Path $Directory $Executable))) {
            throw "Incomplete or mismatched tool cache: $Directory. Choose another -CacheDirectory."
        }
        return
    }
    if (Test-Path -LiteralPath $Directory) {
        throw "Unverified tool directory: $Directory. Preserve its contents and choose another -CacheDirectory."
    }
    if (-not (Test-Path -LiteralPath $Archive)) {
        Write-Host "Downloading $Url"
        $Download = "$Archive.download.zip"
        try {
            if (Get-Command curl.exe -ErrorAction SilentlyContinue) {
                Invoke-WindowsSetupCommand curl.exe @('--fail', '--location', '--retry', '3', '--connect-timeout', '30', '--max-time', '900', '--silent', '--show-error', '--output', $Download, $Url)
            } else {
                Invoke-WebRequest -UseBasicParsing -Uri $Url -OutFile $Download -TimeoutSec 120
            }
        } catch {
            throw "Download failed for ${Url}. Retry setup; existing installed tools are preserved. $($_.Exception.Message)"
        }
        if ((Get-FileHash -LiteralPath $Download -Algorithm SHA256).Hash -ne $Hash) {
            throw "Download checksum mismatch: $Url. Retry setup to download again."
        }
        Move-Item -LiteralPath $Download -Destination $Archive -Force
    }
    $Staging = "$Directory.setup-$([Guid]::NewGuid().ToString('N'))"
    try {
        Expand-WindowsSetupVerifiedArchive $Archive $Hash $Staging
        if (-not (Test-Path -LiteralPath (Join-Path $Staging $Executable))) {
            throw "Downloaded tool is missing ${Executable}: $Archive. Check the archive/pin before retrying."
        }
        $Hash | Set-Content -LiteralPath (Join-Path $Staging '.archive-sha256') -Encoding ascii
        [IO.Directory]::Move([IO.Path]::GetFullPath($Staging), [IO.Path]::GetFullPath($Directory))
    } finally {
        Remove-WindowsSetupStagingDirectory $Staging $Directory
    }
}
