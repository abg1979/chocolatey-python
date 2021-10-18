import-module au

$releases = 'https://www.python.org/downloads/windows/'

function global:au_SearchReplace {
    @{
        ".\tools\helpers.ps1"      = @{
            "(?i)(^\s*packageName\s*=\s*)('.*')"              = "`$1'$($Latest.PackageName)'"
            "(?i)(^\s*fileType\s*=\s*)('.*')"                 = "`$1'$($Latest.FileType)'"
            "(?i)(^\s*file\s*=\s*`"[$]toolsPath\\)(.*)`""     = "`$1$($Latest.FileName32)`""
            "(?i)(\['file64'\]\s*=\s*`"[$]toolsPath\\)(.*)`"" = "`$1$($Latest.FileName64)`""
        }

        ".\legal\VERIFICATION.txt" = @{
            "(?i)(\s+x32:).*"     = "`${1} $($Latest.URL32)"
            "(?i)(\s+x64:).*"     = "`${1} $($Latest.URL64)"
            "(?i)(checksum32:).*" = "`${1} $($Latest.Checksum32)"
            "(?i)(checksum64:).*" = "`${1} $($Latest.Checksum64)"
        }
    }
}

function global:au_BeforeUpdate { Remove-Item tools\*.msi, tools\*.exe -ea 0; Get-RemoteFiles -Purge -NoSuffix }

function GetStreams() {
    param($releaseUrls)
    $streams = @{ }

    $releaseUrls | ForEach-Object {
        $version = $_.href.Trim() -split '/' | Select-Object -Last 1 -Skip 1
        #if ($version -match '[a-z]') { Write-Host "Skipping prerelease: '$version'"; return }
        $versionTwoPart = $version -replace '([\d]+\.[\d]+).*', "`$1"
        Write-Host "ExactVersion: $version`t Version: $versionTwoPart"

        if ($streams.$versionTwoPart) { return }

        $url32 = $_ | Where-Object { $_.href -match "python-.+.(exe|msi)$" -and $_.href -notmatch "amd64" } | Select-Object -first 1 -expand href
        $url64 = $_ | Where-Object href -match "python-.+amd64\.(exe|msi)$" | Select-Object -first 1 -expand href
        Write-Host "32: $url32"
        Write-Host "64: $url64"
        $streams.$versionTwoPart = @{ URL32 = $url32 ; URL64 = $url64 ; Version = Get-Version $version }
    }

    Write-Host $streams.Count 'streams collected'
 ``   $streams
}

function global:au_GetLatest {
    $download_page = Invoke-WebRequest -Uri $releases

    $releaseUrls = $download_page.links | Where-Object { $_.href -match 'http.+python-.+' -and $_.outerHTML -match '.+installer.+'}

    @{ Streams = GetStreams $releaseUrls }
}

if ($MyInvocation.InvocationName -ne '.') {
    # run the update only if script is not sourced by the virtual package python
    Update-Package
}
