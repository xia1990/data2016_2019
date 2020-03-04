#!/bin/bash
#Transsion Top Secret

###############################
###### CONSTANTS SECTION ######
###############################
readonly SCRIPTDIR="$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)"
readonly OPTION_VAR_ARRAY=(
    CODE_DIR
    MANIFEST_XML_NAME_PREFIX
    PROJECT_NAME
    ARCHIVE_PRODUCT_DIR_RELATIVE
    MANIFEST_DIRECTORY
    BASE_URL
    MANIFEST_BRANCH
    CHECKSUM_UTIL_DIR
    ARCHIVE_BASE_DIR
    BUILD_MODE
    OTAPACKAGE
    DEBUG_MODE
    ARCHIVE_DIR_SUFFIX
    ARCHIVE_APK_HIOS
    ARCHIVE_APK_HIOS_REPOSITORY
    ARCHIVE_APK_HIOS_BRANCH
    PUSH_VERNO
    MODIFY_HIOS_APK_VERNO
    SET_MTK_LOADER_UPDATE
    FIX_VERSION_NUMBER
    CI_SMOKE_DIR
    LOCAL_ARCHIVE_DIR
    JIRA_CREATE_VERSION
    VERNO_DEBUG_SUFFIX
)


########################################
###### FUNCTION DECLARATION SECTION  ###
########################################
# shellcheck disable=SC1090
source "${SCRIPTDIR}"/commonlibs.sh
if [ "$?" != 0 ]
then
    echo "commonslibs.sh DOES NOT EXIST, EXIT ABNORMALLY"
    exit 1
fi

# enhanced error log version
function log_error2(){
    EXECUTE_STATUS=1
    log_error "$@"
}

function record_console_log(){
    local -r logfile="$1"
    is_safe_path "${logfile}"
    if [ "$?" != 0 ]
    then
        log_error2 "console log file name not safe: ${logfile}"
        return 1
    fi

    exec 1> >(tee "${logfile}") 2>&1
}


function try_repo_abandon(){
    # abandon local branch in case no clear job has been done
    if [ -n "${LOCAL_PROJECT_BRANCH_NAME}" ]
    then
        pushd "${CODE_DIR}"
            repo abandon "${LOCAL_PROJECT_BRANCH_NAME}" 2>/dev/null
        popd
    fi
}


# Universal exit funtions
# NOTICE: DO NOT "exit" DIRECTLY
function normal_exit()
{
    # abandon local branch in case no clear job has been done
    try_repo_abandon
    log_info "EXIT NORMALLY"
    exit 0
}


function abnormal_exit()
{
    # abandon local branch in case no clear job has been done
    try_repo_abandon

    log_error2 "EXIT ABNORMALLY"
    exit 1
}

function check_dir(){
    local DIR="$1"
    if [ ! -d "${DIR}" ]
    then
        log_error2 "${DIR} does not exist"
        abnormal_exit
    fi
}


# TODO: be more accurate
function guess_nas_path(){
    local -r MOUNT_POINT="$1"
    local -r NAS_DIR=$(python -c "import re; nasdir = re.search('SwVer[0-9]*', '${MOUNT_POINT}'); print nasdir.group(0) if nasdir is not None else ''")
    if [ -n "${NAS_DIR}" ]
    then
        echo  "\\\\192.168.1.75\\${NAS_DIR}"
    else
        echo ""
    fi
}


function local_to_nas_storage(){
    local -r LOCAL_STROAGE="$1"
    local -r NAS_STORAGE=$(echo "/""${LOCAL_STROAGE}" | sed 's/\//\\/g' |sed 's/mnt/192.168.1.75/g')

    echo "${NAS_STORAGE}"
}


function check_disk_space(){
    local -r MOUNT_POINT="$1"
    local -r THRESHOLD=100

    local -r REMAINING_SPACE_G=$(df -BG "${MOUNT_POINT}" | sed -n '2p' | awk '{print $4}' | sed 's/G//g')
    log_info "remaining disk space for ${MOUNT_POINT} is ${REMAINING_SPACE_G}G"
    if [ "${REMAINING_SPACE_G}" -lt "${THRESHOLD}" ]; then
        log_warning "服务器空间不足"
    else
        log_info "服务器空间良好"
    fi
}


