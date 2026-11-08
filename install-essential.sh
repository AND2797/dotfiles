#!/usr/bin/env bash
# install essential cli tools on macOS or linux.
#
#   ./install-essential.sh            install
#   ./install-essential.sh --dry-run  check urls, paths and tools; install nothing
#
# linux: pinned github release binaries into ~/.local (no sudo)
# macOS: homebrew (must already be installed)
# both:  miniconda into ~/miniconda3
#
# a tool is skipped when the pinned version is already on PATH.
# output is also written to logs/install-essential-<timestamp>[-dryrun].log

set -euo pipefail

FZF_VERSION="0.74.5"
RG_VERSION="15.2.0"
NVIM_VERSION="0.12.6"
MINICONDA_VERSION="py314_26.9.4-0"

usage() {
	echo "usage: $0 [--dry-run]"
	echo "  --dry-run  check urls, paths and required tools; download and install nothing"
}

DRY_RUN=0
case "${1:-}" in
	"") ;;
	--dry-run) DRY_RUN=1 ;;
	-h | --help) usage; exit 0 ;;
	*) usage; exit 1 ;;
esac

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
LOCAL_BIN="$HOME/.local/bin"
LOCAL_OPT="$HOME/.local/opt"
CONDA_DIR="$HOME/miniconda3"

LOG_DIR="$REPO_DIR/logs"
LOG_SUFFIX=""
if [ "$DRY_RUN" = 1 ]; then LOG_SUFFIX="-dryrun"; fi
LOG_FILE="$LOG_DIR/install-essential-$(date +%Y%m%d-%H%M%S)$LOG_SUFFIX.log"
mkdir -p "$LOG_DIR"
exec > >(tee -a "$LOG_FILE") 2>&1

# ---------------------------------------------------------------- helpers

SUMMARY=()
CHECKS=()
FAILURES=0
CURRENT_STEP=""

run() {
	if [ "$DRY_RUN" = 1 ]; then
		echo "  + would run: $*"
	else
		echo "  + $*"
		"$@"
	fi
}

on_error() {
	echo
	echo "!! failed during: ${CURRENT_STEP:-setup}"
	echo "!! log: $LOG_FILE"
}
trap on_error ERR

# check <FAIL|warn> <name> <cmd...>: run cmd quietly, record ok or level
check() {
	local level="$1" name="$2" result="ok"
	shift 2
	if ! "$@" >/dev/null 2>&1; then
		result="$level"
		[ "$level" = "FAIL" ] && FAILURES=$((FAILURES + 1))
	fi
	echo "  [$result] $name"
	CHECKS+=("$(printf '[%-4s] %s' "$result" "$name")")
}

check_url() {
	check FAIL "url $1" curl -fsIL -o /dev/null "$1"
}

# mark <install|skip> <location> [detail]
mark() {
	local action="$1"
	LOCATION="$2"
	if [ "$DRY_RUN" = 1 ]; then
		STATUS="would $action"
	else
		STATUS="${action/skip/skipp}ed"
	fi
	[ -n "${3:-}" ] && STATUS="$STATUS ($3)"
	return 0
}

# step <name> <version> <function>
step() {
	local name="$1" version="$2" fn="$3"
	CURRENT_STEP="$name"
	echo
	echo "==> $name $version ($OS $ARCH)"
	local start=$SECONDS
	STATUS="" LOCATION=""
	"$fn"
	local elapsed=$((SECONDS - start))
	echo "  $STATUS: $LOCATION (${elapsed}s)"
	SUMMARY+=("$(printf '%-10s %-28s %-45s %ss' "$name" "$STATUS" "$LOCATION" "$elapsed")")
}

# first line of `<cmd> --version`, or empty if not on PATH
found_version() {
	command -v "$1" >/dev/null 2>&1 || return 0
	"$1" --version 2>/dev/null | head -1
}

# make a temp dir (placeholder in dry run), sets TMP_DIR
make_tmp() {
	if [ "$DRY_RUN" = 1 ]; then
		TMP_DIR="<tmp>"
	else
		TMP_DIR="$(mktemp -d)"
	fi
}

# download_tarball <url>: extracts into a temp dir, sets TMP_DIR
download_tarball() {
	make_tmp
	run curl -fsSL "$1" -o "$TMP_DIR/download.tar.gz"
	run tar -xzf "$TMP_DIR/download.tar.gz" -C "$TMP_DIR"
}

# ---------------------------------------------------------------- platform

case "$(uname -s)" in
	Linux) OS="linux" ;;
	Darwin) OS="macos" ;;
	*) echo "unsupported os: $(uname -s)"; exit 1 ;;
esac

case "$(uname -m)" in
	x86_64 | amd64) ARCH="x86_64" ;;
	aarch64 | arm64) ARCH="arm64" ;;
	*) echo "unsupported arch: $(uname -m)"; exit 1 ;;
