import "@typespec/json-schema";
using TypeSpec.JsonSchema;

// --- Individual Module Configuration Models ---

model SetDefaultShellConfig {
  /** The default shell to configure for the user. */
  shell: string;
}

model CloneDotfilesConfig {
  /** The git repository for the dotfiles. */
  repo: string;
}

model FlatpakRemote {
  /** The name of the flatpak remote. */
  name: string;
  /** The URL of the flatpak remote. */
  url: string;
  /** A list of application IDs to install from this remote. */
  apps?: string[];
}

model InstallFlatpaksConfig {
  /** A list of flatpak remotes to configure. */
  remotes?: FlatpakRemote[];
}

model InstallBrewPackagesConfig {
  /** A list of formulae to install using brew. */
  formulae?: string[];
}

// --- Main Module Models ---

@jsonSchema("/modules/first-time-setup-latest.json")
model FirstTimeSetupModuleLatest {
  ...FirstTimeSetupModuleV1
}

@jsonSchema("/modules/first-time-setup-v1.json")
model FirstTimeSetupModuleV1 {
  /**
   * The first-time-setup module configures the system on first boot.
   */
  type: "first-time-setup" | "first-time-setup@v1" | "first-time-setup@latest";

  /** Configuration for the set_default_shell module. */
  set_default_shell?: SetDefaultShellConfig;
  /** Configuration for the clone_dotfiles module. */
  clone_dotfiles?: CloneDotfilesConfig;
  /** Configuration for the install_flatpaks module. */
  install_flatpaks?: InstallFlatpaksConfig;
  /** Configuration for the install_brew_packages module. */
  install_brew_packages?: InstallBrewPackagesConfig;
  /** Configuration for the install_tailscale module. Can be 'true' to enable. */
  setup_tailscale?: boolean;
  /** Configuration for the configure_git_identity module. Can be 'true' to enable. */
  configure_git_identity?: boolean;
   /** Configuration for the copy_cosmic_config module. Can be 'true' to enable. */
  copy_cosmic_config?: boolean;
   /** Configuration for the setup_ssh_and_github module. Can be 'true' to enable. */
  setup_ssh_and_github?: boolean;
}
