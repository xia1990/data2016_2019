#!/bin/bash
change_version_number(){
if [ "$#" -eq 0 ] #参数个数为0 报错，就是没有传入版本号文件当做参数
then
	echo "no args"
	exit 1
fi
version_number_file="$1"
if [ -s "$version_number_file" ] #版本号文件存在切非空
then
	gw=$(grep -i "PRODUCT_POINT_VERSION.*:=" "$version_number_file" |  awk '{print $NF}') #查找PRODUCT_POINT_VERSION 最后数字
	gw_1=$((gw+1)) #数字加1
	if [ "$gw_1" -eq 10 ] #如果加一后等于10
	then
		gw_1=0 #加一后的当前位置 变为0
		sw=$(grep "PRODUCT_MINOR_VERSION.*:=" "$version_number_file" |  awk '{print $NF}') #查找PRODUCT_MINOR_VERSION 最后数字
		sw_1=$((sw+1)) #数字加1
		if [ "$sw_1" -eq 10 ] #如果加一后等于10
		then
			sw_1=0 #加一后的当前位置 变为0
			bw=$(grep "PRODUCT_MAJOR_VERSION.*:=" "$version_number_file" |  awk '{print $NF}') #查找PRODUCT_MAJOR_VERSION 最后数字
			bw_1=$((bw+1)) #数字加一 最后一位不判断是否到了10.到了就到了
			sed -i "s/PRODUCT_POINT_VERSION.*:=.*/PRODUCT_POINT_VERSION\ :=\ ${gw_1}/g" "$version_number_file" #修改PRODUCT_POINT_VERSION 数字
			sed -i "s/PRODUCT_MINOR_VERSION.*:=.*/PRODUCT_MINOR_VERSION\ :=\ ${sw_1}/g" "$version_number_file" #修改PRODUCT_POINT_VERSION 数字
			sed -i "s/PRODUCT_MAJOR_VERSION.*:=.*/PRODUCT_MAJOR_VERSION\ :=\ ${bw_1}/g" "$version_number_file" #修改PRODUCT_MAJOR_VERSION 数字
		else
			sed -i "s/PRODUCT_POINT_VERSION.*:=.*/PRODUCT_POINT_VERSION\ :=\ ${gw_1}/g" "$version_number_file" #修改PRODUCT_POINT_VERSION 数字
			sed -i "s/PRODUCT_MINOR_VERSION.*:=.*/PRODUCT_MINOR_VERSION\ :=\ ${sw_1}/g" "$version_number_file" #修改PRODUCT_POINT_VERSION 数字
		fi
	else
		sed -i "s/PRODUCT_POINT_VERSION.*:=.*/PRODUCT_POINT_VERSION\ :=\ ${gw_1}/g" "$version_number_file" #修改PRODUCT_POINT_VERSION 数字
	fi
else
	echo "$version_number_file not found" #版本号文件未发现
	exit 1
fi
}

change_version_number "supplier_buildinfo.mk"