esac

print_system_info() {
	echo "==> system"
	if [ "$DRY_RUN" = 1 ]; then
		echo "  mode:      dry run (nothing will be downloaded or installed)"
	fi
	if [ "$OS" = "linux" ]; then
		echo "  os:        $(. /etc/os-release && echo "$PRETTY_NAME")"
		echo "  cpu:       $(lscpu | sed -n 's/^Model name: *//p') ($(nproc) cores)"
		echo "  memory:    $(awk '/MemTotal/ {printf "%.1f GiB", $2/1024/1024}' /proc/meminfo)"
		if command -v apt >/dev/null 2>&1; then
			echo "  pkg mgr:   apt"
		fi
	else
		echo "  os:        $(sw_vers -productName) $(sw_vers -productVersion) ($(sw_vers -buildVersion))"
		echo "  cpu:       $(sysctl -n machdep.cpu.brand_string) ($(sysctl -n hw.ncpu) cores)"
		echo "  memory:    $(($(sysctl -n hw.memsize) / 1024 / 1024 / 1024)) GiB"
		if command -v brew >/dev/null 2>&1; then
			echo "  pkg mgr:   $(brew --version | head -1)"
		else
			echo "  pkg mgr:   homebrew not found"
		fi
	fi
	echo "  kernel:    $(uname -sr)"
	echo "  arch:      $(uname -m)"
	echo "  disk free: $(df -h "$HOME" | awk 'NR==2 {print $4 " of " $2}') at $HOME"
	echo "  user:      $(whoami)@$(hostname)"
	echo "  shell:     ${SHELL:-unknown}"
	echo "  date:      $(date)"
	echo "  log:       $LOG_FILE"
}

# ---------------------------------------------------------------- preflight

# writable <path>: nearest existing ancestor of path is writable
writable() {
	local p="$1"
	while [ ! -e "$p" ]; do p="$(dirname "$p")"; done
	[ -w "$p" ]
}

# local_bin_first: ~/.local/bin is on PATH and comes before /usr/bin
local_bin_first() {
	local dir
	local IFS=:
	for dir in $PATH; do
		[ "$dir" = "$LOCAL_BIN" ] && return 0
		[ "$dir" = "/usr/bin" ] && return 1
	done
	return 1
}

preflight() {
	CURRENT_STEP="preflight"
	echo
	echo "==> preflight"
	local cmd
	for cmd in curl tar install mktemp; do
		check FAIL "command $cmd" command -v "$cmd"
	done
	if [ "$OS" = "macos" ]; then
		check FAIL "command brew" command -v brew
	else
		check FAIL "writable $LOCAL_BIN" writable "$LOCAL_BIN"
		check FAIL "writable $LOCAL_OPT" writable "$LOCAL_OPT"
		check warn "$LOCAL_BIN on PATH before /usr/bin" local_bin_first
	fi
	check FAIL "writable $(dirname "$CONDA_DIR")" writable "$(dirname "$CONDA_DIR")"
}

# ---------------------------------------------------------------- installers

# brew_install <formula> <binary>
brew_install() {
	local formula="$1" bin="$2"
	[ "$DRY_RUN" = 1 ] && check FAIL "brew formula $formula" brew info "$formula"
	if brew list --versions "$formula" >/dev/null 2>&1; then
		mark skip "$(command -v "$bin" || true)" "$(brew list --versions "$formula")"
		return
	fi
	run brew install "$formula"
	if [ "$DRY_RUN" = 1 ]; then
		mark install "$(brew --prefix)/bin/$bin"
	else
		mark install "$(command -v "$bin" || true)" "$(brew list --versions "$formula")"
	fi
}

install_fzf() {
	if [ "$OS" = "macos" ]; then brew_install fzf fzf; return; fi

	local asset_arch="amd64"
	[ "$ARCH" = "arm64" ] && asset_arch="arm64"
	local url="https://github.com/junegunn/fzf/releases/download/v$FZF_VERSION/fzf-$FZF_VERSION-linux_$asset_arch.tar.gz"
	[ "$DRY_RUN" = 1 ] && check_url "$url"

	local found
	found="$(found_version fzf)"
	if [[ "$found" == "$FZF_VERSION "* ]]; then
		mark skip "$(command -v fzf)" "already $FZF_VERSION"
		return
	fi
	[ -n "$found" ] && echo "  found $(command -v fzf) at ${found%% *}, installing pinned $FZF_VERSION"

	download_tarball "$url"
	run mkdir -p "$LOCAL_BIN"
	run install -m 755 "$TMP_DIR/fzf" "$LOCAL_BIN/fzf"
	run rm -rf "$TMP_DIR"
	mark install "$LOCAL_BIN/fzf"
}

