# Termux Linux Setup (XFCE4)

One script that turns an Android phone into an XFCE4 Linux desktop using Termux and Termux:X11. It needs no root and no proot. Everything runs natively in Termux.

It is set up for **Mali GPUs** (tested target: Samsung Exynos 990 / Mali-G77 MP11) and uses software rendering (llvmpipe). Turnip only supports Adreno GPUs, and Zink on Mali tends to be unstable.

## Prerequisites

Install these on the phone before running the script:

1. **Termux** from [F-Droid](https://f-droid.org/packages/com.termux/) or [GitHub releases](https://github.com/termux/termux-app/releases).
   Don't mix install sources: Termux and its add-ons must come from the same place.
2. **Termux:X11 app**: the `arm64-v8a` APK from [termux-x11 releases](https://github.com/termux/termux-x11/releases). This app shows the desktop.
3. **About 4–5 GB of free storage.**
4. **Stop Android from killing Termux** (important on Samsung):
   - Settings → Apps → Termux → Battery → **Unrestricted**. Do the same for Termux:X11.
   - **Android 14+:** Developer options → enable **"Disable child process restrictions"**.
   - **Android 12–13:** from a computer with adb, run:
     ```sh
     adb shell device_config put activity_manager max_phantom_processes 2147483647
     ```
   Without this, the desktop may die after a few minutes with `[Process completed (signal 9)]`.

## Installation

**Quick install** (one line, in Termux):
```sh
curl -fsSL https://raw.githubusercontent.com/rvgpl/termux-xfce-setup/main/setup.sh -o setup.sh && bash setup.sh
```

**Or clone the repo:**
```sh
pkg install -y git
git clone https://github.com/rvgpl/termux-xfce-setup.git
cd termux-xfce-setup
bash setup.sh
```

Then wait. It takes 15–40 minutes depending on your connection. Keep Termux in the foreground or the screen on.

If a step fails, the script either stops (repos, Termux-X11 and XFCE4 are required) or lists the failure at the end. Full output is in `~/termux-setup.log`. It's safe to re-run the script.

## Usage

**Start the desktop:**
```sh
~/start-linux.sh
```
Then open the **Termux:X11** app. Leave Termux running in the background.

**Stop the desktop:**
```sh
~/stop-linux.sh
```
Run it from a new Termux session (swipe from the left edge → New session), or press `Ctrl+C` in the session that started it.

## Tips

- **Speed:** turn off the compositor in XFCE: Settings → Window Manager Tweaks → Compositor → uncheck "Enable display compositing". This is the biggest performance win with software rendering.
- **Resolution / scaling:** in the Termux:X11 app, open Preferences → Output → Display resolution mode. Lower resolutions run faster.
- **Keyboard & mouse:** Bluetooth or USB-C keyboards and mice work. Termux:X11 Preferences has touchpad/touchscreen modes.
- **Windows apps:** run `wine yourapp.exe` from the terminal, or use the *Wine Config* shortcut. Expect slow performance and only light apps to work.
- **Phone storage:** run `termux-setup-storage` once, then use `~/storage/shared` in Thunar.

## Troubleshooting

| Problem | Fix |
|---|---|
| `[Process completed (signal 9)]` | Android killed Termux. See prerequisite 4. |
| Black screen in Termux:X11 | Check `~/start-linux.sh` is still running in Termux. Run `~/stop-linux.sh`, then start again. |
| `X11 server did not start` | Reinstall: `pkg install termux-x11-nightly`. Make sure the Termux:X11 app is installed. |
| No sound | `pulseaudio --kill && pulseaudio --start --exit-idle-time=-1` |
| `Unable to locate package` | `pkg update`, then re-run `bash setup.sh`. |
| Something else failed | Check `~/termux-setup.log`. |

## What gets installed

| Step | Package | Purpose |
|---|---|---|
| Repos | `x11-repo` | Termux X11/desktop package repository |
| | `tur-repo` | Termux User Repository (for Firefox) |
| Display | `termux-x11-nightly` | X11 server (pairs with the Termux:X11 app) |
| | `xorg-xrandr` | Display resolution settings |
| Desktop | `xfce4` | XFCE4 desktop |
| | `xfce4-terminal` | Terminal |
| | `xfce4-whiskermenu-plugin` | Start-menu style launcher |
| | `plank-reloaded` | Dock |
| | `thunar` | File manager |
| | `mousepad` | Text editor |
| | `dbus` | Session bus required by the desktop |
| Audio | `pulseaudio` | Sound server |
| Apps | `firefox` | Web browser |
| | `vlc` | Media player |
| | `git`, `wget`, `curl` | Dev / download tools |
| Python | `python` | Python 3 + pip |
| Windows | `hangover-wine` | Wine (runs Windows apps) |
| | `hangover-wowbox64` | Box64 (x86 → ARM translation) |

The script also upgrades all existing Termux packages and removes `wine-stable` if present. Dependencies such as Mesa, GTK and fonts are pulled in automatically.

## Files created

| Path | Purpose |
|---|---|
| `~/start-linux.sh` | Starts audio, X11 and XFCE4 |
| `~/stop-linux.sh` | Stops the desktop |
| `~/.config/linux-env.sh` | Environment variables for the desktop |
| `~/.config/autostart/plank.desktop` | Starts the Plank dock at login |
| `~/Desktop/*.desktop` | Firefox, VLC, Terminal, Wine Config shortcuts |
| `~/termux-setup.log` | Install log |

## Uninstall

```sh
~/stop-linux.sh
apt-get remove -y xfce4 xfce4-terminal xfce4-whiskermenu-plugin plank-reloaded thunar mousepad \
  firefox vlc hangover-wine hangover-wowbox64 termux-x11-nightly pulseaudio
apt-get autoremove -y
rm -f ~/start-linux.sh ~/stop-linux.sh ~/.config/linux-env.sh ~/.config/autostart/plank.desktop \
  ~/Desktop/{Firefox,VLC,Terminal,Wine_Config}.desktop ~/termux-setup.log
```
To wipe everything, clear Termux's app data in Android settings.

## License

[MIT](LICENSE)
