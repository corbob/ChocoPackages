
$ErrorActionPreference = 'Stop';
$toolsDir = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$url = "[[URL]]"

$unzipLocation = $toolsDir

$previousInstallKey = Get-ChildItem HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\| Get-ItemProperty | Where-Object displayname -like 'browser tamer'

if ($previousInstallKey) {
  Write-Host "Found previous install."
  $unzipLocation = $previousInstallKey.InstallLocation
}

$packageArgs = @{
  packageName    = $env:ChocolateyPackageName
  unzipLocation  = $unzipLocation
  url            = $url
  checksum       = '[[CHECKSUM]]'
  checksumType   = 'sha256'
}

Install-ChocolateyZipPackage @packageArgs
