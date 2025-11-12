; Global variables for progress tracking and restart
Global LastProgressTime := 0
Global ShouldRestart := false
Global MaxStuckTime := 180000 ; 3 minutes in milliseconds (180 seconds)

; Global variables for debug console
Global ConsoleGui := ""
Global ConsoleEditHwnd := ""
Global ConsoleVisible := false
Global IsDebugMode := false

^K:: ; Hotkey: Ctrl + K
{	
	; Check if debug mode is enabled and initialize console
	IsDebugMode := CheckDebugMode()
	If (IsDebugMode)
	{
		CreateConsole()
		DebugLog("Script started - Debug mode enabled")
	}
	
	; Reset restart flag
	ShouldRestart := false
	
	; Initialize progress tracking
	LastProgressTime := A_TickCount
	
	; Start the main attack loop
	RunMainAttackLoop()
	return
}

RunMainAttackLoop()
{
	Global ShouldRestart
	Global LastProgressTime
	
	; Check if surrender mode is enabled
	IsSurrenderMode := CheckSurrenderMode()
	DebugLog("Starting main attack loop. Surrender mode: " . (IsSurrenderMode ? "enabled" : "disabled"))
	
	;Loops 25 times
	Loop, 25{
		DebugLog("Outer loop iteration: " . A_Index . " / 25")
		
		; Check if manual restart was triggered
		If (ShouldRestart)
		{
			DebugLogWarning("Manual restart triggered")
			MsgBox, Restarting script...
			ShouldRestart := false
			LastProgressTime := A_TickCount
			; Restart from beginning by calling the function again
			RunMainAttackLoop()
			return
		}
		
		; Check if script is stuck (no progress detected)
		If (CheckIfStuck())
		{
			DebugLogError("Script appears to be stuck - restarting")
			MsgBox, Script appears to be stuck. Restarting...
			ShouldRestart := false
			LastProgressTime := A_TickCount
			; Restart from beginning
			RunMainAttackLoop()
			return
		}
		
		; Loop 6 times for the full attack cycle
		Loop, 6 {
			DebugLog("Inner loop iteration: " . A_Index . " / 6")
			
			; Check if manual restart was triggered
			If (ShouldRestart)
			{
				DebugLogWarning("Manual restart triggered during attack cycle")
				MsgBox, Restarting script...
				ShouldRestart := false
				LastProgressTime := A_TickCount
				; Restart immediately
				RunMainAttackLoop()
				return
			}
			
			; Check if script is stuck
			If (CheckIfStuck())
			{
				DebugLogError("Script appears to be stuck during attack cycle - restarting")
				MsgBox, Script appears to be stuck. Restarting...
				ShouldRestart := false
				LastProgressTime := A_TickCount
				; Restart immediately
				RunMainAttackLoop()
				return
			}
			
			If (IsSurrenderMode) {
				DebugLog("Starting surrender mode attack loop")
				SurrenderModeAttackingLoop()
			} Else {
				DebugLog("Starting normal attack loop")
				AttackingLoop()
			}
			
			; Update progress time after each attack
			UpdateProgress()
			DebugLog("Attack cycle " . A_Index . " completed, waiting 5 seconds")
        	Sleep, 5000 ; Wait 5 seconds before running again
    	}
		
		DebugLog("Starting builder elixir collection")
		GetBuilderElixer()
		; Update progress time after collecting elixir
		UpdateProgress()
		DebugLog("Builder elixir collection completed")
	}
	DebugLog("Main attack loop completed - all 25 iterations finished")
	MsgBox, Script Has ran its course, LOOT UP!
	return
}

