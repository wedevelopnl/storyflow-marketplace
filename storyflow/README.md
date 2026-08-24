# StoryFlow Plugin for Claude Code

Connect Claude Code to the StoryFlow platform. The plugin ships the StoryFlow MCP server plus four skills, for agency Software Architects working on client codebases.

The MCP toolset is the interface: briefings, stories, epics, releases, refinement, pricing, transitions and asset documentation are all tools, and their descriptions carry their own contracts. `/storyflow:guide` explains how the pieces fit together, and loads on its own when StoryFlow work comes up.

## Requirements

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) installed and running
- A StoryFlow account with an agency role (Software Architect, PO, Admin, or Finance)

## Installation

### 1. Add the marketplace

```
/plugin marketplace add wedevelopnl/storyflow-marketplace
```

### 2. Install the plugin

```
/plugin install storyflow@storyflow-marketplace
```

### 3. Authenticate with StoryFlow

Run the following command to authenticate via your browser:

```
claude mcp auth storyflow
```

This opens your browser where you sign in to StoryFlow. Once approved, Claude Code stores the credentials automatically.

### 4. Configure your project

Start Claude Code in your project directory and run:

```
/storyflow:setup
```

This links the current codebase to its StoryFlow **asset**, detected from the git remote URL. An asset is a codebase belonging to one customer, and it is the only thing a checkout maps onto one-to-one.

Setup does not ask which project the codebase belongs to, because there is no such thing: an asset is worked on under any number of projects at once (a redesign, a maintenance retainer, a release train). Project is a property of the work. Briefings, stories, epics, initiatives and releases pick one when they are created, from the projects that contain the asset (`list-projects` with `assetId`).

### Other MCP clients

The plugin targets Claude Code, but the StoryFlow MCP server works with any MCP client: Claude Desktop, ChatGPT, Cursor, VS Code, or a Personal Access Token bridge for clients without OAuth support. See the [MCP client setup guide](https://git.wdvlp.nl/wedevelop/storyflow/-/blob/main/docs/reference/mcp-client-setup.md) for per-client instructions.

## Skills

| Skill | Description |
|-------|-------------|
| `/storyflow:setup` | Link this codebase to its StoryFlow asset |
| `/storyflow:guide` | How StoryFlow works: the data model, the local config, resolving a project, and which guidelines to fetch before writing |
| `/storyflow:refine-story <id>` | Refine a single story with multi-agent analysis |
| `/storyflow:refine-briefing <id>` | Refine all stories of a briefing with multi-agent analysis |

`/storyflow:guide` is also auto-triggered by Claude when StoryFlow work comes up, so the domain model is available without asking for it.

Everything else runs through the MCP toolset directly.

## Guidelines come from StoryFlow

The agency's standards for writing briefings, writing stories, refining, pricing and documenting an asset are served by the application itself: `get-briefing-guidelines`, `get-story-guidelines`, `get-briefing-to-stories-guidelines`, `get-refinement-guidelines`, `get-pricing-guidelines` and `get-asset-documentation-guidelines`. They are the same ones the in-app assistants use, so a change to agency standards reaches the architect without a plugin release.

## How it works

The plugin uses MCP (Model Context Protocol) to connect to the StoryFlow API. Authentication is handled via OAuth 2.1: Claude Code automatically manages the token lifecycle through the standard MCP OAuth flow.
