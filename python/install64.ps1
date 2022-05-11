$ErrorActionPreference  = 'Stop'
if(!$PSScriptRoot){ $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent }
. "$PSScriptRoot\helper.ps1"

# Get Package Parameters
$parameters = (Get-PackageParameters);
$pp = ( Test-PackageParamaters $parameters ).ToString() -replace('""|="True"','') -replace(";", ' ') -replace("==", '=')
if ([string]::IsNullOrEmpty($pp.InstallPrefix))
{
  $pp.add("TargetDir", $env:ProgramFiles64Folder + '\' + __PackageName__)
}
else
{
  $pp.add("TargetDir", $pp.InstallPrefix + '\' + __PackageName__)
  $pp.remove("InstallPrefix")
}



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
