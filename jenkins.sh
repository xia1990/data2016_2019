#!/bin/bash
readonly SCRIPTDIR="$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)"
release_stript='release_version_new.sh'
ROOT=$(pwd)
MY_NAME=$(whoami)
TODAY=$(date +%Y%m%d)
Random="$RANDOM"
HOST_NAME_ARRAY=(SOFT35-11 SOFT35-12 SOFT35-14 SOFT35-15 SOFT35-16 SOFT35-17 SOFT35-18)
mirror_path_array=('/home/jenkins/mirror' '/home/jenkins/mirror' '/home1/SW3/mirror' '/home1/SW3/mirror' '/home1/SW3/mirror' '/home/jenkins/mirror' '/home/jenkins/mirror')

readonly OPTION_VAR_ARRAY=(
    CODE_URL
    CODE_BRANCH
    CODE_XML
    PROJECT_NAME
    VARIANT
    PROJECT_BUILD_NAME
    SAVE_TYPE
    IN_VER
    OUT_VER
    INCRE_VER
    DEBUG_MOD
    BUILD_B99
)

function clean_environment(){
    echo "clean_environment"
    for myvar in "${OPTION_VAR_ARRAY[@]}"
    do
        unset "$myvar"
    done
}

function modified_auto_args(){
    local -r local_key="$1"
    local -r local_value="$2"
    local local_modified_site="$3"
    Auto_key_line=$(grep -n "$local_key" "$auto_script" | head -1 | awk -F ":|=" '{print $1" "$2}')
    if [[ "$Auto_key_line" == "" || -z $Auto_key_line   ]]
    then
        echo "error , do not found $local_key" && exit 1
    fi
    line_no=$(echo "$Auto_key_line" | awk '{print $1}')
    Auto_key=$(echo "$Auto_key_line" | awk '{print $2}')
    if [[ "$Auto_key" == "$local_key" && "$local_modified_site" == "" ]]
    then
        echo "modified $local_key"
        sed -i "${line_no}s/${local_key}=.*/${local_key}=${local_value} #/g" "$auto_script"
    elif [[ "$Auto_key" == "$local_key" && "$local_modified_site" == "left" ]]
    then
        echo "test"
    elif [[  "$local_modified_site" == "right" ]]
    then
        sed -i "${line_no}s/${local_key}.*/${local_key}${local_value}/g" "$auto_script"
    else
        echo "error no $local_key in auto script"  && exit 1
    fi
}


function check_args(){
    local array="$1"
    local value="$2"
    [[ "$value" == "" || -z "$value" ]] && return 0
    local key_flag="false"
    echo "$array" | grep "\<$value\>" > /dev/null
    if [ "$?" == 0 ]
    then
        key_flag="true"
    fi
    if [ "$key_flag" == "false" ]
    then
        echo "$value value error" && exit 1
    fi
}


function check_arg_null(){
    local key="$1"
    local value="$2"
    if [[ "$value" == "" || -z "$value" ]]
    then
        echo "$key is empty !!!" && exit 1
    fi
}


function blank_check(){
    local var="$1"
    local kongge1_check=$(echo -n "$var" | grep " ")
    if [[ "$kongge1_check"  != "" || ! -z "$kongge1_check" ]]
    then
        echo "error ,blank space in $var"
        exit 1
    fi
}

