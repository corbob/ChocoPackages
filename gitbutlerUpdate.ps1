$ErrorActionPreference = 'Stop'

$chocoPackage = 'gitbutler'
$chocoSource = 'https://community.chocolatey.org/api/v2/'
$GitHubUser = "gitbutlerapp"
$GitHubRepo = "gitbutler"

$Latest = Invoke-RestMethod "https://api.github.com/repos/$GitHubUser/$GitHubRepo/releases/latest"
$Current = choco search $chocoPackage --exact -r --source $chocoSource | ConvertFrom-Csv -Delimiter '|' -Header 'Name', 'Version'

$latestVersion = [version]($Latest.tag_name -replace 'release/', '')

if ($null -eq $Current) {
    $Current = [pscustomobject]@{Version = '0.0.0' }
}
if ([version]($Current.Version) -lt $latestVersion) {
    $toolsDir = Join-Path $PSScriptRoot "packages\$chocoPackage"
    $latestAsset = [System.Net.HttpWebRequest]::Create('https://app.gitbutler.com/downloads/release/windows/x86_64/msi').GetResponse().ResponseUri.AbsoluteUri
    [System.Net.WebClient]::new().DownloadFile($latestAsset, "$toolsDir\tools\$chocoPackage.$assetExtension")
    $nuspec = Get-ChildItem $toolsDir -Recurse -Filter '*.nuspec' | Select-Object -ExpandProperty FullName
    $install = Get-ChildItem $toolsDir -Recurse -Filter 'chocolateyinstall.ps1' | Select-Object -ExpandProperty FullName
    $checksums = Get-FileHash "$toolsDir\tools\$chocoPackage.$assetExtension" -Algorithm SHA256
    $replacements = @(
        @{
            toReplace   = '[[VERSION]]'
            replaceWith = $latestVersion
            file        = $nuspec
        },
        @{
            toReplace   = '[[RELEASE_NOTES]]'
            replaceWith = $latest.body
            file        = $nuspec
        },
        @{
            toReplace   = '[[URL]]'
            replaceWith = $latestAsset
            file        = $install
        },
        @{
            toReplace   = '[[CHECKSUM]]'
            replaceWith = ($checksums | Where-Object algorithm -eq SHA256).hash
            file        = $install
        }
    )
    foreach ($currReplacement in $replacements) {
        (Get-Content $currReplacement.file).Replace($currReplacement.toReplace, $currReplacement.replaceWith) | Set-Content $currReplacement.file
    }

    choco pack $nuspec --output-directory "'$PSScriptRoot\updatedPackages'"
}
