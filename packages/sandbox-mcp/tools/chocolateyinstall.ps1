$ErrorActionPreference = 'Stop'; # stop on all errors
$toolsDir   = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$url64 = "[[URL]]"

$packageArgs = @{
  packageName   = $env:ChocolateyPackageName
  unzipLocation = $toolsDir
  url64bit      = $url64
  checksum64    = '[[CHECKSUM]]'
  checksumType64= 'sha256'
}
Install-ChocolateyZipPackage @packageArgs

# The bundled node.exe is sandbox-mcp's private runtime; without this it would be shimmed onto the PATH as `node`.
New-Item -Path "$toolsDir\node.exe.ignore" -ItemType File -Force | Out-Null
Install-BinFile -Name sbx -Path "$toolsDir\sbx.cmd"
