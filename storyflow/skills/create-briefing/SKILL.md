---
name: create-briefing
description: "Create a new briefing in StoryFlow from conversation context, plan files, or free text. Fetches guidelines, drafts a structured briefing document, iterates with the architect, and uploads after approval."
disable-model-invocation: true
allowed-tools: mcp__storyflow__get-briefing-guidelines, mcp__storyflow__create-briefing, mcp__storyflow__get-briefing, Read, Glob, Grep, Bash, Agent, AskUserQuestion
argument-hint: "[description or path to plan file]"
---

# Create Briefing

Create a new briefing in StoryFlow from conversation context, plan files, or free text input.

## Arguments

The user may provide:
- A free-text description of what the briefing should cover
- A path to a plan or spec file (e.g., `docs/superpowers/specs/2026-03-30-feature-design.md`)
- Nothing (the skill will ask what the briefing should describe)

If no argument is provided and there is relevant context from the current conversation (a discussed feature, plan, or requirement), use that as the starting point. If no context is available either, ask the user what the briefing should describe.

## Process

### 0. Load project context and resolve active asset

Read `.storyflow/config.json`.

- If the file does not exist: tell the user to run `/storyflow:setup` first. Do not proceed without config.

Capture `project.id` (as `projectId`), `project.customer_id`, `project.customer_name`, and `project.assets[]`.

**Resolve the active asset** (the asset the new briefing will belong to):

- If `project.assets` is empty: stop and tell the user this project has no assets configured. A briefing must belong to an asset, so they need to add one in StoryFlow and re-run `/storyflow:setup`.
- If exactly one asset: that's the active asset.
- If multiple assets: match `$CLAUDE_PROJECT_DIR` against each asset's `working_dir` (exact match, or cwd inside `working_dir`). If exactly one matches, that's the active asset. Otherwise use `AskUserQuestion` to let the user pick from the asset names.

Capture the active asset's `id` as `assetId` and `name` as `assetName`. Use `assetName` everywhere the document references the asset.

### 1. Fetch guidelines

Call `mcp__storyflow__get-briefing-guidelines` to retrieve the briefing writing guidelines.

These guidelines define the document structure and quality criteria. Follow them strictly throughout the process.

### 2. Gather context

Collect input from the available sources:

1. **Argument**: If the user provided text or a file path, read and use it as primary input
2. **Plan/spec files**: If the argument references a file, or if the conversation references plan files, read them with the Read tool
3. **Conversation context**: Use what has been discussed in the current session (features, requirements, decisions)

If there is no usable input from any source, ask the user:

> What should this briefing describe? You can explain the feature, paste requirements, or point me to a plan file.

### 3. Optional codebase analysis

Ask the user whether a codebase analysis would help inform the briefing (e.g., to understand existing user roles, features, data models, or workflows).

Only run the analysis if the user confirms. If yes, dispatch the `codebase-analyzer` agent with:

> Asset: "[asset name]"
> Briefing topic: "[brief description of what the briefing covers]"
>
> Analyze the codebase in the current working directory to understand existing functionality relevant to the topic above. Focus on: user roles, existing features, data models, and workflows that relate to this requirement.

### 4. Draft briefing

Using the gathered context, draft a complete briefing document following the document structure, language style, and quality criteria from the guidelines fetched in step 1.

**Title selection**: Before drafting the full document, propose 2-3 concise title options and let the user choose. Good titles are short, specific, and describe the feature from the user's perspective (e.g., "Invoice PDF Export", "Multi-language Support", "Customer Dashboard Redesign").

Then draft all sections as defined in the guidelines.

### 5. Gap analysis

Check the draft against the completeness checklist from the guidelines (fetched in step 1). For any gaps found, ask targeted questions to fill them. Do not ask about all gaps at once. Prioritize the most critical gaps first.

### 6. Final review

Present the complete briefing for approval:

```
## Briefing Review

**Title:** [chosen title]
**Asset:** [asset name]

### Overview
[content]

### Context
[content]

### User Roles
[content]

### Requirements
[content]

### Business Rules
[content]

### Out of Scope
[content]

---

Ready to upload to StoryFlow? You can:
- Request changes to specific sections (e.g., "add an edge case for empty data")
- Say **"upload"** to create the briefing
```

Iterate until the user says "upload" or equivalent confirmation.

### 7. Upload

After the user approves:

1. Call `mcp__storyflow__create-briefing` with `projectId`, `assetId`, `title`, and `content` (the full document as markdown)
2. Extract the briefing ID from the response

### 8. Verify and report

1. Call `mcp__storyflow__get-briefing` with the new briefing ID to verify it was created correctly
2. Display the result:

```
Briefing created: [KEY] - "[title]"
ID: [uuid]
Status: [status]

[Available transitions from the response]

Next steps:
- Share the briefing with your client for review
- Use `/storyflow:briefing [KEY]` to view the full briefing
- Use `/storyflow:briefing-to-stories [KEY]` after the briefing is accepted
```
