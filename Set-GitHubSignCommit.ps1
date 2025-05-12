function Set-GitHubSignCommit {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][string]$RepositoryName,
        [Parameter(Mandatory = $true)][string]$BranchName,
        [Parameter(Mandatory = $true)][string]$PathName,
        [Parameter(Mandatory = $true)][PSCustomObject]$GitHubTokenInstance,
        [Parameter()][string]$OwnerName = "DivyaGhai"
    )

    $commitSha = git rev-parse HEAD
    $commitTree = git cat-file commit $commitSha | Select-String "^tree " | ForEach-Object { $_.Line.Split(" ")[1] }
    $parentSha = git rev-parse HEAD^

    $commitInfo = git log -1 --pretty=format:"%an%n%ae%n%cn%n%ce%n%cI%n%s%n%b" $commitSha
    $authorName, $authorEmail, $committerName, $committerEmail, $isoDate, $commitSubject, $commitBody = $commitInfo

    $unixTimestamp = [int][double]::Parse((Get-Date $isoDate -UFormat %s))
    $timezoneOffset = "-0000"  # adjust if you want local offset

    # Construct raw commit body for signing
    $commitTextLines = @(
        "tree $commitTree",
        "parent $parentSha",
        "author $authorName <$authorEmail> $unixTimestamp $timezoneOffset",
        "committer $committerName <$committerEmail> $unixTimestamp $timezoneOffset",
        "",
        "$commitSubject"
    )
    if ($commitBody) { $commitTextLines += "$commitBody" }

    $commitText = ($commitTextLines -join "`n") + "`n"

    # Sign using GPG
    $tempPath = [System.IO.Path]::GetTempFileName()
    [System.IO.File]::WriteAllText($tempPath, $commitText)
    $signature = & gpg --armor --sign --default-key $authorEmail --detach-sign --output - $tempPath
    Remove-Item $tempPath

    $signedCommit = @{
        message   = "$commitSubject`n$commitBody"
        tree      = $commitTree
        parents   = @($parentSha)
        author    = @{
            name  = $authorName
            email = $authorEmail
            date  = $isoDate
        }
        committer = @{
            name  = $committerName
            email = $committerEmail
            date  = $isoDate
        }
        signature = ($signature -join "`n") + "`n"
    }

    $apiUrl = "https://api.github.com/repos/$OwnerName/$RepositoryName/git/commits"
    $headers = @{
        Authorization = "Bearer $($GitHubTokenInstance.token)"
        Accept        = "application/vnd.github+json"
        "User-Agent"  = "PowerShell-GitHubClient"
    }

    $jsonBody = $signedCommit | ConvertTo-Json -Depth 10 -Compress
    try {
        $response = Invoke-RestMethod -Uri $apiUrl -Method POST -Body $jsonBody -Headers $headers -ContentType "application/json"
        Write-Host "✅ Commit created successfully: $($response.sha)"
        return $response
    } catch {
        Write-Error "❌ Failed to create commit: $_"
    }
}
