# INVEST-2205 Final Verification Test

This file is created to perform a final end-to-end test of the GitHub-Jira integration action.

## Test Details
- Date: June 26, 2025
- Issue: INVEST-2205
- PR Branch: test/INVEST-2205-final-verification

## Expected Behavior
1. When PR is opened:
   - GitHub Action correctly identifies INVEST-2205 from the PR
   - Jira issue details are added to the PR description

2. When PR is merged:
   - GitHub Action transitions the Jira issue to the next appropriate status
   - A comment with the PR link is added to the Jira issue

## Verification Results
- [ ] PR opened workflow ran successfully
- [ ] Jira issue details added to PR description
- [ ] PR merge workflow ran successfully
- [ ] Jira issue transitioned to next status
- [ ] PR link comment added to Jira issue

## Notes
This test is being performed after fixing YAML syntax issues in the workflow file.
