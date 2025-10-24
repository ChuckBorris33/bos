# `brew-install`

The `brew-install` module can be used to install Homebrew packages on every boot.

## Features

- Installs Homebrew packages on every boot using a systemd service.
- Allows specifying command-line options for the `brew install` command.

## Configuration

The `brew-install` module configuration allows you to specify Homebrew packages to install and command-line options to use with the `brew install` command.
Multiple usages of this module can be combined, each with different options.

### Options

The `options:` property is a list of command-line options to pass to the `brew install` command. This is optional.

### Install

The `install:` property is a list of Homebrew packages to install. This is required.

### Example

```yaml
type: brew-install
options:
  - "--force"
install:
  - uv
  - zellij
```

In this example, the `brew install` command will be executed with the `--force` option, and the `uv` and `zellij` packages will be installed.

### Notes

The module creates a script `/usr/libexec/bluebuild/brew-install` that is executed by a systemd timer on boot.
The systemd service and timer files are copied from the `post-boot` directory within the module's directory.
The module uses `jq` to parse the JSON configuration.
