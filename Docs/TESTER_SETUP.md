# ToonAge — Tester Setup Guide

## How Updates Work

ToonAge uses **GitHub Releases** as the update source and **WowUp** as the automatic updater. When a new version is tagged, GitHub Actions packages a ZIP and publishes it. WowUp detects the new release and updates your local copy.

---

## Step 1: Get Access

You need to be added as a **collaborator** on the private GitHub repository:
- Repository: `https://github.com/Sirc146/ToonAge`
- Ask Chris to add your GitHub username as a collaborator.

---

## Step 2: Install WowUp

1. Download WowUp from [https://wowup.io](https://wowup.io)
2. Install and point it at your WoW installation directory.

---

## Step 3: Add ToonAge via URL

1. In WowUp, click **Get Addons** (or the + button)
2. Select **Install from URL**
3. Paste: `https://github.com/Sirc146/ToonAge`
4. Click **Import**, then **Install**

WowUp uses the GitHub provider to detect releases. Since the repo is private, you may need to authenticate WowUp with a GitHub Personal Access Token (PAT):

### Authenticating WowUp for Private Repos

1. Go to GitHub → Settings → Developer settings → Personal access tokens → Fine-grained tokens
2. Create a token with:
   - **Repository access**: Only select repositories → `Sirc146/ToonAge`
   - **Permissions**: Contents (read-only)
3. In WowUp → Options → look for GitHub token / authentication settings
4. Paste your PAT

---

## Step 4: Automatic Updates

Once installed, WowUp will:
- Check for new releases automatically (default: every 30 minutes)
- Download the ZIP asset from the latest GitHub Release
- Extract it into your `Interface/AddOns/` directory
- Overwrite the previous version

You can also manually check by clicking **Refresh** in WowUp.

---

## Step 5: Version Info

- Stable releases: `v2.0.0`, `v2.0.1`, `v2.1.0`
- Dev/test builds: `v2.1.0-dev.1`, `v2.0.0-beta.1`
- Dev builds activate the **tester lock** — only authorized characters can use the addon

If you see: `[ToonAge] Dev build — not authorized`
→ Your character isn't in the testers list. Ask Chris to add `YourName-YourServer`.

---

## WowUp GitHub Provider Endpoint

```
https://api.github.com/repos/Sirc146/ToonAge/releases/latest
```

---

## Troubleshooting

| Problem | Solution |
|---|---|
| WowUp says "not found" | Token may be expired or repo URL is wrong |
| Addon loads but says "not authorized" | Your character isn't in the tester list in `Core/Init.lua` |
| Addon doesn't update | Check WowUp → My Addons → ToonAge → click Refresh |
| Old version still loaded after update | `/reload` in-game |
