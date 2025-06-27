#!/usr/bin/env pwsh
# Script to verify GitHub-Jira Integration setup

param(
    [Parameter(Mandatory=$true)]
    [string]$JiraAPIToken,
    
    [Parameter(Mandatory=$false)]
    [string]$JiraBaseUrl = "https://smartx.atlassian.net",
    
    [Parameter(Mandatory=$false)]
    [string]$JiraUserEmail = "maria@smartxadvisory.com",
    
    [Parameter(Mandatory=$false)]
    [string]$JiraIssueKey = "INVEST-2205"
)

Write-Host "GitHub-Jira Integration Verification" -ForegroundColor Cyan
Write-Host "===================================" -ForegroundColor Cyan

Write-Host "`n1. Testing Jira authentication..." -ForegroundColor Yellow

# Setup auth for Jira API
$auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${JiraUserEmail}:${JiraAPIToken}"))
$headers = @{
    "Authorization" = "Basic $auth"
    "Content-Type" = "application/json"
}

try {
    $myselfUrl = "$JiraBaseUrl/rest/api/3/myself"
    $myself = Invoke-RestMethod -Uri $myselfUrl -Headers $headers -Method Get -ErrorAction Stop
    
    Write-Host "✓ Authentication successful!" -ForegroundColor Green
    Write-Host "  Connected as: $($myself.displayName) ($($myself.emailAddress))" -ForegroundColor Green
    
    # Check issue exists
    Write-Host "`n2. Checking if issue $JiraIssueKey exists..." -ForegroundColor Yellow
    
    $issueUrl = "$JiraBaseUrl/rest/api/3/issue/$JiraIssueKey"
    try {
        $issue = Invoke-RestMethod -Uri $issueUrl -Headers $headers -Method Get -ErrorAction Stop
        Write-Host "✓ Issue found: $JiraIssueKey - $($issue.fields.summary)" -ForegroundColor Green
        Write-Host "  Current status: $($issue.fields.status.name)" -ForegroundColor Green
        
        # Check transitions
        Write-Host "`n3. Checking available transitions..." -ForegroundColor Yellow
        
        $transitionsUrl = "$JiraBaseUrl/rest/api/3/issue/$JiraIssueKey/transitions"
        $transitions = Invoke-RestMethod -Uri $transitionsUrl -Headers $headers -Method Get -ErrorAction Stop
        
        if ($transitions.transitions.Count -gt 0) {
            Write-Host "✓ Available transitions:" -ForegroundColor Green
            foreach ($transition in $transitions.transitions) {
                Write-Host "  - $($transition.name) (ID: $($transition.id))" -ForegroundColor Green
            }
            
            # Check action.yml configured transitions
            Write-Host "`n4. Verifying action.yml transition configurations..." -ForegroundColor Yellow
            
            if (Test-Path "action.yml") {
                $actionContent = Get-Content "action.yml" -Raw
                
                $openTransitionMatch = [regex]::Match($actionContent, "pr-open-transition:[^'`"]*[`"']([^'`"]*)[`"']")
                $mergeTransitionMatch = [regex]::Match($actionContent, "pr-merge-transition:[^'`"]*[`"']([^'`"]*)[`"']")
                
                if ($openTransitionMatch.Success) {
                    $openTransition = $openTransitionMatch.Groups[1].Value
                    Write-Host "  Found PR open transition in action.yml: '$openTransition'" -ForegroundColor Yellow
                    
                    $matchingTransition = $transitions.transitions | Where-Object { $_.name -eq $openTransition }
                    if ($matchingTransition) {
                        Write-Host "  ✓ Transition '$openTransition' is valid for this issue!" -ForegroundColor Green
                    } else {
                        Write-Host "  ✗ Transition '$openTransition' NOT found for this issue!" -ForegroundColor Red
                        Write-Host "    Consider updating action.yml with one of the available transitions." -ForegroundColor Red
                    }
                }
                
                if ($mergeTransitionMatch.Success) {
                    $mergeTransition = $mergeTransitionMatch.Groups[1].Value
                    Write-Host "  Found PR merge transition in action.yml: '$mergeTransition'" -ForegroundColor Yellow
                    
                    $matchingTransition = $transitions.transitions | Where-Object { $_.name -eq $mergeTransition }
                    if ($matchingTransition) {
                        Write-Host "  ✓ Transition '$mergeTransition' is valid for this issue!" -ForegroundColor Green
                    } else {
                        Write-Host "  ✗ Transition '$mergeTransition' NOT found for this issue!" -ForegroundColor Red
                        Write-Host "    Consider updating action.yml with one of the available transitions." -ForegroundColor Red
                    }
                }
            } else {
                Write-Host "  ✗ Could not find action.yml file!" -ForegroundColor Red
            }
            
            # Check workflow file
            Write-Host "`n5. Verifying workflow configuration..." -ForegroundColor Yellow
            
            $workflowPath = ".github/workflows/jira-integration.yml"
            if (Test-Path $workflowPath) {
                $workflowContent = Get-Content $workflowPath -Raw
                
                if ($workflowContent -match "jira-base-url: \`${{.*secrets\.JIRA_BASE_URL") {
                    Write-Host "  ✓ Workflow correctly references JIRA_BASE_URL secret" -ForegroundColor Green
                } else {
                    Write-Host "  ✗ Workflow does not correctly reference JIRA_BASE_URL secret!" -ForegroundColor Red
                }
                
                if ($workflowContent -match "jira-user-email: \`${{.*secrets\.JIRA_USER_EMAIL") {
                    Write-Host "  ✓ Workflow correctly references JIRA_USER_EMAIL secret" -ForegroundColor Green
                } else {
                    Write-Host "  ✗ Workflow does not correctly reference JIRA_USER_EMAIL secret!" -ForegroundColor Red
                }
                
                if ($workflowContent -match "jira-api-token: \`${{.*secrets\.JIRA_API_TOKEN") {
                    Write-Host "  ✓ Workflow correctly references JIRA_API_TOKEN secret" -ForegroundColor Green
                } else {
                    Write-Host "  ✗ Workflow does not correctly reference JIRA_API_TOKEN secret!" -ForegroundColor Red
                }
            } else {
                Write-Host "  ⚠️ Could not find workflow file at $workflowPath" -ForegroundColor Yellow
                Write-Host "     This is not a critical issue. You need to create this file in repositories where you will use this action." -ForegroundColor Yellow
                Write-Host "     Use workflow-template.yml as a reference." -ForegroundColor Yellow
            }
            
            Write-Host "`n✓ Verification complete! Your setup looks valid." -ForegroundColor Green
            Write-Host "  You can now use the GitHub-Jira Integration action in your repository." -ForegroundColor Green
            Write-Host "  Don't forget to set your GitHub repository secrets:" -ForegroundColor Yellow
            Write-Host "    - JIRA_BASE_URL: $JiraBaseUrl" -ForegroundColor Yellow
            Write-Host "    - JIRA_USER_EMAIL: $JiraUserEmail" -ForegroundColor Yellow
            Write-Host "    - JIRA_API_TOKEN: [your token]" -ForegroundColor Yellow
        } else {
            Write-Host "✗ No transitions available for this issue!" -ForegroundColor Red
        }
    } catch {
        Write-Host "✗ Could not find issue $JiraIssueKey!" -ForegroundColor Red
        Write-Host "  Error: $_" -ForegroundColor Red
    }
} catch {
    Write-Host "✗ Authentication failed!" -ForegroundColor Red
    Write-Host "  Error: $_" -ForegroundColor Red
    
    if ($_.Exception.Response) {
        Write-Host "  Status code: $($_.Exception.Response.StatusCode)" -ForegroundColor Red
    }
    
    if ($_.ErrorDetails) {
        Write-Host "  Error details: $($_.ErrorDetails.Message)" -ForegroundColor Red
    }
}
