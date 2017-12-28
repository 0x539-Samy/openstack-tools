#! /bin/bash

#################################################################
#Author :  @BELARBI Samy  15/11/2017				#
##TODO: colors, manage errors, add mount in fstab, functions	#
#################################################################

#Colors
OK='\e[0;32m' # Green
FAIL='\e[0;31m' # Red
RESET='\e[0m' # Text Reset

#check if user id is 0 to execute the script
if [ "$(id --user)" != "0" ];then
    echo -e "\n$FAIL[WARNING]$RESET please use sudo $0 or connect with root to execute the script.\n"
    exit
fi

#Menu
clear
echo -e " ──────────────────────────────"
echo -e "| OPENSTACK VOLUME ATTACH V1.1|" 
echo -e " ──────────────────────────────\n"

#Function scan isci bus to detect new disks
ScanBus() {
    echo "- - -" > /sys/class/scsi_host/host0/scan 	
    echo "- - -" > /sys/class/scsi_host/host1/scan 
    echo "- - -" > /sys/class/scsi_host/host2/scan
}

#list disks
echo -e "\n== Disks List == "
ScanBus && lsblk --nodeps -o NAME,FSTYPE,SIZE

### user input asking name of disk & mount location - interractive ###
echo -e "\n== Disk Add == "
read -p "└─ 1.device name : " device
read -p "└─ 2.Mount point : " MountPoint

#create folder in mount location if not exist
if [ ! -d "$MountPoint" ];then
mkdir $MountPoint &> /dev/null
fi

#user input to confirm actions
echo -e "\nDo you want to mount device  /dev/$device on location $MountPoint"
read -p "└─ 3.please write 'start' to confirm   >> " ValidActions
echo -e "\n"

StartJob() {
    #send fdisk args => new partition ("n"),primary ("p"),first partition ("1"),write change ("w")
    echo -e "o\nn\np\n1\n\n\nw" | fdisk /dev/$device &> /dev/null
    
    #display list of partitions
    echo -e "== list of partitions in disk $device : "
    if [ -z "$(lsblk | grep -oh $device[1-9])" ];then
    	echo -e "\n$FAIL[Critical]$RESET the disk $device not exist... exiting program\n"
	exit
   else
	lsblk | grep -oh $device[1-9]
   fi

    #user input of name of the partition created & displayed by lsblk
    read -p "└─ 4.partition to mount : " PartChoice

    #check if  partition realy exist in system
    CheckPart=$(lsblk -r |awk '{print $1}'|grep --color=yes $PartChoice)
    if [ -z "$CheckPart" ];then
    	echo "$0: Partition $PartChoice not found"
        exit 0
    fi
    
    #format the partition in ext4 filesystem & mount  in read/write
    mkfs.ext4 /dev/$PartChoice &> /dev/null
    mount -o rw /dev/$PartChoice $MountPoint &> /dev/null
    
    ##TODO ==>add mount of partition in boot on fstab file   
 
    #confirm job is done
    echo -e "\n$OK[Success]$RESET Partition $PartChoice mounted in $MountPoint successfully\n\n"
    }

#check user input choice if yes do the job, if no exit  else  error
if [ $ValidActions == "start" ];then
    StartJob
else
    echo -e "\n$FAIL[Critical]$RESET Unknow error, exiting ... " &  exit
fi
