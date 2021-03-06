{{┌──────────────────────────────────────────┐
  │ Parallel LCD driver, 4-bit mode          │   
  │ Author: Chris Gadd                       │   
  │ Copyright (c) 2013 Chris Gadd            │   
  │ See end of file for terms of use.        │   
  └──────────────────────────────────────────┘

  This object is specifically intended to be used with 4-line 20-column displays, though will work with smaller sizes as well
  Includes methods for scrolling text left, up, right, or down

   Send:           Sends one byte - can be a command or a character             LCD.Send("A")
   Str:            Sends a string of command and text bytes                     LCD.Str(string($01,"top line",$C0,"bottom line"))
   Dec:            Displays an ASCII string equivalent of a decimal value       LCD.Dec(1234)
   Hex:            Display the ASCII string equivalent of a hexadecimal number  LCD.Hex($1234, 4)
   Bin:            Display the ASCII string equivalent of a binary number       LCD.Bin(%0001_0010_0011_0100, 16)
   Scroll_r:       Scroll a string right                                        LCD.scroll_r(@test_string,1)
   Scroll_l:       Scroll a string left                                         LCD.scroll_l(@test_string,1)
   Scroll_all:     Scroll up to four lines right or left                        LCD.scroll_all(@line1,"R",@line2,"R",0,0,@line4,"L")
   Scroll_up:      Scroll all lines up and add a new line to bottom             LCD.scroll_up(@bottom_line)
   Scroll_down:    Scroll all lines down and add a new line to top              LCD.scroll_down(@top_line)
   blink:          Blink the entire display                                     LCD.blink(10)
   blink_ind:      Blink one line                                               LCD.blink_ind(1,5)

   Clear:          Clears the LCD display and sets the cursor to home position  LCD.Clear
   Home:           Moves the cursor to the home position                        LCD.Home
   Move:           Moves the cursor to specified position                       LCD.Move(2,1) <- Line 2 column 1


  ┌─Hitachi HD44780 LCD─────────────────────────────────────────────┐    
  │   00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19   │ <- CHARACTER POSITION
  │  ┌──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┐  │                      
  │  │00│01│02│03│04│05│06│07│08│09│0A│0B│0C│0D│0E│0F│10│11│12│13│  │ <- ROW0 DDRAM ADDRESS
  │  │40│41│42│43│44│45│46│47│48│49│4A│4B│4C│4D│4E│4F│50│51│52│53│  │ <- ROW1 DDRAM ADDRESS
  │  │14│15│16│17│18│19│1A│1B│1C│1D│1E│1F│20│21│22│23│24│25│26│27│  │ <- ROW2 DDRAM ADDRESS
  │  │54│55│56│57│58│59│5A│5B│5C│5D│5E│5F│60│61│62│63│64│65│66│67│  │ <- ROW3 DDRAM ADDRESS
  │  └──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┘  │     
  └┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬────┘     
   D7  D6  D5  D4  D3  D2  D1  D0  E   R/W Rs  V0  Vdd Vss NC  NC      
   │   │   │   │   │   │   │   │   │   │   │   │   │  │               
                   x   x   x   x               │   ┣─┘ │ 5V            
                                               └──   │ 10KΩ-20KΩ     
                                                   ┣───┘               
   RS      - low for commands, high for text                          
   R/W     - low for write, high for read                              
   E       - clocks the data lines                                     
   D7 - D4 - data input in 4-bit mode                                  
   D3 - D0 - not used in 4-bit mode                                    
   D7 through D4 must be connected to consecutive pins, D4 on low-pin    
                                                                         
 ┌─────────────┬───────┬──────────────────────────────────┬───────────────────────────────────┐
 │ Instruction │ RS R/W│ DB7 DB6 DB5 DB4 DB3 DB2 DB1 DB0  │  Description                      │
 ├─────────────┼───────┼──────────────────────────────────┼───────────────────────────────────┤
 │ Clear       │  0  0 │  0   0   0   0   0   0   0   1   │  Clears entire display and        │
 │ display     │       │                                  │  sets DDRAM address 0 in          │
 │             │       │                                  │  address counter.                 │
 ├─────────────┼───────┼──────────────────────────────────┼───────────────────────────────────┤
 │ Return      │  0  0 │  0   0   0   0   0   0   1   -   │  Sets DDRAM address 0 in          │
 │ home        │       │                                  │  address counter. Also            │
 │             │       │                                  │  returns display from being       │
 │             │       │                                  │  shifted to original position.    │
 │             │       │                                  │  DDRAM contents remain            │
 │             │       │                                  │  unchanged.                       │
 ├─────────────┼───────┼──────────────────────────────────┼───────────────────────────────────┤
 │ Entry       │  0  0 │  0   0   0   0   0   1  I/D  S   │  Sets cursor move direction       │
 │ mode set    │       │                                │  and specifies display shift.     │
 │             │       │   1=increment / 0=decrement  │   │  These operations are             │
 │             │       │   Accompanies display shift──┘   │  performed during data write      │
 │             │       │                                  │  and read.                        │
 │             │       │                                  │                                   │
 │             │       │                                  │   This object uses 0000_0110      │
 ├─────────────┼───────┼──────────────────────────────────┼───────────────────────────────────┤
 │ Display     │  0  0 │  0   0   0   0   1   D   C   B   │  Sets entire display on/off,      │
 │ on/off      │       │                               │  cursor on/off, and blinking of   │
 │ control     │       │       display on/off─┘   │   │   │  cursor position character.       │
 │             │       │            cursor on/off─┘   │   │                                   │
 │             │       │              blinking on/off─┘   │   This object uses 0000_1100      │
 ├─────────────┼───────┼──────────────────────────────────┼───────────────────────────────────┤
 │ Cursor or   │  0  0 │  0   0   0   1  S/C R/L  -   -   │  Moves cursor and shifts          │
 │ display     │       │                                │  display without changing         │
 │ shift       │       │  1=display shift─┤   │           │  DDRAM contents.                  │
 │             │       │  0=cursor move───┘   │           │                                   │
 │             │       │        1=shift right─┤           │                                   │
 │             │       │        0=shift left──┘           │                                   │
 ├─────────────┼───────┼──────────────────────────────────┼───────────────────────────────────┤
 │ Function    │  0  0 │  0   0   1  DL   N   F   -   -   │  Sets interface data length (DL), │
 │ set         │       │                               │  number of display lines (N),     │
 │             │       │    1=8-bit──┤    │   │           │  and character font (F).          │
 │             │       │    0=4-bit──┘    │   │           │                                   │
 │             │       │        1=2 lines─┤   │           │   This object uses 0010_1000      │
 │             │       │        0=1 line──┘   │           │                                   │
 │             │       │               1=5x10─┤           │                                   │
 │             │       │               0=5x8──┘           │                                   │
 ├─────────────┼───────┼──────────────────────────────────┼───────────────────────────────────┤
 │ Set         │  0  0 │  0   1  ACG ACG ACG ACG ACG ACG  │  Sets CGRAM address.              │
 │ CGRAM       │       │                                  │  CGRAM data is sent and           │
 │ address     │       │                                  │  received after this setting.     │
 ├─────────────┼───────┼──────────────────────────────────┼───────────────────────────────────┤
 │ Set         │  0  0 │  1  ADD ADD ADD ADD ADD ADD ADD  │  Sets DDRAM address.              │
 │ DDRAM       │       │                                  │  DDRAM data is sent and           │
 │ address     │       │                                  │  received after this setting.     │
 ├─────────────┼───────┼──────────────────────────────────┼───────────────────────────────────┤
 │ Read busy   │  0  1 │  BF  AC  AC  AC  AC  AC  AC  AC  │  Reads busy flag (BF)             │
 │ flag &      │       │                                  │  indicating internal operation    │
 │ address     │       │                                  │  is being performed and           │
 │             │       │                                  │  reads address counter            │
 ├─────────────┼───────┼──────────────────────────────────┼───────────────────────────────────┤
 │ Write data  │  1  0 │        Write data                │  Writes data into DDRAM or        │
 │ to CG or    │       │                                  │  CGRAM.                           │
 │ DDRAM       │       │                                  │                                   │
 ├─────────────┼───────┼──────────────────────────────────┼───────────────────────────────────┤
 │ Read data   │  1  1 │        Read data                 │  Reads data from DDRAM or         │
 │ from CG or  │       │                                  │  CGRAM.                           │
 │ DDRAM       │       │                                  │                                   │
 └─────────────┴───────┴──────────────────────────────────┴───────────────────────────────────┘
                                                                         
         Send high nibble                           D7 is high in 1st nibble if LCD is busy        
         │ Send low nibble     Max rate if             Busy flag set   Clear                       
         │ │ Read busy flag     busy flag low          │   │   │   │   │ Clock 2nd nibble through  
                                                                                          
   D7   ────────────                            
   D6                               
   D5                               
   D4                               
                                                                                                   
   E                                
   R/W                              
   RS                               
                                                                                                
         │   Read busy flag      Send Text                                                         
         Send command                                                                              
}}
CON                                       
  CLS   = $01     ' Clear screen
  Hm    = $02     ' Home display and cursor
  CL    = $10     ' Shift cursor left one
  CR    = $14     ' Shift cursor right one

  columns = 20      

