# Resolving a project

Some StoryFlow artefacts belong to a project: briefings (required), stories (required before they can be approved), epics, initiatives and releases. The plugin config holds no project, and no default project per asset either.

The reason is the data model: an asset sits in any number of projects at once via a many-to-many link. A codebase is durable, a project is a unit of work and budget with a start and an end. "Which project does this checkout belong to" therefore has no answer, while "which project do you book this piece of work under" has one, at the moment the work is created.

## The rule

Resolve the project when an action needs it, never at setup time and never earlier in a skill than the step that uses it.

1. Call `mcp__storyflow__list-projects` with `assetId` set to the active asset, `customerId` from the config, and `status: "active"`. The `assetId` filter returns exactly the projects the asset is linked to; it accepts the asset UUID or its key.
2. Then, by the number of results:

   - **Exactly one**: use it. Do not ask. Name it in your output ("Project: WDV-PR-9 Maintenance") so the user can correct you.
   - **More than one**: ask with `AskUserQuestion`. Show key, name and billing model per option, and order the most likely first: a project whose name matches the work at hand, otherwise the one with the narrowest asset list (a project dedicated to this asset beats a customer-wide retainer).
   - **None**: the asset is not linked to any active project. Do not fall back to listing every project of the customer: `create-briefing` refuses a project the asset does not belong to, so an unlinked project cannot carry this work. Tell the user to link the asset to a project in StoryFlow (or to create the project there), and stop.

3. Keep the chosen project for the rest of the session's action. Do not write it to `.storyflow/config.json`.

## What not to do

- Do not ask "which project does this codebase belong to". That question has no answer and the user cannot give a lasting one.
- Do not infer a project from the asset's support project. That field routes incidents; it says nothing about where new work is booked.
- Do not cache a "default project" anywhere. The next briefing may well belong to another project, and a stale default silently books work against the wrong budget.
