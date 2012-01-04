@echo off
setlocal enabledelayedexpansion

REM
REM Usage:
REM     generate-client-keys.cmd
REM  or
REM     generate-client-keys.cmd [computername]

REM
REM Command-line arguments
REM
set computerToGenerate=!COMPUTERNAME!
if NOT {%1}=={} (
    set computerToGenerate=%1
)

REM
REM Generate key
REM
echo Generating a key for !computerToGenerate! into rsync-keys-!computerToGenerate!...

call ssh-keygen.exe -t rsa -b 2048 -N "" -f rsync-keys-!computerToGenerate!

REM
REM Ensure keys are chmod 600:
REM
call chmod.exe 600 rsync-keys-!computerToGenerate!*

REM
REM Show .pub
REM
echo.
echo Add this key to your Synology user's .ssh/authorized_keys (available in rsync-keys-!computerToGenerate!.pub):
type rsync-keys-!computerToGenerate!.pub
echo.
echo You will need to prefix that key with something like this (see README.md):
echo command="/root/.ssh/validate-rsync.sh /volume1/backup/!computerToGenerate!" [ssh-dss AAAbzczcz...]

endlocal