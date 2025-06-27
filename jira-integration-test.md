# Jira Integration Test

This file is created to test the Jira integration workflow. This test focuses on the jira-integration.yml workflow to check if it can properly authenticate with Jira.

## Test Details
- Date: June 26, 2025
- Issue: INVEST-2205
- Test focus: Jira authentication and API interaction

## Expected Results
- The workflow should successfully authenticate with Jira
- The workflow should correctly identify the Jira issue from the PR title
- If PR is merged, it should attempt to transition the Jira issue to the next status
