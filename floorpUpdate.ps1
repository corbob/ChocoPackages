$ErrorActionPreference = 'Stop'

$chocoPackage = 'floorp'
$chocoSource = 'https://community.chocolatey.org/api/v2/'

$Latest = Invoke-RestMethod 'https://api.github.com/repos/floorp-projects/floorp/releases/latest'
$Current = choco search $chocoPackage --exact -r --source $chocoSource | ConvertFrom-Csv -Delimiter '|' -Header 'Name', 'Version'
$latestVersion = [version]($Latest.tag_name -replace 'v', '')

if ($null -eq $Current) {
    $Current = [pscustomobject]@{Version = '0.0.0' }
}

if ([version]($Current.Version) -lt $latestVersion) {
    $latestAsset64 = $latest.assets | Where-Object name -match 'win64'
    $toolsDir = Join-Path $PSScriptRoot "packages/$chocoPackage"
    [System.Net.WebClient]::new().DownloadFile($latestAsset64.browser_download_url, "$toolsDir/$chocoPackage-win64.exe")
    $checksums64 = Get-FileHash "$toolsDir/$chocoPackage-win64.exe" -Algorithm SHA256
    $nuspec = Get-ChildItem $toolsDir -Recurse -Filter '*.nuspec' | Select-Object -ExpandProperty FullName
    $install = Get-ChildItem $toolsDir -Recurse -Filter 'chocolateyinstall.ps1' | Select-Object -ExpandProperty FullName
    $VerificationFile = Get-ChildItem $toolsDir -Recurse -Filter 'VERIFICATION.txt' | Select-Object -ExpandProperty FullName
    $replacements = @(
        @{
            toReplace   = '[[VERSION]]'
            replaceWith = $latestVersion
            file        = $nuspec
        },
        @{
            toReplace   = '[[URL64]]'
            replaceWith = $latestAsset64.browser_download_url
            file        = $install
        },
        @{
            toReplace   = '[[CHECKSUM64]]'
            replaceWith = ($checksums64 | Where-Object algorithm -eq SHA256).hash
            file        = $install
        },
        @{
            toReplace   = '[[RELEASENOTES]]'
            replaceWith = $Latest.body
            file        = $nuspec
        }
    )

    foreach ($currReplacement in $replacements) {
        (Get-Content $currReplacement.file).Replace($currReplacement.toReplace, $currReplacement.replaceWith) | Set-Content $currReplacement.file -Encoding UTF8
    }

    choco pack $nuspec --output-directory "'$PSScriptRoot/updatedPackages'"
}
