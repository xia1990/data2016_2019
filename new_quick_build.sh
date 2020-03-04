#!/bin/bash
# ./quick_build.sh P110 all n user
# ./quick_build.sh P110 all n eng
# ./quick_build.sh P110 n user
# ./quick_build.sh P110 n eng
# ./quick_build.sh P110 r user
# ./quick_build.sh P110 r eng
# ./quick_build.sh P110 amss
# ./quick_build.sh P110 otapackage user
# ./quick_build.sh P110 otapackage eng


ROOT_PATH=$(pwd)
BUILD_LOG_PATH="$ROOT_PATH/build-log"
COPYFILES="no"
CUSTOM_FILES_PATH="$ROOT_PATH/vendor/wind/custom_files/"
AMSS_PATH="$ROOT_PATH/amss"
CPUCORE=24
CUSTOMPATH="$ROOT_PATH/device/wind/"
BUILD_MODE="only_build_android"
ACTION=""
PRODUCT=""
function environment_clean(){
    #清理可能会干扰的环境变量
    local -r OLD_ENVIRONMENT_ARRAY=(
        NAMES
        PATHS
        )
    for old_environment in "${OLD_ENVIRONMENT_ARRAY[@]}"
    do
        unset $old_environment
    done
}


function args_parse(){
    #参数解析
    [ "$(pwd)" == "$ROOT_PATH"  ] && mkdir "$BUILD_LOG_PATH" > /dev/null 2>&1
    echo -e "$(date +"%F %T")" "\033[32m$0 $@\033[0m" | tee -a "$BUILD_LOG_PATH"/record.log
    for args in "$@"
    do
        case $args in
        P110)
            PRODUCT="$args"
            OUT_PATH="$ROOT_PATH"/out/target/product/"$PRODUCT"
            ;;
        user|eng|debug)
            VARIANT="$args"
            ;;
        all|amss|otapackage)
            BUILD_MODE="$args"
            RELEASE_PARAM="$args"
            ;;
        n|new|r|remake)
            ACTION="$args"
            if [ "$ACTION" == "new" ] || [ "$ACTION" == "n" ]
            then
                COPYFILES="yes"
            else
                COPYFILES="no"
            fi
            ;;
        *)
            echo "test"
            ;;
        esac
        echo "$args"
    done
    [ "$PRODUCT" == "" ] && echo "PRODUCT is null" && exit 1
    [ "$BUILD_MODE" == "otapackage" ] && [ "$ACTION" != "" ] && echo "编译otapackage的时候不需要new 或者 remake" && exit 1 
    [ "$BUILD_MODE" != "amss" ] && [ "$BUILD_MODE" != "otapackage" ] && [ "$PRODUCT" != "" ] &&  [ "$ACTION" == "" ] && echo "请明确指出是new编还是remake" && exit 1
    [ "$BUILD_MODE" != "amss" ] && [ "$VARIANT" == "" ] && echo "请明确指出是user编还是eng" && exit 1
    [ "$BUILD_MODE" == "amss" ] && [ "$ACTION" != "" ] && echo "编译otapackage的时候不需要new 或者 remake" && exit 1
}


