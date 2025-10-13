$ErrorActionPreference = 'Stop'

$chocoPackage = 'kanata'
$chocoSource = 'https://community.chocolatey.org/api/v2/'
$GitHubUser = "jtroo"
$GitHubRepo = "kanata"
$AssetPattern = "\..*"

$Latest = Invoke-RestMethod "https://api.github.com/repos/$GitHubUser/$GitHubRepo/releases/latest"
$Current = choco search $chocoPackage --exact -r --source $chocoSource | ConvertFrom-Csv -Delimiter '|' -Header 'Name', 'Version'

$latestVersion = [version]($Latest.tag_name -replace 'v', '')

if ($null -eq $Current) {
    $Current = [pscustomobject]@{Version = '0.0.0' }
}
if ([version]($Current.Version) -lt $latestVersion) {
    $webClient = [System.Net.WebClient]::new()
    $toolsDir = Join-Path $PSScriptRoot "packages\$chocoPackage"
    $webClient.DownloadFile("https://github.com/jtroo/kanata/raw/refs/tags/v$latestVersion/LICENSE", "$toolsDir/tools/LICENSE.txt")
    $assets = $latest.assets | Where-Object name -Match $AssetPattern

    foreach ($asset in $assets) {
        $webClient.DownloadFile($asset.browser_download_url, "$toolsDir\tools\$($asset.name)")
        "$($asset.name) - $($asset.digest)" | Add-Content "$toolsDir/tools/VERIFICATION.txt"
    }

    $nuspec = Get-ChildItem $toolsDir -Recurse -Filter '*.nuspec' | Select-Object -ExpandProperty FullName
    $install = Get-ChildItem $toolsDir -Recurse -Filter 'chocolateyinstall.ps1' | Select-Object -ExpandProperty FullName
    $replacements = @(
        @{
            toReplace   = '[[ID]]'
            replaceWith = $chocoPackage
            file        = $nuspec
        }
        @{
            toReplace   = '[[TITLE]]'
            replaceWith = 'kanata'
            file        = $nuspec
        }
        @{
            toReplace   = '[[AUTHOR]]'
            replaceWith = $GitHubUser
            file        = $nuspec
        }
        @{
            toReplace   = '[[PROJECT_URL]]'
            replaceWith = 'https://github.com/jtroo/kanata/'
            file        = $nuspec
        }
        @{
            toReplace   = '[[LICENSE_URL]]'
            replaceWith = "https://github.com/jtroo/kanata/raw/refs/tags/v$latestVersion/LICENSE"
            file        = $nuspec
        }
        @{
            toReplace   = '[[PROJECT_SOURCE_URL]]'
            replaceWith = 'https://github.com/jtroo/kanata/'
            file        = $nuspec
        }
        @{
            toReplace   = '[[TAGS]]'
            replaceWith = 'kanata keyboard utility'
            file        = $nuspec
        }
        @{
            toReplace   = '[[VERSION]]'
            replaceWith = $latestVersion
            file        = "$toolsDir/tools/VERIFICATION.txt"
        }
        @{
            toReplace   = '[[VERSION]]'
            replaceWith = $latestVersion
            file        = $nuspec
        }
    )
    foreach ($currReplacement in $replacements) {
        (Get-Content $currReplacement.file).Replace($currReplacement.toReplace, $currReplacement.replaceWith) | Set-Content $currReplacement.file
    }

    choco pack $nuspec --output-directory "'$PSScriptRoot\updatedPackages'"
}
