@echo off
pushd "%~dp0"

call build.bat || goto ERROR

echo *********************************************
echo * Run UnoTest tests
echo *********************************************
Stuff\uno test Source -q || goto ERROR

echo *********************************************
echo * Test that shipped packages compile
echo *********************************************
Stuff\uno test-gen Source PackageCompilationTest || goto ERROR
Stuff\uno build --clean --target=dotnetexe --no-strip PackageCompilationTest || goto ERROR

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
