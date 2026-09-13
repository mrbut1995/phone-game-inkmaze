@echo off
REM Build LevelDesigner.exe (double-click file này là chạy được).
setlocal
cd /d "%~dp0"

set "PY=%PYTHON%"
if "%PY%"=="" set "PY=python"

echo === Build Level Designer (.exe) ===
"%PY%" build_exe.py %*
if errorlevel 1 (
    echo.
    echo Build that bai. Xem thong bao ben tren.
    pause
    exit /b 1
)

echo.
echo Xong! File chay: %~dp0dist\LevelDesigner.exe
pause
endlocal
