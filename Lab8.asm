.model tiny                
.code  
.386                    
org 100h             
                           
start:                     
	jmp main               
 
buffer                db  128 dup(?)
sourcePath            db  128 dup(?)
hignPartPos           dw 0       
lowPartPos            dw 0   
hignPartPosLastSymbol          dw 0       
lowPartPosLastSymbol           dw 0 
flag                  db ?          
flag_                    db ?
error                 db "Open file error!$"    
file                  db 128 dup(?) 
sourceID              dw  0
intOldHandler         dd 0                    
                                      
handler PROC                        
	pushf  
	call    cs:intOldHandler                                                      
	push ds                           
    push es                           
	push ax                           
	push bx                          
    push cx                           
    push dx                           
	push di                           
                                      
	push cs                           
	pop ds                            
    
   ; mov ah,0h
   ; int 16h
    in  al, 60h         
    cmp al, 01h                     
    je escHandler
    cmp al, 48h
    je upHandler                            
    cmp al, 50h                        
    je downHandler
        
    pop     di                      
    pop     dx
    pop     cx
    pop     bx
    pop     ax
    pop     es
    pop     ds   
    
    jmp dword ptr cs:intOldHandler    
     
downHandler:   
 
    mov flag,0
    mov flag_,0      
    
    mov ah, 3Dh			        
	mov al, 0			     
	lea dx, sourcePath       
	mov cx, 0			        
	int 21h                        
	
	jc noFileEnd              
	                
	mov sourceId, ax
    
    mov al, 0                ; 
    mov bx, sourceId
	mov ah, 42h           
	mov cx, hignPartPosLastSymbol
	mov dx, lowPartPosLastSymbol		 
	int 21h                               
	
    mov ah, 3Fh                  
	mov bx, sourceID         
	mov cx, 1            
	lea dx, buffer                 
	int 21h  
	
	cmp ax,0
	je endRead 
	
	mov al, 0               
    mov bx, sourceId
	mov ah, 42h            
	mov cx, 0
	mov cx, hignPartPos
	mov dx, lowPartPos			 
	int 21h       
	
    mov ax, 0b800h
    mov es, ax
    mov di, 0 
    
    mov cx,80 
    imul cx,25 
    
loopClear_:
    mov al, ' ' 
    mov es:[di], al
    add di, 2
    loop loopClear_   
    xor di,di               

readAndOutputSymbol: 
                                
    mov ah, 3Fh                  
	mov bx, sourceID            
	mov cx, 1            
	lea dx, buffer                  
	int 21h   	  
	cmp ax,0  
    je endRead       
         
    cmp buffer[0],0Dh  
    jne notEndString   
        
addSpacesInEndString:       
 
    mov al,' '  
    mov es:[di],al
    inc di 
    inc di   
    mov bx,160
    mov ax,di  
    xor dx,dx
    div bx   
    
    cmp dx,0
    jne checkEnd 
    cmp flag,0
    jne checkEnd    
    
    mov al, 1                ; 
    mov bx, sourceId
	mov ah, 42h             
	mov cx, 0
	mov dx, 0		 
	int 21h    
	mov hignPartPos,dx
	mov lowPartPos,ax 
	mov flag,1      
	
checkEnd: 
    cmp di,4000    
    jge endRead 
    mov ax,di 
    xor dx,dx   
    mov bx,160
    div bx 
    cmp dx,0
    jne addSpacesInEndString
    jmp  readAndOutputSymbol    

notEndString:
   
    cmp buffer[0],0Ah
    jne print
    jmp readAndOutputSymbol 
print:
    call printInVideoMemory   
    
    mov bx,160
    mov ax,di  
    xor dx,dx
    div bx
    cmp dx,0  
    jne checkEnd_   
    cmp flag,0
    jne checkEnd_   
    
    mov flag,1 
    mov al, 1               
    mov bx, sourceId
    mov ah, 42h            
    mov cx, 0
    mov dx, 0		 
    int 21h    
    mov hignPartPos,dx
    mov lowPartPos,ax  
    
checkEnd_:
    cmp di,4000
    jge endRead 

jmp readAndOutputSymbol
 
endRead:    
    mov al, 1                
    mov bx, sourceId
	mov ah, 42h             
	mov cx, 0
	mov dx, 0		 
	int 21h    
	mov hignPartPosLastSymbol,dx
	mov lowPartPosLastSymbol,ax  

