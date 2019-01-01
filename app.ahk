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
#include logs.ahk\export.ahk

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

;;Creat Logging obj
log := new Log_class(The_ProjectName "-" A_YYYY A_MM A_DD, A_ScriptDir "\LogFiles")
log.maxSizeMBLogFile_Default := 99 ;Set log Max size to 99 MB
log.application := The_ProjectName
log.preEntryString := "%A_NowUTC% -- "
log.initalizeNewLogFile(false, The_ProjectName " v" The_VersionNumb " log begins...`n")
log.add(The_ProjectName " launched from user " A_UserName " on the machine " A_ComputerName ". Version: v" The_VersionNumb)

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
			if (RegExResult != false) {
				item.filename := A_LoopFileName
				item.filepath := A_LoopFileLongPath
				item.date := TOM_YYYY . TOM_MM . TOM_DD
				item.association := value.association
				
				;; Insert data if it has a valid date and filepath
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



;/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\
; Move files
;\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/
; Array_Gui(AllFiles_Array)
Settings.exportPath := transformStringVars(Settings.exportPath)
FileCreateDir(Settings.exportPath)
loop, % AllFiles_Array.MaxIndex() {
	item := AllFiles_Array[A_Index]
	FileCopy(item.filepath, Settings.exportPath item.filename)
	if (ErrorLevel != 0) {
		;; log failure to move file
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

