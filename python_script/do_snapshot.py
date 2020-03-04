#!/usr/bin/python
import os
import sys
import xml.etree.ElementTree as ET
import shutil
import getopt
import subprocess
import shlex
import commands

args_list = sys.argv
input_file=''
output_file=''
projects_list=[]
remotes_dict={}
wrong_path_list=[]
local_or_remote=""

def dir_check():
    os.system('repoc init -u ssh://10.0.30.9:29418/MSM89XX_O_CODE_SW3/manifest -b PDU3_DEV  --no-repo-verify')
    if not os.path.isdir('.repo'):
        print "wrong code path"
        sys.exit()

def find_xml():
    root_pwd=os.getcwd()
    if os.path.isdir('.repo/manifests/'):
        os.chdir('.repo/manifests')
        file_list=list(os.walk('.'))
        input_file_path=''
        for y in file_list:
            if input_file in y[2]:
                pwd=os.getcwd()
                input_file_path=os.path.join(pwd,y[0])
                input_file_path=os.path.join(input_file_path,input_file)
        if input_file_path:
            os.chdir(root_pwd)
            shutil.copy(input_file_path,'.')
            print "input file name: ", input_file
        else:
            print "do not find: ",input_file
            sys.exit()

def args_prosess():
    opt,args = getopt.getopt(args_list[1:],"i:o:h",["input=","output="])
    for key,value in opt:
        if key == '-h':
            print "Useage:",args_list[0],"-i input.txt -o ouput.txt -h"
            sys.exit()
        elif key == '-i':
            global input_file
            input_file = value
            if os.path.isfile(input_file):
                print "input file name: ",input_file
            else:
                find_xml()

        elif key == '-o':
            global output_file
            output_file = value
            print "output file name: ", output_file
    if len(args_list) < 6:
        print "Useage: python do_snapshot.py -i default.xml -o test.xml local"
        sys.exit()
    else:
        global local_or_remote
        local_or_remote=args[0]
        print local_or_remote," do snapshot"

    if not input_file or not output_file:
        print "error,do not have enough file"
        sys.exit()

def get_remote_commit_id(fetch,name,revision):
    shell_str='git ls-remote %s%s %s' % (fetch,name,revision)
    shell_args=shlex.split(shell_str)
    p=subprocess.Popen(shell_args,stdout=subprocess.PIPE)
    result_code=p.wait()
    if result_code == 0:
        commit_id = p.stdout.readline().split()[0]
        print commit_id
        return commit_id
    else:
        print "get commit-id error"
        sys.exit()

def get_local_commit_id(path):
    pwd=os.getcwd()
    if os.path.isdir(path):
	    os.chdir(path)
	    print path
            result=commands.getstatusoutput('git log --oneline')
            if result[0] != 0:
                os.chdir(pwd)
                wrong_path_list.append(path)
                return None
	    commit_ids=commands.getoutput("git log --pretty=oneline | awk '{print $1}'")
	    commit_id=commit_ids.split()[0]
	    print commit_id
	    os.chdir(pwd)
	    return commit_id
    else:
        print "wrong path",path
        wrong_path_list.append(path)
        return None
    
def do_snapshot():
    tree = ET.parse(input_file)
    root = tree.getroot()
    default_remote=root.find('default').get('remote')
    if default_remote is None:
        print "no default remote"
        sys.exit()
    default_revision=root.find('default').get('revision')
    if default_revision is None:
        print "no default revision"

    for j in root.findall('remote'):
        fetch = j.get('fetch')
        if fetch is None:
            print "error,fetch is Mone"
            sys.exit()
        name = j.get('name')
        if name is None:
            print 'error,name is None'
            sys.exit()
        remotes_dict[name]=fetch

    for i in root.iter('project'):
        name = i.get('name')
        if name is None:
            print "name is None"
            sys.exit()

        path = i.get('path')
        if path is None:
            path = name

        remote = i.get('remote')
        if remote is None:
            remote = default_remote

        revision = i.get('revision')
        if revision is None:
            revision = default_revision
        upstream = i.get('upstream')
        if upstream is None:
            upstream = revision
        if local_or_remote == "remote":
            commit_id = get_remote_commit_id(remotes_dict[remote],name,revision)
        elif local_or_remote == "local":
            commit_id = get_local_commit_id(path)
        else:
            print "wrong args",local_or_remote
            sys.exit()
        if commit_id is not None:
	    i.attrib['upstream']=upstream
            i.attrib['revision']=commit_id
    tree.write(output_file)



if __name__ == "__main__":
    dir_check()
    args_prosess()
    do_snapshot()
    f=open('wrong_path.txt','w')
    for i in wrong_path_list:
        f.write(i+"\n")
    f.flush()
    f.close()
