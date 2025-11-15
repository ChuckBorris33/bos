import "@typespec/json-schema";
using TypeSpec.JsonSchema;

@jsonSchema("/modules/bootc-hooks-latest.json")
model BootcHooksModuleLatest {
  ...BootcHooksModuleV1 
}

@jsonSchema("/modules/bootc-hooks-v1.json")
model BootcHooksModuleV1 {
  /** The bootc-hooks module adds service that checks if image was updated or switched and runs scripts accordingly.
   */
  type: "bootc-hooks" | "bootc-hooks@v1" | "bootc-hooks@latest";
}
