#!/usr/bin/python3
# _*_ coding:utf-8 _*_
from xml.etree import ElementTree as ET
import sys
import os
import paramiko
import re

ip="10.0.30.9"
port=22
username="log_git"
password="log_git"


def args_check():
    if len(sys.argv) != 3:
        print('error,not enough args')
        sys.exit(1)
    for i in sys.argv:
        if not os.path.isfile(i):
            print("%s is not file " % i)
            sys.exit(1)
    global old_xml,new_xml
    old_xml=sys.argv[1]
    new_xml=sys.argv[2]


def parse_xml():
    old_tree = ET.parse(old_xml)
    new_tree = ET.parse(new_xml)
    old_root = old_tree.getroot()
    new_root = new_tree.getroot()

    old_name_list=[]
    old_commit_id_list=[]
    for node_old in old_root.iter('project'):
        old_name=node_old.attrib["name"]
        old_name_list.append(old_name)
        old_commit_id=node_old.attrib["revision"]
        old_commit_id_list.append(old_commit_id)
        assert len(old_name_list) ==  len(old_commit_id_list)
    old_dict=dict(zip(old_name_list,old_commit_id_list))
        
    new_name_list=[]
    new_commit_id_list=[]
    for node_new in new_root.iter('project'):
        new_name=node_new.attrib["name"]
        new_name_list.append(new_name)
        new_commit_id=node_new.attrib["revision"]
        new_commit_id_list.append(new_commit_id)
        assert len(new_name_list) ==  len(new_commit_id_list)
    new_dict=dict(zip(new_name_list,new_commit_id_list))
    
    increment_name_list=[]
    for name in new_dict.keys():
        if name not in old_dict:
            increment_name_list.append(name)
        else:
            old_commit_id = old_dict[name]
            new_commit_id = new_dict[name]
            if old_commit_id != new_commit_id:
                get_log(name,old_commit_id,new_commit_id)


def get_log(path_name,old_commit_id,new_commit_id):
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect(ip,port,username,password)
    stdin,stdout,stder=ssh.exec_command('cd git/{0}.git;git log  {1} --pretty=format:"%H"\,"%an"\,"%s" {2}'.format(path_name,'MTK_BRH',new_commit_id))
    stdout_str=stdout.read().decode('utf-8')
    log_list=stdout_str.split('\n')
    for i,j in enumerate(log_list):
        if re.findall(old_commit_id,j):
            break
    real_log_list=log_list[0:int("{0}".format(i))]
    f=open('log.txt','a+')
    f.write('PATH:'+path_name+'\n')
    for line in real_log_list:
        f.write(line+'\n')
    f.close()
    ssh.close()
    

if __name__ == "__main__":
    args_check()
    parse_xml()
