#! /bin/sh
#######################
# VOLUMEID:存储卷volume id，大小写无关
# FSTYPE：格式化磁盘文件系统类型，支持ext3、ext4、btrfs
# MOUNTPOINT: 挂载点
# NEEDREBOOT: 是否需要重启
#######################
if [ -z "${VOLUMEID}" ] || [ -z "${FSTYPE}" ] || [ -z "${MOUNTPOINT}" ] ;then 
  echo "请初始化参数VOLUMEID，FSTYPE，MOUNTPOINT"
  exit 1
fi

volume=""

function loadVolume(){
        # VOLUMEID传递过来的格式为大写VOL-ABCDEFGH
        volumeid="${VOLUMEID}"
        volumeid=${volumeid:4}
        for dlink in `ls /dev/disk/by-id|grep -i "${volumeid}$"` 
        do 
          # dlink此时应该为virtio-vol-0A543A93或者scsi-******0a543a93，读取对应的设备文件blkpath应该为/dev/vdb或者/dev/sdb
          blkpath=`readlink -f "/dev/disk/by-id/${dlink}"`
          if [[ -e ${blkpath} ]] ; then 
            break
          fi 
        done 
        # volume正确输出应为vdb或者sdb
        volume=${blkpath##*/}
}

for i in $( seq 10);do
    loadVolume;
    echo $volume
    if [ "$volume" == "" ];then
		echo can not load volume
		sleep 5
		continue
	else
		break
	fi
done

if [ "$volume" == "" ] ;then
	if [ -f attach.error ]; then
		echo there is no avalible volume ,please check your vm.
		echo now:`date +%Y-%m-%d" "%k:%M:%S`
		exit 1
  else
		echo "找不到存储卷${VOLUMEID} ，机器将重启来重新加载磁盘。"
		echo "找不到存储卷${VOLUMEID} ，机器将重启来重新加载磁盘。" > attach.error
    if [ "${NEEDREBOOT}" -ne "true" ] ;then 
      exit 1
    fi
		reboot
		sleep 10
	fi
else
if !(test -d ${MOUNTPOINT});then
	 mkdir -p ${MOUNTPOINT}
	echo "创建路径${MOUNTPOINT}"
else
	echo "路径${MOUNTPOINT} 已存在"
fi
	 mkfs  -t ${FSTYPE} /dev/$volume
	 mount /dev/$volume ${MOUNTPOINT}
     echo "UUID="`blkid -o value -s UUID /dev/$volume` " ${MOUNTPOINT} ${FSTYPE}    defaults        0       0">> /etc/fstab
	echo attach volume success $volume
fi