function parse_option(){
    echo "parse_option"
    mkdir CODE  > /dev/null 2>&1
    while [[ $# -gt 1 ]]
    do
        key="$1"
        case "$key" in
            --code-url)
                readonly CODE_URL=$(echo "$2"| sed 's/^[ \t]*//g'| sed 's/[ \t]*$//g')
                echo "check code url"
                check_arg_null "CODE_URL" "$CODE_URL"
                ;;
            --code-branch)
                readonly CODE_BRANCH=$(echo "$2" | sed 's/^[ \t]*//g'| sed 's/[ \t]*$//g')
                echo "check code branch"
                check_arg_null "CODE_BRANCH" "$2"
                ;;
            --code-xml)
                readonly CODE_XML=$(echo "$2" | sed 's/^[ \t]*//g'| sed 's/[ \t]*$//g')
                echo "check code xml"
                check_arg_null "CODE_XML" "$CODE_XML"
                ;;
            --project-name)
                readonly PROJECT_NAME=$(echo "$2" | sed 's/^[ \t]*//g'| sed 's/[ \t]*$//g')      # E260L E296L
                echo "check project name"
                check_arg_null "PROJECT_NAME" "$PROJECT_NAME"
                ;;
            --variant)
                readonly VARIANT=$(echo "$2" | sed 's/^[ \t]*//g'| sed 's/[ \t]*$//g')   # eng  user
                echo "check variant"
                check_arg_null "VARIANT" "$VARIANT"
                check_args 'debug user eng' "$VARIANT"
                ;;
            --project-build-name)
                readonly PROJECT_BUILD_NAME=$(echo "$2" | sed 's/^[ \t]*//g'| sed 's/[ \t]*$//g')  #E260L_WW ZB500TL_CMCC
                echo "check project build name"
                check_arg_null "PROJECT_BUILD_NAME" "$PROJECT_BUILD_NAME"
                #check_args 'ZB500TL ZB500TL_CMCC ZB500TL_CTCC E260L E260L_CMCC E260L_CTCC E260L_CTCERT E260L_WW E262L E262L_CMCC E262L_CTCC E262L_WW D281L_US E286L_CMCC' "$PROJECT_BUILD_NAME"
                readonly PROJECT_BUILD_NAME_FIELD=$(echo "$PROJECT_BUILD_NAME" | awk -F "_" '{print NF}')
                if [ "$PROJECT_BUILD_NAME_FIELD" -ge 1 ]
                then
                    readonly OUT_PROJECT_NAME=$(echo "$PROJECT_BUILD_NAME" | awk -F "_" '{print $1}')
                    BUILD_PROJECT_NAME_END=$(echo "$PROJECT_BUILD_NAME" | awk -F "_" '{print $2}')
                    if [[ "$BUILD_PROJECT_NAME_END" == "" || -z "$BUILD_PROJECT_NAME_END" ]]
                    then
                        readonly BUILD_PROJECT_NAME_END="driveonly"
                    fi
                    echo "$OUT_PROJECT_NAME $BUILD_PROJECT_NAME_END"
                fi
                ;;
            --save-type)
                readonly SAVE_TYPE=$(echo "$2" | sed 's/^[ \t]*//g'| sed 's/[ \t]*$//g')
                echo "check save type"
                check_arg_null "SAVE_TYPE" "$SAVE_TYPE"
                check_args 'preofficial temp factory dailybuild' "$SAVE_TYPE"
                ;;
            --soft-ver)
                readonly SOFT_VER=$(echo "$2" | sed 's/^[ \t]*//g'| sed 's/[ \t]*$//g')
                echo "check soft ver"
                readonly IN_VER=$(echo "$SOFT_VER" | awk '{print $1}')
                readonly OUT_VER=$(echo "$SOFT_VER" | awk '{print $2}')
                readonly INCRE_VER=$(echo "$SOFT_VER" | awk '{print $3}')
                echo "$IN_VER \n  $OUT_VER \n $INCRE_VER"
                ;;
            --sign)
                readonly SIGN_FLAG=$(echo "$2" | sed 's/^[ \t]*//g'| sed 's/[ \t]*$//g')
                echo "check sign flag"
                ;;
            --b99-soft-ver)
                readonly B99_SOFT_VER=$(echo "$2" | sed 's/^[ \t]*//g'| sed 's/[ \t]*$//g')
                echo "check b99 soft ver"
                readonly B99_IN_VER=$(echo "$B99_SOFT_VER" | awk '{print $1}')
                readonly B99_OUT_VER=$(echo "$B99_SOFT_VER" | awk '{print $2}')
                readonly B99_INCRE_VER=$(echo "$B99_SOFT_VER" | awk '{print $3}')
                echo "$B99_INCRE_VER"
                ;;
            --fw-ver)
                readonly ASUSFW_VER=$(echo "$2" | sed 's/^[ \t]*//g'| sed 's/[ \t]*$//g')
                echo "check asusfw ver"
                ;;
            --wind-asusset-ver)
                readonly ASUSSETTING_VER=$(echo "$2" | sed 's/^[ \t]*//g'| sed 's/[ \t]*$//g')
                echo "check asussetting ver"
                ;;
            --hw-ver)
                readonly HW_VER=$(echo "$2" | sed 's/^[ \t]*//g'| sed 's/[ \t]*$//g')
                echo "check hw ver"
                echo "$HW_VER"
                ;;
            --paste-ver-fota1)
                readonly PASTE_FULL_DIR_WINDOWS1=$(echo "$2" | sed 's/^[ \t]*//g'| sed 's/[ \t]*$//g')
                echo "check paste ver fota1"
                blank_check "$PASTE_FULL_DIR_WINDOWS1"
                readonly PASTE_FULL_DIR_LINUX1="${PASTE_FULL_DIR_WINDOWS1//\\/\/}"
                ;;
            --paste-ver-fota2)
                readonly PASTE_FULL_DIR_WINDOWS2=$(echo "$2" | sed 's/^[ \t]*//g'| sed 's/[ \t]*$//g')
                echo "check paste ver fota2"
                blank_check "$PASTE_FULL_DIR_WINDOWS2"
                readonly PASTE_FULL_DIR_LINUX2="${PASTE_FULL_DIR_WINDOWS2//\\/\/}"
                ;;
            --paste-ver-fota3)
                readonly PASTE_FULL_DIR_WINDOWS3=$(echo "$2" | sed 's/^[ \t]*//g'| sed 's/[ \t]*$//g')
                echo "check paste ver fota3"
                blank_check "$PASTE_FULL_DIR_WINDOWS3"
                readonly PASTE_FULL_DIR_LINUX3="${PASTE_FULL_DIR_WINDOWS3//\\/\/}"
                ;;
            --paste-ver-fota4)
                readonly PASTE_FULL_DIR_WINDOWS4=$(echo "$2" | sed 's/^[ \t]*//g'| sed 's/[ \t]*$//g')
                echo "check paste ver fota4"
                blank_check "$PASTE_FULL_DIR_WINDOWS4"
                readonly PASTE_FULL_DIR_LINUX4="${PASTE_FULL_DIR_WINDOWS4//\\/\/}"
                ;;
            --paste-ver-fota5)
                readonly PASTE_FULL_DIR_WINDOWS5=$(echo "$2" | sed 's/^[ \t]*//g'| sed 's/[ \t]*$//g')
                echo "check paste ver fota5"
                blank_check "$PASTE_FULL_DIR_WINDOWS5"
                readonly PASTE_FULL_DIR_LINUX5="${PASTE_FULL_DIR_WINDOWS5//\\/\/}"
                ;;
            --future-ver-fota)
                readonly FUTURE_FULL_DIR_WINDOWS=$(echo "$2" | sed 's/^[ \t]*//g'| sed 's/[ \t]*$//g')
                echo "check future ver fota"
                blank_check "$FUTURE_FULL_DIR_WINDOWS"
                readonly FUTURE_FULL_DIR_LINUX="${FUTURE_FULL_DIR_WINDOWS//\\/\/}"
                ;;
            --otapackage)
                readonly OTA_PACKAGE=$(echo "$2" | sed 's/^[ \t]*//g'| sed 's/[ \t]*$//g')
                echo "check otapackage"
                check_arg_null "OTA_PACKAGE" "$OTA_PACKAGE"
                check_args 'true false' "$OTA_PACKAGE"
                ;;
            --cid)
                readonly CID=$(echo "$2" | sed 's/^[ \t]*//g'| sed 's/[ \t]*$//g')
                echo "check cid"
               # check_args 'CMCC CTCC CKD ASUS' "$CID"
                ;;
            --debug-mod)
                readonly DEBUG_MOD=$(echo "$2" | sed 's/^[ \t]*//g'| sed 's/[ \t]*$//g')
                echo "check debug-mod"
                check_args 'true false' "$DEBUG_MOD"
                ;;
            --build-b99)
                readonly BUILD_B99=$(echo "$2" | sed 's/^[ \t]*//g'| sed 's/[ \t]*$//g')
                echo "check b99"
                check_args 'true false' "$BUILD_B99"
                ;;
            --snapshot)
                readonly UPLOAD_SNAPSHOT=$(echo "$2" | sed 's/^[ \t]*//g'| sed 's/[ \t]*$//g')
                echo "upload snapshot"
                check_args 'true false' "$UPLOAD_SNAPSHOT"
                ;;
            --wait-build)
                readonly WAIT_BUILD=$(echo "$2" | sed 's/^[ \t]*//g'| sed 's/[ \t]*$//g')
                echo "wait build"
                check_args 'true false' "$UPLOAD_SNAPSHOT"
                ;;
            *)
                echo "error"
                exit 1
                ;;
        esac
        shift;shift
    done
    
    for myvar in "${OPTION_VAR_ARRAY[@]}"
    do
        eval "[ -z \${${myvar}+x} ]"
        if [ "$?" == 0 ]
        then
            echo "args empty"
            exit 1
        fi
    done
}


