#!/bin/bash
#update by yaoyuanchun@wind-mobi.com
start_time=$(date +%s)
readonly all_args="$@"
readonly ROOT=$(pwd)
OUT_PATH=$ROOT"/out/target/product"
readonly MY_NAME=$(whoami)
declare tmp_dir
declare Tcard_name
declare Fota_name
readonly sign_mark=sign
readonly verified_mark=verified
flag_6750=false


function change_sign(){
    local tmp_middle=""
    local sign_tmp_middle=""
    local new_release_file=""
    for tmp in $RELEASE_FILES
    do
        change_flag=0
        tmp_middle=$(echo $tmp | awk -F "." '{print $1}')
           
        for sign_tmp in $SIGN_RELEASE_FILES
        do
            sign_tmp_middle=$(echo $sign_tmp | awk -F "." '{print $1}')
            if [ $flag_6750 == "true" ]
            then
                if [ x"$tmp_middle-verified" == x"$sign_tmp_middle" ];then
                    new_release_file=$new_release_file" "$sign_tmp
                    change_flag=1
                fi
            else
                if [ x"$tmp_middle-sign" == x"$sign_tmp_middle" ];then
                    new_release_file=$new_release_file" "$sign_tmp
                    change_flag=1
                fi
            fi
        done
                
        if [ $change_flag -eq 0 ];then
            new_release_file=$new_release_file" "$tmp
        fi
    done
    RELEASE_FILES=$new_release_file
}


function write_md5(){
    > $OUT_PATH/checklist.md5
    echo "/*" >> $OUT_PATH/checklist.md5
    echo "* wind-mobi md5sum checklist" >> $OUT_PATH/checklist.md5
    echo "*/" >> $OUT_PATH/checklist.md5
}


function args_count_check(){
    if [ "$#" -eq 0 ]
    then
        log "error" "${FUNCNAME[1]} need enough args"
        exit 1
    fi
}


function log(){
    args_count_check "$@"
    local -r level="$1"
    local -r string="$2"
    local -r time_now=$(date +%Y-%m-%d' '%H:%M:%S)
    case "$level" in 
        "error") echo -e "\e[31m$time_now ERROR: $string\e[0m" ;;
        "info") echo "$time_now INFO: $string" ;;
        "good") echo -e "\e[32m$time_now GOOD: $string\e[0m" ;;
        "notice") echo -e "\e[34m$time_now NOTICE: $string\e[0m" ;;
    esac    
}

function parse_args(){
    args_count_check "$@"
    log "info" "start to parse args"
    for local_args1 in $@
    do
        local args_count=0
        for local_args2 in $@
        do
            if [ "$local_args1" == "$local_args2" ]
            then
                args_count=$((args_count + 1))
            fi
        done
        if [ "$args_count" -ne 1 ]
        then
            log "error" "$local_args1 multiple"
            exit 1
        fi
    done
    unset local_args1 local_args2
    readonly build_param="$1"
    readonly args_2="$2"
    if [ x"$build_param" = "x" ]
    then
        log "error"  "Usage: command [build_param]. e.g. command l300"
        exit 1
    fi
    [ x"$2" == x"symbols" ] && readonly symbols_flag=1 && release_param="all"
    [ x"$3" == x"sign" ] && sign_flag="yes"
    [ x"$2" == x"sign" ] && sign_flag="yes" && release_param="all"
    [ "$release_param" != "all" ] && release_param="$args_2"
    [[ "$all_args" =~ "zip" ]] && readonly ZIP_VERSION="true"
    [ x"$release_param" = "x" ] &&  release_param=all
    readonly release_param
    [ "$sign_flag" != "" ] && readonly sign_flag
}