function copy_custom_files(){
    if [ "$COPYFILES" == "yes" ]
    then
        if [ "-d" ""$ROOT_PATH"/vendor/qcom/proprietary/" ]
        then
            cd "$ROOT_PATH"/vendor/qcom/proprietary/
                git checkout . && git clean -df
            cd -
        else
            echo -e "\033[31m$ROOT_PATH/vendor/qcom/proprietary/: no such file or directory!!! \033[0m"
            sleep 5s
        fi
        cp -a "$CUSTOM_FILES_PATH"/* .
        [ "$?" != 0 ] && echo -e "\033[31mCopy custom file error!!! \033[0m" && exit 1
    fi
}


function build_pl(){
    echo "========== BOOT.BF.3.3.2 =========="
    echo "start build boot_image"
    if [ -d "$AMSS_PATH/BOOT.BF.3.3.2/boot_images/build/ms/" ]    
    then
        cd "$AMSS_PATH"/BOOT.BF.3.3.2/boot_images/build/ms/
            source ./setenv.sh
            ./build.sh TARGET_FAMILY=8953 --prod | tee "$BUILD_LOG_PATH"/boot_sdm632.log 2>&1
            [ "${PIPESTATUS[0]}" != "0" ] && echo -e "\033[31mbuild BOOT.BF.3.3.2 error\033[0m" && exit 1
        cd -
    else
        echo -e "\033[31m$AMSS_PATH/BOOT.BF.3.3.2/boot_images/build/ms/: no such file or directory!!! \033[0m"
        exit 1
    fi
}


function build_mpss(){
    echo "========== build MPSS.TA.3.0 =========="
    local -r modem_path="MPSS.TA.3.0"
    if [ -d "$AMSS_PATH/$modem_path/modem_proc/build/ms" ]
    then
        cd "$AMSS_PATH/$modem_path/modem_proc/build/ms"
            source setenv.sh
            ./build.sh 8953.gen.prod -k | tee "$BUILD_LOG_PATH"/mpss_sdm632.log
            [ "${PIPESTATUS[0]}" != "0" ] && echo -e "\033[31mbuild MPSS.TA.3.0 error\033[0m" && exit 1
        cd -
    else
        echo -e "\033[31m$AMSS_PATH/BOOT.BF.3.3.2/boot_images/build/ms/: no such file or directory!!! \033[0m"
        exit 1
    fi
}


function build_rpm(){
    echo "========== build RPM.BF.2.4 =========="
    if [ -d "$AMSS_PATH/RPM.BF.2.4/rpm_proc/build/"  ]
    then
        cd "$AMSS_PATH"/"RPM.BF.2.4/rpm_proc/build/"
            source ./setenv.sh
            ./build_632.sh | tee "$BUILD_LOG_PATH"/rpm_proc_sdm632.log
            [ "${PIPESTATUS[0]}" != "0" ] && echo -e "\033[31mbuild RPM.BF.2.4 error\033[0m" && exit 1
        cd -
    else
        echo -e "\033[31m$AMSS_PATH/RPM.BF.2.4/rpm_proc/build/: no such file or directory!!! \033[0m"
        exit 1
    fi
}


function build_tz(){
    echo "========== build TZ.BF.4.0.5 =========="
    if [ -d "$AMSS_PATH/TZ.BF.4.0.5/trustzone_images/build/ms/" ]
    then
	cd "$AMSS_PATH/TZ.BF.4.0.5/trustzone_images/build/ms/"
	    ./build.sh CHIPSET=sdm632 devcfg sampleapp -c
       	    ./build.sh CHIPSET=sdm632 devcfg sampleapp | tee "$BUILD_LOG_PATH"/tz_sdm632.log
        [ "${PIPESTATUS[0]}" != "0" ] && echo -e "\033[31mbuild TZ.BF.4.0.5 error\033[0m" && exit 1
	cd -
    else
        echo -e "\033[31m$AMSS_PATH/TZ.BF.4.0.5/trustzone_images/build/ms/: no such file or directory!!! \033[0m"
        exit 1
    fi
}


function build_adsp(){
    echo "========== ADSP.VT.3.0 =========="
    if [ -d "$AMSS_PATH/ADSP.VT.3.0/adsp_proc" ]
    then
	cd "$AMSS_PATH/ADSP.VT.3.0/adsp_proc"
	    source ./build/setenv.sh
            python ./build/build.py -c msm8953 -o all |tee "$BUILD_LOG_PATH"/adsp_sdm632.log
            [ "${PIPESTATUS[0]}" != "0" ] && echo -e "\033[31mbuild ADSP.VT.3.0 error\033[0m" && exit 1
	cd -
    else
        echo -e "\033[31m$AMSS_PATH/TZ.BF.4.0.5/trustzone_images/build/ms/: no such file or directory!!! \033[0m"
        exit 1
    fi
}


function set_environment(){
    rm version
    VERSION_FILE="$ROOT_PATH/device/wind/${PRODUCT}/version"
    [ -f "$VERSION_FILE" ] && cp "$VERSION_FILE" .

    INVER=$(awk -F = 'NR==1 {printf $2}' version)
    OUTVER=$(awk -F = 'NR==2 {printf $2}' version)
    PROVINCE=$(awk -F = 'NR==3 {printf $2}' version)
    OPERATOR=$(awk -F = 'NR==4 {printf $2}' version)
    INCREMENTALVER=$(awk -F = 'NR==5 {printf $2}' version)
    SVNUMBER=$(awk -F = 'NR==6 {printf $2}' version)
    TIME=$(date +%F)
    BUILDDATE=$(echo $INCREMENTALVER | sed -r 's/^[^-]*-//')
    ASUSVERSION=$(echo $INCREMENTALVER | sed -r '{s/^[^-]*-//;s/-[^-]*$//}')
    WDBUILDDATE=$(echo $INCREMENTALVER | sed -r '{s/^[^-]*-//;s/^[^-]*-//}')
    echo INNER VERSION IS $INVER
    echo OUTER VERSION IS $OUTVER
    echo PROVINCE NAME IS $PROVINCE
    echo OPERATOR NAME IS $OPERATOR
    echo RELEASE TIME IS $TIME
    echo INCREMENTAL VERSION IS $INCREMENTALVER    
    echo SV NUMBER IS $SVNUMBER
    echo BUILD DATE IS $BUILDDATE
    echo ASUS VERSION IS $ASUSVERSION
    export VER_INNER=$INVER
    export VER_OUTER=$OUTVER
    export PROVINCE_NAME=$PROVINCE
    export OPERATOR_NAME=$OPERATOR
    export RELEASE_TIME=$TIME
    export WIND_CPUCORES=$CPUCORE
    export VER_INCREMENTAL=$INCREMENTALVER
    export SV_NUMBER=$SVNUMBER    
    export WIND_PROJECT_NAME_CUSTOM=$CONFIG_NAME
    export WIND_DEXPREOPT_OPTION=$WIND_DEXPREOPT_OPTION    
    export WIND_EFUSE_UNSIGN=$EFUSE_UNSIGN
    export WIND_CHIP=$CHIP
    export WIND_BUILD_MODE=$BUILD_MODE
    export WIND_FACTORY_BUILD=$WIND_FACTORY_BUILD
    export WIND_NO_GMS=$WIND_NO_GMS
    export BUILDDATE
    export ASUSVERSION
    export WDBUILDDATE 
    export PATH="/usr/lib/jvm/java-8-openjdk-amd64/bin":$PATH
}


function config_prop(){
    CHIPID_DIR="SDM632.LA.1.0"
}


function back_ota_files(){
    local -r ota_amss_images=(
        $OUT_PATH/amss_images/sbl1.mbn
        $OUT_PATH/amss_images/tz.mbn
        $OUT_PATH/amss_images/devcfg.mbn
        $OUT_PATH/amss_images/keymaster64.mbn
        $OUT_PATH/amss_images/cmnlib_30.mbn
        $OUT_PATH/amss_images/cmnlib64_30.mbn
        $OUT_PATH/amss_images/rpm.mbn
        $OUT_PATH/amss_images/NON-HLOS.bin
        $OUT_PATH/amss_images/adspso.bin
        $OUT_PATH/mdtp.img
    )
    OTA_UPDATE_BACKUP_MBN="sbl1.mbn tz.mbn devcfg.mbn keymaster64.mbn cmnlib_30.mbn cmnlib64_30.mbn rpm.mbn"

    if [ -d "$CUSTOMPATH/$PRODUCT/radio/" ]
    then
        cd "$$CUSTOMPATH/$PRODUCT/radio/"
            rm -rf $CUSTOMPATH/$PRODUCT/radio/*.*
            for file in ${ota_amss_images[*]}
            do   
                if [ -f "$file" ]
                then
                    cp $file $CUSTOMPATH/$PRODUCT/radio/
                else 
                    echo -e "\033[40;31m Copy otapackage amss files error: can't found $file \033[0m"
                    exit 1
                fi  
            done     
            for file in $OTA_UPDATE_BACKUP_MBN;
            do   
                cp $file ${file}.bak
            done 
            mv cmnlib_30.mbn cmnlib.mbn
            mv cmnlib_30.mbn.bak cmnlib.mbn.bak
            mv cmnlib64_30.mbn cmnlib64.mbn
            mv cmnlib64_30.mbn.bak cmnlib64.mbn.bak
            mv keymaster64.mbn keymaster.mbn
            mv keymaster64.mbn.bak keymaster.mbn.bak
        cd -
    fi
}

function build_android(){
    set_environment
    config_prop
    source build/envsetup.sh
    if [ x"$VARIANT" == x"userroot" ] ; then
        lunch $PRODUCT-user
    else
        lunch $PRODUCT-$VARIANT
    fi
    
    case "$ACTION" in
        n|new|r|remake)
            if [ "$ACTION" == "remake" ] || [ "$ACTION" == "r" ]
            then
                find $OUT_PATH/ -name 'build.prop' -exec rm -rf {} \;
                find $OUT_PATH/ -name 'default.prop' -exec rm -rf {} \;
            fi
            if [ "$ACTION" == 'new' ]  || [ "$ACTION" == 'n' ] 
            then
                make clean
            fi
            if [ "$VARIANT" == "userroot" ]
            then
                make QCOM_BUILD_ROOT=yes -j$CPUCORE 2>&1 | tee "$BUILD_LOG_PATH"/android.log
            else
                make -j$CPUCORE 2>&1 | tee "$BUILD_LOG_PATH"/android.log
            fi
            ;;

    esac

    case "$BUILD_MODE" in
        otapackage)
            back_ota_files            
            make -j$CPUCORE "$BUILD_MODE" 2>&1 | tee "$BUILD_LOG_PATH"/"$BUILD_MODE".log
            if [ x"$BUILD_MODE" == x"otapackage" ];then
                cd "$AMSS_PATH"/$CHIPID_DIR/common/build/bin/asic/sparse_images
                    python "$ROOT_PATH"/amss/BOOT.BF.3.3/boot_images/core/storage/tools/ptool/checksparse.py -i ./../../../rawprogram0.xml -s "$ROOT_PATH"/out/target/product/"$PRODUCT"/ -o rawprogram_unsparse.xml
                cd -
            fi
            ;;
    esac

    cd "$ROOT_PATH"/prebuilts/sdk/tools/
        ./jack-admin kill-server
    cd -
}


function build_amss(){
    build_pl
    build_mpss
    build_rpm
    build_tz
    build_adsp
}

function build_common(){
    echo "========== SDM632.LA.1.0 =========="
    echo "make download files"
    if [ -d "$AMSS_PATH/SDM632.LA.1.0/common/build/" ]
    then
        cd "$AMSS_PATH/SDM632.LA.1.0/common/build/"
            python build.py "$PRODUCT" 2>&1|tee "$BUILD_LOG_PATH"/common_sdm632.log
            [ "${PIPESTATUS[0]}" != "0" ] && echo -e "\033[31mbuild SDM632.LA.1.0 error\033[0m" && exit 1
        cd -
    fi
}

function build_image(){
    case "$BUILD_MODE" in
        all)
            echo "build all"
            build_amss
            echo "build amss successful"
            build_android                    
            build_common
            ;;
        amss)
            echo "build all"
            build_amss
            echo "build amss successful"
            ;;
        otapackage)
            echo "build otapackage"
            build_android
            ;;
        only_build_android)
            echo "build otapackage"
            build_android
            build_common
            ;;
    esac
}


function main(){
    environment_clean
    args_parse "$@"
    copy_custom_files
    build_image
}


main "$@"
