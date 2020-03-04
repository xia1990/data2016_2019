#!/usr/bin/python
import os
import re
import subprocess as sp
import urlparse
root_path=os.getcwd()
home_path='/'.join(root_path.split('/')[0:3])
config_file = home_path+'/'+'.ssh/config'
f=open(config_file)
f_list = f.readlines()
f.close()
res=sp.check_output('git config remote.STS001.review',shell=True)
ip=urlparse.urlsplit(res).hostname

def create_Host_list(l):
    lists = []
    ldict={}
    for i,line in enumerate(l):
        if re.findall(r'^host',line,re.I):
            lists.append(i)
    l_lists = len(lists)
    for j,k in enumerate(lists):
        if not j+1  == l_lists:
            ldict['host'+str(j)] = l[k:lists[j+1]]
        else:
            ldict['host'+str(j)] = l[k:]
    for key,value in ldict.items():
        for line in value:
            if re.findall(ip,line):
                dest_dd = ldict[key]
    for line in dest_dd:
        if re.findall('hostname',line,re.I):
            dest_ip=line.split()[1]
        elif re.findall('user',line,re.I):
            dest_user_name=line.split()[1]

class Host(object):
    def __init__(self,H_host,H_hostname,H_user):
        self.H_host = H_host
        sefl.H_hostname = H_hostname
        self.H_user = H_user

    create_Host_list(f_list)