function init_config(){
    log "info" "start to init config"
    case $build_param in
        E281L)
            HARDWARE_VER="WK4MA1A1-2"
            OUT_PATH="$OUT_PATH/E281L"
            readonly PLATFORM="MT6737T"
            ;;
        D281L)
            HARDWARE_VER="WK4MA1A2-2"
            OUT_PATH="$OUT_PATH/D281L"
            readonly PLATFORM="MT6737M"
            ;;
        ZB500TL)
            HARDWARE_VER=WK4MA1A1-2
            OUT_PATH=$OUT_PATH/ZB500TL
            readonly PLATFORM=MT6737T
            ;;
        ZB500TLVW)
            HARDWARE_VER=S01
            OUT_PATH=$OUT_PATH/ZB500TLVW
            readonly PLATFORM=MT6737M
            ;;
        E271L)
            HARDWARE_VER=S01
            OUT_PATH=$OUT_PATH/E271L
            readonly PLATFORM=MT6737M
            ;;
	E260L)
	    HARDWARE_VER=S01
	    OUT_PATH=$OUT_PATH/E260L
	    readonly PLATFORM=MT6750 
            readonly flag_6750=true
            ;;
        E286L)
            HARDWARE_VER=S01
            OUT_PATH=$OUT_PATH/E286L
            readonly PLATFORM=MT6750
            readonly flag_6750=true
	    ;;
        E287L)
            HARDWARE_VER=S01
            OUT_PATH=$OUT_PATH/E287L
            readonly PLATFORM=MT6750
            readonly flag_6750=true
            ;;
        E266L)
            HARDWARE_VER=S01
            OUT_PATH=$OUT_PATH/E266L
            readonly PLATFORM=MT6750
            readonly flag_6750=true
            ;;
        E267L)
            HARDWARE_VER=S01
            OUT_PATH=$OUT_PATH/E267L
            readonly PLATFORM=MT6750
            readonly flag_6750=true
            ;;
        E262L)
            HARDWARE_VER=S01
            OUT_PATH=$OUT_PATH/E262L
            readonly PLATFORM=MT6750
            readonly flag_6750=true
            ;;
        *)
            log "error" "$build_param : no such project!! in function init_config"
            exit 1
        ;;
    esac

    if [ ! -d "$OUT_PATH" ];then
        log "error" "there is no out path:$OUT_PATH"
        exit 1
    fi
    if [ -s "$OUT_PATH/system/build.prop" ];then
        readonly BUILD_FILE="$OUT_PATH/system/build.prop"
        local -r read_version=$(grep -n "ro.product.hardware=*" $BUILD_FILE | cut -d "=" -f 2)
        if [ x"$read_version" != x ];then
            HARDWARE_VER="$read_version"
        fi
        local -r product_info=$(grep -n "ro.product.carrier=*" $BUILD_FILE | cut -d "=" -f 2)
        if [ x"$product_info" != x ];then
            if [ $flag_6750 == "true" ]
	    then
      		echo "[Software]" > $OUT_PATH/ProductInfo.ini
                echo "HW=$product_info" >> $OUT_PATH/ProductInfo.ini
		echo "[Efuse]" >> $OUT_PATH/ProductInfo.ini
	        echo -n "Enable=YES" >> $OUT_PATH/ProductInfo.ini
	    else
                echo "[Software]" > $OUT_PATH/ProductInfo.ini
                echo -n "HW=$product_info" >> $OUT_PATH/ProductInfo.ini
	    fi
        fi
    fi
    readonly HARDWARE_VER
}


