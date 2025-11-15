# Secure DNS Module

This module configures `systemd-resolved` to use a secure DNS provider, enabling DNS-over-TLS and DNSSEC for enhanced privacy and security.

## Usage

To use this module, add the following to your configuration file:

```yaml
type: secure-dns
provider: <provider-name>
```

Replace `<provider-name>` with one of the supported providers.

## Supported Providers

The following providers are supported:

- [`cloudflare`](https://1.1.1.1/)
- [`opendns`](https://www.opendns.com/)
- [`quad9`](https://quad9.net/)

## Configuration Details

This module will create a configuration file at `/etc/resolved.d/secure-dns.conf` with the appropriate settings for the selected provider. This includes the provider's DNS servers, and enabling DNS-over-TLS and DNSSEC.
