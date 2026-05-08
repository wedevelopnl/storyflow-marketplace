---
name: asset-documentation
description: "Generate or update asset documentation (functional, technical, or both) from the current codebase and save it to StoryFlow. Fetches generation guidelines from StoryFlow via MCP, analyzes the codebase locally, and saves documentation back."
disable-model-invocation: true
allowed-tools: mcp__storyflow__get-asset-documentation, mcp__storyflow__update-asset-documentation, mcp__storyflow__get-asset-documentation-guidelines, mcp__storyflow__list-assets, Read, Glob, Grep, Bash, Agent, AskUserQuestion
argument-hint: "[functional|technical|both]"
---

# Asset Documentation

Generate or update asset documentation from the current codebase and save it to StoryFlow.

## Arguments

Optional argument specifying documentation type: `functional`, `technical`, or `both` (default: `both`).

Examples:
- `/storyflow:asset-documentation` (generates both types)
- `/storyflow:asset-documentation functional`
- `/storyflow:asset-documentation technical`

## Process

1. **Read config and resolve active asset**: Read `.storyflow/config.json`.

   - If the file does not exist: tell the user to run `/storyflow:setup` first and stop.

   Inspect `project.assets[]`:

   - If empty: stop and tell the user this project has no assets configured. Documentation needs an asset to attach to.
   - If exactly one asset: that's the active asset.
   - If multiple assets: match `$CLAUDE_PROJECT_DIR` against each asset's `working_dir` (exact match, or cwd inside `working_dir`). If exactly one matches, that's the active asset. Otherwise use `AskUserQuestion` to let the user pick from the asset names. **Documentation always reflects the codebase you're currently in**, so the cwd match is the strongest signal. Warn the user if their pick mismatches the cwd.

   Capture the active asset's `id` as `assetId` and `name` as `assetName`.

2. **Get commit hash**: Run `git rev-parse HEAD` via Bash to get the current commit hash.

3. **Parse argument**: Determine which types to generate from the user's argument. Default to `both` if no argument provided.

4. **For each documentation type** (functional, technical, or both):

   a. **Check existing docs**: Call `mcp__storyflow__get-asset-documentation` with the asset ID and type.
      - Note the existing content and last commit hash (if any) for context.

   b. **Get generation prompt**: Call `mcp__storyflow__get-asset-documentation-guidelines` with the type.
      - This returns the same prompt instructions the ai-service uses internally.

   c. **Generate documentation**: Using the prompt instructions from step (b), analyze the codebase thoroughly:
      - Use Glob and Grep to explore the project structure
      - Read key files (README, config files, main entry points, route definitions, etc.)
      - Use an Agent (subagent_type: "Explore") for deeper codebase exploration if needed
      - Follow the prompt instructions to produce comprehensive markdown documentation
      - If existing documentation was found in step (a), use it as a reference for what to update/improve

   d. **Save documentation**: Call `mcp__storyflow__update-asset-documentation` with:
      - `assetId`: from the config
      - `type`: the documentation type
      - `content`: the generated markdown
      - `lastCommitHash`: from step 2

5. **Report results**: Show the user:
   - Which documentation types were generated/updated
   - The commit hash it was generated from
   - That the documentation is now visible in StoryFlow's asset documentation view
