# GitHub Commit Signing with PowerShell

This repository contains scripts for signing Git commits using the GitHub API. The main goal is to ensure that signed commits show as "verified" in the GitHub UI.

## Key Scripts

- **Set-GitHubSignCommit.ps1** - The implementation that ensures proper signature verification
- **test-sign.ps1** - Test script to validate signature verification

## The Problem

When signing commits using the GitHub API, signatures may show as "unverified" with the reason "invalid" in the GitHub UI. This happens due to subtle formatting differences between what's being signed and what GitHub expects for verification.

This script addresses these issues by carefully formatting the commit object and signature to match GitHub's expectations, ensuring your commits show as "verified" in the GitHub interface.

## Usage

### Prerequisites

1. GPG key properly set up in GitHub (a sample key file `github-gpg-key.asc` is included in this repo, but don't use it directly, it's just for reference, refer to the [Generating a GPG key](https://docs.github.com/en/authentication/managing-commit-signature-verification/generating-a-new-gpg-key) for creating your own)
2. GitHub Personal Access Token with appropriate permissions
3. PowerShell (Windows PowerShell or PowerShell Core)

### Setting Up Your Token

```powershell
# Set your token as an environment variable
$env:GITHUB_TOKEN = "your-github-token-here"

# Create a token object for use with the script
$GitHubTokenInstance = [PSCustomObject]@{
    token = $env:GITHUB_TOKEN
}
```

### Signing the Latest Commit

The main function to use is `Set-GitHubSignLatestCommit`, which handles the entire signing process:

```powershell
# Load the script
. .\Set-GitHubSignCommit.ps1

# Sign the latest commit on the main branch
Set-GitHubSignLatestCommit -RepositoryName "your-repo" `
                          -BranchName "main" `
                          -GitHubTokenInstance $GitHubTokenInstance `
                          -OwnerName "your-username"
```

**Parameters:**

- `RepositoryName`: The name of your GitHub repository
- `BranchName`: The branch containing the commit to sign
- `GitHubTokenInstance`: A PowerShell object containing your GitHub token
- `OwnerName`: Your GitHub username
```

### Running a Test

The included test script provides an easy way to test the signing functionality:

```powershell
# Run the test script with your token
.\test-sign.ps1 -Token $env:GITHUB_TOKEN
```

You can also specify additional parameters:

```powershell
.\test-sign.ps1 -RepositoryName "your-repo" -BranchName "main" -Token $env:GITHUB_TOKEN
```
```

## How It Works

The `Set-GitHubSignCommit.ps1` script performs the following steps:

1. Fetches the latest commit data from GitHub API
2. Creates a commit object that matches Git's format
3. Signs it with your local GPG key
4. Creates a new commit via GitHub API with the signature
5. Updates the branch reference to point to the new signed commit

## Key Technical Details

1. **Timestamp Handling**: Using the correct timestamp format that GitHub's verification system expects
2. **Commit Object Format**: Creating a commit object that matches Git's format
3. **GPG Signature Integration**: Properly formatting and including GPG signatures
4. **API Interaction**: Constructing and sending API requests to GitHub

## Troubleshooting

- **Signature shows as unverified**: Ensure your GPG key is properly configured in GitHub
- **GPG signing errors**: Check that the email in the commit matches the email associated with your GPG key
- **API errors**: Verify your GitHub token has the repository and commit permissions
- **Token issues**: Make sure your token is valid and hasn't expired

## Repository Contents

- **Set-GitHubSignCommit.ps1** - Main PowerShell script with functions for signing commits via GitHub API
- **test-sign.ps1** - Test script that demonstrates how to use the main script
- **github-gpg-key.asc** - Sample GPG key file (for reference only)
- **test.txt** - Test file used for sample commits

## Verifying Your Signed Commits

After signing a commit with this script:

1. Go to your GitHub repository
2. View the commit history
3. Look for the green "Verified" badge next to the commit
4. Click on the badge to view signature details

## Additional Notes

For more information on GitHub's commit signature verification:

- Check GitHub's documentation on [commit signature verification](https://docs.github.com/en/authentication/managing-commit-signature-verification/about-commit-signature-verification)
- Make sure your GPG key is properly configured in your GitHub account
