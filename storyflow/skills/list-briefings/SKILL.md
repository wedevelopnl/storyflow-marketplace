---
name: briefings
description: "Shows briefings for the active asset (resolved from cwd) or for all configured project assets, grouped by their derived state. Highlights new deliveries that still need stories. Use when the user asks to see available work, list briefings, or check what needs attention."
allowed-tools: mcp__storyflow__list-briefings, AskUserQuestion, Read
argument-hint: "[--all]"
---

# List StoryFlow Briefings

Show briefings, highlighting what needs attention.

## Arguments

- No argument: scope to the active asset (resolved from cwd).
- `--all`: list briefings for every configured asset, grouped by asset.

## Process

1. **Load config** (required): Read `.storyflow/config.json`. If the file does not exist: tell the user to run `/storyflow:setup` first and stop.

   Capture `customer.id`, `customer.name`, and `assets[]`.

2. **Resolve scope**:

   - If `assets` is empty: tell the user to re-run `/storyflow:setup`, and stop.
   - If the user passed `--all`: scope is "all configured assets".
   - Else if exactly one asset is configured: scope is that asset.
   - Else (multiple assets, no `--all`):
     - Match `$CLAUDE_PROJECT_DIR` against each asset's `working_dir` (exact match, or cwd inside the working_dir).
     - If exactly one matches: scope is that asset.
     - If none match or multiple match: use `AskUserQuestion` to let the user pick. Provide options for each asset and one extra option "All configured assets".

3. **Fetch briefings**:

   - For a single-asset scope: call `mcp__storyflow__list-briefings` once with `customerId` and `assetId`.
   - For "all assets": call `mcp__storyflow__list-briefings` once per asset (parallel) and merge.

   Archived briefings are excluded from the response. The optional `state` parameter filters on the derived state; leave it unset here so every state is shown.

4. **Read the derived state**

   A briefing has no status of its own. Every line of the response carries a derived state plus a story counter:

   ```
   - WDV-BR-12: "Invoice PDF export" | State: overgedragen (1/4 stories done) | Customer: ... | Asset: ... (ID: ...) | ID: ...
   ```

   | State | Meaning |
   |---|---|
   | `in_opmaak` | Not handed over yet and no relevant stories exist. The briefing is still being drafted. |
   | `overgedragen` | Handed over, or relevant stories exist, but not all of them are delivered. |
   | `afgerond` | Relevant stories exist and all of them are delivered. |

   A story is "relevant" when it is neither cancelled nor archived; those count toward neither the state nor the counter.

5. **Display briefings**

   For a single-asset scope, group by state in this order (most actionable first), skipping empty groups: `overgedragen`, `in_opmaak`, `afgerond`.

   ```
   # Briefings for [asset_name] ([customer_name])

   ## Overgedragen
   [Key] [Title]
   State: overgedragen | Stories: [done]/[total]
   ```

   For "all assets", group first by asset, then by state within each asset:

   ```
   # Briefings for [customer_name] / [project_name]

   ## [asset_name] ([asset_key])
   ### [State]
   [Key] [Title]
   ...
   ```

   **Highlight new deliveries**: a briefing in state `overgedragen` with `0/0 stories` was handed over but has no stories yet. That is the work waiting to be picked up. Mark those lines and list them first within the group.

6. **Suggest next steps**:

   - New deliveries (`overgedragen`, `0/0 stories`): suggest `/storyflow:briefing-to-stories <key>` to generate stories.
   - `overgedragen` with stories: suggest `/storyflow:briefing <key>` for the full dashboard, or `/storyflow:implement-briefing <key>` to plan the work.
   - `in_opmaak`: suggest `/storyflow:briefing <key>` to review the draft.
   - If no briefings exist for the chosen scope: "No briefings found. Check the StoryFlow UI or ask the customer to create a briefing."
   - If scope was a single asset and there are configured siblings: hint that `/storyflow:briefings --all` lists every asset's briefings.