GetBuilderElixer()
{
    ; Check if surrender mode is enabled
    IsSurrenderMode := CheckSurrenderMode()
    DebugLog("GetBuilderElixer: Surrender mode = " . (IsSurrenderMode ? "enabled" : "disabled"))
    
    ; Check if game is already running (in surrender mode, game stays open)
    IfWinNotExist, ahk_exe crosvm.exe
    {
        DebugLog("Game window not found - starting Clash of Clans")
        ; Start up Clash of Clans if not running
        FileRead, clashLocation, clashOfClansFileLocation.txt
        If (ErrorLevel != 0)
        {
            DebugLogError("Failed to read clashOfClansFileLocation.txt")
        }
        Else
        {
            DebugLog("Starting game from: " . clashLocation)
            Run, %clashLocation%
        }
        
        ; Wait for the game window to appear and activate it
        DebugLog("Waiting for game window to appear...")
        WinWait, ahk_exe crosvm.exe
        WinActivate, ahk_exe crosvm.exe
        Sleep, 2000 ; Wait 2 seconds for window to be ready
        SetFullscreenIfNeeded() ; Check if fullscreen, if not press F11
        UpdateProgress() ; Update progress after game starts
        DebugLog("Game window activated, waiting 15 seconds for load")
        
        Sleep, 15000 ; Wait 20 seconds for Clash of Clans to load up
    }
    Else
    {
        DebugLog("Game window already exists - activating")
        ; Game is already running, just activate it
        WinActivate, ahk_exe crosvm.exe
        WinWaitActive, ahk_exe crosvm.exe, , 5
        If (ErrorLevel != 0)
        {
            DebugLogError("Failed to activate game window")
        }
        Else
        {
            DebugLog("Game window activated successfully")
        }
        Sleep, 1000 ; Small wait to ensure window is active
        UpdateProgress() ; Update progress after activating game
    }

    ImagePath := "PurpleCart.png"
    ImagePathCollect := "GreenColor.png"
    ImagePathRedClose := "RedClose.png"

    ; Get the window's position and size
    WinGetPos, WindowX, WindowY, WindowWidth, WindowHeight, ahk_exe crosvm.exe
    DebugLog("Window position: X=" . WindowX . " Y=" . WindowY . " W=" . WindowWidth . " H=" . WindowHeight)

	MouseMove, WindowWidth/2, WindowHeight/2 ;moves to a standardized position to scroll out correctly
	DebugLog("Mouse moved to center position for scrolling")

	; Scroll down 5 times
    Loop, 10 {
        Send, {WheelDown}
        Sleep, 500 ; Sleep for half a second between scrolls
    }
    DebugLog("Scrolled down 10 times")

	ImageSearch, FoundXPath, FoundYPath, WindowWidth * (5/8) , 0, WindowWidth, WindowHeight/4, *50 %ImagePath%
    If (ErrorLevel = 0)
    {
        DebugLog("PurpleCart found at X=" . FoundXPath . " Y=" . FoundYPath)
        ClickMouse(FoundXPath, FoundYPath)
        UpdateProgress() ; Update progress after clicking cart
    }
    Else
    {
        DebugLogError("PurpleCart image not found")
    }

	Sleep, 1000 ;wait for loot to be collected

    ImageSearch, FoundXPathCollect, FoundYPathCollect, WindowWidth /2 , WindowHeight * (3/4), WindowWidth, WindowHeight, *50 %ImagePathCollect%
    If (ErrorLevel = 0)
    {
        DebugLog("GreenColor (collect) found at X=" . FoundXPathCollect . " Y=" . FoundYPathCollect)
        ClickMouse(FoundXPathCollect, FoundYPathCollect)
        UpdateProgress() ; Update progress after collecting loot
    }
    Else
    {
        DebugLogError("GreenColor (collect) image not found")
    }

    Sleep, 1000
    
    ; If in surrender mode, search for and click RedClose after clicking GreenColor
    If (IsSurrenderMode)
    {
        DebugLog("Surrender mode: Searching for RedClose button")
        ; Search for RedClose and click it
        ImageSearch, FoundXRedClose, FoundYRedClose, 0, 0, WindowWidth, WindowHeight, *50 %ImagePathRedClose%
        If (ErrorLevel = 0)
        {
            DebugLog("RedClose found at X=" . FoundXRedClose . " Y=" . FoundYRedClose)
            ClickMouse(FoundXRedClose, FoundYRedClose)
        }
        Else
        {
            DebugLogWarning("RedClose image not found")
        }
        ; Note: We do NOT close the game in surrender mode
    }
    Else
    {
        DebugLog("Normal mode: Closing game")
        ; Close Clash of Clans using process name (normal mode)
        WinKill, ahk_exe crosvm.exe ; Replace with the actual process name if different
        DebugLog("Game closed")
    }
    UpdateProgress() ; Update progress after finishing elixir collection
    DebugLog("GetBuilderElixer completed")
}

