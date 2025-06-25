#!/usr/bin/env pwsh
# Script to get Jira workflows for INVEST project

param(
    [Parameter(Mandatory=$true)]
    [string]$JiraAPIToken
)

# Set these variables with your Jira credentials
$JiraBaseUrl = "https://smartx.atlassian.net"
$JiraUserEmail = "maria@smartxadvisory.com"
$ProjectKey = "INVEST"

Write-Host "Getting Jira workflows and transitions for project $ProjectKey..." -ForegroundColor Cyan

# Encode credentials
$auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${JiraUserEmail}:${JiraAPIToken}"))
$headers = @{
    "Authorization" = "Basic $auth"
    "Content-Type" = "application/json"
}

try {
    # Test authentication
    Write-Host "Testing authentication..." -ForegroundColor Yellow
    $myselfUrl = "$JiraBaseUrl/rest/api/3/myself"
    $myself = Invoke-RestMethod -Uri $myselfUrl -Headers $headers -Method Get
    Write-Host "Authenticated as $($myself.displayName)" -ForegroundColor Green
    
    # Get project information
    Write-Host "`nGetting project information..." -ForegroundColor Yellow
    $projectUrl = "$JiraBaseUrl/rest/api/3/project/$ProjectKey"
    $project = Invoke-RestMethod -Uri $projectUrl -Headers $headers -Method Get
    
    Write-Host "Project: $($project.name) ($($project.key))" -ForegroundColor Green
    
    # Get workflows for the project
    Write-Host "`nGetting workflows..." -ForegroundColor Yellow
    $workflowsUrl = "$JiraBaseUrl/rest/api/3/workflow/search?projectId=$($project.id)"
    
    try {
        $workflows = Invoke-RestMethod -Uri $workflowsUrl -Headers $headers -Method Get
        
        Write-Host "Found $($workflows.total) workflows" -ForegroundColor Green
        
        foreach ($workflow in $workflows.values) {
            Write-Host "`nWorkflow: $($workflow.name) (ID: $($workflow.id))" -ForegroundColor Magenta
            
            # Get workflow states and transitions
            if ($workflow.id) {
                $workflowDetailsUrl = "$JiraBaseUrl/rest/api/3/workflow/$($workflow.id)"
                try {
                    $workflowDetails = Invoke-RestMethod -Uri $workflowDetailsUrl -Headers $headers -Method Get
                    
                    Write-Host "  Statuses:" -ForegroundColor Yellow
                    foreach ($status in $workflowDetails.statuses) {
                        Write-Host "    - $($status.name) (ID: $($status.id))" -ForegroundColor White
                    }
                    
                    Write-Host "  Transitions:" -ForegroundColor Yellow
                    foreach ($transition in $workflowDetails.transitions) {
                        Write-Host "    - $($transition.name) (ID: $($transition.id))" -ForegroundColor White
                        Write-Host "      From: $($transition.from.name) → To: $($transition.to.name)" -ForegroundColor Gray
                    }
                } catch {
                    Write-Host "  Could not get workflow details: $_" -ForegroundColor Yellow
                }
            }
        }
    } catch {
        Write-Host "Could not get workflows: $_" -ForegroundColor Yellow
        Write-Host "Proceeding with issue type analysis..." -ForegroundColor Yellow
    }

    # Generate a transition matrix for all issue types
    Write-Host "`n📊 Issue Type Transition Summary" -ForegroundColor Green
    Write-Host "================================" -ForegroundColor Green
    
    foreach ($issueType in $project.issueTypes) {
        $issueTypeName = $issueType.name
        Write-Host "`nIssue Type: $issueTypeName (ID: $($issueType.id))" -ForegroundColor Yellow
        
        # Find an issue of this type in any status
        $jql = "project = $ProjectKey AND issuetype = '$issueTypeName' ORDER BY updated DESC"
        $searchUrl = "$JiraBaseUrl/rest/api/3/search?jql=$([System.Web.HttpUtility]::UrlEncode($jql))&maxResults=1"
        $searchResult = Invoke-RestMethod -Uri $searchUrl -Headers $headers -Method Get
        
        if ($searchResult.total -gt 0) {
            $issueKey = $searchResult.issues[0].key
            $issueStatus = $searchResult.issues[0].fields.status.name
            
            Write-Host "  Sample issue: $issueKey (Status: $issueStatus)" -ForegroundColor Cyan
            
            # Get transitions
            $transitionsUrl = "$JiraBaseUrl/rest/api/3/issue/$issueKey/transitions"
            $transitions = Invoke-RestMethod -Uri $transitionsUrl -Headers $headers -Method Get
            
            Write-Host "  Available transitions from ${issueStatus}:" -ForegroundColor White
            foreach ($transition in $transitions.transitions) {
                Write-Host "    - $($transition.name) (ID: $($transition.id))" -ForegroundColor White
            }
            
            # If current status isn't In Progress, try to find an issue in that status
            if ($issueStatus -ne "In Progress") {
                $inProgressJql = "project = $ProjectKey AND issuetype = '$issueTypeName' AND status = 'In Progress' ORDER BY updated DESC"
                $inProgressSearchUrl = "$JiraBaseUrl/rest/api/3/search?jql=$([System.Web.HttpUtility]::UrlEncode($inProgressJql))&maxResults=1"
                $inProgressSearchResult = Invoke-RestMethod -Uri $inProgressSearchUrl -Headers $headers -Method Get
                
                if ($inProgressSearchResult.total -gt 0) {
                    $inProgressIssueKey = $inProgressSearchResult.issues[0].key
                    
                    Write-Host "`n  In Progress issue found: $inProgressIssueKey" -ForegroundColor Green
                    
                    # Get transitions from In Progress
                    $inProgressTransitionsUrl = "$JiraBaseUrl/rest/api/3/issue/$inProgressIssueKey/transitions"
                    $inProgressTransitions = Invoke-RestMethod -Uri $inProgressTransitionsUrl -Headers $headers -Method Get
                    
                    Write-Host "  Available transitions from In Progress:" -ForegroundColor Magenta
                    foreach ($transition in $inProgressTransitions.transitions) {
                        Write-Host "    - $($transition.name) (ID: $($transition.id))" -ForegroundColor Magenta
                    }
                } else {
                    Write-Host "  No issues found in In Progress status for this type" -ForegroundColor Yellow
                }
            }
        } else {
            Write-Host "  No issues found for this type" -ForegroundColor Red
        }
    }
    
    # Provide recommendation for GitHub workflow
    Write-Host "`n🔧 Recommended PR Merge Transitions" -ForegroundColor Green
    Write-Host "=================================" -ForegroundColor Green
    Write-Host "Based on the analysis, these are the recommended transition names" -ForegroundColor Green
    Write-Host "to use in your GitHub-Jira integration for PR merges:" -ForegroundColor Green
    Write-Host "`n  1. 'Complete' - Primary transition for most issue types" -ForegroundColor Yellow
    Write-Host "  2. 'Done' - Alternative transition name" -ForegroundColor Yellow
    Write-Host "  3. 'Ready for QA' - For issues that require testing" -ForegroundColor Yellow
    Write-Host "  4. 'In Review' - For code that needs review" -ForegroundColor Yellow
    
} catch {
    Write-Host "❌ Error: $_" -ForegroundColor Red
    
    if ($_.Exception.Response) {
        $statusCode = $_.Exception.Response.StatusCode
        Write-Host "Status code: $statusCode" -ForegroundColor Red
        
        if ($_.ErrorDetails) {
            Write-Host "Error details: $($_.ErrorDetails)" -ForegroundColor Red
        }
        
        if ($_.Exception.Response.GetResponseStream()) {
            try {
                $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
                $responseBody = $reader.ReadToEnd()
                Write-Host "Response body: $responseBody" -ForegroundColor Red
            } catch {
                Write-Host "Could not read response stream" -ForegroundColor Red
            }
        }
    }
}
