import socket,sys,select
if len(sys.argv)<3:
    print "Useage: sys.argv[0] args1 args2 args3"
    sys.exit()

def promot():
    sys.stdout.write("<YOU> ")
    sys.stdout.flush()

if __name__ == "__main__":
    host = sys.argv[1]
    port = sys.argv[2]
    print host,port
    s=socket.socket(socket.AF_INET,socket.SOCK_STREAM)
    s.settimeout(3)

    s.connect((str(host),int(port)))
    rlist=[sys.stdin,s]

    while True:
        read_list,write_list,error_list = select.select(rlist,[],[])
        for sock in read_list:
            if sock == s:
                data = s.recv(1024)
                if not data:
                    print "disconnect form server"
                    sys.exit()
                else:
                    sys.stdout.write(data)
                    promot()
            else:
                message = sys.stdin.readline()
                s.sendall(message)
                promot()
