$ErrorActionPreference = 'Stop'

$chocoPackage = 'keymapp'
$chocoSource = 'https://community.chocolatey.org/api/v2/'
$latestVersionSource = 'https://oryx.nyc3.cdn.digitaloceanspaces.com/keymapp/keymapp-windows.json'

$Latest = Invoke-RestMethod $latestVersionSource
$Current = choco search $chocoPackage --exact -r --source $chocoSource | ConvertFrom-Csv -Delimiter '|' -Header 'Name', 'Version'

$latestVersion = [version]($Latest.version)

if ($null -eq $Current) {
    $Current = [pscustomobject]@{Version = '0.0.0' }
}

if ([version]($Current.Version) -lt $latestVersion) {
    $toolsDir = Join-Path $PSScriptRoot "packages\$chocoPackage"
    $downloadedFile = New-TemporaryFile
    $latestAsset = $Latest.url
    [System.Net.WebClient]::new().DownloadFile($latestAsset, $downloadedFile)
    $nuspec = Get-ChildItem $toolsDir -Recurse -Filter '*.nuspec' | Select-Object -ExpandProperty FullName
    $install = Get-ChildItem $toolsDir -Recurse -Filter 'chocolateyinstall.ps1' | Select-Object -ExpandProperty FullName
    $checksums = Get-FileHash $downloadedFile -Algorithm SHA256
    Remove-Item $downloadedFile -Force
    $replacements = @(
        @{
            toReplace   = '[[VERSION]]'
            replaceWith = $latestVersion
            file        = $nuspec
        },
        @{
            toReplace   = '[[RELEASE_NOTES]]'
            replaceWith = $latest.releaseNotes
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
    if ($LASTEXITCODE -ne 0) {
        Get-Content $nuspec
        throw "something went wrong..."
    }
}
