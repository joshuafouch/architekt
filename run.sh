#!/bin/bash

###############################################################################################
#     ___              __    _ __       __   __                                               #
#    /   |  __________/ /_  (_) /____  / /__/ /_                                              #
#   / /| | / ___/ ___/ __ \/ / __/ _ \/ //_/ __/                                              #
#  / ___ |/ /  / /__/ / / / / /_/  __/ ,< / /_    a custom arch linux install by joshuafouch  #
# /_/  |_/_/   \___/_/ /_/_/\__/\___/_/|_|\__/    forked from typecraft-dev/crucible          #
#                                                                                             #
###############################################################################################

# error log file!! ####################################
exec 2> >(tee -a "architekt-install-errors.log")

# config variables ####################################
# main packages
INSTALL_PKGS=false

# install my apps
INSTALL_EXTRAS=false

# flatpak programs
INSTALL_FLATPAKS=false

# enabling services
ENABLE_SERVICES=false

# stowing dotfiles
STOW_DOTS=false

# config variables END #################################

# exit on any error
set -e

# source utility functions
source utils.sh

# print da logo
print_logo

# architekt configuration via flags #################################################

# install everything if no args
if [ $# -eq 0 ]; then
    INSTALL_PKGS=true
    INSTALL_EXTRAS=true
    INSTALL_FLATPAKS=true
    ENABLE_SERVICES=true
    STOW_DOTS=true
fi

while [[ $# -gt 0 ]]; do
    case $1 in
    -h | --help)
        showhelp
        exit 0
        ;;
    -a | --all)
        INSTALL_PKGS=true
        INSTALL_EXTRAS=true
        INSTALL_FLATPAKS=true
        ENABLE_SERVICES=true
        STOW_DOTS=true
        shift
        ;;
    -p | --packages)
        INSTALL_PKGS=true
        shift
        ;;
    -f | --flatpaks)
        INSTALL_FLATPAKS=true
        shift
        ;;
    -e | --extras)
        INSTALL_EXTRAS=true
        shift
        ;;
    -s | --services)
        ENABLE_SERVICES=true
        shift
        ;;
    -d | --dots)
        STOW_DOTS=true
        shift
        ;;
    *)
        echo "unknown option: $1"
        showhelp
        exit 0
        ;;
    esac
done

# architekt configuration via flags end #############################################

# if you want to install system utils and packages (from packages.conf)
if [[ "$INSTALLPKGS" == true ]]; then
    # Source the package list
    if [ ! -f "packages.conf" ]; then
        echo "error: packages.conf not found!"
        exit 1
    fi

    source packages.conf

    # update the system first
    echo "updating system..."
    sudo pacman -Syu --noconfirm
fi

print_logo
echo "setup complete!"
echo "error logs in architekt-install-errors.log"
echo "please reboot system to enter your environment"

# architekt END! #######################################################################
