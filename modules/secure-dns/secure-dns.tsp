import "@typespec/json-schema";
using TypeSpec.JsonSchema;

@jsonSchema("/modules/secure-boot-latest.json")
model SecureBootModuleLatest {
  ...SecureBootModuleV1 
}

@jsonSchema("/modules/secure-boot-v1.json")
model SecureBootModuleV1 {
  /** The secure-dns-miodule adds secure dns config for popular dns providers
   */
  type: "secure-boot" | "secure-boot-v1" | "secure-boot-latest";
  provider: "quad9" | "cloudflare" | "opendns"
}
