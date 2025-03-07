@echo off

komorebic start --masir
pwsh -C Start-Process "komorebi-bar" '"--config" "C:\Users\subwa\.config\komorebi\komorebi.bar.json"' -WindowStyle hidden
pwsh -C Start-Process "komorebi-bar" '"--config" "C:\Users\subwa\.config\komorebi\komorebi.bar.2.json"' -WindowStyle hidden
