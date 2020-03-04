#!/usr/bin/python
import getopt
import sys
import os
from xml.etree import ElementTree as ET
import subprocess
import threading
import time

args_list=[]
str_doc="""
-b new branch name
-c code path
-x branch base xml
-h help
--code=path
--branch=branch_name
"""
code_path=''
branch_name=''
xml_base=''
cwd=os.getcwd()

def args_parse():
    global args_list,code_path,branch_name,xml_base
    args_list=sys.argv

    if len(args_list) == 1:
        print('Useage: python push_branch.py -c . -b dev')
        print('Useage: python push_branch.py --code=. --branch=dev')
        sys.exit()

    opt,args = getopt.getopt(args_list[1:],"b:c:x:h",["code=","branch=","help"])
    for key,value in opt:
        if key == "-h" or key == "--help":
            print str_doc
            sys.exit()
        elif key == '-c' or key == '--code':
            if not os.path.exists(value):
                print(value+' do not exist')
                sys.exit()
            else:
                code_path=value
            if os.path.isfile(xml_base):
                print('code and xml can not exist at one time')
                sys.exit()
        elif key == '-x':
            xml_base=value
            try:
                tree = ET.parse(value)
            except Exception,e:
                print(e)
                sys.exit()
            if os.path.exists(code_path):
                print('code and xml can not exist at one time')
                sys.exit()
        elif key == '-b' or key == '--branch':
            branch_name = value 

class MypushThread(threading.Thread):
    def __init__(self,path,revision,origin):
        super(MypushThread,self).__init__()
        self.path = path
        self.revision = revision
        self.origin = origin

    def run(self):
        global cwd
        thread_locker.acquire()
        os.chdir(cwd)
        if os.path.isdir(self.path):
            os.chdir(self.path)
            print os.getcwd()
            subprocess.call('git push {0} HEAD:{1}'.format(self.origin,self.revision),shell=True)
            #subprocess.call('git push origin HEAD:{}'.format(self.revision),shell=True)
            thread_locker.release()
            time.sleep(1)
            thread_locker.acquire()
            os.chdir(cwd)
        else:
            print os.getcwd(),self.path
        thread_locker.release()

def code_create_branch():
    thread_list=[]
    pwd = os.getcwd()
    os.chdir(code_path)
    global branch_name
    if not os.path.exists('.repo'):
        print('not repo path')
        sys.exit()
    subprocess.call('repoc start {} --all'.format(branch_name),shell=True)
    path_str=subprocess.check_output("repoc forall -c 'echo $REPO_PATH $REPO_REMOTE'",shell=True)
    path_list=path_str.split(os.linesep)
    count=0
    for path_l in path_list:
        if not path_l:
            break
        path_l_list=path_l.split()
        thread_l=MypushThread(path_l_list[0],branch_name,path_l_list[1])
        thread_l.start()
        count+=1
        thread_list.append(thread_l)
        if count == branch_limit:
            for i in thread_list:
                i.join()
            time.sleep(1)
            thread_list=[]
            count=0
    if thread_list:
        for i in thread_list:
            i.join()
            
if  __name__ == "__main__":
    branch_limit=20
    thread_locker=threading.Lock()
    args_parse()
    code_create_branch() 
