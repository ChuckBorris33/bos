# Install applications via Homebrew
[group('Apps')]
install-default-brew:
    #!/usr/bin/env bash
    echo "Installing applications via Homebrew..."
    brew bundle --file /usr/share/ublue-os/homebrew/default.Brewfile

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
