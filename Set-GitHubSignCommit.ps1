# Helper function to get timezone offset in Git format
function Get-GitTimezoneOffset {
    param (
        [DateTime]$dateTime = (Get-Date),
        [switch]$IncludeColon = $false
    )
    
    # Get the timezone offset in the proper format
    $offset = $dateTime.ToString("zzz")  # Format like +00:00
    
    if (-not $IncludeColon) {
        $offset = $offset.Replace(":", "")  # Format like +0000 for Git
    }
    
    return $offset
}

# Helper function to convert a DateTime to Git timestamp format
function ConvertTo-GitTimestamp {
    param ([DateTime]$dateTime = (Get-Date))
    
    # Get Unix timestamp (seconds since epoch)
    $unixTimestamp = [int][double]::Parse((Get-Date -Date $dateTime -UFormat %s))
    
    # Get timezone offset without colon (Git format)
    $tzOffset = Get-GitTimezoneOffset -dateTime $dateTime
    
    # Return in Git format: UNIX_TIMESTAMP TIMEZONE_OFFSET
    return "$unixTimestamp $tzOffset"
}

function Set-GitHubSignLatestCommit {
    param (
        [Parameter(Mandatory = $true)][string]$RepositoryName,
        [Parameter(Mandatory = $true)][string]$BranchName,
        [Parameter(Mandatory = $true)][PSCustomObject]$GitHubTokenInstance,
        [Parameter()][string]$OwnerName = "DivyaGhai"
    )

    $headers = @{
        Authorization = "Bearer $($GitHubTokenInstance.token)"
        Accept        = "application/vnd.github+json"
        "User-Agent"  = "PowerShell-GitHubClient"
    }

    Write-Host "Fetching branch information..."
    $branchUrl = "https://api.github.com/repos/$OwnerName/$RepositoryName/branches/$BranchName"
    $branch = Invoke-RestMethod -Uri $branchUrl -Headers $headers

    # Get commit data from the branch latest commit
    Write-Host "Fetching commit data..."
    $commitData = Invoke-RestMethod -Uri $branch.commit.url -Headers $headers

    $commitTree = $commitData.commit.tree.sha
    $author = $commitData.commit.author
    $committer = $commitData.commit.committer
    
    # Parse dates from string to DateTime objects
    $authorDate = [DateTime]::Parse($author.date)
    $committerDate = [DateTime]::Parse($committer.date) 
    
    # Convert to Git timestamp format (Unix timestamp with timezone offset)
    $authorGitDate = ConvertTo-GitTimestamp -dateTime $authorDate
    $committerGitDate = ConvertTo-GitTimestamp -dateTime $committerDate
    
    Write-Host "Author date: $($author.date) -> $authorGitDate"
    Write-Host "Committer date: $($committer.date) -> $committerGitDate"
    
    # Start building commit text lines
    $commitTextLines = @("tree $commitTree")
    
    # Handle all parents (important for merge commits)
    foreach ($parent in $commitData.parents) {
        $commitTextLines += "parent $($parent.sha)"
    }
    
    # Add author and committer lines (both are required)
    $commitTextLines += "author $($author.name) <$($author.email)> $authorGitDate"
    $commitTextLines += "committer $($committer.name) <$($committer.email)> $committerGitDate"
    $commitTextLines += ""
    $commitTextLines += "$($commitData.commit.message)"
    
    Write-Host "Preparing commit for signing with GPG..."
    $commitText = ($commitTextLines -join "`n") + "`n"
    
    # Remove any accidental carriage returns to ensure LF only
    $commitText = $commitText -replace "`r", ""
    $utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $false
    
    Write-Host "===== COMMIT TEXT BEING SIGNED ====="
    Write-Host $commitText
    Write-Host "===== END COMMIT TEXT ====="

    # Write the commit text to a temporary file
    $tempPath = [System.IO.Path]::GetTempFileName()
    [System.IO.File]::WriteAllText($tempPath, $commitText, $utf8NoBomEncoding)

    # Sign the commit with GPG
    Write-Host "Signing with GPG..."
    $signature = & gpg --armor --sign --default-key $author.email --detach-sign --output - $tempPath
    $formattedSignature = ($signature -join "`n") + "`n"
    
    # Remove any potential carriage returns that might cause verification issues
    $formattedSignature = $formattedSignature -replace "`r", ""

    # Get timezone offsets for different formats
    # Use WITH colon for GitHub API (ISO 8601 requires colon in timezone offset)
    $authorIsoTzOffset = Get-GitTimezoneOffset -dateTime $authorDate -IncludeColon
    $committerIsoTzOffset = Get-GitTimezoneOffset -dateTime $committerDate -IncludeColon
    
    # Create author and committer objects with consistent date format
    $authorObject = @{
        name  = $author.name
        email = $author.email
        date  = $authorDate.ToString("yyyy-MM-ddTHH:mm:ss") + $authorIsoTzOffset
    }
    
    $committerObject = @{
        name  = $committer.name
        email = $committer.email
        date  = $committerDate.ToString("yyyy-MM-ddTHH:mm:ss") + $committerIsoTzOffset
    }
    
    Write-Host "Author API date: $($authorObject.date)"
    Write-Host "Committer API date: $($committerObject.date)"

    # Build the parents array for the API payload
    $parentsArray = @()
    foreach ($parent in $commitData.parents) {
        $parentsArray += $parent.sha
    }
    
    # Create the payload for the GitHub API
    $signedCommit = @{
        message    = $commitData.commit.message
        tree       = $commitTree
        parents    = $parentsArray
        author     = $authorObject
        committer  = $committerObject
        signature  = $formattedSignature
    }

    Write-Host "Creating signed commit via GitHub API..."
    $createUrl = "https://api.github.com/repos/$OwnerName/$RepositoryName/git/commits"
    
    # Convert to JSON and display for debugging
    $jsonPayload = $signedCommit | ConvertTo-Json -Depth 10
    Write-Host "===== GITHUB API PAYLOAD ====="
    Write-Host $jsonPayload
    Write-Host "===== END GITHUB API PAYLOAD ====="
    
    # Create the new commit with the signature
    $newCommit = Invoke-RestMethod -Uri $createUrl -Method POST -Headers $headers -Body $jsonPayload -ContentType "application/json"

    # Now move the branch to point to new commit
    Write-Host "Updating branch reference to new commit..."
    $updateRefUrl = "https://api.github.com/repos/$OwnerName/$RepositoryName/git/refs/heads/$BranchName"
    $updatePayload = @{ sha = $newCommit.sha; force = $true } | ConvertTo-Json
    Invoke-RestMethod -Uri $updateRefUrl -Method POST -Headers $headers -Body $updatePayload -ContentType "application/json"

    # Clean up temporary file
    Remove-Item $tempPath -Force
    
    Write-Host "✅ Successfully signed and updated branch to commit: $($newCommit.sha)"
    
    # Return the new commit data
    return $newCommit
}
