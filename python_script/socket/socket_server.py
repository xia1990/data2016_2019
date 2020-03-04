import socket
import select

def boardcast_message(socket_c,message):
    for socket_l in SOCKET_LIST:
        if socket_l != server_socket and socket_l != socket_c:
            try:
                socket_l.sendall(message)
            except socket.error,msg:
                socket_l.close()
                SOCKET_LIST.remove(socket_l)

if __name__ == "__main__":
    SOCKET_LIST=[]
    BUFF=1024
    server_socket=socket.socket(socket.AF_INET,socket.SOCK_STREAM)
    server_socket.setsockopt(socket.SOL_SOCKET,socket.SO_REUSEADDR,1)
    server_socket.bind(("0.0.0.0",12345))
    server_socket.listen(10)
    print "server start to listen tcp port: ",12345
    SOCKET_LIST.append(server_socket)

    while True:
        read_list,write_lit,error_list = select.select(SOCKET_LIST,[],[])
        for sockets in read_list:
            if sockets == server_socket:
                socket_l,addr = server_socket.accept()
                SOCKET_LIST.append(socket_l)
                print "client connect"
                boardcast_message(socket_l,str(addr)+"add to this chat room")
            else:
                try:
                    data = sockets.recv(1024)
                    if data:
                        boardcast_message(sockets,data)
                except socket.error,msg:
                    message="client %s %s" % (sockets,sockets.getpeername())
                    boardcast_message(sockets,"client")
                    sockets.close()
                    SOCKET_LIST.remove(sockets)
                    continue
    server_socket.close()
