'
'Welcome to SimplePropellerAssemblyDebugger (SPAD).  SPAD was developed as a tool for the
'beginner to provide immediate feedback to check the operability of propeller assembly
'language code.  Experienced programmers may find that SPAD is possibly awkward to use and
'the "Header" wastes too much memory. Fortunately, there exists other diagnostic software
'which is better suited for the proficient assembly language programmer.  With that said, I
'now can turn my attention to the beginner who wants to write a few lines of code and make
'something happen. For you, SPAD was made to order. 
'
'SPAD instructions are derived from the beloved Basic Stamp code and they will be easily
'recognized.  But first it is necessary to set the table with five SPAD Block's 1, 2, 3, 4,
'and 5 which must be included in the program.  Special attention must be given to SPAD
'BLOCK 4, because the code is actually part of the assembly language program being created
'and it's code is position sensitive, so nothing must change in SPAD BLOCK 4.  The
'assembly language program being created should start at the position indicated in SPAD
'BLOCK 5.  There are no restrictions on the assembly language program being created.
'
'The BASIC Stamp Editor/Development System Version: 2.2.6 operating at 9600 baud was
'used as the output terminal and input keyboard.  The Propeller Demo board, 5 MHz
'system, was used as the output device.  SPAD utilizes the FullDuplexSerialPlus (FDSP)
'for RS232 communication.  It was necessary to slightly modify FDSP and it was renamed
'FullDuplexSerialPlus_Plus (FDSPP).  Make sure that FDSPP is used and FDSP is not used.  
'
'SPAD functions include the following: debugChar, debugDelay, debugStr, debugDec, debugBin,
'debugWatchDog,  debugInChar, debugInDec, multiply and divide.  Now I ask you Stamp
'enthusiasts, are these instructions sweet or not.  The beauty of SPAD is that simple fully
'functional self contained assembly language programs can be written.  Remember, when running
'the demo programs, if a keyboard entry is requested, then do it and see what happens.
'Also, I suggest that you make erroneous keyboard entry's to test the software.  There are
'six and eight second delays in the demo programs, so be patient.  
' 
'This ReadMeDemo is a tutorial program which is fully operational describes the functions in
'detail.  It has always been my goal to make all my programs, with keyboard entry,
'continuously operational.  This means that after a specified delay, the program will supply
'its own keyboard entry and proceed to the next instruction.  This means that when the "F11"
'transfer is made from the Propeller Tool to the Basic Stamp Editor, the assembly language
'program will hit the ground running and no reset is required to start the program.
'So remember, when starting these demo programs, just wait a few seconds and all should
'be well.  A final note on the MainDemo regarding the led exercise.  It is interesting to
'watch the Stamp Debug window with one eye and pin16/pin17 led's with the other and note
'the led blink frequency, horizontal character rate and blink count for each different blink
'frequency.  See if you can correlate these visual dynamics with the software.
'
'A demo program called SimplePropellerAssemblyDebugger_YourDemo is provided for the beginner
'to get started, so just add a few lines of code and let her rip .......  And finally a last
'word from me if things don't go just right: Remember I am only human and an old one at that.  
'
CON '################################## SPAD BLOCK 1 ########################################
                                                                                          '##
  _clkmode        = xtal1 + pll16x                 '5 MHz system  (Demo Board)            '##
  _xinfreq        = 5_000_000                      '5 MHz system                          '##
'  _clkmode        = xtal1 + pll8x                 '10 MHz system (Spin Stamp)            '##
'  _xinfreq        = 10_000_000                    '10 MHz system                         '##
                                                                                          '##
  CR = 13                                                                                 '##
  CLS = 0                                                                                 '##
  BELL = 7                                                                                '##
  SPACE = 32                                                                              '##
  BKSP = 8                                                                                '##
                                                                                          '##
'############################################################################################
OBJ '################################## SPAD BLOCK 2 ########################################
                                                                                          '##
  SPAD : "SimplePropellerAssemblyDebugger"                                                '##
                                                                                          '##
'############################################################################################                                                                                          
PUB SimplePropAsmDebug_ReadMeDemo '#### SPAD BLOCK 3 ########################################
                                                                                          '##
  SPAD.DebugPropASM                                                                       '##
                                                                                          '##
  cognew(@Entry,0)                                                                        '##
                                                                                          '##
