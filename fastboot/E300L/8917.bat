fastboot oem enable-unlock-once
fastboot flash dsp 8917_adspso.bin
fastboot flash cmnlib 8917_cmnlib_30.mbn
fastboot flash cmnlibbak 8917_cmnlib_30.mbn
fastboot flash cmnlib64 8917_cmnlib64_30.mbn
fastboot flash cmnlib64bak 8917_cmnlib64_30.mbn
fastboot flash devcfg 8917_devcfg.mbn
fastboot flash devcfgbak 8917_devcfg.mbn
fastboot flash apdp 8917_dp_AP_signed.mbn
fastboot flash msadp 8917_dp_MSA_signed.mbn
::8917_dsp2.mbn
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
::create_fashboot_bat(5).sh
::fastboot flash fsg fs_image.tar.gz.mbn.8917.img
fastboot flash logo logo.bin
fastboot flash mdtp mdtp.img
::patch0_8917.xml
::persist.img
::prog_emmc_firehose_8917_ddr.mbn
::rawprogram0_8917.xml
fastboot flash recovery recovery.img
fastboot flash splash splash.img
fastboot flash system system.img
fastboot flash userdata userdata.img
fastboot flash vendor vendor.img
fastboot flash xrom xrom.img
fastboot reboot
