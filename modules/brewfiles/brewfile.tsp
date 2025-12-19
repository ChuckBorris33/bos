import "@typespec/json-schema";
using TypeSpec.JsonSchema;

@jsonSchema("/modules/brewfiles-latest.json")
model BrewfilesModuleLatest {
  ...BrewfilesModuleV1
}

@jsonSchema("/modules/brewfiles-v1.json")
model BrewfilesModuleV1 {
  /**
   * The brewfile module copies Brewfiles to the system for installation.
   */
  type: "brewfiles" | "brewfiles@v1" | "brewfiles@latest";
  /** A list of Brewfile names to include. */
  include: string[];
}
