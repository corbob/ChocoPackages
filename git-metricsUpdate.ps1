$ErrorActionPreference = 'Stop'

$chocoPackage = 'git-metrics'
$chocoSource = 'https://community.chocolatey.org/api/v2/'
$GitHubUser = "steffen"
$GitHubRepo = "git-metrics"
$AssetPattern = "windows-amd64\.zip$"
$assetExtension = "zip"

$Latest = Invoke-RestMethod "https://api.github.com/repos/$GitHubUser/$GitHubRepo/releases/latest"
$Current = choco search $chocoPackage --exact -r --source $chocoSource | ConvertFrom-Csv -Delimiter '|' -Header 'Name', 'Version'

$latestVersion = [version]($Latest.tag_name -replace 'v', '')

if ($null -eq $Current) {
    $Current = [pscustomobject]@{Version = '0.0.0' }
}
if ([version]($Current.Version) -lt $latestVersion) {
    $toolsDir = Join-Path $PSScriptRoot "packages\$chocoPackage"
    $downloadFile = "$toolsDir\tools\$chocoPackage.$assetExtension"
    $latestAsset = $latest.assets | Where-Object name -Match $AssetPattern
    [System.Net.WebClient]::new().DownloadFile($latestAsset.browser_download_url, $downloadFile)
    $nuspec = Get-ChildItem $toolsDir -Recurse -Filter '*.nuspec' | Select-Object -ExpandProperty FullName
    $install = Get-ChildItem $toolsDir -Recurse -Filter 'chocolateyinstall.ps1' | Select-Object -ExpandProperty FullName
    $checksums = Get-FileHash $downloadFile -Algorithm SHA256
    Remove-Item $downloadFile -Force
    $replacements = @(
        @{
            toReplace   = '[[ID]]'
            replaceWith = $chocoPackage
            file        = $nuspec
        }
        @{
            toReplace   = '[[TITLE]]'
            replaceWith = 'git-metrics'
            file        = $nuspec
        }
        @{
            toReplace   = '[[AUTHOR]]'
            replaceWith = $GitHubUser
            file        = $nuspec
        }
        @{
            toReplace   = '[[PROJECT_URL]]'
            replaceWith = 'https://github.com/steffen/git-metrics/'
            file        = $nuspec
        }
        @{
            toReplace   = '[[LICENSE_URL]]'
            replaceWith = 'https://github.com/steffen/git-metrics/blob/main/LICENSE.md'
            file        = $nuspec
        }
        @{
            toReplace   = '[[PROJECT_SOURCE_URL]]'
            replaceWith = 'https://github.com/steffen/git-metrics/'
            file        = $nuspec
        }
        @{
            toReplace   = '[[RELEASE_NOTES]]'
            replaceWith = $Latest.body
            file        = $nuspec
        }
        @{
            toReplace   = '[[TAGS]]'
            replaceWith = 'git metic tools'
            file        = $nuspec
        }
        @{
            toReplace   = '[[SUMMARY]]'
            replaceWith = 'A tool to analyze the growth of Git repositories '
            file        = $nuspec
        }
        @{
            toReplace   = '[[DESCRIPTION]]'
            replaceWith = @"
A powerful Git repository analysis tool that provides detailed metrics, growth statistics, future projections, and contributor insights for your Git repositories.

## Overview

`git-metrics` is a command-line utility that analyzes Git repositories to provide comprehensive insights about repository history, structure, and growth patterns. The tool examines your repository's Git object database to reveal historical trends, identify storage-heavy components, and visualize contributor activity over time. With this data, it generates projections for future repository growth and helps identify optimization opportunities.

Key features include:
- Repository metadata analysis (first commit, age)
- Year-by-year growth statistics for Git objects (commits, trees, blobs) and their on-disk size
- Future growth projections based on historical trends
- Directory structure analysis with size impact indicators
- Identification of largest files in the repository
- File extension distribution analysis
- Contributor statistics showing top committers and authors over time

## Examples

[Interactive examples](https://steffen.github.io/git-metrics/)
"@
            file        = $nuspec
        }
        @{
            toReplace   = '[[VERSION]]'
            replaceWith = $latestVersion
            file        = $nuspec
        }
        @{
            toReplace   = '[[URL]]'
            replaceWith = $LatestAsset.browser_download_url
            file        = $install
        }
        @{
            toReplace   = '[[CHECKSUM]]'
            replaceWith = ($checksums | Where-Object algorithm -EQ SHA256).hash
            file        = $install
        }
    )
    foreach ($currReplacement in $replacements) {
        (Get-Content $currReplacement.file).Replace($currReplacement.toReplace, $currReplacement.replaceWith) | Set-Content $currReplacement.file
    }

    choco pack $nuspec --output-directory "'$PSScriptRoot\updatedPackages'"
}