jmp endHandler
    
upHandler:      
    xor si,si
    add si,hignPartPosLastSymbol
    add si,lowPartPosLastSymbol    
    cmp si,0
    je endHandler   
     
    mov ah, 3Dh			      
	mov al, 0			 
	lea dx, sourcePath     
	mov cx, 0			        
	int 21h                       
	
	jc nofileEnd  
	            
	mov flag,0
	mov flag_,0                
	mov sourceId, ax 

    mov al, 0                 
    mov bx, sourceId
	mov ah, 42h             
	mov cx, hignPartPos
	mov dx, lowPartPos	 		 
	int 21h                                      
    
    mov cx,160    
    
moveBack:  
    push cx     

    mov al, 1                ; 
    mov bx, sourceId
	mov ah, 42h            
	mov cx, -1
	mov dx, -2		 
	int 21h   

    add ax,dx                        
	cmp ax,0 
	je popCx_
	jne readNext
 	
	mov al, 0                 
    mov bx, sourceId
	mov ah, 42h        
	mov cx, 0
	mov dx, 0		 
	int 21h       
	
	push cx
	jmp popCx_   
	
readNext:   
    mov ah, 3Fh                   
	mov bx, sourceID                 
	mov cx, 1         
	lea dx, buffer               
	int 21h        
	
	cmp buffer[0],0Ah
	jne popCx  	
	inc flag_
	cmp flag_,2
	je popCx_ 
	pop cx
	inc cx 
	loop moveBack     
	jmp pushCx            
	
	cmp buffer[0],0Dh
	jne popCx     
	pop cx
	inc cx
	loop moveBack 
	jmp pushCx   
	
popCx:
	pop cx
	loop moveBack
pushCx:   

	push cx
popCx_:  
    pop cx
loopCl:  

    mov ax, 0b800h
    mov es, ax    
    xor di,di 
    mov cx,80
    imul cx,25    
    
loopClear:
    mov al, ' ' 
    mov es:[di], al
    add di, 2
    loop loopClear  
    
    mov flag,0    
    mov di, 0  
    
readAndOutputSymbol_: 
                                
    mov ah, 3Fh                 
	mov bx, sourceID            
	mov cx, 1      
	lea dx, buffer            
	int 21h  
	  
	cmp ax,0  
    je endRead_                 
    cmp buffer[0],0Dh  
    jne notEndString_      

addSpacesInEndString_:       
 
    mov al,' '  
    dec cx
    mov es:[di],al
    inc di 
    inc di 
    mov bx,160
    mov ax,di  
    xor dx,dx
    div bx  
    
    cmp dx,0
    jne checkEnd_1 
    cmp flag,0
    jne checkEnd_1
     
    mov flag,1
    mov al, 1                 
    mov bx, sourceId
	mov ah, 42h            
	mov cx, 0
	mov dx, 0		 
	int 21h    
	mov hignPartPos,dx
	mov lowPartPos,ax 
	
checkEnd_1: 
    cmp di,4000
    jge endRead_  
    xor dx,dx
    mov ax,di    
    mov bx,160
    div bx  
    cmp dx,0
    jne addSpacesInEndString_ 

jmp  readAndOutputSymbol_    

notEndString_:
    
    cmp buffer[0],0Ah
    jne print_
    jmp  readAndOutputSymbol_ 
print_: 

    call printInVideoMemory 
      
    mov bx,160
    mov ax,di  
    xor dx,dx
    div bx     
    
    cmp dx,0 
    jne checkEnd_1_   
    cmp flag,0
    jne checkEnd_1_      
    
    mov flag,1 
    mov al, 1 
    mov bx, sourceId
    mov ah, 42h              
    mov cx, 0
    mov dx, 0		 
    int 21h    
    mov hignPartPos,dx
    mov lowPartPos,ax 
    
checkEnd_1_:
             
    cmp di,4000	  
    jge endRead_
    jmp readAndOutputSymbol_
endRead_:   
    mov al, 1                
    mov bx, sourceId
	mov ah, 42h             
	mov cx, 0
	mov dx, 0		 
	int 21h    
	mov hignPartPosLastSymbol,dx
	mov lowPartPosLastSymbol,ax  
endHandler:
    mov ah, 3Eh            
	mov bx, sourceID          
	int 21h  
	                       