function download_code(){
    echo "download_code"
    local mirror_path=""
    mirror_path_len="${#mirror_path_array[@]}"
    host_name_len="${#HOST_NAME_ARRAY[@]}"
    if [ "$mirror_path_len" == "$host_name_len" ]
    then
        local seq_len=$((mirror_path_len - 1))
        for i in `seq 0 $seq_len`
        do
            if [ "$HOSTNAME" == "${HOST_NAME_ARRAY[$i]}" ]
            then
                readonly mirror_path="${mirror_path_array[$i]}"
                break
            fi
        done
    fi
    
    pushd "$ROOT/CODE"
        cp ../SCM_script/checksum.zip .
        cp ../SCM_script/release_version_new.sh .
        if [[ ! -s "checksum.zip" || ! -s "release_version_new.sh"  ]]
        then
            echo "error,need checksum.zip or release_version_new.sh"
        fi
        case "$PROJECT_NAME" in
            E260L|E262L|E286L|E266L)
                if [ -d "${mirror_path}/260_mirror_repo" ]
                then
                    pushd "${mirror_path}/260_mirror_repo"
                        repo sync  || repo sync || repo sync
                    popd
                    echo "" | repo init -u "$CODE_URL" -b "$CODE_BRANCH" -m "$CODE_XML" --reference="${mirror_path}/260_mirror_repo"
                    [ $? != 0 ] && echo "error, repo init failed" && exit 1
                else
                    echo "" | repo init -u "$CODE_URL" -b "$CODE_BRANCH" -m "$CODE_XML"
                    [ $? != 0 ] && echo "error, repo init failed" && exit 1
                fi
                ;;
            E281L|D281L|E296L)
                if [ -d "${mirror_path}/296_mirror_repo" ]
                then
                    pushd "${mirror_path}/296_mirror_repo"
                        repo sync  || repo sync || repo sync
                    popd
                    echo "" | repo init -u "$CODE_URL" -b "$CODE_BRANCH" -m "$CODE_XML" --reference="${mirror_path}/296_mirror_repo"
                    [ $? != 0 ] && echo "error, repo init failed" && exit 1
                else
                    echo "" | repo init -u "$CODE_URL" -b "$CODE_BRANCH" -m "$CODE_XML"
                    [ $? != 0 ] && echo "error, repo init failed" && exit 1
                fi
                ;;
            *)
                echo "" | repo init -u "$CODE_URL" -b "$CODE_BRANCH" -m "$CODE_XML"
                [ $? != 0 ] && echo "error, repo init failed" && exit 1
                ;;
        esac
            repo sync -j8 || sleep 60s && repo sync -j8 || sleep 60s && repo sync -j8
            [ $? != 0 ] && echo "error, repo sync failed" && exit 1
            repo start "$CODE_BRANCH" --all
        cp wind/scripts/Auto_MT*.sh .
        auto_script=$(ls Auto_MT67* | head -1)
    popd
}


