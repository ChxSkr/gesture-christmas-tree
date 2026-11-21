@echo off
setlocal
cd /d "%~dp0"
set PORT=8777

where python >nul 2>nul
if errorlevel 1 (
  echo [!] Python not found in PATH.
  echo     Any static server works, for example:
  echo         npx serve .
  echo     Camera access requires http://localhost, not file://
  pause
  exit /b 1
)

echo.
echo   Gesture Christmas Tree
echo   ---------------------------------------------
echo   URL      : http://localhost:%PORT%/index.html
echo   Demo     : http://localhost:%PORT%/index.html?demo=1
echo   Stop     : press Ctrl+C in this window
echo   ---------------------------------------------
echo.

start "" cmd /c "timeout /t 2 >nul & start http://localhost:%PORT%/index.html"
python -m http.server %PORT% --bind 127.0.0.1
