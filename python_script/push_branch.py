#!/usr/bin/python
import subprocess
import threading
import os
import time
cwd=os.getcwd()
paht_list=[]
thread_list=[]

class MypushThread(threading.Thread):
    def __init__(self,path,revision):
        super(MypushThread,self).__init__()
        self.path = path
        self.revision = revision

    def run(self):
        global cwd
        thread_locker.acquire()
        os.chdir(cwd)
        if os.path.isdir(self.path):
            os.chdir(self.path)
            thread_locker.release()
            print('%s git push origin HEAD:%s' % (self.path ,self.revision))
            time.sleep(1)
            thread_locker.acquire()
            os.chdir(cwd)
        else:
            print os.getcwd(),self.path
        thread_locker.release()

def get_repo_path():
    os.chdir(cwd)
    path_str=subprocess.check_output("repo forall -c 'echo $REPO_PATH'",shell=True)
    global path_list
    path_list=path_str.split()

if __name__ == "__main__":
    branch_limit=20
    thread_locker=threading.Lock()
    get_repo_path()
    print 'get repo path successful'
    count=0
    for path_l in path_list: 
        thread_l=MypushThread(path_l,"master")
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

