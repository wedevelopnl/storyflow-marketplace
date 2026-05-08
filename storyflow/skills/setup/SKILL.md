---
name: setup
description: "Configure the StoryFlow plugin for the current project by linking it to a customer and one or more assets. Auto-detects the project via Git URL, fetches all assets in the project, captures their working directories, and writes config. Use when setting up StoryFlow for the first time in a project."
disable-model-invocation: true
allowed-tools: mcp__storyflow__get-current-user, mcp__storyflow__get-asset-by-url, mcp__storyflow__list-assets, mcp__storyflow__list-projects, mcp__storyflow__get-asset, Read, Write, Glob, AskUserQuestion, Bash
argument-hint: ""
---

# StoryFlow Setup

Configure the StoryFlow plugin for the current project. A StoryFlow project belongs to one customer and contains zero or more assets (codebases). The plugin works with the project as a whole and resolves the active asset per command based on the current working directory.

## Process

1. **Verify connection**: Call `get-current-user` to verify MCP connection and authentication. If it fails, guide the user:

   **a)** They need to authenticate first. Run:
   ```
   claude mcp auth storyflow
   ```
   This opens their browser to sign in to StoryFlow. Once approved, credentials are stored automatically.

   **b)** If connection still fails, check that the plugin's MCP server is loaded. Run `/mcp` to verify the "storyflow" server appears.

   On success, greet the user by name (from the response) and confirm the connection works.

2. **Detect the project from this codebase**:

   Run `git remote get-url origin` to get the repository URL. Then call `get-asset-by-url` with that URL.

   - **If a match is found**: Show the asset name, customer, project name, and asset type. Confirm with the user. Capture `project.id`, `project.key`, `project.name`, `customer.id`, `customer.name` from the response.
   - **If no match**: Fall back to step 3.

3. **Manual project selection** (only if auto-detect failed): Call `list-projects` and present the available projects (grouped by customer). Ask the user which project this codebase belongs to. If none match, suggest they add the asset in StoryFlow first with the correct repository URL, then re-run setup.

4. **Fetch all assets in the project**:

   Call `list-assets` with the `customerId` filter (and `projectId` if the MCP supports it; otherwise filter the result locally on `project.id` or `project_id`). Capture the full asset list for the project: `id`, `key`, `name`, `type`, `repository_url`, `production_url`.

   - **0 assets**: the project has no assets yet. Continue, the config will store an empty `assets` array. Most skills will refuse to run until at least one asset is configured.
   - **1 or more assets**: continue to step 5.

5. **Capture working directories**:

   For each asset:

   - If the asset's `repository_url` matches the current `git remote get-url origin`: pre-fill `working_dir` with `$CLAUDE_PROJECT_DIR` (current project root). Do not ask, just confirm in the summary.
   - For every other asset: use `AskUserQuestion` to ask the user for the local checkout path, with options:
     - "Skip this asset for now" (leaves `working_dir` unset)
     - A free-text path (option label "Other" auto-provided)

   Working directories must be absolute paths. If the user provides a relative path, resolve it against `$HOME`.

6. **Configure output directory**: Use `AskUserQuestion` to ask where StoryFlow should save generated files (implementation plans, etc.). Suggest `docs/storyflow/` as default. **Wait for the user's response before proceeding.**

   - The path is relative to the project root of whichever asset the user is currently in.

7. **Create config file**: Create the `.storyflow/` directory if it doesn't exist, then write `.storyflow/config.json`:

```json
{
  "version": 1,
  "project": {
    "id": "<project-uuid>",
    "key": "<project-key>",
    "name": "<project-name>",
    "customer_id": "<customer-uuid>",
    "customer_name": "<customer-name>",
    "assets": [
      {
        "id": "<asset-uuid>",
        "key": "<asset-key>",
        "name": "<asset-name>",
        "type": "<asset-type>",
        "repository_url": "<repo-url>",
        "production_url": "<prod-url-or-null>",
        "working_dir": "<absolute-local-path-or-null>"
      }
    ]
  },
  "output_dir": "docs/storyflow"
}
```

   - `assets` is always an array, even with 0 or 1 entries.
   - `working_dir` may be `null` for assets the user hasn't checked out locally yet.
   - `production_url` may be `null`.

8. **Verify .gitignore**: Read the project's `.gitignore` and check that `.storyflow/` is listed. If not, suggest adding it (the config contains project-specific IDs that should not be committed).

9. **Confirm**: Tell the user setup is complete. Show a summary:

   ```
   Project: [project name] ([key])
   Customer: [customer name]
   Assets configured: [N]
     - [asset name] ([key])  cwd: [working_dir or "not set"]
     ...
   ```

   Suggest starting a new session to see the SessionStart context, and using `/storyflow:briefings` to see available work.
