param(
    [Parameter(Mandatory=$true)]
    [string]$JiraAPIToken,
    
    [Parameter(Mandatory=$false)]
    [string]$JiraIssueKey = "INVEST-2115"
)

$jiraEmail = "maria@smartxadvisory.com"
$jiraBaseUrl = "https://smartx.atlassian.net"

Write-Host "Checking transitions for Jira issue $JiraIssueKey..." -ForegroundColor Cyan

# Setup auth
$auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${jiraEmail}:${JiraAPIToken}"))
$headers = @{
    "Authorization" = "Basic $auth"
    "Content-Type" = "application/json"
}

try {
    # First, check authentication
    $myselfUrl = "$jiraBaseUrl/rest/api/3/myself"
    $myself = Invoke-RestMethod -Uri $myselfUrl -Headers $headers -Method Get
    Write-Host "✅ Authenticated as $($myself.displayName)" -ForegroundColor Green
    
    # Get issue details
    $issueUrl = "$jiraBaseUrl/rest/api/3/issue/$JiraIssueKey"
    $issue = Invoke-RestMethod -Uri $issueUrl -Headers $headers -Method Get
    
    $issueType = $issue.fields.issuetype.name
    $issueStatus = $issue.fields.status.name
    $projectKey = $issue.fields.project.key
    
    Write-Host "Issue Details:" -ForegroundColor Yellow
    Write-Host "  Key: $JiraIssueKey" -ForegroundColor Yellow
    Write-Host "  Type: $issueType" -ForegroundColor Yellow
    Write-Host "  Status: $issueStatus" -ForegroundColor Yellow
    Write-Host "  Project: $projectKey" -ForegroundColor Yellow
    
    # Get transitions
    $transitionsUrl = "$jiraBaseUrl/rest/api/3/issue/$JiraIssueKey/transitions"
    $transitions = Invoke-RestMethod -Uri $transitionsUrl -Headers $headers -Method Get
    
    Write-Host "`nAvailable transitions:" -ForegroundColor Cyan
    foreach ($transition in $transitions.transitions) {
        Write-Host "  - ID: $($transition.id), Name: '$($transition.name)'" -ForegroundColor Cyan
    }
      # Get workflow for this issue type
    Write-Host "`nAll workflow statuses for ${issueType} in ${projectKey}:" -ForegroundColor Magenta
    
    # Search for other issues of the same type to see all statuses
    $jql = "project = $projectKey AND issuetype = '$issueType' ORDER BY updated DESC"
    $searchUrl = "$jiraBaseUrl/rest/api/3/search?jql=$([System.Web.HttpUtility]::UrlEncode($jql))&maxResults=100&fields=status"
    
    $searchResult = Invoke-RestMethod -Uri $searchUrl -Headers $headers -Method Get
    
    $statuses = @{}
    foreach ($resultIssue in $searchResult.issues) {
        $statusName = $resultIssue.fields.status.name
        $statusId = $resultIssue.fields.status.id
        
        if (-not $statuses.ContainsKey($statusName)) {
            $statuses[$statusName] = $statusId
        }
    }
    
    foreach ($statusName in $statuses.Keys) {
        Write-Host "  - $statusName (ID: $($statuses[$statusName]))" -ForegroundColor White
    }
    
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
