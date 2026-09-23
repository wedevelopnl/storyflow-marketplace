---
name: guide
description: "How StoryFlow works and how to work with it: the data model, the story lifecycle, briefings as intake, the local config, resolving a project, which guidelines to fetch before writing, how the story key travels into branches, commits and merge requests, and when the story's status moves with the work. Use whenever working with StoryFlow stories, briefings, epics, releases or refinement, and when starting, committing or opening a merge request for work that belongs to a story."
---

# Working with StoryFlow

## Read the guide from StoryFlow first

Call `mcp__storyflow__get-storyflow-guide` and follow it. It explains the data model, the story and incident lifecycles, briefings, how to resolve a project, which guidelines to fetch before writing, how the story key travels into branches, commits and merge requests, and when the story's status moves with the work. StoryFlow serves it with every release, tailored to your role and with your agency's portal host filled in, so it always matches the version you are talking to.

Read it once per session, before the first StoryFlow action. Do not work from a memory of what it said in an earlier session.

What follows is the part StoryFlow cannot know: how this checkout is linked to it.

## The local config

`.storyflow/config.json` in the project root links this checkout to StoryFlow:

```json
{
  "version": 3,
  "portal_url": "<portal-url>",
  "customer": { "id": "<uuid>", "name": "<name>" },
  "assets": [
    {
      "id": "<uuid>",
      "key": "<key>",
      "name": "<name>",
      "type": "<type>",
      "repository_url": "<url>",
      "production_url": null,
      "working_dir": "/absolute/path/to/this/checkout"
    }
  ]
}
```

If the file is missing or incomplete, run `/storyflow:setup`.

**Resolving the active asset**: match the current working directory against each asset's `working_dir`, either exactly or as a parent directory. One match is the active asset. Several matches or none: ask which asset to use, do not guess. `assets` is an array because one checkout can hold several assets, as in a monorepo whose parts are separate assets in StoryFlow.

The active asset and its customer are what the guide means by "the asset the work is on" when it resolves a project. The config holds no project on purpose: the guide explains why.

**The portal url**: `portal_url` is the host this agency's users log in on, the same host the guide names. When the two differ, the guide is current and the config is stale: suggest re-running `/storyflow:setup`. A config written before version 3 has no `portal_url`; the guide still gives you the host.
