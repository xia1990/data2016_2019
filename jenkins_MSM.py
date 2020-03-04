#!/usr/bin/python
# _*_ coding:UTF-8 _*_
import os
import getopt
import sys
import subprocess
import shutil
import socket
import time
import re
import fileinput
import zipfile
import random
import time
import tarfile
today=time.strftime('%Y%m%d')
hostname=socket.gethostname()
pwd=os.getcwd()
mirror_path={"SOFT35-11":'/home/jenkins/mirror/',"SOFT35-12":'/home/jenkins/mirror/',"SOFT35-15":'/home1/SW3/mirror/',"SOFT35-16":'/home1/SW3/mirror/',"SOFT35-17":'/home/jenkins/mirror/',"SOFT35-14":'/home1/SW3/mirror/',"SOFT35-18":'/home/jenkins/mirror/'}
args_list=sys.argv
args_obj=""
CODE_DIR="CODE"

def in_check(VAR,VAR_LIST):
    if VAR not in VAR_LIST:
        print '{0} not in {1}'.format(VAR,str(VAR_LIST))
        sys.exit()

class Args(object):
    bool_stat = ['true','false']
    def __init__(self,PROJECT_NAME,CODE_URL,CODE_BRANCH,CODE_XML,CLEAN_CODE,BUILD_PROJECT,IN_VERSION,OUT_VERSION,INCREMENTAL_VERSION,VARIANT,HARD_VER,SAVE_TYPE,OTAPACKAGE,MODULE,DOWNLOAD_TYPE,WAIT_BUILD):
        self.PROJECT_NAME = PROJECT_NAME
        self.CODE_URL = CODE_URL
        self.CODE_BRANCH = CODE_BRANCH
        self.CODE_XML = CODE_XML
        self.CLEAN_CODE = CLEAN_CODE
        if CLEAN_CODE not in Args.bool_stat:
            print CLEAN_CODE,'value error'
            sys.exit()
        self.BUILD_PROJECT = BUILD_PROJECT
        self.custom = 'driveonly'
        if len(self.BUILD_PROJECT.split('_')) == 2:
            self.custom = self.BUILD_PROJECT.split('_')[1]
        else:
            self.custom = "driveonly"
        self.IN_VERSION = IN_VERSION
        self.OUT_VERSION = OUT_VERSION
        self.INCREMENTAL_VERSION = INCREMENTAL_VERSION
        self.VARIANT = VARIANT
        if VARIANT == 'eng':
            self.VARIANT = ""
        self.HARD_VER = HARD_VER
        self.SAVE_TYPE=SAVE_TYPE
        self.OTAPACKAGE = OTAPACKAGE
        self.MODULE = MODULE
        self.DOWNLOAD_TYPE = DOWNLOAD_TYPE
        if DOWNLOAD_TYPE == "qf":
            self.DOWNLOAD_TYPE = ""
        self.WAIT_BUILD = WAIT_BUILD
    def args_check(self):
        global PROJECT_NAME_LIST
        PROJECT_NAME_LIST=['E300L','E300L_8.1','A306','A307','Z225','A308']
        BUILD_PROJECT_LIST=['E300L_WW','E300L_CN','E300L_IN','A306','A307','Z225','A308']
        VARIANT_LIST=['user','eng','debug',""]
        SAVE_TYPE_LIST=['dailybuild','factory','preofficial','temp']
        BOOL_LIST=['true','false']
        MODULE_LIST=['all','overall']
        DOWNLOAD_TYPE_LIST=['qf','xtt',""]
        in_check(self.PROJECT_NAME,PROJECT_NAME_LIST)
        in_check(self.BUILD_PROJECT,BUILD_PROJECT_LIST)
        in_check(self.VARIANT,VARIANT_LIST)
        in_check(self.SAVE_TYPE,SAVE_TYPE_LIST)
        in_check(self.OTAPACKAGE,BOOL_LIST)
        in_check(self.MODULE,MODULE_LIST)
        in_check(self.DOWNLOAD_TYPE,DOWNLOAD_TYPE_LIST)
        in_check(self.WAIT_BUILD,BOOL_LIST)
        

