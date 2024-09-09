#!/usr/bin/env pwsh
# Copyright (C) 2024 unyt.org <webmaster@unyt.org>
# All rights reserved. MIT license.
# Usage: install.ps1 <optional tag>

$ErrorActionPreference = 'Stop'

if ($v) {
	$Version = "v${v}"
}
if ($Args.Length -eq 1) {
	$Version = $Args.Get(0)
}

$DenoInstall = $env:DENO_INSTALL
$BinDir = if ($DenoInstall) {
	"${DenoInstall}\bin"
} else {
	"${Home}\.uix\bin"
}

$DenoZip = "$BinDir\deno.zip"
$DenoExe = "$BinDir\deno.exe"
$Target = 'x86_64-pc-windows-msvc'

$Version = if (!$Version) {
	curl.exe -s "https://dl.unyt.land"  
} else {
	$Version
}

$DownloadUrl = "https://dl.unyt.land/download/${Version}/deno-${Target}"

if (!(Test-Path $BinDir)) {
	New-Item $BinDir -ItemType Directory | Out-Null
}

curl.exe -Lo $DenoZip $DownloadUrl
tar.exe xf $DenoZip -C $BinDir
Remove-Item $DenoZip

$User = [System.EnvironmentVariableTarget]::User
$Path = [System.Environment]::GetEnvironmentVariable('Path', $User)
if (!(";${Path};".ToLower() -like "*;${BinDir};*".ToLower())) {
	[System.Environment]::SetEnvironmentVariable('Path', "${Path};${BinDir}", $User)
	$Env:Path += ";${BinDir}"
}

if (Test-Path $DenoExe) {
	& $DenoExe install -f --global --root "$BinDir" --import-map https://cdn.unyt.org/uix/importmap.json -Aq -n uix https://cdn.unyt.org/uix/run.ts
	Write-Output "Deno for UIX was installed successfully to ${DenoExe}"
	Write-Output "Run 'uix --init' to get started"
} else {
	Write-Output "Error: Deno executable not found at $DenoExe"
}