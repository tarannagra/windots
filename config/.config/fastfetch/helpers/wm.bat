@echo off

REM Taran's simple batch file to include Windows based Window Managers to fastfetch :D
REM !! It may be slow, but it's okay if it works :D

REM For adding any extra, simply copy the command and then assign the .exe and set wm=WM NAME


tasklist /fi "imagename eq komorebi.exe" | find ":" > nul
if errorlevel 1 set wm=Komorebi
tasklist /fi "imagename eq glazewm.exe" | find ":" > nul
if errorlevel 1 set wm=GlazeWM

echo %wm%