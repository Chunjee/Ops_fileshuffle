#NoTrayIcon

assert := new unittesting()

;Test nothing
assert.test(1,1)


assert.fullreport()
ExitApp

#Include app.ahk
#Include %A_ScriptDir%\Lib\unit-testing.ahk\export.ahk
