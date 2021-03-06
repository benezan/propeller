{{ filter_rc4_asm.spin
┌─────────────────────────────────────┬────────────────┬─────────────────────┬───────────────┐
│ IIR Recursive Filter (Integer) v0.1 │ BR             │ (C)2009             │  18 Oct 2009  │
├─────────────────────────────────────┴────────────────┴─────────────────────┴───────────────┤
│ Infinite Implulse Response (IIR) Recursive filter, implemented in pasm, with recursion.    │
│                                                                                            │
│ Recommended reading if you want to understand how this filter works: www.dspguide.com      │
│ Chapter 19.                                                                                │
│                                                                                            │
│ y(i)= a0*x(i) + a1*x(i-1) + a2*x(i-2) + a3*x(i-3) + a4*x(i-4)  + ..                        │
│           ... + b1*y(i-1) + b2*y(i-2) + b3*y(i-3) + b4*y(i-4)                              │
│ ai, bi = filter coefficients                                                               │
│ x(i) = filter input at timestep i                                                          │
│ y(i) = filter output at timestip i                                                         │
│                                                                                            │
│ USAGE: starts a cog which continuously polls a memory location looking for a data value    │
│        (negx, $8000_000 is assumed to be "no data", filter cog will ignore).  When a data  │
│        value is detected, cog processes data sample and places the filtered output into    │
│        the next location in hub memory.  Thus, filter in and out MUST be adjacent longs in │
│        hub memory.  This was done to facilitate chaining several filters together, and     │
│        also for simplicity.                                                                │
│                                                                                            │
│ NOTES:                                                                                     │
│ •The design objective for this filter was to make it as fast as possible.  This filter     │
│  is capable of 180K samples/sec @ 80 MHz with a simple high or low pass filter. However,   │
│  throughput will vary considerably depending on the particular filter implemented (40K     │
│  samples/sec is a typical figure for the more complicated filters like fslp).  This        │
│  is because: a) the filter will skip the multiplication step for any filter coefficient    │
│  that is zero, so the number of coefficients used impacts throughput, and b) the Kenyan    │
│  multiplicaiton routine is used for speed but has the down side that the exact number of   │
│  cycles needed to complete the multiply is dependent on the numbers being multiplied.      │
│ •This demo provides a timer to enable easy measurement of typical filter throughput to     │
│  give the user an idea of what performance might be attainable from a particular set of    │
│  filter coefficients.                                                                      │
│ •This filter provides no overflow detection, it is up to the user to be sure that the      │
│  data input values and the filter coefficient normalization are reasonable.                │
│                                                                                            │
│ See end of file for terms of use.                                                          │
└────────────────────────────────────────────────────────────────────────────────────────────┘
}}
'FIXME: provide some means of autoscaling the input or,
'FIXME: add integer overflow/underflow detection...
'FIXME: add support for 64 bit integer in accumulator

VAR
  byte cog


PUB start( _inPtr )
''starts 4-element recursive IIR filter in a cog.
''Usage: filter.start(input_ptr)
''Args:  _inPtr = pointer to hub memory location containing input data
''       filter will return its output in the in next long of hub memory

  stop
  cog := cognew( @entry, _inPtr ) + 1
  return cog


PUB stop
  if cog
    cogstop( cog~ - 1 )  


