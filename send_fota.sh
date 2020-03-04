#!/bin/bash
CMD='curl -k -X POST -H "X-FOTA-USERID: PMD_WD" -H "X-FOTA-TOKEN:a42110d41ae77b618b03b776f19bce25" -H "X-FOTA-VERSION:14.01.1706.06-user_CN_X00K-14.01.1706.07-user-CN_X00K-1485" --form "modeltype=phone" --form "carrier=CTCC-ASUS_X00KD-CN_X00K" --form "model=CN_X00K" --form "edition=formal" --form "extra_storage=350" --form "priority=force_P1" --form "activatetime=30" --form "desc=" --form "uploadfile=@E:\14.01.1706.06-user_CN_X00K-14.01.1706.07-user-CN_X00K\CN_X00K-14.01.1706.06-20170607_CN_X00K-14.01.1706.07-20170613.zip" https://dmcontrol.asus.com/DM-server/UploadFile'
function get_build_prop(){
    local -r target_file=$(ls full_*-target_files-*.zip | head -1)
    rm -rf build.prop
    unzip -j "$target_file" "SYSTEM/build.prop" -d .
    carrier=$(grep "ro.product.carrier" build.prop | head -1 | awk -F "=" '{print $2}')
    model=$(grep "ro.build.version.incremental" build.prop | head -1 | awk -F "=" '{print $2}' | awk -F "-|_" '{print $1"_"$2}')
    echo "carrier: $carrier model:$model"
}


function cp_rename_dir(){
    be_send_fota="$1"
    dirname=$(echo "$be_send_fota"  | awk -F "-|_" '{print $3"-user-"$1"_"$2"-"$7"-user-"$5"_"$6}')
    rm -rf /cygdrive/e/"$dirname"
    mkdir /cygdrive/e/"$dirname"
    change_name_fota=$(echo "$be_send_fota" | sed -n "s/-fota\|_fota//g"p)
    cp "$be_send_fota" /cygdrive/e/"$dirname/$change_name_fota" && echo "cp successful"
}


function fix_cmd(){
    count="$1"
    CMD=$(echo "$CMD" | sed -n "s/carrier=CTCC-ASUS_X00KD-CN_X00K/carrier=$carrier/p")
    CMD=$(echo "$CMD" | sed -n "s/model=CN_X00K/model=$model/g"p)
    CMD=$(echo "$CMD" | sed -n "s/X-FOTA-VERSION:14.01.1706.06-user_CN_X00K-14.01.1706.07-user-CN_X00K-1485/X-FOTA-VERSION:$dirname-$count/g"p)
    CMD=$(echo "$CMD" | sed -n "s/14.01.1706.06-user_CN_X00K-14.01.1706.07-user-CN_X00K/$dirname/g"p)
    CMD=$(echo "$CMD" | sed -n "s/CN_X00K-14.01.1706.06-20170607_CN_X00K-14.01.1706.07-20170613.zip/$change_name_fota/g"p)
    echo '#!/bin/bash' > ss.sh
    chmod u+x ss.sh
    echo "$CMD" | tee -a ss.sh
#    source ss.sh
    rm ss.sh
}

function main(){
    if [ ! -s "$1" ]
    then
        echo "$1 do not exist"
        exit 1
    fi
    get_build_prop 
    cp_rename_dir "$1"
    fix_cmd "$2"
}

main $1 $2
