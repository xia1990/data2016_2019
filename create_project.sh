#!/bin/bash
#创建远程仓库脚本

$RPOTPATH=`pwd`

for i in `cat project_name.txt`
do    
    ssh -p 29418 10.0.30.10 gerrit create-project $i -t FAST_FORWARD_ONLY -p Privilege/test
    #设置头指针的指向，即切换分枝
    ssh -p 29418 10.0.30.10 gerrit set-head $i  --new-head master
done
