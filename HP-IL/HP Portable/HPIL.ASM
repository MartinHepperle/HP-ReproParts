page 64,120
;
; Some HP-IL Functions for the Portable Plus and Microsoft BASIC.
;
; The BASIC ROM chip sold by HP contained a copy of MS-BASIC 5.28.
; This version relied on MS-DOS for system-related functions and did
; not have any specific functions for the HP system (no HP-IL, no
; Graphics). However, graphics output could be obtained by using the
; HP-specific escape sequences.
; Later, HP also offered a disk-based version of GWBASIC, which
; included graphics functions, but no HP-IL support.
;
; The routines presented below allow control of the HP-IL interface
; through a set of subroutines written in assembly-language.
; The resulting binary code block must be loaded into memory and
; BASIC must be be told where the routines are located.
; All routines assume a fixed number of parameters, which also MUST be
; of the correct type (use the type extension character '%' for integers
; or use a DEFINT statement to declare integer parameter variables).
; All parameters MUST be variables, no constants are allowed in the CALL
; statement.
;
; Note:
; Microsoft BASIC has one (well known and documented) "feature".
; User defined variables are stored in a fixed sequence in memory: 
; first "simple" variables (numeric and strings), followed by array 
; variables (numeric and strings) and finally by dynamically allocated 
; strings in the "string area".
;
; When a new simple variable (numeric or string) is "allocated",
; either by a DIM statement or simply by using a new variable name,
; all array variables are moved upwards in memory to create space for 
; the simple variable in the area alloted to simple variables.
; For pure BASIC programs this poses no problems.
; But in case of binary programs loaded into array variables and
; referred to by their address using the VARPTR function and the 
; CALL keyword this can lead to problems.
; These addresses become invalid whenever a new simple variable is
; defined and they must be redefined by a new call to VARPTR.
;
;
; There are several ways to overcome the problem of the moving arrays:
;
; A) Load the binary code INTO A BASIC ARRAY VARIABLE:
;  - Pre-allocate ALL simple variable before defining function pointers.
;  - Call VARPTR immediately before using the address in a CALL.
;  - Consumes variable space and reduces the amount of memory
;    available for BASIC program and variables.
;  - This approach is robust, but time consuming and requires very
;    careful coding in BASIC.
;    The example program in this source file uses this approach.
;
; B) Load the binary code INTO A REGION of the memory allocated by
;    BASIC:
;  - Use the /M option to shrink the memory used by BASIC, which is
;    robust, but needs careful calculation of the parameters for the
;    /M option.
;  - Reduces the amount of memory available for the BASIC program and
;    its variables.
;  - The load address of the code must be made known "somehow" to
;    the BASIC program, e.g. by writing the address into some unused 
;    interrupt vector and PEEKing these values from BASIC. 
;  - This is a litle bit on the ugly side, but used in some of the
;    early BASIC manuals.
;
; C) Install the binary ABOVE the memory used by BASIC by implementing
;    it as a TSR program:
;  - The load address of the code must be made known "somehow"
;    to the BASIC program, e.g. by writing the address into some unused 
;    interrupt vector.
;  - This method is used in some of the early BASIC manuals.
;  - The TSR occupies memory even when BASIC is not used and either an
;    unload routine or a reboot is required when the code shall be
;    replaced by a revised version
;
; D) Load the binary code ABOVE the memory used by BASIC:
;  - Define the load address by reading the internal variable DEFSEG
;    from the BASIC work area. The location of this variable depends
;    on the BASIC version. 
;  - Add at least &H1000 to this segment to select the next segment
;    above the memory used by BASIC. 
;  - Assume that there is at least 64 KB of unused memory above BASIC,
;    which is usually the case if the computer has more than 256 kB
;    of RAM.
;  - This is a quite robust and rather simple approach.
;    It does not reduce the memory available for BASIC programs and
;    variables.
;    The example program in HP110.BAS uses this approach.
;
;
; Building:
; ---------
; MASM HPIL;
; LINK HPIL;                 Neglect "no stack segment" warning
; EXE2BIN HPIL.EXE HPIL.BIN
; DEL HPIL.EXE
;
; or:
;
; TASM /L HPIL
; TLINK HPIL
; EXE2BIN HPIL.EXE HPIL.BIN
; DEL HPIL.EXE
;
; Martin Hepperle, 2026
;

