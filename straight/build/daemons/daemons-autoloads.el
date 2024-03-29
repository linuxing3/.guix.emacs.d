;;; daemons-autoloads.el --- automatically extracted autoloads  -*- lexical-binding: t -*-
;;
;;; Code:


;;;### (autoloads nil "daemons" "daemons.el" (0 0 0 0))
;;; Generated autoloads from daemons.el

(autoload 'daemons-status "daemons" "\
Show the status of the daemon NAME.

\(fn NAME)" t nil)

(autoload 'daemons-start "daemons" "\
Start the daemon NAME.  Show results in an output buffer.

\(fn NAME)" t nil)

(autoload 'daemons-stop "daemons" "\
Stop the daemon NAME.  Show results in an output buffer.

\(fn NAME)" t nil)

(autoload 'daemons-restart "daemons" "\
Restart the daemon NAME.  Show results in an ouptut buffer.

\(fn NAME)" t nil)

(autoload 'daemons-reload "daemons" "\
Reload the daemon NAME.  Show results in an output buffer.

\(fn NAME)" t nil)

(autoload 'daemons-enable "daemons" "\
Enable the daemon NAME.  Show results in an output buffer.

\(fn NAME)" t nil)

(autoload 'daemons-disable "daemons" "\
Disable the daemon NAME.  Show results in an output buffer.

\(fn NAME)" t nil)

(autoload 'daemons "daemons" "\
Open the list of system daemons (services) for user management.

This opens a ‘daemons-mode’ list buffer.  Move the cursor to a daemon line and
execute one of the commands in `describe-mode' to show status and manage the
state of the daemon." t nil)

(register-definition-prefixes "daemons" '("daemons-"))

;;;***

;;;### (autoloads nil "daemons-brew" "daemons-brew.el" (0 0 0 0))
;;; Generated autoloads from daemons-brew.el

(register-definition-prefixes "daemons-brew" '("daemons-brew--"))

;;;***

;;;### (autoloads nil "daemons-openrc" "daemons-openrc.el" (0 0 0
;;;;;;  0))
;;; Generated autoloads from daemons-openrc.el

(register-definition-prefixes "daemons-openrc" '("daemons-openrc--"))

;;;***

;;;### (autoloads nil "daemons-shepherd" "daemons-shepherd.el" (0
;;;;;;  0 0 0))
;;; Generated autoloads from daemons-shepherd.el

(register-definition-prefixes "daemons-shepherd" '("daemons-shepherd--"))

;;;***

;;;### (autoloads nil "daemons-systemd" "daemons-systemd.el" (0 0
;;;;;;  0 0))
;;; Generated autoloads from daemons-systemd.el

(register-definition-prefixes "daemons-systemd" '("daemons-systemd-"))

;;;***

;;;### (autoloads nil "daemons-sysvinit" "daemons-sysvinit.el" (0
;;;;;;  0 0 0))
;;; Generated autoloads from daemons-sysvinit.el

(register-definition-prefixes "daemons-sysvinit" '("daemons-sysvinit--"))

;;;***

(provide 'daemons-autoloads)
;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; daemons-autoloads.el ends here
