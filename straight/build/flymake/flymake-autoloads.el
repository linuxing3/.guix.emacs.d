;;; flymake-autoloads.el --- automatically extracted autoloads  -*- lexical-binding: t -*-
;;
;;; Code:


;;;### (autoloads nil "flymake" "flymake.el" (0 0 0 0))
;;; Generated autoloads from flymake.el

(autoload 'flymake-log "flymake" "\
Log, at level LEVEL, the message MSG formatted with ARGS.
LEVEL is passed to `display-warning', which is used to display
the warning.  If this form is included in a file,
the generated warning contains an indication of the file that
generated it.

\(fn LEVEL MSG &rest ARGS)" nil t)

(autoload 'flymake-make-diagnostic "flymake" "\
Make a Flymake diagnostic for LOCUS's region from BEG to END.
LOCUS is a buffer object or a string designating a file name.

TYPE is a diagnostic symbol and TEXT is string describing the
problem detected in this region.  DATA is any object that the
caller wishes to attach to the created diagnostic for later
retrieval with `flymake-diagnostic-data'.

If LOCUS is a buffer BEG and END should be buffer positions
inside it.  If LOCUS designates a file, BEG and END should be a
cons (LINE . COL) indicating a file position.  In this second
case, END may be omitted in which case the region is computed
using `flymake-diag-region' if the diagnostic is appended to an
actual buffer.

OVERLAY-PROPERTIES is an alist of properties attached to the
created diagnostic, overriding the default properties and any
properties listed in the `flymake-overlay-control' property of
the diagnostic's type symbol.

\(fn LOCUS BEG END TYPE TEXT &optional DATA OVERLAY-PROPERTIES)" nil nil)

(autoload 'flymake-diagnostics "flymake" "\
Get Flymake diagnostics in region determined by BEG and END.

If neither BEG or END is supplied, use whole accessible buffer,
otherwise if BEG is non-nil and END is nil, consider only
diagnostics at BEG.

\(fn &optional BEG END)" nil nil)

(autoload 'flymake-diag-region "flymake" "\
Compute BUFFER's region (BEG . END) corresponding to LINE and COL.
If COL is nil, return a region just for LINE.  Return nil if the
region is invalid.  This function saves match data.

\(fn BUFFER LINE &optional COL)" nil nil)

(autoload 'flymake-mode "flymake" "\
Toggle Flymake mode on or off.

This is a minor mode.  If called interactively, toggle the
`Flymake mode' mode.  If the prefix argument is positive, enable
the mode, and if it is zero or negative, disable the mode.

If called from Lisp, toggle the mode if ARG is `toggle'.  Enable
the mode if ARG is nil, omitted, or is a positive number.
Disable the mode if ARG is a negative number.

To check whether the minor mode is enabled in the current buffer,
evaluate `flymake-mode'.

The mode's hook is called both when the mode is enabled and when
it is disabled.

Flymake is an Emacs minor mode for on-the-fly syntax checking.
Flymake collects diagnostic information from multiple sources,
called backends, and visually annotates the buffer with the
results.

Flymake performs these checks while the user is editing.
The customization variables `flymake-start-on-flymake-mode',
`flymake-no-changes-timeout' determine the exact circumstances
whereupon Flymake decides to initiate a check of the buffer.

The commands `flymake-goto-next-error' and
`flymake-goto-prev-error' can be used to navigate among Flymake
diagnostics annotated in the buffer.

The visual appearance of each type of diagnostic can be changed
by setting properties `flymake-overlay-control', `flymake-bitmap'
and `flymake-severity' on the symbols of diagnostic types (like
`:error', `:warning' and `:note').

Activation or deactivation of backends used by Flymake in each
buffer happens via the special hook
`flymake-diagnostic-functions'.

Some backends may take longer than others to respond or complete,
and some may decide to disable themselves if they are not
suitable for the current buffer.  The commands
`flymake-running-backends', `flymake-disabled-backends' and
`flymake-reporting-backends' summarize the situation, as does the
special *Flymake log* buffer.

\(fn &optional ARG)" t nil)

(autoload 'flymake-mode-on "flymake" "\
Turn Flymake mode on." nil nil)

(autoload 'flymake-mode-off "flymake" "\
Turn Flymake mode off." nil nil)

(register-definition-prefixes "flymake" '("flymake-"))

;;;***

(provide 'flymake-autoloads)
;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; flymake-autoloads.el ends here
