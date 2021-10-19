$ErrorActionPreference  = 'Stop'
if(!$PSScriptRoot){ $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent }
. "$PSScriptRoot\helper.ps1"

# Get Package Parameters
$parameters = (Get-PackageParameters); $pp = ( Test-PackageParamaters $parameters ).ToString() -replace('""|="True"','') -replace(";", ' ') -replace("==", '=')

$packageArgs = @{
  PackageName     = ''
  fileType        = ''
  Url             = ''
  Url64bit        = ''
  Checksum        = ''
  ChecksumType    = ''
  Checksum64      = ''
  ChecksumType64  = ''
  SilentArgs      = $pp
}

Install-ChocolateyPackage @packageArgs
