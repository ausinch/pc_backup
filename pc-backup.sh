#!/bin/bash
#  Backup PCs in the PC-list.txt
# :r!date Fri  2 Apr 11:43:08 CEST 2021

#  ---  Functions  ---
convertsecs() {
    ((h=${1}/3600))
    ((m=(${1}%3600)/60))
    ((s=${1}%60))
    printf "%02d:%02d:%02d\n" $h $m $s
}

#  ---  End Function  ---

#  ---  Varables  ---
version=".06"
backup_dir="/home/BACKUP/PCs/"
excludes="/usr/local/backup/excludelist.txt"
log_file="/usr/local/backup/PC_backups.log"
done_all=0
NL=$'\n'
get_from="/usr/local/backup/PC_list.txt"
missed_PCs="/usr/local/backup/missed.txt"
status_dir="/usr/local/backup/status/"
missed_count=0

#  Look for a missing PC file $missed_PCs, if created today then change $get_from to $missed_PCs
#       else remove $missed_PCs
ls -ltr $missed_PCs| grep "$(date '+%b %e')" 2>&1 # 0 result if it has todays date.
if [ $? == 0 ]; then
    #  now see if it has a COMPLETE status, if so terminate
    fgrep COMPLETE $missed_PCs 2>&1
    if [ $? == 0 ]; then
        echo "I see COMPLETE status in $missed_PCs - Terminating"
        exit
    fi
    #  missed_PCs was created today so that will be our get_from list
    get_from=$missed_PCs
    echo "--------------------------------------------" | tee -a $log_file
    echo "Continue with missing PCs " | tee -a $log_file
    cat $get_from | tee -a $log_file
else
    #  old missed_PCs so this is the first time this script has run.
    rm $missed_PCs
    echo "============================================" | tee -a $log_file
    echo "First run for today"
    fi

#  Get ready to back up
missing_list="# $(date)"
echo "$(date)" | tee -a $log_file
t_start_secs="$(date +%s)"
#  Loop PC_list - get the PC name and backup dirs
while IFS= read -r line
do
    # continue if not remed with #
    if [[ $line != \#* ]]; then
        echo "--------------------------------------------" | tee -a $log_file
        # is the PC online
        p_start_secs="$(date +%s)"
        the_pc="$(echo $line|awk '{print $1}')"
        # is the PC online
        ping -c 1 $the_pc > /dev/null 2>&1
        if [ $? == 0 ]; then
            dirs="$(echo $line|cut -d' ' -f2-)"
            the_user="$(echo $dirs|awk '{print $1}')"
            dirs="$(echo $dirs|cut -d' ' -f2-)"
            echo "Backing up $the_pc - $(date)" | tee -a $log_file
            echo "Directory: "$dirs | tee -a $log_file
            for dir in $dirs; do 
                to_dir="$backup_dir$the_pc$dir"
                [ ! -d "$to_dir" ] && mkdir -p $to_dir
                if [ $the_pc == "localhost" ]; then
                    #  this is a local backup so no user id required
                    echo -n "Backing up $the_pc:$dir $to_dir  " | tee -a $log_file
                    #rsync -rltuv --delete --exclude-from=$excludes $dir $to_dir
                    rsync -rltuv --delete-before --exclude-from=$excludes $dir $to_dir
                else
                    #echo "Command: rsync -av --delete --exclude-from=$excludes $the_user@$the_pc:$dir $to_dir"
                    echo -n "Backing up $the_pc:$dir $to_dir  " | tee -a $log_file
                    #rsync -rltuv --delete --exclude-from=$excludes $the_user@$the_pc:$dir $to_dir
                    rsync -rltuv --delete-before --exclude-from=$excludes $the_user@$the_pc:$dir $to_dir
                fi
                # state error code
                rsync_error=$?
                this_status="Fail. Rsync error: $rsync_error"
                to_log="rsynced errored: $rsync_error"
                if [ $rsync_error -eq 23 ]; then 
                    this_status="Success"
                fi
                if [ $rsync_error -eq 0 ]; then 
                    this_status="Success"
                fi
                echo "$this_status" | tee -a $log_file
                # write the backup status file for Nagios check_backup
                echo "$this_status $(date)" > $status_dir$the_pc
                sleep 1
            done
            p_end_secs="$(date +%s)"
            p_time="$[$p_end_secs-p_start_secs]"
            echo "Time taken: $(convertsecs $p_time)" | tee -a $log_file
        else
            echo "$the_pc is not on" | tee -a $log_file
            #echo "$the_pc" >> $missed_PCs
            $(( missed_count++ ))
            missing_list="$missing_list${NL}$line"

        fi
    fi
done < $get_from
echo "............................................" | tee -a $log_file
t_end_secs="$(date +%s)"
t_time="$[$t_end_secs-t_start_secs]"
echo "Total backup time taken: $(convertsecs $t_time)" | tee -a $log_file
if [ $missed_count -eq 0 ];then
    missing_list="# $(date)${NL}#  BACKUP COMPLETE"
    echo "BACKUP COMPLETE $(date)"  | tee -a $log_file
fi
echo "$missing_list" > $missed_PCs
###  Versions  ###
# 20210124  0.04    Added missed_PCs.txt so backups will backup only what was missed previously today
# 20210207  0.05    Moved everything from /usr/local/pc-backup/ to /usr/local/backup/ and some code tidying 
# 20210402  0.06    Add status in /usr/local/backup/status/ for Nagios
