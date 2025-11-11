^K:: ; Hotkey: Ctrl + K
{	
	; Check if surrender mode is enabled
	IsSurrenderMode := CheckSurrenderMode()
	
	;Loops 25 times
	Loop, 25{
		; Loop 6 times for the full attack cycle
		Loop, 6 {
			If (IsSurrenderMode) {
				SurrenderModeAttackingLoop()
			} Else {
				AttackingLoop()
			}
        	Sleep, 5000 ; Wait 5 seconds before running again
    	}
		GetBuilderElixer()
	}
	MsgBox, Script Has ran its course, LOOT UP!
    return
}

GetBuilderElixer()
{
    ; Check if surrender mode is enabled
    IsSurrenderMode := CheckSurrenderMode()
    
    ; Check if game is already running (in surrender mode, game stays open)
    IfWinNotExist, ahk_exe crosvm.exe
    {
        ; Start up Clash of Clans if not running
        FileRead, clashLocation, clashOfClansFileLocation.txt
        Run, %clashLocation%
        
        ; Wait for the game window to appear and activate it
        WinWait, ahk_exe crosvm.exe
        WinActivate, ahk_exe crosvm.exe
        Sleep, 2000 ; Wait 2 seconds for window to be ready
        SetFullscreenIfNeeded() ; Check if fullscreen, if not press F11
        
        Sleep, 15000 ; Wait 20 seconds for Clash of Clans to load up
    }
    Else
    {
        ; Game is already running, just activate it
        WinActivate, ahk_exe crosvm.exe
        WinWaitActive, ahk_exe crosvm.exe, , 5
        Sleep, 1000 ; Small wait to ensure window is active
    }

    ImagePath := "PurpleCart.png"
    ImagePathCollect := "GreenColor.png"
    ImagePathRedClose := "RedClose.png"

    ; Get the window's position and size
    WinGetPos, WindowX, WindowY, WindowWidth, WindowHeight, ahk_exe crosvm.exe

	MouseMove, WindowWidth/2, WindowHeight/2 ;moves to a standardized position to scroll out correctly

	; Scroll down 5 times
    Loop, 10 {
        Send, {WheelDown}
        Sleep, 500 ; Sleep for half a second between scrolls
    }

	ImageSearch, FoundXPath, FoundYPath, WindowWidth * (5/8) , 0, WindowWidth, WindowHeight/4, *50 %ImagePath%
    ClickMouse(FoundXPath, FoundYPath)

	Sleep, 1000 ;wait for loot to be collected

    ImageSearch, FoundXPathCollect, FoundYPathCollect, WindowWidth /2 , WindowHeight * (3/4), WindowWidth, WindowHeight, *50 %ImagePathCollect%
    ClickMouse(FoundXPathCollect, FoundYPathCollect)

    Sleep, 1000
    
    ; If in surrender mode, search for and click RedClose after clicking GreenColor
    If (IsSurrenderMode)
    {
        ; Search for RedClose and click it
        ImageSearch, FoundXRedClose, FoundYRedClose, 0, 0, WindowWidth, WindowHeight, *50 %ImagePathRedClose%
        If (ErrorLevel = 0)
        {
            ClickMouse(FoundXRedClose, FoundYRedClose)
        }
        ; Note: We do NOT close the game in surrender mode
    }
    Else
    {
        ; Close Clash of Clans using process name (normal mode)
        WinKill, ahk_exe crosvm.exe ; Replace with the actual process name if different
    }
}

AttackingLoop()
{
    ; Start up Clash of Clans
    FileRead, clashLocation, clashOfClansFileLocation.txt
    Run, %clashLocation%
    
    ; Wait for the game window to appear and activate it
    WinWait, ahk_exe crosvm.exe
    WinActivate, ahk_exe crosvm.exe
    Sleep, 2000 ; Wait 2 seconds for window to be ready
    SetFullscreenIfNeeded() ; Check if fullscreen, if not press F11
    
    Sleep, 20000 ; Wait 20 seconds for Clash of Clans to load up

    ; Call the Attack function (pass false to use normal sleep)
    Attack(false)
    Sleep, 5000 ; Wait 5 seconds to enter attack screen
    SpamTroops()
    Sleep, 1000 ; Wait after spamming troops

    ; Close Clash of Clans using process name
    WinKill, ahk_exe crosvm.exe ; Replace with the actual process name if different
}

