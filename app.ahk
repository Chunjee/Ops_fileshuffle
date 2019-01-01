;/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\
; Description
;\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/
; Moves files around

;~~~~~~~~~~~~~~~~~~~~~
;Compile Options
;~~~~~~~~~~~~~~~~~~~~~
SetBatchLines -1 ;Go as fast as CPU will allow
#NoTrayIcon
#SingleInstance force
The_ProjectName := "filemover"
The_VersionNumb := "0.0.1"

;Dependencies
#include %A_ScriptDir%\Lib
#include transformStringVars.ahk\export.ahk
#include util-array.ahk\export.ahk
#include json.ahk\export.ahk
#include wrappers.ahk\export.ahk
#include util-misc.ahk\export.ahk
#include biga.ahk\export.ahk

;/--\--/--\--/--\--/--\--/--\
; Global Vars
;\--/--\--/--\--/--\--/--\--/
Sb_GlobalNameSpace()
Sb_InstallFiles()
;;File locations
Settings_FilePath := A_ScriptDir "\settings.json"
AllFiles_Array := []
Errors := []

;; Make some special vars for config file date prediction
Tomorrow := %A_Now%
Tomorrow += 1, d
FormatTime, TOM_DD, %Tomorrow%, dd
FormatTime, TOM_MM, %Tomorrow%, MM
FormatTime, TOM_YYYY, %Tomorrow%, yyyy
FormatTime, TOM_YY, %Tomorrow%, yyyy
TOM_YY := SubStr(TOM_YY, 3, 2)

;/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\
; StartUp
;\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/

;Check for CommandLineArguments
CL_Args = StrSplit(1 , "|")
if (Fn_InArray(CL_Args,"auto")) {
	AUTOMODE := true
}

;;Import and parse settings file
FileRead, The_MemoryFile, % Settings_FilePath
Settings := JSON.parse(The_MemoryFile)
The_MemoryFile := ;blank

;/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\
; MAIN
;\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/
;; Loop all config
Parse:
FormatTime, Today, , yyyyMMdd

The_ListofDirs := Settings.dirs
The_ListofDirs.push(A_ScriptDir)

;; New folder processing
if (Settings.parsing) {
	for key, value in Settings.parsing
	{
		;convert string in settings file to a fully qualifed var + string for searching
		searchdirstring := transformStringVars(value.dir "\*.*")
		if (value.recursive) {
			value.recursive := " R"
		}
		loop, Files, %searchdirstring%, % value.recursive
		{
			item := {}
			value.filepattern := transformStringVars(value.filepattern)
			RegExResult := fn_QuickRegEx(A_LoopFileName,value.filepattern)
			; msgbox, % fn_QuickRegEx(A_LoopFileName,value.filepattern)
			if (RegExResult != false) {
				item.filename := A_LoopFileName
				item.filepath := A_LoopFileLongPath
				item.date := TOM_YYYY . TOM_MM . TOM_DD
				item.association := value.association
				
				;; Insert data if it has a valid date and filepath
				if (item.filepath) {
					AllFiles_Array.push(item)
				} else {
					; else is not handled in a seprate loop checking all files below
				}
			}
		}
	}
} else {
	msg("No .\settings.json file found`n`nThe application will quit")
	ExitApp
}



;/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\
; Move files
;\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/
Array_Gui(AllFiles_Array)
ExportPath := Settings.exportPath "\" TOM_MM "-" TOM_DD "-" TOM_YY "\"
Settings.exportPath := transformStringVars(Settings.exportPath)
FileCreateDir(ExportPath)
loop, % AllFiles_Array.MaxIndex() {
	item := AllFiles_Array[A_Index]
	FileCopy(item.filepath, Settings.exportPath item.filename)
	if (ErrorLevel != 0) {
		;; log failure to move file
		Errors.push(1)
	}
}



;/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\
; Report Generation
;\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/
FileDelete, %Options_DBLocation%\DB.json
loop, % AllFiles_Array.MaxIndex() {
	
}
FileAppend, %The_MemoryFile%, %Options_DBLocation%\DB.json


if (Errors.MaxIndex() >= 1) {
	msg(Errors.MaxIndex() " Errors were encountered. Check logfiles for details")
}

;/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\
; Subroutines
;\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/



;/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\
; Functions
;\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/

;Gets the timestamp out of a filename and converts it into a day of the week name
Fn_GetWeekName(para_String) ;Example Input: "20140730Scottsville"
{
	RegExMatch(para_String, "(\d{4})(\d{2})(\d{2})", RE_TimeStamp)
	if (RE_TimeStamp1 != "") {
		;dddd corresponds to Monday for example
		FormatTime, l_WeekdayName , %RE_TimeStamp1%%RE_TimeStamp2%%RE_TimeStamp3%, dddd
	}
	if (l_WeekdayName != "") {
		return l_WeekdayName
	} else {
		;throw error and return false if unsuccessful
		throw error
		return false
	}
}

;/--\--/--\--/--\--/--\--/--\
; GUI
;\--/--\--/--\--/--\--/--\--/


;/--\--/--\--/--\--/--\--/--\
; Subroutines
;\--/--\--/--\--/--\--/--\--/


;/--\--/--\--/--\--/--\--/--\
; Small functions
;\--/--\--/--\--/--\--/--\--/

