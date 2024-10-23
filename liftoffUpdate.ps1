$ErrorActionPreference = 'Stop'

$chocoPackage = 'liftoff'
$chocoSource = 'https://community.chocolatey.org/api/v2/'

$Latest = Invoke-RestMethod 'https://api.github.com/repos/liftoff-app/liftoff/releases/latest'
$Current = choco search $chocoPackage --exact -r --source $chocoSource | ConvertFrom-Csv -Delimiter '|' -Header 'Name', 'Version'
$latestVersion = [version]($Latest.tag_name -replace 'v')

if ($null -eq $Current) {
    $Current = [pscustomobject]@{Version = '0.0.0' }
}

if ([version]($Current.Version) -lt $latestVersion) {
    $latestAsset = $latest.assets | Where-Object name -Match 'windows'
    $toolsDir = "$PSScriptRoot/packages/$chocoPackage"
    [System.Net.WebClient]::new().DownloadFile($latestAsset.browser_download_url, "$chocoPackage.zip")
    $checksums = Get-FileHash "$chocoPackage.zip" -Algorithm SHA256
    $nuspec = Get-ChildItem $toolsDir -Recurse -Filter '*.nuspec' | Select-Object -ExpandProperty FullName
    $install = Get-ChildItem $toolsDir -Recurse -Filter 'chocolateyinstall.ps1' | Select-Object -ExpandProperty FullName
    $replacements = @(
        @{
            toReplace   = '[[VERSION]]'
            replaceWith = $latestVersion
            file        = $nuspec
        }
        @{
            toReplace   = '[[RELEASENOTES]]'
            replaceWith = $Latest.body
            file        = $nuspec
        }
        @{
            toReplace   = '[[URL]]'
            replaceWith = $latestAsset.browser_download_url
            file        = $install
        },
        @{
            toReplace   = '[[CHECKSUM]]'
            replaceWith = ($checksums | Where-Object algorithm -eq SHA256).hash
            file        = $install
        }
    )

    foreach ($currReplacement in $replacements) {
        (Get-Content $currReplacement.file).Replace($currReplacement.toReplace, $currReplacement.replaceWith) | Set-Content $currReplacement.file -Encoding UTF8
    }

    choco pack $nuspec --output-directory "'$PSScriptRoot/updatedPackages'"
}
