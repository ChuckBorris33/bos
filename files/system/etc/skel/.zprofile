# Autostart graphical session on TTY1
if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty2" ]; then
  exec startlxqtlabwc
fi
