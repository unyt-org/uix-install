#!/usr/bin/env bash
# Copyright (C) 2024 unyt.org <webmaster@unyt.org>
# All rights reserved. MIT license.
# Usage: install.sh <optional tag>
set -eo pipefail

platform=$(uname -ms)

if [ "$OS" = "Windows_NT" ]; then
	if [[ $platform != MINGW64* ]]; then
		powershell -c "irm https://raw.githubusercontent.com/unyt-org/uix-install/main/install.ps1|iex"
		exit $?
	fi
fi

# colors
Color_Off=''
Red=''
Green=''
Dim=''
Bold_White=''
Bold_Green=''

if [[ -t 1 ]]; then
	Color_Off='\033[0m'
	Red='\033[0;31m'
	Green='\033[0;32m'
	Dim='\033[0;2m'
	Bold_Green='\033[1;32m'
	Bold_White='\033[1m'
fi

error() {
	echo -e "${Red}error${Color_Off}:" "$@" >&2
	exit 1
}
info() {
	echo -e "${Dim}$@ ${Color_Off}"
}
info_bold() {
	echo -e "${Bold_White}$@ ${Color_Off}"
}
success() {
	echo -e "${Green}$@ ${Color_Off}"
}

if ! command -v unzip >/dev/null && ! command -v 7z >/dev/null; then
	error "Either unzip or 7z is required to install Deno for UIX." 1>&2
	exit 1
fi

if [[ $# -gt 1 ]]; then
	error 'Too many arguments passed. You can only pass a specific tag of deno for UIX to be installed. (e.g. "v0.1.4")'
fi

case $platform in
	"Darwin x86_64") target="x86_64-apple-darwin" ;;
	"Darwin arm64") target="aarch64-apple-darwin" ;;
	"Linux aarch64") target="aarch64-unknown-linux-gnu" ;;
	'MINGW64'*) target="x86_64-pc-windows-msvc" ;;
	*) target="x86_64-unknown-linux-gnu" ;;
esac

if [ $# -eq 0 ]; then
	deno_version="$(curl -s https://dl.unyt.land)"
else
	deno_version=$1
fi

deno_uri="https://dl.unyt.land/releases/${deno_version}"
echo $deno_uri
echo $target