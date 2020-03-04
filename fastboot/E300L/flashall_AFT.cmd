@ECHO OFF

SET dataerase=0

IF %1 EQU 1 ( SET dataerase=1 )
IF NOT [%2] EQU [] ( SET para=-s )


fastboot getvar platform 2> SOC
for /f "tokens=2 delims= " %%a in ('findstr platform SOC') do set SOC=%%a
echo %SOC%&&del /F /Q /S SOC
REM pause


ECHO.
ECHO ###########################################
ECHO ###########  FLASHING FIRMWARE  ###########
ECHO ###########################################
fastboot oem enable-unlock-once %para% %2
IF NOT %ERRORLEVEL% == 0  (
  ECHO "oem enable-unlock-once FAILED, IGNORE!"
  REM PAUSE
  GOTO FAIL
)

fastboot erase config
IF NOT %ERRORLEVEL% == 0  (
  ECHO "UNLOCK FPP FAILED, IGNORE!"
  REM PAUSE
  GOTO FAIL
)

fastboot flash dsp %SOC%_adspso.bin %para% %2
IF NOT %ERRORLEVEL% == 0  (
  ECHO "flash dsp %SOC%_adspso FAILED, IGNORE!"
  REM PAUSE
  GOTO FAIL
)

fastboot flash cmnlib %SOC%_cmnlib_30.mbn %para% %2
IF NOT %ERRORLEVEL% == 0  (
  ECHO "cmnlib %SOC%_cmnlib FAILED, IGNORE!"
  REM PAUSE
  GOTO FAIL
)

fastboot flash cmnlibbak %SOC%_cmnlib_30.mbn %para% %2
IF NOT %ERRORLEVEL% == 0  (
  ECHO "cmnlibbak %SOC%_cmnlib FAILED, IGNORE!"
  REM PAUSE
  GOTO FAIL
)

fastboot flash cmnlib64 %SOC%_cmnlib64_30.mbn %para% %2
IF NOT %ERRORLEVEL% == 0  (
  ECHO "cmnlib64 %SOC%_cmnlib64 FAILED, IGNORE!"
  REM PAUSE
  GOTO FAIL
)

fastboot flash cmnlib64bak %SOC%_cmnlib64_30.mbn %para% %2
IF NOT %ERRORLEVEL% == 0  (
  ECHO "cmnlib64bak %SOC%_cmnlib64 FAILED, IGNORE!"
  REM PAUSE
  GOTO FAIL
)

fastboot flash devcfg %SOC%_devcfg.mbn %para% %2
IF NOT %ERRORLEVEL% == 0  (
  ECHO "devcfg %SOC%_devcfg FAILED, IGNORE!"
  REM PAUSE
  GOTO FAIL
)

fastboot flash devcfgbak %SOC%_devcfg.mbn %para% %2
IF NOT %ERRORLEVEL% == 0  (
  ECHO "devcfgbak %SOC%_devcfg FAILED, IGNORE!"
  REM PAUSE
  GOTO FAIL
)

fastboot flash apdp %SOC%_dp_AP_signed.mbn %para% %2
IF NOT %ERRORLEVEL% == 0  (
  ECHO "apdp %SOC%_dp_AP_signed FAILED, IGNORE!"
  REM PAUSE
  GOTO FAIL
)

fastboot flash msadp %SOC%_dp_MSA_signed.mbn %para% %2
IF NOT %ERRORLEVEL% == 0  (
  ECHO "msadp %SOC%_dp_MSA_signed FAILED, IGNORE!"
  REM PAUSE
  GOTO FAIL
)

::%SOC%_dsp2.mbn
fastboot flash aboot %SOC%_emmc_appsboot.mbn %para% %2
IF NOT %ERRORLEVEL% == 0  (
  ECHO "aboot %SOC%_emmc_appsboot FAILED, IGNORE!"
  REM PAUSE
  GOTO FAIL
)

fastboot flash abootbak %SOC%_emmc_appsboot.mbn %para% %2
IF NOT %ERRORLEVEL% == 0  (
  ECHO "abootbak %SOC%_emmc_appsboot FAILED, IGNORE!"
  REM PAUSE
  GOTO FAIL
)

:: lihaiyan@wind-mobi.com 20180308 for delete gpt +++
::fastboot flash BackupGPT %SOC%_gpt_backup0.bin %para% %2
::IF NOT %ERRORLEVEL% == 0  (
::  ECHO "BackupGPT %SOC%_gpt_backup0 FAILED, IGNORE!"
::  REM PAUSE
::  REM GOTO END
::)

::fastboot flash PrimaryGPT %SOC%_gpt_main0.bin %para% %2
::IF NOT %ERRORLEVEL% == 0  (
::  ECHO "flash PrimaryGPT %SOC%_gpt_main0 FAILED, IGNORE!"
::  REM PAUSE
::  REM GOTO END
::)
:: lihaiyan@wind-mobi.com 20180308 for delete gpt ---

fastboot flash keymaster %SOC%_keymaster64.mbn %para% %2
IF NOT %ERRORLEVEL% == 0  (
  ECHO "keymaster %SOC%_keymaster64 FAILED, IGNORE!"
  REM PAUSE
  GOTO FAIL
)

fastboot flash keymasterbak %SOC%_keymaster64.mbn %para% %2
IF NOT %ERRORLEVEL% == 0  (
  ECHO "keymasterbak %SOC%_keymaster64 FAILED, IGNORE!"
  REM PAUSE
  GOTO FAIL
)

