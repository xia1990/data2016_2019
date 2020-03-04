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

fastboot oem enable-unlock-once
fastboot flash dsp adspso.bin
fastboot flash APD APD.img
fastboot flash asusfw asusfw.img
fastboot flash boot boot.img
fastboot flash cache cache.img
#::checklist.md5
fastboot flash cmnlib cmnlib_30.mbn
fastboot flash cmnlibbak cmnlib_30.mbn
fastboot flash cmnlib64 cmnlib64_30.mbn
fastboot flash cmnlib64bak cmnlib64_30.mbn
#::create_fashboot_bat.sh
fastboot flash devcfg devcfg.mbn
fastboot flash devcfgbak devcfg.mbn
fastboot flash apdp dp_AP_signed.mbn
fastboot flash msadp dp_MSA_signed.mbn
#::dsp2.mbn
fastboot flash aboot emmc_appsboot.mbn
fastboot flash abootbak emmc_appsboot.mbn
#fastboot flash fsg fs_image.tar.gz.mbn.8917.img
fastboot flash BackupGPT gpt_backup0.bin
fastboot flash PrimaryGPT gpt_main0.bin
fastboot flash keymaster keymaster64.mbn
fastboot flash keymasterbak keymaster64.mbn
fastboot flash logo logo.bin
fastboot flash mdtp mdtp.img
fastboot flash modem NON-HLOS.bin
#::patch0.xml
#::persist.img
#::prog_emmc_firehose_8917_ddr.mbn
#::rawprogram0.xml
fastboot flash recovery recovery.img
fastboot flash rpm rpm.mbn
fastboot flash rpmbak rpm.mbn
fastboot flash sbl1 sbl1.mbn
fastboot flash sbl1bak sbl1.mbn
fastboot flash sec sec.dat
fastboot flash splash splash.img
fastboot flash system system.img
fastboot flash tz tz.mbn
fastboot flash tzbak tz.mbn
fastboot flash userdata userdata.img
fastboot flash vendor vendor.img
fastboot flash xrom xrom.img
fastboot reboot
