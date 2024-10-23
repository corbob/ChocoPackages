$ErrorActionPreference = 'Stop'

$chocoPackage = 'glab'
$chocoSource = 'https://community.chocolatey.org/api/v2/'

$Latest = (Invoke-RestMethod 'https://gitlab.com/api/v4/projects/34675721/releases' | Sort-Object releases -Descending)[0]
$Current = choco search $chocoPackage --exact -r --source $chocoSource | ConvertFrom-Csv -Delimiter '|' -Header 'Name', 'Version'
$latestVersion = [version]($Latest.tag_name -replace 'v', '')

if ($null -eq $Current) {
    $Current = [pscustomobject]@{Version = '0.0.0' }
}

if ([version]($Current.Version) -lt $latestVersion) {
    $toolsDir = "$PSScriptRoot/packages/$chocoPackage"
    $nuspec = Get-ChildItem $toolsDir -Recurse -Filter '*.nuspec' | Select-Object -ExpandProperty FullName
    $replacements = @(
        @{
            toReplace   = '[[VERSION]]'
            replaceWith = $latestVersion
            file        = $nuspec
        }
    )

    foreach ($currReplacement in $replacements) {
        (Get-Content $currReplacement.file).Replace($currReplacement.toReplace, $currReplacement.replaceWith) | Set-Content $currReplacement.file -Encoding UTF8
    }

    choco pack $nuspec --output-directory "'$PSScriptRoot/updatedPackages'"
}