function all_system_file_ready(){
    log "info" "start to all_system_file_ready"
    if [ -s "boot_su.img" ]
    then
        readonly boot_su_flag=1
        cp boot_su.img $OUT_PATH/
    fi
	
    if [ x"$release_param" = x"all" ]; then
        for i in "$OUT_PATH/system/vendor/etc/mddb/BPLGUInfoCustomAppSrcP_MT6735_S00_MOLY_LR9*_ltg_n" ; do
            if [ -f $i ]; then
                cp $i  $OUT_PATH/Modem_Database_ltg
            fi
        done
        if [ $build_param == ZB500TLVW ];then
            i="$OUT_PATH/system/vendor/etc/mddb/BPLGUInfoCustomAppSrcP_MT6735_S00_MOLY_LR9*_lwg_1"
            cp $i  $OUT_PATH/Modem_Database_lwg_1 && unset i
            i="$OUT_PATH/system/vendor/etc/mddb/BPLGUInfoCustomAppSrcP_MT6735_S00_MOLY_LR9*_lwg_2"
            cp $i  $OUT_PATH/Modem_Database_lwg_2     
        elif [ $flag_6750 == "true" ];then
	    for i in "$OUT_PATH/system/vendor/etc/mddb/MDDB_InfoCustomAppSrcP_MT6750_S00_MOLY_LR11*_1_ulwctg_n.EDB" ; do
                if [ -f $i ]; then
                    cp $i  $OUT_PATH/Modem_Database_ulwctg
               fi
            done
            Modem_3G_PATCH="$OUT_PATH/system/vendor/etc/mddb/MDDB.C2K.META*.EDB"
            if [ -f  $Modem_3G_PATCH ];then
               cp $Modem_3G_PATCH  $OUT_PATH/Modem_Database_3g
            fi
	else
            i="$OUT_PATH/system/vendor/etc/mddb/BPLGUInfoCustomAppSrcP_MT6735_S00_MOLY_LR9*_lwg_n"
            cp $i  $OUT_PATH/Modem_Database_lwg
        fi
        if [ $flag_6750 == "true" ]
	then
            for i in "$OUT_PATH/obj/CGEN/APDB_MT6755_"$HARDWARE_VER"_alps-mp-n0.mp7_W??.??" ; do
                if [ -f $i ]; then
                    cp $i $OUT_PATH/AP_Database
                fi
            done 
	else
            for i in "$OUT_PATH/obj/CGEN/APDB_MT6735_"$HARDWARE_VER"_alps-mp-n0.mp1_W17.??" ; do
                if [ -f $i ]; then
                    cp $i $OUT_PATH/AP_Database
                fi
            done
	    
	fi    
    fi
	
    if [ $build_param == ZB500TLVW ];then
        if [ ! -f $OUT_PATH/Modem_Database_ltg ];then
            ALL_RELEASE_FILES_EXCEPT_SYSTEM="logo.bin $PLATFORM"_Android_scatter.txt" preloader_${build_param}.bin AP_Database Modem_Database_lwg_1 Modem_Database_lwg_2 boot.img secro.img userdata.img lk.bin recovery.img cache.img trustzone.bin"
        elif [[ ! -f $OUT_PATH/Modem_Database_lwg_1 && ! -f $OUT_PATH/Modem_Database_lwg_2 ]];then
            ALL_RELEASE_FILES_EXCEPT_SYSTEM="logo.bin $PLATFORM"_Android_scatter.txt" preloader_${build_param}.bin AP_Database Modem_Database_ltg boot.img secro.img userdata.img lk.bin recovery.img cache.img trustzone.bin"
        else
            ALL_RELEASE_FILES_EXCEPT_SYSTEM="logo.bin $PLATFORM"_Android_scatter.txt" preloader_${build_param}.bin AP_Database Modem_Database_ltg Modem_Database_lwg_1 Modem_Database_lwg_2 boot.img secro.img userdata.img lk.bin recovery.img cache.img trustzone.bin"
        fi
        SIGN_RELEASE_FILES="APD-sign.img boot-sign.img cache-sign.img lk-sign.bin logo-sign.bin recovery-sign.img secro-sign.img system-sign.img trustzone-sign.bin userdata-sign.img boot_su-sign.img"
    elif [ $flag_6750 == "true" ];then
        if [ -f $OUT_PATH/Modem_Database_3g ];then
            ALL_RELEASE_FILES_EXCEPT_SYSTEM="logo.bin $PLATFORM"_Android_scatter.txt" preloader_${build_param}.bin AP_Database Modem_Database_ulwctg Modem_Database_3g boot.img secro.img userdata.img lk.bin recovery.img cache.img trustzone.bin md1rom.img md1dsp.img md3rom.img md1arm7.img"
        else
            ALL_RELEASE_FILES_EXCEPT_SYSTEM="logo.bin $PLATFORM"_Android_scatter.txt" preloader_${build_param}.bin AP_Database Modem_Database_ulwctg boot.img secro.img userdata.img lk.bin recovery.img cache.img trustzone.bin md1rom.img md1dsp.img md3rom.img md1arm7.img"
        fi
        SIGN_RELEASE_FILES="boot_su-verified.img boot-verified.img lk-verified.bin logo-verified.bin md1rom-verified.img md1dsp-verified.img md3rom-verified.img md1arm7-verified.img recovery-verified.img trustzone-verified.bin"
    else
        if [ ! -f $OUT_PATH/Modem_Database_ltg ];then
            ALL_RELEASE_FILES_EXCEPT_SYSTEM="logo.bin $PLATFORM"_Android_scatter.txt" preloader_${build_param}.bin AP_Database Modem_Database_lwg boot.img secro.img userdata.img lk.bin recovery.img cache.img trustzone.bin"
        elif [ ! -f $OUT_PATH/Modem_Database_lwg ];then
            ALL_RELEASE_FILES_EXCEPT_SYSTEM="logo.bin $PLATFORM"_Android_scatter.txt" preloader_${build_param}.bin AP_Database Modem_Database_ltg boot.img secro.img userdata.img lk.bin recovery.img cache.img trustzone.bin"
        else
            ALL_RELEASE_FILES_EXCEPT_SYSTEM="logo.bin $PLATFORM"_Android_scatter.txt" preloader_${build_param}.bin AP_Database Modem_Database_ltg Modem_Database_lwg boot.img secro.img userdata.img lk.bin recovery.img cache.img trustzone.bin"
        fi
        SIGN_RELEASE_FILES="APD-sign.img boot-sign.img cache-sign.img lk-sign.bin logo-sign.bin recovery-sign.img secro-sign.img system-sign.img trustzone-sign.bin userdata-sign.img boot_su-sign.img"
    fi
    if [ x"$boot_su_flag" == x"1" ]
    then
        ALL_RELEASE_FILES_EXCEPT_SYSTEM=${ALL_RELEASE_FILES_EXCEPT_SYSTEM}" boot_su.img"
    fi

    if [ -f $OUT_PATH/APD.img ]
    then
        ALL_RELEASE_FILES_EXCEPT_SYSTEM=${ALL_RELEASE_FILES_EXCEPT_SYSTEM}" APD.img"
    fi

    if [ -f $OUT_PATH/asusfw.img ]
    then
        ALL_RELEASE_FILES_EXCEPT_SYSTEM=${ALL_RELEASE_FILES_EXCEPT_SYSTEM}" asusfw.img"
    fi

    if [ -f $OUT_PATH/ProductInfo.ini ];then
        ALL_RELEASE_FILES_EXCEPT_SYSTEM=${ALL_RELEASE_FILES_EXCEPT_SYSTEM}" ProductInfo.ini"
    fi

    if [ x"$symbols_flag" == x"1"  ] && [ -f "$OUT_PATH/symbols.zip" ]
    then
        ALL_RELEASE_FILES=${ALL_RELEASE_FILES_EXCEPT_SYSTEM}" system.img"
    else
        ALL_RELEASE_FILES=${ALL_RELEASE_FILES_EXCEPT_SYSTEM}" system.img"
    fi
}