function build_code(){
    echo "build_code"
    pushd "$ROOT/CODE"
        if [ "$OTA_PACKAGE" == "true" ]
        then
            echo -e "2 3" >  input.txt
            local -r lino=$(grep -n "readonly final_release_param=" release_version_new.sh | awk -F ":" '{print $1}')
            sed -i "${lino}s/readonly final_release_param=.*/readonly final_release_param='all ota'/g" release_version_new.sh
            if [ "$?" != 0 ]
            then
                echo "release_version_new.sh script modified error" && exit 1
            fi
        else
            echo -e "2" > input.txt
            local -r lino1=$(grep -n "readonly final_release_param=" release_version_new.sh | awk -F ":" '{print $1}')
            sed -i "${lino1}s/readonly final_release_param=.*/readonly final_release_param='all'/g" release_version_new.sh
            if [ "$?" != 0 ]
            then
                echo "release_version_new.sh script modified error" && exit 1
            fi
        fi

        rm ~/project.info
        echo "" >> input.txt
        ./$auto_script < input.txt
        if [ "$?" != 0 ]
        then
            echo "error,auto_script error!!!!"
            exit 1
        fi


        local -r success=$(tail build-log/build.log  | grep "success")
        [[ "$success" == "" || -z "$success" ]] && echo "code build error!!!" && exit 1

        rm input.txt
        rm /data/mine/"test"/"MT6572"/"$MY_NAME"/*
        rm -rf /tmp/*
        echo "sleep 30s" && sleep 30s #预防之前释放的文件删除之后继续释放

        case "$SAVE_TYPE" in
        "preofficial" | "factory" | "temp")
            echo "type=${SAVE_TYPE}" > ~/project.info
            echo "project=${PROJECT_NAME}" >> ~/project.info
            echo "custom=${BUILD_PROJECT_NAME_END}" >> ~/project.info
            if [ -d "/jenkins/"$SAVE_TYPE"_version/"$PROJECT_NAME"/"$BUILD_PROJECT_NAME_END"/"$IN_VER"" ]
            then
                echo "version=${IN_VER}_${Random}" >> ~/project.info
            else
                echo "version=${IN_VER}" >> ~/project.info
            fi
            ;;
        "dailybuild")
            echo "type=${SAVE_TYPE}" > ~/project.info
            echo "project=${PROJECT_NAME}" >> ~/project.info
            echo "custom=${BUILD_PROJECT_NAME_END}" >> ~/project.info
            if [ -d "/jenkins/"$SAVE_TYPE"_version/"$PROJECT_NAME"/"${BUILD_PROJECT_NAME_END}_dailybuild"/"$TODAY"" ]
            then
                echo "version=${TODAY}_${Random}" >> ~/project.info
            else
                echo "version=${TODAY}" >> ~/project.info
            fi
            echo "option=custom:${BUILD_PROJECT_NAME_END}_dailybuild" >> ~/project.info
            ;;
        "*");;
        esac

    popd
}


function modified_sign_UL(){
    local -r old_value="$1"
    local -r new_value="$2"
    pushd "${ROOT}/CODE"
        pushd "out/target/product/${OUT_PROJECT_NAME}/"
            local UL_old_name=$(ls full* -t | head -1 )
            rm -rf ota_back_dir && mkdir ota_back_dir
            cp "$UL_old_name" ota_back_dir

            rm -rf META-INF/ && mkdir -p META-INF/com/google/android/
            unzip -j "$UL_old_name" 'META-INF/com/google/android/updater-script' -d "META-INF/com/google/android/"
            sed -i "s/$old_value/$new_value/g" "META-INF/com/google/android/updater-script"
            if [ "$?" != 0 ]
            then
                echo "error: modified 260 ul sign failed"
                return 1
            fi
            zip "$UL_old_name" -f 'META-INF/com/google/android/updater-script'
            if [ "$?" != 0 ]
            then
                echo "error: zip 260 ul sign failed"
                rm -rf "$UL_old_name" && mv ota_back_dir/"$UL_old_name" . && rm -rf ota_back_dir
                return 1
            fi
            mv "$UL_old_name" "${ROOT}/CODE"
            rm -rf META-INF
        popd

        sign_tool=out/host/linux-x86/framework/signapk.jar
        sign_key1=device/mediatek/common/security/"$OUT_PROJECT_NAME"/releasekey.x509.pem
        sign_key2=device/mediatek/common/security/"$OUT_PROJECT_NAME"/releasekey.pk8
        echo "please wait..."
        file_name=$(echo "$UL_old_name" | sed -r 's/\.zip$//i')
        java -Djava.library.path=out/host/linux-x86/lib64 -jar $sign_tool -w $sign_key1 $sign_key2 $UL_old_name ${file_name}_signed.zip
        echo "sign $file to ${file_name}_signed.zip done"
        echo "All done."
        mv ${file_name}_signed.zip out/target/product/E260L/"$UL_old_name"
    popd
}

function check_260_sign_UL(){
    echo "check_260_sign_UL"
    if [[ "$OUT_PROJECT_NAME" == "E260L"  && "$BUILD_PROJECT_NAME_END" == "CMCC" ]]
    then
        modified_sign_UL "ASUS-ASUS_X018DC-CN" "CMCC-ASUS_X018DC-CN"
    elif [[ "$OUT_PROJECT_NAME" == "E260L"  && "$BUILD_PROJECT_NAME_END" == "CTCC" ]]
    then
        modified_sign_UL "ASUS-ASUS_X018DC-CN" "CTCC-ASUS_X018DC-CN"
    fi
}

function modified_auto_scritp_args(){
    echo "modified_auto_scritp_args"
    pushd "$ROOT/CODE"
        modified_auto_args "VARIANT" "$VARIANT"
        modified_auto_args "BUILD_PROJECT" "$PROJECT_BUILD_NAME"
        modified_auto_args "BUILD_PROJECT_NAME" "$OUT_PROJECT_NAME"
        modified_auto_args "RELEASE_PROJECT" "$OUT_PROJECT_NAME"
        modified_auto_args "PRODUCT_NAME=full_" "$OUT_PROJECT_NAME" "right"
        if [ "$BUILD_PROJECT_NAME_END" == "driveonly" ]
        then
            modified_auto_args "VERSION_FILE=version" "" "right"
        else
            modified_auto_args "VERSION_FILE=version" "$BUILD_PROJECT_NAME_END" "right"
        fi
        if [ "$SAVE_TYPE" == "dailybuild" ]
        then
            modified_auto_args "IN_VERSION" "${IN_VER}_${TODAY}"
        else
            modified_auto_args "IN_VERSION" "$IN_VER"
        fi
        modified_auto_args "OUT_VERSION" "$OUT_VER"
        modified_auto_args "INCREMENTAL_VERSION" "$INCRE_VER"
        if [[ "$ASUSFW_VER" != "" && ! -z "$ASUSFW_VER" ]]
        then
            modified_auto_args "ASUSFW_VERSION" "$ASUSFW_VER"
        fi
        if [[ "$ASUSSETTING_VER" != "" && ! -z "$ASUSSETTING_VER" ]]
        then
            modified_auto_args "WIND_ASUSSETTINGSSRC_VERSION" "$ASUSSETTING_VER"
        fi
        if [[ "$SIGN_FLAG" != "" && ! -z "$SIGN_FLAG" ]]
        then
            modified_auto_args "SIGN_FLAG" "$SIGN_FLAG"
        fi
        modified_auto_args "CORE" "24"
        case "$PROJECT_NAME" in
            E260L|E262L)
                     if [[ ! -z "$CID" || "$CID" != "" ]]
                     then
                         modified_auto_args "CID" "$CID"
                     fi
                     ;;
            *) 
                echo "general job"
                ;;
        esac
        case "$PROJECT_NAME" in
            E281L|D281L|E280L|D280L)
                modified_auto_args "KK_CODE_SIGN_FOTA" "no"
                ;;
            *)
                echo "general job"
                ;;
       esac
    popd
}


function release_version(){
echo "release_version"
if [ "$DEBUG_MOD" == "false" ]
then
    SIGN_ARRAY=(E260L_CMCC E260L_CTCC E260L_CTCERT E262L_WW E266L_CMCC ZB500TL_CMCC ZB500TL_CTCC D281L_US E286L_CMCC E281L_TW E286L_IN E286L_CTCC E286L_CTCCMP D281L_WW D281L_JP D281L_ID E281L_ID D281L_TW)
    for i in "${SIGN_ARRAY[@]}"
    do
        if [ "$i" == "$PROJECT_BUILD_NAME" ]
        then
            sign_flag="true"
            break
        else
            sign_flag="false"
        fi
    done
    pushd "$ROOT/CODE"
        if [ "$sign_flag" == "true" ]
        then
            ./release_version_new.sh "$OUT_PROJECT_NAME" "symbols" "sign" "zip"
            [ "$?"  != 0 ] && echo "error,release_version.sh error!!!!" && exit 1
        else
            ./release_version_new.sh "$OUT_PROJECT_NAME" "symbols" "zip"
            [ "$?"  != 0 ] && echo "error,release_version.sh error!!!!" && exit 1
        fi
        if [[ ! -z "$ASUSFW_VER" && "$ASUSFW_VER" != "" ]]
        then
            ./quick_build.sh "$PROJECT_BUILD_NAME" asusfw_otapackage user
            [ "$?" != 0 ] && echo "build asusfw_otapackage error" && exit 1
        fi
    popd
else
    echo "do not release_anyfile"
fi
}


function copy_fota(){
echo "copy_fota"

if [[ "$OTA_PACKAGE" == "true" &&  "$PASTE_FULL_DIR_WINDOWS1" != "" ||  "$PASTE_FULL_DIR_WINDOWS2" != "" || "$PASTE_FULL_DIR_WINDOWS3" != "" || "$FUTURE_FULL_DIR_WINDOWS" != ""  ]]
then
    pushd "$ROOT/CODE"
        if [  -f /jenkins/$PASTE_FULL_DIR_LINUX1 ]
        then
            echo "copy update_a1"
            cp /jenkins/$PASTE_FULL_DIR_LINUX1 update_a1.zip
            [ $? != 0 ] && echo "error, cp $PASTE_FULL_DIR_LINUX1 failed" && exit 1
        fi

        if [ -f /jenkins/$PASTE_FULL_DIR_LINUX2 ]
        then
            echo "copy update_a2"
            cp /jenkins/$PASTE_FULL_DIR_LINUX2 update_a2.zip
            [ $? != 0 ] && echo "error, cp $PASTE_FULL_DIR_LINUX1 failed" && exit 1
        fi

        if [ -f /jenkins/$PASTE_FULL_DIR_LINUX3 ]
        then
            echo "copy update_a3"
            cp /jenkins/$PASTE_FULL_DIR_LINUX3 update_a3.zip
            [ $? != 0 ] && echo "error, cp $PASTE_FULL_DIR_LINUX3 failed" && exit 1
        fi
        
        if [ -f /jenkins/$PASTE_FULL_DIR_LINUX4 ]
        then
            echo "copy update_a4"
            cp /jenkins/$PASTE_FULL_DIR_LINUX4 update_a4.zip
            [ $? != 0 ] && echo "error, cp $PASTE_FULL_DIR_LINUX4 failed" && exit 1
        fi

        if [ -f /jenkins/$PASTE_FULL_DIR_LINUX5 ]
        then
            echo "copy update_a5"
            cp /jenkins/$PASTE_FULL_DIR_LINUX5 update_a5.zip
            [ $? != 0 ] && echo "error, cp $PASTE_FULL_DIR_LINUX5 failed" && exit 1
        fi

        if [ -f /jenkins/$FUTURE_FULL_DIR_LINUX ]
        then
            echo "copy update_c"
            cp /jenkins/$FUTURE_FULL_DIR_LINUX update_c.zip
            [ $? != 0 ] && echo "error, cp $FUTURE_FULL_DIR_LINUX failed" && exit 1
        fi
    popd
fi
}


function do_fota(){
echo "do_fota"
if [[ "$OTA_PACKAGE" == "true" &&  "$PASTE_FULL_DIR_WINDOWS1" != "" ||  "$PASTE_FULL_DIR_WINDOWS2" != "" || "$PASTE_FULL_DIR_WINDOWS3" != "" || "$FUTURE_FULL_DIR_WINDOWS" != ""  ]]
then
    pushd "$ROOT/CODE"
        rm -rf fota_dir
        for update_a in `ls update_a*`
        do
            echo "$update_a"
            mv $update_a update_a.zip
            echo "4" > input.txt
            echo "Y" >> input.txt
            ./"$auto_script" < input.txt
            [ $? != 0 ] && echo "do fota error" && exit 1

            local lino2=$(grep -n "readonly final_release_param=" release_version_new.sh | awk -F ":" '{print $1}')
            sed -i "${lino2}s/readonly final_release_param=.*/readonly final_release_param='diff'/g" release_version_new.sh
            if [ "$?" != 0 ]
            then
                echo "release_version_new.sh script modified error" && exit 1
            fi
            ./release_version_new.sh "$OUT_PROJECT_NAME" zip

            local fota_names=$(ls back_up_version_temp*)
            pushd back_up_version_temp*
                for fota_name in "$fota_names"
                do
                    md5sum -b $fota_name | tee -a "../out/target/product/$OUT_PROJECT_NAME/checklist.md5"
                done
            popd

            mkdir fota_dir
            mv update_a.zip fota_dir/$update_a
            mv update_c.zip fota_dir/ #only mv for fisrt time
            mv updateA2B.zip fota_dir/${update_a}_fota
            mv updateB2C.zip fota_dir/ #only mv for fisrt time
        done
    popd
fi
}


