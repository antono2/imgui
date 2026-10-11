# Checked downloads and Git checkouts used by the isolated Windows bootstrap.
function Invoke-WindowsSetupCommand([string]$Command, [string[]]$Arguments) {
    & $Command @Arguments
    if ($LASTEXITCODE -ne 0) { throw "$Command failed with exit code ${LASTEXITCODE}: $($Arguments -join ' ')" }
}

function Get-WindowsSetupCheckout([string]$Url, [string]$Revision, [string]$Directory) {
    if (-not (Test-Path -LiteralPath $Directory)) {
        Invoke-WindowsSetupCommand git @('-c', 'core.longpaths=true', 'clone', '--filter=blob:none', '--no-checkout', $Url, $Directory)
        Invoke-WindowsSetupCommand git @('-C', $Directory, 'fetch', '--depth', '1', 'origin', $Revision)
        Invoke-WindowsSetupCommand git @('-C', $Directory, 'checkout', '--detach', $Revision)
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
    if (-not (Test-Path -LiteralPath $Archive)) {
        Write-Host "Downloading $Url"
        $Download = "$Archive.download.zip"
        if (Get-Command curl.exe -ErrorAction SilentlyContinue) {
            Invoke-WindowsSetupCommand curl.exe @('--fail', '--location', '--retry', '3', '--connect-timeout', '30', '--max-time', '900', '--silent', '--show-error', '--output', $Download, $Url)
        } else {
            Invoke-WebRequest -UseBasicParsing -Uri $Url -OutFile $Download -TimeoutSec 120
        }
        if ((Get-FileHash -LiteralPath $Download -Algorithm SHA256).Hash -ne $Hash) {
            throw "Download checksum mismatch: $Url. Retry setup to download again."
        }
        Move-Item -LiteralPath $Download -Destination $Archive -Force
    }
    Expand-WindowsSetupVerifiedArchive $Archive $Hash $Directory
    if (-not (Test-Path -LiteralPath (Join-Path $Directory $Executable))) {
        throw "Downloaded tool is missing ${Executable}: $Directory"
    }
    $Hash | Set-Content -LiteralPath $Marker -Encoding ascii
}

# Install manifest-pinned repositories directly: old VPM versions refuse repeat
# installs into a VMODULES directory containing spaces, even at the right pin.
function Install-WindowsSetupModules([string]$ManifestDirectory, [string]$ModulesDirectory, [hashtable]$Checked) {
    $Manifest = Get-Content -LiteralPath (Join-Path $ManifestDirectory 'v.mod') -Raw
    foreach ($Match in [regex]::Matches($Manifest, "'antono2\.([a-z0-9_]+)@([^']+)'")) {
        $Name = $Match.Groups[1].Value
        $Tag = $Match.Groups[2].Value
        if ($Checked.ContainsKey($Name)) {
            if ($Checked[$Name] -ne $Tag) { throw "Conflicting dependency pins for $Name" }
            continue
        }
        $Checked[$Name] = $Tag
        $Repository = if ($Name -eq 'vkmemalloc') { 'vulkan_memory_allocator' } else { $Name }
        $Directory = Join-Path $ModulesDirectory "antono2\$Name"
        Get-WindowsSetupCheckout "https://github.com/antono2/$Repository.git" $Tag $Directory
        Install-WindowsSetupModules $Directory $ModulesDirectory $Checked
    }
}