function precess_release_param(){
    log "info" "start to precess release param"
    local -r local_release_param="$1"
    case $local_release_param in
        all)
            all_system_file_ready
            RELEASE_FILES=$ALL_RELEASE_FILES
            if [ x"$sign_flag" == x"yes" ];then
                change_sign
            fi
            ;;
        system-)
            all_system_file_ready
            RELEASE_FILES=$ALL_RELEASE_FILES_EXCEPT_SYSTEM
            if [ x"$sign_flag" == x"yes" ];then
                change_sign
            fi
            ;;        
        system)
            if [ x"$sign_flag" == x"yes" ];then
                RELEASE_FILES="system-sign.img"
            else
                RELEASE_FILES="system.img"
            fi
            ;;
        recovery)
            if [ x"$sign_flag" == x"yes" ];then
                if [ "$flag_6750" == "true" ]
                then
                    RELEASE_FILES="recovery-verified.img"
                else
                    RELEASE_FILES="recovery-sign.img"
                fi
            else
                RELEASE_FILES="recovery.img"
            fi
            ;;
        boot)
            if [ x"$sign_flag" == x"yes" ];then
                if [ "$flag_6750" == "true" ]
                then
                    RELEASE_FILES="boot-verified.img"
                else
                    RELEASE_FILES="boot-sign.img"
                fi
            else
                RELEASE_FILES="boot.img"
            fi
            ;;
        lk)
            if [ x"$sign_flag" == x"yes" ];then
                if [ "$flag_6750" == "true" ]
                then
                    RELEASE_FILES="lk-verified.bin"
                else
                    RELEASE_FILES="lk-sign.bin"
                fi
            else
                RELEASE_FILES="lk.bin"
            fi
            ;;
        logo)
            if [ x"$sign_flag" == x"yes" ];then
                if [ "$flag_6750" == "true" ]
                then
                    RELEASE_FILES="logo-verified.bin"
                else
                    RELEASE_FILES="logo-sign.bin"
                fi
            else
                RELEASE_FILES="logo.bin"
            fi
            ;;
        userdata)
            if [[ x"$sign_flag" == x"yes" && "$flag_6750" != "false" ]];then
                RELEASE_FILES="userdata-sign.img"
            else
                RELEASE_FILES="userdata.img"
            fi
            ;;
        apd)
            if [[ x"$sign_flag" == x"yes" && "$flag_6750" != "false" ]];then
                RELEASE_FILES="APD-sign.img"
            else
                RELEASE_FILES="APD.img"
            fi
            ;;
        pl)
            RELEASE_FILES="preloader_${build_param}.bin"
            ;;
        ota)
            cd $OUT_PATH
            ota_files=`ls -dt full_${build_param}-ota-*.zip | head -n 1`

            if [ -d $OUT_PATH/obj/PACKAGING/target_files_intermediates ]; then
                cd $OUT_PATH/obj/PACKAGING/target_files_intermediates
                target_files=`ls -dt full_${build_param}-target_files-*.zip | head -n 1`
            fi

            if [ -f $OUT_PATH/target_files-package.zip ]; then
                cd $OUT_PATH    
                adups_target=`ls -dt target_files-package*.zip | head -n 1`
            fi      
            
            cd $ROOT
            
            RELEASE_FILES="$target_files $ota_files $adups_target"
            ;;
        diff)
            if [ -f ./updateA2B.zip ] &&  [ -f ./updateB2C.zip ] ; then
                diff_files="updateA2B.zip updateB2C.zip"
            elif  [ -f ./updateA2B.zip ]; then
                diff_files=updateA2B.zip
            elif  [ -f ./updateB2C.zip ]; then
                diff_files=updateB2C.zip
            fi
            RELEASE_FILES="$diff_files"
            ;;
        none)
            log "error" "build_param: none args"
            exit 1
            ;;        
        *)
            log "error" "not supported!!"
            exit 1
            ;;
    esac
}


