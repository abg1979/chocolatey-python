$ErrorActionPreference = 'Stop'
if (!$PSScriptRoot)
{
    $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent
}
. "$PSScriptRoot\helper.ps1"

# Get Package Parameters
$parameters = (Get-PackageParameters); $pp = ( Test-PackageParamaters $parameters).ToString() -replace ('""|="True"', '') -replace (";", ' ') -replace ("==", '=')

$packageArgs = @{
    PackageName = 'Python20'
    fileType = 'exe'
    Url = 'https://www.python.org/ftp/python/2.0.1/Python-2.0.1.exe'
    Url64bit = ''
    Checksum = 'D8CE498A186D39A9B1EFF2AF356E0E7D8E4BBBFA57C2EAB728640AC7DD1B7BBA'
    ChecksumType = 'sha256'
    Checksum64 = ''
    ChecksumType64 = ''
    SilentArgs = $pp
}

if ($parameters.both)
{
    write-warning "Installing 32bit version"
    Install-ChocolateyPackage $packageArgs.packageName $packageArgs.fileType $packageArgs.SilentArgs $packageArgs.url -checksum $packageArgs.checksum -checksumtype $packageArgs.ChecksumType
    write-warning "Installing 64bit version"
    Install-ChocolateyPackage $packageArgs.packageName $packageArgs.fileType $packageArgs.SilentArgs $packageArgs.Url64bit $packageArgs.Url64bit -checksum $packageArgs.Checksum64 -checksumtype $packageArgs.ChecksumType64
}
else
{
    write-warning "Installing only Get-OSArchitectureWidth"
    Install-ChocolateyPackage @packageArgs
}
