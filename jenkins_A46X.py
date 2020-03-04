#!/usr/bin/python
# -*- coding: utf-8 -*-

import fileinput
import getopt
import os
import random
import re
import shutil
import socket
import subprocess
import sys
import time
import traceback
import zipfile
from zipfile import ZipFile

'''
information:
PROJECT_INFO["code_url"]
PROJECT_INFO["code_branch"]
PROJECT_INFO["manifest"]
PROJECT_INFO["code_mirror"]
PROJECT_INFO["innerver"] = innerver
PROJECT_INFO["outver"] = outver

BUILD_INFO["project"]
BUILD_INFO["variant"]
python jenkins_A46X.py --build-variant "user"  --build-project "A460_Sprint" --save-type "dailybuild" --project-name "A460" 
--version "NUU_A460T_U000N_V1.4B05 A6LG-TM-05"  --code-url "ssh://git@10.0.30.251:22/MT6739_O_SW2/tools/manifests.git" --code-branch "A515_DEV_BRH_SW2" 
--code-xml "460_default.xml" --build-sign "ZZ" --branch "Stable_A460_DEV_BRH"
'''

TODAY = time.strftime("%Y%m%d")
CUSTOM_FILE = "wind/A460/master/device/mediateksample/A460"
CODE_DIR = "A460_code"
PWD = os.getcwd()
PROJECT_INFO = {}
BUILD_INFO = {}
HOSTNAME = socket.gethostname()
HOSTADDR = socket.gethostbyname(HOSTNAME)
RELEASE_DIR = "version_path"
OUTPUT_PATH = "/data/mine/test/MT6572/jenkins/"
MIRROR_PATH = {"SOFT35-11": '/home1/SW3/mirror', "SOFT35-12": '/home/jenkins/mirror', "SOFT35-15": '/home1/SW3/mirror',
               "SOFT35-16": '/home1/SW3/mirror', "SOFT35-17": '/home1/SW3/mirror',"SOFT30-58": '/home/qiancheng/mirror'}


