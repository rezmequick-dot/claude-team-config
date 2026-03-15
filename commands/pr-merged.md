---
description: Post-merge cleanup — checkout main, pull latest, delete the feature branch, and close the linked ADO work item.
argument-hint: PR number or branch name (optional — auto-detected from recently merged PRs if omitted)
---

# Post-Merge Cleanup

Run the following steps in order after a PR has been merged.

## Step 1: Identify the merged PR

If $ARGUMENTS is provided, treat it as either a PR number (e.g. `72`) or a branch name (e.g. `feature/foo`).

If $ARGUMENTS is empty:
- Run `gh pr list --state merged --limit 5` and pick the most recently merged PR
- Confirm with the user if it's ambiguous

Capture:
- `PR_NUMBER`
- `BRANCH_NAME` (the head branch of the PR)
- `PR_BODY` (full PR description — needed to extract the ADO ticket number)

## Step 2: Git cleanup

Run these in order:

```bash
git checkout main
git fetch origin
git pull origin main
git branch -d <BRANCH_NAME>          # safe delete (will fail if unmerged — good)
git push origin --delete <BRANCH_NAME>  # delete remote (ignore error if already gone)
```

Confirm `git log --oneline -1` matches the merge commit from the PR.

## Step 3: Close the ADO work item

Extract the ADO task/bug number from the PR body. Look for patterns like:
- `ADO #86`, `ADO Task #86`, `ADO Bug #86`
- `Closes ADO Task #86`, `Fixes ADO #86`
- `#86` near the words "ADO", "Azure", "Task", or "Bug"

If a number is found:

1. Read `AZURE_DEVOPS_AUTH_TOKEN` from the project's `.env` file
2. Use the ADO REST API to update the work item state:

```
PATCH https://dev.azure.com/applicationIngenuity/Sarah%20Sweeps/_apis/wit/workitems/<ID>?api-version=7.1
Content-Type: application/json-patch+json

[{ "op": "add", "path": "/fields/System.State", "value": "Closed" }]
```

Use Node.js to make the request (the `az` CLI is not available in this environment):

```js
const https = require('https');
const token = '<AZURE_DEVOPS_AUTH_TOKEN>';
const encoded = Buffer.from(':' + token).toString('base64');
const body = JSON.stringify([{ op: 'add', path: '/fields/System.State', value: 'Closed' }]);
const options = {
  hostname: 'dev.azure.com',
  path: '/applicationIngenuity/Sarah%20Sweeps/_apis/wit/workitems/<ID>?api-version=7.1',
  method: 'PATCH',
  headers: {
    'Authorization': 'Basic ' + encoded,
    'Content-Type': 'application/json-patch+json',
    'Content-Length': Buffer.byteLength(body)
  }
};
const req = https.request(options, (res) => {
  let data = '';
  res.on('data', d => data += d);
  res.on('end', () => {
    const parsed = JSON.parse(data);
    console.log(res.statusCode, 'State:', parsed.fields?.['System.State'], 'ID:', parsed.id);
  });
});
req.write(body);
req.end();
```

If no ADO number is found in the PR body, skip this step and note it in the summary.

## Step 4: Summary

Report back:
- Branch deleted (local + remote)
- `main` is now at commit: `<sha> <message>`
- ADO work item #`<N>` → Closed  (or "no ADO ticket found")