def args_parse():
    #print 'START TO PARSE ARGS'
    a=os.system('echo args_parse')
    del a
    opt,args = getopt.getopt(args_list[1:],"h",["project-name=","code-url=","code-branch=","code-xml=","clean-code=","build-project=","ver=",'variant=','hard-ver=','save-type=','otapackage=','module=','download_type=','wait_build='])
    for key,value in opt:
        if key == "-h" or key == "--help":
            print "no help message hahahahhaha"
            sys.exit()
        elif key == "--project-name":
            PROJECT_NAME=value
        elif key == "--code-url":
            CODE_URL=value
        elif key == "--code-branch":
            CODE_BRANCH=value
        elif key == "--code-xml":
            CODE_XML=value
        elif key == "--clean-code":
            CLEAN_CODE=value
        elif key == "--build-project":
            BUILD_PROJECT=value
        elif key == "--ver":
            VERSION=value
            if VERSION:
                IN_VERSION=VERSION.split()[0]
                OUT_VERSION=VERSION.split()[1]
                INCREMENTAL_VERSION=VERSION.split()[2]
            else:
                IN_VERSION=""
                OUT_VERSION=""
                INCREMENTAL_VERSION=""

        elif key == "--variant":
            VARIANT=value
        elif key == "--hard-ver":
            HARD_VER=value
        elif key == '--save-type':
            SAVE_TYPE=value
        elif key == '--otapackage':
            OTAPACKAGE=value
        elif key == '--module':
            MODULE=value
        elif key == '--download_type':
            DOWNLOAD_TYPE=value
        elif key == '--wait_build':
            WAIT_BUILD=value

    global args_obj
    args_obj=Args(PROJECT_NAME,CODE_URL,CODE_BRANCH,CODE_XML,CLEAN_CODE,BUILD_PROJECT,IN_VERSION,OUT_VERSION,INCREMENTAL_VERSION,VARIANT,HARD_VER,SAVE_TYPE,OTAPACKAGE,MODULE,DOWNLOAD_TYPE,WAIT_BUILD)
    args_obj.args_check()
         
def down_load_code(url,branch,xml):
    #print "START TO DOWNLOAD CODE"
    a=os.system('echo down_load_code')
    del a
    projects_mirror_path="abc"
    projects_mirror={('E300L','A306','A307','A308'):'300_mirror_repo',('E300L_8.1',):'300_8.1_mirror_repo',('Z225',):'Z225_mirror_repo'}
    for i in projects_mirror.keys():
        if args_obj.PROJECT_NAME in i:
            projects_mirror_path=projects_mirror[i]

    os.chdir(pwd)
    if os.path.exists(CODE_DIR) and args_obj.CLEAN_CODE == "true":
        shutil.rmtree(CODE_DIR)
    try:
        os.mkdir(CODE_DIR)
    except OSError,e:
        print e
    os.chdir(CODE_DIR)
    if hostname in mirror_path:
#little bug here
        if os.path.exists(mirror_path[hostname]+projects_mirror_path):
            os.chdir(mirror_path[hostname]+projects_mirror_path)
            result=subprocess.Popen('repoc sync -j3',shell=True)
            result.wait()
            time.sleep(2)
            os.chdir(os.path.join(pwd,CODE_DIR))
            result1=subprocess.Popen('repoc init -u {0} -b {1} -m {2} --no-repo-verify --reference={3}'.format(args_obj.CODE_URL,args_obj.CODE_BRANCH,args_obj.CODE_XML,mirror_path[hostname])+projects_mirror_path,shell=True)
            result1.wait()
        else:
            result1=subprocess.Popen('repoc init -u {0} -b {1} -m {2} --no-repo-verify'.format(args_obj.CODE_URL,args_obj.CODE_BRANCH,args_obj.CODE_XML),shell=True)
            result1.wait()
    else:
        result1=subprocess.Popen('repoc init -u {0} -b {1} -m {2} --no-repo-verify'.format(args_obj.CODE_URL,args_obj.CODE_BRANCH,args_obj.CODE_XML),shell=True)
        result1.wait()

    time.sleep(1)
    result2=subprocess.Popen('repoc sync -cj4',shell=True)
    result2.wait()

