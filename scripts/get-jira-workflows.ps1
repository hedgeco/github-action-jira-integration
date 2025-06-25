#!/usr/bin/env pwsh
# Script to fetch Jira workflow transitions for different issue types
# Usage: .\get-jira-transitions.ps1 -JiraApiToken "your-token"

param(
    [Parameter(Mandatory=$true)]
    [string]$JiraApiToken,
    
    [Parameter(Mandatory=$false)]
    [string]$JiraBaseUrl = "https://smartx.atlassian.net",
    
    [Parameter(Mandatory=$false)]
    [string]$JiraUserEmail = "maria@smartxadvisory.com",
    
    [Parameter(Mandatory=$false)]
    [string]$ProjectKey = "INVEST"
)

# Authentication
$auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${JiraUserEmail}:${JiraApiToken}"))
$headers = @{
    "Authorization" = "Basic $auth"
    "Content-Type" = "application/json"
    "Accept" = "application/json"
}

Write-Host "Fetching Jira workflow transitions for project: $ProjectKey" -ForegroundColor Cyan

# Step 1: Get all issue types in the project
try {
    $projectUrl = "$JiraBaseUrl/rest/api/3/project/$ProjectKey"
    Write-Host "Querying project information: $projectUrl" -ForegroundColor Gray
    
    $projectInfo = Invoke-RestMethod -Uri $projectUrl -Headers $headers -Method Get
    
    Write-Host "Project Name: $($projectInfo.name)" -ForegroundColor Green
    Write-Host "Issue Types:" -ForegroundColor Yellow
    
    # Get all issue types and their IDs
    $issueTypes = $projectInfo.issueTypes | Where-Object { -not $_.subtask }
    foreach ($issueType in $issueTypes) {
        Write-Host "  - $($issueType.name) (ID: $($issueType.id))" -ForegroundColor Yellow
    }
    
    # Step 2: For each issue type, find an issue in "In Progress" or create a temporary one
    foreach ($issueType in $issueTypes) {
        Write-Host "`n===========================================" -ForegroundColor Cyan
        Write-Host "ISSUE TYPE: $($issueType.name)" -ForegroundColor Cyan
        Write-Host "===========================================" -ForegroundColor Cyan
        
        # First try to find an existing issue of this type in "In Progress" status
        $jqlQuery = "project = '$ProjectKey' AND issuetype = '$($issueType.name)' AND status in ('In Progress', 'Development') ORDER BY updated DESC"
        $searchUrl = "$JiraBaseUrl/rest/api/3/search?jql=" + [System.Web.HttpUtility]::UrlEncode($jqlQuery)
        
        Write-Host "Searching for $($issueType.name) issues in 'In Progress' status..." -ForegroundColor Gray
        try {
            $searchResult = Invoke-RestMethod -Uri $searchUrl -Headers $headers -Method Get
            
            if ($searchResult.issues -and $searchResult.issues.Count -gt 0) {
                $issue = $searchResult.issues[0]
                Write-Host "Found issue: $($issue.key) - $($issue.fields.summary)" -ForegroundColor Green
                
                # Get transitions for this issue
                $transitionsUrl = "$JiraBaseUrl/rest/api/3/issue/$($issue.key)/transitions"
                $transitions = Invoke-RestMethod -Uri $transitionsUrl -Headers $headers -Method Get
                
                Write-Host "Current status: $($issue.fields.status.name)" -ForegroundColor Yellow
                Write-Host "Available transitions:" -ForegroundColor Green
                
                foreach ($transition in $transitions.transitions) {
                    Write-Host "  - [ID: $($transition.id)] $($transition.name)" -ForegroundColor Green
                    
                    # Check if this transition requires additional fields
                    if ($transition.fields -and $transition.fields.Count -gt 0) {
                        Write-Host "    Required fields:" -ForegroundColor Yellow
                        foreach ($fieldKey in $transition.fields.PSObject.Properties.Name) {
                            $field = $transition.fields.$fieldKey
                            Write-Host "      - $($field.name) (required: $($field.required))" -ForegroundColor Yellow
                        }
                    }
                }
            } else {
                Write-Host "No issues found with status 'In Progress' for type '$($issueType.name)'" -ForegroundColor Yellow
                Write-Host "Checking other statuses to find any issue of this type..." -ForegroundColor Yellow
                
                # Try to find any issue of this type
                $jqlQuery = "project = '$ProjectKey' AND issuetype = '$($issueType.name)' ORDER BY updated DESC"
                $searchUrl = "$JiraBaseUrl/rest/api/3/search?jql=" + [System.Web.HttpUtility]::UrlEncode($jqlQuery)
                
                $searchResult = Invoke-RestMethod -Uri $searchUrl -Headers $headers -Method Get
                
                if ($searchResult.issues -and $searchResult.issues.Count -gt 0) {
                    $issue = $searchResult.issues[0]
                    Write-Host "Found issue: $($issue.key) - $($issue.fields.summary) (Status: $($issue.fields.status.name))" -ForegroundColor Green
                    
                    # Get transitions for this issue
                    $transitionsUrl = "$JiraBaseUrl/rest/api/3/issue/$($issue.key)/transitions"
                    $transitions = Invoke-RestMethod -Uri $transitionsUrl -Headers $headers -Method Get
                    
                    Write-Host "Current status: $($issue.fields.status.name)" -ForegroundColor Yellow
                    Write-Host "Available transitions:" -ForegroundColor Green
                    
                    foreach ($transition in $transitions.transitions) {
                        Write-Host "  - [ID: $($transition.id)] $($transition.name)" -ForegroundColor Green
                    }
                } else {
                    Write-Host "No issues found for type '$($issueType.name)'" -ForegroundColor Red
                }
            }
        } catch {
            Write-Host "Error searching for issues: $_" -ForegroundColor Red
        }
    }
    
    # Step 3: Summary - Write out recommended configuration
    Write-Host "`n===========================================" -ForegroundColor Cyan
    Write-Host "RECOMMENDED CONFIGURATION FOR GITHUB ACTION" -ForegroundColor Cyan
    Write-Host "===========================================" -ForegroundColor Cyan
    Write-Host "Based on the transitions found, here's a recommended mapping for your GitHub Action:" -ForegroundColor Yellow
    Write-Host 
    Write-Host "```yaml" -ForegroundColor Gray
    Write-Host "transition-mapping:" -ForegroundColor White
    foreach ($issueType in $issueTypes) {
        Write-Host "  # For $($issueType.name)" -ForegroundColor White
        Write-Host "  $($issueType.name):" -ForegroundColor White
        Write-Host "    pr-open: 'In Progress'" -ForegroundColor White
        Write-Host "    pr-merge: 'Ready for QA'" -ForegroundColor White
    }
    Write-Host "```" -ForegroundColor Gray
    
} catch {
    Write-Host "Error retrieving project info: $_" -ForegroundColor Red
    Write-Host $_.Exception.Response -ForegroundColor Red
}