function version_back_up(){
    if [ -d "/home1/SW3/" ]
    then
        mkdir -p /home1/SW3/version_back_up
        if [ -d "/home1/SW3/version_back_up" ]
        then
            mkdir -p /home1/SW3/version_back_up/"${PROJECT_NAME}_${TODAY}_${Random}"
            cp '/data/mine/test/MT6572/jenkins/'* /home1/SW3/version_back_up/"${PROJECT_NAME}_${TODAY}_${Random}"/
        else
            echo "version back up failed"
        fi
    fi
}


function md5_check_file(){
    echo "md5_check_file"
    pushd "$ROOT/CODE"
        local status="true"
        local -r DEST_DIR=$(cat ~/project.info  | grep version | head -1 | awk -F "=" '{print $2}')
        while "$status"
        do
           case "$SAVE_TYPE" in
               "preofficial" | "factory" | "temp")
                   ls -al /jenkins/"$SAVE_TYPE"_version/"$PROJECT_NAME"/"$BUILD_PROJECT_NAME_END"/"$DEST_DIR" | tee same_state1
                   sleep 20s
                   ls -al /jenkins/"$SAVE_TYPE"_version/"$PROJECT_NAME"/"$BUILD_PROJECT_NAME_END"/"$DEST_DIR" | tee same_state2
                   ;;
               "dailybuild")
                   ls -al /jenkins/"$SAVE_TYPE"_version/"$PROJECT_NAME"/"${BUILD_PROJECT_NAME_END}_dailybuild"/"$DEST_DIR" | tee same_state1
                   sleep 20s
                   ls -al /jenkins/"$SAVE_TYPE"_version/"$PROJECT_NAME"/"${BUILD_PROJECT_NAME_END}_dailybuild"/"$DEST_DIR" | tee same_state2
                   ;;
               *)
                   echo "error,do not support $SAVE_TYPE"
                   exit 1
                   ;;
           esac
           local state1=$(md5sum same_state1 | awk '{print $1}')
           local state2=$(md5sum same_state2 | awk '{print $1}')
           if [ "$state1" == "$state2" ]
           then
               status="false"
               rm same_state1 same_state2
           fi
        done
        
        case "$SAVE_TYPE" in
            "preofficial" | "factory" | "temp")
            pushd  /jenkins/"$SAVE_TYPE"_version/"$PROJECT_NAME"/"$BUILD_PROJECT_NAME_END"/"$DEST_DIR"
            ;;
            "dailybuild")
            pushd  /jenkins/"$SAVE_TYPE"_version/"$PROJECT_NAME"/"${BUILD_PROJECT_NAME_END}_dailybuild"/"$DEST_DIR"
            ;;
            *)
            echo "error,do not support $SAVE_TYPE"
            exit 1
            ;;
        esac
                for local_file in `ls`
                do
                    local md5value=$(md5sum $local_file | awk '{print $1}')
                    if [  "$local_file" == "checklist.md5" ]
                    then
                        continue
                    fi
                    local filename=$(grep $md5value "checklist.md5" | awk -F "*" '{print $2}' | head -1)
                    if [ "$local_file" == "$filename" ]
                    then
                        echo "$filename md5 check ok!"
                    else
                        echo "error,$filename md5 check failed!"
                        version_back_up
                        exit 1
                    fi
                done
            popd
    popd
}


