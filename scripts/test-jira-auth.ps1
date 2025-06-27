param(
    [Parameter(Mandatory=$true)]
    [string]$JiraAPIToken
)

$jiraEmail = "maria@smartxadvisory.com"
$jiraBaseUrl = "https://smartx.atlassian.net"

Write-Host "Testing Jira API Authentication..." -ForegroundColor Cyan

# Setup auth
$auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${jiraEmail}:${JiraAPIToken}"))
$headers = @{
    "Authorization" = "Basic $auth"
    "Content-Type" = "application/json"
}

try {
    # Simple API call to check authentication - get current user info
    $response = Invoke-RestMethod -Uri "$jiraBaseUrl/rest/api/3/myself" -Headers $headers -Method Get -ErrorAction Stop
    
    Write-Host "Authentication successful!" -ForegroundColor Green
    Write-Host "Connected as: $($response.displayName) ($($response.emailAddress))" -ForegroundColor Green
    Write-Host "Account ID: $($response.accountId)" -ForegroundColor Green
    return $true
}
catch {
    Write-Host "Authentication failed!" -ForegroundColor Red
    if ($_.Exception.Response) {
        Write-Host "Status code: $($_.Exception.Response.StatusCode)" -ForegroundColor Red
    }
    
    if ($_.ErrorDetails) {
        Write-Host "Error details: $($_.ErrorDetails.Message)" -ForegroundColor Red
    }
    
    return $false
}