install_rg() {
	if [ "$OS" = "macos" ]; then brew_install ripgrep rg; return; fi

	local target="x86_64-unknown-linux-musl"
	[ "$ARCH" = "arm64" ] && target="aarch64-unknown-linux-gnu"
	local name="ripgrep-$RG_VERSION-$target"
	local url="https://github.com/BurntSushi/ripgrep/releases/download/$RG_VERSION/$name.tar.gz"
	[ "$DRY_RUN" = 1 ] && check_url "$url"

	local found
	found="$(found_version rg)"
	if [[ "$found" == "ripgrep $RG_VERSION"* ]]; then
		mark skip "$(command -v rg)" "already $RG_VERSION"
		return
	fi
	[ -n "$found" ] && echo "  found $(command -v rg) at $found, installing pinned $RG_VERSION"

	download_tarball "$url"
	run mkdir -p "$LOCAL_BIN"
	run install -m 755 "$TMP_DIR/$name/rg" "$LOCAL_BIN/rg"
	run rm -rf "$TMP_DIR"
	mark install "$LOCAL_BIN/rg"
}

install_nvim() {
	if [ "$OS" = "macos" ]; then brew_install neovim nvim; return; fi

	local name="nvim-linux-$ARCH"
	local dest="$LOCAL_OPT/nvim-$NVIM_VERSION"
	local url="https://github.com/neovim/neovim/releases/download/v$NVIM_VERSION/$name.tar.gz"
	[ "$DRY_RUN" = 1 ] && check_url "$url"

	local found
	found="$(found_version nvim)"
	if [ "$found" = "NVIM v$NVIM_VERSION" ]; then
		mark skip "$(command -v nvim)" "already $NVIM_VERSION"
		return
	fi
	[ -n "$found" ] && echo "  found $(command -v nvim) at $found, installing pinned $NVIM_VERSION"

	download_tarball "$url"
	run mkdir -p "$LOCAL_OPT" "$LOCAL_BIN"
	run rm -rf "$dest"
	run mv "$TMP_DIR/$name" "$dest"
	run ln -sfn "$dest/bin/nvim" "$LOCAL_BIN/nvim"
	run rm -rf "$TMP_DIR"
	mark install "$LOCAL_BIN/nvim -> $dest"
}

install_miniconda() {
	local platform=""
	case "$OS-$ARCH" in
		linux-x86_64) platform="Linux-x86_64" ;;
		linux-arm64) platform="Linux-aarch64" ;;
		macos-arm64) platform="MacOSX-arm64" ;;
	esac
	local url="https://repo.anaconda.com/miniconda/Miniconda3-$MINICONDA_VERSION-$platform.sh"

	if [ -z "$platform" ]; then
		echo "  no miniconda $MINICONDA_VERSION build for $OS $ARCH"
		if [ "$DRY_RUN" = 1 ]; then
			check FAIL "miniconda build for $OS $ARCH" false
			mark install "$CONDA_DIR" "no build for $OS $ARCH"
			return
		fi
		return 1
	fi
	[ "$DRY_RUN" = 1 ] && check_url "$url"

	if [ -d "$CONDA_DIR" ]; then
		mark skip "$CONDA_DIR" "$("$CONDA_DIR/bin/conda" --version 2>/dev/null || echo "dir exists")"
		return
	fi

	make_tmp
	run curl -fsSL "$url" -o "$TMP_DIR/miniconda.sh"
	run bash "$TMP_DIR/miniconda.sh" -b -p "$CONDA_DIR"
	run rm -rf "$TMP_DIR"
	# zsh conda setup lives in dotfiles/zsh/.zshrc (portable); bashrc is per-machine
	run "$CONDA_DIR/bin/conda" init bash
	if [ "$DRY_RUN" = 1 ]; then
		mark install "$CONDA_DIR"
	else
		mark install "$CONDA_DIR" "$("$CONDA_DIR/bin/conda" --version)"
	fi
}

# ---------------------------------------------------------------- main

TOTAL_START=$SECONDS
print_system_info
preflight

if [ "$DRY_RUN" = 0 ] && [ "$FAILURES" -gt 0 ]; then
	echo
	echo "!! $FAILURES preflight check(s) failed, nothing installed. see above."
	echo "!! log: $LOG_FILE"
	exit 1
fi

step fzf "$FZF_VERSION" install_fzf
step ripgrep "$RG_VERSION" install_rg
step neovim "$NVIM_VERSION" install_nvim
step miniconda "$MINICONDA_VERSION" install_miniconda

echo
echo "==> summary ($((SECONDS - TOTAL_START))s total)"
printf '  %-10s %-28s %-45s %s\n' tool status location time
for row in "${SUMMARY[@]}"; do
	echo "  $row"
done
echo
echo "  checks:"
for row in "${CHECKS[@]}"; do
	echo "  $row"
done
echo
echo "log: $LOG_FILE"

if [ "$FAILURES" -gt 0 ]; then
	echo "!! $FAILURES check(s) failed"
	exit 1
fi
