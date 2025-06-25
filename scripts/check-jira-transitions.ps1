#!/usr/bin/env pwsh
# Script to fetch Jira workflow transitions

param(
    [Parameter(Mandatory=$true)]
    [string]$JiraApiToken,
    
    [Parameter(Mandatory=$false)]
    [string]$JiraBaseUrl = "https://smartx.atlassian.net",
    
    [Parameter(Mandatory=$false)]
    [string]$JiraUserEmail = "maria@smartxadvisory.com",
    
    [Parameter(Mandatory=$false)]
    [string]$JiraIssue = "INVEST-2115"
)

# Authentication
$auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${JiraUserEmail}:${JiraApiToken}"))
$headers = @{
    "Authorization" = "Basic $auth"
    "Content-Type" = "application/json"
    "Accept" = "application/json"
}

Write-Host "Fetching Jira workflow transitions for issue: $JiraIssue" -ForegroundColor Cyan

try {
    # Get issue details
    $issueUrl = "$JiraBaseUrl/rest/api/3/issue/$JiraIssue"
    $issue = Invoke-RestMethod -Uri $issueUrl -Headers $headers -Method Get
    
    $issueType = $issue.fields.issuetype.name
    $status = $issue.fields.status.name
    
    Write-Host "Issue Type: $issueType" -ForegroundColor Yellow
    Write-Host "Current Status: $status" -ForegroundColor Yellow
    
    # Get transitions
    $transitionsUrl = "$JiraBaseUrl/rest/api/3/issue/$JiraIssue/transitions"
    $transitions = Invoke-RestMethod -Uri $transitionsUrl -Headers $headers -Method Get
    
    Write-Host "Available Transitions:" -ForegroundColor Green
    foreach ($transition in $transitions.transitions) {
        Write-Host "  - [ID: $($transition.id)] $($transition.name)" -ForegroundColor Green
    }
    
    # Get all in-progress issues of different types
    Write-Host "`nSearching for issues in 'In Progress' status across different issue types..." -ForegroundColor Cyan
    
    $jqlQuery = "status in ('In Progress', 'Development') ORDER BY updated DESC"
    $searchUrl = "$JiraBaseUrl/rest/api/3/search?jql=$([System.Web.HttpUtility]::UrlEncode($jqlQuery))&maxResults=50"
    
    $searchResult = Invoke-RestMethod -Uri $searchUrl -Headers $headers -Method Get
    
    $issueTypeTransitions = @{}
    
    foreach ($issue in $searchResult.issues) {
        $currentType = $issue.fields.issuetype.name
        
        if (-not $issueTypeTransitions.ContainsKey($currentType)) {
            Write-Host "`n=== Issue Type: $currentType ===" -ForegroundColor Yellow
            
            # Get transitions for this issue
            $transUrl = "$JiraBaseUrl/rest/api/3/issue/$($issue.key)/transitions"
            try {
                $trans = Invoke-RestMethod -Uri $transUrl -Headers $headers -Method Get
                
                Write-Host "Transitions for $($issue.key) ($currentType):" -ForegroundColor Green
                foreach ($t in $trans.transitions) {
                    Write-Host "  - [ID: $($t.id)] $($t.name)" -ForegroundColor Green
                }
                
                $issueTypeTransitions[$currentType] = $trans.transitions | ForEach-Object { $_.name }
            }
            catch {
                Write-Host "Error getting transitions for issue $($issue.key): $_" -ForegroundColor Red
            }
        }
    }
    
    Write-Host "`n===== SUMMARY OF TRANSITIONS FROM 'In Progress' BY ISSUE TYPE =====" -ForegroundColor Cyan
    foreach ($type in $issueTypeTransitions.Keys) {
        Write-Host "`nIssue Type: $type" -ForegroundColor Yellow
        Write-Host "Available transitions:" -ForegroundColor Green
        foreach ($transName in $issueTypeTransitions[$type]) {
            Write-Host "  - $transName" -ForegroundColor Green
        }
    }
    
    Write-Host "`n===== RECOMMENDED GITHUB-JIRA INTEGRATION CONFIGURATION =====" -ForegroundColor Cyan
    Write-Host "```yaml" -ForegroundColor Gray
    Write-Host "transition-mapping:" -ForegroundColor White
    foreach ($type in $issueTypeTransitions.Keys) {
        Write-Host "  \"$type\":" -ForegroundColor White
        Write-Host "    pr-open: \"In Progress\"" -ForegroundColor White
        
        $recommendedTransition = $issueTypeTransitions[$type] | Where-Object { 
            $_ -match "Ready for QA|Review|Done|Complete|Closed" 
        } | Select-Object -First 1
        
        if ($recommendedTransition) {
            Write-Host "    pr-merge: \"$recommendedTransition\"" -ForegroundColor White
        } else {
            Write-Host "    # No suitable transition found - please select one from the list above" -ForegroundColor White
            Write-Host "    pr-merge: \"Complete\"" -ForegroundColor White
        }
    }
    Write-Host "```" -ForegroundColor Gray
    
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
}
