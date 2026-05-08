---
name: refine-story
description: "Run multi-agent refinement analysis on a single story. Fetches refinement guidelines (agent perspectives, scoring, synthesis approach) from the ai-service, dispatches parallel subagents per perspective, synthesizes results, and saves via MCP."
disable-model-invocation: true
allowed-tools: mcp__storyflow__get-story, mcp__storyflow__get-briefing, mcp__storyflow__get-refinement-guidelines, mcp__storyflow__refine-story, mcp__storyflow__transition-story, Read, Grep, Glob, Agent
argument-hint: "<story-id>"
---

# Refine a Single Story

Run multi-agent refinement analysis on a story and save the results.

## Arguments

The user provides a story ID as argument: `/storyflow:refine-story <id>`

If no ID is provided, ask the user for one. Suggest loading a briefing first with `/storyflow:briefing <id>` to see available stories.

## Process

### 1. Setup

1. **Load project context**: Read `.storyflow/config.json`.
   - If file does not exist: continue without. Suggest `/storyflow:setup`.
   - If file exists: capture `project.customer_name`, `project.name`, and `project.assets[]` for context (refinement itself does not need to scope by asset; it operates per story).

2. **Fetch story**: Call `mcp__storyflow__get-story` with the provided ID.

   **Status pre-requisite**: A story is refineable only when it is in `Scoped` status. If the story is in `Submitted` or `Accepted`, advance it via the `accept` and `scope` transitions before refining.

3. **Check existing refinement**: If the story already has refinement data, show existing summary and ask to re-refine. If user declines, stop.

4. **Load briefing context**: If the story belongs to a briefing, call `mcp__storyflow__get-briefing` for broader context.

### 2. Fetch Refinement Guidelines

Call `mcp__storyflow__get-refinement-guidelines`. This returns the complete refinement context:
- **Output Format**: MCP tool parameters, report structure, concerns format
- **Scoring & Synthesis Approach**: Complexity, risk, story points, synthesis methodology
- **Agent Perspectives**: Prompts for Backend Engineer, Frontend Engineer, Security Expert, QA Engineer, DevOps Engineer
- **Workflow**: Triage, subagent dispatch template, synthesis rules, and results display format

These guidelines are the single source of truth: the same prompts used by the in-app refinement system.

### 3. Triage, dispatch, synthesize, save

Follow the Workflow section from the guidelines:

1. **Triage**: Select agent perspectives based on story content
2. **Dispatch**: Launch parallel Explore subagents per perspective using the template from the guidelines
3. **Synthesize**: Combine results following the Scoring & Synthesis Approach
4. **Save**: Call `mcp__storyflow__refine-story` with synthesized results
5. **Report**: Display results and suggest available transitions
