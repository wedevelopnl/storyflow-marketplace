---
name: implement-briefing
description: "Generate a comprehensive implementation plan from a StoryFlow briefing. Loads briefing and all story details, launches the briefing-planner agent to explore the codebase and sequence stories into phases, saves the plan, and posts a comment on the briefing."
disable-model-invocation: true
allowed-tools: mcp__storyflow__get-briefing, mcp__storyflow__get-briefing-stories, mcp__storyflow__get-story, mcp__storyflow__add-briefing-comment, Read, Glob, Grep, Bash, Write, Agent
argument-hint: "<briefing-id>"
---

# Implement Briefing

Generate a comprehensive implementation plan from a StoryFlow briefing. This is the flagship workflow command.

## Arguments

The user provides a briefing ID as argument: `/storyflow:implement-briefing <id>`

If no ID is provided, ask the user for one. Suggest running `/storyflow:briefings` to see available briefings.

## Process

1. **Load project context** (required): Read `.storyflow/config.json` to get `project.customer_name`, `project.name`, `project.assets[]`, and `output_dir`.
   - If the file does not exist: tell the user to run `/storyflow:setup` first. Do not proceed without config.
   - If `output_dir` is missing from config: suggest running `/storyflow:setup` again to configure it. Fall back to `docs/storyflow` if the user wants to proceed anyway.

2. **Load briefing and stories list in parallel**:
   - Call `mcp__storyflow__get-briefing` with the provided ID.
   - Call `mcp__storyflow__get-briefing-stories` with the briefing ID.

3. **Determine the briefing's asset and its working directory**:

   Take the briefing's asset id from the `get-briefing` response and find the matching entry in `project.assets[]`.

   - If found and the asset has a `working_dir`: that is where the briefing-planner agent will explore.
   - If found but `working_dir` is missing: ask the user for the local path to that asset, or offer to skip and continue with `$CLAUDE_PROJECT_DIR`.
   - If not found in the configured assets: warn the user that the briefing belongs to an asset outside this project's config, and ask whether to continue against the current cwd or stop.

4. **Load full story details**: For each story, call `mcp__storyflow__get-story` to get the complete description (user story + acceptance criteria) and refinement data (report + concerns). Run these calls in parallel.

   Why: `get-briefing-stories` only returns titles, status, price, and complexity/risk. The briefing-planner agent needs the full descriptions and acceptance criteria to generate a good plan.

5. **Prepare agent prompt**: Compile all briefing and story data into a structured prompt for the briefing-planner agent. Include:
   - Briefing title, status, customer, asset name and key
   - The asset's `working_dir` (so the agent knows where to explore)
   - Full briefing document (functional specification from Virtual PO chat)
   - Full story list with titles, descriptions, acceptance criteria, refinement reports, concerns, complexity, priority

6. **Launch briefing-planner agent**: Use the Agent tool with `subagent_type: "storyflow:briefing-planner"` to generate the implementation plan. Pass the compiled briefing+story data as the prompt. Ask the agent to operate in the asset's `working_dir`. The agent will independently explore that codebase and generate the plan.

7. **Save plan**: Write the generated plan to `{output_dir}/plans/` with the naming convention:
   ```
   {output_dir}/plans/YYYY-MM-DD-briefing-<slug>.md
   ```
   Where `{output_dir}` comes from `.storyflow/config.json` and `<slug>` is a kebab-case version of the briefing title (first 5-6 words).
   Create the directory if it doesn't exist.

8. **Post comment**: Call `mcp__storyflow__add-briefing-comment` to add a comment on the briefing noting that an implementation plan has been generated. Include the plan file path.

9. **Present results**: Show the user:
   - Summary of the generated plan (phases, story coverage)
   - Location of the saved plan file
   - Next steps:
     - "Review the plan at `{output_dir}/plans/<filename>.md`"
     - "Execute the plan phase by phase"
     - "To mark stories as done, use the `transition-story` MCP tool with transition `complete`"
