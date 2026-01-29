@echo off
echo =======================================
echo   Photo AI Booth - Web App
echo =======================================
echo.
echo Starting server at http://localhost:8080
echo Press Ctrl+C to stop the server
echo.
start http://localhost:8080
powershell -ExecutionPolicy Bypass -File "%~dp0serve.ps1"