; This module contains several subroutines, which are addressed by a
; jump table at the beginning of the code.
;
; Usage:
; ======
; ------------------------------------------------
; CALL CONFIGURE ( RET% )
; Configure the loop for new transfers by assigning addresses to all
; devices on the loop.
;
; Parameters:
; RET% = -1: failed
;
; ------------------------------------------------
; CALL GETAID ( DEVADR%, AID% )
; Return the Accessory ID of the device at address DEVADR%.
; Not all devices send an AID (e.g. the HP 3468 DVM).
;
; Parameters:
; DEVADR% = 0...7 HP-IB interface, 8..30 HP-IL devices
; AID%    = -1: failed
;
; ------------------------------------------------
; CALL ADDRESS_DEVICES(TALK%,LISTEN%,RET%)
; Address a pair of talker and listener devices.
;
; Parameters:
; TALK%   device to talk   (0...7 HP-IB interface, 8..30 HP-IL devices)
; LISTEN% device to listen (0...7 HP-IB interface, 8..30 HP-IL devices)
; Notes: address &H1F is the Portable Plus himself.
;        If both are set to &H1F: send UNTALK, UNLISTEN.
;        One of the two devices MUST be &H1F, no direct device-device
;        transfer supported.
; RET% = -1: failed
;
; ------------------------------------------------
; CALL OUTPUT(BUFFER$,END%,RET%)
; Send the bytes in BUFFER$ to the currently addressed listener device,
; optionally send the last byte as an END byte (if END%=1).
; Many instruments expect a trailing CR/LF pair and the END option set.
; It is usually necessary to send a REN frame before a listener accepts
; a command string (e.g. a DVM).
;
; Parameters:
; BUFFER$ contains the data to be sent, may end with CR/LF
; END% = 0: send last byte as a DAB frame
;        1: send last byte as an END frame
; RET% = -1: failed
;
; ------------------------------------------------
; CALL ENTERCNT(BUFFER$,SOT%,RET%)
; Receive bytes from the currently addressed talker device, 
; until the BUFFER$ is full (0..255 bytes),
; optionally send an initial SOT% frame.
;
; Parameters:
; BUFFER$ must be pre-allocated to the desired length. The length
;         defines how many bytes are read.
; SOT% = 0: send no initial Start Of Transmission frame, may be
;           continuation of a previous ENTER.
; Other possible values for SOT%:
;        SDA = 101 01100000 = 560h Send DAta
;        SST = 101 01100001 = 561h Send STatus
;        SDI = 101 01100010 = 562h Send Device Id
;        SAI = 101 01100011 = 563h Send Accessory ID
; RET% = -1: failed
;
; ------------------------------------------------
; CALL ENTERLF(BUFFER$,SOT%,RET%)
; Receive bytes from the currently addressed talker device until a
; LF character was received or the BUFFER$ is full (0..255 bytes),
; optionally send an initial SOT% frame.
;
; Parameters:
; BUFFER$ must be pre-allocated to the desired maximum length.
;         The length defines the maximum number of bytes to be read.
;         The result may be less bytes and the BUFFER$ will be
;         terminated by a LF character (usually a CR+LF pair).
; SOT% = 0: send no initial Start Of Transmission frame, may be
;           continuation of previous ENTER.
; Other possible values for SOT%:
;        SDA = 101 01100000 = 560h Send DAta
;        SST = 101 01100001 = 561h Send STatus
;        SDI = 101 01100010 = 562h Send Device Id
;        SAI = 101 01100011 = 563h Send Accessory ID
; RET% = -1: failed
;
; ------------------------------------------------
; CALL SEND_FRAME ( FRAME%, WAIT%, RET% )
; Send one HP-IL frame to the loop.
;
; Parameters:
; FRAME% the frame ID to send, e.g.;
; Some typical values for FRAME%:
;        SDC = 100 00000100 = 404h Send Device Clear
;        GET = 100 00001000 = 408h Group Execute Trigger
;        REN = 100 10100010 = 492h Remote ENable
;        NRE = 100 10010011 = 493h Not Remote Enable
;        RFC = 101 00000000 = 500h Ready For Command
;        SDA = 101 01100000 = 560h Send DAta
;        SST = 101 01100001 = 561h Send STatus
;        SDI = 101 01100010 = 562h Send Device Id
; WAIT% = 0: wait for loop ready before sending, 1: no wait
; RET%  = -1: failed
;
; ------------------------------------------------
; CALL GET_FRAME ( FRAME%, RET% )
; Receive one HP-IL frame from the the loop.
;
; Parameters:
; FRAME% will receive the frame ID or zero if none available.
; RET% = -1: failed
;
; ------------------------------------------------
;
; Example Program:
; ================
; DIM CODE%(144) : REM 0..144
; BLOAD "HPIL.BIN",VARPTR(CODE%(0)) : REM Alternative: POKE into CODE%.
; IF CODE%(0)=0 THEN STOP
; REM Preallocate all simple variables
; CONFIGURE%=0 : GETAID%=0 : ADDRESS%=0 : OUTPUT%=0
; ENTERCNT%=0 : ENTERLF%=0 : SENDF%=0 : GETF%=0
; ADR%=0 : RET%=0 : TALK%=0 : LISTEN%=0 : SOT%=0
; BUFFER$=SPACE$(13) : REM allocate 13 bytes in string space
; REM no NEW simple vaiables defined below
; CONFIGURE%=VARPTR(CODE%(0))
; GETAID%=CONFIGURE%+3
; ADDRESS%=CONFIGURE%+6
; OUTPUT%=CONFIGURE%+9
; ENTERCNT%=CONFIGURE%+12
; ENTERLF%=CONFIGURE%+15 
; SENDF%=CONFIGURE%+18
; GETF%=CONFIGURE%+21
;
; CALL CONFIGURE%(RET%)
; PRINT "CONFIGURING -> ";RET%
;
; ADR%=8  : REM first HP-IL device on Portable Plus loop
; CALL GETAID%(ADR%,RET%)
; PRINT "AID(";ADR%;") = ";RET%
;
; TALK%=ADR% : LISTEN%=&H1F 
; CALL ADDRESS%(TALK%,LISTEN%,RET%)
; PRINT "ADDRESS -> ";RET%
; 
; SOT%=&H560 : REM SDA
; CALL ENTERCNT(BUFFER$,SOT%,RET%)
; PRINT "ENTER -> ";RET%;BUFFER$
;
; TALK%=&H1F : LISTEN%=&H1F
; CALL ADDRESS%(TALK%,LISTEN%,RET%)
; PRINT "UNT, UNL -> ";RET%
;
; END
;
; Note:
;  The allocation of BUFFER$ should be performed by a string concatenation
;  or by using the SPACE$ function. 
;  Both methods avoids that BUFFER$ is allocated in the program text, but 
;  in string space instead.
;  Otherwise, any ENTER to BUFFER$ would modify the program text.

