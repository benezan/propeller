' Keyboard: gamepad_drv_001     'A simple tool that seemed to be needed.
' AUTHOR: Jeff Ledger
' With thanks to Desilva and Baggers for help getting this to work.
'
' ┌───────────────────────────────────────────┐
' │Keyboard Arrows                            │
' │    ┌──┐                                   │
' │ ┌──┘  └──┐                     B  space   │
' │ └──┐  ┌──┘       [ S ] [ Cr]   O   O      │
' │    └──┘         select start   b   a      │
' └───────────────────────────────────────────┘
'
'
OBJ
  key   : "Keyboard"             ' Keyboard Driver
     
PUB start : okay

  key.start(26, 27)   

PUB stop

PUB read : joy_bits | keystroke

' NES bit encodings -- Provided as reference
'  NES_RIGHT  = %00000001
'  NES_LEFT   = %00000010
'  NES_DOWN   = %00000100
'  NES_UP     = %00001000
'  NES_START  = %00010000
'  NES_SELECT = %00100000
'  NES_B      = %01000000
'  NES_A      = %10000000
  
  joy_bits := %00000000
  
  if (key.keystate(" "))         'Keyboard(SPACE) = A
      joy_bits := %10000000

  if (key.keystate("b"))         'Keyboard(X) = B
      joy_bits := %01000000

  if (key.keystate("s"))         'Keyboard(S) = Select
      joy_bits := %00100000

  if(key.keystate($0D))          'Keyboard(ENTER) = Start
      joy_bits := %00010000     
  
  if(key.keystate($C1))          'Right Arrow on Keyboard
     joy_bits := %00000001

  if(key.keystate($C0))          'Left Arrow on Keyboard
     joy_bits := %00000010

  if(key.keystate($C3))          'Down Arrow on Keyboard
     joy_bits := %00000100

  if(key.keystate($C2))          'Up Arrow on Keyboard
     joy_bits := %00001000


PUB button(WhichOne)
{{ Return value:     true or false                                          }}
  if WhichOne == read
    return true
  else
    return false