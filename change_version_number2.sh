#!/bin/bash
#此函数用来修改T10项目版本号（修改规则是逢10进1位的方法）
change_version_number(){
	#$#在此处表示参数的个数
	if [ "$#" -eq 0 ];then
		echo "no args"
		exit 1
	fi
	#版本号文件
	version_number_file="$1"
	#如果版本号文件存在且不为空
	if [ -s "$version_number_file" ];then
		gw=$(grep -i "PRODUCT_POINT_VERSION.*:=" "$version_number_file" | awk '{print $NF}')
		gw_1=$((gw+1))
		#如果PRODUCT_POINT_VERSION加1后等10
		if [ "$gw_1" -eq 10];then
			#PRODUCT_POINT_VERSION为0，向前进一位
			gw_1=0
			sw=$(grep -i "PRODUCT_MINOR_VERSION.*=" "$version_number_file" | awk '{print $NF}')
			sw_1=$((sw+1))
			if [ "$sw_1" -eq 10 ];then
				sw_1=0
				bw=$(grep -i "PRODUCT_MAJOR_VERSION.*=" "$version_number_file" | awk '{print $NF}')
				bw_1=$((bw+1))
				sed -i "s/PRODUCT_POINT_VERSION.*:=.*/PRODUCT_POINT_VERSION\ :=\ ${gw_1}/g" "$version_number_file"
				sed -i "s/PRODUCT_MINOR_VERSION.*:=.*/PRODUCT_MINOR_VERSION\ :=\ ${sw_1}/g" "$version_number_file"
				sed -i "s/PRODUCT_MAJOR_VERSION.*:=.*/PRODUCT_MAJOR_VERSION\ :=\ ${bw_1}/g" "$version_number_file"
			else
				sed -i "s/PRODUCT_POINT_VERSION.*:=.*/PRODUCT_POINT_VERSION\ :=\ ${gw_1}/g" "$version_number_file"
				sed -i "s/PRODUCT_MINOR_VERSION.*:=.*/PRODUCT_MINOR_VERSION\ :=\ ${sw_1}/g" "$version_number_file"
			fi
		else
			sed -i "s/PRODUCT_POINT_VERSION.*:=.*/PRODUCT_POINT_VERSION\ :=\ ${gw_1}/g" "$version_number_file"
		fi
	else
	#如果版本号文件不存在
		echo "$version_number_file not found"
	fi
	PRODUCT_MAJOR_VERSION=$(grep -i "PRODUCT_MAJOR_VERSION.*:=" "$version_number_file" | awk '{print $NF}')
    PRODUCT_MINOR_VERSION=$(grep -i "PRODUCT_MINOR_VERSION.*:=" "$version_number_file" | awk '{print $NF}')
    PRODUCT_POINT_VERSION=$(grep -i "PRODUCT_POINT_VERSION.*:=" "$version_number_file" | awk '{print $NF}')
    PRODUCT_STAGE=$(grep -i "PRODUCT_STAGE.*:=" "$version_number_file" | awk '{print $NF}')
    DATE=`date +%Y%m%d`
    SUPPLIER_VERSION_EXTERNAL=${PRODUCT_MAJOR_VERSION}.${PRODUCT_MINOR_VERSION}.${PRODUCT_POINT_VERSION}.${DATE}_${PRODUCT_STAGE}
    echo ${SUPPLIER_VERSION_EXTERNAL}
}
#在此处调用函数
change_version_number "supplier_buildinfo.mk"
