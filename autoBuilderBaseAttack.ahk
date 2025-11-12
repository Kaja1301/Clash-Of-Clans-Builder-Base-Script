; Global variables for progress tracking and restart
Global LastProgressTime := 0
Global ShouldRestart := false
Global MaxStuckTime := 180000 ; 3 minutes in milliseconds (180 seconds)

; Global variables for GUI and pause state
Global IsPaused := false
Global IsRunning := false
Global CurrentMode := "Normal Mode"
Global MainGuiVisible := false

; Global variables for debug console
Global ConsoleEditHwnd := ""
Global ConsoleVisible := false
Global IsDebugMode := false

; Initialize GUI on script start
IsDebugMode := CheckDebugMode()
CreateMainGui()

RunMainAttackLoop(Mode)
{
	Global ShouldRestart
	Global LastProgressTime
	Global IsPaused
	Global CurrentMode
	
	; Determine if surrender mode based on Mode parameter
	IsSurrenderMode := (Mode = "Surrender Mode")
	DebugLog("Starting main attack loop. Mode: " . Mode)
	
	;Loops 25 times
	Loop, 25{
		DebugLog("Outer loop iteration: " . A_Index . " / 25")
		
		; Check if paused
		While (IsPaused)
		{
			Sleep, 100
		}
		
		; Check if script should stop
		If (!IsRunning)
		{
			DebugLog("Script stopped by user")
			UpdateStatus("Stopped")
			return
		}
		
		; Check if manual restart was triggered
		If (ShouldRestart)
		{
			DebugLogWarning("Manual restart triggered")
			ShouldRestart := false
			LastProgressTime := A_TickCount
			; Restart from beginning by calling the function again
			RunMainAttackLoop(CurrentMode)
			return
		}
		
		; Check if script is stuck (no progress detected)
		If (CheckIfStuck())
		{
			DebugLogError("Script appears to be stuck - restarting automatically")
			ShouldRestart := false
			LastProgressTime := A_TickCount
			; Restart from beginning
			RunMainAttackLoop(CurrentMode)
			return
		}
		
		; Loop 6 times for the full attack cycle
		Loop, 6 {
			DebugLog("Inner loop iteration: " . A_Index . " / 6")
			
			; Check if paused
			While (IsPaused)
			{
				Sleep, 100
			}
			
			; Check if script should stop
			If (!IsRunning)
			{
				DebugLog("Script stopped by user")
				UpdateStatus("Stopped")
				return
			}
			
			; Check if manual restart was triggered
			If (ShouldRestart)
			{
				DebugLogWarning("Manual restart triggered during attack cycle")
				ShouldRestart := false
				LastProgressTime := A_TickCount
				; Restart immediately
				RunMainAttackLoop(CurrentMode)
				return
			}
			
			; Check if script is stuck
			If (CheckIfStuck())
			{
				DebugLogError("Script appears to be stuck during attack cycle - restarting automatically")
				ShouldRestart := false
				LastProgressTime := A_TickCount
				; Restart immediately
				RunMainAttackLoop(CurrentMode)
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
        	SleepWithPauseCheck(5000) ; Wait 5 seconds before running again
    	}
		
		DebugLog("Starting builder elixir collection")
		GetBuilderElixer(IsSurrenderMode)
		; Update progress time after collecting elixir
		UpdateProgress()
		DebugLog("Builder elixir collection completed")
	}
	DebugLog("Main attack loop completed - all 25 iterations finished")
	IsRunning := false
	UpdateStatus("Stopped")
	; Update button text back to Start
	GuiControl, Main:, StartStopScript, Start
	MsgBox, Script Has ran its course, LOOT UP!
	return
}

GetBuilderElixer(IsSurrenderMode)
{
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
        SleepWithPauseCheck(2000) ; Wait 2 seconds for window to be ready
        SetFullscreenIfNeeded() ; Check if fullscreen, if not press F11
        UpdateProgress() ; Update progress after game starts
        DebugLog("Game window activated, waiting 15 seconds for load")
        
        SleepWithPauseCheck(15000) ; Wait 15 seconds for Clash of Clans to load up
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
        SleepWithPauseCheck(1000) ; Small wait to ensure window is active
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

	SleepWithPauseCheck(1000) ;wait for loot to be collected

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

    SleepWithPauseCheck(1000)
    
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
    SleepWithPauseCheck(2000) ; Wait 2 seconds for window to be ready
    SetFullscreenIfNeeded() ; Check if fullscreen, if not press F11
    UpdateProgress() ; Update progress after game starts
    DebugLog("Game started, waiting 20 seconds for load")
    
    SleepWithPauseCheck(20000) ; Wait 20 seconds for Clash of Clans to load up

    ; Call the Attack function (pass false to use normal sleep)
    DebugLog("Initiating attack")
    Attack(false)
    UpdateProgress() ; Update progress after initiating attack
    SleepWithPauseCheck(5000) ; Wait 5 seconds to enter attack screen
    DebugLog("Deploying troops")
    SpamTroops()
    UpdateProgress() ; Update progress after deploying troops
    SleepWithPauseCheck(1000) ; Wait after spamming troops

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
        SleepWithPauseCheck(2000) ; Wait 2 seconds for window to be ready
        SetFullscreenIfNeeded() ; Check if fullscreen, if not press F11
        UpdateProgress() ; Update progress after game starts
        DebugLog("SurrenderMode: Game started, waiting 20 seconds for load")
        
        SleepWithPauseCheck(20000) ; Wait 20 seconds for Clash of Clans to load up
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
        SleepWithPauseCheck(1000) ; Small wait to ensure window is active
        UpdateProgress() ; Update progress after activating game
    }
    
    ; Call the Attack function with surrender mode flag (skip sleep)
    DebugLog("SurrenderMode: Initiating attack")
    Attack(true)
    UpdateProgress() ; Update progress after initiating attack
    SleepWithPauseCheck(5000) ; Wait 5 seconds to enter attack screen
    DebugLog("SurrenderMode: Deploying troops")
    SpamTroops()
    UpdateProgress() ; Update progress after deploying troops
    SleepWithPauseCheck(2000) ; Wait after spamming troops
    
    ; Surrender by finding and clicking the red surrender button
    DebugLog("SurrenderMode: Starting surrender process")
    Surrender()
    UpdateProgress() ; Update progress after surrendering
    
    ; Wait for surrender to complete and return to base
    DebugLog("SurrenderMode: Waiting 5 seconds for surrender to process")
    SleepWithPauseCheck(5000) ; Wait 5 seconds for surrender to process
    
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
        SleepWithPauseCheck(1000) ; Wait for surrender dialog/confirmation to appear
    }
    Else
    {
        DebugLogWarning("Surrender: RedSurrender not found in bottom area, trying full screen")
        ; If not found, try searching in a different area or wait a bit more
        SleepWithPauseCheck(1000)
        ImageSearch, FoundXSurrender, FoundYSurrender, 0, 0, WindowWidth, WindowHeight, *50 %ImagePathSurrender%
        If (ErrorLevel = 0)
        {
            DebugLog("Surrender: RedSurrender found at X=" . FoundXSurrender . " Y=" . FoundYSurrender . " (full screen search)")
            ClickMouse(FoundXSurrender, FoundYSurrender)
            SleepWithPauseCheck(1000) ; Wait for surrender dialog/confirmation to appear
        }
        Else
        {
            DebugLogError("Surrender: RedSurrender button not found anywhere")
        }
    }
    
    ; After clicking surrender, search for GreenColor and click it (first time)
    SleepWithPauseCheck(1000) ; Small wait for UI to update
    DebugLog("Surrender: Searching for GreenColor confirmation button (first click)")
    ImageSearch, FoundXGreen, FoundYGreen, 0, 0, WindowWidth, WindowHeight, *50 %ImagePathGreen%
    If (ErrorLevel = 0)
    {
        DebugLog("Surrender: GreenColor found at X=" . FoundXGreen . " Y=" . FoundYGreen . " (first click)")
        ClickMouse(FoundXGreen, FoundYGreen)
        SleepWithPauseCheck(1000) ; Wait for UI to update after first click
        
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
    SleepWithPauseCheck(1000)
    ; Only sleep if not in surrender mode (SkipSleep will be empty/false if not provided)
    If (SkipSleep != true)
    {
        DebugLog("Attack: Waiting 12 seconds before Find Now")
        SleepWithPauseCheck(12000) ; Wait 12 seconds between clicking attack button and clicking "Find Now"
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

; Pause hotkey (CTRL+P)
^P::TogglePause() ; Ctrl+P to pause/resume

TogglePause()
{
    Global IsPaused
    Global IsRunning
    Global CurrentMode
    Global MainGuiVisible
    
    If (!IsRunning)
    {
        Return ; Can't pause if not running
    }
    
    IsPaused := !IsPaused
    If (IsPaused)
    {
        DebugLogWarning("Script paused by user (CTRL+P)")
        UpdateStatus("Paused: " . CurrentMode . " Script")
        If (MainGuiVisible)
        {
            GuiControl, Main:, PauseScript, Resume
        }
    }
    Else
    {
        DebugLog("Script resumed by user (CTRL+P)")
        UpdateStatus("Running: " . CurrentMode . " Script")
        If (MainGuiVisible)
        {
            GuiControl, Main:, PauseScript, Pause
        }
    }
}

; Update progress timestamp
UpdateProgress()
{
    Global LastProgressTime
    LastProgressTime := A_TickCount
}

; Sleep with pause checking - respects pause state during sleep
SleepWithPauseCheck(SleepTime)
{
    Global IsPaused
    Global IsRunning
    
    ; Break sleep into smaller chunks to check pause state
    SleepChunk := 100 ; Check every 100ms
    TotalChunks := Ceil(SleepTime / SleepChunk)
    
    Loop, %TotalChunks%
    {
        ; Check if we should stop
        If (!IsRunning)
        {
            Return
        }
        
        ; Wait while paused
        While (IsPaused)
        {
            Sleep, 100
            If (!IsRunning)
            {
                Return
            }
        }
        
        ; Calculate remaining sleep time
        RemainingTime := SleepTime - ((A_Index - 1) * SleepChunk)
        If (RemainingTime > SleepChunk)
        {
            Sleep, %SleepChunk%
        }
        Else
        {
            Sleep, %RemainingTime%
        }
    }
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
; MAIN GUI FUNCTIONS
; ============================================

; Create and show main GUI window
CreateMainGui()
{
    Global MainGuiVisible
    Global IsDebugMode
    Global CurrentMode
    Global ModeDropdown
    Global StatusText
    Global MainConsoleEdit
    
    If (MainGuiVisible)
    {
        Return ; GUI already exists
    }
    
    ; Create main GUI window
    Gui, Main:Add, Text, x10 y10 w200 h20, Farm Mode:
    Gui, Main:Add, DropDownList, x10 y30 w200 h200 Choose1 VModeDropdown gOnModeChange, Normal Mode|Surrender Mode
    CurrentMode := "Normal Mode" ; Initialize default mode
    
    Gui, Main:Add, Button, x10 y60 w100 h30 gStartStopScript, Start
    Gui, Main:Add, Button, x120 y60 w100 h30 gRestartScript, Restart
    Gui, Main:Add, Button, x10 y100 w100 h30 gPauseScript, Pause
    Gui, Main:Add, Button, x120 y100 w100 h30 gExitScript, Exit
    
    Gui, Main:Add, Text, x10 y140 w300 h20, Status:
    Gui, Main:Add, Text, x10 y160 w300 h20 VStatusText, Stopped
    
    ; Add debug console if debug mode is enabled
    If (IsDebugMode)
    {
        Gui, Main:Add, Text, x10 y190 w300 h20, Debug Console:
        Gui, Main:Add, Edit, x10 y210 w600 h300 ReadOnly VMainConsoleEdit Multi HScroll
        Gui, Main:Add, Button, x10 y520 w100 h30 gClearMainConsole, Clear Console
        ; Get the HWND of the console control for scrolling
        Gui, Main:Show, w630 h560, Clash of Clans Auto Builder Base Attack
        Gui, Main:Submit, NoHide
        GuiControlGet, ConsoleEditHwnd, Main:Hwnd, MainConsoleEdit
        ConsoleVisible := true
        DebugLog("Debug console opened in main GUI")
    }
    Else
    {
        Gui, Main:Show, w230 h190, Clash of Clans Auto Builder Base Attack
    }
    
    ; Allow GUI to be minimized
    Gui, Main:+MinSize200x150
    
    MainGuiVisible := true
    UpdateStatus("Stopped")
}

; Handle mode dropdown change
OnModeChange()
{
    Global CurrentMode
    Global ModeDropdown
    Gui, Main:Submit, NoHide
    GuiControlGet, SelectedMode, Main:, ModeDropdown
    CurrentMode := SelectedMode
    DebugLog("Mode changed to: " . CurrentMode)
}

; Start/Stop button handler
StartStopScript()
{
    Global IsRunning
    Global CurrentMode
    Global ShouldRestart
    Global LastProgressTime
    Global IsPaused
    Global ModeDropdown
    
    If (!IsRunning)
    {
        ; Start the script
        IsRunning := true
        IsPaused := false
        ShouldRestart := false
        LastProgressTime := A_TickCount
        
        ; Get current mode from dropdown
        Gui, Main:Submit, NoHide
        GuiControlGet, CurrentMode, Main:, ModeDropdown
        
        UpdateStatus("Running: " . CurrentMode . " Script")
        DebugLog("Script started - Mode: " . CurrentMode)
        
        ; Change button text to Stop
        GuiControl, Main:, StartStopScript, Stop
        
        ; Start the main attack loop in a new thread
        RunMainAttackLoop(CurrentMode)
    }
    Else
    {
        ; Stop the script
        IsRunning := false
        IsPaused := false
        UpdateStatus("Stopped")
        DebugLog("Script stopped by user")
        
        ; Change button text back to Start
        GuiControl, Main:, StartStopScript, Start
    }
}


; Restart button handler
RestartScript()
{
    Global ShouldRestart
    Global IsRunning
    
    If (!IsRunning)
    {
        Return ; Can't restart if not running
    }
    
    ShouldRestart := true
    DebugLogWarning("Restart button clicked")
}

; Pause button handler
PauseScript()
{
    Global IsPaused
    Global IsRunning
    Global CurrentMode
    
    If (!IsRunning)
    {
        Return ; Can't pause if not running
    }
    
    IsPaused := !IsPaused
    If (IsPaused)
    {
        DebugLogWarning("Script paused by user")
        UpdateStatus("Paused: " . CurrentMode . " Script")
        GuiControl, Main:, PauseScript, Resume
    }
    Else
    {
        DebugLog("Script resumed by user")
        UpdateStatus("Running: " . CurrentMode . " Script")
        GuiControl, Main:, PauseScript, Pause
    }
}

; Exit button handler
ExitScript()
{
    Global IsRunning
    Global MainGuiVisible
    
    If (IsRunning)
    {
        IsRunning := false
    }
    
    DebugLog("Script exiting")
    MainGuiVisible := false
    Gui, Main:Destroy
    ExitApp
}

; Update status display
UpdateStatus(StatusText)
{
    Global MainGuiVisible
    
    If (MainGuiVisible)
    {
        GuiControl, Main:, StatusText, %StatusText%
    }
}

; Clear main console
ClearMainConsole()
{
    Global MainConsoleEdit
    GuiControl, Main:, MainConsoleEdit, 
    DebugLog("Console cleared")
}

; Log a message to console (only if debug mode is enabled)
DebugLog(Message, Level := "INFO")
{
    Global ConsoleEditHwnd
    Global ConsoleVisible
    Global IsDebugMode
    Global MainGuiVisible
    Global MainConsoleEdit
    
    ; Only log if debug mode is enabled
    If (!IsDebugMode)
    {
        Return
    }
    
    ; Format timestamp
    FormatTime, TimeString, , yyyy-MM-dd HH:mm:ss
    
    ; Format log entry
    LogEntry := "[" . TimeString . "] [" . Level . "] " . Message . "`r`n"
    
    ; Append to console if visible (main GUI console)
    If (ConsoleVisible && MainGuiVisible)
    {
        GuiControlGet, CurrentText, Main:, MainConsoleEdit
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
        GuiControl, Main:, MainConsoleEdit, %NewText%
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
