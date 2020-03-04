#!/usr/bin/python
#from __future__ import print_function
import re
import fileinput
import time
import sys
l1=[r'BUILD_PROJECT=.*',r'PRODUCT_NAME=.*','BUILD_PROJECT_NAME=.*']
l2=['BUILD_PROJECT=yao','PRODUCT_NAME=yuan','BUILD_PROJECT_NAME=chun']
if len(l1) != len(l2):
    print "error"
    sys.exit(1)

def modified_args(rs,mo):
    for line in fileinput.input(backup=".bak",inplace=1):
        ss=line.rstrip()
        #print(ss,end="")
        ss=re.sub(rs,mo,ss,1)
        print ss
for i in range(len(l1)):
    modified_args(l1[i],l2[i])