AttackingLoop()
{
    DebugLog("=== Starting AttackingLoop ===")
    ; Start up Clash of Clans
    FileRead, clashLocation, clashOfClansFileLocation.txt
    If (ErrorLevel != 0)
    {
        DebugLogError("Failed to read clashOfClansFileLocation.txt")
    }
    Else
    {
        DebugLog("Starting game from: " . clashLocation)
        Run, %clashLocation%
    }
    
    ; Wait for the game window to appear and activate it
    DebugLog("Waiting for game window...")
    WinWait, ahk_exe crosvm.exe
    WinActivate, ahk_exe crosvm.exe
    Sleep, 2000 ; Wait 2 seconds for window to be ready
    SetFullscreenIfNeeded() ; Check if fullscreen, if not press F11
    UpdateProgress() ; Update progress after game starts
    DebugLog("Game started, waiting 20 seconds for load")
    
    Sleep, 20000 ; Wait 20 seconds for Clash of Clans to load up

    ; Call the Attack function (pass false to use normal sleep)
    DebugLog("Initiating attack")
    Attack(false)
    UpdateProgress() ; Update progress after initiating attack
    Sleep, 5000 ; Wait 5 seconds to enter attack screen
    DebugLog("Deploying troops")
    SpamTroops()
    UpdateProgress() ; Update progress after deploying troops
    Sleep, 1000 ; Wait after spamming troops

    ; Close Clash of Clans using process name
    DebugLog("Closing game")
    WinKill, ahk_exe crosvm.exe ; Replace with the actual process name if different
    UpdateProgress() ; Update progress after closing game
    DebugLog("=== AttackingLoop completed ===")
}

SpamTroops()
{    
    DebugLog("SpamTroops: Starting troop deployment")
    ; Get the window's position and size
    WinGetPos, WindowX, WindowY, WindowWidth, WindowHeight, ahk_exe crosvm.exe
    DebugLog("SpamTroops: Window size W=" . WindowWidth . " H=" . WindowHeight)

    ; Scroll down 5 times
    DebugLog("SpamTroops: Scrolling down 5 times")
    Loop, 5 {
        Send, {WheelDown}
        Sleep, 500 ; Sleep for half a second between scrolls
    }
    
    ; Initial troop drop hero 
    DebugLog("SpamTroops: Sending hero key (q)")
    Send, q ; q is what the hero bind is default
    Sleep, 1000 ; Wait 1 second before placing more troops
    ; Drop additional troops at random locations
    DebugLog("SpamTroops: Dropping 5 hero troops at random locations")
    Loop, 5 {
        Random, randX, WindowWidth * (3/16), WindowWidth * (7/8) ; Get a random x-coordinate
        Random, randY, WindowHeight/4, WindowHeight * (3/4) ; Get a random y-coordinate
        DebugLog("SpamTroops: Hero troop drop " . A_Index . " at X=" . randX . " Y=" . randY)
        ClickMouse(randX, randY)
        Sleep, 100 ; Wait 0.1 seconds between clicks
    }

	; Initial troop drop hero 
	;commented out for now as dont have hero on this account
    DebugLog("SpamTroops: Sending troop key (1)")
    Send, 1 ; the default keybind for the troops
    Sleep, 1000 ; Wait 1 second before placing more troops
    ; Drop additional troops at random locations
    DebugLog("SpamTroops: Dropping 15 troops at random locations")
    Loop, 15 {
        Random, randX, WindowWidth * (3/16), WindowWidth * (7/8) ; Get a random x-coordinate
        Random, randY, WindowHeight/4, WindowHeight * (3/4)  ; Get a random y-coordinate
        DebugLog("SpamTroops: Troop drop " . A_Index . " at X=" . randX . " Y=" . randY)
        ClickMouse(randX, randY)
        Sleep, 100 ; Wait 0.1 seconds between clicks
    }
    DebugLog("SpamTroops: Completed")
}

