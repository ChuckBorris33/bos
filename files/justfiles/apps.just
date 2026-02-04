# Install applications via Homebrew
[group('Apps')]
install-default-brew:
    #!/usr/bin/env bash
    if ! command -v brew &> /dev/null; then
        echo "Homebrew not found, installing..."
        # The installation script will ask for sudo password.
        NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

        # Add brew to path for this session
        if [ -x "/home/linuxbrew/.linuxbrew/bin/brew" ]; then
            eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
        else
            echo "Failed to find brew after installation." >&2
            exit 1
        fi
    fi

    if ! command -v brew &> /dev/null; then
        echo "Brew is not available in PATH after attempting installation." >&2
        exit 1
    fi

    echo "Installing applications via Homebrew..."
    brew bundle --file /usr/share/brewfiles/default.Brewfile

[group('Apps')]
install-default-flatpaks:
    #!/usr/bin/bash
    echo "Installing default Flatpak applications..."
    bluebuild-flatpak-manager apply all

# Install a Flatpak application from Flathub
[group('Apps')]
install-flatpak APP_ID:
    #!/usr/bin/bash
    echo "Installing {{ APP_ID }} from Flathub..."
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    flatpak install -y flathub {{ APP_ID }}
