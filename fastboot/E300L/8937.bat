fastboot oem enable-unlock-once
fastboot flash dsp 8937_adspso.bin
fastboot flash cmnlib 8937_cmnlib_30.mbn
fastboot flash cmnlibbak 8937_cmnlib_30.mbn
fastboot flash cmnlib64 8937_cmnlib64_30.mbn
fastboot flash cmnlib64bak 8937_cmnlib64_30.mbn
fastboot flash devcfg 8937_devcfg.mbn
fastboot flash devcfgbak 8937_devcfg.mbn
fastboot flash apdp 8937_dp_AP_signed.mbn
fastboot flash msadp 8937_dp_MSA_signed.mbn
::8937_dsp2.mbn
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
::create_fashboot_bat(5).sh
::fastboot flash fsg fs_image.tar.gz.mbn.8937.img
fastboot flash logo logo.bin
fastboot flash mdtp mdtp.img
::patch0_8937.xml
::persist.img
::prog_emmc_firehose_8937_ddr.mbn
::rawprogram0_8937.xml
fastboot flash recovery recovery.img
fastboot flash splash splash.img
fastboot flash system system.img
fastboot flash userdata userdata.img
fastboot flash vendor vendor.img
fastboot flash xrom xrom.img
fastboot reboot
