---
name: refine-briefing
description: "Refine every ready story of a briefing with multi-agent analysis: confirms which stories qualify, refines each with one subagent per engineering perspective, and shows every refinement for approval before it is saved. The workflow, perspectives and document format come from StoryFlow."
disable-model-invocation: true
allowed-tools: mcp__storyflow__get-briefing, mcp__storyflow__get-briefing-stories, mcp__storyflow__get-story, mcp__storyflow__get-refinement-guidelines, mcp__storyflow__refine-story, Read, Grep, Glob, Agent
argument-hint: "<briefing-id>"
---

# Refine a briefing

The briefing is `$ARGUMENTS`: its id. Without one, ask for it; `mcp__storyflow__list-briefings` shows what is available.

Call `mcp__storyflow__get-refinement-guidelines` once and follow its **Refine a briefing** workflow for this briefing. StoryFlow serves that workflow together with the perspectives, the scoring and the document format, so it always matches the running version: follow it as served, not from memory of an earlier session.