def modified_auto_args():
    #print('START TO MODIFIED AUTO ARGS')
    a=os.system('echo modified_auto_args')
    del a
    if args_obj.PROJECT_NAME=='Z225':
        return 0
    os.chdir(os.path.join(pwd,CODE_DIR))
    shutil.copy('vendor/wind/scripts/Auto_MSM89XX_E300L_V1.0.sh','auto.sh')
    for ih in fileinput.input('auto.sh',inplace=True):
        if len(re.findall(r'^BUILD_PROJECT=.+',ih)):
            new_line=re.sub(r'^BUILD_PROJECT=.+','BUILD_PROJECT={0}'.format(args_obj.BUILD_PROJECT),ih)
            sys.stdout.write(new_line)
        elif len(re.findall(r'^PRODUCT_NAME=.+',ih)):
            new_line=re.sub(r'^PRODUCT_NAME=.+','PRODUCT_NAME={0}'.format(args_obj.BUILD_PROJECT),ih)
            sys.stdout.write(new_line)
        elif len(re.findall(r'^BUILD_PROJECT_NAME=.+',ih)):
            new_line=re.sub(r'^BUILD_PROJECT_NAME=.+','BUILD_PROJECT_NAME={0}'.format(args_obj.BUILD_PROJECT),ih)
            sys.stdout.write(new_line)
        elif len(re.findall(r'^IN_VERSION=.*',ih)):
            new_line=re.sub(r'^IN_VERSION=.*','IN_VERSION={0}'.format(args_obj.IN_VERSION),ih)
            sys.stdout.write(new_line)
        elif len(re.findall(r'^OUT_VERSION=.*',ih)):
            new_line=re.sub(r'^OUT_VERSION=.*','OUT_VERSION={0}'.format(args_obj.OUT_VERSION),ih)
            sys.stdout.write(new_line)
        elif len(re.findall(r'^INCREMENTAL_VERSION=.*',ih)):
            new_line=re.sub(r'^INCREMENTAL_VERSION=.*','INCREMENTAL_VERSION={0}'.format(args_obj.INCREMENTAL_VERSION),ih)
            sys.stdout.write(new_line)
        elif len(re.findall(r'^VARIANT=.*',ih)):
            new_line=re.sub(r'^VARIANT=.*','VARIANT={0}'.format(args_obj.VARIANT),ih)
            sys.stdout.write(new_line)
        elif len(re.findall(r'^MODULE=.*',ih)):
            new_line=re.sub(r'^MODULE=.*','MODULE={0}'.format(args_obj.MODULE),ih)
            sys.stdout.write(new_line)
        elif len(re.findall(r'^RELEASE_PROJECT=.*',ih)):
            new_line=re.sub(r'^RELEASE_PROJECT=.*','RELEASE_PROJECT={0}'.format(args_obj.BUILD_PROJECT),ih)
            sys.stdout.write(new_line)
        elif len(re.findall(r'^RELEASE_TYPE=.*',ih)):
            new_line=re.sub(r'^RELEASE_TYPE=.*','RELEASE_TYPE={0}'.format(args_obj.MODULE),ih)
            sys.stdout.write(new_line)
        elif len(re.findall(r'^DOWNLOAD_TYPE=.*',ih)):
            new_line=re.sub(r'^DOWNLOAD_TYPE=.*','DOWNLOAD_TYPE={0}'.format(args_obj.DOWNLOAD_TYPE),ih)
            sys.stdout.write(new_line)
        elif len(re.findall(r'^CORE=.*',ih)):
            new_line=re.sub(r'^CORE=.*','CORE={0}'.format('32'),ih)
            sys.stdout.write(new_line)
        else:
            sys.stdout.write(ih)
    
