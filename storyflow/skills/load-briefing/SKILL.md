---
name: briefing
description: "Fetch and display a briefing as a smart dashboard with full context: stories, status, functional specification, conversation, and status-aware next steps. Use when the user asks about a specific briefing, wants briefing details, or needs to understand what a briefing contains."
allowed-tools: mcp__storyflow__get-briefing, mcp__storyflow__get-briefing-stories, mcp__storyflow__add-briefing-comment, Read
argument-hint: "<briefing-id>"
---

# Load Briefing Context

Fetch and display a briefing as a smart dashboard: full context with status-aware next steps.

## Arguments

The user provides a briefing ID as argument: `/storyflow:briefing <id>`

If no ID is provided, ask the user for one. Suggest running `/storyflow:briefings` first to see available briefings.

## Process

1. **Load project context**: Read `.storyflow/config.json`.
   - If file exists: capture `project.customer_name`, `project.name`, and `project.assets[]` for context.
   - If file does not exist: continue without context. Suggest running `/storyflow:setup` for a better experience.

2. **Fetch briefing and stories in parallel**:
   - Call `mcp__storyflow__get-briefing` with the provided ID.
   - Call `mcp__storyflow__get-briefing-stories` with the briefing ID.

   Do NOT call `get-story` for individual stories. The stories list already contains status, priority, price, complexity, and risk. Use `/storyflow:story <key>` when the user wants to dive into a specific story.

3. **Display briefing dashboard**:

   If config was loaded and the briefing's asset id is not one of `project.assets[].id`, show a warning:
   "Note: this briefing belongs to asset '[briefing asset name]', which is not part of this project (configured assets: [list of asset names])."

   ```
   # Briefing: [Key] - [Title]
   Status: [status] | Customer: [customer] | Asset: [asset] | Project: [project]
   Architect: [assigned name or "unassigned"] | Created: [date] | Updated: [date]

   ## Briefing Document
   [Show the full briefing document content as returned by get-briefing.
    This is the functional specification from the Virtual PO chat,
    not a list of file attachments.]

   ## Stories ([count])

   | # | Story | Status | Priority | Price | Complexity | Risk |
   |---|-------|--------|----------|-------|------------|------|
   | [key] | [title] | [status] | [priority] | [price or -] | [complexity or -] | [risk or -] |

   ## Next Steps
   [Status-aware guidance, see below]
   ```

4. **Available transitions and next steps**:

   The `get-briefing` MCP response includes an "Available transitions" section. Each transition has an action name, target status, label, description, and any required data fields. Display these as the next steps.

   For each available transition:
   - Show the transition label and description as returned by the MCP
   - If a `/storyflow:` skill exists that performs this action, suggest it (match by action name or description)
   - Otherwise, suggest using the `transition-briefing` MCP tool with the transition name and any required data fields shown in the response

   If no transitions are available, the briefing is in a terminal state.

5. **Orthogonal flag**: The `get-briefing` response includes an `archivedAt` field that is independent of the workflow status:

   - `archivedAt`: when set, the briefing is soft-deleted. It should only appear in the current view if the user explicitly requested archived items. If the field is set, prepend "This briefing is archived" to the output.

   The archive flag is toggled via dedicated MCP actions (`archive-briefing`, `unarchive-briefing`) and is NOT a workflow transition. It does not appear in the "Available transitions" list.

   Always end with: "Use `/storyflow:story <key>` to dive into a specific story's full details, acceptance criteria, and refinement analysis."