; ---------------------------------------------------
; Macro only for output of required dimensioning of the BASIC array
INTSIZE MACRO X
 %OUT REM required size:  DIM CODE%(X)
ENDM
IF2
 ; round up to size array of 16-bit integers
 INTSIZE %(END_OF_CODE-START_OF_CODE+1)/2-1
ENDIF
; ---------------------------------------------------

CODE SEGMENT

     ASSUME CS:CODE,DS:NOTHING,ES:NOTHING           ; DS, ES data in BASIC data segment
     ORG 0h

     ; BLOAD header, must appear first in CODE segment
     _MAGIC  DB 0FDh
     _SEG    DW ?                   ; not used
     _OFF    DW ?                   ; not used
     _LEN    DW END_OF_CODE-$       ; number of bytes

START_OF_CODE LABEL NEAR

; the following part of the code is BLOADed into memory.

; Jump table, each entry uses 3-bytes.
; The assembler optimizes these JMPs to a length of 2 or 3 bytes.
; For each 2-byte JMP (+/-127) it adds a NOP.
            JMP NEAR PTR CONFIG_LOOP
            JMP NEAR PTR GET_AID
            JMP NEAR PTR ADDRESS_DEVICES
            JMP NEAR PTR OUTPUT     ; send a string
            JMP NEAR PTR ENTERCNT   ; enter a string of length
            JMP NEAR PTR ENTERLF    ; enter a string to CR/LF
            JMP NEAR PTR SENDF      ; send one frame
            JMP NEAR PTR GETF       ; get one frame
