#!/usr/bin/env pwsh
# Script to clean up unnecessary files in GitHub-Jira Integration repository

Write-Host "Starting cleanup of GitHub-Jira Integration repository..." -ForegroundColor Cyan

# Files to keep in scripts directory
$keepScripts = @(
    "check-jira-issue-transitions.ps1",
    "debug-jira-token.ps1", 
    "test-jira-auth.ps1", 
    "update-github-secret-enhanced.ps1"
)

# Clean up scripts directory
Write-Host "Cleaning scripts directory..." -ForegroundColor Yellow
$allScripts = Get-ChildItem -Path "scripts" -Filter "*.ps1" -File
foreach ($script in $allScripts) {
    if ($keepScripts -notcontains $script.Name) {
        Write-Host "Removing unnecessary script: $($script.Name)" -ForegroundColor Gray
        Remove-Item -Path $script.FullName -Force
    } else {
        Write-Host "Keeping essential script: $($script.Name)" -ForegroundColor Green
    }
}

# Clean up test files
Write-Host "Cleaning test files..." -ForegroundColor Yellow
$testFiles = @(
    "jira-integration-test.md",
    "test-verification.md",
    "verification-test.md"
)

foreach ($file in $testFiles) {
    if (Test-Path $file) {
        Write-Host "Removing test file: $file" -ForegroundColor Gray
        Remove-Item -Path $file -Force
    }
}

# Clean up any .github directory in scripts
if (Test-Path -Path "scripts\.github") {
    Write-Host "Removing scripts\.github directory..." -ForegroundColor Yellow
    Remove-Item -Path "scripts\.github" -Recurse -Force
}

# Files that should exist in repository root
$requiredFiles = @(
    "action.yml",
    "README.md",
    "DEVELOPER_GUIDE.md",
    "workflow-template.yml",
    ".github\workflows\jira-integration.yml"
)

# Verify essential files exist
Write-Host "Verifying essential files..." -ForegroundColor Yellow
foreach ($file in $requiredFiles) {
    if (Test-Path $file) {
        Write-Host "✓ Essential file exists: $file" -ForegroundColor Green
    } else {
        Write-Host "✗ Missing essential file: $file" -ForegroundColor Red
    }
}

Write-Host "`nCleanup complete!" -ForegroundColor Cyan
Write-Host "The repository now contains only the essential files for GitHub-Jira integration." -ForegroundColor Cyan
Write-Host "`nEssential files:" -ForegroundColor Cyan
Write-Host "- action.yml - The main GitHub Action definition" -ForegroundColor Cyan
Write-Host "- README.md - Main documentation" -ForegroundColor Cyan
Write-Host "- DEVELOPER_GUIDE.md - Detailed guide for developers" -ForegroundColor Cyan
Write-Host "- workflow-template.yml - Example workflow for users" -ForegroundColor Cyan
Write-Host "- .github/workflows/jira-integration.yml - Test workflow" -ForegroundColor Cyan
Write-Host "- scripts/ - Directory with utility scripts" -ForegroundColor Cyan
Write-Host "  ├─ check-jira-issue-transitions.ps1 - Check transitions for a specific issue" -ForegroundColor Cyan
Write-Host "  ├─ debug-jira-token.ps1 - Debug Jira API token issues" -ForegroundColor Cyan
Write-Host "  ├─ test-jira-auth.ps1 - Test Jira authentication" -ForegroundColor Cyan
Write-Host "  └─ update-github-secret-enhanced.ps1 - Update GitHub repository secrets" -ForegroundColor Cyan

Write-Host "`nNote: After running this script, you may want to commit these changes to your GitHub repository." -ForegroundColor Yellow
