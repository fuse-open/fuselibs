@echo off
pushd "%~dp0"

call build.bat || goto ERROR

set UNO=Stuff\uno.exe

echo *********************************************
echo * Run Performance tests
echo *********************************************
%UNO% perf-test -logdirectory=PerfLogs Source -q || goto ERROR

:SUCCESS
echo.
echo SUCCESS!
exit /b 0

:ERROR
echo.
echo FATAL ERROR: Something went wrong
echo.
pause
exit /b 1
