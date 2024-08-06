# Taran's windots

Hello! Welcome to the showcase of my Windows dotfiles (windots) that I use daily. I prefer the clean and minimal type of desktops and have created this thus far.

# Contents

- [Taran's windots](#tarans-windots)
- [Contents](#contents)
  - [GlazeWM Version 2](#glazewm-version-2)
    - [Original Version](#original-version)
    - [Minimal Version (with icons)](#minimal-version-with-icons)
      - [Current Features](#current-features)
  - [GlazeWM Version 3](#glazewm-version-3)
    - [Current State](#current-state)
    - [Tools](#tools)
- [Ending notes](#ending-notes)

## GlazeWM Version 2

### Original Version

<details>
    <summary>Preview</summary>
    <img src="/assets/version_1/desktop_1.png" alt="Preview of my desktop">
</details>
<br>

<details>
    <summary>Preview with terminals</summary>
    <img src="/assets/version_1/desktop_2.png" alt="Preview of my desktop with 3 terminals on display">
</details>
<br>

<details>
    <summary>Preview with WezTerm domain management</summary>
    <img src="/assets/version_1/desktop_3.png" alt="Preview with WezTerm domain management">
</details>
<br>

<details>
    <summary>Preview of my desktop in action!</summary>
    <video src="https://github.com/tarannagra/windots/assets/125768336/07aacd84-0467-42c3-aa9d-1c0c87a70e1d" alt="Preview of my desktop in action!" controls/>
</details>
<br>

### Minimal Version (with icons)

> [!IMPORTANT]
> There was an issue with rendering any of the emoji/icons and a fix has now been made available. Turns out using `cat config.yaml | clip` is a very bad idea.

<details>
    <summary>Showcasing my desktop</summary>
    <img src="/assets/version_2/desktop_1.png" alt="Preview of my desktop with no open apps">
</details>
<br>

<details>
    <summary>Terminals, Terminals, Terminals!</summary>
    <img src="/assets/version_2/desktop_2.png" alt="Showcase of terminals on dev workspace">
</details>
<br>

<!-- <details>
    <summary></summary>
    <img src="/assets/version_2/desktop_2.png" alt="Showcase of terminals on home workspace">
</details>
<br> -->

#### Current Features

- WM:
  - Subtle transparent glow underneath the bar
  - A blue glow around the active window (colour can be changed in config)
  - No titlebar -> thank you to [glazewm-extra :)](https://github.com/ptazithos/glazewm-extra)
- Bar:
  - Lightning emoji that when left clicked, displays Flow Launcher and changes the wallpaper on the right
  - A better date display (displayed as how you would read it)
  - Icons instead of text for each workspace
  - Current weather (long & lat must be changed to fit your current location!)
  - Border around the current time with an emoji to occupy it
  - "Not playing" emoji (in red) when no media is found to be playing
  - Distinct colour when music is played/paused
  - Better looking battery emoji placement
  - The GlazeWM current window tiling direction icon
  - Finally, a power-off button

## GlazeWM Version 3

> [!IMPORTANT]
> This is using [GlazeWM's rewrite](https://github.com/glzr-io/glazewm) and not the previous build in C#.
> This includes a new bar too, [Zebar](https://github.com/glzr-io/zebar) - removes some functions I liked previously but it is what it is.

### Current State

<details>
    <summary>Main desktop (no apps on)</summary>
    <img src="/assets/rewrite/version_1/workspace_home.png" alt="Showing workspace home">
</details>
<br>

<details>
    <summary>My workflow</summary>
    <img src="/assets/rewrite/version_1/workspace_dev.png" alt="Showing workspace dev">
</details>
<br>

### Tools

- [FlowLauncher](https://www.flowlauncher.com/)
- [glazewm](https://github.com/glzr-io/glazewm)
- [NerdFont](https://www.nerdfonts.com/)
- [Oh-My-Posh](https://ohmyposh.dev/)
- [SetWallpaper](https://github.com/tarannagra/SetWallpaper)
- [VSCode](https://code.visualstudio.com/)
- [WezTerm](https://github.com/wez/wezterm)

# Ending notes

If you have found this useful or have taken anything here, I would appreciate a star on here ⭐