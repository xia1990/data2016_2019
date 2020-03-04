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
    DEBUG_MOD
)


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
                ;;
            --code-branch)
                readonly CODE_BRANCH=$(echo "$2" | sed 's/^[ \t]*//g'| sed 's/[ \t]*$//g')
                echo "check code branch"
                ;;
            --code-xml)
                readonly CODE_XML=$(echo "$2" | sed 's/^[ \t]*//g'| sed 's/[ \t]*$//g')
                echo "check code xml"
                ;;
            --project-name)
                echo "debug $2"
                readonly PROJECT_NAME="$2"
                ;;
            --variant)
                VARIANT=$(echo "$2" | sed 's/^[ \t]*//g'| sed 's/[ \t]*$//g')   # eng  user
                echo "check variant"
                ;;
            --project-build-name)
                readonly PROJECT_BUILD_NAME=$(echo "$2" | sed 's/^[ \t]*//g'| sed 's/[ \t]*$//g')  #E260L_WW ZB500TL_CMCC
                echo "check project build name"
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
            --otapackage)
                readonly OTAPACKAGE=$(echo "$2" | sed 's/^[ \t]*//g'| sed 's/[ \t]*$//g')
                echo "check otapackage"
                ;;
            --save-type)
                readonly SAVE_TYPE=$(echo "$2" | sed 's/^[ \t]*//g'| sed 's/[ \t]*$//g')
                echo "check save type"
                ;;
            --soft-ver)
                readonly SOFT_VER=$(echo "$2" | sed 's/^[ \t]*//g'| sed 's/[ \t]*$//g')
                echo "check soft ver"
                readonly IN_VER=$(echo "$SOFT_VER" | awk '{print $1}')
                readonly OUT_VER=$(echo "$SOFT_VER" | awk '{print $2}')
                echo -e "$IN_VER \n  $OUT_VER \n"
                ;;
            --debug-mod)
                readonly DEBUG_MOD=$(echo "$2" | sed 's/^[ \t]*//g'| sed 's/[ \t]*$//g')
                echo "check debug-mod"
                ;;
            --snapshot)
                readonly UPLOAD_SNAPSHOT=$(echo "$2" | sed 's/^[ \t]*//g'| sed 's/[ \t]*$//g')
                echo "upload snapshot"
                ;;
            --wait-build)
                readonly WAIT_BUILD=$(echo "$2" | sed 's/^[ \t]*//g'| sed 's/[ \t]*$//g')
                echo "wait build"
                ;;
            --efuse)
                readonly EFUSE=$(echo "$2" | sed 's/^[ \t]*//g'| sed 's/[ \t]*$//g')
                echo "efuse"
                ;;
            --gms)
                readonly GMS_PATH=$(echo "$2" | sed 's/^[ \t]*//g'| sed 's/[ \t]*$//g')
                LINUX_GMS_PATH="${GMS_PATH//\\/\/}"
                echo "gms $GMS_PATH"
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
    pushd "$ROOT"
        cp /jenkins/"$LINUX_GMS_PATH" .
        gms_zip=$(ls *.zip)
        gms_dir=$(echo $gms_zip | awk -F '.zip' '{print $1}')
        unzip "$gms_zip" -d "$gms_dir"
        rm -rf "$gms_zip"
    popd
    
    pushd "$ROOT/CODE"
        case "$PROJECT_NAME" in
            E630)
                if [ -d "${mirror_path}/630_mirror_repo" ]
                then
                    pushd "${mirror_path}/630_mirror_repo"
                        repoc sync -f || repoc sync -f
                    popd
                    echo "" | repoc init -u "$CODE_URL" -b "$CODE_BRANCH" -m "$CODE_XML" --reference="${mirror_path}/630_mirror_repo"
                    [ $? != 0 ] && echo "error, repo init failed" && exit 1
                else
                    echo "" | repoc init -u "$CODE_URL" -b "$CODE_BRANCH" -m "$CODE_XML"
                    [ $? != 0 ] && echo "error, repo init failed" && exit 1
                fi
                ;;
            E628)
                if [ -d "${mirror_path}/628_mirror_repo" ]
                then
                    pushd "${mirror_path}/628_mirror_repo"
                        repoc sync -f || repoc sync -f
                    popd
                    echo "" | repoc init -u "$CODE_URL" -b "$CODE_BRANCH" -m "$CODE_XML" --reference="${mirror_path}/628_mirror_repo"
                    [ $? != 0 ] && echo "error, repo init failed" && exit 1
                else
                    echo "" | repoc init -u "$CODE_URL" -b "$CODE_BRANCH" -m "$CODE_XML"
                    [ $? != 0 ] && echo "error, repo init failed" && exit 1
                fi
                ;;
            *)
                echo "" | repoc init -u "$CODE_URL" -b "$CODE_BRANCH" -m "$CODE_XML"
                [ $? != 0 ] && echo "error, repo init failed" && exit 1
                ;;
        esac
	    repoc sync -j2 -f || sleep 10s && repoc sync -j2 -f
            [ $? != 0 ] && echo "error, repo sync failed" && exit 1
            repoc start "$CODE_BRANCH" --all
    popd
}

function new_project_info(){
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
        esac
}

