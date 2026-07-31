---
name: deploy-plugin
description: |
  Deploy the StoryFlow Claude Code plugin. Use when deploying plugin changes, releasing a new plugin version, bumping plugin version, or pushing plugin updates to users.
  TRIGGERS: deploy plugin, release plugin, plugin version, bump plugin, push plugin, publish plugin, plugin update, /deploy-plugin
---

# Deploy StoryFlow Plugin

Releases the plugin under `storyflow/` so that users receive the update. This repo (`wedevelopnl/storyflow-marketplace`) is the single source: one commit, one push, no second copy to keep in sync.

## Why the version bump matters

Users install the plugin through Claude Code's marketplace system. Claude Code caches plugins and only refreshes when it detects a new version. Without a bump in `storyflow/.claude-plugin/plugin.json`, users will not see your changes, no matter how many times you push.

## Deployment steps

### 1. Verify there are changes to deploy

```bash
git status
git log origin/main..HEAD --oneline
```

If both are empty, stop and tell the user there is nothing to deploy. If only the second has output (committed but unpushed), skip to step 3.

### 2. Commit the changes

```bash
git add -A && git commit -m "<message>"
```

Use a conventional commit message scoped to `storyflow`, for example:
- `feat(storyflow): add new briefing command`
- `fix(storyflow): correct MCP server config`
- `chore(storyflow): update skill descriptions`

Separate logical changes into separate commits.

### 3. Update the README

Before bumping the version, ensure `storyflow/README.md` is up to date:

1. Scan the actual plugin components:
   - Commands: none currently. The plugin ships no `commands/` directory; user-facing commands are provided as skills. Add this scan only if a `commands/` directory is introduced later.
   - Skills: `storyflow/skills/*/SKILL.md` (read the `name` and `description` from YAML frontmatter)
   - Agents: `storyflow/agents/*.md` (read the `name` and `description` from YAML frontmatter)

2. Compare with what the README documents in its **Commands**, **Skills**, and **Agents** sections.

3. If anything is missing, renamed, or removed: update the README to match reality. Keep the existing prose style and table format. Leave unrelated sections alone.

4. If the README changed, commit it:
   ```bash
   git add storyflow/README.md && git commit -m "docs(storyflow): update README with current commands, skills, and agents"
   ```

### 4. Determine the version bump

```bash
git tag -l 'v*' --sort=-v:refname | head -1
git log <latest-tag>..HEAD --oneline
```

If no tags exist, read the version from `storyflow/.claude-plugin/plugin.json` and use `git log --oneline`.

Apply semver based on the conventional commit prefixes:
- Any `feat` commit -> **minor**
- Only `fix`/`chore`/`docs` -> **patch**
- Any `BREAKING CHANGE` or `!` after the type -> **major**

When in doubt: minor for new functionality, patch for fixes.

Present the proposed bump before applying it:
> Current version: X.Y.Z (from tag vX.Y.Z). Based on the changes, I propose bumping to A.B.C (minor: added new X command). OK?

### 5. Bump the version

Update `version` in `storyflow/.claude-plugin/plugin.json`, and the plugin entry's `version` in `.claude-plugin/marketplace.json` so the two cannot drift apart.

```bash
git add -A && git commit -m "chore(storyflow): bump version to <new-version>"
```

### 6. Tag the release

```bash
git tag -a v<new-version> -m "Release v<new-version>"
```

### 7. Push

```bash
git push origin main --follow-tags
```

This is the push users receive the update from. Confirm with the user before running it: it publishes to everyone who has the plugin installed.

### 8. Confirm

Tell the user:
- The new plugin version and tag (vX.Y.Z)
- That users receive the update on their next Claude Code session (marketplace auto-update) or via `/plugin update storyflow@storyflow-marketplace`

## Backend dependencies

The plugin talks to the StoryFlow MCP server, which lives in `wedevelop/storyflow` (git.wdvlp.nl). A plugin release that relies on a new or changed MCP tool must land **after** that backend change is deployed: a published plugin calling a tool that does not exist yet fails for every user at once.

When the plugin change depends on a backend change, state it in the CHANGELOG entry (a "Requires" section) and verify the backend is live before step 7.

## Important notes

- Always bump the version. Without it, users do not receive the update.
- Keep the version bump in its own commit, separate from the feature commits.
- Always tag the release. The tag is how the next deploy determines what changed.
- Never force-push: users may have cached a specific commit hash.
- On a diverged history, `git pull --rebase origin main` first.
