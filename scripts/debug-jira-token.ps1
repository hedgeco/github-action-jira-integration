#!/usr/bin/env pwsh
# Script to test Jira authentication and debug token issues

param(
    [Parameter(Mandatory=$true)]
    [string]$JiraAPIToken
)

$jiraEmail = "maria@smartxadvisory.com"
$jiraBaseUrl = "https://smartx.atlassian.net"

Write-Host "Testing Jira API Authentication with token..." -ForegroundColor Cyan

# Count characters in token and check if it has valid length
$tokenLength = $JiraAPIToken.Length
Write-Host "Token length: $tokenLength characters" -ForegroundColor Yellow

if ($tokenLength -lt 10) {
    Write-Host "Error: Token seems too short to be valid!" -ForegroundColor Red
    exit 1
}

# Check if token has any special characters that might need escaping
$hasSpecialChars = $JiraAPIToken -match '[~!@#$%^&*(){}[\];:<>,.?/\\]'
if ($hasSpecialChars) {
    Write-Host "Note: Your token contains special characters which might need special handling in some contexts." -ForegroundColor Yellow
}

# Setup auth for curl-like request
$auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${jiraEmail}:${JiraAPIToken}"))
Write-Host "Base64 auth string first 10 chars: $($auth.Substring(0, [Math]::Min(10, $auth.Length)))..." -ForegroundColor Yellow

# Setup headers
$headers = @{
    "Authorization" = "Basic $auth"
    "Content-Type" = "application/json"
}

try {
    # Simple API call to check authentication - get current user info
    Write-Host "Making authentication request to Jira API..." -ForegroundColor Yellow
    $response = Invoke-RestMethod -Uri "$jiraBaseUrl/rest/api/3/myself" -Headers $headers -Method Get -ErrorAction Stop
    
    Write-Host "`n✅ Authentication successful!" -ForegroundColor Green
    Write-Host "Connected as: $($response.displayName) ($($response.emailAddress))" -ForegroundColor Green
    Write-Host "Account ID: $($response.accountId)" -ForegroundColor Green
    
    # Format token for copying to secrets
    Write-Host "`nTokens need to be carefully copied when setting in GitHub Secrets" -ForegroundColor Cyan
    Write-Host "Try updating your GitHub secret with this exact token:" -ForegroundColor Cyan
    Write-Host $JiraAPIToken -ForegroundColor Yellow
    
    return $true
}
catch {
    Write-Host "`n❌ Authentication failed!" -ForegroundColor Red
    if ($_.Exception.Response) {
        Write-Host "Status code: $($_.Exception.Response.StatusCode)" -ForegroundColor Red
    }
    
    if ($_.ErrorDetails) {
        Write-Host "Error details: $($_.ErrorDetails.Message)" -ForegroundColor Red
    }
    
    Write-Host "`nDebugging information:" -ForegroundColor Yellow
    Write-Host "Make sure:" -ForegroundColor Yellow
    Write-Host "1. The token is correctly copied (no extra spaces or characters)" -ForegroundColor Yellow
    Write-Host "2. The token hasn't expired or been revoked" -ForegroundColor Yellow
    Write-Host "3. The Jira email '$jiraEmail' matches the account used to generate the token" -ForegroundColor Yellow
    
    return $false
}
