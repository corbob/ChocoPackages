$ErrorActionPreference = 'Stop'
$toolsDir   = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$fileLocation = 'https://oryx.nyc3.cdn.digitaloceanspaces.com/keymapp/keymapp-latest.exe'
$downloaded = Get-ChocolateyWebFile -PackageName $env:ChocolateyPackageName -FileFullPath "$toolsDir/keymapp.exe" -Url $fileLocation -checksum '7EBC3492233B9812E55A4969033F36F3259401DC0B71E696E77D7A3DD9AE87F8' -checksumType 'sha256'

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
