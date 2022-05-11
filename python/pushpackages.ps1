Write-Output "Got arguments: $args"
$packages = (Get-ChildItem -Filter *.nupkg)
foreach ($package in $packages)
{
	choco push $package @Args
}
