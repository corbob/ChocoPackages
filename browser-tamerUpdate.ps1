$ErrorActionPreference = 'Stop'

$chocoPackage = 'browser-tamer'
$chocoSource = 'https://community.chocolatey.org/api/v2/'
$GitHubUser = "aloneguid"
$GitHubRepo = "bt"
$AssetPattern = "msi$"
$assetExtension = "msi"

$Latest = Invoke-RestMethod "https://api.github.com/repos/$GitHubUser/$GitHubRepo/releases/latest"
$Current = choco search $chocoPackage --exact -r --source $chocoSource | ConvertFrom-Csv -Delimiter '|' -Header 'Name', 'Version'

$latestVersion = [version]($Latest.tag_name -replace 'v', '')

if ($null -eq $Current) {
    $Current = [pscustomobject]@{Version = '0.0.0' }
}
if ([version]($Current.Version) -lt $latestVersion) {
    $toolsDir = Join-Path $PSScriptRoot "packages\$chocoPackage"
    $latestAsset = $latest.assets | Where-Object name -Match $AssetPattern
    [System.Net.WebClient]::new().DownloadFile($latestAsset.browser_download_url, "$toolsDir\tools\$chocoPackage.$assetExtension")
    $nuspec = Get-ChildItem $toolsDir -Recurse -Filter '*.nuspec' | Select-Object -ExpandProperty FullName
    $install = Get-ChildItem $toolsDir -Recurse -Filter 'chocolateyinstall.ps1' | Select-Object -ExpandProperty FullName
    $checksums = Get-FileHash "$toolsDir\tools\$chocoPackage.$assetExtension" -Algorithm SHA256
    $replacements = @(
        @{
            toReplace   = '[[ID]]'
            replaceWith = $chocoPackage
            file        = $nuspec
        }
        @{
            toReplace   = '[[TITLE]]'
            replaceWith = 'Browser Tamer'
            file        = $nuspec
        }
        @{
            toReplace   = '[[AUTHOR]]'
            replaceWith = $GitHubUser
            file        = $nuspec
        }
        @{
            toReplace   = '[[PROJECT_URL]]'
            replaceWith = 'https://www.aloneguid.uk/projects/bt/'
            file        = $nuspec
        }
        @{
            toReplace   = '[[LICENSE_URL]]'
            replaceWith = 'https://github.com/aloneguid/bt/blob/master/LICENSE'
            file        = $nuspec
        }
        @{
            toReplace   = '[[PROJECT_SOURCE_URL]]'
            replaceWith = 'https://github.com/aloneguid/bt'
            file        = $nuspec
        }
        @{
            toReplace   = '[[RELEASE_NOTES]]'
            replaceWith = $Latest.body
            file        = $nuspec
        }
        @{
            toReplace   = '[[TAGS]]'
            replaceWith = 'browser tamer'
            file        = $nuspec
        }
        @{
            toReplace   = '[[SUMMARY]]'
            replaceWith = 'Browser Tamer'
            file        = $nuspec
        }
        @{
            toReplace   = '[[DESCRIPTION]]'
            replaceWith = ''
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
