import-module au
. "$PSScriptRoot\update_helper.ps1"
$defaultPython = 'default'

function global:au_BeforeUpdate
{
    Set-ReadMeFile -keys "FileType,Vendor,Version,PackageVersion,PackageName" -new_info "$( $Latest.fileType ),Python,$( $Latest.VersionTwoPart ),$( $Latest.PackageVersion ),$( $Latest.PackageName )"
    # Removal of downloaded files
    Remove-Item ".\tools\*.$( $Latest.fileType )" -Force
    Copy-Item "$PSScriptRoot\install64.ps1" "$PSScriptRoot\tools\chocolateyinstall.ps1" -Force
    # Adding summary to the Latest Hashtable
    $Latest.summary = "Python is a programming language that lets you work more quickly and integrate your systems more effectively. You can learn to use Python and see almost immediate gains in productivity and lower maintenance costs."
    Get-RemoteFiles -Purge -FileNameBase "$( $Latest.PackageName )"
}

function global:au_SearchReplace
{
    if ( [string]::IsNullOrEmpty($Latest.URL32))
    {
        @{
            ".\tools\chocolateyinstall.ps1" = @{
                "(?i)(^\s*PackageName\s*=\s*)('.*')" = "`$1'$( $Latest.PackageName )'"
                "(?i)(^\s*fileType\s*=\s*)('.*')" = "`$1'$( $Latest.fileType )'"
                "(?i)(^\s*url64bit\s*=\s*)('.*')" = "`$1'$( $Latest.URL64 )'"
                "(?i)(^\s*Checksum64\s*=\s*)('.*')" = "`$1'$( $Latest.Checksum64 )'"
                "(?i)(^\s*ChecksumType64\s*=\s*)('.*')" = "`$1'$( $Latest.ChecksumType64 )'"
            }
            ".\python.nuspec" = @{
                "(?i)(^\s*\<title\>).*(\<\/title\>)" = "`${1}$( $Latest.Title )`${2}"
                "(?i)(^\s*\<summary\>).*(\<\/summary\>)" = "`${1}$( $Latest.summary )`${2}"
                "(?i)(^\s*\<licenseUrl\>).*(\<\/licenseUrl\>)" = "`${1}$( $Latest.LicenseUrl )`${2}"
            }
        }
    }
    else
    {
        @{
            ".\tools\chocolateyinstall.ps1" = @{
                "(?i)(^\s*PackageName\s*=\s*)('.*')" = "`$1'$( $Latest.PackageName )'"
                "(?i)(^\s*fileType\s*=\s*)('.*')" = "`$1'$( $Latest.fileType )'"
                "(?i)(^\s*url\s*=\s*)('.*')" = "`$1'$( $Latest.URL32 )'"
                "(?i)(^\s*url64bit\s*=\s*)('.*')" = "`$1'$( $Latest.URL64 )'"
                "(?i)(^\s*Checksum\s*=\s*)('.*')" = "`$1'$( $Latest.Checksum32 )'"
                "(?i)(^\s*ChecksumType\s*=\s*)('.*')" = "`$1'$( $Latest.ChecksumType32 )'"
                "(?i)(^\s*Checksum64\s*=\s*)('.*')" = "`$1'$( $Latest.Checksum64 )'"
                "(?i)(^\s*ChecksumType64\s*=\s*)('.*')" = "`$1'$( $Latest.ChecksumType64 )'"
            }
            ".\python.nuspec" = @{
                "(?i)(^\s*\<title\>).*(\<\/title\>)" = "`${1}$( $Latest.Title )`${2}"
                "(?i)(^\s*\<summary\>).*(\<\/summary\>)" = "`${1}$( $Latest.summary )`${2}"
                "(?i)(^\s*\<licenseUrl\>).*(\<\/licenseUrl\>)" = "`${1}$( $Latest.LicenseUrl )`${2}"
            }
        }
    }
}

function AddInstaller()
{
    param(
        $streams,
        [string] $versionKey,
        [string] $version,
        [string] $packageVersion,
        [string] $fileType,
        [string] $url32,
        [string] $url64
    )
    if (-not$streams[$versionKey])
    {
        $data = @{ }
        $streams.Insert(0, $versionKey, $data)
        $data["Version"] = $version
        if ($packageVersion -ne $defaultPython) {
            $data["PackageName"] = "Python$packageVersion"
            $data["Title"] = "Python $packageVersion - $version"
            $data["PackageVersion"] = $packageVersion
        } else {
            $data["PackageName"] = "Python"
            $data["Title"] = "Python - $version"
            $data["PackageVersion"] = $packageVersion
        }
        $data["LicenseUrl"] = "https://docs.python.org/$versionTwoPart/license.html"
        $data["fileType"] = $fileType
        $data["SemVer"] = $version
        $data["VersionTwoPart"] = $versionTwoPart

    }
    else
    {
        $existingVersion = [version]$streams[$versionKey]["Version"]
        $currentVersion = [version]$version
        if ($existingVersion -gt $currentVersion)
        {
            return
        }
    }
    if ($url32)
    {
        $streams[$versionKey]["URL32"] = $url32
    }
    if ($url64)
    {
        $streams[$versionKey]["URL64"] = $url64
    }
}

