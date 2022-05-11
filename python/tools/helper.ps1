<# Bol Updating of hashtable to string for ToString method #>
Update-TypeData -TypeName System.Collections.HashTable `
    -MemberType ScriptMethod `
    -MemberName ToString `
    -Value {
    $keys = $this.keys; foreach ($key in $keys)
    {
        $v = $this[$key];
        if ($key -match "\s")
        {
            $hashstr += "`"$key`"" + "=" + "`"$v`"" + ";"
        }
        else
        {
            $hashstr += $key + "=" + "`"$v`"" + ";"
        }
    };
    return $hashstr
}
<# Eol Updating of hashtable to string for ToString method #>

function Test-PackageParamaters
{
    [CmdletBinding()]
    param(
        [hashtable]$pp
    )
    $New_pp = @{ };
    if ([string]::IsNullOrEmpty($pp.AssociateFiles))
    {
        $New_pp.add("AssociateFiles", '0')
    }
    if ([string]::IsNullOrEmpty($pp.InstallAllUsers))
    {
        $New_pp.add("InstallAllUsers", '1')
    }
    if ( [string]::IsNullOrEmpty($pp.quiet))
    {
        $New_pp.add("/quiet", $true)
    }
    else
    {
        # Added to make sure the /quiet silent install is carried over if the user adds it to the params switch list
        $New_pp.add("/quiet", $true)
    }

    return $New_pp
}
