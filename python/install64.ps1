$ErrorActionPreference  = 'Stop'
if(!$PSScriptRoot){ $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent }
. "$PSScriptRoot\helper.ps1"

# Get Package Parameters
$parameters = (Get-PackageParameters);
$validatedParameters = ( Test-PackageParamaters $parameters )
if ([string]::IsNullOrEmpty($validatedParameters.InstallPrefix))
{
  $validatedParameters.add("TargetDir", $env:ProgramFiles64Folder + '\' + __PackageName__)
}
else
{
  $validatedParameters.add("TargetDir", $pp.InstallPrefix + '\' + __PackageName__)
  $validatedParameters.remove("InstallPrefix")
}

$pp = $validatedParameters.ToString() -replace('""|="True"','') -replace(";", ' ') -replace("==", '=')

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