nofileEnd:
                         
    mov al, 20h                       
    out 20h, al                        
    
	pop di                            
	pop dx                            
	pop cx                            
	pop bx                          
	pop ax                            
	pop es                            
	pop ds	                          
	jmp intEnd    
       
escHandler:    
                           
    mov al, 20h                       
    out 20h, al                        
    
	pop di                            
	pop dx                            
	pop cx                            
	pop bx                          
	pop ax                            
	pop es                            
	pop ds	                          
	
    mov ax,2509h
    mov dx,word ptr cs:[intOldHandler]
    mov ds,word ptr cs:[intOldHandler+2]
    int 21h 
    
    mov es,cs:2ch 
    mov ah,49h
    int 21h   
    
    push cs 
    pop es  
    mov ah,49h  
    int 21h ;                         
    
intEnd:     
	iret                              
ENDP                                  

printInVideoMemory proc
    push ax
    push cx
    push dx
    push si
    
    lea si, buffer
     
    mov cx,1

    mov al, [si] 
    mov es:[di], al
    inc si
    add di, 2

    pop si
    pop dx
    pop cx
    pop ax       
    ret
endp 
   
parseCMD PROC                             
	     
xor ch,ch      
	mov cl, es:[80h]     
	mov bl,cl  
	dec bl
	mov si, 82h 
	lea di,file 
	rep movsb      
	      
    mov si,0 
  
checkSpace1:    
    cmp file[si],0
    je errorCommandLine
    cmp file[si],' ' 
    jne readFile1
    inc si
    jmp checkSpace1
                     
readFile1:
         
    mov di,0        
     mov si,0    
     mov cl,bl
cycleReadNameFile1: 
         
    mov al,file[si]               
    mov sourcePath[di],al                   
    inc di
    inc si   
    
    cmp file[si],0
    je errorCommandLine          
    cmp file[si], '.'
    je readTxt
    cmp file[si], ' '
    loop cycleReadNameFile1	
	
setTXT: 

    mov sourcePath[di],'.'
    inc di 
    mov sourcePath[di],'t'
    inc di   
    mov sourcePath[di],'x'
    inc di
    mov sourcePath[di],'t'
    inc di    
   jmp endReadNameFile1
  
readTXT:     

   cmp file[si],'.'
   jne errorCommandLine 
   mov sourcePath[di],'.'
   inc di
   inc si    
   cmp file[si],'t'
   jne errorCommandLine 
      
   mov sourcePath[di],'t'
   inc di
   inc si  
   cmp file[si],'x'
   jne errorCommandLine 

   mov sourcePath[di],'x'
   inc di
   inc si 
   cmp file[si],'t'
   jne errorCommandLine 
   
   mov sourcePath[di],'t'
   inc di
   inc si   
 
endReadNameFile1: 
  
  checkEndCommandLine: 
  mov al,file[si]
  cmp file[si],0Dh
   je setASCIIZ
   cmp file[si],' '
   jne errorCommandLine
   inc si
   jmp   checkEndCommandLine
setASCIIZ:
   mov  byte ptr sourcePath[di],0 
      
    mov ah, 3Dh			      
	mov al, 0			 
	lea dx, sourcePath     
	mov cx, 0			        
	int 21h                       
	
	jc errorCommandLine  
	mov bx,ax
    mov ah, 3Eh                    
	int 21h 
 ret         ;  
endp
  
setHandler PROC                     
	push bx                           
	push dx                         
                                      
	cli                              
                                      
	mov ah, 35h                      
	mov al, 09h                   
	int 21h                            
                                                                                                                       
	                                  
	mov word ptr  intOldHandler, bx     
	mov word ptr  intOldHandler + 2, es
                                     
	push ds			                  
	pop es                           
                                      
	mov ah, 25h                      
	mov al, 09h                      
	mov dx, offset handler            
	int 21h                          
                                      
	sti                                                                   
                                      
	pop dx                          
	pop bx                            
	ret                               
ENDP                                  
                                                                      
main:
	call parseCMD                     
                                     
	call setHandler                			          
                                      
	mov ah, 31h                      
	mov al, 0                                                              
	mov dx, (main - start + 10Fh) / 16                                  
	int 21h  
	ret
	                       
    errorCommandLine:          
	lea dx,error
	mov ah,9
	int 21h     
	int 20h                                   
                             
end start                                       