function do_snapshot(){
    echo "do_snapshot"
    pushd "$ROOT"/CODE
        repo manifest -ro "manifest-${IN_VER}_${TODAY}.xml"
        md5sum -b "manifest-${IN_VER}_${TODAY}.xml" | tee -a "out/target/product/$OUT_PROJECT_NAME/checklist.md5"
        cp manifest-* /data/mine/"test"/"MT6572"/"jenkins"/
        cp "out/target/product/$OUT_PROJECT_NAME/checklist.md5" /data/mine/"test"/"MT6572"/"jenkins"
        if [[ -d "wind/scripts" && "$UPLOAD_SNAPSHOT" == "true" ]]
        then
            pushd "wind"
                git clean -dfx
                git reset --hard
            popd > /dev/null

            pushd "wind/snapshot"
                cp "$ROOT"/CODE/"manifest-${IN_VER}_${TODAY}.xml" .
                git add .
                git commit -m "[$PROJECT_NAME] add snapshot manifest-${IN_VER}_${TODAY}.xml"
                git pull --rebase
                echo 'y' | repo upload .
            popd > /dev/null
        fi
    popd
}

function build_B99(){
echo "build_B99"
if [[ "$BUILD_B99" == "true" && "$B99_IN_VER" != "" && ! -z "$B99_IN_VER" && "$DEBUG_MOD" == "false" ]]
then
    pushd "${ROOT}/CODE"
        mv ~/project.info ~/project.info_back_up
        cp out/target/product/${OUT_PROJECT_NAME}/checklist.md5 checklist.md5_back_up
        rm update_a.zip
        local old_update_b=$(ls out/target/product/${OUT_PROJECT_NAME}/obj/PACKAGING/target_files_intermediates/full_*.zip | head -1)
        cp "$old_update_b" update_a.zip
        if [ "$BUILD_PROJECT_NAME_END" == "driveonly" ]
        then
            sed -i '1s/.*/INVER='"$B99_IN_VER"'/'    ./device/ginreen/$OUT_PROJECT_NAME/version
            sed -i '2s/.*/OUTVER='"$B99_OUT_VER"'/'    ./device/ginreen/$OUT_PROJECT_NAME/version
            sed -i '5s/.*/INCREMENTALVER='"$B99_INCRE_VER"'/'    ./device/ginreen/$OUT_PROJECT_NAME/version
        else
            sed -i '1s/.*/INVER='"$B99_IN_VER"'/'    ./device/ginreen/$OUT_PROJECT_NAME/version"${BUILD_PROJECT_NAME_END}"
            sed -i '2s/.*/OUTVER='"$B99_OUT_VER"'/'    ./device/ginreen/$OUT_PROJECT_NAME/version"${BUILD_PROJECT_NAME_END}"
            sed -i '5s/.*/INCREMENTALVER='"$B99_INCRE_VER"'/'    ./device/ginreen/$OUT_PROJECT_NAME/version"${BUILD_PROJECT_NAME_END}"
        fi
        modified_auto_args "ACTION" "remake"
        echo "2 3 4" > input.txt
        echo "Y" >> input.txt
        echo "" >> input.txt
        ./$auto_script < input.txt
        if [ "$?" != 0 ]
        then
            echo "error,auto_script error!!!!"
            exit 1
        fi

        check_260_sign_UL

        rm input.txt updateB2C.zip
        rm /data/mine/"test"/"MT6572"/"$MY_NAME"/*
        rm -rf /tmp/*
        
        local lino2=$(grep -n "readonly final_release_param=" release_version_new.sh | awk -F ":" '{print $1}')
        sed -i "${lino2}s/readonly final_release_param=.*/readonly final_release_param='ota diff'/g" release_version_new.sh
        if [ "$?" != 0 ]
        then
            echo "release_version_new.sh script modified error" && exit 1
        fi
        mv ~/project.info_back_up ~/project.info
        sed -i '4,$d' "out/target/product/$OUT_PROJECT_NAME/checklist.md5"
        ./release_version_new.sh "$OUT_PROJECT_NAME" zip
        local fota_names=$(ls back_up_version_temp*)
        pushd back_up_version_temp*
            for fota_name in "$fota_names"
            do
                md5sum -b $fota_name | tee -a "../out/target/product/$OUT_PROJECT_NAME/checklist.md5"
            done
        popd
        sed -n '4,$p' checklist.md5_back_up >> out/target/product/$OUT_PROJECT_NAME/checklist.md5
        cp out/target/product/$OUT_PROJECT_NAME/checklist.md5 .
        cp out/target/product/$OUT_PROJECT_NAME/checklist.md5 /data/mine/"test"/"MT6572"/"$MY_NAME"/        
    popd
    md5_check_file
fi
}

