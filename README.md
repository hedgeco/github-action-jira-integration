# GitHub Action: Jira Integration

This reusable GitHub Action automates the integration between GitHub pull requests and Jira issues. It streamlines your development workflow by automatically updating Jira issues as you work with pull requests.

> **Note:** This action was thoroughly tested with INVEST-2204 and INVEST-2205 tickets on June 25-27, 2025.

## Features

- 🔍 Automatically extracts Jira issue keys from PR titles or branch names
- 📝 Adds Jira issue details to PR descriptions
- ⚙️ Transitions Jira issues when PRs are opened (configurable transition)
- ✅ Transitions Jira issues when PRs are merged (configurable transition)
- 💬 Adds comments to Jira issues with PR links
- 🔄 Smart transition selection based on your Jira workflow
- 🧩 Compatible with different Jira workflows and project configurations

## Setup Instructions

### 1. Generate a Jira API Token

1. Log in to your Atlassian account at [id.atlassian.com](https://id.atlassian.com/)
2. Navigate to **Security → API tokens**
3. Click **Create API token**
4. Give it a name like "GitHub Action Integration"
5. Click **Create** and copy the generated token (you won't be able to see it again!)

### 2. Add Required Secrets

Go to your repository's **Settings → Secrets and variables → Actions** and add these repository secrets:

- `JIRA_BASE_URL`: Your Jira instance URL (e.g., `https://yourcompany.atlassian.net`)
- `JIRA_USER_EMAIL`: The email associated with your Jira API token
- `JIRA_API_TOKEN`: The API token you generated in step 1

### 3. Create the Workflow File

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
      - name: Checkout code
        uses: actions/checkout@v3
        
      - name: Run GitHub-Jira Integration
        uses: hedgeco/github-action-jira-integration@main
        with:
          jira-base-url: ${{ secrets.JIRA_BASE_URL }}
          jira-user-email: ${{ secrets.JIRA_USER_EMAIL }}
          jira-api-token: ${{ secrets.JIRA_API_TOKEN }}
          pr-open-transition: 'In Progress'  # Change as needed
          pr-merge-transition: 'Complete'    # Change as needed
          # jira-project-key: 'PROJ'         # Optional: Limits to specific project
```

> **Note:** We've included the checkout step explicitly to ensure the action runs properly. You can also use the `workflow-template.yml` file from this repository as a reference.

### 4. Verify Your Setup

After creating the workflow file and setting up secrets, you can verify your setup using the included verification script:

```powershell
.\verify-setup.ps1 -JiraAPIToken "your-token-here" -JiraIssueKey "PROJ-123"
```

This script will check your Jira connection, authentication, and workflow configuration to ensure everything is set up correctly.

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

## Utility Scripts

This action includes several utility scripts to help you set up, test, and troubleshoot your Jira integration:

### Essential Scripts

| Script | Purpose | Example |
|--------|---------|---------|
| `test-jira-auth.ps1` | Test basic Jira authentication | `.\scripts\test-jira-auth.ps1 -JiraAPIToken "your-token"` |
| `check-jira-issue-transitions.ps1` | List available transitions for an issue | `.\scripts\check-jira-issue-transitions.ps1 -JiraAPIToken "your-token" -JiraIssueKey "PROJ-123"` |
| `debug-jira-token.ps1` | Detailed diagnostics for token issues | `.\scripts\debug-jira-token.ps1 -JiraAPIToken "your-token"` |
| `update-github-secret-enhanced.ps1` | Update GitHub repository secrets | `.\scripts\update-github-secret-enhanced.ps1 -JiraAPIToken "your-token" -RepoName "owner/repo"` |
| `verify-setup.ps1` | Verify your integration setup | `.\verify-setup.ps1 -JiraAPIToken "your-token"` |

> **Tip:** Always run these scripts before configuring your workflow to ensure your Jira connection works properly.

## Advanced Configuration

### Customizing Jira Transitions

The action provides a simple way to customize transitions based on your Jira workflow:

1. **Analyze your Jira workflow** using the included script:
   ```powershell
   # From the scripts directory:
   .\check-jira-issue-transitions.ps1 -JiraAPIToken "your-token-here" -JiraIssueKey "PROJ-123"
   ```

2. **Update your workflow file** with the specific transition names:
   ```yaml
   with:
     # ... other parameters
     pr-open-transition: 'Start Development'   # Use exact names from your workflow
     pr-merge-transition: 'Ready for Testing'
   ```

### Project-Specific Configuration

To limit the action to specific Jira projects:

```yaml
with:
  # ... other parameters
  jira-project-key: 'PROJ'  # Only process issues from this project
```

## Troubleshooting

If the integration is not working as expected:

### 1. Verify Authentication

Test your Jira credentials with the included script:
```powershell
.\scripts\test-jira-auth.ps1 -JiraAPIToken "your-token-here"
```

### 2. Check Jira Transitions

Ensure the transitions you've specified match your Jira workflow:
```powershell
.\scripts\check-jira-issue-transitions.ps1 -JiraAPIToken "your-token-here" -JiraIssueKey "PROJ-123"
```

### 3. Debug Common Issues

- **No Jira key found**: Ensure your PR title or branch name includes a valid Jira issue key (e.g., `PROJ-123`)
- **Authentication failure**: Check that your Jira API token is correct and has not expired
- **Wrong transitions**: Verify that the transition names match exactly with your Jira workflow
- **Workflow errors**: Check GitHub Actions logs for detailed error messages
- **Base64 encoding issues**: Ensure your token doesn't contain special characters that might interfere with encoding
- **Secret formatting**: Make sure your GitHub secrets don't have extra spaces or newlines
- **Permission issues**: Verify the Jira user has permission to transition the issues
- **Case sensitivity**: Jira project keys are case-sensitive (e.g., `PROJ-123` not `proj-123`)

### 4. Update GitHub Secrets

If you need to update your Jira API token:
```powershell
.\scripts\update-github-secret-enhanced.ps1 -JiraAPIToken "your-new-token-here"
```

## License

This project is licensed under the MIT License.
