# Developer Guide: Using GitHub-Jira Integration

This guide explains how to leverage the automated GitHub-Jira integration in your workflow.

## What It Does

Our GitHub-Jira integration automatically:
- Links PRs to Jira tickets
- Updates PR descriptions with Jira details
- Transitions Jira tickets when PRs are opened or merged

## How to Use It

### 1. Reference Jira Tickets

Always include the Jira ticket key in **either**:
- Your branch name: `feature/INVEST-123-new-feature`
- Your PR title: `INVEST-123: Add new login screen`

### 2. PR Creation & Merging

- When you create a PR, the Jira ticket will automatically move to "In Progress"
- When your PR is merged, the Jira ticket will automatically move to "Complete"

### 3. That's It!

No additional steps or manual updates needed. The integration takes care of everything.

## Troubleshooting

If the integration isn't working:
1. Check that your branch name or PR title includes the correct Jira ticket key
2. Ensure the PR is properly linked to your branch
3. Contact the DevOps team if issues persist

## Example

**Branch name:**
```
feature/INVEST-456-add-login-button
```

**PR title:**
```
INVEST-456: Add login button to home screen
```

**Result:**
- PR description will be updated with Jira ticket details
- INVEST-456 will move to "In Progress" when PR is created
- INVEST-456 will move to "Complete" when PR is merged
