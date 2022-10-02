---
system:
  hostname: foobar
  username: foobar
  kernel: standard # standard|lts|zen
  timezone: Europe/Rome
timeshift:
  autosnap:
    enabled: true
    maxSnapshots: 10
bluetooth:
  controllerMode: dual
desktop:
  gnome:
    extensions:
    - appindicatorsupport@rgcjonas.gmail.com
    - just-perfection-desktop@just-perfection
    - screenshot-window-sizer@gnome-shell-extensions.gcampax.github.com
    - user-theme@gnome-shell-extensions.gcampax.github.com
    - dash-to-dock@micxgx.gmail.com
    - ding@rastersoft.com
    - Vitals@CoreCoding.com
    keybindings:
      open_terminal_shortcut: "<Super>Return" # "<Primary><Alt>t"
    dconf:
      use_mouse_natural_scroll: true
      alter_close_window: true
      clock_show_seconds: true
      dash_to_dock_show_favorites: "false" # Note that this is a string, not a boolean
      alt_tab_avoid_grouping: false
  sway:
    enable: false
    waybar: true
  i3:
    enable: false
  x11_gestures: false
  office: false
debug: false
sparkfabrik: false
qemu_for_buildx: true
