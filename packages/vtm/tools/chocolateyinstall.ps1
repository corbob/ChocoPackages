$ErrorActionPreference = 'Stop'; # stop on all errors
$toolsDir   = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$url = "https://github.com/directvt/vtm/releases/download/v0.9.99.70/vtm_windows_x86.zip"
$url64 = "https://github.com/directvt/vtm/releases/download/v0.9.99.70/vtm_windows_x86_64.zip"

$packageArgs = @{
  packageName   = $env:ChocolateyPackageName
  unzipLocation = $toolsDir
  url           = $url
  url64bit      = $url64
  checksum      = 'E4AC4B7CFD22C748C49A481F5D919FBA0256B09EFE3B827B81662DEC8269E89C'
  checksumType  = 'sha256'
  checksum64    = 'B54DA9AC04DE37AC4FD052A2B3BAE0159FABD55F093A1E5E8DD8E42A9FEA1DC3'
  checksumType64= 'sha256'
}
Install-ChocolateyZipPackage @packageArgs