; ---------------------------------------------------
; for addressing parameters on the stack
CONFIG_FRAME STRUC           ; offset
               DW ?         ;   0    saved BP
               DW 2 DUP(?)  ;   2    FAR return address, offset, segment
     C_RET%    DW ?         ;   6    1. parameter
CONFIG_FRAME ENDS

CONFIG_LOOP PROC FAR
            PUSH BP                 ; save register
            MOV  BP,SP              ; BP = SP

            MOV  AH,0               ; configure loop
            INT  54h
            TEST AL,7
            JNZ  ERROR1
            
            MOV  AH,16              ; set timeout
            MOV  BX,64              ; 64*(1/16) = 4 seconds
            INT  54h
            TEST AL,7
            JNZ  ERROR1

            XOR  AX,AX              ; return zero
            JMP DONE1
             
ERROR1 LABEL NEAR
            MOV AX,-1               ; ERROR
;------
DONE1  LABEL NEAR
            MOV  BX,[BP].C_RET%     ; BX = offset of RET%

RETF_1:                             ; common return for 1 parameter
            MOV  [BX],AX            ; [BX] = RET%
            MOV  SP, BP             ; restore SP
            POP  BP                 ; restore BP
            RET  1*2                ; clean up: one 16 bit address
CONFIG_LOOP ENDP

; ---------------------------------------------------
; for addressing parameters on the stack
GET_AID_FRAME STRUC           ; offset
               DW ?         ;   0    saved BP
               DW 2 DUP(?)  ;   2    FAR return address, offset, segment
     I_RET%    DW ?         ;   6    2. parameter, returns accessory id
     I_ADR%    DW ?         ;   8    1. parameter, device address
GET_AID_FRAME ENDS

GET_AID PROC FAR
            PUSH BP                 ; save register
            MOV  BP,SP              ; BP = SP
            
            MOV  BX,[BP].I_ADR%     ; BX = offset of ADR%
            MOV  BX,[BX]            ; BX = device address 0..

            MOV  AH,2               ; get accessory ID to BL
            INT  54h
            TEST AL,7
            JNZ  ERROR2
                        
            XOR  AH,AH              ; zero upper byte of ID
            MOV  AL,BL              ; save ID (0FEh = 254 = no device or no reply)
            JMP DONE2
             
ERROR2 LABEL NEAR
            MOV AX,-1               ; ERROR AID = -1
;------
DONE2 LABEL NEAR
            MOV  BX,[BP].I_RET%     ; BX = offset of RET%
            
RETF_2:                             ; common return for 2 parameters
            MOV  [BX],AX            ; [BX] = RET%
            MOV  SP, BP             ; restore SP
            POP  BP                 ; restore BP
            RET  2*2                ; clean up: two 16 bit addresses
GET_AID ENDP

; ---------------------------------------------------
; for addressing parameters on the stack
ADDRESS_FRAME STRUC           ; offset
               DW ?         ;   0    saved BP
               DW 2 DUP(?)  ;   2    FAR return address, offset, segment
     A_RET%    DW ?         ;   6    3. parameter
     A_LISTEN% DW ?         ;   8    2. parameter
     A_TALK%   DW ?         ;   A    1. parameter
ADDRESS_FRAME ENDS

ADDRESS_DEVICES PROC FAR
            PUSH BP                 ; save register
            MOV  BP,SP              ; BP = SP
            
            MOV  BX,[BP].A_TALK%    ; BX = offset of TALK%
            MOV  AX,[BX]            ; AL = TALK%
            MOV  BX,[BP].A_LISTEN%  ; BX = offset of LISTEN%
            MOV  BX,[BX]            ; BL = LISTEN%
            MOV  BH,AL              ; BX = TALK% | LISTEN%

            MOV  AH,3               ; Address Devices
            INT  54h
            TEST AL,7
            JNZ  ERROR3
                        
            XOR  AX,AX              ; success
            JMP DONE3
             
