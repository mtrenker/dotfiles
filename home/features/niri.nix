{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Core Wayland desktop tools
    # Note: on non-NixOS machines like voyager, install the compositor and
    # graphics-coupled GTK/OpenGL apps system-wide so they use the host graphics
    # stack cleanly. Ghostty should come from CachyOS/pacman, not Nix.
    foot # lightweight fallback terminal
    (writeShellScriptBin "default-terminal" ''
      set -euo pipefail

      if [ -x /usr/bin/ghostty ]; then
        exec /usr/bin/ghostty "$@"
      fi

      exec ${foot}/bin/foot "$@"
    '')
    fuzzel
    waybar
    mako
    swaybg
    swaylock

    # Clipboard / screenshots
    wl-clipboard
    grim
    slurp

    # Common desktop helpers used by keybindings / bar modules
    brightnessctl
    playerctl
  ];

  xdg.configFile."systemd/user/niri.service".text = ''
    [Unit]
    Description=A scrollable-tiling Wayland compositor
    BindsTo=graphical-session.target
    Before=graphical-session.target
    Wants=graphical-session-pre.target
    After=graphical-session-pre.target

    Wants=xdg-desktop-autostart.target
    Before=xdg-desktop-autostart.target

    [Service]
    Slice=session.slice
    Type=notify
    ExecStart=/usr/bin/niri --session
  '';

  xdg.configFile."systemd/user/niri-shutdown.target".text = ''
    [Unit]
    Description=Shutdown running Niri session
    BindsTo=graphical-session.target
    Before=graphical-session.target
    StopWhenUnneeded=yes
  '';

  xdg.configFile."niri/config.kdl".text = ''
    // Shared Niri baseline, initially designed around voyager.
    // Safe to reuse on other Niri machines and override later per-host if needed.

    input {
        keyboard {
            xkb {
                options "compose:ralt,ctrl:nocaps"
            }
            numlock
        }

        touchpad {
            tap
            natural-scroll
        }

        mouse {
            // natural-scroll
        }

        focus-follows-mouse
    }

    layout {
        gaps 12
        center-focused-column "never"
        default-column-width { proportion 0.55; }

        preset-column-widths {
            proportion 0.33
            proportion 0.5
            proportion 0.67
        }

        focus-ring {
            on
            width 3
            active-color "#7aa2f7"
            inactive-color "#414868"
        }

        border {
            off
        }

        shadow {
            on
            softness 20
            spread 4
            offset x=0 y=4
            color "#00000055"
        }
    }

    prefer-no-csd
    screenshot-path "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png"

    binds {
        Mod+Shift+Slash { show-hotkey-overlay; }

        // Launcher / apps
        Mod+Return { spawn "default-terminal"; }
        Super+T { spawn "default-terminal"; }
        Mod+D { spawn "fuzzel"; }
        Super+Alt+L { spawn "swaylock"; }

        // Window management
        Mod+Q { close-window; }
        Mod+F { fullscreen-window; }
        Mod+Shift+F { maximize-column; }
        Mod+V { toggle-window-floating; }
        Mod+W { toggle-column-tabbed-display; }
        Mod+R { switch-preset-column-width; }
        Mod+Shift+R { switch-preset-column-width-back; }
        Mod+Minus { set-column-width "-10%"; }
        Mod+Equal { set-column-width "+10%"; }

        // Focus movement
        Mod+H { focus-column-left; }
        Mod+J { focus-window-down; }
        Mod+K { focus-window-up; }
        Mod+L { focus-column-right; }

        // Move windows / columns
        Mod+Ctrl+H { move-column-left; }
        Mod+Ctrl+J { move-window-down; }
        Mod+Ctrl+K { move-window-up; }
        Mod+Ctrl+L { move-column-right; }

        // Workspaces
        Mod+1 { focus-workspace 1; }
        Mod+2 { focus-workspace 2; }
        Mod+3 { focus-workspace 3; }
        Mod+4 { focus-workspace 4; }
        Mod+5 { focus-workspace 5; }
        Mod+6 { focus-workspace 6; }
        Mod+7 { focus-workspace 7; }
        Mod+8 { focus-workspace 8; }
        Mod+9 { focus-workspace 9; }

        Mod+Shift+1 { move-column-to-workspace 1; }
        Mod+Shift+2 { move-column-to-workspace 2; }
        Mod+Shift+3 { move-column-to-workspace 3; }
        Mod+Shift+4 { move-column-to-workspace 4; }
        Mod+Shift+5 { move-column-to-workspace 5; }
        Mod+Shift+6 { move-column-to-workspace 6; }
        Mod+Shift+7 { move-column-to-workspace 7; }
        Mod+Shift+8 { move-column-to-workspace 8; }
        Mod+Shift+9 { move-column-to-workspace 9; }

        Mod+U { focus-workspace-down; }
        Mod+I { focus-workspace-up; }
        Mod+Shift+U { move-workspace-down; }
        Mod+Shift+I { move-workspace-up; }

        // Screenshots
        Print { screenshot; }
        Ctrl+Print { screenshot-screen; }
        Alt+Print { screenshot-window; }

        // Session
        Mod+Shift+E { quit; }
    }

    spawn-at-startup "waybar"
    spawn-at-startup "mako"
  '';

  xdg.configFile."waybar/config.jsonc".text = ''
    {
      "layer": "top",
      "position": "top",
      "height": 30,
      "modules-left": ["niri/workspaces", "niri/window"],
      "modules-right": ["tray", "pulseaudio", "network", "cpu", "memory", "clock"],

      "niri/workspaces": {
        "format": "{icon}",
        "format-icons": {
          "active": "",
          "default": ""
        }
      },

      "niri/window": {
        "max-length": 80
      },

      "clock": {
        "format": "{:%Y-%m-%d %H:%M}"
      },

      "cpu": {
        "format": "CPU {usage}%"
      },

      "memory": {
        "format": "RAM {}%"
      },

      "network": {
        "format-wifi": "WiFi {essid}",
        "format-ethernet": "ETH",
        "format-disconnected": "Offline"
      },

      "pulseaudio": {
        "format": "VOL {volume}%",
        "format-muted": "MUTED"
      },

      "tray": {
        "spacing": 8
      }
    }
  '';

  xdg.configFile."waybar/style.css".text = ''
    * {
      border: none;
      border-radius: 0;
      font-family: sans-serif;
      font-size: 13px;
      min-height: 0;
    }

    window#waybar {
      background: rgba(26, 27, 38, 0.92);
      color: #c0caf5;
    }

    #workspaces,
    #window,
    #tray,
    #pulseaudio,
    #network,
    #cpu,
    #memory,
    #clock {
      padding: 0 10px;
      margin: 4px 4px;
    }

    #workspaces button {
      color: #7aa2f7;
      padding: 0 6px;
    }

    #workspaces button.active {
      color: #c0caf5;
    }
  '';

  xdg.configFile."fuzzel/fuzzel.ini".text = ''
    [main]
    terminal=default-terminal
    width=40
    lines=12
    horizontal-pad=16
    vertical-pad=12

    [colors]
    background=1a1b26ee
    text=c0caf5ff
    prompt=7aa2f7ff
    placeholder=565f89ff
    input=c0caf5ff
    match=9ece6aff
    selection=2e3c64ff
    selection-text=c0caf5ff
    selection-match=9ece6aff
    border=7aa2f7ff
  '';

  xdg.configFile."mako/config".text = ''
    font=sans-serif 11
    background-color=#1a1b26dd
    text-color=#c0caf5ff
    border-color=#7aa2f7ff
    default-timeout=5000
    border-size=2
    border-radius=8
    padding=12
    width=360
    height=120
    anchor=top-right
    margin=16
  '';
}
