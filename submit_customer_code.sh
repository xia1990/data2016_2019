#!/bin/bash
#提交客户代码(此脚本只限于P118F使用，全部同步)
#此脚本需要放在代码根目录下执行

PATHROOT=`pwd`
PROJECT=P118F
COMMIT_ID="$1"
describe="[K12-332]状态栏蓝牙快捷键开关，打开与关闭时与实际功能相反"


function reset_code(){
    pushd $PATHROOT/wind
        git pull --rebase
        git reset --hard $COMMIT_ID
    popd
}


function commit_code(){
    pushd $PATHROOT
        rsync -avzp --exclude ".git" --delete ./wind/ ../251_P118F/wind/
        cd ../251_P118F/wind/
            rm -rf custom_files/NOHLOS/
            git checkout custom_files/device/qcom/P118F/version
            git add .
            #定义提交模板的信息
            message="[Subject]\n[$PROJECT]\n[Bug Number/CSP Number/Enhancement/New Feature]\nN/A\n[Ripple Effect]\nN/A\n[Solution]\nN/A\n[Project]\n[$PROJECT]\n\n\n"
            #提交信息
            commit_message=$(echo -e $message | sed "0,/\[$PROJECT\]/s/\[$PROJECT\]/&$describe/")
            #提交文件类型
            #TYPE=$(git status -s | awk '{print $1}')
            #提交文件列表
            filelist=$(git status | grep "custom_files")
            #git commit -m "$commit_message\n\t\t$filelist"

            #此处处理换行问题
            git commit --amend -m "$commit_message \n\t\t $filelist"


            #ssh -p 29418 10.0.30.251 gerrit review $COMMIT_ID --code-review +2
            #ssh -p 29418 10.0.30.251 gerrit review $COMMIT_ID --submit
        cd -
    popd
}



function main(){
    reset_code
    commit_code
}

################### MAIN ###################
main "$#"