function change_release_file_to_abs_path(){
    log "info" "start to change release file to abs path"
    FILES=""
    OUT_SIGN_PATH0=$OUT_PATH/resign/bin
    OUT_SIGN_PATH1=$OUT_PATH/signed_bin
    KEEP_OUT_PATH=$OUT_PATH
    for file in $RELEASE_FILES
    do
        if [[ "$file" =~ "sign" ]]
        then
            if [ $flag_6750 == "true" ]
            then
                OUT_PATH=$OUT_SIGN_PATH0
            else
                OUT_PATH=$OUT_SIGN_PATH1
            fi
        else
            OUT_PATH=$KEEP_OUT_PATH
        fi
        if [ x"$target_files" != x"" ] && [ x"$file" == x"$target_files" ]
        then
            FILES=$FILES" "$OUT_PATH"/obj/PACKAGING/target_files_intermediates/"$file
        elif [ x"$file" == x"updateA2B.zip" ] || [ x"$file" == x"updateB2C.zip" ]
        then
            FILES=$FILES" "$ROOT"/"$file
        else
            FILES=$FILES" "$OUT_PATH"/"$file
        fi
    done
    OUT_PATH="$KEEP_OUT_PATH"
    for file in $FILES
    do
        local dir_name=$(dirname $file)
        local file_name=$(basename $file)
        pushd "$dir_name" > /dev/null
            local file_size=$(du -sh "$file_name")&& log "good" "$file_size"
            if [ ! -s "$file_name" ]
            then
                log "error" "$(basename $file_name) do not exist!!!" && exit
            fi
        popd > /dev/null
    done
    log "notice" "$(echo $FILES | awk '{print NF}') files"
}


function cp_release_file_to_tmp(){
    args_count_check "$@"
    local -r LOCAL_FILES="$1"
    local -r local_release_param="$2"
    pushd "$ROOT" > /dev/null
        rm -rf ./back_up_version_temp_*
        tmp_dir=$(mktemp -d back_up_version_temp_XXXX)
        log "info" "start to cp files to $tmp_dir"
        tmp_dir=$(cd $tmp_dir && pwd)
        case $local_release_param in
            diff) : ;;
            *)
                for filename in ${LOCAL_FILES}
                do
                    cp "$filename" "$tmp_dir" && log "info" "cp $(basename $filename) to $(basename $tmp_dir) successful." &
                done
                wait
                ;;
        esac 
        if [[ "$local_release_param" == $last_release_param && "$symbols_flag" == "1" ]]
        then
            mv "all_symbols.zip" "$tmp_dir" #没有写在原来all 对应的释放变量，是因为只有执行all的时候才会释放symbols.zip 
        fi
    popd > /dev/null
}


function do_or_check_md5_for_release_file(){
    args_count_check "$@"
    local -r do_or_check="$1"
    local -r local_out_path="$2"
    local -r local_files="$3"
    pushd "$ROOT" > /dev/null
        if [ -s "$local_out_path/checklist.md5" ]    
        then
            case $do_or_check in
                do) 
                    log "info" "do md5 for release files"
                        for local_tmp_file in ${local_files}
                        do
                            local_tmp_line=$(basename $local_tmp_file)
                            local_file_dir=$(dirname $local_tmp_file)
                            if [ ! -d "$local_file_dir" ]
                            then
                                log "error"  "md5sum: file dir do not exist"
                                exit 1
                            fi
                            if [ "$local_tmp_line" == "checklist.md5" ]
                            then
                                continue
                            fi
                            sed -i "/$local_tmp_line/"d "${local_out_path}/checklist.md5"
                            pushd "$local_file_dir" > /dev/null
                                md5sum -b "${local_tmp_line}" | tee -a "$local_out_path/checklist.md5"
                                if [ "${PIPESTATUS[0]}" != 0 ]
                                then
                                    log "error" "md5sum $local_tmp_line failed"
                                    exit 1
                                fi
                            popd > /dev/null
                        done
                        cp "${local_out_path}/checklist.md5" .
                    ;;
                check) 
                    log "info" "check md5 for release files"
                    for local_tmp_line in ${local_files}
                    do
                        local_tmp_line=$(basename $local_tmp_line)
                        if [ "$local_tmp_line" == "checklist.md5" ]
                        then
                            continue
                        fi
                        local md5num=$(grep "$local_tmp_line" "$local_out_path/checklist.md5" | awk -F "*" '{print $1}')
                        local becheck_file=$(grep "$local_tmp_line" "$local_out_path/checklist.md5" | awk -F "*" '{print $2}')
                        local md5num_recheck=$(md5sum "$tmp_dir/$becheck_file" | awk '{print $1}')
                        if [ "$md5num_recheck" == $(echo "$md5num") ]
                        then
                            log "good" "$becheck_file md5check good!!!"
                        else
                            log "error" "$becheck_file md5check bad!!!"
                            exit 1
                        fi
                    done 
                    ;;
                *) 
                    log "error" "wrong option" && exit 1 
                    ;;
            esac
        else
            log "error" "checklist.md do not exist!!!"
        fi
    popd > /dev/null
}


