#Requires AutoHotkey v2.0
#SingleInstance Force

;!!     Taran's "TheEverythingScript"
;?    A place for me to house EVERYTHING!
;?  WM Binds, App opening and so much more!


;* Variables

;? App names
; if changing in the future, then it's easier
explorer := "explorer"
terminal := "alacritty"

;? Paths
appdata_local := "C:\Users\subwa\AppData\Local"
icon_path := "C:\Users\subwa\.config\notifications\icons"
script_location := Format('{}\.config\notifications\notify.py', EnvGet('USERPROFILE'))

;* Functions

/**
     * @description - `Notify()` -> executes a pre-made script to send a Windows 11 "toast" to notify the user, based on the args. Supports custom images.
     * 
     * Args:
     *  - title
     *  - body
     *  - app
     *  - image
     */
Notify(title, body, app, image) {
    icon := Format('{}\{}', icon_path, image)
    args := Format('-t "{}" -b "{}" -a "{}" -i "{}"', title, body, app, icon)
    finalised := Format('python "{}" {}', script_location, args)

    ; MsgBox finalised
    Run(finalised, , "Hide") ; Don't show a terminal when spawning the process
}

Komorebic(command) {
    Run(Format("komorebic {}", command), , "Hide")
}

;* Keybindings

;? Sending a Hello message

#+w:: {
    Notify(
        "Taran's windots",
        "Hello World!",
        "Taran :)",
        "wallpaper.png"
    )
}

;** Opening Programs

;? win+shift+o -> Obsidian
#+o:: {
    Notify(
        "Opening Obsidian...", 
        "Enjoy your note taking!", 
        "Notifications", 
        "obsidian.png"
    )
    Run Format("{1}\Programs\Obsidian\Obsidian.exe", appdata_local)
}

;? win+q -> Zen Browser
#q:: {
    Run(Format('"{}\Zen Browser\zen.exe"', EnvGet("ProgramFiles")))
}

;? win+e -> Explorer (add it in variables)
#e:: {
    Run(explorer)
}

;? win+space -> Flow.Launcher
#space:: {
    Run(Format('"{}\FlowLauncher\Flow.Launcher.exe"', EnvGet("LOCALAPPDATA")))
}

;? win+enter -> Open Terminal (add it in variables)
#enter:: {
    Run(terminal)
}

;? win+shift+b -> Restart the YASB Bar
#+b:: {
    MsgBox "Needs re-doing"
    ; yasb_exec := Format('{}\Documents\yasb\src\main.py', EnvGet("USERPROFILE"))
    ; Run(Format('python "{}"', yasb_exec))
}

;** Komorebi WM Specific

;~ Configuration

;? win+shift+r -> Reload komorebi configuration
#+r:: {
    Notify(
        "Reloading Configuration",
        "Your config has been reloaded!",
        "Komorebi",
        "komorebi.png"
    )
    Komorebic("reload-configuration")
}

;~ Application Specific

;? win+shift+q -> Close app
#+q:: {
    Komorebic("close")
}

;? win+m -> minimise (UK! UK!)
#m:: {
    Komorebic("minimize")
}

;? win+x -> Maximise (UK! UK!)
#x:: {
    Komorebic("toggle-maximize")
}

;~ Focusing Windows

;? win+left -> Focus Window: Left
#left:: {
    Komorebic("focus left")
}

;? win+right -> Focus Window: Right
#right:: {
    Komorebic("focus right")
}

;? win+up -> Focus Window: Up
#up:: {
    Komorebic("focus up")
}

;? win+down -> Focus Window: Down
#down:: {
    Komorebic("focus down")
}

;~ Moving Windows

;? win+shift+left -> Move Window: Left
#+left:: {
    Komorebic("move left")
}

;? win+shift+right -> Move Window: Right
#+right:: {
    Komorebic("move right")
}

;? win+shift+up -> Move Window: Up
#+up:: {
    Komorebic("move up")
}

;? win+shift+down -> Move Window: Down
#+down:: {
    Komorebic("move down")
}

;~ Window Manipulation

;? win+shift+space -> Toggle Floating
#+space:: {
    Komorebic("toggle-float")
} 

;~ Focusing Workspaces

;? win+1 -> Focus Workspace: 1
#1:: {
    Komorebic("focus-workspace 0")
}

;? win+2 -> Focus Workspace: 2
#2:: {
    Komorebic("focus-workspace 1")
}

;? win+3 -> Focus Workspace: 3
#3:: {
    Komorebic("focus-workspace 2")
}

;? win+4 -> Focus Workspace: 4
#4:: {
    Komorebic("focus-workspace 3")
}

;? win+5 -> Focus Workspace: 5
#5:: {
    Komorebic("focus-workspace 4")
}

;~ Move Window To Workspaces

;? win+shift+1 -> Move *Focused* Window to Workspace: 1
#+1:: {
    Komorebic("move-to-workspace 0")
}

;? win+shift+2 -> Move *Focused* Window to Workspace: 2
#+2:: {
    Komorebic("move-to-workspace 1")
}

;? win+shift+3 -> Move *Focused* Window to Workspace: 3
#+3:: {
    Komorebic("move-to-workspace 2")
}

;? win+shift+4 -> Move *Focused* Window to Workspace: 4
#+4:: {
    Komorebic("move-to-workspace 3")
}

;? win+shift+5 -> Move *Focused* Window to Workspace: 5
#+5:: {
    Komorebic("move-to-workspace 4")
}

;~ Stackbar Specific

;? left_ctrl+win+left -> Stack left
<^#left:: {
    Komorebic("stack left")
}

;? left_ctrl+win+right -> Stack right
<^#right:: {
    Komorebic("stack right")
}

;? left_ctrl+win+up -> Stack up
<^#up:: {
    Komorebic("stack up")
}

;? left_ctrl+win+down -> Stack down
<^#down:: {
    Komorebic("stack down")
}

;? left_ctrl+win+u -> Stack down
<^#u:: {
    Komorebic("unstack")
}

;~ Still Stackbar but Cycling in the Stack

;? right_ctrl+win+[ -> go back in stack
>^#[:: {
    Komorebic("cycle-stack previous")
}

;? right_ctrl+win+] -> go forward in stack
>^#]:: {
    Komorebic("cycle-stack next")
}