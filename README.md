# pc_backup
Daily file sync of Linux machines to central server.

This script is called by crontab.\
On first run for the day the full list of machines (in **PC_list.txt**) is used, if a machine is not on (PC or laptop) during the initial run **missed.txt** list is created.\
This missed.txt is then used for backup runs throughout the day and is modified as machines come online and are backed up.\
This ensures machines are backed up once daily.\
This script is run during working hours 0800 - 2000, every 2 hours.  This can be changed to anything as required in crontab.

## Prerequisits
These files by default reside in /usr/local/backup\
The backup user id on the server of this script must have ssh keys created (`ssh-keygen`) and must transfer the public to the target machine with `ssh-copyid`\
E.g. `ssh-copyid chris@chris-pc`\
*Note:* The user name is critical, sue the appropriate name for the targe machine.
### Esential files
pc-backup.sh - the script\
PC_list.txt - target machines to backup

### Created files
missed.txt - the working target list during the day\
PC_backups.log - log of what is going on

## List of target machines
**PC_list.txt** contains the target machines and is in the following format:\
~~~
chris-pc chris /home/ /etc/
   ^       ^     ^     ^
   |       |     |     |
   |       |     |     |
PC_name User Directories . . . .
~~~
Any number directories can be targeted.\
*Note:* If multiple user /home/ directories need to be backed up you have to make multiple enties in the PC_list.txt file.

## Monitoring
A log is kept in /usr/local/backup/PC_backups.log\
`tail -f PC_backups.log` to keep an eye on the process.\
A result of each backup is written to /usr/local/backup/status/*machine_name*, make sure the backup user ID has access to this directory.\
The reason for this file is for Nagios reporting and alerts.  See the check_backup github project for Nagios integration.

