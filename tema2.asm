
extern puts
extern printf
extern strlen

%define BAD_ARG_EXIT_CODE -1

section .data
filename: db "./input0.dat", 0
inputlen: dd 2263

fmtstr:            db "Key: %d",0xa, 0
usage:             db "Usage: %s <task-no> (task-no can be 1,2,3,4,5,6)", 10, 0
error_no_file:     db "Error: No input file %s", 10, 0
error_cannot_read: db "Error: Cannot read input file %s", 10, 0

section .text
global main


;=========TODO TASK 1===========
;functie pentru calcularea inceputului cheii 
get_key:                   
    push ebp
    mov ebp, esp
    xor edx, edx
    mov ebx, dword [ebp+8]   ;in ebx am incheputul stringului
rep_get_key:
    mov dl, byte[ebx]        ;iau un byte din string
    inc ebx                  ;daca am 0, trec la inceputul cheii
    cmp dl, 0                ;verific daca am ajung la separatorul dintre string si cheie
    jne rep_get_key
    leave
    ret
    
xor_strings:
    push ebp
    mov ebp, esp
    mov ebx, dword [ebp+12] ;in ebx am cheia
    mov ecx, dword [ebp+8]  ;stringul ce trebuie decriptat
    xor edx, edx            ;counter
xor_strings_rep: 
    mov al, byte[ebx]       ;byte din cheie
    mov ah, byte[ecx +edx]  ;byte din string
    cmp al, 0x00            ;verific daca am ajuns la final
    je xor_end              ;ma opresc daca am ajuns la final
    xor al, ah              ;decodare caracter
    mov byte[ecx + edx], al
    inc edx
    inc ebx
    jmp xor_strings_rep
xor_end:
    leave
    ret
	
;=========TODO TASK 2===========
rolling_xor:
    push ebp
    mov ebp, esp
    mov ecx, dword [ebp + 8]    ;stringul ce trebuie decriptat
    xor edx, edx
    mov ah, byte[ecx + edx]     ;aici am primul carater din string, deja decodat
    inc edx                     ;edx = 1
rolling_xor_rep:
    mov al, ah                  ;byte-ul anterior inainte de decriptare
    mov ah, byte[ecx + edx]     ;byte-ul ce trebuie decriptat
    cmp ah, 0                   ;verific daca am ajusn la final
    je rolling_end
    xor al, ah                  ;decriptare byte curent
    mov byte[ecx + edx ], al
    inc edx
    jmp rolling_xor_rep
rolling_end:
    leave
    ret

;=========TODO TASK 3===========
xor_hex_strings: 
    push ebp
    mov ebp, esp
    mov edi, dword[ebp + 8]
    xor eax,eax             ;in al si ah pun caracterele din string
    xor ebx, ebx                
    xor edx, edx            ;parcurg string-ul cu ajutorul lui edx
    xor ecx, ecx            ;counter folosit pentru a lua doi octeti
rep_hex_to_bin:
    mov al, byte[edi + edx ]
    cmp al, 0
    je end_hex_to_bin
    cmp al, '9'             ;veridic daca am cifra
    jle cifra
    cmp al, 'f'             ;verific daca am un caracter de la 'a' la 'f'
    jle litera
cifra:
    sub al,'0'              ;transform in binar   
    add ah, al              
    cmp ecx, 1              ;verific cati octeti am luat inainte sa introduc la loc in string
    je add_to_string
    shl ah, 4               ;tranformarea transforma doi octeti intr-un singur octet
    inc ecx                 ;pentru a lua al doilea octet
    inc edx                 ;trec la urmatorul caracter
    jmp rep_hex_to_bin
litera:                 ;difera doar procedeul de transformare in binar
    sub al, 'a' 
    add al, 10
    add ah, al
    cmp ecx, 1
    je add_to_string
    shl ah, 4
    inc ecx
    inc edx
    jmp rep_hex_to_bin
add_to_string:
    mov byte[edi + ebx],ah  ;introduc ce am transformat in binar
    xor ah, ah
    xor ecx, ecx            ;resetez counter-ul
    inc edx
    inc ebx
    jmp rep_hex_to_bin
end_hex_to_bin:
    mov byte[edi + ebx + 1], 0
    mov eax, dword[ebp + 8]
    mov edx, dword[ebp + 12]
    leave
    ret

