@echo off
setlocal

REM
REM Template to backup a computer.
REM
REM Instructions:
REM  1. Rename to backup-[computername].cmd
REM  2. Set rsyncPath below
REM  3. Setup the rsync commands you want to use
REM
REM Available environment variables:
REM  %rsyncStandardOpts% - Standard rsync command-line options
REM  %rsyncConnectionString% - Rsync connection string
REM  %rsyncRootPath% - Remote root rsync path
REM

REM
REM TODO # 1 / 2: Set your rsync path
REM
REM Examples:
REM  1. Organize backups by computer name:
REM     set rsyncPath=%rsyncRootPath%/%COMPUTERNAME%
REM
REM  2. Organize backups by user name, then computer name:
REM     set rsyncPath=%rsyncRootPath%/bob/%COMPUTERNAME%
REM
set rsyncPath=%rsyncRootPath%/%COMPUTERNAME%

REM
REM TODO # 2 / 2: Setup rsync commands to backup
REM
REM Examples:
REM  1. Backup a user's documents
REM     set cmdArgs=rsync %rsyncStandardOpts% "/cygdrive/c/users/bob/documents/" %rsyncConnectionString%:%rsyncPath%/documents
REM     echo Starting %cmdArgs%
REM     call %cmdArgs%
REM
REM  2. Backup a user's favorites
REM     set cmdArgs=rsync %rsyncStandardOpts% "/cygdrive/c/users/bob/favorites/" %rsyncConnectionString%:%rsyncPath%/favorites
REM     echo Starting %cmdArgs%
REM     call %cmdArgs%
REM
set cmdArgs=rsync %rsyncStandardOpts% "/cygdrive/c/users/bob/documents/" %rsyncConnectionString%:%rsyncPath%/documents
echo Starting %cmdArgs%
call %cmdArgs%

endlocal
exit /b %ErrorLevel%