pub synth_low_pass(x,_normExp)|inorm
''Synthesizes a single pole low-pass filter for use with recurse4.
''Input argument x, is the amount of decay between adjacent filter samples.
'It is related to the time constant of the filter as: x = exp(-1/d) where d
'the number of samples for the filter to decay to 38.6% of its steady state
'value.   In other words, d is the DSP equivalent of RC in an RC circuit.
'x is related to filter cutoff frequency as: x= exp(-2π*fc), fc = cutoff freq.
'expressed as a fraction of sampling frequency, where 0 <= fc <= 0.5.
'Input argument _normExp is a scaling coefficient.  If this filter were
'implemented using floatmath, x would normally be limited to 0 <= x <= 1.
'_normExp scales x such that it is expressed as a fraction of 2^_normExp.
'For example, x= 64, _normExp=7 implies an effective x of 0.5.
'See www.dspguide.com, chapter 19 for more info.
'
'Typical values for a single pole low pass filter:
'# samples per   │  damping, │  (inorm=255)
'time constant   │  exp(-1/d)│    x      b1     a0
'       1        │   0.368   │   94      94    161
'       2        │   0.607   │  155     155    100
'       4        │   0.779   │  199     199     56
'       8        │   0.882   │  225     225     30
'      16        │   0.939   │  240     240     15
'      24        │   0.959   │  245     245     10
'      32        │   0.969   │  247     247      8
'
'The analog equivalent of this filter is:
'        filt_in ─────┳──── filt_out
'                   R     C
'                        

  normExp := 6 #> _normExp <# 16
  inorm := |< normExp -1
  b[0] := x
  a[0] := inorm - x
  b[1] := b[2] := b[3] := 0
  a[1] := a[2] := a[3] := 0
  return @a

                                   
pub synth_high_pass(x,_normExp)|inorm
''Synthesizes a single pole high-pass filter for use with recurse4.
''Input argument x, is the amount of decay between adjacent filter samples.
'The analog equivalent of this filter is:
'        filt_in ─────┳──── filt_out
'                   C    R
'                       
'See synth_low_pass for more info.

  normExp := 6 #> _normExp <# 16        
  inorm := |< normExp -1
  b[0] := x
  a[0] := (inorm + x) / 2
  a[1] := -a[0]
  b[1] := b[2] := b[3] := 0
  a[2] := a[3] := 0
  return @a

                                   
pub synth_band_stop(x,_normExp, f, bw)|dum1,dum2,inorm
''Synthesizes a band-stop filter for use with recurse4.  x, is the amount of decay
''between adjacent filter samples, where typically 0 <= x <= 1 in floatmath. f is
''band stop center frequency, bw is band stop bandwidth. f, and bw are all relative 
''to the sampling frequency, fs, and therefore 0 <= f,bw <= 0.5. inorm is a       
''scaling parameter on x, f, and bw. E.G. for x = 0.5, use x = 50 and inorm = 100.
''To get f = 0.25*fs, use f=25.  For bw=0.1*fs, use bw=10, etc.         
'See www.dspguide.com, chapter 19 for more info.

  normExp := 6 #> _normExp <# 16        
  inorm := |< normExp -1
  dum1 := inorm - 3 * bw
  dum2 := inorm * inorm - 2 * dum1 * cos(360*f/inorm, inorm) + dum1 * dum1
  dum2 /= (2 * inorm - 2 * cos(360*f/inorm, inorm))
  a[0] := dum2 * inorm
  a[1] := -2 * dum2 * cos(360*f/inorm, inorm)
  a[2] := dum2 * inorm
  a[3] := 0
  b[0] := 2 * dum1 * cos(360*f/inorm, inorm)
  b[1] := -dum1 * dum1
  b[2] := b[3] := 0
  normExp *= 2
   return @a


pub synth_band_pass(x,_normExp, f, bw)|dum1,dum2,inorm
''Synthesizes a band-pass filter for use with recurse4.  x, is the amount of decay
''between adjacent filter samples, where typically 0 <= x <= 1 in floatmath. f is
''band pass center frequency, bw is band pass bandwidth. f, and bw are all relative 
''to the sampling frequency, fs, and therefore 0 <= f,bw <= 0.5. inorm is a       
''scaling parameter on x, f, and bw. E.G. for x = 0.5, use x = 50 and inorm = 100.
''To get f = 0.25*fs, use f=25.  For bw=0.1*fs, use bw=10, etc.         
'See www.dspguide.com, chapter 19 for more info.

  normExp := 6 #> _normExp <# 16        
  inorm := |< normExp -1
  dum1 := inorm - 3 * bw
  dum2 := inorm * inorm - 2 * dum1 * cos(360*f/inorm, inorm) + dum1 * dum1
  dum2 /= (2 * inorm - 2 * cos(360*f/inorm, inorm))
  a[0] := (inorm - dum2) * inorm
  a[1] := 2 * (dum2 - dum1) * cos(360*f/inorm, inorm)
  a[2] := dum1 * dum1 - dum2 * inorm
  a[3] := 0
  b[0] := 2 * dum1 * cos(360*f/inorm, inorm)
  b[1] := -dum1 * dum1
  b[2] := b[3] := 0
  normExp *= 2
  return @a


