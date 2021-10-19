import-module au
. "$PSScriptRoot\update_helper.ps1"

function global:au_BeforeUpdate {
	Get-RemoteFiles -Purge -FileNameBase "$($Latest.PackageName)"
	# Removal of downloaded files
	Remove-Item ".\tools\*.$($Latest.fileType)" -Force
	# Change the install file based on $Latest.URL32 and $Latest.fileType
	if (([string]::IsNullOrEmpty($Latest.URL32)) -and ($Latest.fileType -match "msi")) {
		Copy-Item "$PSScriptRoot\install64.ps1" "$PSScriptRoot\tools\chocolateyinstall.ps1" -Force
	}
	else {
		Copy-Item "$PSScriptRoot\install32.ps1" "$PSScriptRoot\tools\chocolateyinstall.ps1" -Force
	}
	Set-ReadMeFile -keys "FileType,Vendor,Version,PackageVersion,PackageName" -new_info "$($Latest.fileType),Python,$($Latest.VersionTwoPart),$($Latest.PackageVersion),$($Latest.PackageName)"
	# Adding summary to the Latest Hashtable
	$Latest.summary	= "Python is a programming language that lets you work more quickly and integrate your systems more effectively. You can learn to use Python and see almost immediate gains in productivity and lower maintenance costs."
}

function global:au_SearchReplace {
	if ( [string]::IsNullOrEmpty($Latest.URL32) ) {
		@{
			".\tools\chocolateyinstall.ps1" = @{
				"(?i)(^\s*PackageName\s*=\s*)('.*')"    = "`$1'$($Latest.PackageName)'"
				"(?i)(^\s*fileType\s*=\s*)('.*')"       = "`$1'$($Latest.fileType)'"
				"(?i)(^\s*url64bit\s*=\s*)('.*')"       = "`$1'$($Latest.URL64)'"
				"(?i)(^\s*Checksum64\s*=\s*)('.*')"     = "`$1'$($Latest.Checksum64)'"
				"(?i)(^\s*ChecksumType64\s*=\s*)('.*')" = "`$1'$($Latest.ChecksumType64)'"
			}
			".\python.nuspec"              = @{
				"(?i)(^\s*\<title\>).*(\<\/title\>)"           = "`${1}$($Latest.Title)`${2}"
				"(?i)(^\s*\<summary\>).*(\<\/summary\>)"       = "`${1}$($Latest.summary)`${2}"
				"(?i)(^\s*\<licenseUrl\>).*(\<\/licenseUrl\>)" = "`${1}$($Latest.LicenseUrl)`${2}"
			}
		}
	}
 else {
		@{
			".\tools\chocolateyinstall.ps1" = @{
				"(?i)(^\s*PackageName\s*=\s*)('.*')"    = "`$1'$($Latest.PackageName)'"
				"(?i)(^\s*fileType\s*=\s*)('.*')"       = "`$1'$($Latest.fileType)'"
				"(?i)(^\s*url\s*=\s*)('.*')"            = "`$1'$($Latest.URL32)'"
				"(?i)(^\s*url64bit\s*=\s*)('.*')"       = "`$1'$($Latest.URL64)'"
				"(?i)(^\s*Checksum\s*=\s*)('.*')"       = "`$1'$($Latest.Checksum32)'"
				"(?i)(^\s*ChecksumType\s*=\s*)('.*')"   = "`$1'$($Latest.ChecksumType32)'"
				"(?i)(^\s*Checksum64\s*=\s*)('.*')"     = "`$1'$($Latest.Checksum64)'"
				"(?i)(^\s*ChecksumType64\s*=\s*)('.*')" = "`$1'$($Latest.ChecksumType64)'"
			}
			".\python.nuspec"              = @{
				"(?i)(^\s*\<title\>).*(\<\/title\>)"           = "`${1}$($Latest.Title)`${2}"
				"(?i)(^\s*\<summary\>).*(\<\/summary\>)"       = "`${1}$($Latest.summary)`${2}"
				"(?i)(^\s*\<licenseUrl\>).*(\<\/licenseUrl\>)" = "`${1}$($Latest.LicenseUrl)`${2}"
			}
		}
	}
}

