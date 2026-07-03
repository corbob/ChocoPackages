$ErrorActionPreference = 'Stop'

$chocoPackage = 'devproxy'
$chocoSource = 'https://community.chocolatey.org/api/v2/'
$GitHubUser = "dotnet"
$GitHubRepo = "dev-proxy"
$AssetPattern = "dev-proxy-win-x64-.*\.zip"

$Latest = Invoke-RestMethod "https://api.github.com/repos/$GitHubUser/$GitHubRepo/releases/latest"
$Current = choco search $chocoPackage --exact -r --source $chocoSource | ConvertFrom-Csv -Delimiter '|' -Header 'Name', 'Version'

$latestVersion = [version]($Latest.tag_name -replace 'v', '')

if ($null -eq $Current) {
    $Current = [pscustomobject]@{Version = '0.0.0' }
}
if ([version]($Current.Version) -lt $latestVersion) {
    $webClient = [System.Net.WebClient]::new()
    $toolsDir = Join-Path $PSScriptRoot "packages\$chocoPackage"
    $asset = $latest.assets | Where-Object name -Match $AssetPattern

    $nuspec = Get-ChildItem $toolsDir -Recurse -Filter '*.nuspec' | Select-Object -ExpandProperty FullName
    $install = Get-ChildItem $toolsDir -Recurse -Filter 'chocolateyinstall.ps1' | Select-Object -ExpandProperty FullName
    $replacements = @(
        @{
            toReplace   = '[[VERSION]]'
            replaceWith = $latestVersion
            file        = $nuspec
        }
        @{
            toReplace = '[[URL]]'
            replaceWith = $asset.browser_download_url
            file = $install
        }
        @{
            toReplace = '[[CHECKSUM]]'
            replaceWith = $asset.digest.Replace('sha256:','').ToUpper()
            file = $install
        }
    )
    foreach ($currReplacement in $replacements) {
        (Get-Content $currReplacement.file).Replace($currReplacement.toReplace, $currReplacement.replaceWith) | Set-Content $currReplacement.file
    }

    choco pack $nuspec --output-directory "'$PSScriptRoot\updatedPackages'"
}