def modified_hard_version():
    #print "START TO MODIFIED HARD VERSION"
    a=os.system('echo modified_hard_version')
    del a
    os.chdir(os.path.join(pwd,CODE_DIR))
    if args_obj.BUILD_PROJECT == 'E300L_IN':
        os.chdir('device/wind/E300L_WW')
    elif args_obj.BUILD_PROJECT == 'A307' or args_obj.BUILD_PROJECT == 'A306' or args_obj.BUILD_PROJECT == 'A308' :
        os.chdir('device/wind/A306')
    else:
        return 0
    if args_obj.HARD_VER:
        if args_obj.BUILD_PROJECT == 'E300L_IN':
            hard_mk_file='E300L_WW.mk'
        else:
            hard_mk_file='{0}.mk'.format(args_obj.BUILD_PROJECT)
        for ih in fileinput.input(hard_mk_file,inplace=True):
            if len(re.findall(r'WIND_PRODUCT_HARDWARE :=',ih)) != 0:
                new_line=re.sub(r"WIND_PRODUCT_HARDWARE :=.*",'WIND_PRODUCT_HARDWARE := {0}'.format(args_obj.HARD_VER),ih)
                sys.stdout.write(new_line)
            else:
                sys.stdout.write(ih)

def clean_bbtd():
    os.chdir('/data/mine/test/MT6572/jenkins/')
    print 'start to clean bbtd'
    for i in os.listdir(os.curdir):
        if os.path.isfile(i):
            os.remove(i)
        else:
            shutil.rmtree(i)

    os.chdir(pwd);os.chdir(CODE_DIR)
    time.sleep(10)

def successful_check(filename):
    old_pwd=os.getcwd()
    os.chdir('build-log')
    p1=subprocess.call('tail -n 10 {0} > result.log'.format(filename),shell=True)
    ex=False
    with open('result.log') as f:
        for i in f.readlines():
            result_len=re.findall(r'successfully',i)
            if result_len:
                ex=True
    if not ex:
        print('version build failed !!!!!')
        sys.exit()
    os.chdir(old_pwd)


def modified_quick_build_core():
    a=os.system('echo modified_quick_build_core')
    del a
    os.chdir(pwd);os.chdir(CODE_DIR)
    for ih in fileinput.input('quick_build.sh',inplace=True):
        if len(re.findall(r'CPUCORE=8',ih)):
            new_line=re.sub(r'CPUCORE=8','CPUCORE=24',ih)
            sys.stdout.write(new_line)
        else:
            sys.stdout.write(ih)
    


def modified_release_path():
    a=os.system('echo modified_release_path')
    del a
    os.chdir(pwd);os.chdir(CODE_DIR)
    version_path='version_path'
    if os.path.exists(version_path):
        shutil.rmtree(version_path)
    os.mkdir(version_path)
    abs_version_path=os.path.join(os.path.join(pwd,CODE_DIR),version_path)
    for ih in fileinput.input('release_version.sh',inplace=True):
        if len(re.findall(r'/data/mine/test/MT6572/\$user',ih)):
            new_line=re.sub(r'/data/mine/test/MT6572/\$user',abs_version_path,ih)
            sys.stdout.write(new_line)
        else:
            sys.stdout.write(ih)


