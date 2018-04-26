@echo off
pushd "%~dp0"

nuget install -ConfigFile Stuff\NuGet.config -OutputDirectory Stuff -ExcludeVersion Stuff\packages.config || goto ERROR
Stuff\stuff install Stuff || goto ERROR
Stuff\uno doctor %* || goto ERROR

popd && exit /b 0

:ERROR
pause
popd && exit /b 1
