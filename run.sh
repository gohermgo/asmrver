fasm src/server.asm && mv src/server.o build/
ld build/server.o -o server && strace -i  -n ./server
