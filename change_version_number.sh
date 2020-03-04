#!/bin/bash

change_version_number(){
	if [ "$#" -eq 0 ];then
		echo "no args"
		exit 1
	fi
	version_number_file="$1"
	#如果版本号文件存在(-s:判断文件长度大于0，且非空)
	if [ -s "$version_number_file" ];then
		#查找PRODUCT_POINT_VERSION最后数字
		gw=$(grep -i "PRODUCT_POINT_VERSION.*:=" "$version_number_file" | awk '{print $NF}')
		#PRODUCT_POINT_VERSION加1
		gw_1=$((gw+1))
		#修改PRODUCT_POINT_VERSION的数字
		sed -i "s/PRODUCT_POINT_VERSION.*:=.*/PRODUCT_POINT_VERSION\ :=\ ${gw_1}/g" "$version_number_file"
	else
		#如果版本号不存在
		echo "$version_number_file not found"
		exit 1
	fi
	PRODUCT_MAJOR_VERSION=$(grep -i "PRODUCT_MAJOR_VERSION.*:=" "$version_number_file" | awk '{print $NF}')
    PRODUCT_MINOR_VERSION=$(grep -i "PRODUCT_MINOR_VERSION.*:=" "$version_number_file" | awk '{print $NF}')
    PRODUCT_POINT_VERSION=$(grep -i "PRODUCT_POINT_VERSION.*:=" "$version_number_file" | awk '{print $NF}')
    PRODUCT_STAGE=$(grep -i "PRODUCT_STAGE.*:=" "$version_number_file" | awk '{print $NF}')
    DATE=`date +%Y%m%d`
    SUPPLIER_VERSION_EXTERNAL=${PRODUCT_MAJOR_VERSION}.${PRODUCT_MINOR_VERSION}.${PRODUCT_POINT_VERSION}.${DATE}_${PRODUCT_STAGE}
    echo ${SUPPLIER_VERSION_EXTERNAL}	
	#T10_LA1.1.1_Branch_ENG_${SUPPLIER_VERSION_EXTERNAL}_R6.0_PRC
}
change_version_number "supplier_buildinfo.mk"

