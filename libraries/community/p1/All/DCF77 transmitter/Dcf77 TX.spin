{
┌──────────────────────────────────────────┐
│ DCF77TX.spin             Version 1.00    │
│ Author: Thierry Eggen  ON5TE             │               
│ Copyright (c) 2012 Thierry Eggen         │               
│ See end of file for terms of use.        │                
└──────────────────────────────────────────┘

DCF77 is a radio station transmitting time and date signals on 77.500 KHz.

This is a demo to simulate the DCF77 transmitter installed in Europe at Mainflingen (Germany, near Frankfurt).

It's for sure not a brilliant example of compact and efficient programming.
Some boaring lists of instructions could be replaced by more sophisticated loops.
We could also create a man-machine interface to enter initial date and time stamps.
Currently, RTC.settime and RTC.setdate are simply coded in the program.

DCF77 is sending a 77.500 Hz carrier.
At each second transistion, the carrier level is reduced approx 25% during
either 200 milliseconds or 100 milliseconds. 200 means a bit 1, 100 means a bit 0.
Transition to second 59 does not carry any bit (no power reduction).
That means that the next start of a bit will correspond to a minute transition.
So we can easily synchronize on minutes and seconds.
The sequence of 59 bits (each one transmitted at a second transition) encodes date and time information
as well as other useful data.

How it works:
- First of all we initialize a realtime clock in a cog (thanks to Mathew Brown)
  and let it run on its own forever
- Then we wait for next minute transition, get date and time from the RTC and
  prepare the 59 bits list into vector.
- Then we simply browse that vector and reduce the carrier level accordingly.
- The transmitter could use directly the Propeller's internal counters to generate the HF, however I
  preferred to use the nice synthesizer proposed by Johannes Ahlebrand because:
  - we can synthesize a much easy to filter signal
  - DCF "modulation" is very easy to perform via the PSG.Setdamplevel routine  
  
Extra hardware:
Not much: a simple one pole filter on PinHF (ex one 10k resistor connected to the pin,
and on a 10k capacitor on the other side, the capa being grounded on the other side;
output at the RC connection).
Not doing that filtering may result in quite heavy noise in sensitive receivers:
up to 145 MHz and probably over.
The "antenna" can be made of a simple wire looped around the receiving clock a couple of times.

It should be quite easy to amplify that signal and foolish some nearby DCF clocks, but not legal ...

By the way, you may use the excellent DCF77 receiver for Propeller written by M.Majoor
and get DCF receiver hardware from Conrad in Germany..

}
CON
  _CLKMODE  = XTAL1 + PLL16X
  _XINFREQ  = 5_000_000

  PinHF         = 3             ' synthesized HF signal output pin
  PinHF2        = 4             ' inverted synthesized HF signal output pin
  PinMod        = 1             ' pin to exhibit  seconds pulses
  Damplevel     = 2             ' damping level of output HF. 1 means 6 dB, 2 is 12 dB etc.
  
  One           = 1
  Zero          = 0
  Nothing       = 2
  ' DCF bits meaning (see DCF protocol)
  BitAntenna    = 15            ' 0 = normal antenna, 1 = backup antenna
  BitNearChange = 16            ' 1 = approaching change from MEZ to MESZ or back
  BitTimeZone   = 17            ' bits 17 and 18 '10' means CET (utc+1) and "01" means CEST, daylight saving (utc+2)
  BitLeap       = 19            ' leap second encoded here one hour before occurrence
  BitStart      = 20            ' Start bit for time string: ALWAYS 1
  BitMinute     = 21            ' from 21 to 27 encoded in 1,2,4,8,10,20,40  with one minute in bit 21
  BitMinuteParity = 28          ' even parity on bits 21 to 28
  BitHour       = 29            ' bit 29 to 34 encoded in 1,2,4,8,10,20 with one hour in bit 29
  BitHourParity = 35            ' even parity on bits 29 to 35
  BitDayMonth   = 36            ' bit 36 to 41 encoded in 1,2,4,8,10,20
  BitDayWeek    = 42            ' bit 42 to 44 encoded in 1,2,4
  BitMonth      = 45            ' bit 45 to 49 endoded in 1,2,4,8,10
  BitYear       = 50            ' bit 50 to 57 encoded in 1,2,4,8,10,20,40,80
  BitParity     = 58            ' even parity on bits 36 to 58
  Bit59         = 59            ' no signal sent on this bit    