SurrenderModeAttackingLoop()
{
    DebugLog("=== Starting SurrenderModeAttackingLoop ===")
    ; Check if game is already running
    IfWinNotExist, ahk_exe crosvm.exe
    {
        DebugLog("SurrenderMode: Game window not found - starting Clash of Clans")
        ; Start up Clash of Clans if not running
        FileRead, clashLocation, clashOfClansFileLocation.txt
        If (ErrorLevel != 0)
        {
            DebugLogError("SurrenderMode: Failed to read clashOfClansFileLocation.txt")
        }
        Else
        {
            DebugLog("SurrenderMode: Starting game from: " . clashLocation)
            Run, %clashLocation%
        }
        
        ; Wait for the game window to appear and activate it
        DebugLog("SurrenderMode: Waiting for game window (30s timeout)...")
        WinWait, ahk_exe crosvm.exe, , 30
        If (ErrorLevel != 0)
        {
            DebugLogError("SurrenderMode: Game window did not appear within 30 seconds")
        }
        WinActivate, ahk_exe crosvm.exe
        Sleep, 2000 ; Wait 2 seconds for window to be ready
        SetFullscreenIfNeeded() ; Check if fullscreen, if not press F11
        UpdateProgress() ; Update progress after game starts
        DebugLog("SurrenderMode: Game started, waiting 20 seconds for load")
        
        Sleep, 20000 ; Wait 20 seconds for Clash of Clans to load up
    }
    Else
    {
        DebugLog("SurrenderMode: Game window already exists - activating")
        ; Game is already running, just activate it and ensure it's ready
        WinActivate, ahk_exe crosvm.exe
        WinWaitActive, ahk_exe crosvm.exe, , 5
        If (ErrorLevel != 0)
        {
            DebugLogError("SurrenderMode: Failed to activate game window")
        }
        Else
        {
            DebugLog("SurrenderMode: Game window activated successfully")
        }
        Sleep, 1000 ; Small wait to ensure window is active
        UpdateProgress() ; Update progress after activating game
    }
    
    ; Call the Attack function with surrender mode flag (skip sleep)
    DebugLog("SurrenderMode: Initiating attack")
    Attack(true)
    UpdateProgress() ; Update progress after initiating attack
    Sleep, 5000 ; Wait 5 seconds to enter attack screen
    DebugLog("SurrenderMode: Deploying troops")
    SpamTroops()
    UpdateProgress() ; Update progress after deploying troops
    Sleep, 2000 ; Wait after spamming troops
    
    ; Surrender by finding and clicking the red surrender button
    DebugLog("SurrenderMode: Starting surrender process")
    Surrender()
    UpdateProgress() ; Update progress after surrendering
    
    ; Wait for surrender to complete and return to base
    DebugLog("SurrenderMode: Waiting 5 seconds for surrender to process")
    Sleep, 5000 ; Wait 5 seconds for surrender to process
    
    ; Note: We do NOT close the game in surrender mode, so it stays open for the next attack
    DebugLog("=== SurrenderModeAttackingLoop completed ===")
}

