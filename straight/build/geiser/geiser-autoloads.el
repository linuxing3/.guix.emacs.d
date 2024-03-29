;;; geiser-autoloads.el --- automatically extracted autoloads  -*- lexical-binding: t -*-
;;
;;; Code:


;;;### (autoloads nil "geiser" "geiser.el" (0 0 0 0))
;;; Generated autoloads from geiser.el

(defconst geiser-elisp-dir (file-name-directory load-file-name) "\
Directory containing Geiser's Elisp files.")

(defconst geiser-scheme-dir (let ((d (expand-file-name "./scheme/" geiser-elisp-dir))) (if (file-directory-p d) d (expand-file-name "../scheme/" geiser-elisp-dir))) "\
Directory containing Geiser's Scheme files.")

(add-to-list 'load-path (directory-file-name geiser-elisp-dir))

(autoload 'geiser-version "geiser-version" "\
Echo Geiser's version." t)

(autoload 'geiser-unload "geiser-reload" "\
Unload all Geiser code." t)

(autoload 'geiser-reload "geiser-reload" "\
Reload Geiser code." t)

(autoload 'geiser "geiser-repl" "\
Start a Geiser REPL, or switch to a running one." t)

(autoload 'run-geiser "geiser-repl" "\
Start a Geiser REPL." t)

(autoload 'geiser-connect "geiser-repl" "\
Start a Geiser REPL connected to a remote server." t)

(autoload 'geiser-connect-local "geiser-repl" "\
Start a Geiser REPL connected to a remote server over a Unix-domain socket." t)

(autoload 'switch-to-geiser "geiser-repl" "\
Switch to a running one Geiser REPL." t)

(autoload 'run-chez "geiser-chez" "\
Start a Geiser Chez REPL." t)

(autoload 'switch-to-chez "geiser-chez" "\
Start a Geiser Chez REPL, or switch to a running one." t)

(autoload 'run-guile "geiser-guile" "\
Start a Geiser Guile REPL." t)

(autoload 'switch-to-guile "geiser-guile" "\
Start a Geiser Guile REPL, or switch to a running one." t)

(autoload 'connect-to-guile "geiser-guile" "\
Connect to a remote Geiser Guile REPL." t)

(autoload 'run-gambit "geiser-gambit" "\
Start a Geiser Gambit REPL." t)

(autoload 'switch-to-gambit "geiser-gambit" "\
Start a Geiser Gambit REPL, or switch to a running one." t)

(autoload 'connect-to-gambit "geiser-gambit" "\
Connect to a remote Geiser Gambit REPL." t)

(autoload 'run-racket "geiser-racket" "\
Start a Geiser Racket REPL." t)

(autoload 'run-gracket "geiser-racket" "\
Start a Geiser GRacket REPL." t)

(autoload 'switch-to-racket "geiser-racket" "\
Start a Geiser Racket REPL, or switch to a running one." t)

(autoload 'connect-to-racket "geiser-racket" "\
Connect to a remote Geiser Racket REPL." t)

(autoload 'run-chicken "geiser-chicken" "\
Start a Geiser Chicken REPL." t)

(autoload 'switch-to-chicken "geiser-chicken" "\
Start a Geiser Chicken REPL, or switch to a running one." t)

(autoload 'connect-to-chicken "geiser-chicken" "\
Connect to a remote Geiser Chicken REPL." t)

(autoload 'run-mit "geiser-mit" "\
Start a Geiser MIT/GNU Scheme REPL." t)

(autoload 'switch-to-mit "geiser-mit" "\
Start a Geiser MIT/GNU Scheme REPL, or switch to a running one." t)

(autoload 'run-chibi "geiser-chibi" "\
Start a Geiser Chibi Scheme REPL." t)

(autoload 'switch-to-chibi "geiser-chibi" "\
Start a Geiser Chibi Scheme REPL, or switch to a running one." t)

(autoload 'geiser-mode "geiser-mode" "\
Minor mode adding Geiser REPL interaction to Scheme buffers." t)

(autoload 'turn-on-geiser-mode "geiser-mode" "\
Enable Geiser's mode (useful in Scheme buffers)." t)

(autoload 'turn-off-geiser-mode "geiser-mode" "\
Disable Geiser's mode (useful in Scheme buffers)." t)

(autoload 'geiser-mode--maybe-activate "geiser-mode")

(mapc (lambda (group) (custom-add-load group (symbol-name group)) (custom-add-load 'geiser (symbol-name group))) '(geiser geiser-repl geiser-autodoc geiser-doc geiser-debug geiser-faces geiser-mode geiser-guile geiser-gambit geiser-image geiser-racket geiser-chicken geiser-chez geiser-chibi geiser-mit geiser-implementation geiser-xref))

(add-hook 'scheme-mode-hook 'geiser-mode--maybe-activate)

(add-to-list 'auto-mode-alist '("\\.rkt\\'" . scheme-mode))

;;;***

;;;### (autoloads nil "geiser-autodoc" "geiser-autodoc.el" (0 0 0
;;;;;;  0))
;;; Generated autoloads from geiser-autodoc.el

(register-definition-prefixes "geiser-autodoc" '("geiser-autodoc-"))

;;;***

;;;### (autoloads nil "geiser-base" "geiser-base.el" (0 0 0 0))
;;; Generated autoloads from geiser-base.el

(register-definition-prefixes "geiser-base" '("geiser--"))

;;;***

;;;### (autoloads nil "geiser-chez" "geiser-chez.el" (0 0 0 0))
;;; Generated autoloads from geiser-chez.el

(register-definition-prefixes "geiser-chez" '("chez" "geiser-chez-"))

;;;***

;;;### (autoloads nil "geiser-chibi" "geiser-chibi.el" (0 0 0 0))
;;; Generated autoloads from geiser-chibi.el

(register-definition-prefixes "geiser-chibi" '("chibi" "geiser-chibi-"))

;;;***

;;;### (autoloads nil "geiser-chicken" "geiser-chicken.el" (0 0 0
;;;;;;  0))
;;; Generated autoloads from geiser-chicken.el

(register-definition-prefixes "geiser-chicken" '("chicken" "connect-to-chicken" "geiser-chicken"))

;;;***

;;;### (autoloads nil "geiser-company" "geiser-company.el" (0 0 0
;;;;;;  0))
;;; Generated autoloads from geiser-company.el

(register-definition-prefixes "geiser-company" '("geiser-company--"))

;;;***

;;;### (autoloads nil "geiser-compile" "geiser-compile.el" (0 0 0
;;;;;;  0))
;;; Generated autoloads from geiser-compile.el

(register-definition-prefixes "geiser-compile" '("geiser-"))

;;;***

;;;### (autoloads nil "geiser-completion" "geiser-completion.el"
;;;;;;  (0 0 0 0))
;;; Generated autoloads from geiser-completion.el

(register-definition-prefixes "geiser-completion" '("geiser-"))

;;;***

;;;### (autoloads nil "geiser-connection" "geiser-connection.el"
;;;;;;  (0 0 0 0))
;;; Generated autoloads from geiser-connection.el

(register-definition-prefixes "geiser-connection" '("geiser-con"))

;;;***

;;;### (autoloads nil "geiser-custom" "geiser-custom.el" (0 0 0 0))
;;; Generated autoloads from geiser-custom.el

(register-definition-prefixes "geiser-custom" '("geiser-custom-"))

;;;***

;;;### (autoloads nil "geiser-debug" "geiser-debug.el" (0 0 0 0))
;;; Generated autoloads from geiser-debug.el

(register-definition-prefixes "geiser-debug" '("geiser-debug-"))

;;;***

;;;### (autoloads nil "geiser-doc" "geiser-doc.el" (0 0 0 0))
;;; Generated autoloads from geiser-doc.el

(register-definition-prefixes "geiser-doc" '("geiser-doc-"))

;;;***

;;;### (autoloads nil "geiser-edit" "geiser-edit.el" (0 0 0 0))
;;; Generated autoloads from geiser-edit.el

(register-definition-prefixes "geiser-edit" '("geiser-"))

;;;***

;;;### (autoloads nil "geiser-eval" "geiser-eval.el" (0 0 0 0))
;;; Generated autoloads from geiser-eval.el

(register-definition-prefixes "geiser-eval" '("geiser-eval--"))

;;;***

;;;### (autoloads nil "geiser-gambit" "geiser-gambit.el" (0 0 0 0))
;;; Generated autoloads from geiser-gambit.el

(register-definition-prefixes "geiser-gambit" '("connect-to-gambit" "gambit" "geiser-gambit-"))

;;;***

;;;### (autoloads nil "geiser-guile" "geiser-guile.el" (0 0 0 0))
;;; Generated autoloads from geiser-guile.el

(register-definition-prefixes "geiser-guile" '("connect-to-guile" "geiser-guile-" "guile"))

;;;***

;;;### (autoloads nil "geiser-image" "geiser-image.el" (0 0 0 0))
;;; Generated autoloads from geiser-image.el

(register-definition-prefixes "geiser-image" '("geiser-"))

;;;***

;;;### (autoloads nil "geiser-impl" "geiser-impl.el" (0 0 0 0))
;;; Generated autoloads from geiser-impl.el

(register-definition-prefixes "geiser-impl" '("define-geiser-implementation" "geiser-" "with--geiser-implementation"))

;;;***

;;;### (autoloads nil "geiser-log" "geiser-log.el" (0 0 0 0))
;;; Generated autoloads from geiser-log.el

(register-definition-prefixes "geiser-log" '("geiser-"))

;;;***

;;;### (autoloads nil "geiser-menu" "geiser-menu.el" (0 0 0 0))
;;; Generated autoloads from geiser-menu.el

(register-definition-prefixes "geiser-menu" '("geiser-menu--"))

;;;***

;;;### (autoloads nil "geiser-mit" "geiser-mit.el" (0 0 0 0))
;;; Generated autoloads from geiser-mit.el

(register-definition-prefixes "geiser-mit" '("geiser-mit-" "mit"))

;;;***

;;;### (autoloads nil "geiser-mode" "geiser-mode.el" (0 0 0 0))
;;; Generated autoloads from geiser-mode.el

(register-definition-prefixes "geiser-mode" '("geiser-" "turn-o"))

;;;***

;;;### (autoloads nil "geiser-popup" "geiser-popup.el" (0 0 0 0))
;;; Generated autoloads from geiser-popup.el

(register-definition-prefixes "geiser-popup" '("geiser-popup-"))

;;;***

;;;### (autoloads nil "geiser-racket" "geiser-racket.el" (0 0 0 0))
;;; Generated autoloads from geiser-racket.el

(register-definition-prefixes "geiser-racket" '("connect-to-racket" "geiser-racket-" "racket" "run-gracket"))

;;;***

;;;### (autoloads nil "geiser-reload" "geiser-reload.el" (0 0 0 0))
;;; Generated autoloads from geiser-reload.el

(register-definition-prefixes "geiser-reload" '("geiser-"))

;;;***

;;;### (autoloads nil "geiser-repl" "geiser-repl.el" (0 0 0 0))
;;; Generated autoloads from geiser-repl.el

(register-definition-prefixes "geiser-repl" '("geiser" "run-geiser" "switch-to-geiser"))

;;;***

;;;### (autoloads nil "geiser-syntax" "geiser-syntax.el" (0 0 0 0))
;;; Generated autoloads from geiser-syntax.el

(register-definition-prefixes "geiser-syntax" '("geiser-syntax--"))

;;;***

;;;### (autoloads nil "geiser-table" "geiser-table.el" (0 0 0 0))
;;; Generated autoloads from geiser-table.el

(register-definition-prefixes "geiser-table" '("geiser-table-"))

;;;***

;;;### (autoloads nil "geiser-version" "geiser-version.el" (0 0 0
;;;;;;  0))
;;; Generated autoloads from geiser-version.el

(register-definition-prefixes "geiser-version" '("geiser-version"))

;;;***

;;;### (autoloads nil "geiser-xref" "geiser-xref.el" (0 0 0 0))
;;; Generated autoloads from geiser-xref.el

(register-definition-prefixes "geiser-xref" '("geiser-xref-"))

;;;***

(provide 'geiser-autoloads)
;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; geiser-autoloads.el ends here
