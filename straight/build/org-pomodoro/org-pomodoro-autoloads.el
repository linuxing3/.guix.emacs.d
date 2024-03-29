;;; org-pomodoro-autoloads.el --- automatically extracted autoloads  -*- lexical-binding: t -*-
;;
;;; Code:


;;;### (autoloads nil "org-pomodoro" "org-pomodoro.el" (0 0 0 0))
;;; Generated autoloads from org-pomodoro.el

(autoload 'org-pomodoro "org-pomodoro" "\
Start a new pomodoro or stop the current one.

When no timer is running for `org-pomodoro` a new pomodoro is started and
the current task is clocked in.  Otherwise EMACS will ask whether we´d like to
kill the current timer, this may be a break or a running pomodoro.

\(fn &optional ARG)" t nil)

(register-definition-prefixes "org-pomodoro" '("org-pomodoro-"))

;;;***

;;;### (autoloads nil "org-pomodoro-pidgin" "org-pomodoro-pidgin.el"
;;;;;;  (0 0 0 0))
;;; Generated autoloads from org-pomodoro-pidgin.el

(register-definition-prefixes "org-pomodoro-pidgin" '("org-pom"))

;;;***

(provide 'org-pomodoro-autoloads)
;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; org-pomodoro-autoloads.el ends here
