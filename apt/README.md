# WeaverBird APT Repository

Official APT repository for WeaverBird CLI and tools.

## Quick Install

```bash
# Add repository
echo "deb [trusted=yes] https://weaverbird-io.github.io/downloads/apt stable main" | sudo tee /etc/apt/sources.list.d/weaverbird.list

# Update and install
sudo apt update
sudo apt install weaverbird
```

**Note:** Using `[trusted=yes]` as repository is not yet GPG-signed. GPG signing coming soon.

## Auto-Updates

Once installed, receive updates automatically:

```bash
sudo apt update && sudo apt upgrade
```

## Available Packages

- **weaverbird** - WeaverBird CLI Agent for server management

## Supported Architectures

- amd64 (x86_64)
- arm64 (aarch64)

---

Visit https://weaverbird.io for more information.