VAR
  long E,RW,RS,D4,D7                      ' declaring these as longs actually requires less space than declaring as bytes

  long  array_ptr
  byte  array[80]
  byte  temp[20]

PUB start(_E,_RW,_RS,_D4)

  E  := _E                             
  RW := _RW                               
  RS := _RS
  D4 := _D4
  D7 := _D4 + 3

  dira[D7..D4]~~
  dira[RW]~~
  dira[RS]~~
  dira[E]~~

  init                                                                                                  ' Initialize as per the datasheet

PUB send(LCD_byte) | ptr
{{
   Displays a single byte
   Parameters: _LCD_byte = byte to be displayed
   example usage: LCD.send("A")
}}
  if $1F < LCD_byte and LCD_byte < $80
    array[array_ptr] := LCD_byte
    text(array_ptr)
    array_ptr++
    case array_ptr
      20,40,60,80: array_ptr -= 20    
  else
    command(LCD_byte)

PUB Str(stringPtr)
{{
   Transmit a string of bytes
   Parameters: stringPtr = the pointer address of the null-terminated string to be sent
   example usage: LCD.Str(@test_string)
}}   
  repeat strsize(stringPtr)
    Send(byte[stringPtr++])                                                                             ' Display each byte in the string

PUB Dec(value) | i, x
{{
   Display the ASCII string equivalent of a decimal value
   Parameters: dec = the numeric value to be displayed
   example usage: LCD.Dec(-1_234_567_890)
}}     
  x := value == NEGX                                                                                    ' Check for max negative
  if value < 0
    value := ||(value+x)                                                                                ' If negative, make positive; adjust for max negative
    Send("-")                                                                                           ' and output sign

  i := 1_000_000_000                                                                                    ' Initialize divisor

  repeat 10                                                                                             ' Loop for 10 digits
    if value => i                                                               
      Send(value / i + "0" + x*(i == 1))                                                                ' If non-zero digit, output digit; adjust for max negative
      value //= i                                                                                       ' and digit from value
      result~~                                                                                          ' flag non-zero found
    elseif result or i == 1
      Send("0")                                                                                         ' If zero digit (or only digit) output it
    i /= 10                                                                                             ' Update divisor

