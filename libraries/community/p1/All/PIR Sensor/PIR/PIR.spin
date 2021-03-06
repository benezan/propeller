{{
***************************************
*        PIR Object V1.0              *
*      (C) 2008 Parallax, Inc.        *
* Author:  Joshua Donelson            *
* Started: 06-03-2008                 *
***************************************

Interfaces the PIR sensor with the Propeller Demo Board.
PIR senses movement and temperature changes within a proximity of about 20 feet.
The PIR module can run either on 3.3 VDC or 5 VDC; however this example program utilizes
a 5 VDC supply from the Demo Board.

       PIR SENSOR 
  ┌───────────────────┐
  │     ┌───────┐     │    :: Connection To Propeller ::
  │     │   ‣   │     │        1 - Ground
  │     └───────┘     │        2 - Either 5 or 3.3 VDC (5 VDC in this example)
  │    GND +5V SIG    │        3 - Signal to Input PIN with 2kΩ resistor
  └─────┬───┬───┬─────┘                                                 
        │  │    2K
          └┘   └ Pin

 
--------------------------REVISION HISTORY--------------------------
  N/A
--------------------------------------------------------------------
 
Copyright (c) 2008 Parallax, Inc. 

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
documentation files (the "Software"), to deal in the Software without restriction, including without limitation
the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software,
and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
The above copyright notice and this permission notice shall be included in all copies or substantial portions of
the Software. 

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED
TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

}}

_clkmode = xtal1 + pll16x                               ' Setting Clock Mode to Crystal 1 with 16 multiplier 
_xinfreq = 5_000_000                                    ' Propeller set to run at 80MHz

                                                                                 
PUB PIR | countdown                                     ' Public Method name PIR (proximity sensor); with a local long sized variable countdown

  dira[1]~                                              ' Set PIN1 to input
  dira[16..17]~~                                        ' Set P16-P17 to outputs                       
  outa[16..17]~                                         ' Set P16-P17 to low

countdown := 30                                         ' Assigned variable "countdown" a value of 30                      

  !outa[17]                                             ' Toggle PIN17 to indicate PIR warm-up process has begun

  repeat until NOT countdown                            ' Repeat loop until countdown = 0
    waitcnt(clkfreq + cnt)                              ' Wait 1 second
    countdown --                                        ' subtract 1 from variable countdown

  !outa[17]                                             ' Toggle PIN17 to indicate warm-up process finished
                      
  repeat                                                ' Repeat
   if ina[1] == 1                                       ' If PIN1 equals a 1 (PIR is triggered)
     !outa[16]                                          ' Toggle PIN16 (LED on)
     waitcnt(clkfreq/10 + cnt)                          ' Wait a 10th of a second
     !outa[16]                                          ' Toggle PIN16 (LED off)