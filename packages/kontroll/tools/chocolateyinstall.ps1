$ErrorActionPreference = 'Stop'; # stop on all errors
$toolsDir   = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$url64 = "https://github.com/zsa/kontroll/releases/download/1.0.3/kontroll-1.0.3-win-x64.zip.zip"

$packageArgs = @{
  packageName   = $env:ChocolateyPackageName
  unzipLocation = $toolsDir
  url64bit      = $url64
  checksum64    = 'C2E4D351E3D423DE18E25F0E3A4656965043FCFF979C06E7D964BEAAECF01C0F'
  checksumType64= 'sha256'
}
Install-ChocolateyZipPackage @packageArgs

