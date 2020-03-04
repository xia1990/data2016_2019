#!/bin/bash

PATHROOT=`pwd`
PRODUCT="ms8937_64"
RADIO_PATH=$PATHROOT/device/qcom/msm8937_64/radio
VARIANT=userdebug

function makeOta()
{
    echo "start to make otapackage"
    cd $PATHROOT/out/target/product/$PRODUCT/
        cp emmc_appsboot.mbn mdtp.img $RADIO_PATH
    cd -
    source build/envsetup.sh
    if [ x$VARIANT == x"userroot" ] ; then
        lunch $PRODUCT-user
    else
        lunch $PRODUCT-$VARIANT
        echo "lunch end"
    fi
    make otapackage
}

makeOta
