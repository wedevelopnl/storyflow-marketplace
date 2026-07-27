# Changelog

All notable changes to the StoryFlow plugin will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 5.0.0 - 2026-07-27

### BREAKING CHANGES

**`transition-briefing` is replaced by three named tools.** A status-less briefing has no transitions: cancel is a one-way domain action and archive is a reversible visibility flag. Calling them "transitions" invited agents to look for a state machine that does not exist, and left `unarchive` unreachable from MCP even though the domain and the HTTP API have it.

| Removed | Use instead |
|---|---|
| `transition-briefing(id, "cancel", '{"reason":"..."}')` | `cancel-briefing(id, reason)` |
| `transition-briefing(id, "archive")` | `archive-briefing(id)` |
| not available | `unarchive-briefing(id)` |

- The cancellation reason is now a required parameter instead of a key in a `data` JSON string. A blank or missing reason is refused; previously the MCP path cancelled the briefing with an empty cancellation comment while the HTTP API answered 400 on the same input.
- All three tools now check `BriefingVoter` before dispatching, matching the HTTP controllers. `transition-briefing` checked only agency ownership.
- `archive-briefing` reports an undelivered briefing as a state problem rather than a permission problem.

### Changed

- `briefing` skill: names the three lifecycle tools instead of `transition-briefing`, and stays read-only.
- README: documents the three actions in a table, including that `unarchive-briefing` neither cascades to the stories nor undoes a cancel.

## 4.0.0 - 2026-07-22

### BREAKING CHANGES

**The briefing is a status-less intake source.** The StoryFlow platform removed the briefing status lifecycle; the plugin skills still described the old model and gave instructions the MCP server rejects. A briefing no longer has a workflow status, a status projection from its stories, or a transition list. Only the story lifecycle remains a state machine.

- **Removed the `/storyflow:claim-briefing` skill.** The `claim` transition no longer exists on the platform. Claiming belonged to the status model; picking up work now means moving the stories (`transition-story`).
- `list-briefings` and `get-briefing` report a **derived state** instead of a status: `in_opmaak` (not handed over, no relevant stories), `overgedragen` (handed over, or relevant stories exist but not all delivered), `afgerond` (all relevant stories delivered), plus a `[done]/[total] stories done` counter. A story is relevant when it is neither cancelled nor archived. The state is computed per read and never stored. `get-briefing` also reports the handoff flag; there is no "Available transitions" section.
- `transition-briefing` supports only `cancel` (requires a `reason`; cascade-cancels the open stories and archives the briefing) and `archive` (allowed once every linked story is delivered).

### Migration

Replace `/storyflow:claim-briefing <id>` in your workflow with `/storyflow:briefing-to-stories <id>` (for a briefing without stories) or `/storyflow:implement-briefing <id>` followed by `transition-story` (for one that already has them).

### Changed

- `briefings` skill: groups briefings by derived state (`overgedragen`, `in_opmaak`, `afgerond`) instead of by status, and highlights fresh deliveries (`overgedragen` with `0/0 stories`) as the work to pick up. The architect column is gone: the MCP response never carried one.
- `briefing` skill: derives its next steps from the state plus the handoff flag rather than from a transitions section, and documents the two briefing-level actions (`cancel`, `archive`).
- `briefing-to-stories` skill: eligibility is the backend's one-shot guard (not archived, no stories yet) instead of a status check, and it no longer applies a briefing transition after saving.
- `create-briefing` skill: the result template no longer prints a status or transition list.
- `refine-briefing` skill: the description now matches the body (stories are filtered on `Scoped`, not "in_review").
- `briefing-to-stories` and `story` skills: briefing-generated stories start in `Scoped`, not `Accepted`. Generating them from a briefing is the agency's commitment to the scope, so they are immediately refineable.
- `story` skill: the archive flag is applied through `transition-story` with `archive` / `unarchive`; there are no separate `archive-story` / `unarchive-story` tools.
- The `invoice` transition is no longer listed for stories. Invoicing is driven by the Invoice aggregate on the StoryFlow platform; the `transition-story` MCP tool no longer includes `invoice` as an available action.

## 3.0.0 - 2026-05-08

### BREAKING CHANGES

The plugin now models a StoryFlow project as a customer plus zero or more assets, instead of one customer and one asset. The `.storyflow/config.json` schema changed; existing configs must be regenerated by running `/storyflow:setup` again.

**New config shape:**

```json
{
  "version": 1,
  "project": {
    "id": "<project-uuid>",
    "key": "<project-key>",
    "name": "<project-name>",
    "customer_id": "<customer-uuid>",
    "customer_name": "<customer-name>",
    "assets": [
      {
        "id": "<asset-uuid>",
        "key": "<asset-key>",
        "name": "<asset-name>",
        "type": "<asset-type>",
        "repository_url": "<repo-url>",
        "production_url": "<prod-url-or-null>",
        "working_dir": "<absolute-path-or-null>"
      }
    ]
  },
  "output_dir": "docs/storyflow"
}
```

**Removed top-level fields:** `project.asset_id`, `project.asset_name` (and any flat `asset_*` field). Skills now resolve the active asset per command by matching `$CLAUDE_PROJECT_DIR` against `assets[].working_dir`. When no match is found and there are multiple assets, the skill asks the user to pick.

### Migration