SpamTroops()
{    
    ; Get the window's position and size
    WinGetPos, WindowX, WindowY, WindowWidth, WindowHeight, ahk_exe crosvm.exe

    ; Scroll down 5 times
    Loop, 5 {
        Send, {WheelDown}
        Sleep, 500 ; Sleep for half a second between scrolls
    }
    
    ; Initial troop drop hero 
    Send, q ; q is what the hero bind is default
    Sleep, 1000 ; Wait 1 second before placing more troops
    ; Drop additional troops at random locations
    Loop, 5 {
        Random, randX, WindowWidth * (3/16), WindowWidth * (7/8) ; Get a random x-coordinate
        Random, randY, WindowHeight/4, WindowHeight * (3/4) ; Get a random y-coordinate
        ClickMouse(randX, randY)
        Sleep, 100 ; Wait 0.1 seconds between clicks
    }

	; Initial troop drop hero 
	;commented out for now as dont have hero on this account
    Send, 1 ; the default keybind for the troops
    Sleep, 1000 ; Wait 1 second before placing more troops
    ; Drop additional troops at random locations
    Loop, 15 {
        Random, randX, WindowWidth * (3/16), WindowWidth * (7/8) ; Get a random x-coordinate
        Random, randY, WindowHeight/4, WindowHeight * (3/4)  ; Get a random y-coordinate
        ClickMouse(randX, randY)
        Sleep, 100 ; Wait 0.1 seconds between clicks
    }
}

SurrenderModeAttackingLoop()
{
    ; Check if game is already running
    IfWinNotExist, ahk_exe crosvm.exe
    {
        ; Start up Clash of Clans if not running
        FileRead, clashLocation, clashOfClansFileLocation.txt
        Run, %clashLocation%
        
        ; Wait for the game window to appear and activate it
        WinWait, ahk_exe crosvm.exe, , 30
        WinActivate, ahk_exe crosvm.exe
        Sleep, 2000 ; Wait 2 seconds for window to be ready
        SetFullscreenIfNeeded() ; Check if fullscreen, if not press F11
        
        Sleep, 20000 ; Wait 20 seconds for Clash of Clans to load up
    }
    Else
    {
        ; Game is already running, just activate it and ensure it's ready
        WinActivate, ahk_exe crosvm.exe
        WinWaitActive, ahk_exe crosvm.exe, , 5
        Sleep, 1000 ; Small wait to ensure window is active
    }
    
    ; Call the Attack function with surrender mode flag (skip sleep)
    Attack(true)
    Sleep, 5000 ; Wait 5 seconds to enter attack screen
    SpamTroops()
    Sleep, 2000 ; Wait after spamming troops
    
    ; Surrender by finding and clicking the red surrender button
    Surrender()
    
    ; Wait for surrender to complete and return to base
    Sleep, 5000 ; Wait 5 seconds for surrender to process
    
    ; Note: We do NOT close the game in surrender mode, so it stays open for the next attack
}