PUB Hex(value, digits)
{{
   Display the ASCII string equivalent of a hexadecimal number
   Parameters: value = the numeric hex value to be transmitted
               digits = the number of hex digits to print                 
   example usage: LCD.Hex($AA_FF_43_21, 8)
}}              
  value <<= (8 - digits) << 2
  repeat digits                                                                                         ' do it for the number of hex digits being transmitted
    Send(lookupz((value <-= 4) & $F : "0".."9", "A".."F"))                                              ' Display the ASCII value of the hex characters

PUB Bin(value, digits)
{{
   Display the ASCII string equivalent of a binary number
   Parameters: value = the numeric binary value to be transmitted
               digits = the number of binary digits to print                 
   example usage: LCD.Bin(%1110_0011_0000_1100_1111_1010_0101_1111, 32)
}}      
  value <<= 32 - digits
  repeat digits
    Send((value <-= 1) & 1 + "0")                                                                       ' Display the ASCII value of each binary digit
    
PUB Scroll_r(stringPtr, row)
{{
   Display a line of text scrolling from the right
   Parameters: stringPtr = the pointer address of the null-terminated string to be sent
               row = row(1-4) on which to display the string                 
   example usage: LCD.Scroll_r(@test_string,1)
}}
  repeat strsize(stringPtr)
    waitcnt(cnt + clkfreq / 10)
    scroll_r_1(byte[stringPtr++],row)

