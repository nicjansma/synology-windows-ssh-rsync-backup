Copyright (c) 2012 Nic Jansma
http://nicj.net

These scripts allow you to easily and securely backup your Windows computers to a Synology NAS via rsync over SSH.

Features
--------
* Uses rsync over ssh to securely backup your Windows hosts to a Synology NAS.
* Each Windows host gets a unique SSH private/public key that can be revoked at any time on the server.
* The server limits the SSH private/public keys so they can only run rsync, and can't be used to log into the server.
* The server also limits the SSH private/public keys to a valid path prefix, so rsync can't destroy other parts of the file system.
* Windows hosts can backup to the Synology NAS if they're on the local network or on a remote network, as long as the outside IP/port are known.

NOTE: The backups are performed via the Synology root user's credentials, to simplify permissions.  The SSH keys are only valid for
rsync, and are limited to the path prefix you specify.  You could change the scripts to backup as another user if you want (config.csv).

Synology NAS Setup
--------------
1.  Enable SSH on your Synology NAS if you haven't already.  Go to Control Panel - Terminal, and check "Enable SSH service".

2.  Log into your Synology via SSH.

3.  Create a /root/.ssh directory if it doesn't already exist

        mkdir /root/.ssh
        chmod 700 /root/.ssh

4.  Upload server/validate-rsync.sh to your /root/.ssh/validate-rsync.sh.  Then chmod it so it can be run:

        chmod 755 /root/.ssh/validate-rsync.sh

5.  Create an authorized_keys file for later use:

        touch /root/.ssh/authorized_keys
        chmod 600 /root/.ssh/authorized_keys

6.  Ensure private/public key logins are enabled in /etc/ssh/sshd_config.

        vi /etc/ssh/sshd_config

    You want to ensure the following lines are uncommented:

        PubkeyAuthentication yes
        AuthorizedKeysFile .ssh/authorized_keys

7.  You should reboot your Synology to ensure the settings are applied:

        reboot

8.  Setup a share on your Synology NAS for backups (eg, 'backup').

Client Package Preparation
--------------------------
Before you backup any clients, you will need to make a couple changes to the files in the client/ directory.

1.  First, you'll need a few binaries (rsync, ssh, chmod, ssh-keygen) on your system to facilitate the ssh/rsync transfer.
    http://www.cygwin.com/ can be used to accomplish this.  You can easily install Cygwin from http://www.cygwin.com/.
    After installing, pluck a couple files from the bin/ folder and put them into the client/ directory.

    The binaries you need are:

        chmod.exe
        rsync.exe
        ssh.exe
        ssh-keygen.exe

    You may also need a couple libraries to ensure those binaries run:

        cygcrypto-0.9.8.dll
        cyggcc_s-1.dll
        cygiconv-2.dll
        cygintl-8.dll
        cygpopt-0.dll
        cygspp-0.dll
        cygwin1.dll
        cygz.dll

2.  Next, you should update config.csv for your needs:

        rsyncServerRemote - The address clients can connect to when remote (eg, a dynamic IP host)
        rsyncPortRemote   - The port clients connect to when remote (eg, 22)
        rsyncServerHome   - The address clients can connect to when on the local network (for example, 192.168.0.2)
        rsyncPortHome     - The port clients connect to when on the local network (eg, 22)
        rsyncUser         - The Synology user to backup as (eg, root)
        rsyncRootPath     - The root path to back up to (eg, /volume1/backup)
        vcsUpdateCmd      - If set, the version control system command to use prior to backup up (eg, svn up)

3.  The version control update command (%vcsUpdateCmd%) can be set to run a version control update on your files prior
    to backing up.  This can be useful if you have a VCS repository that clients can connect to.
    It allows you to make remote changes to the backup scripts, and have the clients get the updated scripts
    without you having to log into them.  The scripts are updated each time start-backup.cmd is run.

    For example, you could use this command to update from a svn repository:

        vcsUpdateCmd,svn up

    If you are using a VCS system, you should ensure you have the proper command-line .exes and .dlls in the client/
    directory.  I've used Collab.net's svn.exe and lib*.dll files from their distribution (http://www.collab.net/downloads/subversion/).

    During client setup, you simply need to log into the machine, checkout the repository, and setup a scheduled task
    to do the backups (see below).  Each time a backup is run, the client will update its backup scripts first.

The client package is now setup!  If you're using %vcsUpdateCmd%, you can check the client/ directory into your remote repository.

Client Setup
------------
For each client you want to backup, you will need to do the following:

1.  Generate a private/public key pair for the computer.  You can do this by running ssh-keygen.exe, or have
    generate-client-keys.cmd do it for you:

        generate-client-keys.cmd
    or

        generate-client-keys.cmd [computername]

    If you run ssh-keygen.exe on your own, you should name the files rsync-keys-[computername]:

        ssh-keygen.exe -t dsa -f rsync-keys-[computername]

    If you run ssh-keygen.exe on your own, do not specify a password, or clients will need to enter it every time
    they backup.

2.  Grab the public key out of rsync-keys-[computername].pub, and put it into your Synology backup
    user's .ssh/authorized_keys:

        vi ~/.ssh/authorized_keys

    You will want to prefix the authorized key with your validation command.  It should look something like this

        command="[validate-rsync.sh location] [backup volume root]" [contents of rsync-keys-x.pub]

    For example:

        command="/root/.ssh/validate-rsync.sh /volume1/backup/MYCOMPUTER" ssh-dss AAAdsadasds...

    This ensures that the public/private key is only used for rsync (and can't be used as a shell login), and
    that the rsync starts at the specified root path and no higher (so it can't destroy the rest of the filesystem).

3.  Copy backup-TEMPLATE.cmd to backup-[computername].cmd

4.  Edit the backup-[computername].cmd file to ensure %rsyncPath% is correct.

    The following DOS environment variable is available to you, which is set in config.csv:

        %rsyncRootPath% - Remote root rsync path

    You should set rsyncPath to the root remote rsync path you want to use.  For example:

        set rsyncPath=%rsyncRootPath%/%COMPUTERNAME%

    or

        set rsyncPath=%rsyncRootPath%/bob/%COMPUTERNAME%

    %rsyncRootPath% is set in config.csv to your Synology backup volume (eg, /volume1/backup), so %rsyncPath% would evaluate to
    this if your current computer's name is MYCOMPUTER:

        /volume1/backup/MYCOMPUTER

    You can see this is the same path that you put in the authorized_keys file.

5.  Edit the backup-[computername].cmd file to run the appropriate rsync commands.

    The following DOS environment variables are available to you, which are set in start-backup.cmd:

        %rsyncStandardOpts% - Standard rsync command-line options
        %rsyncConnectionString% - Rsync connection string

    For example:

        set cmdArgs=rsync %rsyncStandardOpts% "/cygdrive/c/users/bob/documents/" %rsyncConnectionString%:%rsyncPath%/documents
        echo Starting %cmdArgs%
        call %cmdArgs%

6.  Copy the client/ directories to the target computer, say C:\backup.

    If you are using %vcsUpdateCmd%, you can checkout the client directory so you can push remote updates (see above).

7.  Setup a scheduled task (via Windows Task Scheduler) to run start-backup.cmd as often as you wish.

8.  Create the computer's backup directory on your Synology NAS:

        mkdir /volume1/backup/MYCOMPUTER

The client is now setup!

Version History
---------------
v1.0 - 2012-01-04: Initial release