# CLAUDE.md

Guidance for Claude Code when working in this repository.

## What this is

The Claude Code marketplace of WeDevelop, published from `wedevelopnl/storyflow-marketplace` (GitHub). It currently ships one plugin, `storyflow/`: skills, agents and a hook for agency Software Architects who work on client codebases through StoryFlow.

Users install it through Claude Code's marketplace system, so the published `main` branch is what runs on their machines. There is no staging in between.

## Relationship with the StoryFlow backend

The plugin's tools come from the StoryFlow MCP server, which lives in a different repo: `wedevelop/storyflow` on git.wdvlp.nl (GitLab). The MCP tool definitions are in `backend/src/Presentation/Mcp/Tool/` there.

That split has one hard consequence: a plugin release that uses a new or changed MCP tool must land **after** the backend change is deployed. A published skill calling a tool that does not exist yet fails for every user at once. Note the dependency in the CHANGELOG entry as a "Requires" section, and verify the backend is live before pushing.

## Config the plugin writes

`/storyflow:setup` writes `.storyflow/config.json` in the user's project. Version 2 holds a customer plus an assets array, and deliberately no project: an asset belongs to many projects at once, so a checkout cannot name one. Anything needing a project resolves it per action, per `storyflow/references/project-selection.md`.

## Parallel work

Sessions work on this plugin side by side, each in its own git worktree created with `EnterWorktree`. Those land in `.claude/worktrees/`, ignored by git and branched from `origin/main`. There is nothing to install in a fresh worktree.

Inside a worktree:

- Leave `version` alone in both `storyflow/.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`. The number belongs to the release, and two branches choosing one at the same time always collide.
- Document the change under the standing `## Unreleased` heading in `storyflow/CHANGELOG.md`. Keep the heading in place.
- Finish by merging into `main` in the primary checkout. `deploy-plugin` runs there, turns `Unreleased` into the new version number, tags and pushes.

## Conventions

- Skills are instructions for an agent, not documentation for a human: state the correct behavior, never the history of what changed.
- Every user-visible string in the skills and the SessionStart hook is English.
- The version in `storyflow/.claude-plugin/plugin.json` and the plugin entry in `.claude-plugin/marketplace.json` move together.
- Use the `deploy-plugin` skill to release. A change under `storyflow/` reaches users only on a new version, so never push one without a version bump. Repo tooling outside `storyflow/` (this file, `.gitignore`, `.claude/skills/`) ships nothing to users and pushes on its own.