;=========TODO TASK 4===========
base32decode:
    push ebp
    mov ebp, esp
    mov edi, dword[ebp + 8] ;stringul ce trebuie decodat
    xor eax, eax            ;citesc cu al caracterele din edi
    xor ebx, ebx            ;stochez ce am decriptat
    xor ecx, ecx            ;inaintez in edi
    xor edx, edx            ;verific 
rep_base32:   
    mov al, byte[edi + ecx]
    cmp al, 0               ;verific daca am ajuns la finalul stringului
    je end_base32
    cmp al, '='             ;verific daca trebuie sa fac padding
    je base32_padding
for_last_byte:
    cmp al, 'A'             ;verific daca am citit o cifra
    jl two_seven
A_Z:
    sub al, 'A'             ;acum mai am in al doar 5 biti 
    jmp comun_code
two_seven:
    sub al, 24              ;cei mai semnificativi 3 biti nu ma mai intereseaza 
comun_code:
    cmp edx, 5              ;mai jos fac verificari ca sa stiu cate grupuri
    je add_notshl           ;de 5 biti am bagat in ebx si ah
    cmp edx, 6
    je first_3
    cmp edx, 7              ;ebx a fost bagat si mai ramane doar ah
    je last_byte_32
    add ebx, eax
    shl ebx, 5              ;fac loc pentru urmatorii 5 biti
    inc edx
    inc ecx
    jmp rep_base32
add_notshl:                 ;am 30 de biti bagati in ebx
    add ebx, eax
    shl ebx, 2              ;mai am nevoie de doar 2 biti
    inc edx
    inc ecx
    jmp rep_base32
first_3:
    mov ah, al  
    shr al, 3 
    add bl, al
    ror bx, 8               ;bag caracterele decriptate in ordine inversa
    ror ebx, 16             ;si trebuie sa le inversez ordinea
    ror bx, 8
    mov al, bh  
    mov dword[edi], ebx
    inc ecx
    xor ebx, ebx            ;golesc ebx
    inc edx
    jmp rep_base32
last_byte_32:               ;ultimii 8 biti
    mov bl, ah              ;am pastrat ultimii 5 biti in al
    shl bl, 5               ;am nevoie doar de cei mai nesimnificativi 3 biti
    add bl, al
    add edi, 4
    sub ecx, 4
    mov byte[edi], bl
    add edi, 1
    xor edx, edx            ;resetez edx pentru urmatoarele 5 caractere
    xor ebx, ebx
    xor eax, eax
    jmp rep_base32
base32_padding:             ;similar cu introducerea caracterelor
    sub al, '='             ;doar ca introduc doar zerouri in continuarea
    cmp edx, 5              ;caracterelor cititte pana la '='
    je add_notshl2
    cmp edx, 6
    je  shl_ebx_3
    cmp edx, 7
    je add_ah_base32        ;cazul cand doar ultimul caracter din stringul initial e '='
    add bl, al
    shl ebx, 5
    inc ecx
    inc edx
    jmp rep_base32
add_notshl2:
    add bl, al
    inc ecx
    inc edx
    jmp rep_base32
shl_ebx_3:
    shl ebx, 2
    ror bx, 8               ;schimb ordinea caracterelor
    ror ebx, 16             ;dupa caracterele valide o sa am 0 si stringul se termina
    ror bx, 8
    mov dword[edi], ebx
    jmp end_base32
add_ah_base32:
    shl ah, 5
    mov byte[edi], ah        
end_base32:
    mov ecx, dword[ebp + 8]
    leave
    ret

;=========TODO TASK 5===========

;Functia pe care am folosit-o pentru a obtine cheia
;fara sa stiu ca am cuvantul "force".
;Prima daa am incercat sa decodez fara hint
get_key_one:
    push ebp
    mov ebp, esp
    mov edx, dword[ebp + 8]
    xor eax, eax
find_end:
    mov al, byte[edx + 1]
    cmp al, 0
    je end_find_end
    inc edx
    jmp find_end
end_find_end:
    mov al, byte[edx]
    mov ah, 63         ;am verificat si pentru '.' si '!', dar nu a mers
    xor al, ah
    xor ebx,ebx
    mov bl, al
    leave
    ret
;Functia folosita pentru aflarea cheii
get_key_bruteforce:
    push ebp
    mov ebp, esp
    mov edi, dword[ebp + 8] ;stringul ce trebuie decodat