'############################################################################################
DAT '################################## SPAD BLOCK 4 ########################################
                                                                                          '##
                  ORG     0                                                               '##
Entry             jmp     #Code                                                           '##
                                                                                          '##
multiP            long    0                                                               '##
multiC            long    0                                                               '##
product           long    0                                                               '##
dividend          long    0                                                               '##
divisor           long    0                                                               '##
quotient          long    0                                                               '##
remainder         long    0                                                               '##
debugVar          long    0                                                               '##
debug_Var         long    0                                                               '##
debugInVar        long    0                                                               '##
debugDelay        byte    $F1,$B7,$BC,$A0,$61,$B6,$BC,$80,$00,$B6,$BC,$F8,$0B,$10,$FC,$E4 '##
debugDelay_ret    ret                                                                     '##
debugWatchDog     byte    $56,$BA,$BC,$08,$57,$10,$3C,$08,$58,$12,$3C,$08,$02,$BA,$7C,$0C '##
                  byte    $F1,$B7,$BC,$A0,$60,$B6,$BC,$80,$00,$B6,$BC,$F8                 '##
debugWatchDog_ret ret                                                                     '##
debugDec          byte    $4E,$BA,$BC,$08,$47,$9A,$FC,$5C                                 '##
debugDec_ret      ret                                                                     '##
debugChar         byte    $4F,$BA,$BC,$08,$47,$9A,$FC,$5C                                 '##
debugChar_ret     ret                                                                     '##
debugBin          byte    $50,$BA,$BC,$08,$47,$9A,$FC,$5C                                 '##
debugBin_ret      ret                                                                     '##
debugStr          byte    $04,$B6,$FC,$A0,$08,$BC,$BC,$A0,$5E,$4A,$BC,$50,$00,$00,$00,$00 '##
                  byte    $5E,$B8,$BC,$A0,$5C,$10,$BC,$A0,$FF,$10,$FC,$62,$31,$00,$68,$5C '##
                  byte    $51,$BA,$BC,$08,$47,$9A,$FC,$5C,$08,$B8,$FC,$20,$26,$B6,$FC,$E4 '##
                  byte    $01,$BC,$FC,$80,$5E,$4A,$BC,$50,$04,$B6,$FC,$A0,$25,$00,$7C,$5C '##
debugStr_ret      ret                                                                     '##
multiply          byte    $52,$BA,$BC,$08,$01,$10,$BC,$A0,$02,$12,$BC,$A0,$47,$9A,$FC,$5C '##
                  byte    $57,$06,$BC,$08                                                 '##
multiply_ret      ret                                                                     '##
divide            byte    $53,$BA,$BC,$08,$04,$10,$BC,$A0,$05,$12,$BC,$A0,$47,$9A,$FC,$5C '##
                  byte    $57,$0C,$BC,$08,$58,$0E,$BC,$08                                 '##
divide_ret        ret                                                                     '##
debugInDec        byte    $54,$BA,$BC,$08,$47,$9A,$FC,$5C,$57,$14,$BC,$08                 '##
debugInDec_ret    ret                                                                     '##
debugInChar       byte    $55,$BA,$BC,$08,$47,$9A,$FC,$5C,$57,$14,$BC,$08                 '##
debugInChar_ret   ret                                                                     '##
cog_init          byte    $59,$BE,$3C,$08,$57,$10,$3C,$08,$58,$12,$3C,$08,$02,$BA,$7C,$0C '##
                  byte    $59,$B4,$BC,$0A,$4B,$00,$54,$5C                                 '##
cog_init_ret      ret                                                                     '##
variables1        long    $7FD0,$7FD4,$7FD8,$7FDC,$7FE0,$7FE4,$7FE8,$7FEC,$7FF0,$7FF4     '##
variables2        long    $7FF8,$7FFC,0,0,0,0,0,1,30_000,20_000_000                       '##
                                                                                          '##
'############################################################################################
'###################################### SPADE BLOCK 5 #######################################  
                                                                                          '##
Code              nop     'Start your assembly language program here!                     '##

