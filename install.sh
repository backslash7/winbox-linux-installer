#!/usr/bin/env bash

set -Eeuo pipefail
trap cleanup SIGINT SIGTERM ERR EXIT

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

usage() {
    cat <<EOF
Usage: $(basename "${BASH_SOURCE[0]}") [-h] [-v] [-d] [-f <32|64>]

Installs Winbox into user's XDG paths.

Available options:

-h, --help                   Print this help and exit.
-v, --version                Print version information.
-d                           Print debugging information.
--no-color, --no-colour      Disable color output.
-f, --flavour                Choose which Winbox flavour to download. 
                             Defaults to 64-bit.
EOF
exit
}

version () {
    cat <<EOF
winbox-linux-installer 0.1
EOF
exit
}

cleanup() {
    trap - SIGINT SIGTERM ERR EXIT
    rm -f "${script_dir}/winbox.exe"
    rm -f "${script_dir}/winbox.desktop"
}

setup_colors() {
    if [[ -t 2 ]] && [[ -z "${NO_COLOR-}" ]] && [[ "${TERM-}" != "dumb" ]]; then
        NOFORMAT='\033[0m' RED='\033[0;31m' GREEN='\033[0;32m' ORANGE='\033[0;33m' BLUE='\033[0;34m' PURPLE='\033[0;35m' CYAN='\033[0;36m' YELLOW='\033[1;33m'
    else
        NOFORMAT='' RED='' GREEN='' ORANGE='' BLUE='' PURPLE='' CYAN='' YELLOW=''
    fi
}

msg() {
    echo >&2 -e "${1-}"
}

die() {
    local msg=$1
    local code=${2-1} # Defaults to exit code 1
    msg "${msg}"
    exit "${code}"
}

parse_params() {
    flavour="64"
    while :; do
        case "${1-}" in
            -h | --help) usage ;;
            -v | --version) version ;;
            -d | --debug) set -x ;;
            --no-color | --no-colour) NO_COLOR=1 ;;
            -f | --flavour)
                flavour="${2-}"
                shift
                ;;
            -?*) die "Unknown option: $1" ;;
            *) break ;;
        esac
        shift
    done
    
    if [ "${flavour}" != "32" ] && [ "${flavour}" != "64" ]
    then
        die "Unknown flavour: ${flavour}"
    fi

  return 0
}

check_for() {
    command -v "$1" >/dev/null 2>&1 || {
        die "[${RED}ERROR${NOFORMAT}] \`$1\` not found. Please, install suitable package."
    }
}

download_winbox() {
    local flavour="$1"
    if [ "${flavour}" = "32" ]
    then
        dl_url="https://mt.lv/winbox"
    else
        dl_url="https://mt.lv/winbox64"
    fi

    curl -L -o "${script_dir}/winbox.exe" -s "${dl_url}" >/dev/null 2>&1 || {
        die "[${RED}ERROR${NOFORMAT}] Download from \`${dl_url}\` failed."
    }

    if [ ! -s "${script_dir}/winbox.exe" ]
    then
        die "[${RED}ERROR${NOFORMAT}] Empty file downloaded \`from ${dl_url}\`."
    fi

    return 0
}

install_winbox() {
    install -D -t "${HOME}/.local/bin/" "${script_dir}/winbox.exe" >/dev/null 2>&1 || {
        die "[${RED}ERROR${NOFORMAT}] Error copying winbox.exe to its location."
    }

    return 0
}

install_icons() {
    for size in $(find assets/icons/winbox-*.png | cut -d"-" -f2 | cut -d"." -f1 | paste -sd ' ')
    do
        install -v -D "${script_dir}/assets/icons/winbox-${size}.png" "${HOME}/.local/share/icons/hicolor/${size}/apps/winbox.png" >/dev/null 2>&1 || {
            die "[${RED}ERROR${NOFORMAT}] Error installing to ${HOME}/.local/share/icons/hicolor/${size}/apps/winbox.png"
        }
    done

    return 0
}

install_launcher() {
    cat <<EOF > winbox.desktop
[Desktop Entry]
Name=Winbox
GenericName=Configuration tool for RouterOS
Comment=Configuration tool for RouterOS
Exec=env FREETYPE_PROPERTIES="truetype:interpreter-version=35" wine ${HOME}/.local/bin/winbox.exe
Icon=winbox
Terminal=false
Type=Application
StartupNotify=true
StartupWMClass=winbox.exe
Categories=Network;RemoteAccess;
Keywords=winbox;mikrotik;
EOF
    install -D -t "${HOME}/.local/share/applications/" "${script_dir}/winbox.desktop" >/dev/null 2>&1 || {
        die "[${RED}ERROR${NOFORMAT}] Error copying launcher to its location."
    }
    
    return 0
}

xdg_update() {
    xdg-icon-resource forceupdate >/dev/null 2>&1 || {
        die "[${RED}ERROR${NOFORMAT}] Error updating icon resources."
    }

    xdg-desktop-menu forceupdate >/dev/null 2>&1 || {
        die "[${RED}ERROR${NOFORMAT}] Error updating desktop menu."
    }

    return 0
}

parse_params "$@"
setup_colors
check_for "install"
check_for "curl"
check_for "wine"
check_for "xdg-desktop-menu"
check_for "xdg-icon-resource"
msg "[${GREEN}OK${NOFORMAT}] Dependencies checked"

download_winbox "$flavour" && msg "[${GREEN}OK${NOFORMAT}] Winbox downloaded"
install_winbox && msg "[${GREEN}OK${NOFORMAT}] Winbox installed"
install_icons && msg "[${GREEN}OK${NOFORMAT}] Icons installed"
install_launcher && msg "[${GREEN}OK${NOFORMAT}] Launcher installed"
xdg_update && msg "[${GREEN}OK${NOFORMAT}] XSD resources updated."
msg "All done, enjoy!"
