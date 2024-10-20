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

# Defaults
tildify() {
	if [[ $1 = $HOME/* ]]; then
		local replacement=\~/

		echo "${1/$HOME\//$replacement}"
	else
		echo "$1"
	fi
}

# ENV setup
GITHUB=${GITHUB-"https://github.com"}
LAND="https://dl.unyt.land"
github_repo="$GITHUB/unyt-org/deno"

# Logging
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

# Validate args
if [[ $# -gt 1 ]]; then
	error 'Too many arguments passed. You can only pass a specific tag of UIX to be installed. (e.g. "v0.1.4")'
fi

# Check for zip utility
if ! command -v unzip >/dev/null && ! command -v 7z >/dev/null; then
	error "Either unzip or 7z is required to install UIX." 1>&2
	exit 1
fi

# Detect target
case $platform in
	"Darwin x86_64") target="x86_64-apple-darwin" ;;
	"Darwin arm64") target="aarch64-apple-darwin" ;;
	"Linux aarch64") target="aarch64-unknown-linux-gnu" ;;
	'MINGW64'*) target="x86_64-pc-windows-msvc" ;;
	*) target="x86_64-unknown-linux-gnu" ;;
esac

if [[ $target = "darwin-x64" ]]; then
	# Is this process running in Rosetta?
	# redirect stderr to devnull to avoid error message when not running in Rosetta
	if [[ $(sysctl -n sysctl.proc_translated 2>/dev/null) = 1 ]]; then
		target=darwin-aarch64
		info "Your shell is running in Rosetta 2. Downloading Deno for UIX for $target instead."
	fi
fi

# get latest tag or use passed tag
if [ $# -eq 0 ]; then
	deno_version="$(curl -s $LAND)"
else
	release_uri="${LAND}/releases/$1/name"
	release_status=$(curl --write-out "%{http_code}" --silent --output /dev/null "$release_uri")
	echo $release_uri
	if [ "$release_status" != 200 ]; then
		error "The requested tag with the name '$1' could not be found. Please use a valid tag from ${LAND}/releases"
	fi
	deno_version=$1
fi

# prepare installation directory
deno_install="${UIX_INSTALL:-$HOME/.uix}"
bin_dir="$deno_install/bin"
exe="$bin_dir/deno"
if [ ! -d "$bin_dir" ]; then
	mkdir -p "$bin_dir"
fi

# download executable
deno_uri="${LAND}/download/${deno_version}/deno-${target}"

rm -f "$exe.zip"
curl --fail --location --progress-bar --output "$exe.zip" "$deno_uri" ||
	error "Failed to download deno for UIX from \"$deno_uri\""

# unzip executable
if command -v unzip >/dev/null; then
	unzip -oqd "$bin_dir" -o "$exe.zip"
else
	7z x -o"$bin_dir" -y "$exe.zip"
fi
rm "$exe.zip"

# give permissions
if [ -e "$exe" ]; then
	chmod +x "$exe" ||
		error 'Failed to set permissions on deno executable.'
else
	error "Deno executable not found at $exe"
fi

success "Deno for UIX was installed successfully to $Bold_Green$(tildify "$exe")"

# install UIX
## temp fix!
# $exe install --global --root "$deno_install" -f --import-map https://cdn.unyt.org/uix/importmap.json -Aq -n uix https://cdn.unyt.org/uix/run.ts
# success "UIX CLI was installed successfully"

# shell detection for persistent installation
refresh_command=''

tilde_bin_dir=$(tildify "$bin_dir")
quoted_install_dir=\"${deno_install//\"/\\\"}\"
if [[ $quoted_install_dir = \"$HOME/* ]]; then
	quoted_install_dir=${quoted_install_dir/$HOME\//\$HOME/}
fi

install_env=DENO_INSTALL
bin_env=\$$install_env/bin

case $(basename "$SHELL") in
fish)
	# Install completions, but we don't care if it fails
	SHELL=fish $exe completions &>/dev/null || :
	commands=(
		"set --export $install_env $quoted_install_dir"
		"set --export PATH $bin_env \$PATH"
	)

	fish_config=$HOME/.config/fish/config.fish
	tilde_fish_config=$(tildify "$fish_config")
	if [[ -w $fish_config ]]; then
		{
			echo -e "\n# Deno for UIX"

			for command in "${commands[@]}"; do
				echo "$command"
			done
		} >>"$fish_config"
		info "Added \"$tilde_bin_dir\" to \$PATH in \"$tilde_fish_config\""
		refresh_command="source $tilde_fish_config"
	else
		echo "Manually add the directory to $tilde_fish_config (or similar):"
		for command in "${commands[@]}"; do
			info_bold "  $command"
		done
	fi
	;;
	zsh)
	# Install completions, but we don't care if it fails
	SHELL=zsh $exe completions &>/dev/null || :

	commands=(
		"export $install_env=$quoted_install_dir"
		"export PATH=\"$bin_env:\$PATH\""
	)

	zsh_config=$HOME/.zshrc
	tilde_zsh_config=$(tildify "$zsh_config")

	if [[ -w $zsh_config ]]; then
		{
			echo -e "\n# Deno for UIX"
			for command in "${commands[@]}"; do
				echo "$command"
			done
		} >>"$zsh_config"

		info "Added \"$tilde_bin_dir\" to \$PATH in \"$tilde_zsh_config\""
		refresh_command="exec $SHELL"
	else
		echo "Manually add the directory to $tilde_zsh_config (or similar):"
		for command in "${commands[@]}"; do
			info_bold "  $command"
		done
	fi
	;;
	bash)
	# Install completions, but we don't care if it fails
	SHELL=bash $exe completions &>/dev/null || :
	commands=(
		"export $install_env=$quoted_install_dir"
		"export PATH=\"$bin_env:\$PATH\""
	)
	bash_configs=(
		"$HOME/.bashrc"
		"$HOME/.bash_profile"
	)

	if [[ ${XDG_CONFIG_HOME:-} ]]; then
		bash_configs+=(
			"$XDG_CONFIG_HOME/.bash_profile"
			"$XDG_CONFIG_HOME/.bashrc"
			"$XDG_CONFIG_HOME/bash_profile"
			"$XDG_CONFIG_HOME/bashrc"
		)
	fi

	set_manually=true
	for bash_config in "${bash_configs[@]}"; do
		tilde_bash_config=$(tildify "$bash_config")
		if [[ -w $bash_config ]]; then
			{
				echo -e "\n# Deno for UIX"
				for command in "${commands[@]}"; do
					echo "$command"
				done
			} >>"$bash_config"

			info "Added \"$tilde_bin_dir\" to \$PATH in \"$tilde_bash_config\""
			refresh_command="source $bash_config"
			set_manually=false
			break
		fi
	done

	if [[ $set_manually = true ]]; then
		echo "Manually add the directory to $tilde_bash_config (or similar):"
		for command in "${commands[@]}"; do
			info_bold "  $command"
		done
	fi
	;;
*)
	echo 'Manually add the directory to ~/.bashrc (or similar):'
	info_bold "  export $install_env=$quoted_install_dir"
	info_bold "  export PATH=\"$bin_env:\$PATH\""
	;;
esac

echo
info "To get started with UIX, run:"
echo

if [[ $refresh_command ]]; then
	info_bold "  $refresh_command"
fi

info_bold "  uix --init"