ERROR3 LABEL NEAR
            MOV AX,-1               ; Error: RET%= -1
;------
DONE3  LABEL NEAR
            MOV  BX,[BP].A_RET%     ; BX = offset of RET%

RETF_3:                             ; common return for 3 parameters
            MOV  [BX],AX            ; [BX] = RET%
            MOV  SP, BP             ; restore SP
            POP  BP                 ; restore BP
            RET  3*2                ; clean up: three 16 bit addresses
ADDRESS_DEVICES ENDP

; ---------------------------------------------------
; for addressing parameters on the stack
OUTPUT_FRAME STRUC           ; offset
               DW ?         ;   0    saved BP
               DW 2 DUP(?)  ;   2    FAR return address, offset, segment
     O_RET%    DW ?         ;   6    3. parameter
     O_END%    DW ?         ;   8    2. parameter, 1: last byte sent as an END frame
     O_BUFF$   DW ?         ;   A    1. parameter
OUTPUT_FRAME ENDS

OUTPUT PROC FAR
            PUSH BP                 ; save register
            MOV  BP,SP              ; BP = SP
          
            MOV  BX,[BP].O_END%     ; BX = offset of END%
            MOV  DX,[BX]            ; DX = END% option 0 or 1
            
            MOV  BX,[BP].O_BUFF$    ; BX = offset of string descriptor
            XOR  CH,CH
            MOV  CL,[BX]            ; CX = byte count
            MOV  DI,[BX+1]          ; DI = offset of first byte
            ; PUSH DS                 ; ES already contains BASIC data segment
            ; POP  ES                 ; ES:DI = source address

            MOV  AH,4               ; Output Data Block: CX bytes at ES:DI
            INT  54h                ; DX containe END byte option 0 or 1
            TEST AL,7
            JNZ  ERROR4
                        
            XOR  AX,AX              ; success
            JMP DONE4
             
ERROR4 LABEL NEAR
            MOV AX,-1               ; Error RET% = -1
;------
DONE4  LABEL NEAR
            MOV  BX,[BP].O_RET%     ; BX = offset of RET%

            JMP  RETF_3             ; MOV [BX],AX; restore BP, SP; RETF
OUTPUT ENDP
; ---------------------------------------------------
; for addressing parameters on the stack
ENTER_FRAME STRUC           ; offset
               DW ?         ;   0    saved BP
               DW 2 DUP(?)  ;   2    FAR return address, offset, segment
     E_RET%    DW ?         ;   6    3. parameter
     E_SOT%    DW ?         ;   8    2. parameter
     E_BUFF$   DW ?         ;   A    1. parameter
ENTER_FRAME ENDS

ENTER_SETUP PROC NEAR
            ; prepare stack
            ; load CX with max. count (length of BUFFER$)
            ; load DI with offset of BUFFER$
            ; load BX with SOT%
            PUSH BP                 ; save register
            MOV  BP,SP              ; BP = SP

            MOV  BX,[BP].E_BUFF$    ; BX = offset of string descriptor
            XOR  CH,CH
            MOV  CL,[BX]            ; CX = byte count 0..255
            MOV  DI,[BX+1]          ; DI = offset of first byte
            
            MOV  BX,[BP].E_SOT%     ; BX = offset of E_SOT%
            MOV  BX,[BX]            ; BX = E_SOT%, e.g. SDA=560h
            RET
ENTER_SETUP ENDP

ENTERCNT PROC FAR
            ; enter bytes until BUFFER$ has been filled
            CALL ENTER_SETUP        ; common parameter setup

            MOV  AH,5               ; Enter Data Block of CX bytes to ES:DI
            INT  54h                ; BX = SOT or zero
            TEST AL,7
            JNZ  ENTER_ERROR
                                    ; CX has count of bytes actually read
            
