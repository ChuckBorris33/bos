# bootc-hooks Module

The `bootc-hooks` module provides a flexible way to run custom scripts at different stages of the system lifecycle, especially in relation to `bootc` image updates and switches.

## How It Works

This module sets up two separate `systemd` services to run scripts in different contexts:

-   `system-bootc-hooks.service`: Runs system-wide hooks as the `root` user.
-   `user-bootc-hooks.service`: Runs user-specific hooks as the logged-in user.

The core logic resides in two scripts:
-   `/usr/libexec/bootc-hooks/run-system-bootc-hooks.sh`
-   `/usr/libexec/bootc-hooks/run-user-bootc-hooks.sh`

Here's the execution flow for each service:

1.  The script retrieves the current booted image's name and digest using `bootc status --format yaml --booted`.
2.  It compares this with information from the previous boot, which is stored in a version file.
    -   The system service uses `/var/lib/bootc-hooks/version.yaml`.
    -   The user service uses `$HOME/.config/bootc-hooks/version.yaml`.
3.  Based on the comparison, the script triggers specific "hooks" by executing scripts located in predefined directories.

## Supported Hooks

The module organizes hooks by **scope** (`system` or `user`) and then by **event**. The three supported events are:

-   **`boot`**: Scripts for this event are executed on every single boot (for system) or login (for user).
-   **`update`**: These scripts run only when the digest of the `bootc` image has changed, indicating an image update has been applied.
-   **`switch`**: These scripts are triggered when the image name itself has changed, which happens when rebasing to a different image entirely.

Scripts are executed from the following directories within `/usr/libexec/bootc-hooks/`:
-   `system/boot/`
-   `system/update/`
-   `system/switch/`
-   `user/boot/`
-   `user/update/`
-   `user/switch/`

## Usage

To use this module, you need to enable it in your `recipe.yml` and configure which scripts to run for each hook. The module supports two contexts (`system` and `user`) and three events (`boot`, `update`, `switch`).

All your hook scripts should be placed in the `files/scripts/` directory. In your `recipe.yml`, you will specify which script file to run for each hook event.

### Example

Let's say you want to run a system script on every boot and a user-specific script when a user logs in.

1.  Add your scripts to the `files/scripts/` directory. For example:
    *   `files/scripts/system_boot.sh`
    *   `files/scripts/user_boot.sh`

2.  Configure the `bootc-hooks` module in your `recipe.yml` to execute these scripts:

    ```yaml
    modules:
      - type: bootc-hooks
        system:
          boot:
            # This script will run as root on every boot
            - system_boot.sh
        user:
          boot:
            # This script will run as the user on every login
            - user_boot.sh
    ```

During the image build process, the module will copy these scripts to the appropriate execution directories in `/usr/libexec/bootc-hooks/` and set up the `systemd` services to trigger them at the correct time.

## Debugging

The hooks are executed by the `system-bootc-hooks.service` and `user-bootc-hooks.service` `systemd` services. You can check their status and logs to debug your scripts.

### System Hooks

-   **Check service status**:
    ```bash
    systemctl status system-bootc-hooks.service
    ```
-   **View logs**:
    ```bash
    journalctl -u system-bootc-hooks.service
    ```

### User Hooks

-   **Check service status**:
    ```bash
    systemctl --user status user-bootc-hooks.service
    ```
-   **View logs**:
    ```bash
    journalctl --user -u user-bootc-hooks.service
    ```