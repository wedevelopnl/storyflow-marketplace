---
name: briefing-to-stories
description: "Generate user stories from a briefing. Uses codebase-analyzer agent for analysis, MCP guidelines for format, and creates stories in epics or standalone groups. Includes a two-phase review (story plan, then full stories) before saving."
disable-model-invocation: true
allowed-tools: mcp__storyflow__get-briefing, mcp__storyflow__get-briefing-stories, mcp__storyflow__create-briefing-stories, mcp__storyflow__get-briefing-to-stories-guidelines, Read, Glob, Grep, Bash, Agent
argument-hint: "<briefing-id>"
---

# Briefing to Stories

Generate user stories from a briefing.

## Arguments

The user provides a briefing ID as argument: `/storyflow:briefing-to-stories <id>`

If no ID is provided, ask the user for one. Suggest running `/storyflow:briefings` to see available briefings.

## Process

### 1. Load project context

Read `.storyflow/config.json` to get `project.customer_name`, `project.name`, and `project.assets[]`.
- If the file does not exist: tell the user to run `/storyflow:setup` first. Do not proceed without config.

### 2. Load briefing and resolve its asset

Call `mcp__storyflow__get-briefing` with the provided ID.

**Validate eligibility**: story generation is **one-shot**. A briefing has no status; the preconditions are that it is not archived, has no stories yet, and that you hold the agency permission to create stories on it. All three live in the backend, so `create-briefing-stories` is the authority: if it refuses, relay its error message verbatim and stop. Use the derived state in the response as an early signal (`in_opmaak` and `overgedragen` with `0/0 stories` are the normal starting points), not as a hard gate.

**Locate the briefing's asset in config**: Match the briefing's asset id against `project.assets[].id`.

- If found: use that asset's `name` and `working_dir` for the codebase analysis below.
- If `working_dir` is missing: ask the user for the local path, or fall back to `$CLAUDE_PROJECT_DIR` with a warning.
- If the briefing's asset is not in this project's configured assets: warn the user and ask whether to continue against the current cwd or stop.

### 3. Check existing stories

Call `mcp__storyflow__get-briefing-stories` with the briefing ID.

If stories already exist, stop and tell the user: story generation runs once per briefing, so `create-briefing-stories` will reject the call. Point them at `/storyflow:briefing <key>` to work with the existing stories instead.

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

### 7. Report

There is no briefing transition to apply afterwards: the briefing is a status-less intake source, and its derived state follows the stories you just created automatically. Fetch the briefing again only to show the updated state, then report results following the guidelines report format.

**Note:** Stories generated from a briefing start in the `Scoped` status. Generating them is the agency's commitment to the scope, so the `accept` and `scope` steps are already implied and the stories are immediately refineable: continue with `/storyflow:refine-briefing <key>`.
