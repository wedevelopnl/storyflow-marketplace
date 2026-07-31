---
name: price-story
description: "Price a refined story using agency-specific pricing guidelines. Fetches guidelines with hourly rate, analyzes refinement data, calculates price, confirms with the architect, and saves via MCP."
disable-model-invocation: true
allowed-tools: mcp__storyflow__get-story, mcp__storyflow__get-pricing-guidelines, mcp__storyflow__price-story, AskUserQuestion
argument-hint: "<story-id>"
---

# Price a Story

Calculate and set the price for a refined story based on the agency's pricing guidelines.

## Arguments

The user provides a story ID as argument: `/storyflow:price-story <id>`

If no ID is provided, ask the user for one. Suggest running `/storyflow:briefings` to see available briefings and stories.

## Process

### 1. Load story

Call `mcp__storyflow__get-story` with the provided ID.

**Status pre-requisite**: A story must be in `Refined` status to be priced. If the story is not yet refined, inform the user and suggest `/storyflow:refine-story <id>` first. Do not proceed.

If the story already has a price, show the existing price and ask whether to re-price. If the user declines, stop.

### 2. Fetch pricing guidelines

Call `mcp__storyflow__get-pricing-guidelines`. This returns:
- Hour estimation ranges
- Risk buffer guidance
- The agency's hourly rate and price calculation formula

These guidelines are the single source of truth for pricing.

### 3. Calculate price

Using the story's refinement data (the analysis document and story points) and the pricing guidelines:

1. Estimate the hours following the guideline ranges
2. Apply risk buffers as specified
3. Calculate: `estimatedHours * hourlyRateInCents = priceInCents`
4. Round to the nearest EUR 5 (500 cents)

### 4. Confirm with architect

Present the pricing proposal using `AskUserQuestion`. **Wait for confirmation before saving.**

```
## Price Proposal: [story key] - "[title]"

| | |
|---|---|
| Story Points | [points] |
| Estimated Hours | [hours] |
| Hourly Rate | EUR [rate] |
| **Price** | **EUR [price]** |

Reasoning: [brief explanation of the hour estimate based on the refinement data]

Confirm this price? (yes / adjust / skip)
```

If the user wants to adjust, ask for the corrected price or hours and recalculate.

### 5. Save price

Call `mcp__storyflow__price-story` with:
- `storyId`: the story ID
- `priceInCents`: the confirmed price in cents
- `currency`: `EUR`

### 6. Report

Display the result:

```
Story [key] priced at EUR [price].

Next steps:
- Use `/storyflow:briefing <briefing-key>` to see the briefing overview with all story prices
```
