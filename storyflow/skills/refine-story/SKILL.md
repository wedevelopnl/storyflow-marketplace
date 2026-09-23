---
name: refine-story
description: "Refine a single story with multi-agent analysis: one subagent per engineering perspective, synthesized into one refinement that is shown for approval before it is saved. The workflow, perspectives and document format come from StoryFlow."
disable-model-invocation: true
allowed-tools: mcp__storyflow__get-story, mcp__storyflow__get-briefing, mcp__storyflow__get-refinement-guidelines, mcp__storyflow__refine-story, Read, Grep, Glob, Agent
argument-hint: "<story-id>"
---

# Refine a story

The story is `$ARGUMENTS`: a key (`WDV-42`) or a UUID. Without one, ask for it.

Call `mcp__storyflow__get-refinement-guidelines` and follow its **Refine one story** workflow for this story. StoryFlow serves that workflow together with the perspectives, the scoring and the document format, so it always matches the running version: follow it as served, not from memory of an earlier session.
