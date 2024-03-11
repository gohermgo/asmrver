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

        mov    rsi,SOCK_STREAM
        mov    rdx,PROTOCOL  
        push .bind
        jmp _socket
        ;call _socket ;; We make the socket
.bind:  push .listen
        jmp _bind ;; We bind the socket
.listen:mov    esi,listen_length
        mov    eax,SYS_listen
        push .mainloop
        jmp _listen
.mainloop: ;; We enter the main loop
        push .read_request
        jmp _accept
        .read_request:
                mov di,[client]
                mov rsi,client.addr       
                mov edx,[client.len]      
                push .prepare_response
                jmp _read
        .prepare_response:
                mov [request.len], eax
                mov edi,response.path
                mov esi,O_RDONLY
                push .read_response
                jmp _open
        .read_response:
                mov [response.fd],eax
                mov edi,[response.fd]
                mov rsi,response
                mov edx,[response.maxlen]
                push .write_response
                jmp _read
        .write_response:
                cmp eax,0x0
                je .cleanup
                mov [response.len], eax
                mov edi,[client]
                mov rsi,response
                mov edx,[response.len]
                push .close_response
                jmp _write
        .close_response:
                mov edi,[response.fd]
                push .drop_client
                jmp _close
        .drop_client:
                mov [response.fd],0
                mov di,[client]
                cmp edi,0x0
                je .cleanup
                push .clear_client
                jmp _close
        .clear_client:
                mov word[client],0
                jmp .mainloop
.cleanup: 
        mov di,[socket]
        cmp edi,0x0
        je .client_clean
        push .client_clean
        jmp _close
.client_clean:
        mov di,[client]
        cmp edi,0x0
        je _exit
        push .clear_exit_code
        jmp _close
.clear_exit_code:
        mov rbx, 0
        jmp _exit
.error: mov rbx, rax
        jmp _exit


;; Function defs
_read:  mov eax,SYS_read
        syscall
        cmp eax, 0x0
        jl .fail
        pop rbx
        jmp rbx
.fail:  mov  rsi,.message
        mov  rdx,.length
        jmp _fail
        .message: db 'Read failed',0
        .length : dd $-.message
fn_read:  ; Reads DI, into buffer SI (EDX bytes)
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
_write: ; Push the returnaddress
        mov eax,SYS_write
        syscall
        cmp eax, 0x0
        jl .fail
        pop rbx
        jmp rbx
.fail:  mov rsi,.message
        mov rdx,.length
        jmp _fail
        .message: db 'Write failed',0
        .length : dd $-.message
        
fn_write: ; Writes to DI, from buffer SI
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
        mov eax,SYS_open
        syscall
        cmp eax, 0x0
        jl .fail
        pop rbx
        jmp rbx
.fail:  mov rsi,.message
        mov rdx,.length
        jmp _fail
        .message: db 'Open failed',0
        .length : dd $-.message
fn_open:  ; Opens DI, with flags in SI
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
        mov eax,SYS_close
        syscall
        cmp eax, 0x0
        jl .fail
        pop rbx
        jmp rbx
.fail:  mov rsi,.message
        mov rdx,.length
        jmp _fail
        .message: db 'Close failed',0
        .length : dd $-.message
fn_close: ; Closes the FD in DI
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
_socket: ; Makes socket, DI : family, SI : Sockettype, DX : protocol -> AX : fd
        mov di,[socket.addr] ; The sa_family_t of the socket
        mov eax,SYS_socket       
        syscall              
        cmp eax, 0x0
        jl .fail
        mov [socket],ax
        mov di,[socket]
        mov esi,SOL_SOCKET
        mov edx,SO_REUSEADDR
        mov r8d,4
        mov r10d,socket.opts
        mov eax,SYS_setsockopt
        syscall
        cmp eax,0x0
        jl .fail
        pop rbx
        jmp rbx
.fail:  mov rsi,.message
        mov rdx,.length
        jmp _fail
        .message: db 'Socket failed',0
        .length:  dd $-.message
fn_socket: ; Makes socket, DI : family, SI : Sockettype, DX : protocol -> AX : fd
        push rbp
        mov rbp,rsp
        mov di,[socket.addr] ; The sa_family_t of the socket
        mov eax,SYS_socket       
        syscall              
        cmp eax, 0x0
        jl .fail
        mov [socket],ax
        mov di,[socket]
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
        mov di,[socket]
        mov esi,socket.addr  
        mov edx,[socket.len]
        mov eax,SYS_bind
        syscall
        cmp eax, 0x0
        jl .fail
        mov [client],di
        pop rbx
        jmp rbx
.fail:  mov rsi,.message
        mov rdx,.length
        jmp _fail
        .message: db 'Bind failed',0
        .length:  dd $-.message
fn_bind:
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
        mov di,[socket]
        mov rsi,client.addr
        mov rdx,client.len
        mov eax,SYS_accept
        syscall
        cmp eax, 0x0
        jl .fail
        mov [client],ax
        pop rbx
        jmp rbx
.fail:  mov  rsi,.message
        mov  rdx,.length
        jmp  _fail
        .message: db 'Accept failed',0
        .length:  dd $-.message
fn_accept: ; DI : fd, SI : Address-write-buffer, DX : buffer-length
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
        mov di,[socket]
        mov eax,SYS_listen
        syscall
        cmp rax,                  0x0
        jl .fail
        pop rbx
        jmp rbx
.fail:  mov rsi,.message
        mov rdx,.length
        jmp _fail
        .message: db 'Listen failed',0
        .length:  dd $-.message
fn_listen:
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
        .opts   dd 1
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
        .fd rd 2
        .handle:
                push rbp
                mov rbp,rsp
                ;;Open
                mov edi,response.path
                mov esi,O_RDONLY
                call _open
                mov [responsefd],eax
                ;; Read
                mov edi,[response.fd]
                mov rsi,response
                mov edx,[response.maxlen]
                call _read
                mov [response.len], eax
                ;; Write
                mov edi,[client]
                mov rsi,response
                mov edx,[response.len]
                call _write
                mov rsp,rbp
                pop rbp
                ret

