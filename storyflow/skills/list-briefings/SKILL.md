---
name: briefings
description: "Shows briefings for the active asset (resolved from cwd) or for all configured project assets, grouped by status. Highlights briefings ready to claim (Accepted). Use when the user asks to see available work, list briefings, or check what needs attention."
allowed-tools: mcp__storyflow__list-briefings, AskUserQuestion, Read
argument-hint: "[--all]"
---

# List StoryFlow Briefings

Show briefings, highlighting what needs attention.

## Arguments

- No argument: scope to the active asset (resolved from cwd).
- `--all`: list briefings for every configured asset in the project, grouped by asset.

## Process

1. **Load config** (required): Read `.storyflow/config.json`. If the file does not exist: tell the user to run `/storyflow:setup` first and stop.

   Capture `project.customer_id`, `project.customer_name`, `project.name`, and `project.assets[]`.

2. **Resolve scope**:

   - If `project.assets` is empty: tell the user the project has no assets configured yet, suggest re-running `/storyflow:setup` once an asset has been added in StoryFlow, and stop.
   - If the user passed `--all`: scope is "all configured assets".
   - Else if exactly one asset is configured: scope is that asset.
   - Else (multiple assets, no `--all`):
     - Match `$CLAUDE_PROJECT_DIR` against each asset's `working_dir` (exact match, or cwd inside the working_dir).
     - If exactly one matches: scope is that asset.
     - If none match or multiple match: use `AskUserQuestion` to let the user pick. Provide options for each asset and one extra option "All assets in this project".

3. **Fetch briefings**:

   - For a single-asset scope: call `mcp__storyflow__list-briefings` once with `customerId` and `assetId`.
   - For "all assets": call `mcp__storyflow__list-briefings` once per asset (parallel) and merge.

4. **Display briefings**:

   For a single-asset scope, group by status (most actionable first), skip empty groups:

   ```
   # Briefings for [asset_name] ([customer_name])

   ## [Status Group]
   [Key] [Title]
   Status: [status] | Architect: [name or unassigned] | Stories: [count if available]
   Available actions: [list transition labels from MCP response]
   ```

   For "all assets", group first by asset, then by status within each asset:

   ```
   # Briefings for [customer_name] / [project_name]

   ## [asset_name] ([asset_key])
   ### [Status Group]
   [Key] [Title]
   ...
   ```

   A briefing is a "ready to claim" candidate when its status is `Accepted` and no architect is assigned yet. Briefings later in the lifecycle (`Scoped`, `Refined`, `Priced`, `ToDo`, `Doing`) are already being worked on (their status projects from the linked stories).

5. **Suggest next steps**:

   - For briefings with available transitions: suggest `/storyflow:briefing <key>` to see full details and act on the transitions.
   - If no briefings exist for the chosen scope: "No briefings found. Check the StoryFlow UI or ask the customer to create a briefing."
   - If scope was a single asset and there are configured siblings: hint that `/storyflow:briefings --all` lists every asset's briefings.