def release_version():
    #print "START TO RELAESE VERSION"
    a=os.system('echo release_version')
    del a
    new_project_info()
    os.chdir(os.path.join(pwd,CODE_DIR))

    if os.path.exists('version_path'):
        shutil.rmtree('version_path')
    try:
        os.mkdir('version_path')
    except OSError,e:
        print e
    if args_obj.PROJECT_NAME=='Z225':
        result1=subprocess.Popen('./release_version.sh',shell=True)
        result1.wait()
        time.sleep(5)
        return 0
    if args_obj.PROJECT_NAME=='A308':
        result1=subprocess.Popen('./release_version.sh efuse',shell=True)
        result1.wait()
        time.sleep(5)
        return 0

    if args_obj.MODULE == 'all':
        if args_obj.VARIANT == 'eng' or args_obj.VARIANT == "" :
            result1=subprocess.Popen('./release_version.sh {0} {1} symbols'.format(args_obj.BUILD_PROJECT,args_obj.DOWNLOAD_TYPE),shell=True)
            result1.wait()
        elif args_obj.VARIANT == 'user':
            result1=subprocess.Popen('./release_version.sh {0} {1} user symbols'.format(args_obj.BUILD_PROJECT,args_obj.DOWNLOAD_TYPE),shell=True)
            result1.wait()
        elif args_obj.VARIANT == 'debug':
            result1=subprocess.Popen('./release_version.sh {0} {1} debug symbols'.format(args_obj.BUILD_PROJECT,args_obj.DOWNLOAD_TYPE),shell=True)
            result1.wait()
    elif args_obj.MODULE == 'overall':
        if args_obj.VARIANT == 'eng' or args_obj.VARIANT == "":
            result1=subprocess.Popen('./release_version.sh {0} overall {1} symbols'.format(args_obj.BUILD_PROJECT,args_obj.DOWNLOAD_TYPE),shell=True)
            result1.wait()
        elif args_obj.VARIANT == 'user':
            result1=subprocess.Popen('./release_version.sh {0} overall {1} user symbols'.format(args_obj.BUILD_PROJECT,args_obj.DOWNLOAD_TYPE),shell=True)
            result1.wait()
    time.sleep(5)



def version_build():
    #print "START TO BUILD VERSION"
    a=os.system('echo "version_build"')
    del a
    os.chdir(pwd);os.chdir(CODE_DIR)
    if os.path.isfile('/home/jenkins/project.info'):
        os.remove('/home/jenkins/project.info')

    os.chdir(pwd);os.chdir(CODE_DIR)
    if args_obj.PROJECT_NAME=='Z225':
        result1=subprocess.Popen('./quick_build.sh all new efuse',shell=True,stdin=subprocess.PIPE)
        result1.wait()
    elif args_obj.PROJECT_NAME =='A308':
        result1=subprocess.Popen('./quick_build.sh A308 all new',shell=True,stdin=subprocess.PIPE)
        result1.wait()
    else:
        if os.path.isfile('auto.sh'):
            result1=subprocess.Popen('./auto.sh',shell=True,stdin=subprocess.PIPE)
            if args_obj.OTAPACKAGE == 'true':
                result1.stdin.write('2'+os.linesep)
                result1.wait()
                release_version() #先释放一下 生成 overall_all_images等文件夹，不然 otapackage没法编译

                result2=subprocess.Popen('./auto.sh',shell=True,stdin=subprocess.PIPE)
                result2.stdin.write('3'+os.linesep)
                result2.wait()

                successful_check('android.log')
                successful_check('otapackage.log')
            else:
                result1.stdin.write('2'+os.linesep)
                result1.wait()
                successful_check('android.log')
        else:
            print "error no auto.sh"
            sys.exit()

def make_zip(source_dir,output_filename):
    zipf=zipfile.ZipFile(output_filename,'w',allowZip64=True,compression=zipfile.ZIP_DEFLATED)
    for path,sondir,filenames in os.walk(source_dir):
        if filenames:
            for filename in filenames:
                print 'Adding ',filename
                zipf.write(path+os.path.sep+filename)
    zipf.close()

