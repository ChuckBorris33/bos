import "@typespec/json-schema";
using TypeSpec.JsonSchema;

@jsonSchema("/modules/brew-install-latest.json")
model BrewModuleLatest {
  ...BrewInstallModuleV1;
}

@jsonSchema("/modules/brew-install-v1.json")
model BrewInstallModuleV1 {
  /** BrewInstall module install selected brew packages at sustem boot
   */
  type: "brew-install" | "brew-install@v1" | "brew-install@latest";
  /** options to be used with brew install*/
  options?: string[];
  /** packages to be installed*/
  install: string[];
}
