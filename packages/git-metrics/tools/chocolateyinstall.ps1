$ErrorActionPreference = 'Stop';
$toolsDir = "$(Split-Path -Parent $MyInvocation.MyCommand.Definition)"
$url = "[[URL]]"

$packageArgs = @{
  packageName    = $env:ChocolateyPackageName
  unzipLocation  = $toolsDir
  url64bit       = $url
  checksum64     = '[[CHECKSUM]]'
  checksumType64 = 'sha256'
}

Install-ChocolateyZipPackage @packageArgs
