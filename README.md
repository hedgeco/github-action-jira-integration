# GitHub Action: Jira Integration

This reusable GitHub Action automates the integration between GitHub pull requests and Jira issues.

> **Note:** This action was tested with INVEST-2204 and works correctly.

## Features

- 🔍 Automatically extracts Jira issue keys from PR titles or branch names
- 📝 Adds Jira issue details to PR descriptions
- ⚙️ Transitions Jira issues when PRs are opened
- ✅ Transitions Jira issues when PRs are merged
- 💬 Adds comments to Jira issues with PR links

## Setup Instructions

### 1. Create Workflow File

Create a `.github/workflows/jira-integration.yml` file in your repository:

```yaml
name: Jira Integration

on:
  pull_request:
    types: [opened, reopened, edited, closed]

jobs:
  jira-integration:
    runs-on: ubuntu-latest
    steps:
      - uses: hedgeco/github-action-jira-integration@main
        with:
          jira-base-url: ${{ secrets.JIRA_BASE_URL }}
          jira-user-email: ${{ secrets.JIRA_USER_EMAIL }}
          jira-api-token: ${{ secrets.JIRA_API_TOKEN }}
          pr-open-transition: 'In Progress'  # Change as needed
          pr-merge-transition: 'Complete'    # Change as needed
          jira-project-key: 'INVEST'         # Optional: Limits to specific project
```

### 2. Add Required Secrets

Go to your repository's **Settings > Secrets and variables > Actions** and add these secrets:

- `JIRA_BASE_URL`: Your Jira instance URL (e.g., `https://smartx.atlassian.net`)
- `JIRA_USER_EMAIL`: The email associated with your Jira API token
- `JIRA_API_TOKEN`: Your Jira API token

## Usage

Simply include the Jira issue key in either:
- Your branch name (e.g., `feature/INVEST-123-new-feature`)
- Your PR title (e.g., `INVEST-123: Add new login screen`)

The workflow will automatically:
1. Add Jira issue details to the PR description
2. Update the Jira issue status when the PR is opened
3. Update the Jira issue status when the PR is merged

## Configuration Options

| Input | Description | Required | Default |
|-------|-------------|---------|---------|
| `jira-base-url` | Your Jira instance URL | Yes | - |
| `jira-user-email` | Email for Jira authentication | Yes | - |
| `jira-api-token` | Jira API token | Yes | - |
| `github-token` | GitHub token for authentication | No | `${{ github.token }}` |
| `pr-open-transition` | Transition when PR is opened | No | `In Progress` |
| `pr-merge-transition` | Transition when PR is merged | No | `Complete` |
| `jira-project-key` | Specific Jira project key | No | - |

## Troubleshooting

If the integration is not working as expected:

1. Check that your Jira API token has appropriate permissions
2. Verify that the transition names match those in your Jira workflow
3. Ensure your PR title or branch name includes a valid Jira issue key

## License

This project is licensed under the MIT License.
