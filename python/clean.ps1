Remove-Item -Path *.nupkg -Force -ErrorAction:SilentlyContinue
Remove-Item -Path python.json -Force -ErrorAction:SilentlyContinue
Remove-Item -Path README.md -Force -ErrorAction:SilentlyContinue
Remove-Item -Path tools/*.exe -Force -ErrorAction:SilentlyContinue
Remove-Item -Path tools/*.msi -Force -ErrorAction:SilentlyContinue
