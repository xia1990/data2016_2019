import os
import sys
import time
if len(sys.argv) != 2:
    print "Useage:",sys.argv[0],"1"
    sys.exit(1)
times=int(sys.argv[1])
if not isinstance(times,int):
    print "wrong args type,need int"
    sys.exit(1)
try:
    for i in range(0,3600):
	os.system('clear')
        os.system('ssh -p 29418 10.0.30.9 gerrit show-connections')
        os.system('ssh -p 29418 10.0.30.9 gerrit show-queue -w')
        time.sleep(times)
except KeyboardInterrupt,e:
    print e
finally:
    print "close check server"
