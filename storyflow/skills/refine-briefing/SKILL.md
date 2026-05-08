---
name: refine-briefing
description: "Run multi-agent refinement analysis on all stories within a briefing. Filters stories by status (in_review by default), confirms scope with the user, then refines each story using parallel subagents per engineering perspective. Guidelines are fetched once from the ai-service and reused across all stories."
disable-model-invocation: true
allowed-tools: mcp__storyflow__get-briefing, mcp__storyflow__get-briefing-stories, mcp__storyflow__get-story, mcp__storyflow__get-refinement-guidelines, mcp__storyflow__refine-story, mcp__storyflow__transition-story, Read, Grep, Glob, Agent
argument-hint: "<briefing-id>"
---

# Refine All Stories in a Briefing

Run multi-agent refinement analysis on all stories within a briefing.

## Arguments

The user provides a briefing ID as argument: `/storyflow:refine-briefing <id>`

If no ID is provided, ask the user for one. Suggest running `/storyflow:briefings` to see available briefings.

## Process

### 1. Setup

1. **Load project context**: Read `.storyflow/config.json`.
   - If file does not exist: continue without. Suggest `/storyflow:setup`.
   - If file exists: capture `project.customer_name`, `project.name`, and `project.assets[]` for context (refinement itself does not need to scope by asset; it operates per story).

2. **Fetch briefing**: Call `mcp__storyflow__get-briefing` with the provided ID.

3. **Fetch stories**: Call `mcp__storyflow__get-briefing-stories`, then `mcp__storyflow__get-story` for each to get full details (parallel where possible).

4. **Filter**: By default, select stories in `Scoped` status (stories must have been accepted and scoped by the agency before refinement is allowed). Include already-refined stories only if the user explicitly requests re-refinement. If you encounter stories in `Submitted` or `Accepted`, advance them first via the `accept` and `scope` transitions; if refinement reveals missing scope, use `return-to-scoped` to move them back.

### 2. Fetch Refinement Guidelines

Call `mcp__storyflow__get-refinement-guidelines` (once, reuse for all stories). This returns the complete refinement context including the Workflow section with batch refinement instructions.

### 3. Confirm scope, refine, report

Follow the Batch Refinement section from the guidelines Workflow:

1. **Confirm scope**: Show stories to be refined, wait for confirmation
2. **Refine each story**: Triage, dispatch, synthesize, save per the Workflow. Show progress.
3. **Summary table**: Display all results
4. **Next steps**: Fetch stories and briefing to suggest available transitions