def new_project_info():
    os.chdir('/home/jenkins/')
    with open('project.info','w') as pf:
        pf.write('type={0}'.format(args_obj.SAVE_TYPE)+os.linesep)
        pf.write('project={0}'.format(args_obj.PROJECT_NAME)+os.linesep)
        pf.write('custom={0}'.format(args_obj.custom)+os.linesep) #TODO drive only

        if args_obj.SAVE_TYPE in ('preofficial','factory','temp'):
            if os.path.exists('/jenkins/{0}_version/{1}/{2}/{3}'.format(args_obj.SAVE_TYPE,args_obj.PROJECT_NAME,args_obj.custom,args_obj.IN_VERSION)):
                pf.write('version={0}_{1}'.format(args_obj.IN_VERSION,int(random.random()*1000))+os.linesep)
            else:
                pf.write('version={0}'.format(args_obj.IN_VERSION)+os.linesep)
        elif args_obj.SAVE_TYPE == 'dailybuild':
            if os.path.exists('/jenkins/{0}_version/{1}/{2}_dailybuild/{3}'.format(args_obj.SAVE_TYPE,args_obj.PROJECT_NAME,args_obj.custom,today)):
                pf.write('version={0}_{1}'.format(today,int(random.random()*1000))+os.linesep)
            else:
                pf.write('version={0}'.format(today)+os.linesep)
            pf.write('option=custom:{0}_dailybuild'.format(args_obj.custom)+os.linesep)
        pf.flush()


def release_ota():
    #print "START TO RELEASE OTA"
    a=os.system('echo release_ota')
    del a
    if args_obj.PROJECT_NAME=='Z225':
        return 0
    if args_obj.OTAPACKAGE == 'false':
        return 1
    os.chdir(os.path.join(pwd,CODE_DIR))
    if os.path.exists('version_path'):
        shutil.rmtree('version_path')
    try:
        os.mkdir('version_path')
    except OSError,e:
        print e

    if args_obj.VARIANT == 'user': 
        UL_type='user'
    else:
        UL_type='eng'
    UL_sku='WW'
    if args_obj.PROJECT_NAME == 'E300L_8.1' or args_obj.PROJECT_NAME == 'E300L':
        UL_device='ASUS_X00P'
    else:
        UL_device='ASUS_X00R'
    incre_no=args_obj.OUT_VERSION.split('-')[1]
    

    if args_obj.MODULE == 'overall':
        if args_obj.PROJECT_NAME == 'E300L' or args_obj.PROJECT_NAME == 'E300L_8.1':
            result1=subprocess.Popen('./release_version.sh E300L_IN ota',shell=True)
            result1.wait()
        else:
            print 'Error overall 没有其他项目了'
    else:
        result1=subprocess.Popen('./release_version.sh {0} ota'.format(args_obj.BUILD_PROJECT),shell=True)
        result1.wait()
    time.sleep(5)

    for i in os.listdir('version_path'):
        if len(re.findall(r'[a-zA-Z0-9_]*-ota',i)) != 0:
            shutil.copy('version_path/'+i,'/data/mine/test/MT6572/jenkins/UL-{0}-{1}-{2}-{3}.zip'.format(UL_device,UL_sku,incre_no,UL_type))
        else:
            shutil.copy('version_path/'+i,'/data/mine/test/MT6572/jenkins/{0}'.format(i))
   
def do_snapshot():
    a=os.system('echo do_snapshot')
    del a
    os.chdir(os.path.join(pwd,CODE_DIR))
    result1=subprocess.Popen('repoc manifest -ro manifest-{0}_{1}.xml'.format(args_obj.IN_VERSION,today),shell=True)
    result1.wait()
    shutil.copy('manifest-{0}_{1}.xml'.format(args_obj.IN_VERSION,today),'/data/mine/test/MT6572/jenkins/')

def quick_build_do_not_release():
    a=os.system('echo quick_build_do_not_release')
    del a
    if args_obj.PROJECT_NAME=='Z225':
        return 0
    os.chdir(os.path.join(pwd,CODE_DIR))
    for ih in fileinput.input('quick_build.sh',inplace=True):
        if re.findall(r'release_version.sh',ih):
            if ih[:-1].lstrip() != './release_version.sh $PRODUCT amssbackup':
                sys.stdout.write('#'+ih)
                sys.stdout.write(':'+os.linesep)
            else:
                sys.stdout.write(ih)
        else:
            sys.stdout.write(ih)

def tar_unzip_file(target_file,unzip_path):
    tar = tarfile.open(target_file,'r:gz')
    filenames=tar.getnames()
    for name in filenames:
        tar.extract(name,unzip_path)
    tar.close()