fastboot flash modem %SOC%_NON-HLOS.bin %para% %2
IF NOT %ERRORLEVEL% == 0  (
  ECHO "modem %SOC%_NON-HLOS FAILED, IGNORE!"
  REM PAUSE
  GOTO FAIL
)

fastboot flash rpm %SOC%_rpm.mbn %para% %2
IF NOT %ERRORLEVEL% == 0  (
  ECHO "rpm %SOC%_rpm FAILED, IGNORE!"
  REM PAUSE
  GOTO FAIL
)

fastboot flash rpmbak %SOC%_rpm.mbn %para% %2
IF NOT %ERRORLEVEL% == 0  (
  ECHO "rpmbak %SOC%_rpm FAILED, IGNORE!"
  REM PAUSE
  GOTO FAIL
)

fastboot flash sbl1 %SOC%_sbl1.mbn %para% %2
IF NOT %ERRORLEVEL% == 0  (
  ECHO "sbl1 %SOC%_sbl1 FAILED, IGNORE!"
  REM PAUSE
  GOTO FAIL
)

fastboot flash sbl1bak %SOC%_sbl1.mbn %para% %2
IF NOT %ERRORLEVEL% == 0  (
  ECHO "sbl1bak %SOC%_sbl1 FAILED, IGNORE!"
  REM PAUSE
  GOTO FAIL
)

fastboot flash sec %SOC%_sec.dat %para% %2
IF NOT %ERRORLEVEL% == 0  (
  ECHO "sec %SOC%_sec FAILED, IGNORE!"
  REM PAUSE
  GOTO FAIL
)

fastboot flash tz %SOC%_tz.mbn %para% %2
IF NOT %ERRORLEVEL% == 0  (
  ECHO "tz %SOC%_tz FAILED, IGNORE!"
  REM PAUSE
  GOTO FAIL
)

fastboot flash tzbak %SOC%_tz.mbn %para% %2
IF NOT %ERRORLEVEL% == 0  (
  ECHO "tzbak %SOC%_tz FAILED, IGNORE!"
  REM PAUSE
  GOTO FAIL
)

fastboot flash APD APD.img %para% %2
IF NOT %ERRORLEVEL% == 0  (
  ECHO "APD APD FAILED, IGNORE!"
  REM PAUSE
  GOTO FAIL
)

fastboot flash asusfw asusfw.img %para% %2
IF NOT %ERRORLEVEL% == 0  (
  ECHO "asusfw asusfw FAILED, IGNORE!"
  REM PAUSE
  GOTO FAIL
)

fastboot flash boot boot.img %para% %2
IF NOT %ERRORLEVEL% == 0  (
  ECHO "boot boot FAILED, IGNORE!"
  REM PAUSE
  GOTO FAIL
)

fastboot flash cache cache.img %para% %2
IF NOT %ERRORLEVEL% == 0  (
  ECHO "cache cache FAILED, IGNORE!"
  REM PAUSE
  GOTO FAIL
)

::create_fashboot_bat(5).sh
::fastboot
::fastboot.exe
::fastboot.sh

fastboot flash logo logo.bin %para% %2
IF NOT %ERRORLEVEL% == 0  (
  ECHO "logo logo FAILED, IGNORE!"
  REM PAUSE
  GOTO FAIL
)

fastboot flash mdtp mdtp.img %para% %2
IF NOT %ERRORLEVEL% == 0  (
  ECHO "mdtp mdtp FAILED, IGNORE!"
  REM PAUSE
  GOTO FAIL
)

::patch0_%SOC%.xml
::fastboot flash persist persist.img %para% %2
::IF NOT %ERRORLEVEL% == 0  (
::  ECHO "persist persist FAILED, IGNORE!"
::  REM PAUSE
::  GOTO FAIL
::)

::prog_emmc_firehose_%SOC%_ddr.mbn
::rawprogram0_%SOC%.xml
fastboot flash recovery recovery.img %para% %2
IF NOT %ERRORLEVEL% == 0  (
  ECHO "recovery recovery FAILED, IGNORE!"
  REM PAUSE
  GOTO FAIL
)

fastboot flash splash splash.img %para% %2
IF NOT %ERRORLEVEL% == 0  (
  ECHO "splash splash FAILED, IGNORE!"
  REM PAUSE
  GOTO FAIL
)

fastboot flash system system.img %para% %2
IF NOT %ERRORLEVEL% == 0  (
  ECHO "system system FAILED, IGNORE!"
  REM PAUSE
  GOTO FAIL
)

IF %dataerase% EQU 1 (
  fastboot flash userdata userdata.img %para% %2
  IF NOT %ERRORLEVEL% == 0  (
    ECHO "erase data FAILED, EXIT!"
    GOTO FAIL
  )
)

fastboot flash vendor vendor.img %para% %2
IF NOT %ERRORLEVEL% == 0  (
  ECHO "vendor vendor FAILED, IGNORE!"
  REM PAUSE
  GOTO FAIL
)

fastboot flash xrom xrom.img %para% %2
IF NOT %ERRORLEVEL% == 0  (
  ECHO "xrom xrom FAILED, IGNORE!"
  REM PAUSE
  GOTO FAIL
)


fastboot reboot %para% %2

ECHO DL_PASS
  GOTO END


:FAIL
  ECHO DL_FAIL
  GOTO END


:END
  ECHO DL_END