ENTER_EXIT LABEL NEAR               ; common return fro both ENTER functions
            XOR  AX,AX              ; success RET% = 0
            JMP DONE5
             
ENTER_ERROR LABEL NEAR
            MOV AX,-1               ; Error RET% = -1
;------
DONE5  LABEL NEAR
            MOV  BX,[BP].E_RET%     ; BX = offset of RET%

            JMP  RETF_3             ; MOV [BX],AX; restore BP, SP; RETF
ENTERCNT ENDP

; ---------------------------------------------------
ENTERLF PROC FAR
            ; like ENTERCNT, but stop at LF or when BUFFER$ has been filled
            CALL ENTER_SETUP        ; common parameter setup, BX, CX, ES:DI

NEXT LABEL NEAR
            MOV  DX,CX              ; save byte count
            MOV  CX,1               ; read a single byte
            MOV  AH,5               ; Enter Data Block of 1 byte to ES:DI
            INT  54h                ; BX = SOT or zero
            MOV  CX,DX              ; restore byte count

            TEST AL,7
            JNZ  ENTER_ERROR

            CMP  BYTE PTR ES:[DI],0Ah
            JZ   ENTER_EXIT         ; LF: leave loop and return
            
            INC  DI                 ; advance to next element
            XOR  BX,BX              ; no SOT of subsequent bytes
            LOOP NEXT               ; decrement CX and loop
            
            JMP  ENTER_EXIT         ; common return
ENTERLF ENDP

; ---------------------------------------------------
; for addressing parameters on the stack
SEND_FRAME STRUC           ; offset
               DW ?         ;   0    saved BP
               DW 2 DUP(?)  ;   2    FAR return address, offset, segment
     S_RET%    DW ?         ;   6    3. parameter
     S_WAIT%   DW ?         ;   8    2. parameter
     S_FRM%    DW ?         ;   A    1. parameter
SEND_FRAME ENDS

SENDF PROC FAR
            PUSH BP                 ; save register
            MOV  BP,SP              ; BP = SP

            MOV  BX,[BP].S_WAIT%    ; BX = offset WAIT%
            MOV  DX,[BX]            ; CX = wait option 0 or 1
            
            MOV  BX,[BP].S_FRM%     ; BX = offset of FRAME%
            MOV  BX,[BX]            ; BX = FRAME%

            MOV  AH,6               ; Send frame in BX, DX has wait option
            INT  54h                ; BX = SOT or zero
            TEST AL,7
            JNZ  ERROR6
                        
            XOR  AX,AX              ; success RET% = 0
            JMP DONE6
             
ERROR6 LABEL NEAR
            MOV AX,-1               ; Error RET% = -1
;------
DONE6  LABEL NEAR
            MOV  BX,[BP].S_RET%     ; BX = offset of RET%
            
            JMP  RETF_3             ; MOV [BX],AX; restore BP, SP; RETF

SENDF ENDP

; ---------------------------------------------------
; for addressing parameters on the stack
GET_FRAME STRUC           ; offset
               DW ?         ;   0    saved BP
               DW 2 DUP(?)  ;   2    FAR return address, offset, segment
     G_RET%    DW ?         ;   6    2. parameter
     G_FRM%    DW ?         ;   8    1. parameter
GET_FRAME ENDS

GETF PROC FAR
            PUSH BP                 ; save register
            MOV  BP,SP              ; BP = SP
            
            MOV  AH,7               ; read one frame to BX
            INT  54h                ; 
            TEST AL,7
            JNZ  ERROR7
                        
            XOR  AX,AX              ; success RET% = 0
            JMP DONE7
             
ERROR7 LABEL NEAR
            MOV AX,-1               ; Error RET% = -1
;------
DONE7  LABEL NEAR
            MOV  CX,BX              ; save received frame 
            
            MOV  BX,[BP].G_FRM%     ; BX = offset of FRAME%
            MOV  [BX],CX            ; FRAME% = CX
            
            MOV  BX,[BP].G_RET%     ; BX = offset of RET%

            JMP  RETF_2             ; MOV [BX],AX; restore BP, SP; RETF
GETF ENDP

END_OF_CODE   LABEL   NEAR

CODE ENDS
     
     END
