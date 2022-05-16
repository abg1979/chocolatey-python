$ErrorActionPreference  = 'Stop'
if(!$PSScriptRoot){ $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent }
. "$PSScriptRoot\helper.ps1"

# Get Package Parameters
$parameters = (Get-PackageParameters);
$validatedParameters = ( Test-PackageParamaters $parameters )
if ([string]::IsNullOrEmpty($validatedParameters.InstallPrefix))
{
  $validatedParameters.add("TargetDir", $env:ProgramFiles64Folder + '\' +'Python36')
}
else
{
  $validatedParameters.add("TargetDir", $pp.InstallPrefix + '\' +'Python36')
  $validatedParameters.remove("InstallPrefix")
}

$pp = $validatedParameters.ToString() -replace('""|="True"','') -replace(";", ' ') -replace("==", '=')

$packageArgs = @{
  PackageName     = 'Python36'
  fileType        = 'exe'
  Url             = 'https://www.python.org/ftp/python/3.6.8/python-3.6.8.exe'
  Url64bit        = 'https://www.python.org/ftp/python/3.6.8/python-3.6.8-amd64.exe'
  Checksum        = '89871D432BC06E4630D7B64CB1A8451E53C80E68DE29029976B12AAD7DBFA5A0'
  ChecksumType    = 'sha256'
  Checksum64      = '96088A58B7C43BC83B84E6B67F15E8706C614023DD64F9A5A14E81FF824ADADC'
  ChecksumType64  = 'sha256'
  SilentArgs      = $pp
}

Install-ChocolateyPackage @packageArgs
