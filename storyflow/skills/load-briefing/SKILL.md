---
name: briefing
description: "Fetch and display a briefing as a smart dashboard with full context: stories, derived state, functional specification, and state-aware next steps. Use when the user asks about a specific briefing, wants briefing details, or needs to understand what a briefing contains."
allowed-tools: mcp__storyflow__get-briefing, mcp__storyflow__get-briefing-stories, mcp__storyflow__add-briefing-comment, Read
argument-hint: "<briefing-id>"
---

# Load Briefing Context

Fetch and display a briefing as a smart dashboard: full context with state-aware next steps.

## Arguments

The user provides a briefing ID as argument: `/storyflow:briefing <id>`

If no ID is provided, ask the user for one. Suggest running `/storyflow:briefings` first to see available briefings.

## Process

1. **Load config**: Read `.storyflow/config.json`.
   - If file exists: capture `customer.name` and `assets[]` for context.
   - If file does not exist: continue without context. Suggest running `/storyflow:setup` for a better experience.

2. **Fetch briefing and stories in parallel**:
   - Call `mcp__storyflow__get-briefing` with the provided ID.
   - Call `mcp__storyflow__get-briefing-stories` with the briefing ID.

   Do NOT call `get-story` for individual stories. The stories list already contains status, priority, price, and story points. Use `/storyflow:story <key>` when the user wants to dive into a specific story.

3. **Display briefing dashboard**:

   If config was loaded and the briefing's asset id is not one of `assets[].id`, show a warning:
   "Note: this briefing belongs to asset '[briefing asset name]', which is not configured for this checkout (configured assets: [list of asset names])."

   ```
   # Briefing: [Key] - [Title]
   State: [state] ([done]/[total] stories done) | Handed over: [yes/no]
   Customer: [customer] | Asset: [asset] | Project: [project]
   Created: [date] | Updated: [date]

   ## Briefing Document
   [Show the full briefing document content as returned by get-briefing.
    This is the functional specification from the Virtual PO chat,
    not a list of file attachments.]

   ## Stories ([count])

   | # | Story | Status | Priority | Price | Story Points |
   |---|-------|--------|----------|-------|--------------|
   | [key] | [title] | [status] | [priority] | [price or -] | [points or -] |

   ## Next Steps
   [State-aware guidance, see below]
   ```

4. **Next steps**

   A briefing has no status and no transition list: it is a status-less intake source. The work moves forward through its **stories**, not through the briefing. Reason from the two signals the `get-briefing` response gives you, the derived state and the handoff flag:

   | State | Meaning |
   |---|---|
   | `in_opmaak` | Not handed over yet and no relevant stories exist. Still being drafted. |
   | `overgedragen` | Handed over, or relevant stories exist, but not all of them are delivered. |
   | `afgerond` | Relevant stories exist and all of them are delivered. |

   A story is "relevant" when it is neither cancelled nor archived; those count toward neither the state nor the counter. A briefing whose stories were all cancelled therefore reads `in_opmaak` while the stories table still lists them.

   Derive the next steps:

   - **`in_opmaak`**: the document is still being shaped. Point the user at the `update-briefing` MCP tool to edit it, then `/storyflow:briefing-to-stories <key>` once it is complete.
   - **`overgedragen`, no stories**: a fresh delivery. Suggest `/storyflow:briefing-to-stories <key>` to generate the stories.
   - **`overgedragen`, with stories**: the work is under way. Suggest `/storyflow:refine-briefing <key>` for stories that still need refinement, `/storyflow:implement-briefing <key>` for a plan, and the `transition-story` MCP tool to move individual stories.
   - **`afgerond`**: everything is delivered. Mention that `archive-briefing` curates it off the intake list.

5. **Briefing-level actions**

   This skill is read-only: name the available actions, never perform them. There are no briefing transitions, only three named tools:

   - `cancel-briefing(briefingId, reason)`: the reason is required. Cascade-cancels the open stories and archives the briefing. One-way, so only mention it when the user wants to drop the work.
   - `archive-briefing(briefingId)`: only allowed once every linked story is delivered.
   - `unarchive-briefing(briefingId)`: restores an archived briefing. It does not cascade to the stories and does not undo a cancel.

   Note when you name cancel or archive that both remove the briefing from the default listings, and that an archived briefing can no longer be modified via `update-briefing`.

   Always end with: "Use `/storyflow:story <key>` to dive into a specific story's full details, acceptance criteria, and refinement analysis."
