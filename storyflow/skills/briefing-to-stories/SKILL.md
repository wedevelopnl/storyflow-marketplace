---
name: briefing-to-stories
description: "Generate user stories from an accepted briefing. Uses codebase-analyzer agent for analysis, MCP guidelines for format, and creates stories in epics or standalone groups. Includes a two-phase review (story plan, then full stories) before saving."
disable-model-invocation: true
allowed-tools: mcp__storyflow__get-briefing, mcp__storyflow__get-briefing-stories, mcp__storyflow__create-briefing-stories, mcp__storyflow__transition-briefing, mcp__storyflow__get-briefing-to-stories-guidelines, Read, Glob, Grep, Bash, Agent
argument-hint: "<briefing-id>"
---

# Briefing to Stories

Generate user stories from an accepted briefing.

## Arguments

The user provides a briefing ID as argument: `/storyflow:briefing-to-stories <id>`

If no ID is provided, ask the user for one. Suggest running `/storyflow:briefings` to see available briefings.

## Process

### 1. Load project context

Read `.storyflow/config.json` to get `project.customer_name`, `project.name`, and `project.assets[]`.
- If the file does not exist: tell the user to run `/storyflow:setup` first. Do not proceed without config.

### 2. Load briefing and resolve its asset

Call `mcp__storyflow__get-briefing` with the provided ID.

**Validate eligibility**: Check the briefing's available transitions (included in the response). The `create-briefing-stories` MCP tool requires the briefing to be in a status that allows story creation. If this is not possible, inform the user of the current status and the available transitions instead. Stop here if story creation is not available.

**Locate the briefing's asset in config**: Match the briefing's asset id against `project.assets[].id`.

- If found: use that asset's `name` and `working_dir` for the codebase analysis below.
- If `working_dir` is missing: ask the user for the local path, or fall back to `$CLAUDE_PROJECT_DIR` with a warning.
- If the briefing's asset is not in this project's configured assets: warn the user and ask whether to continue against the current cwd or stop.

### 3. Check existing stories

Call `mcp__storyflow__get-briefing-stories` with the briefing ID.

If stories already exist, warn the user and wait for confirmation before proceeding.

### 4. Fetch guidelines

Call `mcp__storyflow__get-briefing-to-stories-guidelines` for the complete story generation guidelines.

Follow the guidelines strictly throughout the remaining steps. The guidelines contain:
- Role and approach for story generation
- Briefing-to-stories methodology (analysis, grouping, epic organization, review)
- Story writing format (language guardrails, acceptance criteria, priority)
- Analysis, generation, and review phases
- Workflow with presentation formats, save structure, and report format

### 5. Analyze codebase

Dispatch the `codebase-analyzer` agent with the briefing context (asset name, briefing title, functional document content). Tell the agent to operate in the briefing-asset's `working_dir` (resolved in step 2). Wait for the functional analysis result.

### 6. Story plan, write, review, save

Follow the Workflow section from the guidelines:

1. **Story plan** (Phase 1 review gate): propose a plan, iterate until the architect says "approved"
2. **Write stories** (Phase 2 review gate): write full descriptions, iterate until the architect says "save"
3. **Save**: call `mcp__storyflow__create-briefing-stories` with the briefing ID and the JSON data structured as described in the guidelines

### 7. Transition and report

After stories are created, fetch the briefing again to check available transitions. Apply the appropriate transition to advance the briefing. Report results following the guidelines report format.

**Note:** Stories generated from a briefing start in the `Accepted` status (not `Submitted`). The agency has committed to the work by generating the stories, so the commitment is implicit; the agency still needs to confirm the scope explicitly by moving each story to `Scoped` before refinement is allowed.
