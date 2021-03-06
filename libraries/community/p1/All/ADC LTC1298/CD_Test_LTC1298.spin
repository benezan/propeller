{
********************************************
    Test LTC1298 Demo
********************************************
    Charlie Dixon (CDSystems) 2007 
********************************************
}
CON
  _CLKMODE = XTAL1 + PLL16X
  _XINFREQ = 5_000_000

  _stack = ($3000 + $3000 + 100) >> 2                   'accommodate display memory and stack

  x_tiles = 16
  y_tiles = 12

  x_screen = x_tiles << 4
  y_screen = y_tiles << 4

  width = 0             '0 = minimum
  x_scale = 1           '1 = minimum
  y_scale = 1           '1 = minimum
  x_spacing = 6         '6 = normal
  y_spacing = 13        '13 = normal

  x_chr = x_scale * x_spacing
  y_chr = y_scale * y_spacing

  y_offset = y_spacing / 6 + y_chr - 1

  x_limit = x_screen / (x_scale * x_spacing)
  y_limit = y_screen / (y_scale * y_spacing)
  y_max = y_limit - 1

  y_screen_bytes = y_screen << 2
  y_scroll = y_chr << 2
  y_scroll_longs = y_chr * y_max
  y_clear = y_scroll_longs << 2
  y_clear_longs = y_screen - y_scroll_longs

  paramcount = 14

  display_base = $5000
  bitmap_base = $2000

VAR

    long  tv_status     '0/1/2 = off/visible/invisible           read-only
    long  tv_enable     '0/? = off/on                            write-only
    long  tv_pins       '%ppmmm = pins                           write-only
    long  tv_mode       '%ccinp = chroma,interlace,ntsc/pal,swap write-only
    long  tv_screen     'pointer to screen (words)               write-only
    long  tv_colors     'pointer to colors (longs)               write-only               
    long  tv_hc         'horizontal cells                        write-only
    long  tv_vc         'vertical cells                          write-only
    long  tv_hx         'horizontal cell expansion               write-only
    long  tv_vx         'vertical cell expansion                 write-only
    long  tv_ho         'horizontal offset                       write-only
    long  tv_vo         'vertical offset                         write-only
    long  tv_broadcast  'broadcast frequency (Hz)                write-only
    long  tv_auralcog   'aural fm cog                            write-only

    word  screen[x_tiles * y_tiles]
    long  colors[64]
    long  x, y, cel, far     

OBJ
    tv    :     "TV"
    gr    :     "CD_Graphics"
    Num   :     "CD_Numbers"
    adc   :     "CD_LTC1298"
        
PUB MAIN | i,dx,dy,Temp

    'start tv
    longmove(@tv_status, @tvparams, paramcount)
    tv_screen := @screen
    tv_colors := @colors
    tv.start(@tv_status)

    'init colors
    repeat i from 0 to 63
      colors[i] := $00001010 * (9) & $F + $2B060C02   '$00001010 * (5+4) & $F + $2B060C02

    'init tile screen
    repeat dx from 0 to tv_hc - 1
      repeat dy from 0 to tv_vc - 1
        screen[dy * tv_hc + dx] := display_base >> 6 + dy + dx * tv_vc + ((dy & $3F) << 10)

   'start and setup graphics, LTC1298 ADC chip
    gr.start                                            'Start Graphics Driver
    gr.setup(16, 12, 128, 96, bitmap_base)
    adc.start(0)                                        'Initialize ADC chip

'**************************************************************************************************
' Main Program Loop to get and display ADC data to TV Screen
'**************************************************************************************************

    repeat
      gr.clear                                        'Num.ToStr(Temp, Num#DEC)
      gr.colorwidth(1, 2)                             'Resolution = 5.00V / 4096 = 0.00122
      gr.textmode(1,1,7,%0000)                         
      Temp := adc.GetADC(0)                           
      gr.text(-128,80,string("ADC Channel 0: "))
      gr.text(-25,80,Num.ToStr(Temp, Num#BIN))
      gr.text(-128,65,string("ADC Channel 0: "))
      gr.text(-25,65,Num.ToStr(Temp, Num#DEC))
      Temp := adc.GetADC(1) 
      gr.text(-128,50,string("ADC Channel 1: "))
      gr.text(-25,50,Num.ToStr(Temp, Num#BIN))
      gr.text(-128,35,string("ADC Channel 1: "))
      gr.text(-25,35,Num.ToStr(Temp, Num#DEC))
      gr.copy(display_base)

DAT

Zero                    word    $30
DP                      word    $2E
Hyphen                  word    $2D

tvparams                long    0               'status
                        long    1               'enable
                        long    %001_0101       'pins
                        long    %0000           'mode
                        long    0               'screen
                        long    0               'colors
                        long    x_tiles         'hc
                        long    y_tiles         'vc
                        long    10              'hx
                        long    1               'vx
                        long    0               'ho
                        long    0               'vo
                        long    0               'broadcast
                        long    0               'auralcog

color_schemes           long    $BC_6C_05_02
                        long    $0E_0D_0C_0A
                        long    $6E_6D_6C_6A
                        long    $BE_BD_BC_BA
DAT
     {<end of object code>}
     
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