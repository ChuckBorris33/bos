# Brewfile Module

This module copies specified `Brewfile` files to `/usr/local/etc/brewfiles` and can optionally validate them. This is useful for ensuring that Homebrew packages are managed consistently within the image.

## Usage

To use this module, add it to your `recipe.yml`. You need to provide a list of `Brewfile` names to be included. These files should be located in a `brewfiles` directory alongside your `recipe.yml`.

### Example

1.  Create a `brewfiles` directory in your project:
    ```
    - brewfiles/
      - Brewfile.base
      - Brewfile.workstation
    - recipe.yml
    ```

2.  Add the module to your `recipe.yml`:
    ```yaml
    modules:
      - type: brewfiles
        # A list of Brewfile names from the 'brewfiles' directory
        include:
          - Brewfile.base
          - Brewfile.workstation
        # If true, runs 'brew bundle check' for each file
        validate: true
    ```

## How It Works

The module performs the following actions:

1.  Reads the `include` list from your configuration.
2.  Copies each specified `Brewfile` from `files/brewfiles/` into `/usr/local/etc/brewfiles/`.
3.  If `validate` is set to `true`, it will run `brew bundle check --file=<path>` for each Brewfile to verify that all dependencies are listed correctly.
