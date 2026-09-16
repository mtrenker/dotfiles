-- Preserve defiant's working monitor configuration.
hl.monitor({
    output   = "DP-1",
    mode     = "5120x1440@120",
    position = "0x0",
    scale    = "1",
})

-- Ultrawide: comfortable columns rather than stretching a lone window to 32:9.
hl.config({
    general = { layout = "scrolling" },
    scrolling = {
        fullscreen_on_one_column = false,
        column_width = 1 / 3,
        explicit_column_widths = "0.333333, 0.5, 0.666667, 1.0",
    },
    master = {
        orientation = "center",
        mfact = 0.5,
        slave_count_for_center_master = 0,
        new_status = "slave",
    },
})

-- Session-wide layout comparison; reloading restores the scrolling default.
hl.bind("SUPER + CTRL + F1", function ()
    hl.config({ general = { layout = "scrolling" } })
end)
hl.bind("SUPER + CTRL + F2", function ()
    hl.config({ general = { layout = "master" } })
end)
hl.bind("SUPER + CTRL + F3", function ()
    hl.config({ general = { layout = "dwindle" } })
end)
-- Scrolling only: cycle the focused column through the widths above.
hl.bind("SUPER + CTRL + right", hl.dsp.layout("colresize +conf"))
hl.bind("SUPER + CTRL + left", hl.dsp.layout("colresize -conf"))

-- Existing Proton Pass setup; the CLI and authentication are installed separately.
hl.env("SSH_AUTH_SOCK", os.getenv("XDG_RUNTIME_DIR") .. "/proton-pass-agent.sock")
hl.on("hyprland.start", function ()
    hl.exec_cmd("protonvpn-app")
    hl.exec_cmd('/home/martin/.local/bin/pass-cli ssh-agent daemon start --socket-path "$XDG_RUNTIME_DIR/proton-pass-agent.sock"')
end)