pub synth_fslp(x,_normExp)|inorm
''Synthesizes a four stage low-pass filter for use with recurse4.
''Input argument x, is the amount of decay between adjacent filter samples.
'See synth_low_pass for more info.
'FIXME: this filter is very sensitive to startup transients and also seems
'to be prone to instability for values of x/inorm > 0.4 or so.
'Probably better if implemented using floatmath.

  normExp := 6 #> _normExp <# 16        
  inorm := |< normExp -1
  b[0] := 4 * x * inorm * inorm * inorm
  b[1] := -6 * x * x * inorm * inorm
  b[2] := 4 * x * x * x * inorm
  b[3] := -x * x * x * x
  a[0] := (inorm - x) * (inorm - x) * (inorm - x) * (inorm - x)
  a[1] := a[2] := a[3] := 0
  normExp *= 4
  return @a


pub set_kernel(kern_ptr)
''Moves filter kernel coefficients into the filter object dat space.
''Input arg is pointer to filter coefficients.  This object expects
''filter coeffs to be packed in a block of longs as such:
'' a0,a1,a2,a3,b1,b2,b3,b4

  longmove(@a,kern_ptr,16)


pub set_normExp(userValue)
''Sets filter kernel normalization value (poor man's fixed point math)
''Input is a power of 2 (e.g., normExp=8 -> all filter coefficients norm'd by 255)

  normExp := userValue
  

PUB sin(degree, mag) : s | c,z,angle
''Returns scaled sine of an angle: rtn = mag * sin(degree)
'Function courtesy of forum member Ariba
'http://forums.parallax.com/forums/default.aspx?f=25&m=268690

  angle //= 360
  angle := (degree*91)~>2 ' *22.75
  c := angle & $800
  z := angle & $1000
  if c
    angle := -angle
  angle |= $E000>>1
  angle <<= 1
  s := word[angle]
  if z
    s := -s
  return (s*mag)~>16       ' return sin = -range..+range


pub cos(degree, mag) : s
''Returns scaled cosine of an angle: rtn = mag * cos(degree)

  return sin(degree+90,mag)

  
DAT
'--------------------------
'4-element recursive IIR filter
'--------------------------
           org        
entry      mov     inPtr,par               'get pointer for filter data input location
           mov     outPtr,par              'set pointer for filter data output location
           add     outPtr,#4               '(output assumed to be next long in hub memory) 
           call    #finit                  'initialize filter
'--------------------------                                                                        
'on entry: raw data is in hub memory location par
'on exit: filtered data is in par+4
'--------------------------      
top        mov     acum,#0                 'zero accumulator
           mov     arg1,a1
           mov     arg2,x1
a1x1       call    #mac16                  'a1*x1
           mov     arg1,a2
           mov     arg2,x2
a2x2       call    #mac16                  'a2*x2
           mov     arg1,a3
           mov     arg2,x3
a3x3       call    #mac16                  'a3*x3
           mov     arg1,b1
           mov     arg2,y1
b1y1       call    #mac16                  'b1*y1
           mov     arg1,b2
           mov     arg2,y2
b2y2       call    #mac16                  'b2*y2
           mov     arg1,b3
           mov     arg2,y3
b3y3       call    #mac16                  'b3*y3
           mov     arg1,b4
           mov     arg2,y4
b4y4       call    #mac16                  'b4*y4

           mov     y4,y3                   'update x-buffer, y-buffer
           mov     y3,y2                   
           mov     y2,y1
           mov     x3,x2
           mov     x2,x1
           mov     x1,x0
           wrlong  nul,inPtr               'zero input register (ready for next data) 
           
loop       rdlong  x0,inPtr                'get new filter data input        
           cmps    x0,nul       wz         'check for nul input
      if_z jmp     #loop                   'if nul, disregard...loop back       
           mov     arg1,a0
           mov     arg2,x0
           call    #mac16                  'a0*x0

           sar     acum,normExp            'divide by 2^n to remove normalization-->y1 
           wrlong  acum,outPtr             'write filtered data to hub memory        
           mov     y1,acum
'          wrlong  nul,inPtr               'zero input register (ready for next data)
           jmp     #top                    'play it again, Sam                   

'--------------------------                                                                          
'Kenyan multiplication routine (code courtesy of Cessnapilot)
'http://forums.parallax.com/forums/default.aspx?f=25&m=372582
'modified to accumulate result into acum
'--------------------------
mac16      cmp     arg1,arg2 wc            'If arg1 is less than arg2 C is set
      if_c xor     arg1,arg2               'Swap arguments
      if_c xor     arg2,arg1
      if_c xor     arg1,arg2
'Start Kenyan multiplication
           mov     r1,#0                   'Clear 32-bit product
:loop      shr     arg2,#1 wc,wz           'Half multiplyer and get LSB of it
      if_c add     r1,arg1                 'Add multiplicand to product on C
           shl     arg1,#1                 'Double multiplicand
     if_nz jmp     #:loop                  'Check nonzero multiplier to continue mult
           adds    acum,r1                 'add result to accumulator
mac16_ret ret                                                                                                                  
'--------------------------                                                              
'filter initialization routine
'--------------------------                                                                            
finit
           movd    :loop,#arg1             'zero buffer registers
           mov     indx,#4
:loop      mov     0-0,#0
           add     :loop,t1
           djnz    indx,#:loop             
           cmp     a1,#0   wz              'convert any multiplication call having   
      if_z mov     a1x1,#0                 'a zero coefficient into a nop
           cmp     a2,#0   wz
      if_z mov     a2x2,#0
           cmp     a3,#0   wz
      if_z mov     a3x3,#0
           cmp     b1,#0   wz
      if_z mov     b1y1,#0
           cmp     b2,#0   wz
      if_z mov     b2y2,#0
           cmp     b3,#0   wz
      if_z mov     b3y3,#0
           cmp     b4,#0   wz
      if_z mov     b4y4,#0
finit_ret  ret
'--------------------------                                                                            
'initialized data
'--------------------------                                                                           
a                                          'filter x-coefficients a[0], a[1],...         
a0         long    0                       
a1         long    0
a2         long    0
a3         long    0
b                                          'filter y-coefficients b[1], b[2],...        
b1         long    0                       
b2         long    0
b3         long    0
b4         long    0
normExp    long    0
x_buf
x0         long    0                       'filter input history buffer
x1         long    0
x2         long    0
x3         long    0
y_buf
y1         long    0                       'filter output history buffer          
y2         long    0
y3         long    0
y4         long    0
t1         long    1 << 9
nul        long    negx
'uninitialized data
arg1       res     1                       'mult input arg 1
arg2       res     1                       'mult input arg 2
r1         res     1                       'mult result
acum       res     1                       'accumulator
indx       res     1                       'offset used for initialization
inPtr      res     1                       'filter data input location
outPtr     res     1                       'filter data output location

fit 496


DAT

{{

┌─────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                     TERMS OF USE: MIT License                                       │                                                            
├─────────────────────────────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy of this software and    │
│associated documentation files (the "Software"), to deal in the Software without restriction,        │
│including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,│
│and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so,│
│subject to the following conditions:                                                                 │
│                                                                                                     │                        │
│The above copyright notice and this permission notice shall be included in all copies or substantial │
│portions of the Software.                                                                            │
│                                                                                                     │                        │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT│
│LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  │
│IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER         │
│LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION│
│WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                                      │
└─────────────────────────────────────────────────────────────────────────────────────────────────────┘
}}  