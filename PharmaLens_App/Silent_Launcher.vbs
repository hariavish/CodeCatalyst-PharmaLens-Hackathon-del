Set WshShell = CreateObject("WScript.Shell")

' 1. Launch the batch file completely invisibly (0 means hide window)
WshShell.Run chr(34) & "Boot_PharmaLens.bat" & Chr(34), 0, False

' 2. Wait a few seconds to ensure the Python server has fully started
WScript.Sleep 3000

' 3. Automatically open the login page in the user's default web browser
WshShell.Run "login.html"

Set WshShell = Nothing