'************************************* debugChar ********************************************
'Call #debugChar sends byte to the terminal (may wait for room in buffer).
'A 32-bit long variable "debugVar" contains the byte to be sent to the terminal.
'******************************************************************************************** 

                  mov     debugVar,#"H"
                  call    #debugChar                'Send "H" char to the terminal

                  mov     debugVar,#101
                  call    #debugChar                'Send "e" char to the terminal

                  mov     debugVar,#$6C
                  call    #debugChar                'Send "l" char to the terminal

                  mov     debugVar,#"l"
                  call    #debugChar                'Send "l" char to the terminal

                  mov     debugVar,#111
                  call    #debugChar                'Send "o" char to the terminal

                  mov     debugVar,#CR
                  call    #debugChar                'Send carriage return to the terminal

'************************************* debugDelay *******************************************
'Call #debugDelay activates a time delay for a certain number of quarter seconds from now.
'A 32-bit long variable "debugVar" contains the number of quarter seconds delay.
'********************************************************************************************

                  mov     debugVar,#BELL          
                  call    #debugChar                'Send BELL char to the terminal

                  mov     debugVar,#4
                  call    #debugDelay               'Delay 4 quater seconds or 1 second

                  mov     debugVar,#7
                  call    #debugChar                'Send BELL char to the terminal

                  mov     debugVar,#8
                  call    #debugDelay               'Delay 8 quarter seconds or 2 seconds

                  mov     debugVar,#7
                  call    #debugChar                'Send BELL char to the terminal

'************************************* debugStr *********************************************                                    
'Call #debugStr sends zero terminated string to the terminal.
'A 32-bit long variable "debugVar" contains the memory address of the string to be sent.
'SPAD strings must be terminated with a zero. 
'SPAD strings must end on a long.
'********************************************************************************************
 
                    mov     debugVar,#str1         
                    call    #debugStr               'Send string str1 to the terminal
 
                    mov     debugVar,#str2         
                    call    #debugStr               'Send string str2 to the terminal

                    mov     debugVar,#str3         
                    call    #debugStr               'Send string str3 to the terminal

                    mov     debugVar,#str4         
                    call    #debugStr               'Send string str4 to the terminal                                        

str1                byte    "SPAD strings must end on a long***",13,0     'Pad not needed
str2                byte    "SPAD strings must end on a long**",13,0,0    'Pad with one 0s
str3                byte    "SPAD strings must end on a long*",13,0,0,0   'Pad with two 0s
str4                byte    "SPAD strings must end on a long",13,0,0,0,0  'Pad with three 0s

'************************************* debugDec *********************************************
'Call #debugDec sends a decimal number to the terminal.
'A 32 bit long variable 'debugVar" contains the number to be sent to the terminal.
'********************************************************************************************

                   mov     debugVar,myVariable1  
                   call    #debugDec             'Send DEC number 2147483647 to the terminal

                   mov     debugVar,#13
                   call    #debugChar            'Send carriage return to the terminal.

                   mov     debugVar,myVariable2  
                   call    #debugDec            'Send DEC number -2147483648 to the terminal

                   mov     debugVar,#13
                   call    #debugChar           'Send carriage return to the terminal          

myVariable1        long    2_147_483_647
myVariable2        long    -2_147_483_648

'************************************* debugBin ********************************************* 
'Call #debugBin sends a 32 character representation of a binary number to the terminal.
'A 32 bit long variable "debugVar" contains the number to be sent to the terminal.
'A 32 character representation is displayed 0000_0000_0000_0000_0000_0000_0000_0000
'********************************************************************************************

                   mov     debugVar,myVariable1  
                   call    #debugBin             'Send BIN number 2147483647 to the terminal

                   mov     debugVar,#13
                   call    #debugChar

                   mov     debugVar,myVariable2  
                   call    #debugBin            'Send BIN number -2147483648 to the terminal

                   mov     debugVar,#13
                   call    #debugChar               'Send carriage return to the terminal

'************************************* debugWatchDog ****************************************                                        
'Call #debugWatchDog activates a WatchDog timer to send a selected char at a selected time. 
'A 32-bit long variable "debugVar" contains the selected number of quarter seconds delay.
'A 32-bit long variable "debug_Var" contains the selected char to be sent.
'********************************************************************************************

                  mov     debugVar,#7               'WatchDog timer = 7 qtrSec or 1.75 secs.
                  mov     debug_Var,#"#"            'WatchDog char = "#"
                  call    #debugWatchDog            'WatchDog timer on

