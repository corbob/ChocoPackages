param($ApiKey)
$exits = @()
choco find --source updatedPackages -r | ConvertFrom-Csv -Delimiter '|' -Header Name, Version | ForEach-Object {
    $existing = choco find $_.Name --source https://community.chocolatey.org/api/v2/ --version $_.Version --exact -r
    if ([string]::IsNullOrWhiteSpace($existing)) {
        choco push "updatedPackages/$($_.Name).$($_.Version).nupkg" --source https://push.chocolatey.org/ --key $ApiKey
        $exits += [pscustomobject]@{ Name = $_.Name ; Exit = $LASTEXITCODE }
    } else {
        Write-Host "$($_.Name) is already published to Community Repository, it's likely not yet approved."
    }
}
$failures = $exits | ? Exit -ne 0
if ($null -ne $failures) {
    Write-Error "$($failures.Count) failures pushing:
$failures"
    throw "There were failures pushing to CCR."
} 
