#!/bin/bash

# print the logo
print_logo() {
    cat <<"EOF"
    ___              __    _ __       __   __ 
   /   |  __________/ /_  (_) /____  / /__/ /_
  / /| | / ___/ ___/ __ \/ / __/ _ \/ //_/ __/  
 / ___ |/ /  / /__/ / / / / /_/  __/ ,< / /_    a custom arch linux install by joshuafouch
/_/  |_/_/   \___/_/ /_/_/\__/\___/_/|_|\__/    forked from typecraft-dev/crucible 
                                              
EOF
}

# help function
showhelp() {
    echo "usage: $0 [OPTION]"
    echo "options:"
    echo "  -h, --help                 display this help message"
    echo "  -a, --all                  install everything (DEFAULT)"
    echo "  -p, --packages             install all base packages"
    echo "  -f, --flatpaks             install flatpaks (like discord)"
    echo "  -e, --extras               install extra apps (like browser)"
    echo "  -s, --services             enable necessary services (like network)"
    echo "  -d, --dotfiles             symlinks to your dotfile configs (like in .config)"
    echo
}

# Function to check if a package is installed
is_installed() {
    pacman -Qi "$1" &>/dev/null
}

# Function to check if a package is installed
is_group_installed() {
    pacman -Qg "$1" &>/dev/null
}

# Function to install packages if not already installed
install_packages() {
    local packages=("$@")
    local to_install=()

    for pkg in "${packages[@]}"; do
        if ! is_installed "$pkg" && ! is_group_installed "$pkg"; then
            to_install+=("$pkg")
        fi
    done

    if [ ${#to_install[@]} -ne 0 ]; then
        echo "Installing: ${to_install[*]}"
        yay -S --noconfirm "${to_install[@]}"
    fi
}

# adding cider (an Apple Music player) to the pacman repository
add_cider() {
    # import GPG key:
    if ! pacman-key --list-keys A0CD6B993438E22634450CDD2A236C3F42A61682 &>/dev/null; then
        echo "Importing Cider GPG Key..."
        curl -s https://repo.cider.sh/ARCH-GPG-KEY | sudo pacman-key --add -
        sudo pacman-key --lsign-key A0CD6B993438E22634450CDD2A236C3F42A61682
    else
        echo "Cider GPG Key already added!"
    fi

    if ! grep -q "\[cidercollective\]" /etc/pacman.conf; then
        echo "Adding Cider into your pacman repository!"

        # add the repo to /etc/pacman.conf
        cat <<'EOF' | sudo tee -a /etc/pacman.conf

# Cider Collective Repository
[cidercollective]
SigLevel = Required TrustedOnly
Server = https://repo.cider.sh/arch
EOF

    else
        echo "Cider is already added in the pacman repository!"
    fi
}

# install yay AUR helper if not present
install_yay() {

    if ! command -v yay &>/dev/null; then
        echo "Installing yay AUR helper..."
        sudo pacman -S --needed git base-devel --noconfirm
        if [[ ! -d "yay" ]]; then
            echo "Cloning yay repository..."
        else
            echo "yay directory already exists, removing it..."
            rm -rf yay
        fi

        git clone https://aur.archlinux.org/yay.git

        cd yay
        echo "building yay.... yaaaaayyyyy"
        makepkg -si --noconfirm
        cd ..
        rm -rf yay
    else
        echo "yay is already installed"
    fi

}

# enable services
enable_services() {

    local services=("$@")

    if [ ${#services[@]} -eq 0 ]; then
        echo "no args given"
        return
    fi

    echo "configuring services..."
    for service in "${SERVICES[@]}"; do
        if ! systemctl is-enabled "$service" &>/dev/null; then
            echo "enabling $service..."
            sudo systemctl enable "$service"
        else
            echo "$service is already enabled"
        fi
    done
}

# install flatpaks
install_flatpacks() {

    local flatpaks=("$@")

    if [ ${#flatpaks[@]} -eq 0 ]; then
        echo "no args given"
        return
    fi

    for pak in "${flatpaks[@]}"; do
        if ! flatpak list | grep -i "$pak" &>/dev/null; then
            echo "installing flatpak: $pak"
            flatpak install --noninteractive "$pak"
        else
            echo "flatpak already installed: $pak"
        fi
    done

}

# stow dotfiles
stow_dotfiles() {

    ORIGINAL_DIR=$(pwd)
    REPO_URL="https://github.com/joshuafouch/dotfiles"
    REPO_NAME="dotfiles"

    if ! is_installed stow; then
        echo "installing dependency (GNU Stow)..."
        yay -S --noconfirm stow
    fi

    cd ~

    # Check if the repository already exists
    if [ -d "$REPO_NAME" ]; then
        echo "repository '$REPO_NAME' already exists. skipping clone"
    else
        git clone "$REPO_URL"
    fi

    # Check if the clone was successful
    if [ $? -eq 0 ]; then
        cd "$REPO_NAME"
        stow i3
        stow zsh
        stow nvim
        stow rofi
        stow polybar
        stow dunst
        stow fastfetch
        stow git
        stow kitty
        stow yazi
        stow cava
        # add other essential dotfiles here
    else
        echo "failed to clone the repository."
        exit 1
    fi

}