def unzip_file(target_file,unzip_path):
    zf = zipfile.ZipFile(target_file)
    for name in zf.namelist():
        zf.extract(name,unzip_path)
    zf.close()

def get_fastboot(dest_path):
    if args_obj.DOWNLOAD_TYPE == 'xtt':
        return 1
    if args_obj.PROJECT_NAME == 'E300L' or args_obj.PROJECT_NAME == 'E300L_8.1':
        fastboot_path=os.path.join(pwd,'SCM_script/fastboot/E300L/')
    elif args_obj.PROJECT_NAME == 'A306':
        fastboot_path=os.path.join(pwd,'SCM_script/fastboot/A306/')
    elif args_obj.PROJECT_NAME == 'A307' or args_obj.PROJECT_NAME == 'A308':
        fastboot_path=os.path.join(pwd,'SCM_script/fastboot/A306/')
    for ifile in os.listdir(fastboot_path):
        shutil.copy(fastboot_path+ifile,dest_path+ifile)

def process_release_file():
    a=os.system('echo process_release_file')
    del a
    os.chdir(os.path.join(pwd,CODE_DIR))
    os.chdir('version_path')
    if args_obj.PROJECT_NAME=='Z225':
        for l_file in os.listdir('.'):
            if len(re.findall('225',l_file)):
                os.rename(l_file,'updateA2B.zip')    
        for l_file in os.listdir('.'):
            shutil.copy(l_file,'/data/mine/test/MT6572/jenkins/')
        return 0
    if args_obj.MODULE != 'overall' and args_obj.DOWNLOAD_TYPE == 'xtt':
        os.remove('sparse_images.tar.gz.apk')
    if args_obj.MODULE == 'overall':
        shutil.copy('overall_symbols.zip','/data/mine/test/MT6572/jenkins/')
    else:
        shutil.copy('all_symbols.zip','/data/mine/test/MT6572/jenkins/')
        os.remove('all_symbols.zip')
        if args_obj.DOWNLOAD_TYPE == 'xtt':
            os.mkdir(args_obj.IN_VERSION+'_DL')
            if args_obj.BUILD_PROJECT == 'E300L_IN':
                out_img_path='../out/target/product/E300L_WW/sparse_images/'
            else:
                out_img_path='../out/target/product/{0}/sparse_images/'.format(args_obj.BUILD_PROJECT)

            for ifile in os.listdir(out_img_path):
                shutil.copy(out_img_path+ifile,args_obj.IN_VERSION+'_DL')

            for ifile in os.listdir(os.curdir):
                if ifile != args_obj.IN_VERSION+'_DL':
                    shutil.move(ifile,args_obj.IN_VERSION+'_DL')
            make_zip(args_obj.IN_VERSION+'_DL',args_obj.IN_VERSION+'_DL.zip')
        else:
            os.mkdir(args_obj.IN_VERSION+'_DL')
            for ifile in os.listdir(os.curdir):
                if ifile != args_obj.IN_VERSION+'_DL':
                    shutil.move(ifile,args_obj.IN_VERSION+'_DL')
            get_fastboot(args_obj.IN_VERSION+'_DL/')	
            make_zip(args_obj.IN_VERSION+'_DL',args_obj.IN_VERSION+'_DL.zip')

    shutil.copy(args_obj.IN_VERSION+'_DL.zip','/data/mine/test/MT6572/jenkins/')

def wait_build():
    a=os.system('echo wait_build')
    del a
    os.chdir(os.path.join(pwd,CODE_DIR))
    if args_obj.WAIT_BUILD == 'true':
        while True:
            time.sleep(10)
            if os.path.isfile('startbuild'):
                break
            print 'we are waiting now!!!'


if __name__ == '__main__':
    args_parse()
    down_load_code(args_obj.CODE_URL,args_obj.CODE_BRANCH,args_obj.CODE_XML)
    wait_build()
    modified_hard_version()
    modified_auto_args()
    modified_release_path()
    quick_build_do_not_release()
    modified_quick_build_core()
    version_build()
    release_version()
    process_release_file()
    release_ota()
    do_snapshot()