PUB Scroll_l(stringPtr, row) | i
{{
   Display a line of text scrolling from the left
   Parameters: stringPtr = the pointer address of the null-terminated string to be sent
               row = row(1-4) on which to display the string                 
   example usage: LCD.Scroll_l(@test_string,1)
}}
  i := stringPtr + strsize(stringPtr)
  repeat strsize(stringPtr)
    waitcnt(cnt + clkfreq / 10)
    scroll_l_1(byte[--i],row)

PUB Scroll_all(row_1,dir1,row_2,dir2,row_3,dir3,row_4,dir4) | ptr1, ptr2, ptr3, ptr4, n, len1, len2, len3, len4
{{
   Scroll any number of lines left or right
   Parameters: row_1, row_2, row_3, row_4 = pointer address of the null-terminated string to be sent on each row
               dir1, dir2, dir3, dir4 = direction to scroll each line
   example usage: LCD.Scroll_all(@line_1_string,"R",@line_2_string,"L",@line_3_string,"R",0,0) ' lines 1 & 3 scroll right, 2 scrolls left, and 4 does not scroll
}}
  len1 := strsize(row_1)
  len2 := strsize(row_2)
  len3 := strsize(row_3)
  len4 := strsize(row_4)

  repeat while len1 or len2 or len3 or len4
    waitcnt(cnt + clkfreq / 10)
    if len1
      if dir1 == "R"
        scroll_r_1(byte[row_1++],1)
      if dir1 == "L"
        scroll_l_1(byte[row_1 + len1 - 1],1)
      len1--

    if len2
      if dir2 == "R"
        scroll_r_1(byte[row_2++],2)
      if dir2 == "L"
        scroll_l_1(byte[row_2 + len2 - 1],2)
      len2--

    if len3
      if dir3 == "R"
        scroll_r_1(byte[row_3++],3)
      if dir3 == "L"
        scroll_l_1(byte[row_3 + len3 - 1],3)
      len3--

    if len4
      if dir4 == "R"
        scroll_r_1(byte[row_4++],4)
      if dir4 == "L"
        scroll_l_1(byte[row_4 + len4 - 1],4)
      len4--

PUB Scroll_up(stringPtr) | i, row
{{
   Scroll all display up one line and add a new line to the bottom
   Parameters: stringPtr = the pointer address of the null-terminated string to be sent
   example usage: LCD.Scroll_up(@test_string)
}}
  repeat row from 4 to 2
    move(row,1)
    repeat i from 0 to columns - 1
      send(array[array_ptr - 20])
  move(1,1)
  str(stringPtr)
  repeat until array_ptr == columns - 1
    send(" ")  

PUB Scroll_down(stringPtr) | i, row
{{
   Scroll all display up one line and add a new line to the top
   Parameters: stringPtr = the pointer address of the null-terminated string to be sent
   example usage: LCD.Scroll_down(@test_string)
}}
  repeat row from 1 to 3
    move(row,1)
    repeat i from 0 to columns - 1
      send(array[array_ptr + 20])
  move(4,1)
  str(stringPtr)
  repeat until array_ptr == 60 + columns - 1
    send(" ")
      
PRI scroll_r_1(char, row)
{{
  Scoll right one position
}}
  move(row,1)
  array_ptr := (row - 1) * 20
  repeat columns - 1
    Send(array[array_ptr + 1])
  Send(char)

PRI scroll_l_1(char, row) | i                         
{{
  Scoll left one position
}}

  array_ptr := (row - 1) * 20 + columns - 1
  repeat i from columns to 2
    move(row,i)
    Send(array[array_ptr - 1])
  move(row,1)
  Send(char)