function ValidateInstallerFile() {
    param(
    [string] $version,
    [string] $fileVersion,
    [string] $fileQualifier,
    [string] $fileInstallType,
    [string] $fileType
    )
    if ($fileQualifier -and $fileQualifier -ne '.')
    {
        Write-Verbose "Filename: $fileName had a qualier [$fileQualifier]."
        return 0
    }
    if ($fileInstallType -and $fileInstallType -ne "-amd64" -and $fileInstallType -ne "amd64")
    {
        Write-Verbose "Filename: $fileName had a install type [$fileInstallType] which is not win32 or win64."
        return 0
    }
    if ($fileVersion -ne $version)
    {
        Write-Verbose "Filename: $fileName had a version [$version] different from url version [$fileVersion]."
        return 0
    }
    $installerVersion = [version]$version
    $version360 = [version]'3.6.0'
    $version300 = [version]'3.0.0'
    $version270 = [version]'2.7.0'
    if ($installerVersion -lt $version360 -and $installerVersion -ge $version300) {
        # Only support versions > 3.6.0
        Write-Verbose "Filename: $fileName has a version [$version] earlier than 3.6.0."
        return 0
    }
    if ($installerVersion -lt $version270) {
        # Only allow 2.7.0
        Write-Verbose "Filename: $fileName has a version [$version] earlier than 2.7.0."
        return 0
    }

    return 1
}

function GetStreams()
{
    param($releaseUrls)
    $streams = [ordered]@{ }

    $releaseUrls | ForEach-Object {
        $version = $_.href.Trim() -split '/' | Select-Object -Last 1 -Skip 1
        $fileName = $_.href.Trim() -split '/' | Select-Object -Last 1
        $versionTwoPart = $version -replace '([\d]+\.[\d]+).*', "`$1"
        if ($versionTwoPart -eq $version) {
            $version = "$version.0"
            Write-Verbose "Changed version from [$versionTwoPart] to [$version]."
        }
        $versionOnePart = $version -replace '([\d]+).*', "`$1"
        $packageVersion = $versionTwoPart -replace '\.', ''
        if ($fileName -match "([p|P]ython)\-(?<fileVersion>\d+\.\d+(\.\d+)?)(?<fileQualifier>.*?)(?<fileInstallType>[\-|amd64|webinstall|embed]*)\.(?<fileType>msi|exe)")
        {
            $fileVersion = $Matches.fileVersion
            if ($versionTwoPart -eq $fileVersion) {
                $fileVersion = "$fileVersion.0"
                Write-Verbose "Changed file version from [$versionTwoPart] to [$fileVersion]."
            }
            $fileQualifier = $Matches.fileQualifier
            $fileInstallType = $Matches.fileInstallType
            $fileType = $Matches.fileType
        }
        else
        {
            Write-Verbose "Filename [$fileName] did not match."
            return
        }
        $validInstaller = ValidateInstallerFile $version $fileVersion $fileQualifier $fileInstallType $fileType
        if (-not $validInstaller) {
            return
        }
        $url32 = $_ | Where-Object { $_.href -match "python-.+.(exe|msi)$" -and $_.href -notmatch "amd64" } | Select-Object -first 1 -expand href
        $url64 = $_ | Where-Object href -match "python-.+amd64\.(exe|msi)$" | Select-Object -first 1 -expand href
        if (-not $url32 -and -not $url64)
        {
            Write-Verbose "URL: $_ could not be converted to 32 bit or 64 bit urls."
            return
        }
        AddInstaller $streams $versionTwoPart $version $packageVersion $fileType $url32 $url64
        AddInstaller $streams $versionOnePart $version $versionOnePart $fileType $url32 $url64
        AddInstaller $streams $defaultPython $version $defaultPython $fileType $url32 $url64
    }

    foreach ($stream in $streams.GetEnumerator())
    {
        Write-Verbose "Validating Python version $( $stream.Name )"
        Write-Verbose "$( $stream.Value | Out-String )"
    }
    return $streams
}

function global:au_GetLatest
{
    $releases = 'https://www.python.org/downloads/windows/'
    $download_page = Invoke-WebRequest -Uri $releases

    $releaseUrls = $download_page.links | Where-Object { $_.href -match 'http.+python-.+' -and $_.outerHTML -match '.+installer.+' }

    return @{ Streams = GetStreams $releaseUrls }
}
# Optionally add '-NoCheckChocoVersion' below to create packages for versions that already exist on the Chocolatey server.
update -ChecksumFor none -NoCheckUrl -NoCheckChocoVersion
