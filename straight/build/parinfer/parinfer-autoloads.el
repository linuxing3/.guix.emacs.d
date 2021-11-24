;;; parinfer-autoloads.el --- automatically extracted autoloads  -*- lexical-binding: t -*-
;;
;;; Code:


;;;### (autoloads nil "parinfer" "parinfer.el" (0 0 0 0))
;;; Generated autoloads from parinfer.el

(autoload 'parinfer-mode "parinfer" "\
Parinfer mode.

This is a minor mode.  If called interactively, toggle the
`Parinfer mode' mode.  If the prefix argument is positive, enable
the mode, and if it is zero or negative, disable the mode.

If called from Lisp, toggle the mode if ARG is `toggle'.  Enable
the mode if ARG is nil, omitted, or is a positive number.
Disable the mode if ARG is a negative number.

To check whether the minor mode is enabled in the current buffer,
evaluate `parinfer-mode'.

The mode's hook is called both when the mode is enabled and when
it is disabled.

\(fn &optional ARG)" t nil)

(autoload 'parinfer-region-mode "parinfer" "\
Available when region is active.

This is a minor mode.  If called interactively, toggle the
`Parinfer-Region mode' mode.  If the prefix argument is positive,
enable the mode, and if it is zero or negative, disable the mode.

If called from Lisp, toggle the mode if ARG is `toggle'.  Enable
the mode if ARG is nil, omitted, or is a positive number.
Disable the mode if ARG is a negative number.

To check whether the minor mode is enabled in the current buffer,
evaluate `parinfer-region-mode'.

The mode's hook is called both when the mode is enabled and when
it is disabled.

\(fn &optional ARG)" t nil)

(register-definition-prefixes "parinfer" '("parinfer-"))

;;;***

;;;### (autoloads nil "parinfer-ext" "parinfer-ext.el" (0 0 0 0))
;;; Generated autoloads from parinfer-ext.el

(register-definition-prefixes "parinfer-ext" '("parinfer-"))

;;;***

;;;### (autoloads nil "parinferlib" "parinferlib.el" (0 0 0 0))
;;; Generated autoloads from parinferlib.el

(register-definition-prefixes "parinferlib" '("parinferlib-"))

;;;***

(provide 'parinfer-autoloads)
;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; parinfer-autoloads.el ends here
