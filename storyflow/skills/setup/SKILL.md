---
name: setup
description: "Configure the StoryFlow plugin for the current codebase by linking it to its asset. Auto-detects the asset via the git remote URL and writes config. Use when setting up StoryFlow for the first time in a project."
disable-model-invocation: true
allowed-tools: mcp__storyflow__get-current-user, mcp__storyflow__get-asset-by-url, mcp__storyflow__list-assets, mcp__storyflow__list-customers, mcp__storyflow__get-asset, Read, Write, Glob, AskUserQuestion, Bash
argument-hint: ""
---

# StoryFlow Setup

Link this codebase to its StoryFlow **asset**. An asset is a codebase belonging to one customer, and it is the only thing a local checkout maps onto one-to-one.

Setup does **not** ask for a project. An asset is worked on under any number of projects at the same time (a redesign, a maintenance retainer, a release train), so "the project of this checkout" has no answer. Project is a property of the work, not of the directory: briefings, stories, epics, initiatives and releases pick one at the moment they are created, from the projects that contain the active asset. `/storyflow:guide` has the rule for resolving one.

## Process

1. **Verify connection**: Call `get-current-user` to verify MCP connection and authentication. If it fails, guide the user:

   **a)** They need to authenticate first. Run:
   ```
   claude mcp auth storyflow
   ```
   This opens their browser to sign in to StoryFlow. Once approved, credentials are stored automatically.

   **b)** If connection still fails, check that the plugin's MCP server is loaded. Run `/mcp` to verify the "storyflow" server appears.

   On success, greet the user by name (from the response) and confirm the connection works.

2. **Detect the asset from this codebase**:

   Run `git remote get-url origin` to get the repository URL. Then call `get-asset-by-url` with that URL.

   - **If a match is found**: show the asset name, key, type and customer, and confirm with the user. Capture `id`, `key`, `name`, `type`, repository URL and production URL of the asset, plus the customer's `id` and `name`.
   - **If no match**: fall back to step 3.

3. **Manual asset selection** (only if auto-detect failed): call `list-assets` and let the user pick with `AskUserQuestion`. Group the options by customer. Then tell them to fill in the repository URL on that asset in StoryFlow, so the next checkout detects itself.

   If no asset fits, the codebase has no asset in StoryFlow yet: tell the user to create one there (with this repository URL) and re-run setup. Do not write a config without an asset.

4. **Create config file**: create the `.storyflow/` directory if it doesn't exist, then write `.storyflow/config.json`:

```json
{
  "version": 2,
  "customer": {
    "id": "<customer-uuid>",
    "name": "<customer-name>"
  },
  "assets": [
    {
      "id": "<asset-uuid>",
      "key": "<asset-key>",
      "name": "<asset-name>",
      "type": "<asset-type>",
      "repository_url": "<repo-url>",
      "production_url": "<prod-url-or-null>",
      "working_dir": "<absolute-path-to-this-checkout>"
    }
  ]
}
```

   - `working_dir` of the detected asset is `$CLAUDE_PROJECT_DIR`, filled in without asking.
   - `assets` is an array because one checkout can hold several assets (a monorepo whose parts are separate assets in StoryFlow). Setup writes the one it detected; a second entry is added by re-running setup from that codebase, or by hand.
   - `production_url` may be `null`.
   - There is no `project` key. Anything that needs a project resolves it per action.

5. **Verify .gitignore**: read the project's `.gitignore` and check that `.storyflow/` is listed. If not, suggest adding it (the config contains ids specific to this machine and checkout).

6. **Confirm**: tell the user setup is complete. Show a summary:

   ```
   Customer: [customer name]
   Asset:    [asset name] ([key], [type])
   Checkout: [working_dir]
   ```

   Suggest starting a new session to see the SessionStart context, and running `/storyflow:guide` for how to work with StoryFlow from here.

## Reconfiguring

Re-running setup on a codebase that already has `.storyflow/config.json` rewrites it. Read the existing file first and keep any extra asset entries whose `working_dir` still exists, so a monorepo setup is not lost.
