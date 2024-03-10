#include <asm-generic/socket.h>
#include <sys/syscall.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <fcntl.h>
// SOCKET constants
_sock_cll = SYS_socket;  // System-call value
_sock_dmn = AF_INET;     // Socket-domain (int) -> edi (AF_INET for IPv4)
_sock_typ = SOCK_STREAM; // Socket-type (int) -> esi
_sock_prt = 0;           // Socket-protocol (int) -> edx
// BIND constants
_bind_cll = SYS_bind;    // System-call value
_bind_len = 16;          // Socket-address length (int32) -> edx
// LISTEN constants
_list_cll = SYS_listen;  // System-call value
_list_lln = 10;          // Backlog length
// ACCEPT constants
_acpt_cll = SYS_accept; 
// READ constants
_read_cll = SYS_read;
// OPEN constants
_open_cll = SYS_open;
_open_flg = O_RDONLY;
// WRITE constants
_writ_cll = SYS_write;
_close_cll = SYS_close;
x = SOL_SOCKET;
