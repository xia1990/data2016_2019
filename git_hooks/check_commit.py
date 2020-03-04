#!/usr/bin/python
# _*_ coding:utf-8 _*_
import sys
import re
message_file=sys.argv[1]
with open(message_file) as fe:
    s = fe.read()
    res1 = re.findall(r'[\[]',s)
    res2 = re.findall(r'[\]]',s)
    if not len(res1) == 5 or not len(res2) == 5:
        print('中括号个数变更')
        sys.exit(1)
        
    sts=re.split("[\[\]]",s)
    stt=[]
    for line in sts:
        if line:
            stt.append(line)
    for i,line1 in enumerate(stt):
        if i == 0 and not re.findall(r'subject',line1):
            print("subject 标题被改写")
            sys.exit(1)
        if i == 1 and not re.findall(r'Project',line1):
            print('Project 标题被修改')
            sys.exit(1)
        if i == 1 and line1.split()[1] == 'xxxx':
            print('Project 信息没有写')
            sys.exit(1)
        if i == 2 and line1.split()[0] == 'FeatureID/BugID/PatchID':
            print('ID 标题只能写一个')
            sys.exit(1)            
        if i == 2 :
            if line1.split()[0] == 'FeatureID' or line1.split()[0] == 'BugID' or line1.split()[0] == 'PatchID':
                pass
            else:
                print('ID 标题必须写一个')
                sys.exit(1)
        if i == 2 and line1.split()[1] == 'xxxx':
            print('ID 信息需要写')
            sys.exit(1)
        if i == 3 and not line1.split()[0] == 'Module':
            print('Module 标题被改写')
            sys.exit(1)
        if i == 3 and line1.split()[1] == 'xxxx':
            print('Module 信息需要写')
            sys.exit(1)
        if i == 4 and line1 == 'xxxx':
            print('提交描述信息需要写')
            sys.exit(1)
        if i == 5 and not re.findall(r'Ripple Effect',line1):
            print('Ripple Effect 标题被修改')
            sys.exit(1)
        if i == 6 and line1 == 'xxxx':
            print('波及分析需要写')
            sys.exit(1)
