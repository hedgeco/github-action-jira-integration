# Script to fetch Jira workflow transitions

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

Write-Host "Fetching Jira workflow transitions for project: $ProjectKey"

# Step 1: Find issues in different statuses
$jqlQuery = "project = $ProjectKey AND status = 'In Progress' ORDER BY updated DESC"
$searchUrl = "$JiraBaseUrl/rest/api/3/search?jql=" + [Uri]::EscapeDataString($jqlQuery)

Write-Host "Searching for issues in 'In Progress' status..."

try {
    $searchResult = Invoke-RestMethod -Uri $searchUrl -Headers $headers -Method Get
    
    $issueTypes = @{}
    
    foreach ($issue in $searchResult.issues) {
        $issueType = $issue.fields.issuetype.name
        
        if (-not $issueTypes.ContainsKey($issueType)) {
            Write-Host ""
            Write-Host "==============================================="
            Write-Host "Issue Type: $issueType"
            Write-Host "==============================================="
            
            # Get transitions for this issue
            $transitionsUrl = "$JiraBaseUrl/rest/api/3/issue/$($issue.key)/transitions"
            $transitions = Invoke-RestMethod -Uri $transitionsUrl -Headers $headers -Method Get
            
            Write-Host "Issue Key: $($issue.key)"
            Write-Host "Current Status: $($issue.fields.status.name)"
            Write-Host "Available transitions:"
            
            foreach ($transition in $transitions.transitions) {
                Write-Host "  - [ID: $($transition.id)] $($transition.name)"
            }
            
            $issueTypes[$issueType] = $transitions.transitions | ForEach-Object { @{ id = $_.id; name = $_.name } }
        }
    }
    
    # Summary
    Write-Host ""
    Write-Host "==============================================="
    Write-Host "SUMMARY OF TRANSITIONS BY ISSUE TYPE"
    Write-Host "==============================================="
    
    foreach ($type in $issueTypes.Keys) {
        Write-Host ""
        Write-Host "Issue Type: $type"
        Write-Host "Available transitions:"
        foreach ($transition in $issueTypes[$type]) {
            Write-Host "  - [ID: $($transition.id)] $($transition.name)"
        }
    }
    
    # Recommendations
    Write-Host ""
    Write-Host "==============================================="
    Write-Host "RECOMMENDED GITHUB ACTION CONFIGURATION"
    Write-Host "==============================================="    Write-Host "transition-mapping:"
    foreach ($type in $issueTypes.Keys) {
        Write-Host "  `"$type`":"
        Write-Host "    pr-open: 'In Progress'"
        
        # Look for good candidates for PR merge transition
        $mergeTransition = $issueTypes[$type] | 
                          Where-Object { $_.name -match "Ready for QA|Review|Done|Complete" } | 
                          Select-Object -First 1
        
        if ($mergeTransition) {
            Write-Host "    pr-merge: '$($mergeTransition.name)'"
        } else {
            Write-Host "    pr-merge: 'Done' # Choose appropriate transition"
        }
    }
    
} catch {
    Write-Host "Error occurred: $($_.Exception.Message)"
}