function zip_version(){
    args_count_check "$@"
    log "info" "start to zip version"
    local -r local_Plat_version_name="$1"
    local -r local_Outer_version_name="$2"
    local -r files_do_not_need_to_zip=("boot_su" "checklist" "all_symbols")
    pushd "$ROOT" > /dev/null
        rm -rf "$local_Plat_version_name" "$local_Outer_version_name"
        mkdir "$local_Plat_version_name"
        mkdir "${local_Outer_version_name}"
        mv "$tmp_dir"/* "$local_Plat_version_name"
        for local_files in "${files_do_not_need_to_zip[@]}"
        do
            [ -s "$local_Plat_version_name"/"$local_files"* ] &&  mv "$local_Plat_version_name"/"$local_files"* "$tmp_dir"
        done
        cp "${local_Plat_version_name}"/*  "${local_Outer_version_name}"
        zip -r -m "${local_Plat_version_name}.zip" "$local_Plat_version_name"&
        zip -r -m "${local_Outer_version_name}.zip" "${local_Outer_version_name}"&
        #touch ${local_Plat_version_name}.zip && rm -rf ${local_Plat_version_name}
        #touch ${local_Outer_version_name}.zip && rm -rf ${local_Outer_version_name}
        wait
        mv "${local_Plat_version_name}.zip" "$tmp_dir"
        mv "${local_Outer_version_name}.zip" "$tmp_dir"
        log "info" "zip ${local_Plat_version_name}.zip && ${local_Outer_version_name}.zip"
    popd > /dev/null
}


function get_ota_name(){
    args_count_check "$@"
    local -r target_file="$1"
    rm -rf "${target_file}_zip_dir" > /dev/null 2>&1
    unzip -j "${target_file}.zip" "SYSTEM/build.prop" -d "${target_file}_zip_dir" > /dev/null 2>&1
    if [ "$?" != 0 ]
    then
        log "error" "error"
        exit 1
    fi
    sed -n "s/ro.build.version.incremental=//g"p "${target_file}_zip_dir/build.prop"
    if [ "$?" != 0 ]
    then
        log "error" "error"
    fi
    rm -rf "${target_file}_zip_dir" > /dev/null 2>&1
}


function rename_ota_or_diff__name(){
    args_count_check "$@"
    local -r rename_type="$1"
    case $rename_type in
        ota) 
            log "info" "ota rename"
            pushd "${tmp_dir}" > /dev/null
                if [ "$build_param" == "E262L" ]
                then
                    local -r device=$(sed -n "s/ro.product.model=//g"p "$BUILD_FILE" | head -1)
                else
                    local -r device=$(sed -n "s/ro.product.device=//g"p "$BUILD_FILE" | head -1)
                fi
                local -r sku=$(sed -n "s/ro.build.asus.sku=//g"p "$BUILD_FILE" | head -1)
                local -r version=$(sed -n "s/ro.build.display.id=//g"p "$BUILD_FILE" | head -1 | awk -F "-" '{print $2}')
                local -r build_type=$( sed -n "s/ro.build.type=//g"p "$BUILD_FILE" | head -1)
                if [[ "$device" == "" || "$sku" == "" || "$version" == "" || "$build_type" == "" ]]
                then
                    log "error" "fail to get Tcard name!!!"
                    exit 1
                fi
                Tcard_name="UL"-"${device}"-"${sku}"-"${version}"-"${build_type}".zip
		readonly Tcard_name=$(echo $Tcard_name | sed "s/ //g")
                mv "$ota_files" "$Tcard_name"
            popd > /dev/null
            ;;
        diff)
            log "info" "diff rename"
			local -r diff_rename_type="$2"
            pushd "$ROOT" > /dev/null
                case $diff_rename_type in
                    A2B)
                        log "info" "rename A->B"
                        local -r ota_past_name=$(get_ota_name "update_a")
                        local -r ota_base_name=$(get_ota_name "update_b")
                        if [[ "$ota_past_name" == "" ||"$ota_base_name" == "" ]]
                        then
                            log "error" "empty ,faild to get ota_past_name or ota_base_name"
                            exit 1
                        elif [[ "$ota_past_name" =~ "error" || "$ota_base_name" =~ "error" ]]
                        then
                            log "error" "error ,faild to get ota_past_name or ota_base_name"
                            exit 1
                        fi
                        
                        Fota_name="${ota_past_name}_${ota_base_name}_fota.zip"
                        cp "updateA2B.zip" "$Fota_name"
                        mv "${Fota_name}" "$tmp_dir"
                        ;;
                    B2C)
                        log "info" "rename B->C"
                        local -r ota_base_name=$(get_ota_name "update_b")
                        local -r ota_future_name=$(get_ota_name "update_c")
                        if [[ "$ota_base_name" == "" || "$ota_future_name" == "" ]]
                        then
                            log "error" "empty ,faild to get ota_base_name or ota_future_name"
                            exit 1
                        elif [[ "$ota_base_name" =~ "error" || "$ota_future_name" =~ "error" ]]
                        then
                            log "error" "error ,faild to get ota_base_name or ota_future_name"
                            exit 1
                        fi
                        
                        Fota_name="${ota_base_name}_${ota_future_name}_fota.zip"
                        cp "updateB2C.zip" "$Fota_name"
                        mv "${Fota_name}" "$tmp_dir"
                        ;;
                esac
            popd > /dev/null
            ;;
        *)
            log "info"  "other action"
            ;;
    esac
}


function do_checksum(){
    args_count_check "$@"
    log "info" "start to do checksum for version"
    local -r checksum_dir="$1"
    pushd "$tmp_dir" > /dev/null
        #cp $checksum_dir/* .
        #if [[ ! -s "CheckSum_Gen.exe" || ! -s "FlashToolLib.dll" || ! -s "FlashToolLibEx.dll" || ! -s "FlashToolLibEx.dll" ]]
        #then
        #    log "error" "need CheckSum file"
        #    exit 1
        #fi
        #log "info" "source ~/.bashrc"
        #source ~/.bashrc
        #echo "\015" | wine CheckSum_Gen.exe
        git clone ssh://10.0.30.9:29418/SCM_script
        [ "$?" != 0 ] && echo "git clone SCM_script error" && exit 1
        cp "SCM_script"/checksum.zip .
        unzip checksum.zip
        ./CheckSum_Gen
        if [ "$?"  != 0 ]
        then
            log "error" "do checksum failed!"
            exit 1
        fi
        rm CheckSum_Gen.exe  FlashTool* CheckSum_Gen* libflashtool* checksum.zip
        rm -rf Log SCM_script
    popd > /dev/null
}


function process_release_file(){
    args_count_check "$@"
    local -r local_release_param="$1"
    local local_files="$2"
    local -r checksum_dir="$3"
    pushd "$ROOT" > /dev/null
        case $local_release_param in
            all) 
                if [ $flag_6750 == "true" ]
                then
                    local -r Plat_version_name="$(sed -n  "s/ro.build.wind.version=//g"p "$OUT_PATH/system/build.prop" | head -1 | awk -F "Plat:|Outer:" '{print $2}')_DL"
                    local -r Outer_version_name="$(sed -n "s/ro.custom.build.version=//g"p "$OUT_PATH/system/build.prop" | head -1 )"
                else
                    local -r Plat_version_name="$(sed -n  "s/ro.build.wind.version=//g"p "$OUT_PATH/system/build.prop" | awk -F "Plat:|Outer:" '{print $2}')_DL"
                    local Outer_version_name=$(sed -n  "s/ro.build.wind.version=//g"p "$OUT_PATH/system/build.prop" | awk -F "Plat:|Outer:" '{print $3}' | cut -f2-10 -d ".")
                    readonly Outer_version_name="${Outer_version_name%End}"
                fi
                if [[ "$Plat_version_name" == "" || "$Outer_version_name" == "" ]]
                then
                    log "error" "version name empty!!!"
                    exit 1
                fi
                do_checksum "$checksum_dir"
                zip_version "${Plat_version_name}" "$Outer_version_name"
                md5_files=$(ls $tmp_dir) 
		for line in $md5_files; do md5_files_path=$(echo $md5_files_path $tmp_dir/$line); done
                do_or_check_md5_for_release_file "do" "$OUT_PATH" "$md5_files_path"
                unset md5_files md5_files_path
                ;;
            ota)
                rename_ota_or_diff__name "$local_release_param"
                md5_files=$(ls $tmp_dir) 
		for line in $md5_files; do md5_files_path=$(echo $md5_files_path $tmp_dir/$line); done
                do_or_check_md5_for_release_file "do" "$OUT_PATH" "$md5_files_path"
                unset md5_files md5_files_path
                ;;
            diff)
                local diff_status="false"
                if [[ -s "updateA2B.zip" && -s "update_a.zip" && -s "update_b.zip" ]]
                then
                    rename_ota_or_diff__name "$local_release_param" "A2B"
                    diff_status="true"
                    
                fi
                if [[ -s "updateB2C.zip" && -s "update_b.zip" && -s "update_c.zip" ]]
                then
                    rename_ota_or_diff__name "$local_release_param" "B2C"
                    diff_status="true"
                fi

                md5_files=$(ls $tmp_dir) 
 	        for line in $md5_files; do md5_files_path=$(echo $md5_files_path $tmp_dir/$line); done
                echo "$md5_files_path ##########"
                do_or_check_md5_for_release_file "do" "$OUT_PATH" "$md5_files_path"
                unset md5_files md5_files_path
                if [ "$diff_status" == "false" ]
                then
                    log "error" "need update*.zip"
                    exit 1
                fi
                local -r fota_files=$(ls "$tmp_dir"/*fota.zip)
                ;;
            *)
                log "info" "do other"
                ;;
        esac
    popd >/dev/null
}


function cp_release_files_to_bbtd(){
    args_count_check "$@"
    local -r local_release_param="$1"
    pushd "${tmp_dir}" > /dev/null
        log "info" "start to cp release files to bbtd"
        local -r be_released_files=$(ls)
        for file in ${be_released_files}
        do
            cp "$file" /data/mine/test/MT6572/$MY_NAME/
            log "info" "cp $file to /data/mine/test/MT6572/$MY_NAME/ successful!!!"
        done
    popd > /dev/null
}


function release_files(){
    args_count_check "$@"
    local -r local_release_param="$1"
    precess_release_param "$local_release_param"
    change_release_file_to_abs_path
    FILES=$FILES" "$OUT_PATH"/"checklist.md5
    #do_or_check_md5_for_release_file "do" "$OUT_PATH" "$FILES"
    cp_release_file_to_tmp "$FILES" "$local_release_param"
    process_release_file "$local_release_param" "$FILES" ~/checksum
    cp "$OUT_PATH/checklist.md5" "$tmp_dir"
    cp_release_files_to_bbtd "$local_release_param"
    log "info" "$local_release_param: Successful!!!"
}

function clean_checklist(){
    if [ -s "$OUT_PATH/checklist.md5" ]
    then
        if [ "$sign_flag" == "yes" ]
        then
            if [ "$flag_6750" == "true" ]
            then
                grep "$verified_mark" "$OUT_PATH/checklist.md5" > /dev/null
                if [ "$?" != 0 ]
                then
                    write_md5
                fi
            else
                grep "$sign_mark" "$OUT_PATH/checklist.md5" > /dev/null
                if [ "$?" != 0 ]
                then
                    write_md5
                fi
            fi
        else
            if [ "$flag_6750" == "true" ]
            then
                grep "$verified_mark" "$OUT_PATH/checklist.md5" > /dev/null
                if [ "$?" == 0 ]
                then
                    write_md5
                fi
            else
                grep "$sign_mark" "$OUT_PATH/checklist.md5" > /dev/null
                if [ "$?" == 0 ]
                then
                    write_md5
                fi
            fi
        fi
    else
        write_md5
    fi
}


function zip_all_symbols(){
    args_count_check "$@"
    local -r local_release_param="$1"
    local -r symbols_path="$OUT_PATH/symbols"
    local -r vmlinux_path="$OUT_PATH/obj/KERNEL_OBJ/vmlinux"
    local -r bl31_path="$OUT_PATH/trustzone/ATF_OBJ/debug/bl31/bl31.elf"
    pushd "$ROOT"
        if [ -s "all_symbols.zip" ]
        then
            rm "all_symbols.zip"
        fi
        if [[ "$local_release_param" =~ "all" && "$local_release_param" =~ "ota" && "$symbols_flag" == "1" ]]
        then
            cp -a "$symbols_path" .
            cp -a "$vmlinux_path" .
            cp -a "$bl31_path" .
            zip -r -m "all_symbols.zip" "symbols" "vmlinux" "bl31.elf"
        elif [[ "$local_release_param" =~ "all" && "$symbols_flag" == "1" ]]
        then
            cp -a "$symbols_path" .
            cp -a "$bl31_path" .
            zip -r -m "all_symbols.zip" "symbols" "bl31.elf"
        elif [[ "$local_release_param" =~ "ota" && "$symbols_flag" == "1" ]]
        then
            cp -a "$vmlinux_path" .
            cp -a "$bl31_path" .
            zip -r "all_symbols.zip" "vmlinux" "bl31.elf"
        fi
    popd
}

#################     main     ###################
parse_args "$@"
init_config
if [ "$ZIP_VERSION" == "true" ]
then
    write_md5
    readonly final_release_param="all ota diff"
    readonly last_release_param=$(echo $final_release_param | awk '{print $NF}')
    zip_all_symbols "$final_release_param"
    for local_release_param in $final_release_param
    do
        release_files "$local_release_param"
    done
else
    precess_release_param "$release_param"
    change_release_file_to_abs_path
    clean_checklist
    FILES=$FILES" "$OUT_PATH"/"checklist.md5
    do_or_check_md5_for_release_file "do" "$OUT_PATH" "$FILES"
    log "info" "cp release files to bbtd"
    for local_file in $FILES
    do
        cp "$local_file" /data/mine/test/MT6572/$MY_NAME/
        log "info" "cp $(basename $local_file) to /data/mine/test/MT6572/$MY_NAME/ successful!!!"
    done
    log "good" "successful!"
fi

end_time=$(date +%s)
count_time=$((end_time - start_time))
echo "times: $count_time"
