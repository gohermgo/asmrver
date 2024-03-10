format ELF64
public _start

STDERR        =  2

SYS_read      =  0
SYS_write     =  1
SYS_close     =  3
SYS_open      =  2
SYS_socket    = 41
SYS_accept    = 43
SYS_bind      = 49
SYS_listen    = 50
SYS_setsockopt= 54
SYS_exit      = 60

SO_REUSEADDR  =  2
SOL_SOCKET    =  1
AF_INET       =  2
SOCK_STREAM   =  1
PROTOCOL      =  0
;bind_length   = 16
listen_length =0x0A

O_RDONLY      =  0x00

section '.text' executable
_start:
        push  rbp
        mov   rbp,rsp
        mov word[socket],0
        mov word[client],0
        xor   rax,rax
        xor   rbx,rbx
        xor   rcx,rcx
        xor   rdx,rdx
        xor   r15,r15

        mov    rdi,AF_INET  
        mov    rsi,SOCK_STREAM
        mov    rdx,PROTOCOL  
        call _socket ;; We make the socket

        call _bind ;; We bind the socket
        mov    esi,listen_length
        mov    eax,SYS_listen
        call _listen
        .mainloop: ;; We enter the main loop
                call _accept
        .read_request:
                mov di,[client]
                mov rsi,client.addr       
                mov edx,[client.len]      
                call _read
                mov [request.len], eax
        .prepare_response:
                mov edi,response.path
                mov esi,O_RDONLY
                call _open
                mov [responsefd],eax
        .read_response:
                mov edi,[responsefd]
                mov rsi,response
                mov edx,[response.maxlen]
                call _read
                cmp eax,0x0
                je .cleanup
                mov [response.len], eax
        .write_response:
                mov edi,[client]
                mov rsi,response
                mov edx,[response.len]
                call _write
        .close_response:
                mov edi,[responsefd]
                call _close
                mov [responsefd],0
        .drop_client:
                mov di,[client]
                cmp edi,0x0
                je .cleanup
                call _close
                mov word[client],0
                jmp .mainloop
.cleanup: 
        mov di,[socket]
        cmp edi,0x0
        je .client_clean
        call _close
.client_clean:
        mov di,[client]
        cmp edi,0x0
        je _exit
        call _close
        mov rbx, 0
        jmp _exit
.error: mov rbx, rax
        jmp _exit


;; Function defs
_read:  ; Reads DI, into buffer SI (EDX bytes)
        push rbp
        mov rbp,rsp
        mov eax,SYS_read
        syscall
        cmp eax, 0x0
        jl .fail
        mov rsp,rbp
        pop rbp
        ret
.fail:  mov  rsi,.message
        mov  rdx,.length
        jmp _fail
        .message: db 'Read failed',0
        .length : dd $-.message
_write: ; Writes to DI, from buffer SI
        push rbp
        mov rbp,rsp
        mov eax,SYS_write
        syscall
        cmp eax, 0x0
        jl .fail
        mov rsp,rbp
        pop rbp
        ret
.fail:  mov rsi,.message
        mov rdx,.length
        jmp _fail
        .message: db 'Write failed',0
        .length : dd $-.message
_open:  ; Opens DI, with flags in SI
        push rbp
        mov rbp,rsp
        mov eax,SYS_open
        syscall
        cmp eax, 0x0
        jl .fail
        mov rsp,rbp
        pop rbp
        ret
.fail:  mov rsi,.message
        mov rdx,.length
        jmp _fail
        .message: db 'Open failed',0
        .length : dd $-.message
_close: ; Closes the FD in DI
        push rbp
        mov rbp,rsp
        mov eax,SYS_close
        syscall
        cmp eax, 0x0
        jl .fail
        mov rsp,rbp
        pop rbp
        ret
.fail:  mov rsi,.message
        mov rdx,.length
        jmp _fail
        .message: db 'Close failed',0
        .length : dd $-.message
_socket: ; Makes socket, DI : Type, SI : Sockettype, DX : protocol -> AX : fd
        push rbp
        mov rbp,rsp
        mov eax,SYS_socket       
        syscall              
        cmp eax, 0x0
        jl .fail
        mov [socket],ax
        mov di, [socket]
        mov esi,SOL_SOCKET
        mov edx,SO_REUSEADDR
        mov r8d,4
        mov r10d,socket.opts
        mov eax,SYS_setsockopt
        syscall
        cmp eax,0x0
        jl .fail
        mov rsp,rbp
        pop rbp
        ret
.fail:  mov rsi,.message
        mov rdx,.length
        jmp _fail
        .message: db 'Socket failed',0
        .length:  dd $-.message
_bind:
        push rbp
        mov rbp,rsp
        mov di,[socket]
        mov esi,socket.addr  
        mov edx,[socket.len]
        mov eax,SYS_bind
        syscall
        cmp eax, 0x0
        jl .fail
        mov [client],di
        mov rsp,rbp
        pop rbp
        ret
.fail:  mov rsi,.message
        mov rdx,.length
        jmp _fail
        .message: db 'Bind failed',0
        .length:  dd $-.message
_accept: ; DI : fd, SI : Address-write-buffer, DX : buffer-length
        push rbp
        mov rbp,rsp
        mov di,[socket]
        mov rsi,client.addr
        mov rdx,client.len
        mov eax,SYS_accept
        syscall
        cmp eax, 0x0
        jl .fail
        mov [client],ax
        mov rsp,rbp
        pop rbp
        ret
.fail:  mov  rsi,.message
        mov  rdx,.length
        jmp  _fail
        .message: db 'Accept failed',0
        .length:  dd $-.message
_listen:
        push rbp
        mov rbp,rsp
        mov di,[socket]
        mov eax,SYS_listen
        syscall
        cmp rax,                  0x0
        jl .fail
        mov rsp,rbp
        pop rbp
        ret
.fail:  mov rsi,.message
        mov rdx,.length
        jmp _fail
        .message: db 'Listen failed',0
        .length:  dd $-.message
;; Error handling section
_fail:
        mov rdi, STDERR
        mov rax, SYS_write
        mov r12, rbx
        syscall
        mov rdi, 1
        jmp _exit
;; Main exit point        
_exit:
        mov rsp,rbp
        pop rbp
        mov rax, 0x60
        int 0x80
section '.data' writeable
;; Socket
socket:
        rw 2
        .len dd 16
        .addr:
                dw AF_INET
                dw 0x901f
                dd 0
                dq 0
        .opts:
                dw 0
                db 0
                db 1
;; Client
client:
        rw 2
        .len dd 14
        .addr:
                rw 1
                rw 1
                rd 1
                rq 1
;; Request
request:
        rd 1024
        .maxlen dd 1024
        .len dd 2
;; Response
responsefd rd 2
response:
        rd 1024
        .maxlen dd 1024
        .len rd 2
        .path db 'index.html',0
