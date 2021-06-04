# winbox-linux-installer

This is a simple script to install Winbox - a Mikrotik's tool for managing RouterOS devices. This installer was inspiried by [mriza/winbox-installer](https://github.com/mriza/winbox-installer), but it installs the launcher and icons just for the user running the installation script to the XDG directories. This seemed like more sensible way of installing third party EXE files.

Bits and parts of this script was also put together from these inspirative sources:
- [How to write safe Bash script with perfect basic function](https://www.fatalerrors.org/a/0d111Dg.html)
- [https://github.com/jordansissel/sysadvent/blob/master/2009/08/cronhelper.sh](https://github.com/jordansissel/sysadvent/blob/master/2009/08/cronhelper.sh)
- [https://gist.github.com/montanaflynn/e1e754784749fd2aaca7](https://gist.github.com/montanaflynn/e1e754784749fd2aaca7)

Kudos to them :pray:

## Requirements

- `wine` (for Winbox runtime itself)
- `curl` (for downloading latest version of Winbox)
- xdg-utils package (for `xdg-desktop-menu` and `xdg-icon-resource`)

## Install

1. Clone the repository  
`mkdir ~/tmp && cd ~/tmp && git clone https://github.com/backslash/winbox-linux-installer.git`
2. Run the install script  
`cd winbox-linux-installer && ./install.sh`

You may select which flavour (32 or 64-bit) of Winbox you wish to install -
`./install.sh -f 32` or `./install.sh -f 64`.The script defaults to download the 64-bit flavour.

## Uninstall

Just remove the launcher, the binary and icons. Then refresh XDG resources. Like this:

```
find ~/.local/share/icons/hicolor -t f -name winbox.png -delete
rm -f ~/.local/bin/winbox.exe
rm -f ~/.local/share/applications/winbox.desktop
xdg-icon-resource forceupdate
xdg-desktop-menu forceupdate
```

