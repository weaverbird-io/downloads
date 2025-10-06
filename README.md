# WeaverBird Downloads

Official downloads page for WeaverBird software releases.

## Live Site

Visit [weaverbird-io.github.io/downloads](https://weaverbird-io.github.io/downloads) to download WeaverBird tools.

## How It Works

1. **Source Code**: Located in `/apps/downloads` (Astro + Tailwind CSS)
2. **Releases Catalog**: `public/releases.json` defines available software
3. **Binary Hosting**: GitHub Releases in respective repos (e.g., `weaverbird-io/weaverbird-cli`)
4. **Deployment**: Automatic via GitHub Actions to GitHub Pages

## Adding New Software

Edit `/apps/downloads/public/releases.json`:

```json
{
  "software": [
    {
      "id": "your-tool",
      "name": "Your Tool",
      "description": "Description of your tool",
      "icon": "🛠️",
      "color": "weaver-primary",
      "repo": "weaverbird-io/your-tool",
      "platforms": ["linux-amd64", "linux-arm64", "windows-amd64"],
      "installCommand": "curl -fsSL https://downloads.weaverbird.io/install-your-tool.sh | sh"
    }
  ]
}
```

## Features

- **OS Auto-Detection**: Highlights the correct download for user's platform
- **GitHub Releases Integration**: Fetches latest versions dynamically
- **SEO Optimized**: Static site generation with proper meta tags
- **Brand Consistent**: Uses WeaverBird color scheme

## Development

The downloads site source code is managed in the monorepo at `apps/downloads`.

```bash
cd apps/downloads
npm install
npm run dev
```

## Deployment

Pushes to `main` branch automatically trigger deployment to GitHub Pages.