function down_load_262_modem(){
if [ "$PROJECT_NAME" == "E262L" ]
then
    echo "down_load_262_modem"
    modem_git_repository_name='GR6750_66_A_N_LWCTG_MP3_MOLY.LR11.W1603.MD.MP.V35.4'
    pushd "${ROOT}"
        rm -rf "modem262" && mkdir "modem262"
        pushd "modem262"
            echo "" | repo init -u git@10.0.30.8:GR6750_66_A_N_SW3/modem/tools/manifest.git -b PDU3
            repo sync
            if [ "$?" != 0 ]
            then
                echo "down 262modem failed" && exit 1
            fi

            pushd "${modem_git_repository_name}/mcu"
                echo "reset modem successful"
                local out_version_num=$(echo "$OUT_VER" | awk -F '-' '{print $2}')
                sed -i "s/14.02[0-9.]*/$out_version_num/g" "pcore/custom/modem_E262LWW/common/ps/custom_imc_config.c"
                ./makeLWCTG.sh E262LWW
                if [ "$?" == 0 ]
                then
                    rm "${ROOT}"/CODE/wind/custom_files/vendor/mediatek/proprietary/modem/E262LWW_LWCTG_CBON/*
                    cp OUT/GR6750_66_A_N_LWCTG_MP3_E262LWW/* "${ROOT}"/CODE/wind/custom_files/vendor/mediatek/proprietary/modem/E262LWW_LWCTG_CBON/
                else
                    echo "modem build failed" && exit 1
                fi
            popd
        popd
    popd
fi
}

function wait_build(){
    if [ "$WAIT_BUILD" == "true" ]
    then
        echo "wait_build"
        pushd "${ROOT}/CODE"
            while true
            do
                echo "we are wating now !!!" && sleep 20s
                if [ -f "startbuild" ]
                then
                    break
                fi
            done
        popd > /dev/null
    fi
}
#####main####
clean_environment
parse_option "$@"
copy_fota
download_code
down_load_262_modem
wait_build
modified_auto_scritp_args
build_code
check_260_sign_UL
release_version
do_fota
if [ "$DEBUG_MOD" == "false" ]
then
    do_snapshot
    md5_check_file
else
    echo "do not do snapshot"
fi
build_B99
