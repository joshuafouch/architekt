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
    echo "  --dry-run                  for testing script without executing install commands"
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

# Function to see if user wants to install a certain program
wants_to_install() {

    local pkg="$1"

    if [[ "$DRY_RUN" == true ]]; then
        while true; do
            echo ""
            read -rp "[DRY-RUN] Would you like to install ${pkg} [Y/n]: " ans
            case "${ans,,}" in
            y | "") return 0 ;; # install
            n) return 1 ;;      # skip
            *) echo "[DRY-RUN] please answer 'y' or 'n'. " ;;
            esac
        done
    else
        while true; do
            echo ""
            read -rp "Would you like to install  ${pkg} [Y/n]: " ans
            case "${ans,,}" in
            y | "") return 0 ;; # install
            n) return 1 ;;      # skip
            *) echo "please answer 'y' or 'n'. " ;;
            esac
        done
    fi
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
        if [[ "$DRY_RUN" == true ]]; then
            echo "[DRY-RUN] skipping installs"
        else
            yay -S --noconfirm "${to_install[@]}"
        fi
    else
        if [[ "$DRY_RUN" == true ]]; then
            echo "all packages already installed: ${packages[*]}"
        else
            echo "all packages already installed!"
        fi
    fi
}

# adding cider (an Apple Music player) to the pacman repository
add_cider() {

    # if dry run
    if [[ "$DRY_RUN" == true ]]; then
        echo "[DRY-RUN] Would import Cider's GPG key"
        echo "[DRY-RUN] Would Append Cider data into /etc/pacman.conf"
        return
    fi

    # import GPG key:
    if ! pacman-key --list-keys A0CD6B993438E22634450CDD2A236C3F42A61682 &>/dev/null; then
        echo "importing cider gpg key..."
        curl -s https://repo.cider.sh/ARCH-GPG-KEY | sudo pacman-key --add -
        sudo pacman-key --lsign-key A0CD6B993438E22634450CDD2A236C3F42A61682
    else
        echo "cider gpg key already added!"
    fi

    if ! grep -q "\[cidercollective\]" /etc/pacman.conf; then
        echo "adding cider into your pacman repository"

        # add the repo to /etc/pacman.conf
        cat <<'EOF' | sudo tee -a /etc/pacman.conf

# Cider Collective Repository
[cidercollective]
SigLevel = Required TrustedOnly
Server = https://repo.cider.sh/arch
EOF

    else
        echo "cider is already added in the pacman repository!"
    fi
}

# install yay aur helper if not present
install_yay() {

    # if dry run
    if [ "$DRY_RUN" == true ]; then
        echo "[DRY-RUN] Would check if yay is installed and install it"
        if ! command -v yay &>/dev/null; then

            if [[ ! -d "yay" ]]; then
                echo "  would need to clone yay repo: https://aur.archlinux.org/yay.git"
                echo "  would build yay package and then remove the yay repository"
            else
                echo "  there is a yay directory in this system but yay is not a command, this directory will be removed"
            fi

        else
            echo "  yay is already installed in this system"
        fi
        return
    fi

    if ! command -v yay &>/dev/null; then
        echo "installing yay aur helper..."
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
    for service in "${services[@]}"; do

        if [ "$DRY_RUN" == true ]; then
            echo "[DRY-RUN] Would enable service: $service"
        else
            if ! systemctl is-enabled "$service" &>/dev/null; then
                echo "enabling $service..."
                sudo systemctl enable "$service"
            else
                echo "$service is already enabled"
            fi
        fi

    done
}

# install flatpaks
install_flatpaks() {

    local flatpaks=("$@")

    if [ ${#flatpaks[@]} -eq 0 ]; then
        echo "no args given"
        return
    fi

    echo "installing flatpaks..."

    for pak in "${flatpaks[@]}"; do

        if [ "$DRY_RUN" == true ]; then
            echo "[DRY-RUN] Would install: $pak"
        else
            if ! flatpak list | grep -i "$pak" &>/dev/null; then
                echo "installing flatpak: $pak"
                flatpak install --noninteractive "$pak"
            else
                echo "flatpak already installed: $pak"
            fi
        fi

    done

}

interactive_yay() {

    local programs=("$@")

    if [ ${#programs[@]} -eq 0 ]; then
        echo "no args given"
        return
    fi

    echo "interactive install session start..."

    for prog in "${programs[@]}"; do

        if [ "$DRY_RUN" == true ]; then
            if wants_to_install "$prog"; then
                echo "--> would install $prog..."
            else
                echo "--> would skip $prog"
            fi
        else
            if wants_to_install "$prog"; then
                echo "--> installing $prog..."
                yay -S --noconfirm "$prog"
            else
                echo "--> skipping $prog"
            fi
        fi

    done

}

interactive_flathub() {

    local programs=("$@")

    if [ ${#programs[@]} -eq 0 ]; then
        echo "no args given"
        return
    fi

    echo "interactive install session start..."

    for prog in "${programs[@]}"; do

        if [ "$DRY_RUN" == true ]; then
            if wants_to_install "$prog"; then
                echo "--> would install $prog..."
            else
                echo "--> would skip $prog"
            fi
        else
            if wants_to_install "$prog"; then
                echo "--> installing $prog..."
                flatpak install --noninteractive "$prog"
            else
                echo "--> skipping $prog"
            fi
        fi

    done

}

# stow dotfiles
stow_dotfiles() {

    ORIGINAL_DIR=$(pwd)
    REPO_URL="https://github.com/joshuafouch/dotfiles"
    REPO_NAME="dotfiles"

    if [ "$DRY_RUN" == true ]; then
        echo "[DRY-RUN] Would check/install GNU Stow"
        echo "[DRY-RUN] Would clone $REPO_URL if not present"
        echo "[DRY-RUN] Would stow your all configurations."
        return
    fi
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
        echo "stowing i3..."
        stow i3

        echo "stowing zsh..."
        stow zsh

        echo "stowing nvim..."
        stow nvim

        echo "stowing rofi..."
        stow rofi

        echo "stowing polybar..."
        stow polybar

        echo "stowing dunst..."
        stow dunst

        echo "stowing fastfetch..."
        stow fastfetch

        echo "stowing git..."
        stow git

        echo "stowing kitty..."
        stow kitty

        echo "stowing yazi..."
        stow yazi

        echo "stowing cava..."
        stow cava
        # add other essential dotfiles here
    else
        echo "failed to clone the repository."
        exit 1
    fi

}
