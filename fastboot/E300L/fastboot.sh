#!/bin/bash

#
#    This file is auto create by scripts
#    For download all img by fastboot
#    2018/01/18
#

# set path
if [ -z "`which fastboot`" ] && [ -e "fastboot" ];then
    for i in `echo $PATH | sed -e 's/:/ /g'`;do
        cp -rf fastboot $i/fastboot > /dev/null
    done
    export PATH=`pwd`:$PATH
fi

# check fastboot tool
if [ -z "`which fastboot`" ];then
    echo -e "Error: No fastboot tool found !!!"
    exit 1
fi

fastboot_type=down_img

command_array=($1 $2 $3 $4 $5)

for command in ${command_array[*]}; do
	case $command in
	8917)
        down_platform="8917"
	continue
	;;
	8937)
        down_platform="8937"
	continue
	;;
	esac
	
	if [ x$command == x"wipe" ] ;then
        fastboot_type=wipe
	else
        fastboot_type=down_img
	fi	
done

# begin download
if [ x$fastboot_type == x"down_img" ] ;then
fastboot oem enable-unlock-once

if [ x$down_platform == x"8917" ] ;then

fastboot flash dsp 8917_adspso.bin
fastboot flash cmnlib 8917_cmnlib_30.mbn
fastboot flash cmnlibbak 8917_cmnlib_30.mbn
fastboot flash cmnlib64 8917_cmnlib64_30.mbn
fastboot flash cmnlib64bak 8917_cmnlib64_30.mbn
fastboot flash devcfg 8917_devcfg.mbn
fastboot flash devcfgbak 8917_devcfg.mbn
fastboot flash apdp 8917_dp_AP_signed.mbn
fastboot flash msadp 8917_dp_MSA_signed.mbn
fastboot flash aboot 8917_emmc_appsboot.mbn
fastboot flash abootbak 8917_emmc_appsboot.mbn
fastboot flash BackupGPT 8917_gpt_backup0.bin
fastboot flash PrimaryGPT 8917_gpt_main0.bin
fastboot flash keymaster 8917_keymaster64.mbn
fastboot flash keymasterbak 8917_keymaster64.mbn
fastboot flash modem 8917_NON-HLOS.bin
fastboot flash rpm 8917_rpm.mbn
fastboot flash rpmbak 8917_rpm.mbn
fastboot flash sbl1 8917_sbl1.mbn
fastboot flash sbl1bak 8917_sbl1.mbn
fastboot flash sec 8917_sec.dat
fastboot flash tz 8917_tz.mbn
fastboot flash tzbak 8917_tz.mbn
fastboot flash APD APD.img
fastboot flash asusfw asusfw.img
fastboot flash boot boot.img
fastboot flash cache cache.img
#fastboot flash fsg fs_image.tar.gz.mbn.8917.img
fastboot flash logo logo.bin
fastboot flash mdtp mdtp.img
fastboot flash recovery recovery.img
fastboot flash splash splash.img
fastboot flash system system.img
fastboot flash userdata userdata.img
fastboot flash vendor vendor.img
fastboot flash xrom xrom.img



elif [ x$down_platform == x"8937" ] ;then


fastboot flash dsp 8937_adspso.bin
fastboot flash cmnlib 8937_cmnlib_30.mbn
fastboot flash cmnlibbak 8937_cmnlib_30.mbn
fastboot flash cmnlib64 8937_cmnlib64_30.mbn
fastboot flash cmnlib64bak 8937_cmnlib64_30.mbn
fastboot flash devcfg 8937_devcfg.mbn
fastboot flash devcfgbak 8937_devcfg.mbn
fastboot flash apdp 8937_dp_AP_signed.mbn
fastboot flash msadp 8937_dp_MSA_signed.mbn
fastboot flash aboot 8937_emmc_appsboot.mbn
fastboot flash abootbak 8937_emmc_appsboot.mbn
fastboot flash BackupGPT 8937_gpt_backup0.bin
fastboot flash PrimaryGPT 8937_gpt_main0.bin
fastboot flash keymaster 8937_keymaster64.mbn
fastboot flash keymasterbak 8937_keymaster64.mbn
fastboot flash modem 8937_NON-HLOS.bin
fastboot flash rpm 8937_rpm.mbn
fastboot flash rpmbak 8937_rpm.mbn
fastboot flash sbl1 8937_sbl1.mbn
fastboot flash sbl1bak 8937_sbl1.mbn
fastboot flash sec 8937_sec.dat
fastboot flash tz 8937_tz.mbn
fastboot flash tzbak 8937_tz.mbn
fastboot flash APD APD.img
fastboot flash asusfw asusfw.img
fastboot flash boot boot.img
fastboot flash cache cache.img
#fastboot flash fsg fs_image.tar.gz.mbn.8937.img
fastboot flash logo logo.bin
fastboot flash mdtp mdtp.img
fastboot flash recovery recovery.img
fastboot flash splash splash.img
fastboot flash system system.img
fastboot flash userdata userdata.img
fastboot flash vendor vendor.img
fastboot flash xrom xrom.img

fi

#fastboot oem reboot-recovery-wipe
fastboot reboot

# erase boot,force to reboot to bootloader
#fastboot erase boot
elif [ x$fastboot_type == x"wipe" ] ;then
    fastboot oem reboot-recovery-wipe
fi