rep_get_key_bruteforce:   
    mov al, byte[edi]       ;iau fiecare element din string
    cmp al, 0
    je end_get_key_bruteforce
    xor edx, edx
    xor al,'f'              ;calculez cheia presupunand ca in al am 'f'
    inc edx
o:                          ;am pus o,r,c si e sa urmaresc mai usor codul
    mov ah, byte[edi + edx] ;iau urmatorul caracter ce trebuie verificat
    xor ah, al
    cmp ah, 'o'             ;verific daca urmeaza 'o' dupa litera 'f'
    jne prepare_rep         ;reiau cautarile daca nu am gasit 'o'
    inc edx
r:
    mov ah, byte[edi + edx]
    xor ah, al
    cmp ah, 'r'             ;verific daca urmeaza 'r' dupa litera 'o'
    jne prepare_rep         ;reiau cautarile daca nu am gasit 'r'
    inc edx
c:
    mov ah, byte[edi + edx]
    xor ah, al
    cmp ah, 'c'             ;verific daca urmeaza 'c' dupa litera 'r'
    jne prepare_rep         ;reiau cautarile daca nu am gasit 'c'
    inc edx
e:
    mov ah, byte[edi + edx]
    xor ah, al
    cmp ah, 'e'             ;verific daca urmeaza 'e' dupa litera 'c'
    jne prepare_rep         ;reiau cautarile daca nu am gasit 'e'
    jmp end_get_key_bruteforce ;daca am ajuns aici, am gasit cheia corecta
prepare_rep:
    xor edx, edx            ;resetez counterul
    inc edi                 ;trec la urmatorul caracter din string
    jmp rep_get_key_bruteforce
end_get_key_bruteforce:
    xor ebx, ebx
    mov bl, al              ;mut cheia in ebx
    leave
    ret
    
bruteforce_singlebyte_xor:
    push ebp
    mov ebp, esp
    mov ecx, dword[ebp + 8] ;iau stringul ce trebuie decodat
    xor edx, edx
rep_bruteforce_xor:
    mov al, byte[ecx + edx]
    cmp al, 0
    je end_bruteforce_xor
    xor al, bl              ;in ebx am cheia
    mov byte[ecx + edx], al ;pun byte-ul decodat in string
    inc edx
    jmp rep_bruteforce_xor
end_bruteforce_xor:
    leave
    ret

;=========TODO TASK 6===========

;M-am folosit de informatia de pe forum: putem considera ca avem
;doar minuscule in string
decode_vigenere:
    push ebp
    mov ebp, esp
    mov ecx, dword[ebp + 8]         ;stringul de decriptat
    mov ebx, dword[ebp + 12]        ;cheia
    xor edx, edx
rep_decode_vigenere:
    mov al, byte[ecx]               ;parcurg stringul
    mov dl, byte[ebx]               ;iau cheia corespunzatoare fiecarui caracter
    cmp al, 0                       ;verific daca am ajuns la final
    je end_decode_vigenere
    cmp dl, 0                       ;verific daca trebuie resetata cheia
    je new_key_vigenere    
    sub dl, 'a'                     ;calculez nuamrul de shiftari
    cmp al, 'a'                     ;verific daca caracterul curent trebuie decriptat
    jl new_byte_vigenere
    cmp al, 'z'                     ;execut shiftarea caracterului pentru decriptare
    jle shift_a
    jmp new_iteration_vigenere
new_key_vigenere:
    mov ebx, dword[ebp + 12]        ;resetez cheia daca este cazul
    jmp rep_decode_vigenere
shift_a:
    sub al, dl
    cmp al, 'a'
    jl sub_vigenere_26              ;alfabetul este 'periodic' si verific daca trebuie sa apun perioada
    cmp al, 'z'
    jle new_iteration_vigenere
sub_vigenere_26:
    add al, 26                      ;readuc caracterul curent in intervalul [a;z]
new_iteration_vigenere:
    mov byte[ecx], al               ;introduc caracterul decriptat
    inc ecx
    inc ebx                         
    jmp rep_decode_vigenere
new_byte_vigenere:              
    mov byte[ecx], al               ;introduc caracterul ce nu a avut nevoie de decriptare
    inc ecx
    jmp rep_decode_vigenere
end_decode_vigenere:
    mov ecx, dword[ebp + 8]
    leave	
    ret
;===============================

