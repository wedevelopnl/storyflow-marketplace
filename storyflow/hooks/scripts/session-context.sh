#!/bin/bash
# Detect StoryFlow configuration on session start.
# Reads .storyflow/config.json and resolves the active asset by matching
# $CLAUDE_PROJECT_DIR against each asset's working_dir.
set -euo pipefail

CONFIG_FILE="$CLAUDE_PROJECT_DIR/.storyflow/config.json"
LEGACY_CONFIG="$CLAUDE_PROJECT_DIR/.claude/storyflow.local.md"

if [ -f "$CONFIG_FILE" ]; then
  message=$(CWD="$CLAUDE_PROJECT_DIR" python3 -c "
import json, os, sys

cwd = os.environ.get('CWD', '')

try:
    with open('$CONFIG_FILE') as f:
        cfg = json.load(f)
except Exception:
    print('StoryFlow: Config file is not valid JSON. Run /storyflow:setup to reconfigure.')
    sys.exit(0)

project = cfg.get('project') or {}
customer = project.get('customer_name', '')
project_name = project.get('name', '')
assets = project.get('assets') or []

if not customer:
    print('StoryFlow: Config found but incomplete. Run /storyflow:setup to reconfigure.')
    sys.exit(0)

label = customer if not project_name else customer + ' / ' + project_name

if not assets:
    print('StoryFlow: Connected to ' + label + ' (no assets configured). Run /storyflow:setup once an asset is added in StoryFlow.')
    sys.exit(0)

# Resolve active asset via cwd match against each asset's working_dir.
matches = []
for a in assets:
    wd = a.get('working_dir') or ''
    if not wd:
        continue
    if cwd == wd or cwd.startswith(wd.rstrip('/') + '/'):
        matches.append(a)

if len(matches) == 1:
    active = matches[0].get('name', '?')
    if len(assets) == 1:
        print('StoryFlow: Connected to ' + label + ' / ' + active + '. Use /storyflow:briefings to see available work.')
    else:
        print('StoryFlow: Connected to ' + label + ' / ' + active + ' (' + str(len(assets)) + ' assets in project). Use /storyflow:briefings to see available work.')
elif len(matches) > 1:
    names = ', '.join(m.get('name', '?') for m in matches)
    print('StoryFlow: Connected to ' + label + '. Multiple assets match this directory (' + names + '); resolve manually per command.')
else:
    asset_names = ', '.join(a.get('name', '?') for a in assets)
    print('StoryFlow: Connected to ' + label + '. This cwd does not match any configured asset (' + asset_names + '); skills will ask which asset to use.')
" 2>/dev/null || echo "")

  if [ -n "$message" ]; then
    echo "$message"
  else
    echo "StoryFlow: Config found but could not be parsed. Run /storyflow:setup to reconfigure."
  fi
elif [ -f "$LEGACY_CONFIG" ]; then
  echo "StoryFlow: Legacy config detected (.claude/storyflow.local.md). Run /storyflow:setup to reconfigure."
else
  echo "StoryFlow plugin is installed but not configured for this project. Run /storyflow:setup to link this project to a customer and its assets."
fi