def shell_command(cmd, env=None):
    if sys.platform.startswith('linux'):
        p = subprocess.Popen(['/bin/bash', '-c', cmd], env=env, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    else:
        p = subprocess.Popen(cmd, env=env, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    stdout, stderr = p.communicate()
    return p.returncode, stdout, stderr


def record_log(msg):
    os.chdir(PWD)
    filename = 'auto_build.log'
    if os.path.exists(filename):
        os.remove(filename)
    mtime = time.strftime('%Y--%m--%d--%H--%M')
    with open(filename, 'a+') as f:
        f.write(mtime + ":    " + msg + os.linesep)
    print(mtime + msg)


def check_space():
    if sys.platform.startswith('linux'):
        stat = os.statvfs('.')
        avail_g = stat.f_bavail * stat.f_bsize / 1024 / 1024 / 1024
        print(avail_g)
        if avail_g < 30:
            record_log('no space! please check you workspace,exit ....')
            sys.exit(1)


def check_info(dictobj):
    project_list = ["A460_TMO", "A460_Sprint"]
    build_variant = ["user", "eng", "debug", "userroot"]
    #build_command = ["new", "remake", "n", "r", ""]
    save_type = ["preofficial", "temp", "factory", "dailybuild"]
    for key in dictobj:
        if key == "variant" and BUILD_INFO["variant"] not in build_variant:
            record_log("build-variant error")
            sys.exit(1)
        elif key == "project" and BUILD_INFO["project"] not in project_list:
            record_log("build-command error")
            sys.exit(1)
        # elif key == "variant" and BUILD_INFO["variant"] not in build_command:
        #     record_log("build-command error")
        #     sys.exit(1)
        elif key == "innerver" and PROJECT_INFO["innerver"] is None:
            record_log("build-version error")
            sys.exit(1)
        elif key == "outver" and PROJECT_INFO["outver"] is None:
            record_log("build-version error")
            sys.exit(1)
        elif key == "save_type" and PROJECT_INFO["save_type"] not in save_type:
            record_log("save-type error")
            sys.exit(1)


def parse_args():
    global PROJECT_INFO
    global BUILD_INFO
    opt, args = getopt.getopt(sys.argv[1:], 'h',
                              ['save-type=', 'project-name=', 'code-url=', 'code-branch=', 'code-xml=',
                               'branch=', 'version=',
                               'build-project=', 'build-variant=', 'build-sign='])
    for k, v in opt:
        if k in ("-h", "--help"):
            print("use ur talent to guess")
        elif k == "--save-type":
            PROJECT_INFO["save_type"] = v
        elif k == "--project-name":
            PROJECT_INFO["project_name"] = v
        elif k == "--code-url":
            PROJECT_INFO["code_url"] = v
        elif k == "--code-branch":
            PROJECT_INFO["code_branch"] = v
        elif k == "--code-xml":
            PROJECT_INFO["manifest"] = v
        elif k == "--branch":
            PROJECT_INFO["branch"] = v
        elif k == "--version":
            if v:
                innerver = v.split()[0]
                outver = v.split()[1]
                PROJECT_INFO["innerver"] = innerver
                PROJECT_INFO["outver"] = outver
            else:
                PROJECT_INFO["innerver"] = ""
                PROJECT_INFO["outver"] = ""
        elif k == "--build-project":
            BUILD_INFO["project"] = v
        elif k == "--build-variant":
            BUILD_INFO["variant"] = v
        elif k == "--build-sign":
            BUILD_INFO["sign"] = v
    print(PROJECT_INFO)
    print(BUILD_INFO)
    record_log(str(PROJECT_INFO))
    record_log(str(BUILD_INFO))
    check_info(PROJECT_INFO)
    check_info(BUILD_INFO)


def custom_modify():
    os.chdir(os.path.join(PWD,CODE_DIR))
    cur_dir=os.path.abspath(os.getcwd())
    if BUILD_INFO["sign"] != "efuse":
        os.chdir(os.path.join(cur_dir,"wind/A460/{0}/device/mediateksample/A460/".format(BUILD_INFO["project"].split("_")[1])))
        if os.path.exists("ProjectConfig.mk"):
            for ih in fileinput.input("ProjectConfig.mk",inplace=True):
                if re.findall("MTK_EFUSE_WRITER_SUPPORT\s?=.*",ih):
                    data = re.sub("MTK_EFUSE_WRITER_SUPPORT\s?=.*","MTK_EFUSE_WRITER_SUPPORT = no",ih)
                    sys.stdout.write(data)
                else:
                    sys.stdout.write(ih)
        os.chdir(os.path.join(PWD, CODE_DIR))
        os.chdir(os.path.join(cur_dir,"wind/A460/{0}/vendor/mediatek/proprietary/bootable/bootloader/lk/project".format(BUILD_INFO["project"].split("_")[1])))
        if os.path.exists("A460.mk"):
            for tx in fileinput.input("A460.mk",inplace=True):
                if re.findall("MTK_EFUSE_WRITER_SUPPORT\s?=.*",tx):
                    data = re.sub("MTK_EFUSE_WRITER_SUPPORT\s?=.*","MTK_EFUSE_WRITER_SUPPORT = no",tx)
                    sys.stdout.write(data)
                else:
                    sys.stdout.write(tx)
    os.chdir(os.path.join(PWD, CODE_DIR))
    os.chdir(os.path.join(cur_dir,CUSTOM_FILE))
    if os.path.isfile("version"):
        #之前没有指定inplace=True,导致无法替换
        for ver in fileinput.input("version",inplace=True):
            if re.findall("INVER",ver):
                data = re.sub("INVER=.*", "INVER={0}".format(PROJECT_INFO["innerver"]), ver)
                sys.stdout.write(data)
            elif re.findall("OUTVER",ver):
                data = re.sub("OUTVER=.*", "OUTVER={0}".format(PROJECT_INFO["outver"]), ver)
                sys.stdout.write(data)
            else:
                sys.stdout.write(ver)

def build_version_without_release():
    '''
    # modify build version info and compile cpu core
    # compile format like : ./quick_build.sh A460_TMO user new
    # BTW, we could not let quick script to invoke release_version to avoid mass up jenkins release directory
    :return: None
    '''
    record_log("start to modify version")
    os.chdir(os.path.join(PWD, CODE_DIR))
    if os.path.exists("quick_build.sh"):
        for qf in fileinput.input("quick_build.sh",inplace=True):
            if re.search(r"release_version.sh",qf):
                data = re.sub(r"\s*./release_version.sh",r"#./release_version.sh",qf)
                sys.stdout.write(data)
            else:
                sys.stdout.write(qf)
    sp = subprocess.Popen("./quick_build.sh {0} {1} {2}".format(BUILD_INFO["project"], "new", BUILD_INFO["variant"]), shell=True)
    sp.wait()
    log_name = "build.log"
    os.chdir("build-log")
    if os.path.exists(log_name):
        build_flag = check_compile_status(log_name)
        if build_flag:
            record_log("build successful !")
        else:
            record_log("build error")
            sys.exit(1)

def check_compile_status(filename):
    os.chdir(os.path.join(PWD, CODE_DIR))
    old_path = os.getcwd()
    compile_flag = False
    if os.path.exists(filename):
        sp = subprocess.call("tail -n 100 {0} > result.log".format(filename),shell=True)
        with open("result.log", "r") as f:
            for line in f:
                if re.findall(r"Successfully", line, re.I):
                    print("build version successed!")
                    compile_flag = True
                    break
                else:
                    print("build version failed!")
                    compile_flag = False
    os.chdir(old_path)
    return compile_flag


def new_project_info():
    os.chdir("/home/jenkins")

    with open("project.info", "w") as f:
        f.write("type={0}".format(PROJECT_INFO["save_type"]) + os.linesep)
        f.write("project={0}".format(BUILD_INFO["project"]) + os.linesep)
        #f.write("custom=TMO" + os.linesep)  # we could not distinct TMO or Sprint at now
        if PROJECT_INFO["save_type"] in ['preofficial','factory','temp']:
            if os.path.exists('/jenkins/{0}_version/{1}/{2}'.format(PROJECT_INFO["save_type"], BUILD_INFO["project"],
                                                                        PROJECT_INFO["innerver"])):
                f.write("version={0}_{1}".format(PROJECT_INFO["innerver"], random.randint(10) + os.linesep))
            else:
                f.write("version={0}".format(PROJECT_INFO["innerver"] + os.linesep))
        elif PROJECT_INFO["save_type"] == "dailybuild":
            if os.path.exists('/jenkins/{0}_version/{1}/{2}_dailybuild/'.format(PROJECT_INFO["save_type"],BUILD_INFO["project"],TODAY)):
                f.write("version={0}_{1}".format(TODAY,random.randint(10) + os.linesep))
            else:
                f.write("version={0}".format(TODAY + os.linesep))
        f.flush()


def modified_release_path():
    '''
    modify release path, not release at once
    :return: None
    '''
    os.chdir(os.path.join(PWD,CODE_DIR))
    abs_release_dir = os.path.join(os.path.join(PWD, CODE_DIR), RELEASE_DIR)
    for ih in fileinput.input('release_version.sh', inplace=True):
        if re.findall(r"/data/mine/test/MT6572/\$MY_NAME", ih):
            newline = re.sub(r"/data/mine/test/MT6572/\$MY_NAME", abs_release_dir, ih)
            sys.stdout.write(newline)
        else:
            sys.stdout.write(ih)


def release_version():
    '''
    we must relase version to a specific file,not into sw_exchange as usual
    so create a new_project_info funciton to handle release route issue
    :return: None
    '''

    modified_release_path()
    new_project_info()
    os.chdir(os.path.join(PWD, CODE_DIR))
    try:
        if os.path.exists(RELEASE_DIR):
            shutil.rmtree(RELEASE_DIR)
        os.mkdir(RELEASE_DIR)
    except OSError as e:
        print(traceback.format_exc())

    sp = subprocess.Popen("./release_version.sh {0}".format(PROJECT_INFO["project_name"]), shell=True)
    sp.wait()
    time.sleep(5)


def zip_file(source, target):
    #os.chdir(os.path.join(PWD,CODE_DIR))
    #cur_dir = os.getcwd()
    #os.chdir(os.path.join(cur_dir,RELEASE_DIR))
    zipf = ZipFile(target, "w", allowZip64=True,compression=zipfile.ZIP_DEFLATED)
    #for paths, filenames in os.walk(source):
    for img in os.listdir(source):
        zipf.write(source + os.path.sep + img)
        #if filenames:
            #for filename in filenames:
                #zipf.write(paths + os.path.sep + filename)
    zipf.close()


def process_release_file():
    os.chdir(os.path.join(PWD, CODE_DIR))
    os.chdir(RELEASE_DIR)
    curdir = os.path.abspath(os.getcwd())
    dl_name = PROJECT_INFO["innerver"] + "_DL"

    os.mkdir(dl_name)
    for file in os.listdir(curdir):
        if file != dl_name and file != "vmlinux.zip":  # both string, move all img into dl_name except it self
            shutil.move(file, dl_name)
    zip_file(dl_name, dl_name + ".zip")

    shutil.copy(dl_name + ".zip", OUTPUT_PATH)
    shutil.copy("vmlinux.zip",OUTPUT_PATH)


def do_snapshot():
    '''
    # format: manifest-ASUS_X00PD_WW_ENG_V1.0B58_20180615.xml
    # repo manifest -ro $format
    :return:None
    '''
    os.chdir(os.path.join(PWD, CODE_DIR))
    sp = subprocess.Popen('repoc manifest -ro manifest-{0}_{1}.xml'.format(PROJECT_INFO["innerver"], TODAY), shell=True)
    sp.wait()
    shutil.copy("manifest-{0}_{1}.xml".format(PROJECT_INFO["innerver"], TODAY), RELEASE_DIR)
    shutil.copy("manifest-{0}_{1}.xml".format(PROJECT_INFO["innerver"], TODAY), OUTPUT_PATH)


def download_code():
    '''
    format:
    repoc init -u ssh://git@10.0.30.251:22/MT6739_O_SW2/tools/manifests.git -b A515_DEV_BRH_SW2 -m 460_default.xml --no-repo-verify
    repoc sync -j8
    repo start Stable_A460_DEV_BRH --all
    :return:
    '''
    print("start to download code")
    # mirror info
    os.chdir(PWD)
    if os.path.exists(CODE_DIR):
        shutil.rmtree(CODE_DIR)
    os.mkdir(CODE_DIR)
    os.chdir(CODE_DIR)
    starttime = time.time()
        
    if HOSTNAME in MIRROR_PATH:
        #mirror_path = os.path.join(MIRROR_PATH[HOSTNAME], "A46X_mirror_repo")
        mirror_path = os.path.join(MIRROR_PATH[HOSTNAME], "46X_mirror_8.0")
        if os.path.exists(mirror_path):
            mirror_flag = True
        else:
            mirror_flag = False
        if mirror_flag:
            os.chdir(mirror_path)
            result = subprocess.Popen('repoc sync -cj3', shell=True)
            result.wait()
            time.sleep(5)
            os.chdir(os.path.join(PWD, CODE_DIR))
            subprocess.Popen(
                "repoc init -u {0} -b {1} -m {2} --reference={3} --no-repo-verify".format(PROJECT_INFO["code_url"],
                                                                                          PROJECT_INFO["code_branch"],
                                                                                          PROJECT_INFO["manifest"],
                                                                                          mirror_path), shell=True)
        else:
            result = subprocess.Popen(
                "repoc init -u {0} -b {1} -m {2} --no-repo-verify".format(PROJECT_INFO["code_url"],
                                                                          PROJECT_INFO["code_branch"],
                                                                          PROJECT_INFO["manifest"]), shell=True)
            result.wait()
    else:
        result = subprocess.Popen(
            "repoc init -u {0} -b {1} -m {2} --no-repo-verify".format(PROJECT_INFO["code_url"],
                                                                      PROJECT_INFO["code_branch"],
                                                                      PROJECT_INFO["manifest"]), shell=True)
        result.wait()
    time.sleep(5)
    result = subprocess.Popen("repoc sync -cj8 && repoc start {0} --all".format(PROJECT_INFO["branch"]), shell=True)
    result.wait()
    if os.path.isfile("release_version.sh"):
        record_log("download code done!")
    else:
        record_log("download code failed")
        sys.exit(1)
    endtime = time.time()
    record_log("download end,total time is %s" % (endtime - starttime))


def new_project_info():
    os.chdir(PWD)
    with open("project.info", "w") as pf:
        pf.write("type={0}".format(PROJECT_INFO["save_type"]) + os.linesep)
        pf.write("project={0}".format(PROJECT_INFO["project_name"]) + os.linesep)
        pf.write("custom={0}".format(BUILD_INFO["project"].split("_")[1]) + os.linesep)

        if PROJECT_INFO["save_type"] in ['preofficial', 'factory', 'temp']:
            if os.path.exists(
                    '/jenkins/{0}_version/{1}/{3}'.format(PROJECT_INFO["save_type"], PROJECT_INFO["project_name"],
                                                          PROJECT_INFO["innerver"])):
                pf.write("version={0}_{1}".format(PROJECT_INFO["innerver"], random.randint(1000) + os.linesep))
            else:
                pf.write("version={0}".format(PROJECT_INFO["innerver"] + os.linesep))
        elif PROJECT_INFO["save_type"] == "dailybuild":
            if os.path.exists("/jenkins/{0}_version/{1}/{2}".format(PROJECT_INFO["project_name"],
                                                                    PROJECT_INFO["project_name"], TODAY)):
                pf.write("version={0}_{1}".format(TODAY, random.randint(1000) + os.linesep))
            else:
                pf.write("version={0}".format(TODAY + os.linesep))
            pf.write('option=custom:{0}_dailybuild'.format(BUILD_INFO["project"]) + os.linesep)
        pf.flush()

if __name__ == '__main__':
    check_space()
    parse_args()
    download_code()
    custom_modify()
    build_version_without_release()
    release_version()
    process_release_file()
    do_snapshot()
