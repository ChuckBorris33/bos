# bootc-hooks Module

The `bootc-hooks` module provides a flexible way to run custom scripts at different stages of the boot process, especially in relation to `bootc` image updates and switches.

## How It Works

This module sets up a systemd service (`bootc-hooks.service`) that runs on every boot after the network is online. The core logic is in the `/usr/libexec/bootc-hooks/run-bootc-hooks.sh` script.

Here's the execution flow:

1.  The script retrieves the current booted image and its digest using `bootc status --format yaml --booted`.
2.  It compares this information with the details from the previous boot, which are stored in `/var/lib/bootc-hooks/version.yaml`.
3.  Based on the comparison, it triggers specific "hooks" by executing scripts located in predefined directories.

## Supported Hooks

The module supports three types of hooks:

*   **`boot`**: Scripts in this hook are executed on *every single boot*.
*   **`update`**: These scripts run when the digest of the bootc image has changed, indicating an image update.
*   **`switch`**: These scripts are triggered when the image name itself has changed, which happens when switching to a different image entirely.

For each hook type, you can have a main script (e.g., `boot.sh`) or multiple scripts in a corresponding `.d` directory (e.g., `boot.d/`).

The script will execute the following, if they exist and are executable:

*   **On every boot:**
    *   `/usr/libexec/bootc-hooks/boot.sh`
    *   Scripts in `/usr/libexec/bootc-hooks/boot.d/`
*   **On image digest change:**
    *   `/usr/libexec/bootc-hooks/update.sh`
    *   Scripts in `/usr/libexec/bootc-hooks/update.d/`
*   **On image name change:**
    *   `/usr/libexec/bootc-hooks/switch.sh`
    *   Scripts in `/usr/libexec/bootc-hooks/switch.d/`

## Usage

To use this module, you need to place your custom scripts in the `files/bootc-hooks/` directory within your project. The module will automatically copy them to the appropriate location in `/usr/libexec/bootc-hooks/` and make them executable.

### Example

Let's say you want to run a script to pull your latest dotfiles using `yadm` on every boot.

1.  Create the script `files/bootc-hooks/boot.d/yadm_pull.sh`:

    ```bash
    #!/bin/bash
    
    # Ensure yadm is installed
    if ! command -v yadm &> /dev/null; then
        echo "yadm could not be found, installing..."
        rpm-ostree install yadm
    fi

    echo "Pulling latest dotfiles..."
    yadm pull
    ```

2.  Make sure the `bootc-hooks` module is enabled in your `recipe.yml`.

During the build, this script will be copied to `/usr/libexec/bootc-hooks/boot.d/yadm_pull.sh` in the final image. On every boot, the `bootc-hooks` service will execute it.