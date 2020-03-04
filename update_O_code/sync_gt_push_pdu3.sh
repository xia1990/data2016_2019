#!/bin/bash
ROOT=$(pwd)
PROJECT_PREFIX="MSM89XX_O_CODE_SW3"
SERVER_IP="10.0.30.9"
PORT="29418"
BRANCH="qualcomm"
rm change_git_repo_name.txt change_git_repo_path.txt > /dev/null 2>&1

function log(){
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

function get_git_path(){
    log "good" "path"
    while read line
    do
        grep "$line" new_code.xml > grep_result.txt
        if [ "$?" == 0 ]
        then
            while read iv
            do
                local line_exist="false"
                local line_name=$(echo $iv | grep -aoe "name=[.A-Z_a-z0-9\"/-]*" | awk -F '"' '{print $2}')
                if [ "$line" == "$line_name" ]
                then
                    line_exist="true"
                    path=$(echo "$iv" | grep -aoe "path=[.A-Z_a-z0-9\"/-]*" | awk -F '"' '{print $2}')
                    if [ "$path" == "" ]
                    then
                        path="$line"
                    fi
                    echo "$path" | tee -a change_git_repo_path.txt
                    break
                fi
            done < grep_result.txt
            if [ "$line_exist" == "false" ]
            then
                log "error" "name 值在new_code.xml中没有找到 false" && exit 1
            fi
            rm grep_result.txt
            unset line_exist line_name path iv
        else
            log "error" "name 值在new_code.xml中没有找到" && exit 1
        fi
    done < change_git_repo_name.txt
}


function incremental_git_repositories_prosess(){
   rm  gerrit_projects_name_list.txt > /dev/null 2>&1
   local project_profix="$1"
   pushd "$ROOT"
       ssh -p ${PORT} "$SERVER_IP" gerrit ls-projects -r "$project_profix".* >  gerrit_projects_name_list.txt
       rm incremental_projects_name_list.txt > /dev/null 2>&1
       while read line
       do
           grep "^MSM89XX_O_CODE_SW3/${line}$" gerrit_projects_name_list.txt > /dev/null
           if [ "$?" != 0 ]
           then
               log "info" "新增仓库: $line"
               echo "$line" >> incremental_projects_name_list.txt
           fi
       done < change_git_repo_name.txt
       unset line
       rm gerrit_projects_name_list.txt local_grep_result > /dev/null 2>&1

       rm incremental_projects_path_list.txt > /dev/null 2>&1
	if [ -s "incremental_projects_name_list.txt" ]
	then
            while read line
            do
                grep "$line" new_code.xml > grep_result.txt
                if [ "$?" == 0 ]
                then
                    while read iv
                    do
                        local line_exist="false"
                        local line_name=$(echo $iv | grep -aoe "name=[.A-Z_a-z0-9\"/-]*" | awk -F '"' '{print $2}')
                        if [ "$line" == "$line_name" ]
                        then
                            line_exist="true"
                            path=$(echo "$iv" | grep -aoe "path=[.A-Z_a-z0-9\"/-]*" | awk -F '"' '{print $2}')
                            if [ "$path" == "" ]
                            then
                                path="$line"
                            fi
                            echo "$path" >> incremental_projects_path_list.txt
                            break
                        fi
                    done < grep_result.txt
                    if [ "$line_exist" == "false" ]
                    then
                        log "error" "name 值在new_code.xml中没有找到 false" && exit 1
                    fi
                    rm grep_result.txt
                    unset line_exist line_name path iv
                else
                    log "error" "name 值在new_code.xml中没有找到" && exit 1
                fi
            done < incremental_projects_name_list.txt
	fi

       if [ -s "incremental_projects_name_list.txt" ]
       then
           cp change_git_repo_name.txt change_git_repo_name_backup.txt
           cp change_git_repo_path.txt change_git_repo_path_backup.txt
           while read line
           do
               grep -n "$line" change_git_repo_name.txt > local_grep_result
               if [ "$?" != 0 ]
               then
                   log "error" "faile to grep $line,剔除操作失败" && exit 1
               else
                   grep_result_line=$(wc -l local_grep_result | awk '{print $1}')
#TODO 一行不一定等于自己，但这里特殊点。因为这里查找的东西原本就来自被查找文件。所以一定有，和上面的不同。
                   if [ "$grep_result_line" -eq 1 ]
                   then
                       local line_no=$(cat local_grep_result | awk -F ":" '{print $1}')
                   else
                       for q in $(cat local_grep_result)
                       do
                           local value=$(echo $q | awk -F ":" '{print $2}')
                           local line_exist="false"
                           if [ "$line" == "$value" ]
                           then
                               line_exist="true"
                               line_no=$(echo $q | awk -F ":" '{print $1}')
                               break
                           fi
                       done
                       if [ "$line_exist" == "false" ]
                       then
                           log "error" "新增仓库在原始仓库名单中没有找到" && exit 1
                       fi
                   fi
               fi

               sed -i "${line_no}d" change_git_repo_name.txt
               sed -i "${line_no}d" change_git_repo_path.txt
           done < incremental_projects_name_list.txt
           unset line_no grep_result_line value line_exist q line
           rm local_grep_result > /dev/null 2>&1
	else
	    log "info" "没有新增仓库"
        fi
   popd > /dev/null
}

function update_check(){
pushd "$ROOT"
#    if [ -d ".repo" ]
#    then
#        repo manifest -ro old_code.xml #打个老快照 用来和新快照对比 看看有么有仓库更新
#        [ "$?" != 0 ] && log "error" "do old snapshot failed" && exit 1
#    else
#        log "error" "代码路径错误,当前目录下没有 .repo 文件夹" && exit 1
#    fi
#    repo sync -j4
    #if [ "$?" == 0 ]
    #then
    #    repo manifest -ro new_code.xml #打个新快照 用来和老快照对比 看看有么有仓库更新
    #    [ "$?" != 0 ] && log "error" "do new snapshot failed" && exit 1
    #fi

    diff_name_array=($(diff old_code.xml new_code.xml | grep -aoe "name=[.A-Z_a-z0-9\"/-]*" | awk -F '"' '{print $2}'| sort -u))

    log "notice" "${#diff_name_array[@]}"
    if [ "${#diff_name_array[@]}" == 0 ]
    then
        log "notice" "没有更新,退出！！！"
        exit 1
    fi

    log "good" "name"
    for i in ${diff_name_array[@]}
    do
        echo $i | tee -a change_git_repo_name.txt
    done
    unset i diff_name_array
    get_git_path
popd > /dev/null
}


function safe_push_check_and_push(){
    local git_url="$1"
    local git_branch="$2"
    pushd "$ROOT"
        readarray -t change_git_repo_path_array < change_git_repo_path.txt
        readarray -t change_git_repo_name_array < change_git_repo_name.txt
        if [ "${#change_git_repo_path_array[@]}" != "${#change_git_repo_name_array[@]}" ]
        then
            echo "error path array length do not equal name array length"
            exit 1
        fi

        length="${#change_git_repo_name_array[@]}"
        reallength=$((length - 1))
        rm "$ROOT"/name_path_not_equal.txt "$ROOT"/log_update > /dev/null 2>&1
        for i in `seq 0 $reallength`
        do
            change_git_repository="${change_git_repo_path_array[$i]}"
            [ -d "$change_git_repository" ] && pushd "$change_git_repository" && pushd_successful="true"
                if [ "$pushd_successful" == "true" ]
                then
                    git ls-remote "$git_url"/"${change_git_repo_name_array[$i]}" "$git_branch" > "$ROOT"/ls_head_commit_id.txt
                    if [ "$?" != 0 ]
                    then
                        log "notice"  "path:$change_git_repository  name:${change_git_repo_name_array[$i]}" | tee -a "$ROOT"/name_path_not_equal.txt
                    else
                        commit_id=$(cat "$ROOT"/ls_head_commit_id.txt | awk '{print $1}')
                        commit_line_no=$(git log --pretty=oneline |grep -n "$commit_id" | awk -F ":" '{print $1}')
                        if [ "$commit_line_no" -ne 1 ]
                        then
                            echo "PATH: $change_git_repository" >> "$ROOT"/log_update
                            git log --pretty=oneline | sed -n "1,${commit_line_no}"p >> "$ROOT"/log_update
                            echo "#############" >> "$ROOT"/log_update

                        fi
                        git log --pretty=oneline | grep "$commit_id" > /dev/null
                        if [ "$?" != 0 ]
                        then
                            log "error"  "30.9 ${change_git_repo_name_array[$i]} 仓库的最新提交，在本仓库上没有发现，push 会报错"
                            exit 1
                        fi
                   
    

                        #git push "$git_url"/"${change_git_repo_name_array[$i]}" HEAD:"$git_branch" --dry-run
                        #if [ "$?" == 0 ]
                        #then
                        #    git push "$git_url"/"${change_git_repo_name_array[$i]}" HEAD:"$git_branch"
                        #    [ "$?" != 0 ] && log "error" "push failed" && exit 1
                        #else
                        #    log "error" "push DEBUG failed "
                        #    exit 1
                        #fi
                    fi
                fi
            [ "$pushd_successful" == "true" ] && popd > /dev/null
            unset pushd_successful change_git_repository
        done
        unset length reallength
        rm "$ROOT"/ls_head_commit_id.txt
        
    popd > /dev/null
    
}


function create_projects(){
    local -r branchName="master"
    pushd "$ROOT"
    if [ ! -s incremental_projects_name_list.txt  ]
    then
        log "error" "incremental_projects_name_list.txt 文件不存在"
        exit 1
    else
        readarray -t incremental_projects_array < incremental_projects_name_list.txt
        for i in "${incremental_projects_array[@]}"
        do
            ssh -p ${PORT} $SERVER_IP gerrit create-project -n "$PROJECT_PREFIX"/"${i}" --empty-commit -b $branchName -t FAST_FORWARD_ONLY -p All-Projects
            [ "$?" == 0 ] && log "good" "create project "$PROJECT_PREFIX"/"${i}" successful"
        done
        unset i
    fi
    popd > /dev/null
}


function push_incremental_projects(){
    local git_url="$1"
    local git_branch="$2"
    pushd "$ROOT"
    if [[ -s "incremental_projects_name_list.txt" && -s "incremental_projects_path_list.txt" ]]
    then
        local name_line_count=$(wc -l incremental_projects_name_list.txt | awk '{print $1}')
        local path_line_count=$(wc -l incremental_projects_path_list.txt | awk '{print $1}')
        if [ "$name_line_count" !=  "$path_line_count" ]
        then
            log "error" "新增name path 个数不相等" && exit 1
        fi
        readarray -t incremental_name_array < incremental_projects_name_list.txt
        readarray -t incremental_path_array < incremental_projects_path_list.txt

        for i in `seq 0 $((path_line_count -1))`
        do
            [ -d "${incremental_path_array[$i]}" ] && pushd "${incremental_path_array[$i]}" && pushd_successful="true"
                if [ "$pushd_successful" == "true" ]
                then
                    ###本地必须有分支才能push成功
                    git push "$git_url"/"${incremental_name_array[$i]}" HEAD:"$git_branch" --dry-run
                    if [ "$?" == 0 ]
                    then
                        git push "$git_url"/"${incremental_name_array[$i]}" HEAD:"$git_branch"
                    else
                        log "error" "push DEBUG failed"
                        exit 1
                fi
            fi
            [ "$pushd_successful" == "true" ] && popd > /dev/null
        unset pushd_successful
    done
    fi
    popd > /dev/null
}

####main####
readonly rooter="$1"
if [[ "$rooter" == "first_push" ]]
then
    repoc list > name_path.txt
    while read line
    do
        #千万不要拿 : 当分隔符
        name=$(echo $line | awk  '{print $3}')
        path=$(echo $line | awk  '{print $1}')
        echo $name >> change_git_repo_name.txt
        echo $path >> change_git_repo_path.txt
    done < name_path.txt
    rm name_path.txt
    repoc manifest -ro new_code.xml
    incremental_git_repositories_prosess "$PROJECT_PREFIX"
    #safe_push_check_and_push  "ssh://${SERVER_IP}:${PORT}/${PROJECT_PREFIX}" "$BRANCH"
elif [ "$rooter" == "push" ]
then
    log "notice" "常规push操作"
    update_check
    incremental_git_repositories_prosess "$PROJECT_PREFIX"
    safe_push_check_and_push  "ssh://${SERVER_IP}:${PORT}/${PROJECT_PREFIX}" "$BRANCH"

elif [ "$rooter" == "create" ]
then
    log "notice" "新增仓库新建并push操作"
    create_projects
    push_incremental_projects "ssh://${SERVER_IP}:${PORT}/${PROJECT_PREFIX}" "$BRANCH"
fi