function GetStreams() {
    param($releaseUrls)
    $streams = [ordered]@{}
    $files = @()

    $releaseUrls | ForEach-Object {
        $version = $_.href.Trim() -split '/' | Select-Object -Last 1 -Skip 1
        $fileName = $_.href.Trim() -split '/' | Select-Object -Last 1
        $versionTwoPart = $version -replace '([\d]+\.[\d]+).*', "`$1"
		$versionOnePart = $version -replace '([\d]+).*', "`$1"
        if ($fileName -match "([p|P]ython)\-(?<fileVersion>\d+\.\d+(\.\d+)?)(?<fileQualifier>.*?)(?<fileInstallType>[\-|amd64|webinstall|embed]*)\.(?<fileType>msi|exe)") {
            $fileVersion = $Matches.fileVersion
            $fileQualifier = $Matches.fileQualifier
            $fileInstallType = $Matches.fileInstallType
			$fileType = $Matches.fileType
        } else {
            Write-Verbose "Filename did not match."
            return
        }
        if ($fileQualifier -and $fileQualifier -ne '.') {
            Write-Verbose "Filename: $fileName had a qualier [$fileQualifier]."
            return
        }
        if ($fileInstallType -and $fileInstallType -ne "-amd64" -and $fileInstallType -ne "amd64") {
            Write-Verbose "Filename: $fileName had a install type [$fileInstallType] which is not win32 or win64."
            return
        }
        if ($fileVersion -ne $version) {
            Write-Verbose "Filename: $fileName had a version different from url version."
            return
        }
        $files += $fileName
        $url32 = $_ | Where-Object { $_.href -match "python-.+.(exe|msi)$" -and $_.href -notmatch "amd64" } | Select-Object -first 1 -expand href
        $url64 = $_ | Where-Object href -match "python-.+amd64\.(exe|msi)$" | Select-Object -first 1 -expand href
		if (-not $url32 -and -not $url64) {
			Write-Verbose "URL: $_ could not be converted to 32 bit or 64 bit urls."
			return
		}
		$packageVersion = $versionTwoPart -replace '\.', ''
        if (-not $streams[$versionTwoPart]) { 
            $streams.Insert(0, $versionTwoPart, @{})
			$streams[$versionTwoPart]["Version"] = $version
			$streams[$versionTwoPart]["PackageName"] = "Python$packageVersion"
			$streams[$versionTwoPart]["Title"] = "Python $packageVersion - $version"
			$streams[$versionTwoPart]["LicenseUrl"] = "https://docs.python.org/$versionTwoPart/license.html"
			$streams[$versionTwoPart]["fileType"] = $fileType
			$streams[$versionTwoPart]["SemVer"] = $version
			$streams[$versionTwoPart]["VersionTwoPart"] = $versionTwoPart
			$streams[$versionTwoPart]["PackageVersion"] = $packageVersion
        } else {
			$existingVersion = [version]$streams[$versionTwoPart]["Version"]
			$currentVersion = [version]$version
			if ($existingVersion -gt $currentVersion) {
				return
			}
		}
		if ($url32) {
			$streams[$versionTwoPart]["URL32"] = $url32
		}
		if ($url64) {
			$streams[$versionTwoPart]["URL64"] = $url64
		}
		if (-not $streams[$versionOnePart]) {
			$streams.Insert(0, $versionOnePart, @{})
			$streams[$versionOnePart]["Version"] = $version
			$streams[$versionOnePart]["PackageName"] = "Python$versionOnePart"
			$streams[$versionOnePart]["Title"] = "Python $versionOnePart - $version"
			$streams[$versionOnePart]["LicenseUrl"] = "https://docs.python.org/$versionOnePart/license.html"
			$streams[$versionOnePart]["fileType"] = $fileType
			$streams[$versionOnePart]["SemVer"] = $version
			$streams[$versionOnePart]["VersionTwoPart"] = $versionOnePart
			$streams[$versionOnePart]["PackageVersion"] = $versionOnePart
		} else {
			$existingVersion = [version]$streams[$versionOnePart]["Version"]
			$currentVersion = [version]$version
			if ($existingVersion -gt $currentVersion) {
				return
			}
		}
		if ($url32) {
			$streams[$versionOnePart]["URL32"] = $url32
		}
		if ($url64) {
			$streams[$versionOnePart]["URL64"] = $url64
		}
    }

	foreach ($stream in $streams.GetEnumerator()) {
		Write-Verbose "Validating Python version $($stream.Name)"
		Write-Verbose "$($stream.Value | Out-String)"
	}

    return $streams
}

function global:au_GetLatest {
	$releases = 'https://www.python.org/downloads/windows/'
	$download_page = Invoke-WebRequest -Uri $releases

    $releaseUrls = $download_page.links | Where-Object { $_.href -match 'http.+python-.+' -and $_.outerHTML -match '.+installer.+'}

    return @{ Streams = GetStreams $releaseUrls }
}
# Optionally add '-NoCheckChocoVersion' below to create packages for versions that already exist on the Chocolatey server.
update -ChecksumFor none -NoCheckUrl -NoCheckChocoVersion