Surrender()
{
    DebugLog("Surrender: Starting surrender process")
    ; Path to surrender image
    ImagePathSurrender := "RedSurrender.png"
    ImagePathGreen := "GreenColor.png"
    
    ; Get the window's position and size
    WinGetPos, WindowX, WindowY, WindowWidth, WindowHeight, ahk_exe crosvm.exe
    DebugLog("Surrender: Window size W=" . WindowWidth . " H=" . WindowHeight)
    
    ; Search for the red surrender button (search in the bottom area where surrender button typically appears)
    DebugLog("Surrender: Searching for RedSurrender button in bottom area")
    ImageSearch, FoundXSurrender, FoundYSurrender, 0, WindowHeight * (2/3), WindowWidth, WindowHeight, *50 %ImagePathSurrender%
    
    ; Click the surrender button if found
    If (ErrorLevel = 0)
    {
        DebugLog("Surrender: RedSurrender found at X=" . FoundXSurrender . " Y=" . FoundYSurrender)
        ClickMouse(FoundXSurrender, FoundYSurrender)
        Sleep, 1000 ; Wait for surrender dialog/confirmation to appear
    }
    Else
    {
        DebugLogWarning("Surrender: RedSurrender not found in bottom area, trying full screen")
        ; If not found, try searching in a different area or wait a bit more
        Sleep, 1000
        ImageSearch, FoundXSurrender, FoundYSurrender, 0, 0, WindowWidth, WindowHeight, *50 %ImagePathSurrender%
        If (ErrorLevel = 0)
        {
            DebugLog("Surrender: RedSurrender found at X=" . FoundXSurrender . " Y=" . FoundYSurrender . " (full screen search)")
            ClickMouse(FoundXSurrender, FoundYSurrender)
            Sleep, 1000 ; Wait for surrender dialog/confirmation to appear
        }
        Else
        {
            DebugLogError("Surrender: RedSurrender button not found anywhere")
        }
    }
    
    ; After clicking surrender, search for GreenColor and click it (first time)
    Sleep, 1000 ; Small wait for UI to update
    DebugLog("Surrender: Searching for GreenColor confirmation button (first click)")
    ImageSearch, FoundXGreen, FoundYGreen, 0, 0, WindowWidth, WindowHeight, *50 %ImagePathGreen%
    If (ErrorLevel = 0)
    {
        DebugLog("Surrender: GreenColor found at X=" . FoundXGreen . " Y=" . FoundYGreen . " (first click)")
        ClickMouse(FoundXGreen, FoundYGreen)
        Sleep, 1000 ; Wait for UI to update after first click
        
        ; Check for GreenColor again and click it (second time)
        DebugLog("Surrender: Searching for GreenColor confirmation button (second click)")
        ImageSearch, FoundXGreen2, FoundYGreen2, 0, 0, WindowWidth, WindowHeight, *50 %ImagePathGreen%
        If (ErrorLevel = 0)
        {
            DebugLog("Surrender: GreenColor found at X=" . FoundXGreen2 . " Y=" . FoundYGreen2 . " (second click)")
            ClickMouse(FoundXGreen2, FoundYGreen2)
        }
        Else
        {
            DebugLogWarning("Surrender: GreenColor not found for second click")
        }
    }
    Else
    {
        DebugLogError("Surrender: GreenColor confirmation button not found")
    }
    DebugLog("Surrender: Surrender process completed")
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

CheckDebugMode()
{
    ; Default to false if config file doesn't exist or doesn't contain the setting
    DebugMode := false
    
    ; Check if config.txt exists
    IfExist, config.txt
    {
        ; Read the config file
        FileRead, configContent, config.txt
        
        ; Check if debugMode=true is in the file (case-insensitive)
        IfInString, configContent, debugMode=true
        {
            DebugMode := true
        }
    }
    
    Return DebugMode
}

Attack(SkipSleep)
{
    DebugLog("Attack: Starting attack sequence. SkipSleep=" . (SkipSleep ? "true" : "false"))
    ;Path to my image
	ImagePathAttack := "greyToStartAttack.png"
    ImagePathFindNow := "GreenColor.png"

    ; Get the window's position and size
    WinGetPos, WindowX, WindowY, WindowWidth, WindowHeight, ahk_exe crosvm.exe
    DebugLog("Attack: Window size W=" . WindowWidth . " H=" . WindowHeight)

	; preform a image search
	DebugLog("Attack: Searching for greyToStartAttack button")
	ImageSearch, FoundX, FoundY, 0, WindowHeight - 250, 250, WindowHeight, *50 %ImagePathAttack%
    ; Only click if the image was found (ErrorLevel = 0 means success)
    If (ErrorLevel = 0)
    {
        DebugLog("Attack: greyToStartAttack found at X=" . FoundX . " Y=" . FoundY)
        ClickMouse(FoundX, FoundY)
    }
    Else
    {
        DebugLogError("Attack: greyToStartAttack button not found")
    }
    Sleep 1000
    ; Only sleep if not in surrender mode (SkipSleep will be empty/false if not provided)
    If (SkipSleep != true)
    {
        DebugLog("Attack: Waiting 12 seconds before Find Now")
        Sleep, 12000 ; Wait 12 seconds between clicking attack button and clicking "Find Now"
    }
    Else
    {
        DebugLog("Attack: SkipSleep enabled - skipping 12 second wait")
    }

    DebugLog("Attack: Searching for GreenColor (Find Now) button")
    ImageSearch, FoundXPath, FoundYPath, (WindowWidth/3)*2 , 0, WindowWidth, WindowHeight, *50 %ImagePathFindNow%
    If (ErrorLevel = 0)
    {
        DebugLog("Attack: GreenColor (Find Now) found at X=" . FoundXPath . " Y=" . FoundYPath)
        ClickMouse(FoundXPath, FoundYPath)
    }
    Else
    {
        DebugLogError("Attack: GreenColor (Find Now) button not found")
    }
    DebugLog("Attack: Attack sequence completed")
}

SetFullscreenIfNeeded()
{
    DebugLog("SetFullscreenIfNeeded: Checking fullscreen status")
    ; Get the window's position and size
    WinGetPos, WindowX, WindowY, WindowWidth, WindowHeight, ahk_exe crosvm.exe
    
    ; Get screen resolution
    ScreenWidth := A_ScreenWidth
    ScreenHeight := A_ScreenHeight
    DebugLog("SetFullscreenIfNeeded: Window=" . WindowWidth . "x" . WindowHeight . " Screen=" . ScreenWidth . "x" . ScreenHeight)
    
    ; Check if window is in fullscreen mode
    ; Fullscreen typically means window covers the entire screen (allowing small margin for error)
    ; We check if window is at position 0,0 and matches screen dimensions (within 10 pixels tolerance)
    Tolerance := 10
    IsFullscreen := (WindowX <= Tolerance) && (WindowY <= Tolerance) && (Abs(WindowWidth - ScreenWidth) <= Tolerance) && (Abs(WindowHeight - ScreenHeight) <= Tolerance)
    
    ; If not in fullscreen, press F11 to toggle fullscreen
    If (!IsFullscreen)
    {
        DebugLog("SetFullscreenIfNeeded: Not in fullscreen - pressing F11")
        Send, {F11}
        Sleep, 500 ; Wait a bit for fullscreen transition
        DebugLog("SetFullscreenIfNeeded: F11 pressed, waiting for transition")
    }
    Else
    {
        DebugLog("SetFullscreenIfNeeded: Already in fullscreen mode")
    }
}

ClickMouse(x, y)
{
    DebugLog("ClickMouse: Moving to X=" . x . " Y=" . y)
    MouseMove, %x%, %y% ; Move the mouse to (x, y)
    Sleep, 100 ; Wait for the mouse to get in position
    Click, left, 1 ; Single left-click at current position (1 click)
    DebugLog("ClickMouse: Clicked at X=" . x . " Y=" . y)
}

; Define the function to exit the script early
^E::EndScript() ; Ctrl+E to end the script

EndScript()
{
    MsgBox, Script is ending now. Goodbye!
    ExitApp
}

; Manual restart hotkey (CTRL+R)
^R::ManualRestart() ; Ctrl+R to manually restart

ManualRestart()
{
    Global ShouldRestart
    ShouldRestart := true
    DebugLogWarning("Manual restart triggered by user (CTRL+R)")
    MsgBox, Manual restart triggered. Script will restart on next check.
}

; Update progress timestamp
UpdateProgress()
{
    Global LastProgressTime
    LastProgressTime := A_TickCount
}

; Check if script is stuck (no progress for MaxStuckTime)
CheckIfStuck()
{
    Global LastProgressTime
    Global MaxStuckTime
    
    ; If LastProgressTime is 0, we haven't started yet
    If (LastProgressTime = 0)
    {
        Return false
    }
    
    ; Calculate time since last progress
    CurrentTime := A_TickCount
    TimeSinceLastProgress := CurrentTime - LastProgressTime
    TimeSinceLastProgressSeconds := Round(TimeSinceLastProgress / 1000)
    
    ; Also check if game window is still active/responsive
    IfWinNotExist, ahk_exe crosvm.exe
    {
        ; Game window doesn't exist - might be stuck
        ; But only consider it stuck if we've been waiting a while
        If (TimeSinceLastProgress > MaxStuckTime)
        {
            DebugLogError("CheckIfStuck: Script stuck - no progress for " . TimeSinceLastProgressSeconds . " seconds, game window not found")
            Return true
        }
        Else
        {
            DebugLog("CheckIfStuck: No progress for " . TimeSinceLastProgressSeconds . " seconds, but within tolerance. Game window not found.")
        }
    }
    Else
    {
        ; Check if window is responding
        WinGet, WinState, MinMax, ahk_exe crosvm.exe
        ; If window exists but we haven't made progress in a while, consider stuck
        If (TimeSinceLastProgress > MaxStuckTime)
        {
            DebugLogError("CheckIfStuck: Script stuck - no progress for " . TimeSinceLastProgressSeconds . " seconds, game window exists but no progress")
            Return true
        }
        Else
        {
            DebugLog("CheckIfStuck: No progress for " . TimeSinceLastProgressSeconds . " seconds, but within tolerance. Game window exists.")
        }
    }
    
    Return false
}

; ============================================
; DEBUG CONSOLE FUNCTIONS
; ============================================

; Create and show console window
CreateConsole()
{
    Global ConsoleGui
    Global ConsoleEdit
    Global ConsoleVisible
    
    If (ConsoleVisible)
    {
        Return ; Console already exists
    }
    
    ; Create GUI window
    Gui, Console:Add, Edit, x10 y10 w800 h500 ReadOnly VConsoleEdit Multi HScroll
    Gui, Console:Add, Button, x10 y520 w100 h30 gClearConsole, Clear
    Gui, Console:Add, Button, x120 y520 w100 h30 gCloseConsole, Close
    Gui, Console:Show, w830 h560, Script Debug Console
    Gui, Console:Submit, NoHide
    ; Get the HWND of the ConsoleEdit control for scrolling
    GuiControlGet, ConsoleEditHwnd, Console:Hwnd, ConsoleEdit
    
    ConsoleVisible := true
    DebugLog("Debug console opened")
}

; Close console window
CloseConsole()
{
    Global ConsoleVisible
    Gui, Console:Destroy
    ConsoleVisible := false
}

; Clear console content
ClearConsole()
{
    Global ConsoleEdit
    GuiControl, Console:, ConsoleEdit, 
    DebugLog("Console cleared")
}

; Log a message to console (only if debug mode is enabled)
DebugLog(Message, Level := "INFO")
{
    Global ConsoleEdit
    Global ConsoleVisible
    Global IsDebugMode
    
    ; Only log if debug mode is enabled
    If (!IsDebugMode)
    {
        Return
    }
    
    ; Format timestamp
    FormatTime, TimeString, , yyyy-MM-dd HH:mm:ss
    
    ; Format log entry
    LogEntry := "[" . TimeString . "] [" . Level . "] " . Message . "`r`n"
    
    ; Append to console if visible
    If (ConsoleVisible)
    {
        GuiControlGet, CurrentText, Console:, ConsoleEdit
        NewText := CurrentText . LogEntry
        ; Keep only last 2000 lines to prevent memory issues
        StringSplit, Lines, NewText, `n
        If (Lines0 > 2000)
        {
            ; Remove oldest lines
            Loop, % (Lines0 - 2000)
            {
                StringGetPos, Pos, NewText, `n, , 1
                StringTrimLeft, NewText, NewText, % (Pos + 1)
            }
        }
        GuiControl, Console:, ConsoleEdit, %NewText%
        ; Auto-scroll to bottom
        If (ConsoleEditHwnd != "")
        {
            SendMessage, 0x115, 7, 0, , ahk_id %ConsoleEditHwnd% ; WM_VSCROLL, SB_BOTTOM
        }
    }
}

; Log an error message
DebugLogError(Message)
{
    DebugLog(Message, "ERROR")
}

; Log a warning message
DebugLogWarning(Message)
{
    DebugLog(Message, "WARNING")
}
