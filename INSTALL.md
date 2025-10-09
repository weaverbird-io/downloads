# WeaverBird CLI Installation

## Quick Install (Linux/macOS)

```bash
curl -fsSL https://weaverbird-io.github.io/downloads/install.sh | sh
```

This script will:
1. Auto-detect your OS and architecture
2. Download the latest WeaverBird CLI release
3. Install to `/usr/local/bin/weaverbird`
4. Verify the installation

## Supported Platforms

- Linux (AMD64, ARM64)
- macOS (AMD64, ARM64) - Coming soon
- Windows (AMD64) - Manual installation required

## Manual Installation

### Linux/macOS

1. Download the binary for your platform from [GitHub Releases](https://github.com/weaverbird-io/weaverbird-cli/releases/latest)

2. Extract the archive:
   ```bash
   tar -xzf weaverbird-cli-*.tar.gz
   ```

3. Move to your PATH:
   ```bash
   sudo mv weaverbird /usr/local/bin/
   sudo chmod +x /usr/local/bin/weaverbird
   ```

4. Verify installation:
   ```bash
   weaverbird --version
   ```

### Windows

1. Download `weaverbird-cli-windows-amd64.zip` from [GitHub Releases](https://github.com/weaverbird-io/weaverbird-cli/releases/latest)

2. Extract the ZIP file

3. Add the binary location to your PATH environment variable

4. Verify installation:
   ```cmd
   weaverbird --version
   ```

## Uninstallation

```bash
sudo rm /usr/local/bin/weaverbird
```

## Troubleshooting

**Permission Denied**
- Run with sudo: `curl -fsSL https://weaverbird-io.github.io/downloads/install.sh | sudo sh`

**Command not found after install**
- Ensure `/usr/local/bin` is in your PATH
- Restart your terminal

**Download failed**
- Check your internet connection
- Verify the release exists on GitHub

## Support

For issues or questions:
- GitHub Issues: https://github.com/weaverbird-io/weaverbird-cli/issues
- Documentation: https://weaverbird.io