'************************************* debugInChar ******************************************                  
'Call #debugInChar gets byte from the terminal.
'A 32 bit long variable "debugInVar" returns the corresponding value.
'********************************************************************************************

                  call    #debugInChar              'Get char sent by WatchDog timer
                  
                  mov     debugVar,debugInVar
                  call    #debugChar                'Send WatchDog timer char to the terminal

                  mov     debugVar,#13
                  call    #debugChar                'Send carriage return to the terminal

'************************************* debugInDec *******************************************                     
'Call #debugInDec gets decimal characer representation of a number from the terminal.
'A 32 bit long variable "debugInVar" returns the corresponding value.
'Number should be equal or greater than -2_147_483_648 and equal or less than 2_147_483_647.
'Exceeding limits on either side returns "zero".
'Each complete number entry should be followed by a single carriage return. 
'Entering a carriage return without a number returns "zero".
'Entering a carriage return from the WatchDog timer without a number returns "zero". 
'********************************************************************************************

                  mov     debugVar,#str5
                  call    #debugStr                 'Send string str5 to the terminal

                  mov     debugVar,#str6
                  call    #debugStr                 'Send string str6 to the terminal

                  mov     debugVar,#32              'WatchDog timer = 32 qtrSec
                  mov     debug_Var,#CR             'WatchDog char = CR
                  call    #debugWatchDog            'WatchDog timer on

                  call    #debugInDec               'Get Dec input from the terminal

                  mov     debugVar,debugInVar
                  call    #debugDec                 'Send Dec input to the terminal

                  mov     debugVar,#13
                  call    #debugChar                'Send carriage return to the terminal

                  cmp     debugInVar,#0 wz          'Check for WatchDog timer return
            if_z  jmp     #over      

                  mov     debugVar,#16              'Wait for WatchdDog timer completion
                  call    #debugDelay

over              nop                  

str5              byte    "Enter number followed by carriage return in 8 seconds or",13,0,0,0
str6              byte    "WatchDog timer will enter carriage return and autoRun",13,0,0

'************************************* multiply *********************************************
'Call #multiply is an unsigned 32-bit multiplication routine.
'Two 32-bit long variables "multiC" and "multiP" are multiplied. 
'A 32-bit long variable "product" returns the corresponding value.
'If the product is greater than 2_147_483_647, product returns "zero".
'If "multiC" or "multiP" are negative, product returns "zero".
'********************************************************************************************

                  mov     multiC,myVariable3
                  mov     multiP,#9       
                  call    #multiply                 'Multiply myVariable3 X 9
                  
                  mov     debugVar,product
                  call    #debugDec                 'Send decimal product to the terminal

myVariable3       long    123456789

                  mov     debugVar,#13
                  call    #debugChar                'Send carriage return to the terminal

'************************************* divide ***********************************************                  
'Call divide is an unsigned 32-bit division routine.
'A 32-bit long variable "dividend" is divided by a 32-bit long variable "divisor".
'A 32-bit long variable "quotient" returns the corresponding value.
'A 32-bit long variable "remainder" returns the corresponding value.
'If the "dividend" is negative or "zero", the "quotient" and "remainder" are "zero".
'If the "divisor" is negative or "zero", the "quotient" and "remainder" are "zero".
'******************************************************************************************** 
 
                  mov      dividend,myVariable3
                  mov      divisor,#8
                  call     #divide                  'Divide myVariable3 / 8
                  
                  mov      debugVar,quotient
                  call     #debugDec                'Send decimal quotient to the terminal

                  mov      debugVar,#13
                  call     #debugChar               'Send carriage return to the terminal
                  
                  mov      debugVar,remainder
                  call     #debugDec                'Send decimal remainder to the terminal

                  mov      debugVar,#13
                  call     #debugChar               'Send carriage return to the terminal

                  mov      debugVar,#16
                  call     #debugDelay              'Delay 16 quarter seconds or 4 seconds

                  mov      debugVar,#CLS
                  call     #debugChar               'Clear terminal screen

                  mov      debugVar,#8
                  call     #debugDelay              'Delay 8 quarter seconds or 2 seconds
                  

                  jmp     #code                                                          

                  fit 
        