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

    $branchUrl = "https://api.github.com/repos/$OwnerName/$RepositoryName/branches/$BranchName"
    $branch = Invoke-RestMethod -Uri $branchUrl -Headers $headers

    $commitSha = $branch.commit.sha
    $commitData = Invoke-RestMethod -Uri $branch.commit.url -Headers $headers

    $commitTree = $commitData.commit.tree.sha
    $parentSha = $commitData.parents[0].sha
    $author = $commitData.commit.author
    $committer = $commitData.commit.committer

    function Get-TimezoneOffsetString($dateObj) {
        $offset = $dateObj.ToString("zzz").Replace(":", "")
        return $offset
    }

    $authorDateObj = Get-Date $author.date
    $committerDateObj = Get-Date $committer.date
    $authorOffset = Get-TimezoneOffsetString $authorDateObj
    $committerOffset = Get-TimezoneOffsetString $committerDateObj

    $authorTimestamp = [Math]::Floor((Get-Date $author.date -UFormat %s))
    $committerTimestamp = [Math]::Floor((Get-Date $committer.date -UFormat %s))

    $commitTextLines = @(
        "tree $commitTree",
        "parent $parentSha",
        "author $($author.name) <$($author.email)> $authorTimestamp $authorOffset",
        "committer $($committer.name) <$($committer.email)> $committerTimestamp $committerOffset",
        "",
        "$($commitData.commit.message)"
    )

    $commitText = ($commitTextLines -join "`n") + "`n"
    $utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $false

    $tempPath = [System.IO.Path]::GetTempFileName()
    [System.IO.File]::WriteAllText($tempPath, $commitText, $utf8NoBomEncoding)

    $signature = & gpg --armor --sign --default-key $author.email --detach-sign --output - $tempPath
    $formattedSignature = ($signature -join "`n") + "`n"
    
    # Remove any potential carriage returns that might cause verification issues
    $formattedSignature = $formattedSignature -replace "`r", ""

    $signedCommit = @{
        message    = $commitData.commit.message
        tree       = $commitTree
        parents    = @($parentSha)
        author     = $author
        committer  = $committer
        signature  = $formattedSignature
    }

    $createUrl = "https://api.github.com/repos/$OwnerName/$RepositoryName/git/commits"
    $newCommit = Invoke-RestMethod -Uri $createUrl -Method POST -Headers $headers `
        -Body ($signedCommit | ConvertTo-Json -Depth 10 -Compress) `
        -ContentType "application/json"

    # Now move the branch to point to new commit
    $updateRefUrl = "https://api.github.com/repos/$OwnerName/$RepositoryName/git/refs/heads/$BranchName"
    $updatePayload = @{ sha = $newCommit.sha; force = $true } | ConvertTo-Json
    Invoke-RestMethod -Uri $updateRefUrl -Method POST -Headers $headers -Body $updatePayload -ContentType "application/json"

    Remove-Item $tempPath -Force
    Write-Host "✅ Signed and updated branch to commit: $($newCommit.sha)"
}