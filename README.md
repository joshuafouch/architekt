# architekt 🛠️

an arch linux system tool that automates the setup and configuration of an arch linux system with i3wm. it installs and configures packages, desktop environments, and various utilities to create a fully functional development environment.

## features

- you like to "rice" your arch linux? is it hard and tedious work? well architekt does everything for you. it installs dependencies and packages, enables services, adds your personal configuration files, and other such cool things that are super cool like that.
- yeah, that's about it for the features.

## prerequisites

- a fresh arch linux installation
- internet connection
- sudo privileges
- that's it

## installation

1. clone this repository:

```bash
git clone https://github.com/joshuafouch/architekt.git
```

2. change directory into architekt with:

```bash
cd architekt
```

3. thats how to install. easy.

## usage

1. run the setup script:

```bash
./run.sh
```

2. you can set different flags to do things you want to do...

| Flag               | Description                                 |
| ------------------ | ------------------------------------------- |
| `-h`, `--help`     | Display this help message                   |
| `-a`, `--all`      | Install everything (default)                |
| `-p`, `--packages` | Install all base packages                   |
| `-f`, `--flatpaks` | Install flatpaks (like Discord)             |
| `-e`, `--extras`   | Install extra apps (like a browser)         |
| `-s`, `--services` | Enable necessary services (like networking) |
| `-d`, `--dotfiles` | Symlink your dotfile configs                |
