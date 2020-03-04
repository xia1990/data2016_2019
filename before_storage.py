#!/usr/bin/python
#_*_ coding:utf-8 _*_
#编译前入库编译（就是change入库前，将提交 cherry-pick到本地编译的脚本）
#1：查找gerrit上open状态的所有提交
#2：使用cherry-pick方法，把open状态的提交PICK到本地
#3：所有代码pick到本地后，进行编译

#ssh -p 29418 10.0.30.10 gerrit query branch:master_32 project:^LNX_LA_SDM450_S102X_PSW/.* status:open --format JSON --current-patch-set --files | egrep "project^ number|revision|Depends-On"> message.txt

ssh -p 29418 10.0.30.10 gerrit query branch:master project:^LNX_LA_RK3399_FireFly_X200_PSW/.* status:merged --format JSON 
--current-patch-set --files | egrep "project^ number|revision|Depends-On" > message.txt
with open("message.txt") as f:
    line1=f.readline()
    print(type(line1))
