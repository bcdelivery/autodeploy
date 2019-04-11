#! /bin/sh
#######################
# GRIDUSER: grid用户
# volumenum: 磁盘数量
#######################
# TODO: grid用户已经写死，后续应该从自动化部署的环境变量中取得grid用户。当前的运维方案不支持从部署方案中获取参数

echo "使用udev配置asm磁盘路径和权限"
volumestr="${outputs.multi.asm_primary.volumeCode}"
volumestr=${volumestr#[}
volumestr=${volumestr%]}
volumearr=(${volumestr//,/ })

for volume in ${volumearr[@]}; do
  #获取磁盘volume对应的序列号，后8位位序列号
  serial=${volume:4}
  #kvm平台序列号为大写，vmware平台序列号为小写，所以两个都写，不会同时起作用
  lserial=$(echo $serial | tr '[A-Z]' '[a-z]')
  cat <<EOF >>/etc/udev/rules.d/99-oracle-asmdevices.rules
    SUBSYSTEM=="block",ENV{ID_SERIAL}=="?*${serial}",NAME="asm-${volume}", OWNER="grid",GROUP="asmadmin", MODE="0660"
    SUBSYSTEM=="block",ENV{ID_SERIAL}=="?*${lserial}",NAME="asm-${volume}", OWNER="grid",GROUP="asmadmin", MODE="0660"
EOF

done


devices=$(printf ",/dev/asm-%s" "${volumearr[@]}")
asmstr=$(printf "<add><dsk string=\"/dev/asm-%s\"/></add>" "${volumearr[@]}")
devices=${devices:1}
export devices 
export asmstr
# 重新加载udev规则，触发生成asm磁盘盘符
udevadm control --reload-rules && udevadm trigger

echo "查看变更前磁盘"
su -c "asmcmd lsdsk -p -G DATA"  - ${GRIDUSER}

# 生成asm磁盘修改脚本
cat <<EOF >/tmp/grid_asm_extend.xml
<chdg name="data" power="3">
$asmstr
</chdg>
EOF

chmod +r /tmp/grid_asm_extend.xml
su -c "asmcmd chdg /tmp/grid_asm_extend.xml" - ${GRIDUSER}

echo "查看变更后磁盘"
su -c "asmcmd lsdsk -p -G DATA"  - ${GRIDUSER}