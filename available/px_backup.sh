#---------------------------------------------
#!/bin/sh
#---------------------------------------------
CRED_ID=676f8a3c-4706-44e4-947a-3c1cfe67698c
REMAIN_DAYS=15

BASE_DIR=/data
ALL_VOLUMES=$(pxctl v l|tee $BASE_DIR/px_all_pv_$(date +%Y%m%d)|awk 'NR>1{print $1}')
BACKUP_LOG=$BASE_DIR/px_volume_backup_$(date +%Y%m%d).log
CLEAR_LOG=$BASE_DIR/px_snap_clear_$(date +%Y%m%d).log
TMP_FILE=$BASE_DIR/px_backup_tmp
ALL_SNAPS_FILE=$BASE_DIR/px_all_snap_$(date +%Y%m%d)

# log & gernerate tmp file
pxctl cloudsnap list|tee $ALL_SNAPS_FILE|awk 'NR>1 {print $2,$3,$5$6$7}' > $TMP_FILE

# backup px volume
_backup_px_volume(){
for volume in $ALL_VOLUMES
do
	pxctl cloudsnap backup $volume --cred-id $CRED_ID
        if [ $? -eq 0 ];then
		echo [ $(date +"%Y%m%d %H%M%S") ] backup $volume ok| tee -a $BACKUP_LOG
	else
		echo [ $(date +"%Y%m%d %H%M%S") ] backup $volume error| tee -a $BACKUP_LOG
	fi
done
}

# clear older snap
_clear_older_snap(){
while read snap
do
        created_time=$(date +%Y%m%d --date "$(echo $snap|awk '{print $3}')")
        source_volume_id=$(echo $snap|awk '{print $1}')
        cloud_snap_id=$(echo $snap|awk '{print $2}')
        if [ $((($(date +%s --date $created_time)-$(date +%s --date $(date +%Y%m%d --date "$(($REMAIN_DAYS+1)) days ago")))/3600/24)) -eq 0 ];then
                pxctl cloudsnap delete --snap $cloud_snap_id --cred-id $CRED_ID
                if [ $? -eq 0 ];then
			echo [ $(date +"%Y%m%d %H%M%S") ] delete snap $cloud_snap_id ok| tee -a $CLEAR_LOG
		fi
        fi
done < $TMP_FILE
}

# clear log
_rotate_log(){
rm -rf $BASE_DIR/*$(date +%Y%m%d --date "$(($REMAIN_DAYS+1)) days ago").log
rm -rf $TMP_FILE
}



#---------------------------------------------
_backup_px_volume
_clear_older_snap

_rotate_log
#---------------------------------------------