main:
	push ebp
	mov ebp, esp
	sub esp, 2300

	; test argc
	mov eax, [ebp + 8]
	cmp eax, 2
	jne exit_bad_arg

	; get task no
	mov ebx, [ebp + 12]
	mov eax, [ebx + 4]
	xor ebx, ebx
	mov bl, [eax]
	sub ebx, '0'
	push ebx

	; verify if task no is in range
	cmp ebx, 1
	jb exit_bad_arg
	cmp ebx, 6
	ja exit_bad_arg

	; create the filename
	lea ecx, [filename + 7]
	add bl, '0'
	mov byte [ecx], bl

	; fd = open("./input{i}.dat", O_RDONLY):
	mov eax, 5
	mov ebx, filename
	xor ecx, ecx
	xor edx, edx
	int 0x80
	cmp eax, 0
	jl exit_no_input

	; read(fd, ebp - 2300, inputlen):
	mov ebx, eax
	mov eax, 3
	lea ecx, [ebp-2300]
	mov edx, [inputlen]
	int 0x80
	cmp eax, 0
	jl exit_cannot_read
        
	; close(fd):
	mov eax, 6
	int 0x80

	; all input{i}.dat contents are now in ecx (address on stack)
	pop eax
	cmp eax, 1
	je task1
	cmp eax, 2
	je task2
	cmp eax, 3
	je task3
	cmp eax, 4
	je task4
	cmp eax, 5
	je task5
	cmp eax, 6
	je task6
	jmp task_done

task1:
	; TASK 1: Simple XOR between two byte streams

        push ecx
        call get_key        ;obtinerea cheii pentru decodare(in ebx)
        add esp,4

        push ebx
        push ecx
        call xor_strings    ;apelul functiei de decodare
        add esp,8

               
	push ecx
	call puts                   ;print resulting string
	add esp, 4
	jmp task_done

task2:
	; TASK 2: Rolling XOR

        push ecx
        call rolling_xor    ;apelul functiei de decodare
        add esp, 4

	push ecx
	call puts
	add esp, 4

	jmp task_done

task3:
	; TASK 3: XORing strings represented as hex strings
        push ecx
        call get_key        ;obtinerea cheii in registrul ebx
        add esp,4
 
        push ebx
        push ecx
        call xor_hex_strings;functie de conversie din hexadecimal in binar
        add esp,8
        mov ecx, eax        ;sirul de decodat in format binar
        mov ebx, edx        ;cheia in hexadecimal

        push ecx
        push ebx
        call xor_hex_strings;functie de conversie din hexadecimal in binar
        add esp, 8 
        mov ebx, eax        ;cheia in format binar
        mov ecx, edx        ;sigur de decodat in format binar

        push ebx
        push ecx
        call xor_strings    ;apelul functiei folosite la taskul 1
        add esp,8
        
	push ecx                     ;print resulting string
        call puts
	add esp, 4

	jmp task_done

task4:
	; TASK 4: decoding a base32-encoded string
        push ecx
        call base32decode
        add esp, 4
	
	push ecx
	call puts                    ;print resulting string
	pop ecx
	
	jmp task_done

task5:
	; TASK 5: Find the single-byte key used in a XOR encoding
        push ecx
        call get_key_bruteforce         ;obtinere cheie pentru task5
        add esp, 4
        
        push ecx
        call bruteforce_singlebyte_xor;apelul functie de decodare
        add esp, 4
  
	push ecx                       ;print resulting string
	call puts
	pop ecx

	push ebx                       ;ebx = key value
	push fmtstr
	call printf                 ;print key value
	add esp, 8

	jmp task_done

task6:
	; TASK 6: decode Vignere cipher
        push ecx
        call get_key
        add esp,4

	push ebx
	push ecx                   ;ecx = address of input string 
	call decode_vigenere       ;aplelul functie de decodare
	pop ecx
	add esp, 4

	push ecx
	call puts
	add esp, 4

task_done:
	xor eax, eax
	jmp exit

exit_bad_arg:
	mov ebx, [ebp + 12]
	mov ecx , [ebx]
	push ecx
	push usage
	call printf
	add esp, 8
	jmp exit

exit_no_input:
	push filename
	push error_no_file
	call printf
	add esp, 8
	jmp exit

exit_cannot_read:
	push filename
	push error_cannot_read
	call printf
	add esp, 8
	jmp exit

exit:
	mov esp, ebp
	pop ebp
	ret
