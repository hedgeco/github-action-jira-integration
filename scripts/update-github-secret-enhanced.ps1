param(
    [Parameter(Mandatory=$true)]
    [string]$JiraAPIToken,
    
    [Parameter(Mandatory=$false)]
    [string]$RepoName = 'hedgeco/github-action-jira-integration',
    
    [Parameter(Mandatory=$false)]
    [switch]$Confirm
)

Write-Host 'Updating GitHub repository secret for JIRA_API_TOKEN...' -ForegroundColor Cyan

# Check if gh CLI is installed
try {
    $ghVersion = gh --version
    Write-Host 'GitHub CLI detected: ' -ForegroundColor Green -NoNewline
    Write-Host $ghVersion
}
catch {
    Write-Host 'GitHub CLI (gh) is not installed or not in PATH. Please install it first:' -ForegroundColor Red
    Write-Host 'https://cli.github.com/manual/installation' -ForegroundColor Yellow
    exit 1
}

# Check if logged in to gh
try {
    $ghStatus = gh auth status
    Write-Host 'GitHub CLI authentication status:' -ForegroundColor Green
    Write-Host $ghStatus -ForegroundColor Green
}
catch {
    Write-Host 'Not logged in to GitHub CLI. Please login first:' -ForegroundColor Red
    Write-Host 'gh auth login' -ForegroundColor Yellow
    exit 1
}

# Update the secret
try {
    Write-Host 'Setting JIRA_API_TOKEN secret...' -ForegroundColor Yellow
    
    # Check if user wants confirmation
    if ($Confirm) {
        Write-Host 'Token to be set (first 5 chars): ' -NoNewline
        Write-Host $JiraAPIToken.Substring(0, 5) -ForegroundColor Yellow -NoNewline
        Write-Host '...' -NoNewline
        Write-Host $JiraAPIToken.Substring($JiraAPIToken.Length - 5, 5) -ForegroundColor Yellow
        Write-Host 'Token length: ' -NoNewline
        Write-Host $JiraAPIToken.Length -ForegroundColor Yellow
        
        $confirmation = Read-Host 'Continue with updating the secret? (y/n)'
        if ($confirmation -ne 'y') {
            Write-Host 'Operation cancelled by user.' -ForegroundColor Yellow
            exit 0
        }
    }
    
    # Set the secret
    $JiraAPIToken | gh secret set JIRA_API_TOKEN --repo $RepoName
    Write-Host 'âœ Secret JIRA_API_TOKEN updated successfully!' -ForegroundColor Green
}
catch {
    Write-Host 'Failed to update secret:' -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

Write-Host 'Note: The token has been updated, but existing workflows may still need to be re-run.' -ForegroundColor Yellow
Write-Host 'Try these steps:' -ForegroundColor Cyan
Write-Host '1. Close and reopen PR #8 to trigger the workflow again, or' -ForegroundColor Cyan
Write-Host '2. Re-run the failed workflow manually from the GitHub Actions tab' -ForegroundColor Cyan
