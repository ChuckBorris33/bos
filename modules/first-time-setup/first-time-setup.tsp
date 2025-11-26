import "@typespec/json-schema";
using TypeSpec.JsonSchema;

model FlatpakRemote {
  /** The name of the flatpak remote. */
  name: string;
  /** The URL of the flatpak remote. */
  url: string;
  /** A list of application IDs to install from this remote. */
  apps?: string[];
}

model Brew {
  /** A list of formulae to install using brew. */
  formulae?: string[];
}

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

  /** The default shell to configure for the user. */
  shell?: string;

  /** The git repository for the dotfiles. */
  dotfiles_repo?: string;

  /** A list of flatpak remotes to configure. */
  flatpak_remotes?: FlatpakRemote[];

  /** Brew packages to install. */
  brew?: Brew;
}
