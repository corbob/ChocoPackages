$ErrorActionPreference = 'Stop'

$chocoPackage = 'wezterm.install'
$chocoSource = 'https://community.chocolatey.org/api/v2/'

$Latest = Invoke-RestMethod 'https://api.github.com/repos/wez/wezterm/releases/latest'
$Current = choco search $chocoPackage --exact -r --source $chocoSource | ConvertFrom-Csv -Delimiter '|' -Header 'Name', 'Version'
$latestVersion = [version](($Latest.tag_name -split '-')[0..1] -join '.')

if ($null -eq $Current) {
    $Current = [pscustomobject]@{Version = '0.0.0' }
}

if ([version]($Current.Version) -lt $latestVersion) {
    $latestAsset = $latest.assets | Where-Object name -like 'WezTerm*.exe'
    $toolsDir = Join-Path $PSScriptRoot "packages/$chocoPackage"
    [System.Net.WebClient]::new().DownloadFile($latestAsset.browser_download_url, "$toolsDir/tools/$chocoPackage.exe")
    $checksums = Get-FileHash "$toolsDir/tools/$chocoPackage.exe" -Algorithm SHA256
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
            toReplace   = '[[URL]]'
            replaceWith = $Latest.zipball_url
            file        = $VerificationFile
        },
        @{
            toReplace   = '[[CHECKSUM]]'
            replaceWith = ($checksums | Where-Object algorithm -eq SHA256).hash
            file        = $VerificationFile
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
