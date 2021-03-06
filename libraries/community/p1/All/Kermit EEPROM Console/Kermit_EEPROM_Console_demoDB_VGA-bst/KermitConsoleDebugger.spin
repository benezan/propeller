{{

┌──────────────────────────────────────────┐
│ KermitConsoleDebugger 1.0                │
│ Object for debugging Kermit file         │
│ receiving object                         │
│ Author: Eric Ratliff                     │               
│ Copyright (c) 2009 Eric Ratliff          │               
│ See end of file for terms of use.        │                
└──────────────────────────────────────────┘

KermitConsoleDebugger.spin, compainon object to Kermit file receiver/cosole/serial driver object
by Eric Ratliff
2009.5.25 from 'receiver' now 'console', expecting changes needed due to different companion object
}}
CON
  NumBytesInLongLog = Monitor#NumBytesInLongLog ' quantity of bytes in a long as power of 2

  ' limits and locations of display areas on screen------------------------------------------------------------------
  InputDisplaySizeLong = 504        ' how many longs we want to show, can be up to 512 for screen's limitations,  Use 504 to leave 1 line available
  GeneralLiveVarsBeginLine = 0  ' index in variable array to have general debugging variables at
  GeneralLiveVarsBeginLong = GeneralLiveVarsBeginLine * Monitor#VarsPerRow ' index in variable array to have general debugging variables at
  NumGeneralLiveVars = 32       ' quantity limit of general live variables
  ' have 'all input' area follow the general live variables area
  AllInputBeginLine = ((GeneralLiveVarsBeginLong + NumGeneralLiveVars - 1)/Monitor#VarsPerRow) + 1
  AllInputBeginLong = AllInputBeginLine * Monitor#VarsPerRow
  AllInputBeginByte = AllInputBeginLong << NumBytesInLongLog
  NumAllInputLong = 79          ' actual quantity of characters showable is four time this
  AllInputEndLong = AllInputBeginLong + NumAllInputLong - 1
  ' have packet diagnostics area follow the 'all input' area, calculated visually
  PacktDiagBeginLong = 128
  PacktDiagBeginByte = PacktDiagBeginLong << NumBytesInLongLog
  PacktDiagBeginLine = PacktDiagBeginLong/Monitor#VarsPerRow
  NumPacktDiagLines = 16        ' how many lines of packet analyisis diagnostics to show
  ' have one blank line between packet diagnostics and display of packets, calculated visually
  PacketsBeginLong = 256
  PacketsBeginLine = PacketsBeginLong/Monitor#VarsPerRow
  NumPacketLines = 10           ' leave two blank lines before error log area
  ' have error log at top of a band on screen, following packets display, calculated visually
  ErrorLogBeginLong = 352       ' where to post incoming packet error log on screen
  ErrorLogBeginLine = ErrorLogBeginLong/Monitor#VarsPerRow
  ' we stuff file length display into the error log band
  DFL_IndexLong = ErrorLogBeginLong+22 ' where to display declared file length (long offsets from start of display array)
  MFL_IndexLong = DFL_IndexLong + 1 ' where to display measured file length (long offsets from start of display array)
  ' have file data bands follow the error log band, calculated visually
  FileDataBeginLong = 384       ' where to show just file contents
  FileDataBeginLine = FileDataBeginLong/Monitor#VarsPerRow
  LongsInBand = Monitor#VarsPerRow * Monitor#RowsPerBand
  NumFileDataBands = 4          ' how many bands of data packtest to show
  RightMarginStartCol = 115     ' where we can write at right of screen
  LastLineBeginLong = 504       ' last line of screen, not part of display body, i.e. the bottom margin for a label
  TitleLabelBeginColumn = 30    ' where bottom label begins on screen
  FileNameColumn = 9            ' where to show file name

  ' error codes
  ' serial object's error code
  SerialDriverTimeout = -1      ' this must match timeout return value of rxcheck in FullDuplexSerial
  ' this program's character get routine error code
  CharacterTimeoutError = SerialDriverTimeout    ' got no character while waiting for one

  MinPacketLength = 3           ' Kermit minimum packet length for sequence, type, and checksum
  MaxPacketLength = 96          ' Kermit max packet length
  'MinSeqNum = 0                ' Kermit minimum packet length for sequence, type, and checksum
  'MaxSeqNum = 99               ' Kermit max packet length
  'BadSeqNum = -4               ' extracted sequence number is out of Kermit limits
  TimeoutIndex = 5              ' where in send init and init ack the timeout parameter is
  MARK = 1                      ' character that begins a Kermit packet
  EOL = $d                      ' expect carrige return as end of line character
  NULL = 0                      ' string terminator
  FLD_index = 8                 ' file length digit count index in file attributes packet
  FL_index = FLD_index + 1      ' file length first character index in file attributes packet

  

  ' packet types
  SendInitiate_type = $53       ' Send Initiate Kermit type, S
  FileHeader_type = $46         ' File Header Kermit type, F
  FileAttributes_type = $41     ' File Header Kermit type, A
  Data_type = $44               ' Data Kermit type, D
  EndOfFile_type = $5A          ' End of file Kermit type, Z
  BreakTransmission_type = $42  ' Break Transmission Kermit type, B
  
  RemainderMask = (1 << NumBytesInLongLog)-1                          ' one less than the number of bytes in a long
  DEL = $FF                     ' delete character, is special case of quoted characters, a non 'control' character
  MaxShowableInBand = 32 * 4    ' limit of string to have in VGA color band, used to prevent repeat char overrun on screen
  InitSeqNumber = 0             ' sequence number expected for a send init packet
  MaxErrors = 5                 ' when to give up and go back to looking for init packet
  AscciiZero = $30              ' ascii code for the character "0"
  
  ' state types
  WaitingForInit = 0
  GotInit = 1

  AsciiDoubleQuote = $22        ' hex for ASCII double quote

  ' special debugging for data not coming from PC, so I can see it in serial port monitor (2009.5.31 now programming from Mac, so this makes less sense)
  EchoRawInput = false          ' to echo all input to a serial port
  EchoDataPacketsOnly = true    ' for selective echo
  FileNameBufferSize = 40

OBJ
  KDefs : "KermitConsoleDefs" ' sort of an include file
  ' starts a 2 cog driver that runs VGA output signal and has large in hub ram font definition, can run a 3rd cog to update display
  Monitor :     "MonVarsVGA"
  RxBufMonitor : "SerialMonitorNarrow" ' constantly checks fullness of serial input buffer
  KermitConsole : "Kermit EEPROM Console" ' for access to file info routine, might eliminate need for defs file too
  nums : "Numbers" ' formats numerical output to ASCII
  'DebugSerialDriver : "SerialMirror"                    ' for second serial port

VAR
  long pMonArray                     ' pointer to variables that will be monitored for changes
  long MonitorCogCode

  ' simple pointers
  ' from receive structure
  'long pDebug                  ' simple pointer to the debug structure
  'long pFileNameBuffer          ' location of file name buffer
  ' from debug structure
  long pPacket                  ' ptr to incoming packet buffer, not null terminated

  
  long PacketIndex              ' what packet are we showing? 0 based
  long PacketInputIndex         ' index of last byte in the packet
  long AllInputByteCount        ' how many bytes have arrived
  long ThisDataPacketBeginLong  ' current data packet's display offset, a long index to screen
  long ThisBandEndLong          ' current data packet's display long index limit
  long FileDataIndexByte        ' byte index of currrent file data byte in the whole screen
  long DataPacketIndex          ' zero based index of incoming data packets
  long SB_MonitorCogCode        ' result of trying to start a cog to monitor the serial buffer usage
  long pTitleStartString        ' pointer to first part of title label string
  long WaitingForFirstPacket    ' flag to see when we can display program version number, means that receiver has started and posted its version
  long FileNameDisplayed        ' flag record fact we displayed the file name
  long FileLengthDisplayed      ' flag to record fact we displayed the declared file length

{  ' debug serial port variables, for echoing input from ZTerm running on Mac
  long DBrxPin ' where Propeller chip receives data
  long DBtxPin ' where Propeller chip outputs data
  long DBSerialMode ' bit 0: invert rx, bit 1 invert tx, bit 2 open-drain source tx, ignore tx echo on rx
  ' individual components of mode
  long DBInvertRx
  long DBInvertTx
  long DBOpenDrainSourctTx
  long DBIgnoreTxEchoOnRx
  long DBbaud ' (bits/second)
  long DegugPortStart           ' result of trying to start another serial driver
  long EchoIndex                ' for copying binary array to debug port
}
  long DeclaredLengthNotShown   ' flag to show we did not show a declared file length
  long LastPacketMFL            ' Measured File Length at last packet
  long PresentMFL               ' Measured File Length at this packet
  long DeclaredFileLength
  long NeedToStartSerialMonitor ' flag to show we attempted to start the serial input buffer space remaining monitor cog
  long DebugStruct[KDefs#KDB_Size] ' where console object will exchange debugging data
  long FileNameBuffer[FileNameBufferSize]

'PUB Start(pMonArray,EchoRawInput):pDebug | NewStringLength, VGA_result, VK_MonitorCogCode ' may add this back later, with conditional use of VGA
PUB Start(pMonArrayParam):pDebug | NewStringLength, VGA_result, VK_MonitorCogCode
'' starts a cog that displays debug information and keeps varibles updated
  Stop  ' do not allow more than one instance of this object

  pMonArray := pMonArrayParam
  Monitor.PreBlankVariables(pMonArray,0,InputDisplaySizeLong-1)                     ' inhibit opening paint of numbers
  FileNameDisplayed := false
  FileLengthDisplayed := false
  FileDataIndexByte := FileDataBeginLong << NumBytesInLongLog ' set output display index to its beginning
  ' start VGA driver and prepare the video screen with same character formatting that is used by "UHexStart" of the monitor object
  if Monitor.VGA_OnlyStart(Monitor#DevBoardVGABasePin,pMonArray,InputDisplaySizeLong,Monitor#uhexFormat,Monitor#uhexSignness)
    pDebug := @DebugStruct
    WaitingForFirstPacket := true ' waiting for first packet result
    ' annotate in display margins, these only need doing once because they are never cleared
    Monitor.LiveString(STRING("general vars"),RightMarginStartCol,GeneralLiveVarsBeginLine)
    Monitor.LiveString(STRING("all input"),RightMarginStartCol,AllInputBeginLine)
    Monitor.LiveString(STRING("packet diag"),RightMarginStartCol,PacktDiagBeginLine)
    Monitor.LiveString(STRING("packets"),RightMarginStartCol,PacketsBeginLine)
    Monitor.LiveString(STRING("packet"),RightMarginStartCol,ErrorLogBeginLine)
    Monitor.LiveString(STRING("err codes"),RightMarginStartCol,ErrorLogBeginLine+1)
    Monitor.LiveString(STRING("file data"),RightMarginStartCol,FileDataBeginLine)
    pTitleStartString := STRING("Kermit Console Debugger, 2009.7.25 version, tested object version ")
    Monitor.LiveString(pTitleStartString,TitleLabelBeginColumn,LastLineBeginLong>>3)
    ' version number is not ready yet here
    'Monitor.LiveString(nums.ToStr(LONG[pDebug][KDefs#KDB_KR_VersionNumber],nums#DEC),TitleLabelBeginColumn+STRSIZE(pTitleStartString),LastLineBeginLong>>3)
{    if EchoRawInput           ' are we sending all input from the XBee to the USB port?  for debugging ZTerm receiving
      ' these are for the USB port
      DBrxPin := 31
      DBtxPin := 30
      DBInvertRx := FALSE ' (does not matter, this program only transmits)
      DBInvertTx := FALSE ' (must be FALSE)
      DBOpenDrainSourctTx := TRUE ' I'm guessing this is for half duplex, such as 2 wire RS-485 (does not matter)
      DBIgnoreTxEchoOnRx := FALSE ' I'm guessing this is for half duplex, such as 2 wire RS-485 ( surprise, must be FALSE for transmit to work)
      DBSerialMode := (%1 & DBInvertRx)
      DBSerialMode |= (%10 & DBInvertTx)
      DBSerialMode |= (%100 & DBOpenDrainSourctTx)
      DBSerialMode |= (%1000 & DBIgnoreTxEchoOnRx)
      DBbaud := 115200
      DegugPortStart := DebugSerialDriver.start(DBrxpin, DBtxpin, DBSerialMode, DBbaud)
}
    PacketErrorLogPrep
    SetupForInitPacket
    NeedToStartSerialMonitor := true ' we did not try yet, and don't try here because the Kermit monitor has not started yet

    ' signal that the debugger cog has started
    DebugStruct[KDefs#KDB_DebuggerStarted] := true
  else
    pDebug := 0 ' signal that we don't have debugging and don't have a VGA driver

PUB Stop
  Monitor.Stop  ' stop any VGA driver cogs running
  if SB_MonitorCogCode
    cogstop(SB_MonitorCogCode-1)
    SB_MonitorCogCode := 0

PUB UpdateDisplay|TryingToGetFileData,NewChar,PacketErrorCode,PrefixLength,FileNameLength
' display File Data and Packet Results if available
' public to allow cog conservation
' call this from main (demo program) after processing Kermit or console input

  'if DebugStruct[KDefs#KDB_ExtrSequenceNumber] == 1                   ' get the extracted sequence number, 2 allows mark, 1 prevents mark
  '  repeat ' hang here
  if DebugStruct[KDefs#KDB_ShowPacketResults] or DebugStruct[KDefs#KDB_ShowInput] or DebugStruct[KDefs#KDB_FileDataCount]
    'if DebugStruct[KDefs#KDB_ExtrSequenceNumber] == 27                   ' get the extracted sequence number
    '  repeat ' hang here
    if DebugStruct[KDefs#KDB_ClearBeforeShowing]
      'repeat ' hang here, preserves screen instead of clearing it
      ' clear the screen and generally reset
      ' set up variable array and internal reference values to not repaint screen by assigning an 'unlikely value' to them
      ' start only after the 'general variables' area at the top of the screen
      Monitor.PreBlankVariables(pMonArray,AllInputBeginLong,InputDisplaySizeLong-1)
      Monitor.LiveBlankScreen(AllInputBeginLong,InputDisplaySizeLong-1) ' remove some old numbers and labels from display
      FileNameDisplayed := false
      FileLengthDisplayed := false
      PacketErrorLogPrep
      SetupForInitPacket
      AllInputByteCount := 0
      FileDataIndexByte := FileDataBeginLong << NumBytesInLongLog ' set output display index back to its beginning

  ' show any decoded data
  if DebugStruct[KDefs#KDB_FileDataCount]
    ' show the string, but don't consume it because: 1. we don't have lock, 2. sender will mark it consumed after return, we get one synced chance only
    Monitor.SafePutMeasuredFrontierString(pMonArray,InputDisplaySizeLong,FileDataIndexByte,DebugStruct[KDefs#KDB_pFileOutput],DebugStruct[KDefs#KDB_FileDataCount]) 
    FileDataIndexByte += DebugStruct[KDefs#KDB_FileDataCount]
    ' more frequent reporting of measured file size
    PresentMFL := DebugStruct[KDefs#KDB_MeasuredFileLength]
    LONG[pMonArray][MFL_IndexLong] := PresentMFL ' copy measured file length to debugging display area

  ' is there input to the receiver that we can show?
  if DebugStruct[KDefs#KDB_ShowInput] 
    if not pPacket
      ' establish simple pointer to the packet input buffer
      pPacket := DebugStruct[KDefs#KDB_pPacket]
    PacketInputIndex := DebugStruct[KDefs#KDB_PacketInputIndex]
    ' post packet buffer to 'all input' area
    Monitor.SafePutMeasuredFrontierString(pMonArray,AllInputEndLong+1,AllInputByteCount+AllInputBeginByte,pPacket,PacketInputIndex)
    AllInputByteCount += PacketInputIndex
  'if DebugStruct[KDefs#KDB_ExtrSequenceNumber] == 27  ' get the extracted sequence number, 1 means file header is finished and gets no mark here
  '  repeat ' hang here

  ' check packet received & processed flag
  if DebugStruct[KDefs#KDB_ShowPacketResults]
    PacketErrorCode := DebugStruct[KDefs#KDB_PacketErrorCode]
    PacketInputIndex := DebugStruct[KDefs#KDB_PacketInputIndex]

    ' handle packet result
    ReportParseDiagnostics(PacketErrorCode)
    'if DebugStruct[KDefs#KDB_ExtrSequenceNumber] == 1  ' 1 prevents mark here
    '  repeat ' hang here
    case DebugStruct[KDefs#KDB_PakType] ' branch depending on packet type
      SendInitiate_type :                       ' not expected type
        ' do nothing
      Data_type :
        ' is this an 'early' data packet, indicating no file attributes packet will have been received?
        if DeclaredLengthNotShown
          ' did we get a declared file length?
          KermitConsole.GetFileAttributes(@FileNameBuffer,FileNameBufferSize,@DeclaredFileLength)
          if DeclaredFileLength <> KDefs#NoFileLength
            LONG[pMonArray][DFL_IndexLong] := DeclaredFileLength ' copy declared file length to debugging display area
            DeclaredLengthNotShown := false
        PresentMFL := DebugStruct[KDefs#KDB_MeasuredFileLength]
        LONG[pMonArray][MFL_IndexLong] := PresentMFL ' copy measured file length to debugging display area
      FileHeader_type :
        'if DebugStruct[KDefs#KDB_ExtrSequenceNumber] == 1  ' 1 gets mark here, now quit qetting mark here, 2 now getting mark here
        '  repeat ' hang here
        PresentMFL := DebugStruct[KDefs#KDB_MeasuredFileLength]
        LONG[pMonArray][MFL_IndexLong] := PresentMFL ' initialize measured file length display
        PrefixLength := Monitor.LiveString(STRING("file name: ",AsciiDoubleQuote),FileNameColumn,ErrorLogBeginLine+3) ' label and open quote
        'if DebugStruct[KDefs#KDB_ExtrSequenceNumber] == 1  ' 1 prevents mark here
        '  repeat ' hang here
        ' file name, we don't expect to succeed in getting size here
        KermitConsole.GetFileAttributes(@FileNameBuffer,FileNameBufferSize,@DeclaredFileLength)
        FileNameLength := Monitor.LiveString(@FileNameBuffer,FileNameColumn+PrefixLength,ErrorLogBeginLine+3)
        'if DebugStruct[KDefs#KDB_ExtrSequenceNumber] == 17  ' 1 gets mark here
        '  repeat ' hang here
        Monitor.LiveString(STRING(AsciiDoubleQuote),FileNameColumn+PrefixLength+FileNameLength,ErrorLogBeginLine+3) ' close quote
        Monitor.Redline(ErrorLogBeginLine+3)              ' blank line index and make foreground 75% red
        Monitor.RowForegroundColor(ErrorLogBeginLine+3,3,0,0)                     ' make foreground 100% red
        ' find where to put show first file data string, each new one goes in another band on VGA monitor, also inc the index
        DataPacketIndex := 0
        LastPacketMFL := PresentMFL
      FileAttributes_type :
        ' did we get a declared file length?
        KermitConsole.GetFileAttributes(@FileNameBuffer,FileNameBufferSize,@DeclaredFileLength)
        if DeclaredFileLength <> KDefs#NoFileLength
          LONG[pMonArray][DFL_IndexLong] := DeclaredFileLength ' copy declared file length to debugging display area
        DeclaredLengthNotShown := false
      OTHER :             ' not expected
        ' do nothing
    ' end of packet type cases
    PacketIndex++
    'if DebugStruct[KDefs#KDB_ExtrSequenceNumber] == 1  ' 1 gets mark here
    '  repeat ' hang here
  ' end of packet received & processed flag is true
  'if DebugStruct[KDefs#KDB_ExtrSequenceNumber] == 2  ' get the extracted sequence number, 1 means file header is finished and gets no mark here
  '  repeat ' hang here
    
  if WaitingForFirstPacket
    WaitingForFirstPacket := false
    Monitor.LiveString(nums.ToStr(DebugStruct[KDefs#KDB_KR_VersionNumber],nums#DEC),TitleLabelBeginColumn+STRSIZE(pTitleStartString),LastLineBeginLong>>3)
    'Monitor.LiveString(String("Dummy String"),TitleLabelBeginColumn+STRSIZE(pTitleStartString),LastLineBeginLong>>3)

  ' update variables   ???  OH! I was going to NOT run variable update alone from MonVarsVGA... any cog created does both to save on cogs
  ' prefer NOT keeping VGA base pin hard coded, I think there are 4 choices for VGA base pins
  Monitor.MonitorVariables(KermitConsole#DummyInit,pMonArray,InputDisplaySizeLong)

  ' see if serial monitor needs starting
  if NeedToStartSerialMonitor
    ' try to start serial input buffer space remaining monitor cog
    SB_MonitorCogCode := RxBufMonitor.CogRun(KermitConsole.GetBufIndiciesAddress,pMonArray + (ErrorLogBeginLong + 16) << NumBytesInLongLog)
    'SB_MonitorCogCode := RxBufMonitor.CogRun(KermitConsole.GetBufIndiciesAddress,pMonArray + ErrorLogBeginLong + 20)
    NeedToStartSerialMonitor := false
  ' strange!! putting a 1 HERE blocks the showing of packet with sequence 1!!
  ' no, not strange.  Updating happens more often than just when packet processing is finished
  'if DebugStruct[KDefs#KDB_ExtrSequenceNumber] == 2  ' get the extracted sequence number, 1 means file header is finished and gets no mark here, 2 does get mark
  '  repeat ' hang here

  GeneralDebug(31,cnt) ' something to see if updating is happening

PRI GeneralDebug(index,the_value)
' place a value in the general variables area
  LONG[pMonArray][GeneralLiveVarsBeginLong+index] := the_value

PRI SetupForInitPacket
  ' place annotation within body of display, other is in margin and only placed once
  ' LiveString(pString,ColumnIndex,RowIndex)
  ' packet diag area
  Monitor.LiveString(STRING(" LengthChk   CountedLength  Decl Length  SequenceNumber ExtCkSum      CalcCkSum     Input flags   Ty Ec FS PS"),4,PacktDiagBeginLong>>3-1)
  ' error log area
  Monitor.LiveString(STRING("  PacketOK   TimeoutError  BadPaktStart  BadPacketLen      BadEOL    CkSumMismatch  WrongPktSeq    MissgChars"),4,ErrorLogBeginLong>>3-1)
  Monitor.LiveString(STRING("In Process     Waiting     ErrOutOfRnge"),4,ErrorLogBeginLong>>3+2)
  Monitor.LiveString(STRING("------Rx Buf----Rx Buf Min---          ---Decl File Sz--Meas File Sz"),45,ErrorLogBeginLong>>3+1)
  PacketIndex := 0              ' no packets received yet for this showing
  DeclaredLengthNotShown := true

PRI ReportParseDiagnostics(PacketECode)|ThisPacketBeginLong, ThisPacketTruncateLong
  PacketErrorLog(PacketECode)

  ShowPacketDiagnostics

  ' find long index of beginning of line to show this packet at
  if PacketIndex < NumPacketLines                       ' are we below limit of quantity of packets we will display?
    ThisPacketBeginLong := (PacketsBeginLong+(PacketIndex)*Monitor#VarsPerRow)
  else
    ' let additional packets over write the last packet repeatedly
    ThisPacketBeginLong := (PacketsBeginLong+(NumPacketLines-1)*Monitor#VarsPerRow)
    
  ThisPacketTruncateLong := ThisPacketBeginLong + Monitor#VarsPerRow            ' only show bytes of packet that fit on one row
  ' show this packet
  Monitor.SafePutMeasuredFrontierString(pMonArray,ThisPacketTruncateLong+1,ThisPacketBeginLong<<NumBytesInLongLog,pPacket,PacketInputIndex)

PRI PacketErrorLog(PakErrCode)|OffsetIntoErrorLog
  if PakErrCode < KDefs#ErrorCodeRange and PakErrCode => KDefs#PEC_KermitPacketReady
    ' where to tally is based on error code value
    OffsetIntoErrorLog := PakErrCode
  else
    ' report that index violation attempt occured, as yet another error code, i.e. error code itsself was out of range
    OffsetIntoErrorLog := KDefs#ErrorCodeRange
  LONG[pMonArray][ErrorLogBeginLong + OffsetIntoErrorLog]++


PRI ShowPacketDiagnostics : SequenceNumber | LengthCheckFlag, CalculatedChecksum, ExtractedChecksum, ShowAt, TheAddress
  ' display some diagnostics about the packet
  ' does measured packet length equal declared?
  if PacketInputIndex == DebugStruct[KDefs#KDB_DeclPacketLength]
    LengthCheckFlag := true                             ' show that measured packet length equals declared
  else
    LengthCheckFlag := false
    
  SequenceNumber := DebugStruct[KDefs#KDB_ExtrSequenceNumber]                    ' get the extracted sequence number
  ExtractedChecksum := DebugStruct[KDefs#KDB_ExtractedChecksum]
  CalculatedChecksum := DebugStruct[KDefs#KDB_CalculatedChecksum]
  
  if PacketIndex < NumPacktDiagLines                    ' is there room on the screen to show this diagnostic?
    ' show on new line
    ShowAt := PacketIndex*Monitor#VarsPerRow
  else
    ' over write last line
    ShowAt := (NumPacktDiagLines-1)*Monitor#VarsPerRow

  TheAddress := PakReportAddress(pMonArray,PacktDiagBeginByte,ShowAt,0)
  LONG[TheAddress] := LengthCheckFlag                                ' post agreement flag
  TheAddress := PakReportAddress(pMonArray,PacktDiagBeginByte,ShowAt,1)
  LONG[TheAddress] := PacketInputIndex ' counted characters
  TheAddress := PakReportAddress(pMonArray,PacktDiagBeginByte,ShowAt,2)
  LONG[TheAddress] := DebugStruct[KDefs#KDB_DeclPacketLength] ' string length from declared length field
  TheAddress := PakReportAddress(pMonArray,PacktDiagBeginByte,ShowAt,3)
  LONG[TheAddress] := SequenceNumber ' sequence number from sequence field
  TheAddress := PakReportAddress(pMonArray,PacktDiagBeginByte,ShowAt,4)
  LONG[TheAddress] := ExtractedChecksum ' numeric checksum from declared checksum field
  TheAddress := PakReportAddress(pMonArray,PacktDiagBeginByte,ShowAt,5)
  LONG[TheAddress] := CalculatedChecksum ' numeric checksum calculated from input string                 
  TheAddress := PakReportAddress(pMonArray,PacktDiagBeginByte,ShowAt,6)
  LONG[TheAddress] := DebugStruct[KDefs#KDB_InputStatusFlags] ' input status flag bits being passed to caller

  ' set individual bytes of this last column                        
  BYTE[pMonArray + PacktDiagBeginByte + (ShowAt+7) << NumBytesInLongLog][3] := DebugStruct[KDefs#KDB_PakType] ' show global that has packet type, in most significatn byte
  BYTE[pMonArray + PacktDiagBeginByte + (ShowAt+7) << NumBytesInLongLog][2] := DebugStruct[KDefs#KDB_PacketErrorCode] ' show global that has parse error code
  BYTE[pMonArray + PacktDiagBeginByte + (ShowAt+7) << NumBytesInLongLog][1] := DebugStruct[KDefs#KDB_FileState] ' show global that has state of file process
  BYTE[pMonArray + PacktDiagBeginByte + (ShowAt+7) << NumBytesInLongLog][0] := DebugStruct[KDefs#KDB_ParseState] ' show global that has state of parse process
                                                                                 
PRI PakReportAddress(pArray,Offset,LineIndex,ColIndex):Address
  Address := pArray + PacktDiagBeginByte + ((LineIndex + ColIndex) << NumBytesInLongLog)

PRI PacketErrorLogPrep
  '  zero tally of errors
  LONGFILL(pMonArray+ErrorLogBeginLong<<2,0,KDefs#ErrorCodeRange+1)
  
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