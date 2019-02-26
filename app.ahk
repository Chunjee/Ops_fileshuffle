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
The_ProjectName := "fileshuffle"
The_VersionNumb := "1.1.0"

;Dependencies
#include %A_ScriptDir%\Lib
#include transformStringVars.ahk\export.ahk
#include util-array.ahk\export.ahk
#include json.ahk\export.ahk
#include wrappers.ahk\export.ahk
#include util-misc.ahk\export.ahk
#include logs.ahk\export.ahk

;/--\--/--\--/--\--/--\--/--\
; Global Vars
;\--/--\--/--\--/--\--/--\--/
;;File locations
Settings_FilePath := A_ScriptDir "\settings.json"
AllFiles_Array := []
Errors := []



;/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\
; StartUp
;\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/

;Check for CommandLineArguments
RawArgs = %1%
CL_Args := StrSplit(RawArgs,"|")
if (Fn_InArray(CL_Args,"auto")) {
	AUTOMODE := true
}
if (CL_Args.MaxIndex() > 0) {
	loop, % CL_Args.MaxIndex() {
		if (fn_QuickRegEx(CL_Args[A_Index],"(\d{8})") != "") {
			The_CustomDate := CL_Args[A_Index]
		}
	}
}


;;Import and parse settings file
FileRead, The_MemoryFile, % Settings_FilePath
Settings := JSON.parse(The_MemoryFile)
The_MemoryFile := ;blank
; Array_Gui(Settings)

;;Creat Logging obj
log := new Log_class(The_ProjectName "-" A_YYYY A_MM A_DD, Settings.logfiledir)
log.maxSizeMBLogFile_Default := 99 ;Set log Max size to 99 MB
log.application := The_ProjectName
log.preEntryString := "%A_NowUTC% -- "
log.initalizeNewLogFile(false, The_ProjectName " v" The_VersionNumb " log begins...`n")
log.add(The_ProjectName " launched from user " A_UserName " on the machine " A_ComputerName ". Version: v" The_VersionNumb)

;/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\
; MAIN
;\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/
;; Loop all config
Parse:
if (The_CustomDate != "") {
	FormatTime, The_Date, %The_CustomDate%000000, yyyyMMddhhmmss
} else {
	;; Make some special vars for config file date prediction
	Tomorrow := %A_Now%
	Tomorrow += 1, d
	The_Date := Tomorrow
}
FormatTime, TOM_DD, %The_Date%, dd
FormatTime, TOM_MM, %The_Date%, MM
FormatTime, TOM_YYYY, %The_Date%, yyyy
FormatTime, TOM_YY, %The_Date%, yyyy
TOM_YY := SubStr(TOM_YY, 3, 2)
;some other more obscure stuff
FormatTime, TOM_D, %The_Date%, d
FormatTime, TOM_M, %The_Date%, M
log.add("Executing for the following date: " TOM_YYYY TOM_MM TOM_DD)


Settings.exportPath := transformStringVars(Settings.exportPath)
;; New folder processing
if (Settings.parsing) {
	for key, value in Settings.parsing
	{
		;convert string in settings file to a fully qualifed var + string for searching
		searchdirstring := transformStringVars(value.dir "\*.*")
		if (value.recursive) {
			value.recursive := " R"
		}
		log.add(searchdirstring " is being searched for files")
		loop, Files, %searchdirstring%, % value.recursive
		{
			item := {}
			value.filepattern := transformStringVars(value.filepattern)
			RegExResult := fn_QuickRegEx(A_LoopFileName,value.filepattern)
			;if a filename matches the patern required
			if (RegExResult != false) {
				item.filename := A_LoopFileName
				item.filepath := A_LoopFileLongPath
				item.date := TOM_YYYY . TOM_MM . TOM_DD
				item.association := value.association
				item.destination := Settings.exportPath . item.filename
				;if this parser has an associated rename(s), loop and apply them all
				if (value.renames) {
					Loop, % value.renames.MaxIndex() {
						For Key1, Value1 in value.renames[A_Index]
						{
							item.changename := StrReplace(item.filename, Key1, Value1)
							item.destination := Settings.exportPath . item.changename
						}
					}
				}
				
				;; Insert data if it has a valid filepath
				if (item.filepath) {
					AllFiles_Array.push(item)
					log.add(A_LoopFileName " Added to list of files to be copied")
				} else {
					; do nothing
				}
			}
		}
	}
} else {
	msg("No .\settings.json file found`n`nThe application will quit.")
	log.add("Quit due to missing settings file.", "FATAL")
	log.finalizeLog(The_ProjectName . " log ends.")
	ExitApp, 1
}
Array_Gui(AllFiles_Array)
ExitApp


;/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\
; Move files
;\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/
; Array_Gui(AllFiles_Array)

FileCreateDir(Settings.exportPath)
loop, % AllFiles_Array.MaxIndex() {
	item := AllFiles_Array[A_Index]

	item.fileSizeOrigin	:= FileGetSize(item.filepath)
	item.fileSizeDest 	:= FileGetSize(item.destination)
	if (item.fileSizeOrigin = item.fileSizeDest) {
		replacefile_flag := 0
	} else {
		FileDelete(item.destination)
		Sleep 1000
		FileCopy(item.filepath, item.destination, 1)
	}
	if (ErrorLevel != 0) {
		;; log failure to copy file
		log.add(item.filename " failed to be copied to the destination folder '" Settings.exportPath "' `n This is often the result of a permissions issue.", "ERROR")
		Errors.push(1)
	} else {
		log.add(item.filename " moved to the destination folder with success")
	}
}



;/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\
; Report Generation
;\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/
; FileDelete, %Options_DBLocation%\DB.json
; loop, % AllFiles_Array.MaxIndex() {
	; BLANK ATM
; }
; FileAppend, %The_MemoryFile%, %Options_DBLocation%\DB.json

;/--\--/--\--/--\--/--\--/--\--/--\--/--\
; WrapUp
;\--/--\--/--\--/--\--/--\--/--\--/--\--/
if (Errors.MaxIndex() >= 1) {
	msg := Errors.MaxIndex() " Errors were encountered. Check logfiles for details at " Settings.logfiledir
	msg(msg)
	log.add(msg, "ERROR")
} else {
	log.add("All files moved without error.")
}

;Wrap up logs and Exit
log.finalizeLog(The_ProjectName . " log ends.")
ExitApp, 0

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

