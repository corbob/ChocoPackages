$ErrorActionPreference = 'Stop'

$chocoPackage = 'glab.portable'
$chocoSource = 'https://community.chocolatey.org/api/v2/'
$32bitMatch = '386'
$64bitMatch = 'amd64'

$Latest = (Invoke-RestMethod 'https://gitlab.com/api/v4/projects/34675721/releases' | Sort-Object releases -Descending)[0]
$Current = choco search $chocoPackage --exact -r --source $chocoSource | ConvertFrom-Csv -Delimiter '|' -Header 'Name', 'Version'
$latestVersion = [version]($Latest.tag_name -replace 'v', '')

if ($null -eq $Current) {
    $Current = [pscustomobject]@{Version = '0.0.0' }
}

if ([version]($Current.Version) -lt $latestVersion) {
    $latestAssets = $Latest.assets.links | Where-Object name -Match 'zip'
    $toolsDir = "$PSScriptRoot/packages/$chocoPackage"
    $tempDir = "$PSScriptRoot/temp/$chocoPackage"
    mkdir $tempDir
    foreach ($zipFile in $latestAssets) {
        [System.Net.WebClient]::new().DownloadFile($zipFile.direct_asset_url, "$tempDir/$($zipFile.name)")
    }
    $checksum = Get-FileHash "$tempDir/*$32bitMatch.zip" -Algorithm SHA256
    $checksum64 = Get-FileHash "$tempDir/*$64bitMatch.zip" -Algorithm SHA256
    $nuspec = Get-ChildItem $toolsDir -Recurse -Filter '*.nuspec' | Select-Object -ExpandProperty FullName
    $chocolateyInstall = Get-ChildItem $toolsDir -Recurse -Filter 'chocolateyinstall.ps1' | Select-Object -ExpandProperty FullName
    $replacements = @(
        @{
            toReplace   = '[[VERSION]]'
            replaceWith = $latestVersion
            file        = $nuspec
        }
        @{
            toReplace   = '[[URL]]'
            replaceWith = $latestAssets.direct_asset_url | Where-Object { $_ -match $32bitMatch }
            file        = $chocolateyInstall
        }
        @{
            toReplace   = '[[URL64]]'
            replaceWith = $latestAssets.direct_asset_url | Where-Object { $_ -match $64bitMatch }
            file        = $chocolateyInstall
        }
        @{
            toReplace   = '[[CHECKSUM]]'
            replaceWith = ($checksum | Where-Object Algorithm -EQ SHA256).hash
            file        = $chocolateyInstall
        }
        @{
            toReplace   = '[[CHECKSUM64]]'
            replaceWith = ($checksum64 | Where-Object Algorithm -EQ SHA256).hash
            file        = $chocolateyInstall
        }
    )

    foreach ($currReplacement in $replacements) {
        (Get-Content $currReplacement.file).Replace($currReplacement.toReplace, $currReplacement.replaceWith) | Set-Content $currReplacement.file -Encoding UTF8
    }

    choco pack $nuspec --output-directory "'$PSScriptRoot/updatedPackages'"
}
