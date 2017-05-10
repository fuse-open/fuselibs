@echo off
pushd "%~dp0"

Stuff\stuff install Stuff || goto ERROR
Stuff\uno doctor %* || goto ERROR

popd && exit /b 0

:ERROR
pause
popd && exit /b 1