PUB Blink(count)
{{
  Blink the display at a 1Hz rate
  Parameters: count = number of times to blink the display
                       0 causes the display to blink indefinitely
  example usage: LCD.Blink(10)
}}

  repeat while Count := --Count #> -1                                                                
    waitcnt(clkfreq / 2 + cnt)                                                                          
    Send(%0000_1000)                                                                                    
    waitcnt(clkfreq / 2 + cnt)
    Send(%0000_1100)              

PUB Blink_ind(row,count) | i
{{
  Blink a single line at a 1Hz rate
  Parameters: count = number of times to blink the display
                       0 causes the display to blink indefinitely
  example usage: LCD.Blink_ind(10)
}}

  bytemove (@temp,@array[(row - 1) * 20],columns)
  repeat while Count := --Count #> -1                                                                 
    waitcnt(clkfreq / 2 + cnt)
    move(row,1)
    repeat columns
      Send(" ")
    waitcnt(clkfreq / 2 + cnt)
    move(row,1)
    repeat i from 0 to columns - 1
      send(temp[i])

PUB Clear
{{
   Clears the display and moves the cursor to row 1 column 1
   Parameters: none
   example usage: LCD.Clear  
   alternate to: LCD.Send(LCD#CLS)
}}

  Send(CLS)
  array_ptr := 0
  bytefill(@array," ",80)

PUB Home
{{
   Moves the cursor back to row 1 column 1
   Parameters: none
   example usage: LCD.Home
   alternative to: LCD.Send(LCD#Hm)
}}

  Send(Hm)
  array_ptr := 0

PUB Move(Row, Column)
{{
   Moves the cursor position to row,column
   Parameters: column = first(1), last(20)
               Row   = top(1) through bottom(4)
   example usage: LCD.Move(2,1) moves cursor to row 2 column 1
}}

   Send($80 | ((row - 1) & %01 * $40) | ((row - 1) & %10 * 10) + (column - 1))
   array_ptr := (row - 1) * 20 + column - 1

CON
''Low-level methods for driving the display

PRI init

  waitcnt(cnt + (clkfreq / 1000) * 20)                                          ' > 15ms
  outa[D7..D4] := %0011                                                         ' Set 8-bit mode
  clock
  waitcnt(cnt + (clkfreq / 1000) * 5)                                           ' > 4.1ms
  outa[D7..D4] := %0011                                                         ' Set 8-bit mode
  clock
  waitcnt(cnt + clkfreq / 1000)                                                 ' > 100us
  outa[D7..D4] := %0011                                                         ' Set 8-bit mode
  clock

  check_busy_flag
  outa[D7..D4] := %0010                                                         ' Set 4-bit mode
  clock
  command(%0010_1000)                                                           ' 4-bit mode, 2-line, 5x8 pixel characters
  command(%0000_1100)                                                           ' Turn display on, no cursor, no blinking
  command(%0000_0110)                                                           ' Increment cursor, no display shift
  clear

PRI command(data)
  check_busy_flag
  outa[RS]~
  send_nibbles(data)

PRI text(ptr) 
  check_busy_flag
  outa[RS]~~
  send_nibbles(array[ptr])

PRI send_nibbles(data)  
  outa[D7..D4] := data >> 4
  clock
  outa[D7..D4] := data 
  clock

PRI check_busy_flag | busy

  busy := 1
  dira[D7]~
  outa[RS]~
  outa[RW]~~
  repeat while busy
    outa[E]~~
    busy := ina[D7]                                                             ' Check busy flag while E is high
    outa[E]~
    clock
  dira[D7]~~
  outa[RW]~

PRI clock
  outa[E]~~
  outa[E]~  

DAT
{{
┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                   TERMS OF USE: MIT License                                                  │                                                            
├──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation    │ 
│files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,    │
│modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software│
│is furnished to do so, subject to the following conditions:                                                                   │
│                                                                                                                              │
│The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.│
│                                                                                                                              │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE          │
│WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR         │
│COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,   │
│ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                         │
└──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
}}                      