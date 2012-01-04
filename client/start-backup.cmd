@echo off
setlocal enabledelayedexpansion

REM
REM Usage:
REM     start-backup.cmd [/p]
REM
REM Arguments:
REM         /p: Pretend - show which files would be transfered, but don't do anything
REM

set thisDir=%~dp0
set thisDir=!thisDir:~0,-1!

REM
REM Command-line arguments
REM
set dryRun=
if {%1}=={/p} (
    set dryRun=--dry-run 
)

REM
REM Constants
REM
set configFile=config.csv

REM
REM Ensure we're working out of this script's directory
REM
echo Starting backup from !thisDir!
pushd !thisDir!

REM
REM If vcsUpdateCmd is set, use a version-control system (git, svn, etc) to
REM auto-update these scripts
REM
if NOT {!vcsUpdateCmd!}=={} ( 
    echo Updating scripts:
    echo !vcsUpdateCmd!
    call !vcsUpdateCmd!
)

echo Updating paths, environment variables for Cygwin tools
set HOME=!thisDir!
set PATH=!thisDir!;!PATH!

REM
REM Load config from config.csv
REM
echo Loading configuration:
for /f "delims=, tokens=1,2*" %%f in (!configFile!) do (
    echo %%f=%%g
    set %%f=%%g
)

REM
REM Determine if this computer is on a local or remote network
REM
echo Determining if !rsyncServerHome! is up...
call ping -n 1 !rsyncServerHome! > nul
if !ErrorLevel! EQU 0 (
    set hostToUse=!rsyncServerHome!
    set portToUse=!rsyncPortHome!
) else (
    set hostToUse=!rsyncServerRemote!
    set portToUse=!rsyncPortRemote!
)

echo Using !hostToUse!:!portToUse!

REM
REM Look for a backup script for this computer
REM
set backupScript=backup-!COMPUTERNAME!.cmd
if not exist !backupScript! (
    echo !backupScript! does not exist!
    popd & exit /b 1
)

REM
REM ensure correct rsync-keys permissions
REM
call chmod.exe 600 rsync-keys*

REM
REM Set rsync environment variables
REM
set rsyncStandardOpts=--delete --recursive --times --compress --verbose --progress --update --human-readable --filter="- @eaDir" --filter="- *@SynoEAStream"
set rsyncStandardOpts=!rsyncStandardOpts! --rsh="ssh -p !portToUse! -i rsync-keys-!COMPUTERNAME!" !dryRun!

set rsyncConnectionString=!rsyncUser!@!hostToUse!

echo Starting !backupScript!
call !backupScript!

popd
endlocal