function build_code(){
    echo "build_code"
    pushd "$ROOT/CODE"
        rm ~/project.info
        #这里写quick_build.sh编译命令
        case "$PROJECT_NAME" in
        E630)
            if [ "$EFUSE" == "true" ]
            then
                ./quick_build.sh "$PROJECT_BUILD_NAME" all new "$VARIANT" gms efuse
            else
                ./quick_build.sh "$PROJECT_BUILD_NAME" all new "$VARIANT" gms
            fi
            local -r success=$(tail build-log/build.log  | grep "[sS]uccess")
            if [[ "$OTAPACKAGE" == "true" ]]
            then
                if [ "$EFUSE" == "true" ]
                then
                    ./quick_build.sh "$PROJECT_BUILD_NAME" otapackage "$VARIANT" gms efuse
                else
                    ./quick_build.sh "$PROJECT_BUILD_NAME" otapackage "$VARIANT" gms
                fi
            fi
        ;;
    	E628)
            VARIANT_BACK="$VARIANT" #quick_build.sh 中有同名变量
            if [ "$EFUSE" == "true" ]
            then
                source quick_build.sh && wind_lunch "$PROJECT_BUILD_NAME" new "$VARIANT_BACK" efuse && make -j24 2>&1 | tee build.log
            else
                source quick_build.sh && wind_lunch "$PROJECT_BUILD_NAME" new "$VARIANT_BACK" && make -j24 2>&1 | tee build.log
            fi
            VARIANT="$VARIANT_BACK"
            local -r success=$(tail build.log  | grep "[sS]uccess")
            if [[ "$OTAPACKAGE" == "true" && "$EFUSE" == "true" ]]
            then
                source vendor/mediatek/proprietary/scripts/sign-image/sign_image.sh
                make otapackage
            fi
	;;
        esac
        [[ "$success" == "" || -z "$success" ]] && echo "code build error!!!" && exit 1

        rm /data/mine/"test"/"MT6572"/"$MY_NAME"/*
        rm -rf /tmp/*
        echo "sleep 30s" && sleep 30s #预防之前释放的文件删除之后继续释放
    popd
}


function release_version(){
echo "release_version"
pushd "$ROOT/CODE"
if [ "$DEBUG_MOD" == "false" ]
then
    case "$PROJECT_NAME" in
    E630)
        if [ "$EFUSE" == "true" ]
        then
            ./release_version.sh E630 efuse zip
        else
            ./release_version.sh E630 zip
        fi
        if [ "$OTAPACKAGE" == "true" ]
        then
            ./release_version.sh E630 ota
        fi
    ;;
    E628)
        source vendor/mediatek/proprietary/scripts/sign-image/sign_image.sh
        if [ "$EFUSE" == "true" ]
        then
            ./release_version_efuse.sh E628 zip
        else
            ./release_version.sh E628 zip 
        fi
    ;;
    esac
    #这里写release_version.sh脚本释放命令
else
    echo "do not release_anyfile"
fi
popd
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
            if [ -s "checklist.md5" ]
            then
                md5sum -c checklist.md5
            fi
            popd
    popd
}


function do_snapshot(){
    echo "do_snapshot"
    pushd "$ROOT"/CODE
        repo manifest -ro "manifest-${IN_VER}_${TODAY}.xml"
	if [ "$OUT_PROJECT_NAME" == "D630" ]
	then
	    md5sum -b "manifest-${IN_VER}_${TODAY}.xml" | tee -a "out/target/product/msm8937_64/checklist.md5"
	else
	    md5sum -b "manifest-${IN_VER}_${TODAY}.xml" | tee -a "out/target/product/$OUT_PROJECT_NAME/checklist.md5"
	fi
        cp manifest-* /data/mine/"test"/"MT6572"/"jenkins"/
        cp "out/target/product/$OUT_PROJECT_NAME/checklist.md5" /data/mine/"test"/"MT6572"/"jenkins"
    popd
}

function modified_cpucore(){
    echo "modified_cpucore"
    pushd "$ROOT"/CODE
        if [ "$PROJECT_NAME" == "E630" ]
        then
            sed -i 's/CPUCORE=[0-8]*/CPUCORE=24/g' quick_build.sh
        fi
    popd
}


function modified_versionno(){
    echo "modified_versionno"
    pushd "$ROOT"/CODE
        if [ "$PROJECT_NAME" == "E630" ]
        then
            sed -i "s/INVER=.*/INVER=$IN_VER/g" wind/D615/GIG-8937/version
            sed -i "s/OUTVER=.*/OUTVER=$OUT_VER/g" wind/D615/GIG-8937/version
        elif [ "$PROJECT_NAME" == "E628" ]
        then
            sed -i "s/VER_OUTER=.*/VER_OUTER=$OUT_VER/g" wind/"$OUT_PROJECT_NAME"/"$BUILD_PROJECT_NAME_END"/config/ProjectConfig.mk 
            sed -i "s/VER_INNER=.*/VER_INNER=$IN_VER/g" wind/"$OUT_PROJECT_NAME"/"$BUILD_PROJECT_NAME_END"/config/ProjectConfig.mk 
        fi
    popd
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
parse_option "$@" #参数解析
download_code #下载代码 
wait_build #等待编译,提供手动修改的时间
modified_cpucore #修改cpu编译时间
modified_versionno #修改版本号
build_code #开始编译
new_project_info #新建 释放配置文件 ~/project.info
release_version #释放版本
if [ "$DEBUG_MOD" == "false" ]
then
    do_snapshot
    md5_check_file
else
    echo "do not do snapshot"
fi
