---
name: story
description: "Fetch and display complete details for a specific story: description, acceptance criteria, refinement data (complexity, risk, report, concerns), comments, and status-aware next steps. Use when the user asks about a specific story or wants to see story details."
allowed-tools: mcp__storyflow__get-story, mcp__storyflow__add-story-comment, Read
argument-hint: "<story-id>"
---

# Load Story Context

Fetch and display complete details for a specific story.

## Arguments

The user provides a story ID as argument: `/storyflow:story <id>`

If no ID is provided, ask the user for one. Suggest loading a briefing first with `/storyflow:briefing <id>` to see available stories.

## Process

1. **Load project context** (required): Read `.storyflow/config.json` to get `project.customer_name`, `project.name`, and `project.assets[]`.
   - If the file does not exist: tell the user to run `/storyflow:setup` first. Do not proceed without config.

2. **Fetch story**: Call `mcp__storyflow__get-story` with the provided ID.

3. **Display story dashboard**:

   If the story's asset id is not one of `project.assets[].id`, show a warning:
   "Note: this story belongs to asset '[story asset name]', which is not part of this project (configured assets: [list of asset names])."

   ```
   # Story: [Key] - [Title]
   Status: [status] | Priority: [priority] | Price: [price or "not priced"]
   Asset: [asset] | Project: [project] | Briefing: [briefing key]
   Created: [date] | Updated: [date]

   ## Description
   [Full user story with acceptance criteria as returned by get-story]

   ## Refinement
   Complexity: [complexity] | Risk: [risk]

   ### Analysis
   [The refinement report - this is a detailed implementation analysis,
    not a list of acceptance criteria]

   ### Concerns
   [List concerns with their severity level: WARNING or INFO]
   ```

   If no refinement data exists, show: "This story has not been refined yet."

4. **Available transitions and next steps**:

   The `get-story` MCP response includes an "Available transitions" section listing what actions can be taken next, with transition names, labels, target statuses, and required data fields. Display these transitions as the next steps.

   For each available transition, suggest the corresponding action:
   - If a transition maps to a plugin skill (e.g., refinement, pricing), suggest the `/storyflow:` skill
   - Otherwise, suggest using the `transition-story` MCP tool with the transition name

   If no transitions are available, the story is in a terminal state (Done, Invoiced, Cancelled).

5. **Orthogonal flag**:

   - `archivedAt`: soft-delete flag. If set, prepend "This story is archived" to the output.

   The archive flag is an orthogonal action, not a workflow transition. It does not appear in the "Available transitions" list; it is surfaced via separate MCP actions (`archive-story`, `unarchive-story`).

6. **Accept and Scope**: The feature story lifecycle includes two explicit agency commitment steps between `Submitted` and `Refined`:

   - `accept`: the agency commits to the story (`Submitted -> Accepted`)
   - `scope`: the agency confirms the scope definition (`Accepted -> Scoped`)

   Refinement (`refine`) now starts from `Scoped`, not `Submitted`. Briefing-generated stories start in `Accepted` (the agency has implicitly committed by generating them); the agency still needs to confirm the scope explicitly via `scope` before refinement is allowed. A story shown in `Accepted` or `Scoped` is waiting for the agency to advance it, not for the customer.

   Always end with: "Use `/storyflow:briefing <key>` to see the full briefing context for this story."
