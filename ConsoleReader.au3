#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=Icons\console.ico
#AutoIt3Wrapper_Res_Comment=Reads out stdout of programs started with drag and drop onto consolereader.
#AutoIt3Wrapper_Res_Description=Reads out stdout of programs started with drag and drop onto consolereader.
#AutoIt3Wrapper_Res_Fileversion=1.0.0.8
#AutoIt3Wrapper_Res_Fileversion_AutoIncrement=y
#AutoIt3Wrapper_Res_LegalCopyright=Conrad Zelck
#AutoIt3Wrapper_Res_Language=1031
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#include <AutoItConstants.au3>
#include <WindowsConstants.au3>
#include <EditConstants.au3>
#include <GUIConstantsEx.au3>
#include <StaticConstants.au3>
#include <array.au3>
#include <WinAPIProc.au3>
#include <GuiEdit.au3>
#include <TrayCox.au3> ; source: https://github.com/SimpelMe/TrayCox

Opt("GUIOnEventMode", 1)

Global $data = ""
Global $g_aPID = [0]
Global $g_bFreeze = False
Global $g_iZaehler = 0

Global $g_hGUI = GUICreate("Console: StdoutRead" , 800, 800, -1, -1, $WS_OVERLAPPEDWINDOW + $WS_CLIPCHILDREN, $WS_EX_ACCEPTFILES)
GUISetOnEvent($GUI_EVENT_CLOSE, "_Exit")

Global $text = GUICtrlCreateEdit("",10,30,780,760, $ES_AUTOVSCROLL + $WS_VSCROLL + $ES_READONLY + $ES_NOHIDESEL)
GUICtrlSetState(-1, $GUI_DROPACCEPTED)
GUICtrlSetFont(-1, 9, -1, -1, "Lucida Console")
GUICtrlSetResizing(-1, $GUI_DOCKBORDERS)
GUISetOnEvent($GUI_EVENT_DROPPED, "_Dropped")
_GUICtrlEdit_SetLimitText($text, 8388608) ; that should be 1MB max.

Global $g_LaZeilen = GUICtrlCreateLabel("Zeilen: " & StringFormat("% 5d", $g_iZaehler), 680, 10, 100, 9, $SS_LEFTNOWORDWRAP, $WS_EX_LAYERED)
GUICtrlSetFont(-1, 9, -1, -1, "Lucida Console")
GUICtrlSetResizing(-1, $GUI_DOCKRIGHT + $GUI_DOCKTOP + $GUI_DOCKSIZE)

Global $g_hCbFreeze = GUICtrlCreateCheckbox("&Freeze", 13, 5, 90)
GUICtrlSetFont(-1, 9, -1, -1, "Lucida Console")
GUICtrlSetResizing(-1, $GUI_DOCKALL)
GUICtrlSetOnEvent($g_hCbFreeze, "_Freeze")

Global $g_hBuCopy = GUICtrlCreateButton("&Copy All", 125, 5, 70, 20)
GUICtrlSetFont(-1, 9, -1, -1, "Lucida Console")
GUICtrlSetResizing(-1, $GUI_DOCKALL)
GUICtrlSetOnEvent($g_hBuCopy, "_Copy")

GUISetState(@SW_SHOW)
If $CmdLine[0] > 0 Then
	_ViaCmdline()
	_GUICtrlEdit_AppendText($text, $CmdLine[1] & @CRLF)
EndIf

Global $sText = StringFormat("% 5d", $g_iZaehler) & @TAB
_GUICtrlEdit_AppendText($text, $sText)

Local $nextline
While 1
	If $g_aPID[0] > 0 Then
		$nextline = _ConsoleReadLine()
		$nextline = StringReplace($nextline, @CRLF, @CRLF & StringFormat("% 5d", $g_iZaehler) & @TAB)
		$sText = $nextline
		If $g_bFreeze = False Then
			_GUICtrlEdit_AppendText($text, $sText)
		EndIf
		GUICtrlSetData($g_LaZeilen, "Zeilen: " & StringFormat("% 5d", $g_iZaehler))
	EndIf
	_ProcessExist()
WEnd

#region - Funcs
Func _ConsoleReadLine()
    Local $Result,$crPos
    While True
		_ProcessExist()
		For $i = 1 To $g_aPID[0]
			$data &= StdoutRead($g_aPID[$i])
			If @error Then ExitLoop
		Next
        $crPos = StringInStr($data, @CRLF)
        If $crPos Then
            $Result = StringLeft($data, $crPos) & @CRLF
            $data = StringRight($data, StringLen($data) - $crPos)
			$g_iZaehler += 1
            Return $Result
        EndIf
    WEnd
    Return SetError(1, 1, $data)
EndFunc

Func _Dropped()
	Local $hPID = Run(@GUI_DragFile, "", Default, $STDERR_MERGED)
	ConsoleWrite("DROP: " & $hPID & " " & @GUI_DragFile & @CRLF)
	_ArrayAdd($g_aPID, $hPID)
	$g_aPID[0] = UBound($g_aPID) - 1
EndFunc

Func _ViaCmdline()
	Local $hPID = Run($CmdLine[1], "", Default, $STDERR_MERGED)
	ConsoleWrite("CMDLINE: " & $hPID & " " & $CmdLine[1] & @CRLF)
	_ArrayAdd($g_aPID, $hPID)
	$g_aPID[0] = UBound($g_aPID) - 1
EndFunc

Func _Freeze()
	$g_bFreeze = Not $g_bFreeze
	ConsoleWrite("FREEZE: " & $g_bFreeze & @CRLF)
	GUICtrlSetState($text, $GUI_FOCUS)
EndFunc

Func _Copy()
	ConsoleWrite("COPY" & @CRLF)
	ClipPut(GUICtrlRead($text))
EndFunc


Func _ProcessExist()
	For $i = $g_aPID[0] To 1 Step - 1
		If Not ProcessExists($g_aPID[$i]) Then
			ConsoleWrite("GONE: " & $g_aPID[$i] & @CRLF)
			_ArrayDelete($g_aPID, $i)
			$g_aPID[0] = UBound($g_aPID) - 1
		EndIf
	Next
EndFunc

Func _Exit()
	If $CmdLine[0] = 0 Then ; only if programs are dragged and dropped onto consolereader - kill PIDs
		For $i = 1 To $g_aPID[0]
			ConsoleWrite("KILL: " & $g_aPID[$i] & " " & _WinAPI_GetProcessFileName($g_aPID[$i]) & @CRLF)
			ProcessClose($g_aPID[$i])
		Next
	EndIf
	ConsoleWrite("EXIT" & @CRLF)
	Exit
EndFunc
#endregion Funcs