function archive_cwd_zip(){
    local zipfilename="$1"
    is_safe_name_component "${zipfilename}"
    if [ $? != 0 ]
    then
        log_error2 "zip file name not safe: ${zipfilename}"
    fi

    P7ZIP=$(which 7z 2>/dev/null)
    if [ -n "${P7ZIP}" ]
    then
        log_info "zip using p7zip to speed up"
        "${P7ZIP}" a -tzip "${zipfilename}" ./* -mmt=on -mx1
    else
        log_info "zip using normal zip util"
        zip -r "${zipfilename}" ./*
    fi
}


function sync_code(){
    log_info "START SYNCING CODE NOW"
    sync_code_with_modes incremental
    if [ "$?" != 0 ]
    then
        log_warning "incremental sync code failed. try to do full sync now."
        sync_code_with_modes full
    fi

    check_dir "${CHECKSUM_UTIL_DIR}"
    check_dir "${PROJECT_DIR}"
}


function sync_code_with_modes(){
    # clean out the workspace and update the work
    # .repo can be reused
    local cmd
    local clear_code_command
    local mode=$1
    case "${mode}" in
        "incremental")
            clear_code_command="find . -maxdepth 1 ! -name '.repo' ! -name '.' ! -name '*.log' | xargs rm -rf"
            ;;
        "full")
            clear_code_command="find . -maxdepth 1 ! -name '.' ! -name '*.log' | xargs rm -rf"
            ;;
        *)
            log_error2 "unexpected sync code mode: ${mode}"
            abnormal_exit
            ;;
    esac

    pushd "${CODE_DIR}"
        if [ -d .repo/manifests ]
        then
            pushd .repo/manifests
                git reset --hard; git clean -fdx
            popd
        fi

        # need eval when pipeline occurs
        eval "${clear_code_command}"

        cmd="repo init -u ${BASE_URL} -b ${MANIFEST_BRANCH} -m ${MANIFEST_XML_NAME_PREFIX}.xml"
        log_info "execute cmd now: $cmd"
        $cmd
        if [ "$?" != 0 ]
        then
            if [ "$mode" == "incremental" ]
            then
                return 1
            else
                log_error2 "failed to execute command: $cmd"
                abnormal_exit
            fi
        fi

        cmd="repo sync  -c -d -j${CONCURRENT_SYNC_NUM}" # detached mode in case local branch has been modified manually.
        log_info "execute cmd now: $cmd"
        $cmd
        if [ "$?" != 0 ]
        then
            if [ "${mode}" == "incremental" ]
            then
                return 1
            else
                log_error2 "failed to execute command: $cmd"
                abnormal_exit
            fi
        fi

    popd

    return 0
}

function make_clean_snapshot(){
    log_info "MAKE A CLEAN SNAPSHOT NOW"
    pushd "${CODE_DIR}"
        pushd "${PROJECT_DIR}"
            local -r LAST_VERNO=$(grep MTK_BUILD_VERNO ProjectConfig.mk | sed 's/ //g' | sed 's/.*=//g'|sed 's/#.*$//g')
            readonly VERNO_DEL_DATE="${LAST_VERNO%-*}"
        popd
        readonly CLEAN_SNAPSHOT="${CODE_DIR}/${VERNO_DEL_DATE}-CLEAN-SNAPSHOT-${SNAP_TIME}.xml"

        repo manifest -r -o "${CLEAN_SNAPSHOT}"

        if [ $? != 0 ]
        then
            log_error2 "Do clean snapshot failed !!! : ${CLEAN_SNAPSHOT} "
        fi
    popd
}

function check_new_commit(){
    log_info "CHECK NEW COMMIT NOW"
    if [[ -n "$FIX_VERSION_NUMBER" || -n "$BUILD_USER" ]]
    then
        log_info "人为触发构建，或者固定版本号编译，退出校验新提交的检查"
        return 0
    else
        pushd "${MANIFEST_DIRECTORY}"
            local -r LAST_BUILD_XML=$(git log | grep "${VERNO_DEL_DATE}-[0-9]\{12\}\.xml" |grep "add snapshot for ${MANIFEST_XML_NAME_PREFIX} ${PROJECT_NAME} ${BUILD_MODE}"|grep -v 'Merge "'| sed -n "1p" | grep -aoE '[^ ]*.xml')
        popd
        if [ ! -z "${LAST_BUILD_XML}" ]
        then
            pushd "${CODE_DIR}"
                repo diffmanifests "${MANIFEST_DIRECTORY}"/"${LAST_BUILD_XML}" "${CLEAN_SNAPSHOT}" | grep '\[+\]' | grep -v 'HIOSWY-0 ver'
                local REPO_DIFF_STATUS=${PIPESTATUS[0]} FIND_NEW_COMMIT_STATUS=${PIPESTATUS[2]}
                if [ "${REPO_DIFF_STATUS}" != 0 ]
                then
                    log_error2 "repo diffmanifests failed, pls check your snapshot.xml and your code environment"
                elif [ "${FIND_NEW_COMMIT_STATUS}" != 0 ]
                then
                    log_info "距离上一次构建XML'${LAST_BUILD_XML}'没有更新，退出构建"
                    abnormal_exit
                else
                    log_info "CONTINUE TO BUILD NEXT"
                fi
            popd
        else
            log_info "COMPILE TYPE ${PROJECT_NAME} ${BUILD_MODE} HAS NOT BEEN BUILDED, CONTINUE TO BUILD"
        fi
    fi
}

function repo_start_project_dir(){
    log_info "REPO START PROJECT DIRECTORY NOW"
    pushd "${PROJECT_DIR}"
        cmd="repo start ${LOCAL_PROJECT_BRANCH_NAME} ."
        $cmd
        if [ "$?" != 0 ]
        then
            log_error2 "failed to execute command: $cmd"
            abnormal_exit
        fi
    popd
}


# TODO: sometimes it is not necessary
function modify_local_project_dir_verno(){
    log_info "MODIFY VERNO OF ProjectConfig.mk IN PROJECT DIRECTORY NOW"
    local -r TODAY=$(date +%y%m%d)
    pushd "${PROJECT_DIR}"
        if [ -n "${FIX_VERSION_NUMBER}" ]
        then
            sed -i "s/MTK_BUILD_VERNO = .*/MTK_BUILD_VERNO = ${FIX_VERSION_NUMBER}/" ProjectConfig.mk
            log_info "Fix version:${FIX_VERSION_NUMBER}"

            VERNO_GLOBAL="${FIX_VERSION_NUMBER}"
        else
            local -r VERNO=$(grep MTK_BUILD_VERNO ProjectConfig.mk | sed 's/ //g' | sed 's/.*=//g'|sed 's/#.*$//g')
            local -r VERNO_PREFIX=${VERNO%-*}
            local -r NUMBER_LAST=${VERNO##*V}  # CAUTION: use "##" instead of "#", otherwise we'll find a bug when google releases 'V' AOSP baseline.
            local -r NUMBER_NEXT=$((NUMBER_LAST + 1))
            local -r VERNO_NEXT="${VERNO_PREFIX}-${TODAY}V${NUMBER_NEXT}"
            log_info "VERNO_NEXT: ${VERNO_NEXT}"
            sed -i "s/MTK_BUILD_VERNO = .*/MTK_BUILD_VERNO = ${VERNO_NEXT}/" ProjectConfig.mk
            VERNO_GLOBAL="${VERNO_NEXT}"
            git add ProjectConfig.mk
            git commit -m " HIOSWY-0 ver ${VERNO_NEXT}"
            # TODO: maybe it's better to defer git-commit to try_push_verno
            if [ "$?" != 0 ]
            then
                log_error2 "failed to change verno locally."
                # compilation has not been started, exit fast.
                abnormal_exit
            fi
        fi

        if [[ -n "$FIX_VERSION_NUMBER" && -n "$VERNO_DEBUG_SUFFIX" ]]
        then
            sed -i "s/MTK_BUILD_VERNO = .*/MTK_BUILD_VERNO = ${FIX_VERSION_NUMBER}${VERNO_DEBUG_SUFFIX}/" ProjectConfig.mk
            log_info "Version number debug suffix:${FIX_VERSION_NUMBER}${VERNO_DEBUG_SUFFIX}"
        elif [[ -n "$VERNO_DEBUG_SUFFIX" ]]
        then
            sed -i "s/MTK_BUILD_VERNO = .*/MTK_BUILD_VERNO = ${VERNO_NEXT}${VERNO_DEBUG_SUFFIX}/" ProjectConfig.mk
            log_info "Version number debug suffix:${VERNO_NEXT}${VERNO_DEBUG_SUFFIX}"
        fi

        log_info "MODIFY OS VERNO OF ProjectConfig.mk IN PROJECT DIRECTORY NOW"
        #maybe use command 'awk' to be better,but some linux's 'awk' is different
        local -r NUMBER=$(grep MTK_BUILD_NUMBER ProjectConfig.mk | sed 's/ //g' | sed 's/.*=//g'|sed 's/#.*$//g')  #OS NUMBER XOS-V2.2.1-P0-161208
        if [ -n "${NUMBER}"  ]
        then
            local -r NUMBER_FIRST_FIELD=$(echo "${NUMBER}"| awk -F "-" '{print $1}') # XOS
            local -r NUMBER_SECOND_FIELD=$(echo "${NUMBER}"| awk -F "-" '{print $2}') # V2.2.1
            local -r NUMBER_THIRD_FIELD=$(echo "${NUMBER}"| awk -F "-" '{print $3}') # P4
            #local -r NUMBER_FORTH_FIELD=$(echo "${NUMBER}"| awk -F "-" '{print $4}') #161212

            local -r NUMBER_SECOND_FIELD_DIGITAL=${NUMBER_SECOND_FIELD##*.} # 1 
            local -r NUMBER_SECOND_FIELD_DIGITAL_REMAIN=${NUMBER_SECOND_FIELD%.*}  # V2.2 
            local -r NUMBER_SECOND_FIELD_DIGITAL_NEXT=$((NUMBER_SECOND_FIELD_DIGITAL+1)) # ++
            local -r NUMBER_VERSION_NEXT="${NUMBER_FIRST_FIELD}-${NUMBER_SECOND_FIELD_DIGITAL_REMAIN}.${NUMBER_SECOND_FIELD_DIGITAL_NEXT}-${NUMBER_THIRD_FIELD}-${TODAY}"
            log_info "NUMBER_VERSION_NEXT:${NUMBER_VERSION_NEXT}"
            sed -i "s/MTK_BUILD_NUMBER = .*/MTK_BUILD_NUMBER = ${NUMBER_VERSION_NEXT}/" ProjectConfig.mk
            #XOS var NUMBER_GALOBAL exits,then ro.mediatek.version.release is OS version,not the project version
            NUMBER_GLOBAL="${NUMBER_VERSION_NEXT}"
            git add ProjectConfig.mk
            git commit -m "HIOSWY-0 ver ${NUMBER_GLOBAL}"
            if [ "$?" != 0  ]
            then
                log_error2 "failed to change os verno locally."
                abnormal_exit
            fi
      fi
    popd
}


function set_ccache(){
    export USE_CCACHE=true            # ccache switch, used by build/core/ccache.mk
    export CCACHE_COMPRESS=true       # always compress ccache files with negligible performance slowdown(man ccache)
    export CCACHE_DIR=~/.ccache       # you can CUSTOMize ccache dir here
    local CCACHE=${CODE_DIR}/prebuilts/misc/linux-x86/ccache/ccache
    if [ ! -f "${CCACHE}" ]
    then
        # fall back to host ccache
        CCACHE=ccache
    fi
    # size of compressed ccache files for one android project is about 2GB.
    # we promise the capacity for about 20 absolute different android projects.
    #    in fact, ccache files are mostly same for the same platform(same android version(M etc.)/similar chipset platform(MTK XXXX etc.))
    $CCACHE -M 50G
}


function make_bin(){
    log_info "COMPILE CODE NOW"
    set_ccache

    local legacy_mk

    pushd "${CODE_DIR}"
        if [ "${SECBOOT}" == "true" ] && [ ! -f "${SIGNED_SCRIPT_RELATIVE_SEC11}" ]
        then
            log_error2 "The sign_image.sh not exist!! the script path is : ${SIGNED_SCRIPT_RELATIVE_SEC11}"
            abnormal_exit
        fi

        local -r ERROR_LOG_DIR=$(get_archive_dir "${ARCHIVE_DIRECTORY}" "${CURRENT_DATE}" "${ARCHIVE_DIR_SUFFIX}_error" "${DEBUG_SUFFIX}")

        # load android related environment variables and may do some source file copy
        if [ -e rlk_setenv.sh ]
        then
            if [ "${MTK_LOG}" == "true" ]
            then
                log_info "open MTK_LOG switch"
                # shellcheck disable=SC1091
                source rlk_setenv.sh "${PROJECT_NAME}" "${BUILD_MODE}" "mtklog"
            else
                # shellcheck disable=SC1091
                source rlk_setenv.sh "${PROJECT_NAME}" "${BUILD_MODE}"
            fi
        elif [ -e mk ]
        then
            legacy_mk="true"
            log_info "rlk_setenv.sh does not exist, but mk exists"
        else
            log_error2 "can not find rlk_setenv.sh or mk, exit abnormally"
            abnormal_exit
        fi

        if [ "${SECBOOT2}" == "true" ] && [ ! -f "${SIGNED_ALLIMG_SCRIPT_RELATIVE_SEC20}" ]
        then
            log_error2 "The sign_allimg.sh not exist!! the script path is : ${SIGNED_ALLIMG_SCRIPT_RELATIVE_SEC20}"
            abnormal_exit
        fi

        if [ -z "${armarch+x}" ]
        then
            log_warning "armarch not set, may be an error"
        else
            log_info "armarch: ${armarch}"
            readonly armarch
        fi

        # make normal fastboot package
        # HACK: jenkins multiple executors in one machine/one user
        local -r workspace_tail2=${WORKSPACE:(-2)}
        log_info "workspace tail: ${workspace_tail2}"
        local JACKHOME
        if [[ "${workspace_tail2}" == '-2' ]]
        then
            JACKHOME=~/jackhome2
            mkdir -p "${JACKHOME}"
            log_info "use custom jack home: ${JACKHOME}"
        else
            JACKHOME="${HOME}"
        fi

        if [ "${legacy_mk}" == "true" ]
        then
            HOME="${JACKHOME}" ./mk "${PROJECT_NAME}" "${BUILD_MODE}" new | tee "${BUILD_LOG}"
        else
            HOME="${JACKHOME}" make -j"${CONCURRENT_COMPILE_NUM}" 2>&1 | tee "${BUILD_LOG}"
        fi
        if [ "${PIPESTATUS[0]}" -ne 0 ]
        then
            log_error2 "error compile"
            mkdir -p "${ERROR_LOG_DIR}"
            abnormal_exit
        fi

        # execute sign image script
        if [ "${SECBOOT}" == "true" ]
        then
            log_info "start execute sign_image.sh script: ${SIGNED_SCRIPT_RELATIVE_SEC11}"
            ${SIGNED_SCRIPT_RELATIVE_SEC11}
            if [ "$?" -ne 0 ]
            then
                log_error2 "sign_image filed !!!"
            fi
        elif [ "${SECBOOT2}" == "true" ]
        then
            log_info "start execute sign_allimg.sh script: ${SIGNED_ALLIMG_SCRIPT_RELATIVE_SEC20}"
            ${SIGNED_ALLIMG_SCRIPT_RELATIVE_SEC20}
            if [ "$?" -ne 0 ]
            then
                log_error2 "sign_allimg filed !!!"
            fi
        fi

        # make full/Tcard packages
        if [ "${OTAPACKAGE}" == "true" ]
        then
            log_info "start generating otapackage"
            echo "$(date '+%Y-%m-%d %H:%M:%S') start generating otapackage" >> "${BUILD_LOG}"
            if [ "${legacy_mk}" == "true" ]
            then
                HOME="${JACKHOME}" ./mk "${PROJECT_NAME}" "${BUILD_MODE}" otapackage | tee --append "${BUILD_LOG}"
            else
                HOME="${JACKHOME}" make otapackage -j"${HALF_CONCURRENT_COMPILE_NUM}"  2>&1 | tee --append "${BUILD_LOG}"
            fi
            if [ "${PIPESTATUS[0]}" -ne 0 ]
            then
                log_error2 "error otapackage compile"
                mkdir -p "${ERROR_LOG_DIR}"
                abnormal_exit
            else
                #execute sign_system_image.sh script
                if [ "${SECBOOT}" == "true" ]
                then
                    log_info "start sign system.img after make otapackage!"
                    ${SIGNED_SYSTEMIMG_SCRIPT_RELATIVE_SEC11}
                    if [ "$?" -ne 0 ]
                    then
                        log_error2 "sign_system_image filed !!!"
                    fi
                fi
            fi
        else
            log_info "do not generate otapackage"
        fi

        # determine mtk project such as rlk6580_we_m
        local -r mtkprojects=$(find out/target/product/ -maxdepth 1 -mindepth 1 -type d)
        if [ -z "${mtkprojects}" ]
        then
            log_error2 "no directory found in out/target/product after compilation, exit abnormally"
            abnormal_exit
        elif [ "$(echo "${mtkprojects}" | wc -l)" != 1 ]
        then
            log_error2 "multiple directories found in out/target/product after compilation, exit abnormally"
            abnormal_exit
        fi

        CUSTOM=$(basename "${mtkprojects}")
        readonly CUSTOM
        # TODO: relationship with ro.mediatek.version.release?
        if [ -z "${NUMBER_GLOBAL}"   ]
        then
            VERSION=$(grep "ro.mediatek.version.release"  out/target/product/"$CUSTOM"/system/build.prop|sed 's/ //g'|sed 's/.*=//g')
        else
            VERSION=$(grep "ro.build.display.id"  out/target/product/"$CUSTOM"/system/build.prop|sed 's/ //g'|sed 's/.*=//g')
        fi
        readonly VERSION
    popd
}


# TODO: sometimes it is not necessary
function try_push_verno(){
    log_info "TRY TO PUSH VERNO NOW"
    if [[ -n "${FIX_VERSION_NUMBER}" ]]
    then
        log_info "WE DO NOT NEED TO PUSH VERNO NOW"
        log_info "THIS IS FIX VERSION NUMBER"
        log_info "THE FIX VERSION NUMBER is ${FIX_VERSION_NUMBER}"
        return 0
    fi
    
    if [[ -n "$VERNO_DEBUG_SUFFIX" ]]
    then
        log_info "WE DO NOT NEED TO PUSH VERNO NOW"
        log_info "THIS IS VERNO DEBUG SUFFIX"
        log_info "THE VERNO DEGUG SUFFIX is ${VERNO_DEBUG_SUFFIX}"
        return 0
    fi

    pushd "${PROJECT_DIR}"
        # shellcheck disable=SC2016
        local -r PROJECT_REMOTE=$(repo forall '' -c 'echo ${REPO_REMOTE}')
        if [ -z "${PROJECT_REMOTE}" ]
        then
            log_error2 "failed to get git project remote"
            return
        fi

        # shellcheck disable=SC2016
        local -r PROJECT_REMOTE_BRANCH=$(repo forall '' -c 'echo ${REPO_RREV}')
        if [ -z "${PROJECT_REMOTE_BRANCH}" ]
        then
            log_error2 "failed to get git project remote branch"
            return
        fi

        grep "make completed successfully" "${BUILD_LOG}" 1>/dev/null 2>&1
        if [ "$?" == 0 ];then
            # push modified ProjectConfig.mk to reflect the new version number
            log_info "git status:"
            log_info "$(git status)"
            log_info "git stash:"
            git stash  || log_error2 "git stash failed"
            git pull --rebase || log_error2 "git pull --rebase failed before git push verno"
            if [ "${DEBUG_MODE}" == "true" ]
            then
                log_info "DEBUG STUB: git push ${PROJECT_REMOTE} HEAD:${PROJECT_REMOTE_BRANCH}"
            else
                if [ "${PUSH_VERNO}" == "false" ]
                then
                    log_info "PUSH_VERNO == false, no need to push verno"
                else
                    local cmd="git push ${PROJECT_REMOTE} HEAD:${PROJECT_REMOTE_BRANCH}"
                    log_info "execute cmd now: $cmd"
                    $cmd
                    if [ "$?" == 0 ]
                    then
                        log_info "succeeded to execute: $cmd"
                    else
                        # TODO: make more notification
                        log_error2 "failed to execute: $cmd"
                    fi
                fi
            fi
        else
            # TODO: what shall we do when log says compilation failed?
            log_error2 "make failed."
            try_repo_abandon  # reflect the code status before modification of verno for snapshot
        fi
    popd
}


# TODO: sometimes it is not necessary
function generate_push_snapshot(){
    log_info "TRY TO GENERATE AND PUSH SNAPSHOT NOW"
    pushd "${CODE_DIR}"
        # generate snapshot locally
        local VERSION_BASE=${VERSION%-*}
        SNAP_VERSION_XML="${CODE_DIR}/${VERSION_BASE}-${SNAP_TIME}.xml"
        readonly SNAP_VERSION_XML

        repo manifest -r -o "${SNAP_VERSION_XML}"

        # try to push snapshot to gerrit
        pushd .repo/manifests
            git reset --hard 1>/dev/null 2>&1
            git clean -fdx 1>/dev/null 2>&1
            git pull --rebase

            if [ ! -d "${MANIFEST_DIRECTORY}" ]
            then
                mkdir "${MANIFEST_DIRECTORY}"
            fi
            RELEASE_SNAPSHOT_LOG_HEAD="add snapshot for ${MANIFEST_XML_NAME_PREFIX} ${PROJECT_NAME} ${BUILD_MODE}"
            NO_RELEASE_SNAPSHOT_LOG_HEAD="add snapshot no_release for ${MANIFEST_XML_NAME_PREFIX} ${PROJECT_NAME} ${BUILD_MODE}"
            if [ "${NO_RELEASE}" == "true" ]
            then
                local -r ADD_SNAPSHOT_LOG_HEAD="${NO_RELEASE_SNAPSHOT_LOG_HEAD}"
            else
                local -r ADD_SNAPSHOT_LOG_HEAD="${RELEASE_SNAPSHOT_LOG_HEAD}"
            fi
            cp "${SNAP_VERSION_XML}" "${MANIFEST_DIRECTORY}"
            git add .
            git commit -m "${ADD_SNAPSHOT_LOG_HEAD} $(basename "${SNAP_VERSION_XML}")"
            if [ "$?" != 0 ]
            then
                # do not exit here. fail to push snapshot to gerrit but still could archive in storage server afterwards
                log_error2 "failed to commit snapshot locally"
            else
                git pull --rebase || log_error2 "git pull --rebase failed before git push snapshot"
                # TODO: "origin" here may be invalid for some products some day
                if [ "${DEBUG_MODE}" == "true" ]
                then
                    log_info "DEBUG STUB: git push origin HEAD:${MANIFEST_BRANCH}"
                else
                    if [ "${PUSH_VERNO}" == "false" ]
                    then
                        log_info "PUSH_VERNO == false, no need to push snapshot either, to keep snapshot and verno consistent"
                    else
                        local cmd="git push origin HEAD:${MANIFEST_BRANCH}"
                        log_info "execute cmd now: $cmd"
                        $cmd
                        if [ "$?" == 0 ]
                        then
                            log_info "succeeded to execute: $cmd"
                        else
                            # TODO: make more notification
                            # do not exit here. fail to push snapshot to gerrit but still could archive in storage server afterwards
                            log_error2 "failed to execute: $cmd"
                        fi
                    fi
                fi
            fi

            # last snapshot file may not be in ${MANIFEST_DIRECTORY}
            local lastsnapshotname
            lastsnapshotname=$(git log | grep "${VERSION_BASE}-[0-9]\{12\}\.xml" |grep "${RELEASE_SNAPSHOT_LOG_HEAD}"|grep -v 'Merge "'| sed -n "2p" | grep -aoE '[^ ]*.xml')
            if [ -z "${lastsnapshotname}" ]
            then
                # legacy format
                log_info "can not find snapshot with branch name through compile type log, fall back to legacy format"
                lastsnapshotname=$(git log | grep "${VERSION_BASE}-[0-9]\{12\}\.xml" |grep "add snapshot for ${MANIFEST_XML_NAME_PREFIX}"|grep -v 'Merge "'| sed -n "2p" | grep -aoE '[^ ]*.xml')
                if [ -z "${lastsnapshotname}" ]
                then
                    log_info "can not find snapshot with branch name through fixed manifest name log, fall back to legacy format"
                    lastsnapshotname=$(git log | grep "${VERSION_BASE}-[0-9]\{12\}\.xml" |grep "add snapshot" |grep -v "no_release"|grep -v 'Merge "'| sed -n "2p" | grep -aoE '[^ ]*.xml')
                fi
            fi

            if [ -n "${LAST_MANIFEST}" ]
            then 
                lastsnapshotname=${LAST_MANIFEST}.xml
                log_info "last manifest is ****** ${LAST_MANIFEST} ******"
            fi
            readonly LAST_SNAP_VERSION_XML=$(find "${CODE_DIR}"/.repo/manifests -name  "$lastsnapshotname")
            if [ -z "${LAST_SNAP_VERSION_XML}" ]
            then
                log_error2 "failed to find last snapshot xml"
            else
                if [ -n "${LAST_MANIFEST}" ]
                then
                    echo "Change_log is from ${lastsnapshotname} to today's SNAP" >> "${CODE_DIR}"/LAST_MANIFEST.txt
                fi
            fi
        popd
    popd

    # we can abandon project branch only after archiving snapshot, to make snapshot reflect code state correctly.
    pushd "${PROJECT_DIR}"
        repo abandon "${LOCAL_PROJECT_BRANCH_NAME}"
    popd
}


# input: ${LAST_SNAP_VERSION_XML} ${SNAP_VERSION_XML}
# output: ${GIT_LOG_DIFF_TOBE_ARCHIVED}
function generate_git_log_diff(){
    log_info "GENERATE GIT LOG DIFF NOW"
    pushd "${CODE_DIR}"
        GIT_LOG_DIFF_TOBE_ARCHIVED=$(myrealpath 'log.txt')
        local -r LOGFILE_TEMP=$(myrealpath 'log_cm')
        rm -f "${GIT_LOG_DIFF_TOBE_ARCHIVED}" "${LOGFILE_TEMP}"
        touch "${GIT_LOG_DIFF_TOBE_ARCHIVED}" "${LOGFILE_TEMP}"

        repo diffmanifests "${LAST_SNAP_VERSION_XML}" "${SNAP_VERSION_XML}" | awk '{if($3~/^from$/ && $2~/^changed$/ && $5~/^to$/ || $3~/^revision$/ && $2~/^at$/)print}' | awk '{print $1,$4,$6}' > "${LOGFILE_TEMP}"
        if [ "${PIPESTATUS[0]}" != 0 ]
        then
            log_error2 "repo diff manifests failed"
        fi

        sed -i 's/refs\/tags\///g' "${LOGFILE_TEMP}"

        local PROJECT_PATH
        local CHANGE_FROM_REVISION
        local CHANGE_TO_REVISION
        while read -r line
        do
            PROJECT_PATH=$(echo "$line" | awk  '{print $1}')
            CHANGE_FROM_REVISION=$(echo "$line" | awk  '{print $2}')
            CHANGE_TO_REVISION=$(echo "$line" | awk  '{print $3}')
            log_info "PROJECT_PATH: ${PROJECT_PATH}"
            log_info "CHANGE_FROM_REVISION: ${CHANGE_FROM_REVISION}"
            log_info "CHANGE_TO_REVISION: ${CHANGE_TO_REVISION}"
            if [ -d "${PROJECT_PATH}" ]
            then
                pushd "${PROJECT_PATH}"
                    if [ ! -n "${CHANGE_TO_REVISION}" ];then
                        echo "${PROJECT_PATH}" >> "${GIT_LOG_DIFF_TOBE_ARCHIVED}"
                        git log  "${CHANGE_FROM_REVISION}" --pretty="%an|[%h] %s" | grep -v "Merge" | awk -F\| '{printf("%-15s\t%s\n",$1, $2) }' >> "${GIT_LOG_DIFF_TOBE_ARCHIVED}"
                    else
                        echo "${PROJECT_PATH}" >> "${GIT_LOG_DIFF_TOBE_ARCHIVED}"
                        git log  "${CHANGE_FROM_REVISION}..${CHANGE_TO_REVISION}" --pretty="%an|[%h] %s" | grep -v "Merge" | awk -F\| '{printf("%-15s\t%s\n",$1, $2) }' >> "${GIT_LOG_DIFF_TOBE_ARCHIVED}"
                        if [ "${PIPESTATUS[0]}" -ne 0 ];then
                            git log "${CHANGE_TO_REVISION}" --pretty="%an|[%h] %s" | grep -v "Merge" | awk -F\| '{printf("%-15s\t%s\n",$1, $2) }' >> "${GIT_LOG_DIFF_TOBE_ARCHIVED}"
                        fi
                    fi
                popd
            else
                log_warning "${PROJECT_PATH} does not exist, do not get git log diff"
            fi
        done < "${LOGFILE_TEMP}"
    popd
}


function archive_build_output(){
    # TODO: archive with more powerful tool
    # TODO: figure out whether output is configurable
    log_info "ARCHIVE BUILD RESULT NOW"
    pushd "${CODE_DIR}"
        # ARCHIVE COMPILE OUTPUT LOCALLY
        local -r local_archive_dir_relative="local_archive_$(date +%Y.%m.%d_%H.%M.%S)"
        mkdir "${local_archive_dir_relative}"
        log_info "local archive directory: ${local_archive_dir_relative}"

        #################
        # release files #
        #################
        rm -rf ./release; mkdir release
        local -r signed_img_dir="${CODE_DIR}/out/target/product/${CUSTOM}/signed_bin"
        local -r efuse_dir="${CODE_DIR}/out/target/product/${CUSTOM}/efuse"
        if [ "${SECBOOT}" == "true" ]
        then
            if [ -d "${signed_img_dir}" ]
            then
                # All signed_bin file except auth*.auth DA_SWSEC.bin and MTK_AllInOne_DA.bin
                rm -f "${signed_img_dir}"/auth*.auth
                rm -f "${signed_img_dir}"/DA_SWSEC.bin
                rm -f "${signed_img_dir}"/MTK_AllInOne_DA.bin
                cp "${signed_img_dir}"/* ./release
                # AP + BP
                cp ./out/target/product/"${CUSTOM}"/obj/CGEN/APDB* ./release
                rm -f ./release/*_ENUM
                find ./out/target/product/"${CUSTOM}"  -name "BPLG*" -type f -exec cp {}  ./release \;
                # gen Checksum.ini
                cp "${CHECKSUM_UTIL_DIR}"/CheckSum_Gen.exe ./release
                cp "${CHECKSUM_UTIL_DIR}"/FlashToolLib* ./release
            else
                log_error2 "signed_bin dir have not found ,please check !!"
                abnormal_exit
            fi
        else
            cp ./out/target/product/"${CUSTOM}"/obj/CGEN/APDB* ./release
            rm -f ./release/*_ENUM

            find ./out/target/product/"${CUSTOM}"  -name "BPLG*" -type f -exec cp {}  ./release \;
            #  Android N Modem just only for  MDDB_Info*, reducing work  for choosing  to flash  version
            cp ./out/target/product/"${CUSTOM}"/obj/ETC/MDDB_Info*/* ./release 2>/dev/null
            cp ./out/target/product/"${CUSTOM}"/MBR* ./release 2>/dev/null
            cp ./out/target/product/"${CUSTOM}"/EBR* ./release 2>/dev/null
            cp ./out/target/product/"${CUSTOM}"/*.img ./release
            cp ./out/target/product/"${CUSTOM}"/*.bin ./release
            cp ./out/target/product/"${CUSTOM}"/*_Android_scatter.txt ./release
            cp ./out/target/product/"${CUSTOM}"/preloader* ./release
            cp ./out/target/product/"${CUSTOM}"/kernel ./release
            cp "${CHECKSUM_UTIL_DIR}"/CheckSum_Gen.exe ./release
            cp "${CHECKSUM_UTIL_DIR}"/FlashToolLib* ./release
            if [ "${SECBOOT2}" == "true" ]
            then
                # archive efuse files except auth*.auth DA_SWSEC.bin and MTK_AllInOne_DA.bin
                rm -f "${efuse_dir}"/auth*.auth
                rm -f "${efuse_dir}"/DA_SWSEC.bin
                rm -f "${efuse_dir}"/MTK_AllInOne_DA.bin
                cp "${efuse_dir}"/* ./release
            fi
        fi
        pushd ./release
            # wangyongrong: why "\015"?
            echo "\015" | wine CheckSum_Gen.exe
            rm CheckSum_Gen.exe
            rm FlashToolLib*
            archive_cwd_zip "${VERSION}".zip
            md5sum "${VERSION}".zip > "${VERSION}".md5
            log_info "============================="
            log_info "PROJECT VERSION is ${VERSION}"
        popd
        cp -r ./release/"${VERSION}".zip "${local_archive_dir_relative}"
        cp -r ./release/"${VERSION}".md5 "${local_archive_dir_relative}"

        if [ -n "${NUMBER_GLOBAL}" ]
        then
            log_info "============================="
            log_info "OS VERSION NUMBER is ${NUMBER_GLOBAL}"
            pushd "${local_archive_dir_relative}"
                mv "${VERSION}".zip "${NUMBER_GLOBAL}".zip
            popd
        fi

        #################
        # mapping files #
        #################
        rm -rf ./mapping_file; mkdir mapping_file

        local -r mappingfiles=$(find . -type f -name 'mapping_file_*')
        if [ ! -z "${mappingfiles}" ]
        then
            # shellcheck disable=SC2086
            cp -rf --parents ${mappingfiles} ./mapping_file
            pushd ./mapping_file
                archive_cwd_zip mapping_file.zip
            popd
            cp -r ./mapping_file/mapping_file.zip "${local_archive_dir_relative}"
        fi


        ###############
        # track files #
        ###############
        rm -rf ./track; mkdir track

        cp ./out/target/product/"${CUSTOM}"/obj/KERNEL_OBJ/vmlinux ./track
        cp -r ./out/target/product/"${CUSTOM}"/symbols ./track
        cp build/target/product/security/platform.pk8 ./track
        cp build/target/product/security/platform.x509.pem ./track
        pushd ./track
            archive_cwd_zip track.zip
        popd
        cp -r ./track/track.zip "${local_archive_dir_relative}"


        ########
        # prop #
        ########
        cp out/target/product/"${CUSTOM}"/system/build.prop "${local_archive_dir_relative}"


        ############################
        # full/Tcard packages etc. #
        ############################
        if [ "${OTAPACKAGE}" == "true" ]
        then
            cp -r out/target/product/"${CUSTOM}"/obj/PACKAGING/target_files_intermediates/*.zip "${local_archive_dir_relative}"
            # TODO: is full_$CUSTOM*.zip unique?
            cp out/target/product/"${CUSTOM}"/full_"${CUSTOM}"*.zip  "${local_archive_dir_relative}"/Tcard_update_"${VERSION##*-}".zip
            local FULL_NAME=""
            FULL_NAME="$(basename out/target/product/"${CUSTOM}"/obj/PACKAGING/target_files_intermediates/*.zip)"
            FULL_NAME=${FULL_NAME%.*}
            md5sum "${local_archive_dir_relative}"/"${FULL_NAME}".zip > "${local_archive_dir_relative}"/"${FULL_NAME}".md5
            md5sum "${local_archive_dir_relative}"/Tcard_update_"${VERSION##*-}".zip > "${local_archive_dir_relative}"/Tcard_update_"${VERSION##*-}".md5
        fi


        ################################
        # hios apk archive result etc. #
        ################################
        if [ -f "${ARCHIVE_APK_MISSING_SOURCE_FILE_LIST}" ]
        then
            cp "${ARCHIVE_APK_MISSING_SOURCE_FILE_LIST}" "${local_archive_dir_relative}"
        fi


        ##############################
        # change diffs and snapshot  #
        ##############################
        # ARCHIVE CHANGE DIFFS AND SNAPSHOT LOCALLY
        cp "${GIT_LOG_DIFF_TOBE_ARCHIVED}" "${local_archive_dir_relative}" || log_error2 "local git log diff ${GIT_LOG_DIFF_TOBE_ARCHIVED} does not exist, failed to archive"
        cp "${SNAP_VERSION_XML}" "${local_archive_dir_relative}" || log_error2 "local snapshot ${SNAP_VERSION_XML} does not exist, failed to archive"
        cp "${CLEAN_SNAPSHOT}" "${local_archive_dir_relative}" || log_error2 "local clean snapshot ${CLEAN_SNAPSHOT} does not exist, failed to archive"

        #############
        # OTA TOOLS #
        #############
        local -r OTA_TOOLS_DIR_NAME=OTA_TOOLS
        rm -rf "${OTA_TOOLS_DIR_NAME}"; mkdir "${OTA_TOOLS_DIR_NAME}"

        local -r devicespecificscript=device/mediatek/build/releasetools/mt_ota_from_target_files.py
        local -r publickeyfile=$(grep 'DumpPublicKey:' "${VERBOSE_BUILD_LOG}" | grep -aoe 'DumpPublicKey: .*$' |cut -d ' ' -f4)
        local -r privatekeyfile=${publickeyfile%*.x509.pem}.pk8

        cp --parents --no-dereference  build/tools/releasetools/*     "${OTA_TOOLS_DIR_NAME}" || log_error2 "failed to archive OTA related script"
        cp --parents "${devicespecificscript}"                        "${OTA_TOOLS_DIR_NAME}"    # may not exist
        cp --parents "${publickeyfile}"                               "${OTA_TOOLS_DIR_NAME}" || log_error2 "failed to archive OTA related key"
        cp --parents "${privatekeyfile}"                              "${OTA_TOOLS_DIR_NAME}" || log_error2 "failed to archive OTA related key"
        cp --parents out/host/linux-x86/framework/signapk.jar         "${OTA_TOOLS_DIR_NAME}" || log_error2 "failed to archive OTA related tool"
        cp --parents out/host/linux-x86/bin/zipalign                  "${OTA_TOOLS_DIR_NAME}" || log_error2 "failed to archive OTA related tool"
        cp --parents out/host/linux-x86/bin/imgdiff                   "${OTA_TOOLS_DIR_NAME}" || log_error2 "failed to archive OTA related tool"
        cp --parents out/host/linux-x86/bin/bsdiff                    "${OTA_TOOLS_DIR_NAME}" || log_error2 "failed to archive OTA related tool"
        cp --parents out/host/linux-x86/bin/mkbootfs                  "${OTA_TOOLS_DIR_NAME}" || log_error2 "failed to archive OTA related tool"
        cp --parents out/host/linux-x86/bin/mkbootimg                 "${OTA_TOOLS_DIR_NAME}" || log_error2 "failed to archive OTA related tool"
        cp --parents out/host/linux-x86/bin/minigzip                  "${OTA_TOOLS_DIR_NAME}" || log_error2 "failed to archive OTA related tool"
        # libc++.so for the binaries above. the dynamical link of the binaries try to find in "../lib64"
        cp --parents out/host/linux-x86/lib64/libc++.so               "${OTA_TOOLS_DIR_NAME}" || log_error2 "failed to archive OTA related tool"
        # libcutils.so and liblog.so for mkbootfs
        cp --parents out/host/linux-x86/lib64/libcutils.so            "${OTA_TOOLS_DIR_NAME}"    # may not exist
        cp --parents out/host/linux-x86/lib64/liblog.so               "${OTA_TOOLS_DIR_NAME}" || log_error2 "failed to archive OTA related tool"
        # not so necessary
        cp --parents out/host/linux-x86/framework/BootSignature.jar   "${OTA_TOOLS_DIR_NAME}" 2>/dev/null
        cp --parents out/host/linux-x86/bin/boot_signer               "${OTA_TOOLS_DIR_NAME}" 2>/dev/null
        cp --parents out/host/linux-x86/lib64/libdivsufsort64.so      "${OTA_TOOLS_DIR_NAME}" 2>/dev/null
        cp --parents out/host/linux-x86/lib64/libdivsufsort.so        "${OTA_TOOLS_DIR_NAME}" 2>/dev/null
        cp --parents out/host/linux-x86/lib64/libconscrypt_openjdk_jni.so        "${OTA_TOOLS_DIR_NAME}" 2>/dev/null

        if [ "${OTAPACKAGE}" == "true" ]
        then
            local -r scatterfiles=$(find . -type f -name ota_scatter.txt)
            if [ -z "${scatterfiles}" ]
            then
                log_error2 "scatter files not found, failed to archive"
            else
                for scatterfile in ${scatterfiles}
                do
                    cp --parents "${scatterfile}"                           "${OTA_TOOLS_DIR_NAME}" || log_error2 "failed to archive OTA related ota_scatter.txt"
                done
            fi
        fi

        # information about the current build
        echo "${BASE_URL} ${MANIFEST_XML_NAME_PREFIX} ${PROJECT_NAME} ${BUILD_MODE} $(date +%Y%m%d%H%M%S)"  > "${OTA_TOOLS_DIR_NAME}"/build_info.txt
        cp "${SNAP_VERSION_XML}" "${OTA_TOOLS_DIR_NAME}"

        pushd "${OTA_TOOLS_DIR_NAME}"
            archive_cwd_zip "${OTA_TOOLS_DIR_NAME}".zip
        popd
        cp -r "${OTA_TOOLS_DIR_NAME}/${OTA_TOOLS_DIR_NAME}".zip "${local_archive_dir_relative}"


        ##############
        # secret tag #
        ##############
        cp "${SECRET_TAG}" "${local_archive_dir_relative}" || log_error2 "failed to archive secret tag"


        ###################
        # secboot warning #
        ###################
        if [[ "${SECBOOT}" == "true" ]]
        then
            touch "${local_archive_dir_relative}/BUILD_WITH_SECBOOT_1.1.txt"
        fi

        if [[ "${SECBOOT2}" == "true" ]]
        then
            touch "${local_archive_dir_relative}/BUILD_WITH_SECBOOT_2.0.txt"
        fi

        ###################
        # LAST_MNIAFEST   #
        ################### 
        if [ -f "${CODE_DIR}/LAST_MANIFEST.txt" ]
        then
            mv "${CODE_DIR}"/LAST_MANIFEST.txt "${local_archive_dir_relative}"
        fi

        #############################################################
        # COPY LOCAL ARCHIVE TO DESTINATION(USUALLY A NAS LOCATION) #
        #############################################################
        # TODO: use smbclient to archive instead of copy after cifs mount
        local -r storage_archive_dir=$(get_archive_dir "${ARCHIVE_DIRECTORY}" "${CURRENT_DATE}" "${ARCHIVE_DIR_SUFFIX}" "${DEBUG_SUFFIX}")
        log_info "target archive directory: ${storage_archive_dir}"
        cp -rf "${local_archive_dir_relative}" "${storage_archive_dir}"
        if [ "$?" != 0 ]
        then
            log_error2 "fail to archive to ${storage_archive_dir}"
            if [ -n "${LOCAL_ARCHIVE_DIR}" ]
            then
                mkdir -p "${LOCAL_ARCHIVE_DIR}"
                local -r local_storage_archive_dir=$(get_archive_dir "${LOCAL_ARCHIVE_DIR}" "${CURRENT_DATE}" "${ARCHIVE_DIR_SUFFIX}" "${DEBUG_SUFFIX}")
                log_info "LOCAL_ARCHIVE_DIR desiginated, try to archive locally: ${local_storage_archive_dir}"
                cp -rf "${local_archive_dir_relative}" "${local_storage_archive_dir}"
            else
                log_info "LOCAL_ARCHIVE_DIR not desiginated, do not archive locally"
            fi
        else
            if [ -d "${CI_SMOKE_DIR}" ]
            then
                local -r nas_storage_dir=$(local_to_nas_storage "${storage_archive_dir}")
                local -r CI_SMOKE_DATE=$(date +%Y.%m.%d)
                local -r CI_SMOKE_DATE_DIR="${CI_SMOKE_DIR}/${CI_SMOKE_DATE}"
                mkdir -p "${CI_SMOKE_DATE_DIR}"
                if [ -d "${CI_SMOKE_DATE_DIR}" ]
                then
                    if [ "${DEBUG_MODE}" == "true" ]
                    then
                        log_info "DEBUG_MODE not archive CI_SMOKE!"
                    else
                        echo "${nas_storage_dir}" > "${CI_SMOKE_DATE_DIR}/${VERNO_GLOBAL}.txt"
                    fi
                else
                    log_error2 "failed to make dir: ${VERNO_DIR}"
                fi
            fi
        fi
    popd
}


function try_modify_app_version(){
    pushd "${CODE_DIR}"
        log_info "TRY TO MODIRY APP VERSION NOW"
        if [ "${ARCHIVE_APK_HIOS}" == "false" ]
        then
            log_info "apk archive switch is not on, do not modify app version"
            return 0
        fi

        if [ "${MODIFY_HIOS_APK_VERNO}" == "false" ]
        then
            log_info "modify hios apk verno switch is not on, do not modify app version"
            return 0
        fi

        # TODO: put to constants section
        local apparray=(
            packages/apps/AgingTest
            packages/apps/Bluetooth
            packages/apps/Browser
            packages/apps/Calculator
            packages/apps/Calendar
            packages/apps/DeskClock
            frameworks/base/packages/DocumentsUI
            packages/providers/DownloadProvider/ui
            packages/apps/Email
            packages/apps/Exchange2
            vendor/mediatek/proprietary/packages/apps/FileManager
            packages/apps/Gallery2
            packages/apps/HiManager
            packages/apps/Launcher3
            packages/apps/ManualGuide
            packages/apps/Microintelligence
            packages/apps/NoteBook
            packages/apps/OOBE
            packages/apps/PackageInstaller
            packages/apps/PowerSaveManagement
            vendor/mediatek/proprietary/packages/apps/SchedulePowerOnOff
            packages/apps/SoundRecorder
            vendor/mediatek/proprietary/packages/apps/SystemUpdate
            packages/apps/Theme
            vendor/mediatek/proprietary/packages/apps/VideoPlayer
            packages/apps/WallpaperGallery
            packages/apps/Weather
            packages/apps/Contacts
            packages/providers/DownloadProvider
            vendor/mediatek/proprietary/packages/apps/FmRadio
            packages/apps/InCallUI
            packages/providers/MediaProvider
            packages/apps/Mms
            packages/services/Mms
            packages/apps/Settings
            vendor/mediatek/proprietary/packages/apps/Stk1
            frameworks/base/packages/SystemUI
            frameworks/base/telecomm
            frameworks/base/telephony
            vendor/mediatek/proprietary/packages/apps/Camera
            vendor/mediatek/proprietary/packages/apps/BackupRestore
        )

        local -r TODAY=$(date +%Y%m%d)
        local appversionname
        local versionName_del_space
        local version_del_last
        local version_no
        local version_id_0
        local version_id
        local version_last_no
        local version_last_no_nodate
        local version_last_no_len

        for app in "${apparray[@]}"
        do
            log_info "process $app now"
            if [ -d "$app" ]
            then
                pushd "$app"
                    if [ -e AndroidManifest.xml ]
                    then
                        appversionname=$(grep "android:versionName" AndroidManifest.xml)
                        versionName_del_space="${appversionname// /;}"
                        if [ ! -z  "$versionName_del_space" ]
                        then
                                version_del_last="${versionName_del_space%\"*}"
                                version_no="${version_del_last//\"}"
                                version_id_0="${version_no##*android:versionName=}"
                                version_id="${version_id_0//;/ }"
                                echo "#############  $version_id  #########"
                                version_last_no="${version_id##*\.}"
                                version_last_no_nodate="${version_id%\.*}"
                                version_last_no_len="${#version_last_no}"
                                if [ "${version_last_no_len}" -eq 8 ]
                                then
                                       sed -i "s/android:versionName=\".*\"/android:versionName=\"${version_last_no_nodate}\.${TODAY}\"/" AndroidManifest.xml
                                else
                                       sed -i "s/android:versionName=\".*\"/android:versionName=\"${version_id}\.${TODAY}\"/" AndroidManifest.xml
                                fi
                                log_info "modify version of $app:"
                                log_info "$(git diff AndroidManifest.xml)"
                        fi
                    else
                        log_info "AndroidManifest.xml does not exist"
                    fi
                popd
            else
                log_info "$app does not exist"
            fi
        done
    popd
}


# archive hios apk for beijing team to use
function try_archive_hios_apk(){
    log_info "TRY ARCHIVING HIOS APK NOW"
    if [ "${ARCHIVE_APK_HIOS}" == "false" ]
    then
        log_info "apk archive switch is not on, do not archive apk to hios"
        return 0
    fi

    if [[ -z "${ARCHIVE_APK_HIOS_REPOSITORY}" || -z "${ARCHIVE_APK_HIOS_BRANCH}" ]]
    then
        log_info "hios repository or branch not designated, do not archive apk to hios"
        return 0
    fi

    pushd "$CODE_DIR"
        local SOURCE_TXT="${CODE_DIR}"/modified_files/source.txt
        local DEST_TXT="${CODE_DIR}"/modified_files/dest.txt

        if [[ ! -f "${SOURCE_TXT}" || ! -f "${DEST_TXT}" ]]
        then
            log_error2 "source or dest files missing: ${SOURCE_TXT} ${DEST_TXT}, do not archive hios apk any more"
            return 1
        fi

        local ARCHIVE_APK_MISSING_SOURCE_FILE_LIST="${CODE_DIR}"/archive_apk_missing_source_file_list.txt
        local HIOS_DIR="${CODE_DIR}"/hios

        rm -rf "${ARCHIVE_APK_MISSING_SOURCE_FILE_LIST}"
        rm -rf "${HIOS_DIR}"

        local cmd="git clone ${ARCHIVE_APK_HIOS_REPOSITORY} ${HIOS_DIR}"
        eval "$cmd"
        if [ "$?" != 0 ]
        then
            log_error2 "failed to execute command: $cmd , do not archive hios apk any more"
            return 1
        fi

        pushd "${HIOS_DIR}"
            cmd="git checkout ${ARCHIVE_APK_HIOS_BRANCH}"
            eval "$cmd"
            if [ "$?" != 0 ]
            then
                log_error2 "failed to execute command: $cmd , do not archive hios apk any more"
                return 1
            fi
        popd

        readarray -t sourcearray < "${SOURCE_TXT}"
        readarray -t destarray < "${DEST_TXT}"
        if [ "${#sourcearray[@]}" != "${#destarray[@]}" ]
        then
            log_error2 "numbers of items are different: $SOURCE_TXT $DEST_TXT , do not archive hios apk any more"
            return 1
        fi

        local myfileabs
        local outtargetdirabs
        for index in $(seq 0 $((${#sourcearray[@]} - 1)))
        do
            # NOTICE: permit wildcard notation, no double quote needed. if the paths contain whitespace etc., maybe we need eval

            if [ "${sourcearray[index]}" == "vendor/tecno/frameworks/" ]
            then
                log_info "hack: permit vendor/tecno/frameworks src to deliver as common files, do not do security check"

                # shellcheck disable=SC2086
                rsync -ar --exclude '.git' ${sourcearray[index]} ${destarray[index]} 2>/dev/null
                if [ "$?" != 0 ]
                then
                    echo "${sourcearray[index]} file not exist" >> "${ARCHIVE_APK_MISSING_SOURCE_FILE_LIST}"
                fi
            else
                # validation for information security, in case path traversal attack happens
                for myfile in ${sourcearray[index]}
                do
                    myfileabs=$(myrealpath "$myfile")
                    outtargetdirabs=$(myrealpath "${CODE_DIR}/out/target")
                    echo x"${myfileabs}" | grep -q x"${outtargetdirabs}"
                    if [ "${PIPESTATUS[1]}" != 0 ]
                    then
                        log_error2 "non-secure file path detected in source.txt: $myfileabs, exit abnormally"
                        abnormal_exit
                    fi
                done

                # shellcheck disable=SC2086
                cp -rf ${sourcearray[index]} ${destarray[index]} 2>/dev/null
                if [ "$?" != 0 ]
                then
                    echo "${sourcearray[index]} file not exist" >> "${ARCHIVE_APK_MISSING_SOURCE_FILE_LIST}"
                fi
            fi

            # HACK: many "*.so" soft links are linked to wrong path such as "/system/lib64/libmpbase.so".
            if [ -d "${destarray[index]}" ]
            then
                pushd "${destarray[index]}"
                    find -type l -name "*.so" -exec rm -rf {} \;
                popd
            fi
        done

        pushd "${HIOS_DIR}"
            if [ -f "${ARCHIVE_APK_MISSING_SOURCE_FILE_LIST}" ];then
                echo -e  "\033[31msome files can not find in source ,you can see it ==>> ${ARCHIVE_APK_MISSING_SOURCE_FILE_LIST}\033[0m"
                cp "${ARCHIVE_APK_MISSING_SOURCE_FILE_LIST}" ./
            fi

            local -r NOW="$(date +%Y%m%d%H%M)"
            mkdir -p logs 2>/dev/null
            # according to Beijing team, archive git log for them
            cp "${GIT_LOG_DIFF_TOBE_ARCHIVED}" ./logs/log_"${NOW}".txt || log_error2 "git log diff ${GIT_LOG_DIFF_TOBE_ARCHIVED} does not exist, failed to archive to hios repository"
            tree -afpsuD -L 8 "$CODE_DIR"/out > ./logs/out_tree_"${NOW}".txt

            git add .
            git commit -m "add apk at ${NOW} project name: ${PROJECT_NAME} armarch: ${armarch} buildtype: ${BUILD_MODE}"  # armarch from rlk_setenv.sh

            git stash   # do not care about the removed libs, in case git pull --rebase error
            git pull --rebase || log_error2 "git pull --rebase failed before git push hios apk"

            # TODO: "origin" here may be invalid for some products some day
            if [ "${DEBUG_MODE}" == "true" ]
            then
                local cmd="echo DEBUG STUB: git push origin HEAD:${ARCHIVE_APK_HIOS_BRANCH}"
            else
                local cmd="git push origin HEAD:${ARCHIVE_APK_HIOS_BRANCH}"
            fi

            eval "$cmd"
            if [ "$?" != 0 ]
            then
                log_error2 "failed to execute command: $cmd"
                return 1
            fi
        popd
    popd
}


function try_archive_vtf_hack(){
    log_info "HACK: TRY ARCHIVING VENDOR TECNO FRAMEWORKS TO BEIJING"
    if [[ "${ARCHIVE_APK_HIOS}" == "false" || "${MANIFEST_XML_NAME_PREFIX}" != "L9_L9LITE_WX3_H80X_HIOS_SHANGHAI" ]]
    then
        log_info "do not need vendor/techo/frameworks archive hack"
        return 0
    fi

    pushd "$CODE_DIR"
        local -r SRC_VTF_DIR="${CODE_DIR}/vendor/tecno/frameworks"
        local -r DEST_VTF_DIR="${CODE_DIR}/VTF"
        local -r DEST_BRANCH="L9_L9LITE_WX3_H80X_HIOS"

        if [ ! -d "${SRC_VTF_DIR}" ]
        then
            log_error2 "vtf dir does not exist: ${SRC_VTF_DIR}"
            return 1
        fi

        # init dest git repository
        rm -rf "${DEST_VTF_DIR}"
        local cmd="git clone ssh://192.168.10.40:29418/MT6580_N/vendor/tecno -b ${DEST_BRANCH} ${DEST_VTF_DIR}"
        eval "$cmd"
        if [ "$?" != 0 ]
        then
            log_error2 "failed to execute command: $cmd , do not do vendor/tecno/frameworks hack any more"
            return 1
        fi

        # copy from src to dest
        rm -rf "${DEST_VTF_DIR}/frameworks/base"
        rsync -ar --exclude '.git' --exclude '.repo' "${SRC_VTF_DIR}/base" "${DEST_VTF_DIR}/frameworks"
        if [ "$?" != 0 ]
        then
            log_error2 "failed to copy VTF code locally"
            return 1
        fi

        pushd "${DEST_VTF_DIR}"
            git add -A .
            git commit -m "add vendor/tecno/frameworks at $(date +%Y%m%d%H%M) project name: ${PROJECT_NAME} armarch: ${armarch} buildtype: ${BUILD_MODE}"

            git stash
            git pull --rebase || log_error2 "git pull --rebase failed before git push vendor/tecno/frameworks"

            # TODO: "origin" here may be invalid for some products some day
            if [ "${DEBUG_MODE}" == "true" ]
            then
                local cmd="echo DEBUG STUB: git push origin HEAD:${DEST_BRANCH}"
            else
                local cmd="git push origin HEAD:${DEST_BRANCH}"
            fi

            eval "$cmd"
            if [ "$?" != 0 ]
            then
                log_error2 "failed to execute command: $cmd"
                return 1
            fi
        popd
    popd
}


function get_archive_dir(){
    local archive_directory="$1"
    local current_date="$2"
    local archive_dir_suffix="$3"
    local debug_suffix="$4"

    if [[ ! -e "${archive_directory}" || -z "${current_date}" ]]
    then
        return 1
    fi

    local archive_dir="${archive_directory}/${current_date}${archive_dir_suffix}${debug_suffix}"

    if [ -e "${archive_dir}" ]
    then
        archive_dir="${archive_directory}/$(date +%Y.%m.%d_%H.%M.%S)${archive_dir_suffix}${debug_suffix}"
    fi

    echo "${archive_dir}"
}


function send_message(){
    local LINUX_DIR="${ARCHIVE_PRODUCT_DIR_RELATIVE}/${ARCHIVE_TIME_DIR_RELATIVE}"
    local -r WIN_DIR=$(echo "${LINUX_DIR}" | tr '/' '\\')
    local message="Version: ${VERSION}
ArchiveDirectory: ${NAS_PATH}\\${WIN_DIR}"

    #rm the last result_properties after the abnormaly exit
    local -r RESULT_DIR="${WORKSPACE_DIR}/result"
    rm -rf "${RESULT_DIR}"

    if [ "${JIRA_CREATE_VERSION}" == "false"  ]
    then
        log_info "JIRA_CREATE_VERSION == false,so need not to create new version after the build" 
    else
        #some variables are used to environment
        log_info "start inject environment varibales"

        #make a dir to save result message
        mkdir "${RESULT_DIR}"
        pushd "${RESULT_DIR}"
            if [ -n "${NUMBER_GLOBAL}" ]
            then
                echo "VERSION=${NUMBER_GLOBAL}" | tee result_properties
            else
                echo "VERSION=${VERSION}" | tee result_properties
            fi
        popd
    fi

    # here send message to external system, such as email
    log_info "$message"
}


# prevent environment variable pollution
function clean_environment(){
    for myvar in "${OPTION_VAR_ARRAY[@]}"
    do
        unset "$myvar"
    done
}


function print_arguments(){
    log_info "command line arguments: "
    for arg in "$@"
    do
        log_info "$arg"
    done
}


function parse_options(){
    # NOTICE: try out best to transform directory paths to absolute paths(e.g. './' -> '/home/user/mycode')
    while [[ $# -gt 1 ]]
    do
        key="$1"

        case "$key" in
            --code-dir)
                readonly CODE_DIR=$(myrealpath "$2")
                is_safe_path "${CODE_DIR}"
                if [ $? != 0 ]
                then
                    log_error2 "path not safe: ${CODE_DIR}, exit abnormally"
                    abnormal_exit
                fi
                mkdir -p "${CODE_DIR}"  # ensure existence before repo init etc.
                ;;
            --base-url)
                readonly BASE_URL="$2"
                is_safe_url "${BASE_URL}"
                if [ $? != 0 ]
                then
                    log_error2 "base url name not safe: ${BASE_URL}, exit abnormally"
                    abnormal_exit
                fi
                ;;
            --manifest-branch)
                readonly MANIFEST_BRANCH="$2"
                is_safe_name_component "${MANIFEST_BRANCH}"  # HACK, not so precise
                if [ $? != 0 ]
                then
                    log_error2 "manifest branch name not safe: ${MANIFEST_BRANCH}, exit abnormally"
                    abnormal_exit
                fi
                ;;
            --xml-name-prefix)
                readonly MANIFEST_XML_NAME_PREFIX="$2"
                if [ -z "${MANIFEST_XML_NAME_PREFIX}" ]
                then
                    log_error2 "xml name prefix empty, exit abnormally"
                    abnormal_exit
                fi

                is_safe_name_component "${MANIFEST_XML_NAME_PREFIX}"
                if [ $? != 0 ]
                then
                    log_error2 "xml name prefix not safe: ${MANIFEST_XML_NAME_PREFIX}, exit abnormally"
                    abnormal_exit
                fi
                ;;
            --manifest-directory)
                if [ -z "${CODE_DIR+x}" ]
                then
                    log_error2 "please set --code-dir before --manifest-directory, exit abnormally"
                    abnormal_exit
                fi

                is_safe_name_component "$2"
                if [ $? != 0 ]
                then
                    log_error2 "manifest directory name not safe: $2, exit abnormally"
                    abnormal_exit
                fi
                readonly MANIFEST_DIRECTORY="${CODE_DIR}"/.repo/manifests/"$2"
                ;;
            --project-name)
                readonly PROJECT_NAME="$2"
                if [ -z "${PROJECT_NAME}" ]
                then
                    log_error2 "project name empty, exit abnormally"
                    abnormal_exit
                fi

                is_safe_name_component "${PROJECT_NAME}"
                if [ $? != 0 ]
                then
                    log_error2 "project name not safe: ${PROJECT_NAME}, exit abnormally"
                    abnormal_exit
                fi
                ;;
            --build-mode)
                readonly BUILD_MODE="$2"
                if [[ "${BUILD_MODE}" != "eng" && "${BUILD_MODE}" != "user" && "${BUILD_MODE}" != "userdebug" && "${BUILD_MODE}" != "gmo_user" ]]
                then
                    log_error2 "build mode error: ${BUILD_MODE}, exit abnormally"
                    abnormal_exit
                fi

                if [ "${BUILD_MODE}" == "eng" ]
                then
                    readonly ENG_SUFFIX="_ENG"
                else
                    readonly ENG_SUFFIX=""
                fi
                ;;
            --otapackage)
                readonly OTAPACKAGE="$2"
                all_switch "${OTAPACKAGE}"
                if [ "$?" != 0 ]
                then
                    log_error2 "--otapackage should be true or false, exit abnormally"
                    abnormal_exit
                fi
                ;;
            --archive-base-dir)
                readonly ARCHIVE_BASE_DIR=$(myrealpath "$2")
                if [ -z "${ARCHIVE_BASE_DIR}" ]
                then
                    log_error2 "archive base directory empty, exit abnormally"
                    abnormal_exit
                fi

                is_safe_path "${ARCHIVE_BASE_DIR}"
                if [ $? != 0 ]
                then
                    log_error2 "archive base directory name not safe: ${ARCHIVE_BASE_DIR}, exit abnormally"
                    abnormal_exit
                fi
                ;;
            --archive-product-dir-relative)
                readonly ARCHIVE_PRODUCT_DIR_RELATIVE="$2"
                if [ -z "${ARCHIVE_PRODUCT_DIR_RELATIVE}" ]
                then
                    log_error2 "archive product dir relative empty, exit abnormally"
                    abnormal_exit
                fi

                # may contain chinese
                is_safe_utf8_path "${ARCHIVE_PRODUCT_DIR_RELATIVE}"
                if [ $? != 0 ]
                then
                    log_error2 "archive product dir relative not safe: ${ARCHIVE_PRODUCT_DIR_RELATIVE}, exit abnormally"
                    abnormal_exit
                fi
                ;;
            --archive-dir-suffix)
                if [ -z "${ENG_SUFFIX+x}" ]
                then
                    log_error2 "please set --build-mode before --archive-dir-suffix, exit abnormally"
                    abnormal_exit
                fi

                readonly ARCHIVE_DIR_SUFFIX="${2}""${ENG_SUFFIX}"
                if [ -n "${ARCHIVE_DIR_SUFFIX}" ]
                then
                    is_safe_name_component "${ARCHIVE_DIR_SUFFIX}"
                    if [ $? != 0 ]
                    then
                        log_error2 "archive directory suffix not safe: ${ARCHIVE_DIR_SUFFIX}, exit abnormally"
                        abnormal_exit
                    fi
                fi
                ;;
            --checksum-util-dir)
                readonly CHECKSUM_UTIL_DIR=$(myrealpath "$2")
                is_safe_path "${CHECKSUM_UTIL_DIR}"
                if [ $? != 0 ]
                then
                    log_error2 "checksum util directory name not safe: ${CHECKSUM_UTIL_DIR}, exit abnormally"
                    abnormal_exit
                fi
                ;;
            --archive-apk-hios)
                readonly ARCHIVE_APK_HIOS="$2"
                all_switch "${ARCHIVE_APK_HIOS}"
                if [ "$?" != 0 ]
                then
                    log_error2 "--archive-apk-hios should be true or false, exit abnormally"
                    abnormal_exit
                fi
                ;;
            --archive-apk-hios-repository)
                readonly ARCHIVE_APK_HIOS_REPOSITORY="$2"
                if [ -n "${ARCHIVE_APK_HIOS_REPOSITORY}" ]
                then
                    is_safe_url "${ARCHIVE_APK_HIOS_REPOSITORY}"
                    if [ $? != 0 ]
                    then
                        log_error2 "archive apk hios repository not safe: ${ARCHIVE_APK_HIOS_REPOSITORY}, exit abnormally"
                        abnormal_exit
                    fi
                fi
                ;;
            --archive-apk-hios-branch)
                readonly ARCHIVE_APK_HIOS_BRANCH="$2"
                if [ -n "${ARCHIVE_APK_HIOS_BRANCH}" ]
                then
                    is_safe_name_component "${ARCHIVE_APK_HIOS_BRANCH}"  # HACK, not so precise
                    if [ $? != 0 ]
                    then
                        log_error2 "archive apk hios branch name not safe: ${ARCHIVE_APK_HIOS_BRANCH}, exit abnormally"
                        abnormal_exit
                    fi
                fi
                ;;
            --push-verno)
                readonly PUSH_VERNO="$2"
                all_switch "${PUSH_VERNO}"
                if [ "$?" != 0 ]
                then
                    log_error2 "--push-verno should be true or false, exit abnormally"
                    abnormal_exit
                fi
                ;;
            --modify-hios-apk-verno)
                readonly MODIFY_HIOS_APK_VERNO="$2"
                all_switch "${MODIFY_HIOS_APK_VERNO}"
                if [ "$?" != 0 ]
                then
                    log_error2 "--modify-hios-apk-verno should be true or false, exit abnormally"
                    abnormal_exit
                fi
                ;;
            --set-mtk-loader-update)
                readonly SET_MTK_LOADER_UPDATE="$2"
                all_switch "${SET_MTK_LOADER_UPDATE}"
                if [ "$?" != 0 ]
                then
                    log_error2 "--set-mtk-loader-update should be true or false, exit abnormally"
                    abnormal_exit
                fi
                if [ "${SET_MTK_LOADER_UPDATE}" == true ]
                then
                    local cmd="export MTK_LOADER_UPDATE=yes"
                    log_info "set MTK_LOADER_UPDATE to yes"
                    log_info "execute: ${cmd}"
                    ${cmd}
                else
                    log_info "no need to reset MTK_LOADER_UPDATE, keep default behavior"
                fi
                ;;
            --debug-mode)
                readonly DEBUG_MODE="$2"
                all_switch "${DEBUG_MODE}"
                if [ "$?" != 0 ]
                then
                    log_error2 "--debug-mode should be true or false, exit abnormally"
                    abnormal_exit
                fi

                if [ -z "${ARCHIVE_BASE_DIR+x}" ]
                then
                    log_error2 "please set --archive-base-dir before --debug-mode, exit abnormally"
                    abnormal_exit
                fi

                if [ "$DEBUG_MODE" == "true" ]
                then
                    log_info "DEBUG MODE IS ON"
                    readonly DEBUG_SUFFIX="_CI_DEBUG"
                    mkdir -p "${ARCHIVE_BASE_DIR}"  # allow temp relative dir for ci debug
                else
                    check_dir "${ARCHIVE_BASE_DIR}"
                fi
                ;;
            --fix-version-number)
                readonly FIX_VERSION_NUMBER="$2"
                if [ -n "$FIX_VERSION_NUMBER" ]
                then
                    is_safe_verison_name "${FIX_VERSION_NUMBER}"
                    if [ "$?" != 0 ]
                    then
                        log_warning "Version number is not correct Please check ${FIX_VERSION_NUMBER}"
                    fi
                    log_info "Fix version is ${FIX_VERSION_NUMBER}"
                else
                    log_info "The current Fix_Version_Number is empty! Following normal version number processing!"
                fi
                ;;
            --ci-smoke-dir)
                readonly CI_SMOKE_DIR="$(myrealpath "$2")"
                if [ -d "${CI_SMOKE_DIR}" ]
                then
                    is_safe_path "${CI_SMOKE_DIR}"
                    if [ $? != 0 ]
                    then
                        log_error2 "ci smoke dir not safe: ${CI_SMOKE_DIR}, exit abnormally"
                        abnormal_exit
                    fi
                else
                    log_info "ci smoke dir does not exist, ignore"
                fi
                ;;
            --local-archive-dir)
                LOCAL_ARCHIVE_DIR="$2"
                if [ -n "${LOCAL_ARCHIVE_DIR}" ]
                then
                    is_safe_path "${LOCAL_ARCHIVE_DIR}"
                    if [ $? != 0 ]
                    then
                        log_error2 "local archive directory name not safe: ${LOCAL_ARCHIVE_DIR}, exit abnormally"
                        abnormal_exit
                    fi
                    LOCAL_ARCHIVE_DIR="$(myrealpath "$2")"
                    log_info "LOCAL_ARCHIVE_DIR designated, archive locally if remote archive failes"
                else
                    log_info "LOCAL_ARCHIVE_DIR not designated, do not archive locally"
                fi
                readonly LOCAL_ARCHIVE_DIR
                ;;
            --secboot)
                readonly SECBOOT="$2"
                all_switch "${SECBOOT}"
                if [ "$?" != 0 ]
                then
                    log_error2 "--secboot should be true or false, exit abnormally"
                    abnormal_exit
                fi
                ;;
            --secboot2)
                readonly SECBOOT2="$2"
                all_switch "${SECBOOT2}"
                if [ "$?" != 0 ]
                then
                    log_error2 "--secboot2 should be true or false, exit abnormally"
                    abnormal_exit
                fi
                ;;
            --no-release)
                readonly NO_RELEASE="$2"
                all_switch "${NO_RELEASE}"
                if [ "$?" != 0 ]
                then
                    log_error2 "--no_release should be true or false."
                fi
                ;;
           --mtk-log)
                readonly MTK_LOG="$2"
                all_switch "${MTK_LOG}"
                if [ "$?" != 0 ]
                then
                    log_error2 "--mtk-log should be true or false."
                fi
                ;;
           --last-manifest)
                LAST_MANIFEST="$2"
                if [ -n "$LAST_MANIFEST" ]
                then
                    is_safe_name_component "${LAST_MANIFEST}"
                    if [ "$?" != 0 ]
                    then
                        LAST_MANIFEST=""
                        echo "${LAST_MANIFEST} is not correct change log will generate normally" >> "${CODE_DIR}"/LAST_MANIFEST.txt
                        log_warning "manifest name is not correct Please check ${LAST_MANIFEST}"
                    fi
                    log_info "From Manifest is ${LAST_MANIFEST}"
                else
                    log_info "The From Manifest is empty! Following normal lastsnapshot processing!"
                fi
                ;;
            --jira-create-version)
                readonly JIRA_CREATE_VERSION="$2"
                all_switch "${JIRA_CREATE_VERSION}"
                if [ "$?" != 0  ]
                then
                    log_error2 "--JIRA-CREATE-VERSION should be true or false,exit abnormally"
                    abnormal_exit
                fi
                ;;
            --verno_suffix)
                readonly VERNO_DEBUG_SUFFIX="$2"
                if [ -n "$VERNO_DEBUG_SUFFIX" ]
                then
                    is_safe_name_component "$VERNO_DEBUG_SUFFIX"
                    if [ "$?" != 0 ]
                    then
                        log_warning "version number debug suffix  is not correct Please check ${VERNO_DEBUG_SUFFIX}"
                        abnormal_exit
                    fi
                    log_info "Version number debug suffix is ${VERNO_DEBUG_SUFFIX}"
                else
                    log_info "The current verno_debug_suffix is empty! Following normal version number processing!"
                fi
                ;;
            *)
                log_error2 "do not allow non-option command line arguments: $1, exit abnormally"
                abnormal_exit
                ;;
        esac
        shift; shift # past option, do not support regular argument
    done

    # ensure all option variables are initialized
    for myvar in "${OPTION_VAR_ARRAY[@]}"
    do
        eval "[ -z \${${myvar}+x} ]"
        if [ "$?" == 0 ]
        then
           log_error2 "${myvar} not set, must be given through command line, exit abnormally"
           abnormal_exit
        fi
    done

    if [[ "${SECBOOT}" == "true" && "${SECBOOT2}" == "true" ]]
    then
        log_error2 "--secboot and --secboot2 should not be set in the same time, exit abnormally"
        abnormal_exit
    fi
}


# initialize regular variables
function init_vars(){
    # initial normal state, state machine 0 -> 1
    # TODO: put it in the very start
    EXECUTE_STATUS=0

    # directories
    readonly ARCHIVE_DIRECTORY="${ARCHIVE_BASE_DIR}/${ARCHIVE_PRODUCT_DIR_RELATIVE}"
    mkdir -p "${ARCHIVE_DIRECTORY}"  # TODO: do in debug mode?
    readonly NAS_PATH=$(guess_nas_path "${ARCHIVE_BASE_DIR}")
    readonly PROJECT_DIR="${CODE_DIR}/rlk_projects/${PROJECT_NAME}"
    readonly WORKSPACE_DIR="$(myrealpath .)"

    # timestamps
    readonly SNAP_TIME=$(date +%Y%m%d%H%M)
    readonly CURRENT_DATE=$(date +%Y.%m.%d)
    readonly LOCAL_PROJECT_BRANCH_NAME=${MANIFEST_XML_NAME_PREFIX}_${PROJECT_NAME}_$(date +%Y%m%d%H%M%S)

    # number parameters
    readonly CONCURRENT_COMPILE_NUM=$(python -c "print int(1 * $(grep -c processor /proc/cpuinfo))")
    readonly HALF_CONCURRENT_COMPILE_NUM=$((CONCURRENT_COMPILE_NUM/2))
    readonly CONCURRENT_SYNC_NUM=12

    # log files
    readonly BUILD_LOG=${CODE_DIR}/build.log
    readonly VERBOSE_BUILD_LOG=${CODE_DIR}/verbose_build.log
    rm -f "${BUILD_LOG}"
    rm -f "${VERBOSE_BUILD_LOG}"

    # secret tag
    readonly SECRET_TAG="${SCRIPTDIR}/secret_tag/内部公开-InternalUse.pdf"
    if [ ! -e "${SECRET_TAG}" ]
    then
        log_error2 "secret tag not found: ${SECRET_TAG}"
    fi

    #sign_image script
    readonly SIGNED_SCRIPT_RELATIVE_SEC11="vendor/mediatek/proprietary/scripts/sign-image/sign_image.sh"
    readonly SIGNED_SYSTEMIMG_SCRIPT_RELATIVE_SEC11="vendor/mediatek/proprietary/scripts/sign-image/sign_systemimg.sh"
    readonly SIGNED_ALLIMG_SCRIPT_RELATIVE_SEC20="vendor/mediatek/proprietary/scripts/sign-image_v2/sign_allimg.sh"
}


function detect_log_error(){
    # error logs like "unified_build.sh: line 927: local: outtargetdirabs: readonly variable"
    grep '^.*: line .* local: .*: readonly variable' "${VERBOSE_BUILD_LOG}" 2>/dev/null
    if [ "$?" == 0 ]
    then
        log_error2 "readonly variables assigned, please check log: ${VERBOSE_BUILD_LOG}"
    fi
}

##################
## MAIN FUNCTION #
##################
function main(){
     ## get ready
     clean_environment
     print_arguments "$@"
     parse_options "$@"
     init_vars
     record_console_log "${VERBOSE_BUILD_LOG}"
     check_disk_space "/"
     check_disk_space "${ARCHIVE_BASE_DIR}"

     ## main process
     sync_code
     make_clean_snapshot
     check_new_commit
     repo_start_project_dir
     modify_local_project_dir_verno
     try_modify_app_version
     make_bin
     try_push_verno
     generate_push_snapshot
     generate_git_log_diff
     try_archive_hios_apk
     try_archive_vtf_hack
     archive_build_output

     ## message system
     send_message

     ## detect error in logs
     detect_log_error

     log_info "MAIN PROCESS IS OVER"
     if [ "${EXECUTE_STATUS}" == 0 ]
     then
         normal_exit
     else
         abnormal_exit
     fi
}

#################################
######  MAIN CALL SECTION  ######
#################################

main "$@"
