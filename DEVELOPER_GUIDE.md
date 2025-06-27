# Developer Guide: GitHub-Jira Integration

This comprehensive guide explains how to set up, use, and troubleshoot the GitHub-Jira integration action. It provides step-by-step instructions for developers and DevOps engineers to seamlessly connect GitHub pull requests with Jira issues.

## Initial Setup

### Installation Steps

1. **Copy the workflow template** to your repository:
   
   Create a `.github/workflows/jira-integration.yml` file using the provided template:

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
             pr-open-transition: 'In Progress'
             pr-merge-transition: 'Complete'
   ```

   > **Note:** You can also use the `workflow-template.yml` file from this repository as a starting point.

2. **Set up required secrets** in your repository:
   
   Navigate to **Settings → Secrets and variables → Actions** and add:
   
   - `JIRA_BASE_URL`: Your Jira instance URL (e.g., `https://yourcompany.atlassian.net`)
   - `JIRA_USER_EMAIL`: Email associated with your Jira account
   - `JIRA_API_TOKEN`: API token generated from your Atlassian account

3. **Verify your setup**:

   Use the included verification script to check that your Jira connection and configuration are working properly:

   ```powershell
   # From the repository root:
   .\verify-setup.ps1 -JiraAPIToken "your-token-here" -JiraIssueKey "PROJ-123"
   ```

   This script will:
   - Test your Jira authentication
   - Check if the specified issue exists
   - List available transitions for the issue
   - Verify your action.yml and workflow configurations

4. **Test the installation**:
   
   Create a test PR with a Jira issue key in the title or branch name to verify everything works.

## Day-to-Day Usage

### Referencing Jira Tickets

Always include the Jira ticket key in **either**:

- **Branch name**: `feature/PROJ-123-new-feature` 
- **PR title**: `PROJ-123: Add new login screen`

The action will automatically detect the Jira issue key from either location.

### Workflow Integration

1. **Creating a PR**:
   - Create your pull request as normal
   - The action automatically detects the Jira issue key
   - Jira issue details are added to the PR description
   - The Jira ticket transitions to the configured status (default: "In Progress")

2. **Merging a PR**:
   - Merge your PR as normal
   - The Jira ticket automatically transitions to the configured status (default: "Complete")
   - A comment with the PR link is added to the Jira issue

### Example Workflow

1. **Start work on a ticket**:
   ```bash
   git checkout -b feature/PROJ-123-add-login
   # Make your changes...
   git add .
   git commit -m "PROJ-123: Implement login feature"
   git push origin feature/PROJ-123-add-login
   ```

2. **Create the PR** with title "PROJ-123: Add login feature"
   - The action automatically adds Jira details to the PR
   - The Jira ticket moves to "In Progress" (or your configured status)

3. **Merge the PR**
   - The Jira ticket moves to "Complete" (or your configured status)
   - The PR link is added as a comment in the Jira ticket

## Customizing Your Integration

### Analyze Your Jira Workflow

To determine available transitions for your projects:

```powershell
# From the scripts directory:
.\check-jira-issue-transitions.ps1 -JiraAPIToken "your-token" -JiraIssueKey "PROJ-123"
```

This will show all available transitions for the specified issue.

### Configure Custom Transitions

Update your workflow file to use specific transitions that match your Jira workflow:

```yaml
- name: Run GitHub-Jira Integration
  uses: hedgeco/github-action-jira-integration@main
  with:
    # ... other parameters
    pr-open-transition: 'Start Development'  # Your custom transition
    pr-merge-transition: 'Ready for Review'  # Your custom transition
```

## Advanced Troubleshooting

### Verify API Token and Connectivity

Test your Jira API token and connection:

```powershell
.\scripts\debug-jira-token.ps1 -JiraAPIToken "your-token"
```

### Update GitHub Secrets

If you need to update your Jira API token:

```powershell
.\scripts\update-github-secret-enhanced.ps1 -JiraAPIToken "your-token" -RepoName "owner/repo"
```

### Diagnose Common Issues

1. **Authentication failures**:
   - Check if your token has expired (tokens can expire after a certain period)
   - Verify the email associated with the token matches exactly what's in GitHub secrets
   - Ensure the token has appropriate permissions (you need read/write access to issues)
   - Test the token directly with the `test-jira-auth.ps1` script to isolate GitHub vs. Jira issues

2. **Transition failures**:
   - Check if the specified transition is valid for the current status using `check-jira-issue-transitions.ps1`
   - Verify that your account has permission to make the transition
   - Look for exact transition name matches - even spacing and capitalization matter
   - Ensure the issue is in a state where the requested transition is allowed

3. **No Jira details in PR**:
   - Check that your Jira issue exists and is accessible
   - Verify that the API token has permissions to view the issue
   - Ensure the PR title or branch contains the Jira key in the correct format (e.g., `PROJ-123`)
   - Check the GitHub Actions logs for any errors in the API calls

4. **GitHub Action not running**:
   - Check the workflow file syntax using GitHub's built-in validator
   - Verify that the workflow is enabled (workflows can be disabled in repository settings)
   - Ensure the workflow triggers on the correct events (`pull_request` with appropriate types)
   - Check that the repository has access to the required secrets

5. **Base64 Encoding Issues**:
   - If your token contains special characters, it might not encode properly
   - Use the `debug-jira-token.ps1` script to diagnose encoding problems
   - Consider regenerating your token if problems persist

## Best Practices

1. **Use consistent naming conventions** for branches and PRs
   - Always include the Jira key in the same format: `PROJ-123`
   
2. **Keep Jira and GitHub in sync** by using this integration
   - Avoid manually updating Jira when the automation can handle it
   
3. **Customize transitions** to match your team's workflow
   - Different projects may need different transition configurations

4. **Use PR templates** that include placeholders for Jira keys to encourage consistency
