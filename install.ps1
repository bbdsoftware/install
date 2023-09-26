#!/usr/bin/env pwsh

$ErrorActionPreference = 'Stop'

$inputRepo = if ($repo) { "${repo}" } else { "${r}" }
$inputVersion = if ($version) { "${version}" } else { "${v}" }
$inputExe = if ($exe) { "${exe}" } else { "${e}" }

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-Error "gh is not installed. Visit https://github.com/cli/cli#installation for installation instructions."
    exit 1
}

$arr = $inputRepo.Split('/')
$owner = $arr.Get(0)
$repoName = $arr.Get(1)
$exeName = if ($inputExe) { "${inputExe}" } else { "${repoName}" }

if ([Environment]::Is64BitProcess) {
    $arch = "amd64"
} else {
    $arch = "386"
}

$BinDir = "$Home\bin"
$downloadedTagGz = "$BinDir\${exeName}.tar.gz"
$downloadedExe = "$BinDir\${exeName}.exe"
$Target = "windows_$arch"

# Fetch asset URL using 'gh' CLI
$ResourceUri = gh release download --repo "${owner}/${repoName}" -p "${exeName}_${Target}.tar.gz" --dir "$BinDir"

if (!(Test-Path $BinDir)) {
    New-Item $BinDir -ItemType Directory | Out-Null
}

if (Check-Command -Command tar) {
    Invoke-Expression "tar -xvzf $downloadedTagGz -C $BinDir"
} else {
    function Expand-Tar {
        param($tarFile, $dest)

        if (-not (Get-Command Expand-7Zip -ErrorAction Ignore)) {
            Install-Package -Scope CurrentUser -Force 7Zip4PowerShell > $null
        }

        Expand-7Zip $tarFile $dest
    }

    Expand-Tar $downloadedTagGz $BinDir
}

Remove-Item $downloadedTagGz

$User = [EnvironmentVariableTarget]::User
$Path = [Environment]::GetEnvironmentVariable('Path', $User)
if (!(";$Path;".ToLower() -like "*;$BinDir;*".ToLower())) {
    [Environment]::SetEnvironmentVariable('Path', "$Path;$BinDir", $User)
    $Env:Path += ";$BinDir"
}

Write-Output "${exeName} was installed successfully to $downloadedExe"
Write-Output "Run '${exeName} --help' to get started"

function Check-Command {
    param($Command)
    $found = $false
    try {
        $Command | Out-Null
        $found = $true
    } catch [System.Management.Automation.CommandNotFoundException] {
        $found = $false
    }

    $found
}