OBJ
  pst : "Parallax Serial Terminal"                   ' Serial communication object for debugging            
  rtc:  "RealTimeClock"                              ' excellent routines from Obex
  psg : "PropellerSignalGenerator"                   ' another great routine from Obex

VAR
  byte Seconds
  byte Minutes
  byte Hours                                            ' 0..23 hour indication
  byte WeekDay
  byte Days
  byte Months
  word Years

  byte Vector[60]     '  we preset here the bits sequence for the next minute

  word i 
  byte  tmp


PUB Main

  ' inits

  repeat i from 0 to 59         ' make sure the vector is initialized to zero
    vector[i] := Zero

  repeat 3     
   waitcnt(clkfreq + cnt)       ' just to give time to switch to terminal and enable it without loss
  
  pst.start(57600)              ' init terminal session
  pst.clear                     ' clear screen
  pst.str(string("OK we start"))
  pst.newline

  'Start Real time clock
  RTC.Start
  waitcnt(clkfreq + cnt)        ' delay to give time to initialize timer

  
  'Preset time/date...
  RTC.SetTime(15,59,58)                                 '
  RTC.SetDate(12,10,09)                                 '
  
  'Spit out start of message to terminal
  displaydate
  
  'Start "Propeller Signal Generator" and output signal on pinHF (inverted signal on pinHF2)
  psg.start(PinHF, PinHF2, 32) ' Sync pin = 32 = No sync pin needed
  psg.setParameters(psg#SINUS, 77500, 0, 0)  ' sinus wave (in PWM) and frequency is 77.5 KHz
    
  'repeat
    'Wait for next minute to pass, rather than constantly sending time/date to debug comms
    'Minutes := RTC.ReadTimeReg(1)                          'Read current minute
    repeat while Minutes == RTC.ReadTimeReg(1)             'Wait until minutes changes
      pst.dec(minutes)
      pst.newline
  Dira[pinmod] := 1      ' clamp the signal 
   ' main loop
  repeat
    ' get time information from clock
     Seconds := RTC.ReadTimeReg(0)                          'Read current second
     Minutes := RTC.ReadTimeReg(1)                          'Read current minute
     Hours   := RTC.ReadTimeReg(2)                          'etc.
     Days    := RTC.ReadTimeReg(3)                          '
     Months  := RTC.ReadTimeReg(4)                          '
     Years   := RTC.ReadTimeReg(5)                          '
     WeekDay := RTC.ReadTimeReg(6)                          '
          
    ' fill in vector with that info, compute also parity bits

    ' minutes
      tmp  := minutes
      vector[BitMinute + 6] := tmp/40
      tmp := tmp//40
      vector[BitMinute + 5] := tmp/20
      tmp := tmp//20      
      vector[BitMinute+4] := tmp/10
      tmp := tmp//10    
      vector[BitMinute+3] := tmp/8
      tmp := tmp//8
      vector[BitMinute+2] := tmp/4
      tmp := tmp//4
      vector[BitMinute+1] := tmp/2
      tmp := tmp//2
      vector[BitMinute] := tmp
    ' parity on minutes
      tmp := 0
      repeat i from BitMinute to (BitMinuteParity-1)
        tmp := tmp + Vector[i]
      Vector[BitMinuteParity] := tmp//2               

      ' hours
      tmp  := hours
      vector[BitHour + 5] := tmp/20
      tmp := tmp//20      
      vector[BitHour+4] := tmp/10
      tmp := tmp//10    
      vector[BitHour+3] := tmp/8
      tmp := tmp//8
      vector[BitHour+2] := tmp/4
      tmp := tmp//4
      vector[BitHour+1] := tmp/2
      tmp := tmp//2
      vector[BitHour] := tmp
    ' parity on hours
      tmp := 0
      repeat i from BitHour to (BitHourParity - 1)
        tmp := tmp + Vector[i]
      Vector[BitHourParity] := tmp//2        

      ' day in month
      tmp  := Days
      vector[BitDayMonth + 5] := tmp/20
      tmp := tmp//20      
      vector[BitDayMonth+4] := tmp/10
      tmp := tmp//10    
      vector[BitDayMonth+3] := tmp/8
      tmp := tmp//8
      vector[BitDayMonth+2] := tmp/4
      tmp := tmp//4
      vector[BitDayMonth+1] := tmp/2
      tmp := tmp//2
      vector[BitDayMonth] := tmp

      ' day in week

      tmp  := WeekDay
      vector[BitDayWeek+2] := tmp/4
      tmp := tmp//4
      vector[BitDayWeek+1] := tmp/2
      tmp := tmp//2
      vector[BitDayWeek] := tmp

      ' month
      tmp  := months
      vector[BitMonth+4] := tmp/10
      tmp := tmp//10    
      vector[BitMonth+3] := tmp/8
      tmp := tmp//8
      vector[BitMonth+2] := tmp/4
      tmp := tmp//4
      vector[BitMonth+1] := tmp/2
      tmp := tmp//2
      vector[BitMonth] := tmp

      ' year

      tmp  := years
      vector[BitYear + 7] := tmp/80
      tmp := tmp//80
      vector[BitYear + 6] := tmp/40
      tmp := tmp//40
      vector[BitYear + 5] := tmp/20
      tmp := tmp//20      
      vector[BitYear+4] := tmp/10
      tmp := tmp//10    
      vector[BitYear+3] := tmp/8
      tmp := tmp//8
      vector[BitYear+2] := tmp/4
      tmp := tmp//4
      vector[BitYear+1] := tmp/2
      tmp := tmp//2
      vector[BitYear] := tmp

      ' parity on last bundle

      tmp := 0
      repeat i from BitDayMonth to (BitParity-1)
        tmp := tmp + Vector[i]
      Vector[BitParity] := tmp//2   

    Vector[Bitstart] := One      ' always One
    Vector[BitTimeZone] := zero '
    Vector[BitTimeZone+1] := One ' always reverse of BitTimeZone1, shall be automatic in the future     
    Vector[Bit59] := Nothing
       
    case Vector[Seconds]
      One:     Sendone
      Zero:    SendZero
      Nothing: Sendnothing
               displaydate
      
    repeat while Seconds == RTC.ReadTimeReg(0)             'Wait until seconds changes

Pub SendOne       ' reduce HF signal amplitude for 0.2 second, 
    Outa[pinmod] := 1                                   ' set pinmod for LED, display etc. 
    psg.setdamplevel(damplevel)                         ' reduce HF amplitude
    waitcnt((clkfreq / 5) + cnt)                        ' wait 200 milliseconds
    psg.setdamplevel(0)                                 ' restore HF power
    Outa[pinmod] := 0                                   ' clear pin
    pst.char("1")                                       ' just for debug
 
Pub SendZero      ' same as above but for 100 milliseconds
    Outa[pinmod] := 1      
    psg.setdamplevel(damplevel)  
    waitcnt((clkfreq / 10) + cnt)
    psg.setdamplevel(0)
    Outa[pinmod] := 0  
    pst.char("0")
      
Pub SendNothing   ' do nothing except debug display
    pst.char("*")
    pst.newline

pub displaydate      
  'Spit out start of message to terminal
  pst.Str(String("Time:"))
  pst.Str(RTC.ReadStrTime)
  pst.Str(String("  ..  Date:"))
  pst.Str(RTC.ReadStrWeekday)
  pst.char(" ")
  pst.Str(RTC.ReadStrDate(0))  'parameter 0 means European date format 
     
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
}}          pst.newline