#!/bin/bash
#uid_name=`whoami`
#cur_time=`date +%m%d-%H%M%S`
#file_name=$1
#other_name=$2
#echo "begin"
#echo $file_name
#tar -czf $other_name.tar.gz  $file_name
#zip -r $other_name.apk $other_name.tar.gz
#cp $other_name.apk /data/mine/test/yaoyuanchun/
#rm -rf $other_name.tar.gz
#rm -rf $other_name.apk
#echo "done"

function release_file(){
    local -r file_name="$1"
    local -r re_filename="$2"
    echo -e "\e[32m$file_name ==> $re_filename.apk\e[0m"
    tar -czf $re_filename.tar.gz  $file_name
    zip -r "${re_filename}.apk" "${re_filename}.tar.gz"
    cp "${re_filename}.apk" "/data/mine/test/MT6572/${USER}/"
    echo -e "\e[32mrelease successful\e[0m"
    rm "$re_filename.tar.gz" "${re_filename}.apk"
}

release_file "$1" "$2"
