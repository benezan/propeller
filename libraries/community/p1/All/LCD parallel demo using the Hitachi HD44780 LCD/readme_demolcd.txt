{{
LCDDEMO Version 1.2 April 21,2007
Added the ability to define custom characters
Added the ability to change already defined custom characters while they're being displayed
Changed method to send commands to the LCD a public method  
Added clear current line
Fixed some minor problems
Removed use of escape to display characters.
Legal character codes are now, 0-7 and 32-127

Version 1.1 April 16,2007
Added the escape character test in the string output
so that any character (0-255) can be sent to the display
Added lines per display (lcdlines) so that other displays
(1 to n lines) can be used.

4 bit parallel interface to a
4 line by 20 character LCD
Which uses the Hitachi HD44780 LCD controller

**************************************************
*****  DO NOT set the clock for RCMODE=SLOW  *****
**************************************************

These are the connections I used

  PORTA          LCD Display
           ┌──── PIN 1  GND
           │ +5V PIN 2  VCC
           ┣──── PIN 3  Contrast
  PIN 5 ───┼──── PIN 4  Enable
           ┣──── PIN 5  RD/!WR
  PIN 4 ───┼──── PIN 6  Register Select
           ┣──── PIN 7  D0
          ┌╋──── PIN 8  D1
          ┣──── PIN 9  D2
           └──── PIN 10 D3
  PIN 3───────── PIN 11 D4
  PIN 2───────── PIN 12 D5
  PIN 1───────── PIN 13 D6
  PIN 0───────── PIN 14 D7 



Methods used in LCDDEMO:
pub init  'Initialize the LCD to four bit mode and clear it
pub writestr(stringptr)          Write out a string to the LCD
pub writecg(CharCode, stringptr) Write custom characters to the cg ram
pub writecgline(CharCode, CharLine, stringptr) Write a line into a custom character
pub commandOut(code)             Write out a command to the display controller
pub writeOut(character)          Write out a single character to the display
pub cls                          Clear the display
pub cll                          Clear the current line
pub cursor_on                    Turn the cursor and blink on
pub cursor_off                   Turn the cursor and blink off
pub pos(line,column)             Set the position
pub home                         Go back to the start of the line
pub uSdelay(DelayuS)             Delay for # of microseconds

                                Method Descriptons:
                                
        init                     Initialize the LCD

        writestr(@string)        Write a string at the current position
                If the string is terminated by a carriage return ($0D) or
                line feed ($0A) then the position will move to the next line
                If the string exceeds the line length, then it will wrap to the next
                line. If this occurs on the last line, it will wrap to the first line        

        writecg(character code, @string) Write a custom character to the cg ram
                Character codes may be 0-7
                string contains the data for the code(s)
                more than one character may be written at a time
                Creation of custom characters is eased by using the
                LCD Character Creator from Parallax but copy only the hex code portion from
                the LCD Character Creator
                  WRONG: Char0 DATA $00,$00,$00,$00,$00,$00,$00,$00
                  RIGHT: $00,$00,$00,$00,$00,$00,$00,$00 
                Terminate the write process with an eog ($FF)

        writecgline(character code, character line, @string)
                Character codes may be 0-7
                Character lines may be 0-7
                Terminate the same way as writecg (eog)

        commandOut(code)         Write a command to the display controller

        writeOut("character")    Write a single character at the current position

        cls                      Clear the display

        cll                      Clear the current line
        
        cursor_on                Cursor on and blinking
        
        cursor_off               Turn the cursor off. Off is default after initialization

        pos(line, column)        Set position at line 1-4, column 1-20
        
        home                     Home to the beginning of the current line
        
        uSdelay(#microseconds)   Delay a specific number of microseconds

Object "LCDDEMO" Interface:

PUB  init
PUB  writestr(stringptr)
PUB  writecg(CharCode, stringptr)
PUB  writecgline(CharCode, CharLine, stringptr)
PUB  commandOut(char)
PUB  writeOut(character)
PUB  cls
PUB  cll
PUB  cursor_on
PUB  cursor_off
PUB  pos(line, column)
PUB  home
PUB  uSdelay(DelayuS)

Program:     146 Longs
Variable:      1 Longs
}}