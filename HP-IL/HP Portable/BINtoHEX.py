#
# Convert binary code file to HEX DATA statements.
# The binary code blob must be created by assembler, linker, EXE2BIN.
#

fileName = 'HPIL.BIN'

import os   # for stat function

def OutputBASICLine(line,s):
	print('%04d %s' % (line,s))
	return line+10

# determine code size
statinfo = os.stat(fileName)

line = 1000
nBytes = statinfo.st_size-7 # actual code bytes, minus BLOAD header size
nWords = int((nBytes+1)/2)  # required 16-bit integers

line = OutputBASICLine(line,'REM ----- Martin Hepperle, 2026')
# line = OutputBASICLine(line,'DIM CODE%('+str(nWords-1)+') : REM 0..'+str(nWords-1)) # 0-based array indices
# line = OutputBASICLine(line,'REM Preallocate all simple variables to avoid array move')
# Portable Plus display: 480 x 200 pixels
# x=20..469 (449 wide) NX% samples
# y=10..189 (179 high) UX% Volts
# borders: left: 20, right, top, bottom: 10
line = OutputBASICLine(line,'NX%=100 : UX%=12 : REM max. samples, volts')
line = OutputBASICLine(line,'DIM VOLTS(NX%),TSECS(NX%)')
# HP 3468 sends exactly 13 characters incl. CR/LF
line = OutputBASICLine(line,'BUFFER$=SPACE$(13) : EC$=CHR$(27)')
#line = OutputBASICLine(line,'A%=0 : B%=0 : X%=0 : Y%=0 : U=0 : B$=""')
#line = OutputBASICLine(line,'RET%=0 : ADDR%=0 : TALK%=0 : LISTEN%=0 : SOT%=0')
#line = OutputBASICLine(line,'CONFIGURE%=0 : GETAID%=0 : ADDRESS%=0 : OUTPUT%=0')
#line = OutputBASICLine(line,'ENTERCNT%=0 : ENTERLF%=0 : SENDF%=0 : GETF%=0')
line = OutputBASICLine(line,'FX=(480-30)/NX% : FY=(200-20)/UX%')
line = OutputBASICLine(line,'DEF FNX%(X)=20+CINT(FX*X)')
line = OutputBASICLine(line,'DEF FNY%(Y)=10+CINT(FY*Y)')
#line = OutputBASICLine(line,'REM Do not allocate any new simple variables below!')
line = OutputBASICLine(line,'PRINT EC$+"H"+EC$+"J"; : REM home and clear alpha')
# either load from BIN (if exists)
line = OutputBASICLine(line,'DEF SEG : REM read DEFSEG from BASIC data segment')
line = OutputBASICLine(line,'BIN.SEG=PEEK(&H4D0)+256*PEEK(&H4D1)+&H1010 : REM above MBASIC 5.28')
line = OutputBASICLine(line,'DEF SEG=BIN.SEG')
line = OutputBASICLine(line,'ON ERROR GOTO '+str(line+30))
line = OutputBASICLine(line,'BLOAD "HPIL.BIN",0')
line = OutputBASICLine(line,'GOTO '+str(line+50))
# or read from DATA
line = OutputBASICLine(line,'A%=0')
line = OutputBASICLine(line,'READ B$ : IF B$="XX" THEN GOTO '+str(line+20))
line = OutputBASICLine(line,'POKE A%,VAL("&H"+B$) : A%=A%+1 : GOTO '+str(line-10))
# save to BIN for later speedy BLOADing
line = OutputBASICLine(line,'BSAVE "HPIL.BIN",0,'+str(nBytes))
#
line = OutputBASICLine(line,'CONFIGURE%=0 : GETAID%=3 : ADDRESS%=6')
line = OutputBASICLine(line,'OUTPUT%=9 : ENTERCNT%=12 : ENTERLF%=15')
line = OutputBASICLine(line,'SENDF%=18 : GETF%=21')
line = OutputBASICLine(line,'REM')
line = OutputBASICLine(line,'CALL CONFIGURE%(RET%)')
line = OutputBASICLine(line,'IF RET%=-1 THEN PRINT "ERROR: CONFIGURE" : STOP')
line = OutputBASICLine(line,'REM')
#   HP-IL addresses on the Portables:
#   0...7  = HP-IB devices via HL-IL/HP-IB I/F
#   8...30 = regular HP-IL devices
#   31     = Portable
line = OutputBASICLine(line,'ADDR%=8')
#line = OutputBASICLine(line,'CALL GETAID%(ADDR%,RET%)')
#line = OutputBASICLine(line,'PRINT "AID(";ADDR%;") -> ";RET%')
line = OutputBASICLine(line,'REM Talker: Portable, Listener: DVM')
line = OutputBASICLine(line,'TALK%=&H1F : LISTEN%=ADDR%')
line = OutputBASICLine(line,'CALL ADDRESS%(TALK%,LISTEN%,RET%)')
line = OutputBASICLine(line,'IF RET%=-1 THEN PRINT "ERROR: ADDRESS" : STOP')
line = OutputBASICLine(line,'REM send REN and wait')
line = OutputBASICLine(line,'A%=&H492 : B%=1')
line = OutputBASICLine(line,'CALL SENDF%(A%,B%,RET%)')
line = OutputBASICLine(line,'IF RET%=-1 THEN PRINT "ERROR: REN" : STOP')
line = OutputBASICLine(line,'REM DCV, 30V, NO Autozero, with END frame')
line = OutputBASICLine(line,'B$="F1R3Z0"+CHR$(13)+CHR$(10) : A%=1')
line = OutputBASICLine(line,'CALL OUTPUT%(B$,A%,RET%)')
line = OutputBASICLine(line,'IF RET%=-1 THEN PRINT "ERROR: OUTPUT" : STOP')
line = OutputBASICLine(line,'REM Talker: DVM, Listener: Portable')
line = OutputBASICLine(line,'TALK%=ADDR% : LISTEN%=&H1F')
line = OutputBASICLine(line,'CALL ADDRESS%(TALK%,LISTEN%,RET%)')
line = OutputBASICLine(line,'IF RET%=-1 THEN PRINT "ERROR: ADDRESS" : STOP')
#
line = OutputBASICLine(line,'REM plot axes and gridlines')
line = OutputBASICLine(line,'PRINT EC$+"*daC"; : REM clear GRAPHICS, GRAPHICS on')
line = OutputBASICLine(line,'PRINT EC$+"*pa20,189b20,10,469,10Z";')
line = OutputBASICLine(line,'FOR A%=0 TO NX% STEP 10')     # horizontal axis: 10 samples tick step
line = OutputBASICLine(line,' X%=FNX%(A%) : PRINT EC$+"*pa"+STR$(X%)+",8b"+STR$(X%)+",10Z";')
line = OutputBASICLine(line,'NEXT A%')
# STR$() inserts a leading space, so a comma separator can be omitted in front of STR$()
line = OutputBASICLine(line,'FOR A%=0 TO UX% STEP 1')     # vertical axis: 1 V tick step
line = OutputBASICLine(line,' Y%=FNY%(A%) : PRINT EC$+"*pa18"+STR$(Y%)+"b20"+STR$(Y%)+"Z";')
line = OutputBASICLine(line,'NEXT A%')
# grid
line = OutputBASICLine(line,'PRINT EC$+"*m7B";') # dotted line
line = OutputBASICLine(line,'FOR A%=0 TO NX% STEP 10')     # vertical grid lines
line = OutputBASICLine(line,' X%=FNX%(A%) : PRINT EC$+"*pa"+STR$(X%)+",10b"+STR$(X%)+",189Z";')
line = OutputBASICLine(line,'NEXT A%')
line = OutputBASICLine(line,'PRINT EC$+"*d18,0O0";')
line = OutputBASICLine(line,'PRINT EC$+"*d445,0O"+str$(NX%);')
line = OutputBASICLine(line,'FOR A%=0 TO UX% STEP 1')     # horizontal grid lines
line = OutputBASICLine(line,' Y%=FNY%(A%) : PRINT EC$+"*pa20"+STR$(Y%)+"b469"+STR$(Y%)+"Z";')
line = OutputBASICLine(line,' PRINT EC$+"*d0"+STR$(Y%-4)+"O"+RIGHT$(STR$(A%),2);')
line = OutputBASICLine(line,'NEXT A%')
line = OutputBASICLine(line,'PRINT EC$+"*m0B";') # solid line
#
line = OutputBASICLine(line,'REM plot measurements')
line = OutputBASICLine(line,'PRINT EC$+"*pa20,10Z"; : REM start with pen up') # lift graphics pen
line = OutputBASICLine(line,'SOT%=&H560 : REM SDA')
line = OutputBASICLine(line,'T0=TIME')
line = OutputBASICLine(line,'FOR A%=0 TO NX%')
line = OutputBASICLine(line,' CALL ENTERCNT%(BUFFER$,SOT%,RET%)')
line = OutputBASICLine(line,' IF RET%=-1 THEN PRINT "ERROR: ENTERCNT" : STOP')
line = OutputBASICLine(line,' U=VAL(LEFT$(BUFFER$,11))')  # usually 13 characters, trim off CR/LF
line = OutputBASICLine(line,' PRINT EC$+"*d382,177O"+"N ="+STR$(A%)')
line = OutputBASICLine(line,' PRINT USING "U =###.#### V";U') # always goes into bottom line?
line = OutputBASICLine(line,' PRINT EC$+"*p"+STR$(FNX%(A%))+","+STR$(FNY%(U))+"B";')
line = OutputBASICLine(line,' VOLTS(A%)=U')
line = OutputBASICLine(line,' TSECS(A%)=TIME-T0')
line = OutputBASICLine(line,'NEXT A%')
#
line = OutputBASICLine(line,'REM')
line = OutputBASICLine(line,'PRINT EC$+"*dE"; : REM ALPHA on')
line = OutputBASICLine(line,'TALK%=&H1F : LISTEN%=&H1F')
line = OutputBASICLine(line,'CALL ADDRESS%(TALK%,LISTEN%,RET%)')
line = OutputBASICLine(line,'IF RET%=-1 THEN PRINT "ERROR: UNT, UNL" : STOP')
line = OutputBASICLine(line,'REM')
line = OutputBASICLine(line,'DEF SEG')
line = OutputBASICLine(line,'FOR A%=0 TO NX%')
line = OutputBASICLine(line,' PRINT USING "####  ###.#### V";A%,VOLTS(A%)')
line = OutputBASICLine(line,'NEXT A%')
line = OutputBASICLine(line,'END')
line = OutputBASICLine(line,'REM -----')

# append DATA statements with binary code

f = open(fileName,'rb')
b=f.read(7)              # skip BLOAD header

i = 0
for n in range(0,10000):
	b = f.read(1)
	if len(b) == 0:
		# end of file reached
		if len(s) > 4:
			# more than "DATA"
			line = OutputBASICLine(line,s)
		break

	if i==0:
		s = ('DATA')
		line = line+10
		s = s + (' %02X' % (int.from_bytes(b,byteorder='little')))
	else:
		s = s + (',%02X' % (int.from_bytes(b,byteorder='little')))
	i = i+1
	if len(s) > 64:
		i = 0
		line = OutputBASICLine(line,s)
		s = ('DATA')

f.close()
line = OutputBASICLine(line,'DATA XX')

line = OutputBASICLine(line,'REM -----')
