---
name: claim-briefing
description: "Claim an accepted briefing to start implementing its stories. Assigns you as the Software Architect and pulls the briefing into your active workspace. Includes asset matching validation and confirmation prompt."
disable-model-invocation: true
allowed-tools: mcp__storyflow__get-briefing, mcp__storyflow__claim-briefing, Read
argument-hint: "<briefing-id>"
---

# Claim a Briefing

Claim an accepted briefing so you can start implementing its stories. An accepted briefing is one where the agency has committed to the work and the stories have been generated. From `Accepted` onwards the briefing's workflow status is automatically projected from its linked stories, so claiming does not change the briefing's workflow status: it assigns you as the Software Architect and pulls the briefing into your active workspace.

## Arguments

The user provides a briefing ID as argument: `/storyflow:claim-briefing <id>`

If no ID is provided, ask the user for one. Suggest running `/storyflow:briefings` to see available briefings.

## Process

1. **Load project context** (required): Read `.storyflow/config.json` to get `project.customer_name`, `project.name`, and `project.assets[]`.
   - If the file does not exist: tell the user to run `/storyflow:setup` first. Do not proceed without config.

2. **Fetch briefing**: Call `mcp__storyflow__get-briefing` with the provided ID to verify it exists and check its status.

3. **Safety check**: Compare the briefing's asset id against `project.assets[].id`.

   - If the briefing's asset is one of the configured assets: no warning.
   - If not: warn the user: "This briefing belongs to asset '[briefing asset name]', which is not part of this project (configured assets: [list of asset names]). Are you sure you want to proceed?" Wait for confirmation before continuing.

4. **Verify claimability**: Check the briefing's available transitions (included in the `get-briefing` response). If `claim` is not listed as an available transition, inform the user of the current status and the available transitions instead.

5. **Confirm with user**: Before claiming, show:
   ```
   About to claim briefing:
   Title: [title]
   Customer: [customer]
   Asset: [asset]

   This assigns you as the implementer. The briefing status follows its stories automatically: once you start working on the first story (move it to Doing), the briefing projection reflects that.
   Proceed? (yes/no)
   ```

6. **Claim briefing**: Call `mcp__storyflow__claim-briefing` with the briefing ID.

7. **Confirm success**: Show confirmation and suggest next steps:
   - "Briefing claimed successfully. You are now the assigned Software Architect."
   - "Next: Use `/storyflow:implement-briefing <id>` to generate an implementation plan."
   - "Or use `/storyflow:briefing <id>` to review the full context first."

8. **Post-claim onboarding**: After successful claim, show a quick checklist:
   ```
   Briefing claimed! Here's your checklist:
   - [ ] Review full briefing context: `/storyflow:briefing <id>`
   - [ ] Review individual stories: `/storyflow:story <key>`
   - [ ] Generate implementation plan: `/storyflow:implement-briefing <id>`
   - [ ] Start implementing the plan
   ```
