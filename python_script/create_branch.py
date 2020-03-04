#!/usr/bin/python
# -*- coding: UTF-8 -*-
import requests
from pprint import pprint
from requests.auth import HTTPDigestAuth
import json
import sys
project_name=""
branch_name=""
base_branch=""
ip=""
args_list=sys.argv

class GerritHttp(object):
    def __init__(self,user,passwd,header=None,datas=None):
        self.user=user
        self.passwd=passwd
        self.header=header
        self.datas=datas
        self.auth=HTTPDigestAuth(self.user, self.passwd)
        auth=self.auth
        
    def get(self,key):
        if hasattr(self,key):
            return getattr(self,key)
        else:
            return None

def create_project(ip,project_name,branch_name,base_branch_name):
    headers={'Content-Type': 'application/json; charset=UTF-8'}
    datas=json.dumps({'revision': '{}'.format(base_branch_name)})     
    GH=GerritHttp('gerrit','VAHg7MGtGf7kcH8WoAK/0Ez+ZEFz9Cn+IayG0HpkoA',headers,datas) 
    r1_https='http://{0}/a/projects/{1}/branches/{2}'.format(ip,project_name,branch_name)
    r1=requests.get(r1_https,auth=GH.get('auth'))
    if r1.status_code == 200:
        print('{} branch aleady exist'.format(branch_name))
    elif r1.status_code == 404:
        r = requests.put('http://{0}/a/projects/{1}/branches/{2}'.format(ip,project_name,branch_name), auth=GH.get('auth'),data=GH.get('datas'),headers=GH.get('header'))
        if r.status_code == 201:
            print "create {} successful".format(branch_name)
            print(r.content)
    else:
        print "unknow error"

def args_parse():
    global ip,project_name,branch_name,base_branch
    if len(args_list) < 5:
        print "error,not enough args"
        sys.exit()
    else:
        ip=args_list[1]
        project_name=args_list[2]
        branch_name=args_list[3]
        base_branch=args_list[4]
    
if __name__ == "__main__":
    args_parse()
    create_project(ip,project_name,branch_name,base_branch)
