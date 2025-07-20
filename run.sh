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

# dry run for testing
DRY_RUN=false

# config variables END #################################

# exit on any error
set -e

# export DRY_RUN variable for use in utils.sh
export DRY_RUN

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
    --dry-run)
        DRY_RUN=true
        # if user does not specify any other flag, set all flags to true
        #INSTALL_PKGS=true
        #INSTALL_EXTRAS=true
        #INSTALL_FLATPAKS=true
        #ENABLE_SERVICES=true
        #STOW_DOTS=true
        shift
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

# if user picks one of these three options, a system update is needed
if [[ "$INSTALL_PKGS" == true || "$INSTALL_EXTRAS" == true || "$INSTALL_FLATPAKS" == true ]]; then

    echo "updating system..."
    if [[ "$DRY_RUN" == true ]]; then
        echo "[DRY-RUN] sudo pacman -Syu --noconfirm"
    else

        # if user chooses to install extras, make sure needed GPG keys are imported
        if [[ "$INSTALL_EXTRAS" == true ]]; then
            add_cider
        fi

        # update the system first
        sudo pacman -Syu --noconfirm
        echo "system update over!"
    fi

fi

# if user picks one of these two options, the yay aur must be installed
if [[ "$INSTALL_PKGS" == true || "$INSTALL_EXTRAS" == true ]]; then

    if [[ "$DRY_RUN" == true ]]; then
        echo "[DRY-RUN] would download the yay AUR"
        install_yay
    else
        # install yay aur
        install_yay
    fi

fi

# if you want to install system utils and packages (from packages.conf)
if [[ "$INSTALL_PKGS" == true ]]; then
    # source the package list
    if [ ! -f "packages.conf" ]; then
        echo "error: packages.conf not found!"
        exit 1
    fi

    source packages.conf

    # install packages (see function in utils.sh)
    echo "installing system utilities..."
    install_packages "${SYS_UTILS[@]}"

    echo "installing dev utilies..."
    install_packages "${DEV_UTILS[@]}"

    echo "installing desktop utilies..."
    install_packages "${DESKTOP_UTILS[@]}"

    echo "installing fonts..."
    install_packages "${FONTS[@]}"

    echo "installing necessities..."
    install_packages "${ESSENTIALS[@]}"

fi

# if you want to install your extra apps (from extras.conf)
if [[ "$INSTALL_EXTRAS" == true ]]; then

    # source the app list
    if [ ! -f "extras.conf" ]; then
        echo "error: extras.conf not found!"
        exit 1
    fi

    source extras.conf

    # install extra apps
    echo "installing extra applications..."
    interactive_yay "${EXTRAS[@]}"

fi

# if you want to install your flatpak packages (from flatpaks.conf)
if [[ "$INSTALL_FLATPAKS" == true ]]; then
    # source the app list
    if [ ! -f "flatpaks.conf" ]; then
        echo "error: flatpaks.conf not found!"
        exit 1
    fi

    source flatpaks.conf

    interactive_flathub "${FLATPAKS[@]}"

fi

# if you want to enable specified services (from services.conf)
if [[ "$ENABLE_SERVICES" == true ]]; then
    # source the app list
    if [ ! -f "services.conf" ]; then
        echo "error: services.conf not found!"
        exit 1
    fi

    source services.conf

    # enable service function
    enable_services "${SERVICES[@]}"

fi

# if you want to stow your dotfiles from your git repo (see stow_dotfiles() in utils.sh)
if [[ "$STOW_DOTS" == true ]]; then

    # stow ur dotfiles
    stow_dotfiles

fi

echo ""
echo "setup complete!"
echo ""
echo "error logs in architekt-install-errors.log"
echo "NOTE: to show XFCE-settings-manager in rofi, comment the OnlyShowIn=XFCE line in /usr/share/applications/xfce-settings-manager.desktop"
echo "NOTE: to enable a desktop manager, you must use systemctl enable"
echo ""
echo "please reboot system to enter your environment"

# architekt END! #######################################################################
