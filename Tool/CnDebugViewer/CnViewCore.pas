{******************************************************************************}
{                       CnPack For Delphi/C++Builder                           }
{                     �й����Լ��Ŀ���Դ�������������                         }
{                   (C)Copyright 2001-2023 CnPack ������                       }
{                   ------------------------------------                       }
{                                                                              }
{            ���������ǿ�Դ���������������������� CnPack �ķ���Э������        }
{        �ĺ����·�����һ����                                                }
{                                                                              }
{            ������һ��������Ŀ����ϣ�������ã���û���κε���������û��        }
{        �ʺ��ض�Ŀ�Ķ������ĵ���������ϸ���������� CnPack ����Э�顣        }
{                                                                              }
{            ��Ӧ���Ѿ��Ϳ�����һ���յ�һ�� CnPack ����Э��ĸ��������        }
{        ��û�У��ɷ������ǵ���վ��                                            }
{                                                                              }
{            ��վ��ַ��http://www.cnpack.org                                   }
{            �����ʼ���master@cnpack.org                                       }
{                                                                              }
{******************************************************************************}

unit CnViewCore;
{ |<PRE>
================================================================================
* �������ƣ�CnDebugViewer
* ��Ԫ���ƣ����Ľṹ���ַ������嵥Ԫ
* ��Ԫ���ߣ���Х��LiuXiao�� liuxiao@cnpack.org
* ��    ע��
* ����ƽ̨��PWin2000Pro + Delphi 5.01
* ���ݲ��ԣ�PWin9X/2000/XP + Delphi 5/6/7
* �� �� �����õ�Ԫ�е��ַ���֧�ֱ��ػ�������ʽ
* �޸ļ�¼��2008.01.18
*               Sesame: ���ӱ��洰���ϴ�λ�õ�����
*           2005.01.01
*               ������Ԫ��ʵ�ֹ���
================================================================================
|</PRE>}

interface

uses
  SysUtils, Classes, Windows, Forms, Graphics, TLHelp32, PsAPI,
  OmniXML, OmniXMLPersistent, CnLangMgr, CnIniStrUtils, CnDebugIntf;

const
  CnMapSize = 65536;
  CnHeadSize = 64;
  CnProtectSize = 4;

  CnWaitEventTime = 100;
  CnWaitMutexTime = 100;
  CnStartRetryCount = 20;

  SCnViewerMutexName = 'CnViewerMutexName';
  SCnDefDateTimeFmt = 'hh:nn:ss.zzz';
  SCnDefLongDateTimeFmt = 'yyyy-mm-dd hh:nn:ss.zzz';
  SCnOptionFileName = 'CnDVOptions.xml';

  csLangDir = 'Lang\';
  csHelpDir = 'Help\';
  SCnDbgHelpIniFile = 'Help.ini';
  SCnDbgHelpIniSecion = 'CnDebugger';
  SCnDbgHelpIniTopic = 'CnDebugViewer';

  CnInvalidSlot = -1;
  CnInvalidLine = -1;
  CnInvalidFileProcId = $FFFFFFFF;

  DbWinBufferSize = 4096;
  SDbWinBufferReady = 'DBWIN_BUFFER_READY';
  SDbWinDataReady = 'DBWIN_DATA_READY';
  SDbWinBuffer = 'DBWIN_BUFFER';

type
  TCnCoreInitResults = (ciOK, ciCreateEventFail, ciCreateMutexFail, ciCreateMapFail, ciMapViewFail);

  TCnViewerOptions = class(TPersistent)
  private
    FDateTimeFormat: string;
    FSearchDownCount: Integer;
    FEnableFilter: Boolean;
    FFilterTypes: TCnMsgTypes;
    FFilterLevel: Integer;
    FFilterTag: string;
    FMsgColumnWidth: Integer;
    FIgnoreODString: Boolean;
    FShowTrayIcon: Boolean;
    FMinToTrayIcon: Boolean;
    FMainShortCut: TShortCut;
    FCloseToTrayIcon: Boolean;
    FStartMin: Boolean;
    FAutoScroll: Boolean;
    FSaveFormPosition: Boolean;
    FTop, FLeft, FHeight, FWidth, FWinState: Integer;
    FLongDateTimeFormat: string;
    FEnableUDPMsg: Boolean;
    FUDPPort: Integer;
    FLocalSession: Boolean;
    FDisplayFont: TFont;
    FDisplayFontStr: string;
    FWhiteList: string;
    FBlackList: string;
    FChangeCount: Integer;
    FUseBlackList: Boolean;
    procedure SetTop(const Value: Integer);
    procedure SetLeft(const Value: Integer);
    procedure SetWidth(const Value: Integer);
    procedure SetHeight(const Value: Integer);
    procedure SetDisplayFontStr(const Value: string);
    procedure SetDisplayFont(const Value: TFont);
    procedure SetBlackList(const Value: string);
    procedure SetWhiteList(const Value: string);
  public
    constructor Create;
    destructor Destroy; override;

    procedure FontNeeded;

    property DisplayFont: TFont read FDisplayFont write SetDisplayFont;
    {* ��ʾ�����壬Ĭ��Ϊ nil Ҳ��ʹ��ϵͳ����}
    property ChangeCount: Integer read FChangeCount write FChangeCount;
  published
    property IgnoreODString: Boolean read FIgnoreODString write FIgnoreODString;
    property EnableFilter: Boolean read FEnableFilter write FEnableFilter;
    property FilterLevel: Integer read FFilterLevel write FFilterLevel;
    property FilterTag: string read FFilterTag write FFilterTag;
    property FilterTypes: TCnMsgTypes read FFilterTypes write FFilterTypes;

    property EnableUDPMsg: Boolean read FEnableUDPMsg write FEnableUDPMsg;
    property UDPPort: Integer read FUDPPort write FUDPPort default 9099;

    property SearchDownCount: Integer read FSearchDownCount write FSearchDownCount;
    property DateTimeFormat: string read FDateTimeFormat write FDateTimeFormat;
    property LongDateTimeFormat: string read FLongDateTimeFormat write FLongDateTimeFormat;
    property MsgColumnWidth: Integer read FMsgColumnWidth write FMsgColumnWidth;
    
    property ShowTrayIcon: Boolean read FShowTrayIcon write FShowTrayIcon;
    {* �Ƿ���ʾϵͳ����ͼ�꣬��Ϊ False�����������С����ϵͳ���̵�������Ч }
    property MinToTrayIcon: Boolean read FMinToTrayIcon write FMinToTrayIcon;   
    {* ��С��ʱ�Ƿ�ϵͳ���̣�Ҳ������ʾ���������� }
    property MainShortCut: TShortCut read FMainShortCut write FMainShortCut;
    {* ��ʾ�������ȫ�ֿ�ݼ� }
    property CloseToTrayIcon: Boolean read FCloseToTrayIcon write FCloseToTrayIcon;
    {* �ر�ʱ�Ƿ���С����ϵͳ���̣����رգ�Ҳ����ʾ���������� }
    property StartMin: Boolean read FStartMin write FStartMin;
    {* ����ʱ�Ƿ���С��}
    property AutoScroll: Boolean read FAutoScroll write FAutoScroll;
    {* ������Ϣʱ�Ƿ��Զ����¹���}
    property SaveFormPosition: Boolean read FSaveFormPosition write FSaveFormPosition;
    {* �Ƿ񱣴洰���ϴ��˳�ʱ��״̬}      
    property Top: Integer read FTop write SetTop;
    {* ���ڶ�����ʼλ��}
    property Left: Integer read FLeft write SetLeft;
    {* ���������ʼλ��}
    property Height: Integer read FHeight write SetHeight;
    {* ���ڸ߶�}
    property Width: Integer read FWidth write SetWidth;
    {* ���ڿ���}  
    property WinState: Integer read FWinState write FWinState;
    {* ����״̬}

    property LocalSession: Boolean read FLocalSession write FLocalSession;
    {* �Ƿ�ʹ�ñ���ģʽ}
    property DisplayFontStr: string read FDisplayFontStr write SetDisplayFontStr;
    {* ����������ַ��������ڴ洢}

    property UseBlackList: Boolean read FUseBlackList write FUseBlackList;
    {* ����ʾ��������������н��̣�True��������ֻ��ʾ�������ڵĽ��̣�False��}
    property WhiteList: string read FWhiteList write SetWhiteList;
    {* ���̰�����}
    property BlackList: string read FBlackList write SetBlackList;
    {* ���̺�����}
  end;

var
  HMap:   THandle = 0;
  HMutex: THandle = 0;
  HEvent: THandle = 0;
  HFlush: THandle = 0;
  HViewerMutex: THandle = 0;
  PHeader: PCnMapHeader;
  PBase: Pointer;

  SysDebugReady: Boolean = False;
  SysDebugExists: Boolean = False;

  SysDbgSa: TSecurityAttributes;
  SysDbgSd: TSecurityDescriptor;
  HSysBufferReady: THandle = 0;
  HSysDataReady: THandle = 0;
  HSysBuffer: THandle = 0;
  PSysDbgBase: Pointer;

  CSMsgStore: TRTLCriticalSection;

  CPUClock: Extended; // ������õ� CPU ��Ƶ���� MHZ Ϊ��λ
  CnViewerOptions: TCnViewerOptions = nil;

  IsLocalMode: Boolean = False;

// ==== Start of 'Constant' String for Translation

  SCnNoneProcName: string = '[Unknown]';
  SCnHintMsgTree: string = 'Debugging Information Display';

  SCnCPUSpeedFmt: string = 'CPU Speed: %f MHz';
  SCnTreeColumn0: string = '#';
  SCnTreeColumn1: string = 'Information';
  SCnTreeColumn2: string = 'Type';
  SCnTreeColumn3: string = 'Level';
  SCnTreeColumn4: string = 'Thread';
  SCnTreeColumn5: string = 'Tag';
  SCnTreeColumn6: string = 'TimeStamp';

  SCnMsgTypeNone:          string = '*';
  SCnMsgTypeInformation:   string = 'Information';
  SCnMsgTypeWarning:       string = 'Warning';
  SCnMsgTypeError:         string = 'Error';
  SCnMsgTypeSeparator:     string = 'Separator';
  SCnMsgTypeEnterProc:     string = 'Enter';
  SCnMsgTypeLeaveProc:     string = 'Leave';
  SCnMsgTypeTimeMarkStart: string = 'Timing';
  SCnMsgTypeTimeMarkStop:  string = 'Timing';
  SCnMsgTypeMemoryDump:    string = 'MemDump';
  SCnMsgTypeException:     string = 'Exception';
  SCnMsgTypeObject:        string = 'Object';
  SCnMsgTypeComponent:     string = 'Component';
  SCnMsgTypeCustom:        string = 'Custom';
  SCnMsgTypeSystem:        string = 'System';
  SCnMsgTypeUDPMsg:        string = 'UDPMsg';
  SCnMsgTypeWatch:         string = 'Watch';
  SCnMsgTypeClearWatch:    string = 'ClearWatch';

  SCnMsgTypeEnterLeaveProc:     string = 'Enter/Leave';

  SCnMsgDescriptionFmt: string =
    'No: %-5d    Indent: %-3d    Level: %-1d    ThreadID: $%-8x    ProcessID: $%-8x   Tag: %-8s   TimeStamp: %s' +
    #13#10 + '%s';
  SCnTimeDescriptionFmt: string =
    'No: %-5d    Count: %8d    Tag: %-8s    Summary: %f us / (%s)' + #13#10 +
    'Average: %f us / (%s)    Max: %f us / (%s)   Min: %f us / (%s)';

  SCnThreadRunning: string = 'Running...';
  SCnThreadPaused: string = 'Paused';
  SCnThreadStopped: string = 'Stopped';

  SCnErrorCaption: string = 'Error';
  SCnInfoCaption: string = 'Hint';
  SCnNotFound: string = 'Searching Content NOT Found.';
  SCnStopFirst: string = 'Loading NOT Supported while Reading Debugging Information. Stop it First?';
  SCnDebuggerExists: string = 'Warning: Another Debugger Exists.';
  SCnBookmarkFull: string = 'Maximized Bookmark Count Reached! Can NOT Continue.';
  SCnBookmarkNOTExist: string = ' Bookmark NOT found, maybe Filtered.';
  SCnRegisterHotKeyError: string = 'Register HotKey Error. HotKey Disabled.';

  SCnBookmark: string = 'Bookmark &%d, Line %d';
  SCnNoHelpofThisLang: string = 'Sorry. No HELP in this Language.';

  SCnCSVFormatHeader: string = 'Index,Level,Type,ThreadID,ProcessID,Tag,TimeStamp,Message';
  SCnHTMFormatCharset: string = 'iso-8859-1';

  SCnHTMFormatStyle: string =
    '.tabletext   { font-family: Tahoma; font-size: 8pt; text-align: left; line-height: 13pt;' + #13#10 +
    '               color: #000000; background-color: #FFFFF8 }' + #13#10 +
    '.tablehead   { font-family: Tahoma; font-size: 8pt; text-align: center; line-height: 13pt;' + #13#10 +
    '               color: #0000FF; background-color: #DDEEFF }' + #13#10;
  SCnHTMFormatTableHead: string =
    '<tr>' + #13#10 +
      '<td width="24pt" class="tablehead" valign="top">Index</td>' + #13#10 +
      '<td width="9pt" class="tablehead" valign="top">Level</td>' + #13#10 +
      '<td width="28pt" class="tablehead" valign="top">Type</td>' + #13#10 +
      '<td width="32pt" class="tablehead" valign="top">ThreadID</td>' + #13#10 +
      '<td width="32pt" class="tablehead" valign="top">ProcessID</td>' + #13#10 +
      '<td width="28pt" class="tablehead" valign="top">Tag</td>' + #13#10 +
      '<td width="60pt" class="tablehead" valign="top">TimeStamp</td>' + #13#10 +
      '<td class="tablehead">Message</td>' + #13#10 +
    '</tr>';
  SCnDebugViewerAboutCaption: string = 'About';
  SCnDebugViewerAbout: string =
    'CnDebugViewer 1.9' + #13#10#13#10 +
    'This Tool is Used to Show the Debugging Output Information from CnDebug.' + #13#10#13#10 +
    'Author: Liu Xiao (liuxiao@cnpack.org)' + #13#10 +
    'Copyright (C) 2001-2023 CnPack Team';

  SCnHTMFormatHeader: string =
    '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">' + #13#10 +
    '<html>' + #13#10 +
    '<head>' + #13#10 +
    '<style>' + #13#10 +
    '<!--' + #13#10 + '%s' +
    '-->' + #13#10 +
    '</style>' + #13#10 +
    '<title>%s</title>' + #13#10 +
    '<meta http-equiv="Content-Type" content="text/html; charset=%s">' + #13#10 +
    '<link rel="stylesheet" href="../css/style.css" type="text/css">' + #13#10 +
    '</head>' + #13#10 +
    '<table width="100%%" cellspacing="1" cellpadding="2" bgcolor="#CCCCFF"' + #13#10 +
    'bordercolor="#CCCCFF" bordercolorlight="#FFFFFF" bordercolordark="#6666FF" valign="top">';

  SCnHTMFormatLine: string = 
    '<tr>' + #13#10 +
      '<td width="24pt" class="tabletext" valign="top">%d</td>' + #13#10 +
      '<td width="9pt" class="tabletext" valign="top">%d</td>' + #13#10 +
      '<td width="28pt" class="tabletext" valign="top">%s</td>' + #13#10 +
      '<td width="32pt" class="tabletext" valign="top">$%x</td>' + #13#10 +
      '<td width="32pt" class="tabletext" valign="top">$%x</td>' + #13#10 +
      '<td width="28pt" class="tabletext" valign="top">%s</td>' + #13#10 +
      '<td width="60pt" class="tabletext" valign="top">%s</td>' + #13#10 +
      '<td class="tabletext">%s</td>' + #13#10 +
    '</tr>';

  SCnHTMFormatEnd: string = '</table></body></html>';

// ==== End of 'Constant' String for Translation

const
  SCnTreeColumnArray: array[0..6] of PString = (@SCnTreeColumn0,
    @SCnTreeColumn1, @SCnTreeColumn2, @SCnTreeColumn3, @SCnTreeColumn4,
    @SCnTreeColumn5, @SCnTreeColumn6);

  CnMsgTypesArray: array[0..13] of TCnMsgTypes = ( [],
    [cmtInformation], [cmtWarning], [cmtError], [cmtSeparator], [cmtEnterProc,
    cmtLeaveProc], [cmtTimeMarkStart, cmtTimeMarkStop], [cmtMemoryDump],
    [cmtException], [cmtObject], [cmtComponent], [cmtCustom], [cmtSystem], [cmtUDPMsg]
  );

  SCnMsgTypesDescArray: array[0..13] of PString = ( @SCnMsgTypeNone,
    @SCnMsgTypeInformation, @SCnMsgTypeWarning, @SCnMsgTypeError,
    @SCnMsgTypeSeparator, @SCnMsgTypeEnterLeaveProc,
    @SCnMsgTypeTimeMarkStart, @SCnMsgTypeMemoryDump,
    @SCnMsgTypeException, @SCnMsgTypeObject, @SCnMsgTypeComponent,
    @SCnMsgTypeCustom, @SCnMsgTypeSystem, @SCnMsgTypeUDPMsg);

  SCnMsgTypeDescArray: array[TCnMsgType] of PString = (
    @SCnMsgTypeInformation, @SCnMsgTypeWarning, @SCnMsgTypeError,
    @SCnMsgTypeSeparator, @SCnMsgTypeEnterProc, @SCnMsgTypeLeaveProc,
    @SCnMsgTypeTimeMarkStart, @SCnMsgTypeTimeMarkStop, @SCnMsgTypeMemoryDump,
    @SCnMsgTypeException, @SCnMsgTypeObject, @SCnMsgTypeComponent,
    @SCnMsgTypeCustom, @SCnMsgTypeSystem, @SCnMsgTypeUDPMsg, @SCnMsgTypeWatch,
    @SCnMsgTypeClearWatch);

  SCnHotKeyId = 1;
  
function InitializeCore: TCnCoreInitResults;

procedure FinalizeCore;

procedure InitSysDebug;

procedure CalcCPUSpeed;

function CheckRunning: Boolean;

procedure SetAnotherViewer;

procedure PostStartEvent;

function GetProcNameFromProcessID(ProcessID: DWORD): string;

procedure LoadOptions(const FileName: string);

procedure SaveOptions(const FileName: string);

procedure UpdateFilterToMap;

procedure ErrorDlg(const AText: string);

function QueryDlg(Mess: string; DefaultNo: Boolean = False;
  Caption: string = ''): Boolean;

procedure TranslateStrings;

implementation

function GetCPUPeriod: Int64; assembler;
asm
  DB 0FH;
  DB 031H;
end;

function InitializeCore: TCnCoreInitResults;
begin
  HEvent := CreateEvent(nil, False, False, PChar(SCnDebugQueueEventName));
  if HEvent = 0 then
  begin
    Result := ciCreateEventFail;
    Exit;
  end;

  HMutex := CreateMutex(nil, False, PChar(SCnDebugQueueMutexName));
  if HMutex = 0 then
  begin
    Result := ciCreateMutexFail;
    Exit;
  end;

  HMap := CreateFileMapping(INVALID_HANDLE_VALUE, nil, PAGE_READWRITE, 0,
    CnMapSize + CnProtectSize, PChar(SCnDebugMapName));

  if HMap = 0 then
  begin
    Result := ciCreateMapFail;
    Exit;
  end;

  PBase := MapViewOfFile(HMap, FILE_MAP_WRITE or FILE_MAP_READ, 0, 0, 0);
  if PBase = nil then
  begin
    Result := ciMapViewFail;
    Exit;
  end;

  PHeader := PBase;
  PHeader^.MapSize := CnMapSize;
  PHeader^.DataOffset := CnHeadSize;
  PHeader^.QueueFront := 0;
  PHeader^.QueueTail := 0;
  PHeader^.MapEnabled := CnDebugMapEnabled;
{$IFDEF UNICODE}
  CopyMemory(Pointer(PHeader), @CnDebugMagicName[1], Length(CnDebugMagicName) + 1);
{$ELSE}
  StrCopy(Pointer(PHeader), CnDebugMagicName);
{$ENDIF}

  InitializeCriticalSection(CSMsgStore);
  if not CnViewerOptions.IgnoreODString then
    InitSysDebug;

  Result := ciOK;
end;

procedure InitSysDebug;
begin
  if not InitializeSecurityDescriptor(@SysDbgSd, SECURITY_DESCRIPTOR_REVISION) then
    Exit;

  if not SetSecurityDescriptorDacl(@SysDbgSd, True, nil, False) then
    Exit;

  SysDbgSa.nLength := sizeof(TSecurityAttributes);
  SysDbgSa.bInheritHandle := True;
  SysDbgSa.lpSecurityDescriptor := @SysDbgSd;

  HSysBufferReady := CreateEvent(@SysDbgSa, False, False, SDbWinBufferReady);
  if HSysBufferReady = 0 then
    Exit;

  if GetLastError() = ERROR_ALREADY_EXISTS then
  begin
    SysDebugExists := True;
    Exit;
  end;

  HSysDataReady := CreateEvent(@SysDbgSa, False, False, SDbWinDataReady);
  if HSysDataReady = 0 then
    Exit;

  HSysBuffer := CreateFileMapping(INVALID_HANDLE_VALUE, @SysDbgSa, PAGE_READWRITE,
    0, DbWinBufferSize, SDbWinBuffer);
  if HSysBuffer <> 0 then
  begin
    PSysDbgBase := MapViewOfFile(HSysBuffer, FILE_MAP_READ, 0, 0, DbWinBufferSize);
    if PSysDbgBase <> nil then
      SysDebugReady := True;
  end;
end;

procedure FinalizeCore;
begin
  if HViewerMutex <> 0 then
  begin
    CloseHandle(HViewerMutex);
    HViewerMutex := 0;
  end;
  if PBase <> nil then
  begin
    PHeader := PBase;
    PHeader^.MapEnabled := 0;
    // д�������ֵ�����´� CnDebug ��Ԫֹͣ���
    UnmapViewOfFile(PBase);
    PBase := nil;
  end;
  if HMap <> 0 then
  begin
    CloseHandle(HMap);
    HMap := 0;
  end;
  if HEvent <> 0 then
  begin
    CloseHandle(HEvent);
    HEvent := 0;
  end;
  if HFlush <> 0 then
  begin
    CloseHandle(HFlush);
    HFlush := 0;
  end;
  if HMutex <> 0 then
  begin
    CloseHandle(HMutex);
    HMutex := 0;
  end;

  DeleteCriticalSection(CSMsgStore);

  if PSysDbgBase <> nil then
  begin
    UnmapViewOfFile(PSysDbgBase);
    PSysDbgBase := nil;
  end;
  if HSysBuffer <> 0 then
  begin
    CloseHandle(HSysBuffer);
    HSysBuffer := 0;
  end;
  if HSysDataReady <> 0 then
  begin
    CloseHandle(HSysDataReady);
    HSysDataReady := 0;
  end;
  if HSysBufferReady <> 0 then
  begin
    CloseHandle(HSysBufferReady);
    HSysBufferReady := 0;
  end;
end;

procedure CalcCPUSpeed;
var
  T: DWORD;
  A, B: Int64;
begin
  T := GetTickCount;
  while T = GetTickCount do;{wait for tickchange}
  A := GetCPUPeriod;
  while GetTickCount < (T + 501) do;
  B := GetCPUPeriod;
  CPUClock := 2e-6 * (B - A);{MHz}
end;

function CheckRunning: Boolean;
begin
  HViewerMutex := CreateMutex(nil, False, PChar(SCnViewerMutexName));
  Result := ERROR_ALREADY_EXISTS = GetLastError;
  if Result and FindCmdLineSwitch('A', ['-'], True) then
    PostStartEvent;
end;

procedure SetAnotherViewer;
var
  HViewer: HWND;
begin
  HViewer := FindWindow('TCnMainViewer', nil);
  if HViewer <> 0 then
    SetForegroundWindow(HViewer);
end;

procedure PostStartEvent;
var
  HStartEvent: THandle;
begin
  HStartEvent := OpenEvent(EVENT_MODIFY_STATE, False, PChar(SCnDebugStartEventName));
  if HStartEvent <> 0 then
  begin
    SetEvent(HStartEvent);
    CloseHandle(HStartEvent);
  end;
end;

function GetProcNameFromProcessID(ProcessID: DWORD): string;
var
  HSnap, Hp: THandle;
  Pe: TProcessEntry32;
  Next: BOOL;
  HM: HModule;
  N: DWORD;
  ModName: array[0..MAX_PATH - 1] of Char;
begin
  Result := '';
  Hp := OpenProcess(PROCESS_QUERY_INFORMATION or PROCESS_VM_READ, False, ProcessID);
  if Hp <> 0 then
  begin
    if EnumProcessModules(Hp, @HM, Sizeof(HM), N) then
    begin
      if GetModuleFileNameEx(Hp, HM, ModName, Sizeof(ModName)) > 0 then
      begin
        Result := ModName;
        CloseHandle(Hp);
        Exit;
      end;
    end;
    CloseHandle(Hp);
  end;

  HSnap := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  Pe.dwSize := SizeOf(Pe);
  Next := Process32First(HSnap, Pe);
  while Next do
  begin
    if Pe.th32ProcessID = ProcessID then
    begin
      Result := Pe.szExeFile;
      Break;
    end;
    Next := Process32Next(HSnap, Pe);
  end;
  CloseHandle(HSnap);
end;

procedure LoadOptions(const FileName: string);
begin
  if FileExists(FileName) then
    TOmniXMLReader.LoadFromFile(CnViewerOptions, FileName);
end;

procedure SaveOptions(const FileName: string);
begin
  ForceDirectories(ExtractFileDir(FileName));
  TOmniXMLWriter.SaveToFile(CnViewerOptions, FileName, pfAuto, ofIndent);
end;

procedure UpdateFilterToMap;
var
  Len: Integer;
begin
  if (HMap <> 0) and (PHeader <> nil) then
  begin
    if CnViewerOptions.EnableFilter then
      PHeader^.Filter.Enabled := 1
    else
      PHeader^.Filter.Enabled := 0;
    PHeader^.Filter.Level := CnViewerOptions.FFilterLevel;

    FillChar(PHeader^.Filter.Tag, CnMaxTagLength, 0);
    Len := Length(CnViewerOptions.FFilterTag);
    if Len > CnMaxTagLength then Len := CnMaxTagLength;
    CopyMemory(@(PHeader^.Filter.Tag), PChar(CnViewerOptions.FilterTag), Len);

    PHeader^.Filter.MsgTypes := CnViewerOptions.FilterTypes;
    PHeader^.Filter.NeedRefresh := 1;
  end;
end;

procedure ErrorDlg(const AText: string);
begin
  MessageBox(Application.Handle, PChar(AText), PChar(SCnErrorCaption),
    MB_OK or MB_ICONERROR);
end;

function QueryDlg(Mess: string; DefaultNo: Boolean; Caption: string): Boolean;
const
  Defaults: array[Boolean] of DWORD = (0, MB_DEFBUTTON2);
begin
  if Caption = '' then
    Caption := SCnInfoCaption;
  Result := Application.MessageBox(PChar(Mess), PChar(Caption),
    MB_YESNO + MB_ICONQUESTION + Defaults[DefaultNo]) = IDYES;
end;

procedure TranslateStrings;
begin
  TranslateStr(SCnNoneProcName, 'SCnNoneProcName');
  TranslateStr(SCnHintMsgTree, 'SCnHintMsgTree');

  TranslateStr(SCnCPUSpeedFmt, 'SCnCPUSpeedFmt');
  TranslateStr(SCnTreeColumn0, 'SCnTreeColumn0');
  TranslateStr(SCnTreeColumn1, 'SCnTreeColumn1');
  TranslateStr(SCnTreeColumn2, 'SCnTreeColumn2');
  TranslateStr(SCnTreeColumn3, 'SCnTreeColumn3');
  TranslateStr(SCnTreeColumn4, 'SCnTreeColumn4');
  TranslateStr(SCnTreeColumn5, 'SCnTreeColumn5');
  TranslateStr(SCnTreeColumn6, 'SCnTreeColumn6');

  TranslateStr(SCnMsgTypeNone, 'SCnMsgTypeNone');
  TranslateStr(SCnMsgTypeInformation, 'SCnMsgTypeInformation');
  TranslateStr(SCnMsgTypeWarning, 'SCnMsgTypeWarning');
  TranslateStr(SCnMsgTypeError, 'SCnMsgTypeError');
  TranslateStr(SCnMsgTypeSeparator, 'SCnMsgTypeSeparator');
  TranslateStr(SCnMsgTypeEnterProc, 'SCnMsgTypeEnterProc');
  TranslateStr(SCnMsgTypeLeaveProc, 'SCnMsgTypeLeaveProc');
  TranslateStr(SCnMsgTypeTimeMarkStart, 'SCnMsgTypeTimeMarkStart');
  TranslateStr(SCnMsgTypeTimeMarkStop, 'SCnMsgTypeTimeMarkStop');
  TranslateStr(SCnMsgTypeMemoryDump, 'SCnMsgTypeMemoryDump');
  TranslateStr(SCnMsgTypeException, 'SCnMsgTypeException');
  TranslateStr(SCnMsgTypeObject, 'SCnMsgTypeObject');
  TranslateStr(SCnMsgTypeComponent, 'SCnMsgTypeComponent');
  TranslateStr(SCnMsgTypeCustom, 'SCnMsgTypeCustom');
  TranslateStr(SCnMsgTypeSystem, 'SCnMsgTypeSystem');
  TranslateStr(SCnMsgTypeSystem, 'SCnMsgTypeSystem');
  TranslateStr(SCnMsgTypeUDPMsg, 'SCnMsgTypeUDPMsg');
  TranslateStr(SCnMsgTypeEnterLeaveProc, 'SCnMsgTypeEnterLeaveProc');

  TranslateStr(SCnMsgDescriptionFmt, 'SCnMsgDescriptionFmt');
  TranslateStr(SCnTimeDescriptionFmt, 'SCnTimeDescriptionFmt');

  TranslateStr(SCnThreadRunning, 'SCnThreadRunning');
  TranslateStr(SCnThreadPaused, 'SCnThreadPaused');
  TranslateStr(SCnThreadStopped, 'SCnThreadStopped');

  TranslateStr(SCnErrorCaption, 'SCnErrorCaption');
  TranslateStr(SCnInfoCaption, 'SCnInfoCaption');
  TranslateStr(SCnNotFound, 'SCnNotFound');
  TranslateStr(SCnStopFirst, 'SCnStopFirst');
  TranslateStr(SCnDebuggerExists, 'SCnDebuggerExists');

  TranslateStr(SCnBookmarkFull, 'SCnBookmarkFull');
  TranslateStr(SCnBookmark, 'SCnBookmark');
  TranslateStr(SCnBookmarkNOTExist, 'SCnBookmarkNOTExist');

  TranslateStr(SCnCSVFormatHeader, 'SCnCSVFormatHeader');
  TranslateStr(SCnHTMFormatStyle, 'SCnHTMFormatStyle');
  TranslateStr(SCnHTMFormatCharset, 'SCnHTMFormatCharset');
  TranslateStr(SCnHTMFormatTableHead, 'SCnHTMFormatTableHead');

  TranslateStr(SCnDebugViewerAboutCaption, 'SCnDebugViewerAboutCaption');
  TranslateStr(SCnDebugViewerAbout, 'SCnDebugViewerAbout');
end;

{ TCnViewerOptions }

constructor TCnViewerOptions.Create;
begin
  inherited;
  FFilterLevel := 3;
  FSearchDownCount := 7;
  FDateTimeFormat := SCnDefDateTimeFmt;
  FLongDateTimeFormat := SCnDefLongDateTimeFmt;
  FIgnoreODString := True;
  FMainShortCut := 49238; //Ctrl + Alt + V
  FShowTrayIcon := True;
  FMinToTrayIcon := True;
  FSaveFormPosition := True;
  FTop := 0;
  FLeft := 0;
  FHeight := Screen.Height - 25;
  FWidth := Screen.Width;
  FWinState := 0;
  FEnableUDPMsg := False;
  FUDPPort := 9099;
  FLocalSession := True;
  FUseBlackList := True;
end;

destructor TCnViewerOptions.Destroy;
begin
  FDisplayFont.Free;
  inherited;
end;

procedure TCnViewerOptions.SetTop(const Value: Integer);
begin
  if (Value >= 0) and (Value <> FTop) then
    FTop := Value;
end;

procedure TCnViewerOptions.SetLeft(const Value: Integer);
begin
  if (Value >= 0) and (Value <> FLeft) then
  FLeft := Value;
end;

procedure TCnViewerOptions.SetWhiteList(const Value: string);
begin
  FWhiteList := Value;
end;

procedure TCnViewerOptions.SetWidth(const Value: Integer);
begin
  if (Value > 0) and (Value <> FWidth) then
    FWidth := Value;
end;

procedure TCnViewerOptions.SetHeight(const Value: Integer);
begin
  if (Value > 0) and (Value <> FHeight) then
    FHeight := Value;
end;

procedure TCnViewerOptions.FontNeeded;
begin
  if FDisplayFont = nil then
    FDisplayFont := TFont.Create;
end;

procedure TCnViewerOptions.SetDisplayFontStr(const Value: string);
begin
  FDisplayFontStr := Value;
  if Value = '' then
    FreeAndNil(FDisplayFont)
  else
  begin
    FontNeeded;
    StringToFont(Value, FDisplayFont);
  end;
end;

procedure TCnViewerOptions.SetBlackList(const Value: string);
begin
  FBlackList := Value;
end;

procedure TCnViewerOptions.SetDisplayFont(const Value: TFont);
begin
  if Value = nil then
    FreeAndNil(FDisplayFont)
  else
  begin
    FontNeeded;
    FDisplayFont.Assign(Value);
    FDisplayFontStr := FontToString(FDisplayFont);
  end;
end;

initialization
  CalcCPUSpeed;
  CnViewerOptions := TCnViewerOptions.Create;

finalization
  FreeAndNil(CnViewerOptions);
  FinalizeCore;

end.