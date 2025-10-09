$ErrorActionPreference = 'Stop'
$toolsDir   = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$fileLocation = 'https://oryx.nyc3.cdn.digitaloceanspaces.com/keymapp/keymapp-latest.exe'
$downloaded = Get-ChocolateyWebFile -PackageName $env:ChocolateyPackageName -FileFullPath "$toolsDir/keymapp.exe" -Url $fileLocation -checksum 'FFE4BBCF2618FB19454F5C829066C5B2746FCE9F572386E863D70B8FD77D7576' -checksumType 'sha256'

[System.IO.File]::WriteAllBytes("$toolsDir/zsa.cer", (Get-AuthenticodeSignature $downloaded).SignerCertificate.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Cert))

certutil -addstore -f "TrustedPublisher" $toolsDir/zsa.cer

$packageArgs = @{
  packageName   = $env:ChocolateyPackageName
  fileType      = 'exe'
  file         = $downloaded
  softwareName  = 'Keymapp*'
  validExitCodes= @(0, 3010, 1641)
  silentArgs   = '/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP-' # Inno Setup
}

Install-ChocolateyPackage @packageArgs