Surrender()
{
    ; Path to surrender image
    ImagePathSurrender := "RedSurrender.png"
    ImagePathGreen := "GreenColor.png"
    
    ; Get the window's position and size
    WinGetPos, WindowX, WindowY, WindowWidth, WindowHeight, ahk_exe crosvm.exe
    
    ; Search for the red surrender button (search in the bottom area where surrender button typically appears)
    ImageSearch, FoundXSurrender, FoundYSurrender, 0, WindowHeight * (2/3), WindowWidth, WindowHeight, *50 %ImagePathSurrender%
    
    ; Click the surrender button if found
    If (ErrorLevel = 0)
    {
        ClickMouse(FoundXSurrender, FoundYSurrender)
        Sleep, 1000 ; Wait for surrender dialog/confirmation to appear
    }
    Else
    {
        ; If not found, try searching in a different area or wait a bit more
        Sleep, 1000
        ImageSearch, FoundXSurrender, FoundYSurrender, 0, 0, WindowWidth, WindowHeight, *50 %ImagePathSurrender%
        If (ErrorLevel = 0)
        {
            ClickMouse(FoundXSurrender, FoundYSurrender)
            Sleep, 1000 ; Wait for surrender dialog/confirmation to appear
        }
    }
    
    ; After clicking surrender, search for GreenColor and click it (first time)
    Sleep, 1000 ; Small wait for UI to update
    ImageSearch, FoundXGreen, FoundYGreen, 0, 0, WindowWidth, WindowHeight, *50 %ImagePathGreen%
    If (ErrorLevel = 0)
    {
        ClickMouse(FoundXGreen, FoundYGreen)
        Sleep, 1000 ; Wait for UI to update after first click
        
        ; Check for GreenColor again and click it (second time)
        ImageSearch, FoundXGreen2, FoundYGreen2, 0, 0, WindowWidth, WindowHeight, *50 %ImagePathGreen%
        If (ErrorLevel = 0)
        {
            ClickMouse(FoundXGreen2, FoundYGreen2)
        }
    }
}

CheckSurrenderMode()
{
    ; Default to false if config file doesn't exist or doesn't contain the setting
    SurrenderMode := false
    
    ; Check if config.txt exists
    IfExist, config.txt
    {
        ; Read the config file
        FileRead, configContent, config.txt
        
        ; Check if surrenderMode=true is in the file (case-insensitive)
        IfInString, configContent, surrenderMode=true
        {
            SurrenderMode := true
        }
    }
    
    Return SurrenderMode
}

Attack(SkipSleep)
{
    ;Path to my image
	ImagePathAttack := "greyToStartAttack.png"
    ImagePathFindNow := "GreenColor.png"

    ; Get the window's position and size
    WinGetPos, WindowX, WindowY, WindowWidth, WindowHeight, ahk_exe crosvm.exe

	; preform a image search
	ImageSearch, FoundX, FoundY, 0, WindowHeight - 250, 250, WindowHeight, *50 %ImagePathAttack%
    ; Only click if the image was found (ErrorLevel = 0 means success)
    If (ErrorLevel = 0)
    {
        ClickMouse(FoundX, FoundY)
    }
    Sleep 1000
    ; Only sleep if not in surrender mode (SkipSleep will be empty/false if not provided)
    If (SkipSleep != true)
    {
        Sleep, 12000 ; Wait 12 seconds between clicking attack button and clicking "Find Now"
    }

    ImageSearch, FoundXPath, FoundYPath, (WindowWidth/3)*2 , 0, WindowWidth, WindowHeight, *50 %ImagePathFindNow%
    ClickMouse(FoundXPath, FoundYPath)
}

SetFullscreenIfNeeded()
{
    ; Get the window's position and size
    WinGetPos, WindowX, WindowY, WindowWidth, WindowHeight, ahk_exe crosvm.exe
    
    ; Get screen resolution
    ScreenWidth := A_ScreenWidth
    ScreenHeight := A_ScreenHeight
    
    ; Check if window is in fullscreen mode
    ; Fullscreen typically means window covers the entire screen (allowing small margin for error)
    ; We check if window is at position 0,0 and matches screen dimensions (within 10 pixels tolerance)
    Tolerance := 10
    IsFullscreen := (WindowX <= Tolerance) && (WindowY <= Tolerance) && (Abs(WindowWidth - ScreenWidth) <= Tolerance) && (Abs(WindowHeight - ScreenHeight) <= Tolerance)
    
    ; If not in fullscreen, press F11 to toggle fullscreen
    If (!IsFullscreen)
    {
        Send, {F11}
        Sleep, 500 ; Wait a bit for fullscreen transition
    }
}

ClickMouse(x, y)
{
    MouseMove, %x%, %y% ; Move the mouse to (x, y)
    Sleep, 100 ; Wait for the mouse to get in position
    Click, left, 1 ; Single left-click at current position (1 click)
}

; Define the function to exit the script early
^E::EndScript() ; Ctrl+E to end the script

EndScript()
{
    MsgBox, Script is ending now. Goodbye!
    ExitApp
}
