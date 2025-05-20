# Check commit signature verification status
param (
    [string]$CommitSHA = $null
)

# If no CommitSHA is provided, get the latest commit
if (-not $CommitSHA) {
    $CommitSHA = git rev-parse HEAD
}

# Get repository info
$remoteUrl = git remote get-url origin
if ($remoteUrl -match "github.com[:/]([^/]+)/([^/.]+)") {
    $owner = $matches[1]
    $repo = $matches[2]
    if ($repo.EndsWith(".git")) {
        $repo = $repo.Substring(0, $repo.Length - 4)
    }
}
else {
    Write-Host "Could not determine repo owner and name from git remote URL" -ForegroundColor Red
    exit 1
}

Write-Host "📝 Repository: $owner/$repo" -ForegroundColor Cyan
Write-Host "🔍 Checking signature for commit: $CommitSHA" -ForegroundColor Cyan

# GitHub API URL for the commit
$apiUrl = "https://api.github.com/repos/$owner/$repo/commits/$CommitSHA"

try {
    # Make API request
    $headers = @{
        "Accept" = "application/vnd.github.v3+json"
        "User-Agent" = "PowerShell-Script"
    }
    
    # Add authorization if GITHUB_TOKEN is set
    if ($env:GITHUB_TOKEN) {
        $headers["Authorization"] = "Bearer $env:GITHUB_TOKEN"
    }
    
    $response = Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method Get
    
    # Check verification status
    $verified = $response.commit.verification.verified
    $reason = $response.commit.verification.reason
    
    if ($verified) {
        Write-Host "✅ Signature is VERIFIED!" -ForegroundColor Green
    }
    else {
        Write-Host "❌ Signature is NOT VERIFIED: $reason" -ForegroundColor Red
    }
    
    # Display additional details
    Write-Host "`nCommit Details:" -ForegroundColor Yellow
    Write-Host "Author: $($response.commit.author.name) <$($response.commit.author.email)>"
    Write-Host "Date: $($response.commit.author.date)"
    Write-Host "Message: $($response.commit.message)"
    
    Write-Host "`nSignature Verification:" -ForegroundColor Yellow
    Write-Host "Status: $($verified ? 'Verified' : 'Not Verified')"
    Write-Host "Reason: $reason"
    
    # Show the actual signed payload and compare to make sure they match
    Write-Host "`nVerification Payload:" -ForegroundColor Yellow
    Write-Host $response.commit.verification.payload
    
    # Get local commit info for comparison
    Write-Host "`nLocal Git Commit Details:" -ForegroundColor Yellow
    $localCommitInfo = git show --pretty=raw $CommitSHA
    Write-Host $localCommitInfo
    
} catch {
    Write-Host "❌ Error checking commit: $($_.Exception.Message)" -ForegroundColor Red
}