Re-run `/storyflow:setup` in every project that uses the StoryFlow plugin. The setup flow now detects the project, lists every asset in it, and asks for a `working_dir` per asset (or lets you skip assets you do not have checked out locally).

### Changed

- `setup` skill: detects project (not just asset), captures every asset in the project with its local `working_dir`.
- Session-start hook: matches `$CLAUDE_PROJECT_DIR` against each asset's `working_dir` to determine the active asset; reports cleanly for 0 / 1 / N asset projects.
- `briefings` skill: scoped to the active asset by default; new `--all` argument lists briefings for every project asset, grouped by asset.
- `create-briefing`, `asset-documentation`: resolve the active asset before creating or writing.
- `claim-briefing`, `briefing`, `story` skills: safety check now compares the briefing/story asset against the full set of project assets, not a single configured asset.
- `implement-briefing`, `briefing-to-stories`: use the briefing's own asset (and its `working_dir`) for codebase exploration, regardless of which asset the user is currently in.
- `briefing-planner` and `codebase-analyzer` agents: accept and operate on a passed `working_dir`, supporting projects that span multiple repositories.

## 2.0.0 - 2026-04-10

### BREAKING CHANGES

The StoryFlow briefing and story lifecycles have been harmonised. Clients that hardcoded transition names, workflow status values, or the "approved briefing" terminology must update.

**Briefing transitions no longer exposed (the briefing projection replaces them):**

From `Accepted` onwards, a briefing's workflow status is projected automatically from its linked stories. The following briefing-level transitions are therefore removed from the MCP transition map and will fail if invoked directly:

- `scoped` (`Accepted -> Scoped`)
- `refined` (`Scoped -> Refined`)
- `priced` (`Refined -> Priced`)
- `approve` (briefing-level, `Priced -> ToDo`)
- `start` (`ToDo -> Doing`)
- `complete` (`Doing -> Done`)
- `return-to-accepted` (`Scoped -> Accepted`)
- `return-to-scoped` (`Refined -> Scoped`)
- `return-to-refined` (`Priced -> Refined`)
- `archive` (briefing-level, replaced by the `archivedAt` orthogonal flag)

The briefing transition map now only contains `submit`, `withdraw`, `return-to-draft`, `accept`, `return-to-submitted`, and `cancel`. Forward motion from `Accepted` onwards happens by moving the linked stories.

**Story transitions no longer exposed:**

- `archive` (story-level, replaced by the `archivedAt` orthogonal flag)

**Removed workflow status values:**

- Story statuses: `NeedsClarification`, `Archived`
- Briefing statuses: `Archived`

`NeedsClarification` was dropped without a replacement flag; `Archived` is now an orthogonal flag (`archivedAt`), not a workflow status.

**New story transitions:**

- `accept` (`Submitted -> Accepted`): the agency commits to the story
- `scope` (`Accepted -> Scoped`): the agency confirms the scope definition
- `return-to-submitted` (`Accepted -> Submitted`)
- `return-to-accepted` (`Scoped -> Accepted`)
- `return-to-scoped` (`Refined -> Scoped`)

Refinement (`refine`) now starts from `Scoped`, not `Submitted`.

**New orthogonal MCP actions (not workflow transitions):**

- `archive-story` + `unarchive-story`: toggle the `archivedAt` soft-delete flag (allowed only from a terminal workflow status; preserves the status).
- `archive-briefing` + `unarchive-briefing`: same for briefings.

**Briefing status is now a projection.** From `Accepted` onwards, the briefing's workflow status is automatically computed from its linked stories using a min-wins rule with a `Doing` any-wins override. Manual briefing transitions for those steps no longer exist.

### Migration

1. Upgrade the plugin: `/plugin update storyflow@storyflow-marketplace`.
2. Review any external automations or scripts that call the MCP server directly. Replace removed transition names with the new orthogonal actions (`archive-story`, etc.) or the new `accept` / `scope` story transitions.
3. Clients that listed `approved` as the "ready to claim" criterion should switch to `accepted` (the same semantic step under the new naming).
4. Clients that surfaced `Archived` as a separate kanban column should use the `archivedAt` flag on the regular workflow status instead.
5. Clients that called briefing transitions from `Accepted` onwards (`scoped`, `refined`, `priced`, `approve`, `start`, `complete`, or any `return-to-*` from those steps) should drive the motion through the linked stories instead.

### Added

- Orthogonal archive flag (`archivedAt`) exposed in `get-briefing` and `get-story` responses.
- New explicit agency commitment steps: `accept` and `scope` between `Submitted` and `Refined`.
- `load-briefing` and `load-story` skills now render the archive flag alongside the workflow status.
- README section documenting the lifecycle and the archive flag.

### Changed

- `claim-briefing` skill: updated terminology (`accepted` instead of `approved`), no longer claims to "transition the briefing to InProgress". Claim now only assigns the architect; the workflow status projects from the stories.
- `list-briefings` skill: claim-target is now briefings in `Accepted` status without an assigned architect.
- `refine-briefing` and `refine-story` skills: refinement now starts from `Scoped` status (stories must be accepted and scoped first).
- `briefing-to-stories` skill: generated stories start in `Accepted` instead of `Submitted`.
- Plugin version bumped to 2.0.0 to signal the breaking changes.

### Removed

- All references to `approved briefing` terminology from skill descriptions and bodies.
- All references to `NeedsClarification` and `Archived` as workflow statuses from skill content.
