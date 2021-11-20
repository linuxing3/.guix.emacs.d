  ;; -*- lexical-binding: t; -*-

  ;; The default is 800 kilobytes.  Measured in bytes.
  (setq gc-cons-threshold (* 50 1000 1000))

  ;; Profile emacs startup
  (add-hook 'emacs-startup-hook
            (lambda ()
              (message "*** Emacs loaded in %s seconds with %d garbage collections."
                       (emacs-init-time "%.2f")
                       gcs-done)))

  ;; Silence compiler warnings as they can be pretty disruptive
  (setq native-comp-async-report-warnings-errors nil)

  ;; Set the right directory to store the native comp cache
  (add-to-list 'native-comp-eln-load-path (expand-file-name "eln-cache/" user-emacs-directory))

  (load-file "~/.dotfiles/.guix.emacs.d/lisp/dw-settings.el")

  ;; Load settings for the first time
  (dw/load-system-settings)

  (require 'subr-x)
  (setq dw/is-termux
        (string-suffix-p "Android" (string-trim (shell-command-to-string "uname -a"))))

  (setq dw/is-guix-system (and (eq system-type 'gnu/linux)
                               (require 'f)
                               (string-equal (f-read "/etc/issue")
                                             "\nThis is the GNU system.  Welcome.\n")))

  (unless (featurep 'straight)
    ;; Bootstrap straight.el
    (defvar bootstrap-version)
    (let ((bootstrap-file
           (expand-file-name "straight/repos/straight.el/bootstrap.el" user-emacs-directory))
          (bootstrap-version 5))
      (unless (file-exists-p bootstrap-file)
        (with-current-buffer
            (url-retrieve-synchronously
             "https://raw.githubusercontent.com/raxod502/straight.el/develop/install.el"
             'silent 'inhibit-cookies)
          (goto-char (point-max))
          (eval-print-last-sexp)))
      (load bootstrap-file nil 'nomessage)))

  ;; Use straight.el for use-package expressions
  (straight-use-package 'use-package)

  (straight-use-package '(setup :type git :host nil :repo "https://git.sr.ht/~pkal/setup"))
  (require 'setup)

  ;; Uncomment this for debugging purposes
  ;; (defun dw/log-require (&rest args)
  ;;   (with-current-buffer (get-buffer-create "*require-log*")
  ;;     (insert (format "%s\n"
  ;;                     (file-name-nondirectory (car args))))))
  ;; (add-to-list 'after-load-functions #'dw/log-require)

  ;; Recipe is always a list
  ;; Install via Guix if length == 1 or :guix t is present

  (defvar dw/guix-emacs-packages '()
    "Contains a list of all Emacs package names that must be
  installed via Guix.")

  ;; Examples:
  ;; - (org-roam :straight t)
  ;; - (git-gutter :straight git-gutter-fringe)

  (defun dw/filter-straight-recipe (recipe)
    (let* ((plist (cdr recipe))
           (name (plist-get plist :straight)))
      (cons (if (and name (not (equal name t)))
                name
              (car recipe))
            (plist-put plist :straight nil))))

  (setup-define :pkg
    (lambda (&rest recipe)
      (if (and dw/is-guix-system
               (or (eq (length recipe) 1)
                   (plist-get (cdr recipe) :guix)))
          `(add-to-list 'dw/guix-emacs-packages
                        ,(or (plist-get recipe :guix)
                             (concat "emacs-" (symbol-name (car recipe)))))
        `(straight-use-package ',(dw/filter-straight-recipe recipe))))
    :documentation "Install RECIPE via Guix or straight.el"
    :shorthand #'cadr)

  (setup-define :delay
     (lambda (&rest time)
       `(run-with-idle-timer ,(or time 1)
                             nil ;; Don't repeat
                             (lambda () (require ',(setup-get 'feature)))))
     :documentation "Delay loading the feature until a certain amount of idle time has passed.")

  (setup-define :disabled
    (lambda ()
      `,(setup-quit))
    :documentation "Always stop evaluating the body.")

  (setup-define :load-after
      (lambda (features &rest body)
        (let ((body `(progn
                       (require ',(setup-get 'feature))
                       ,@body)))
          (dolist (feature (if (listp features)
                               (nreverse features)
                             (list features)))
            (setq body `(with-eval-after-load ',feature ,body)))
          body))
    :documentation "Load the current feature after FEATURES."
    :indent 1)

  ;; Change the user-emacs-directory to keep unwanted things out of ~/.guix.emacs.d
  (setq user-emacs-directory (expand-file-name "~/.cache/emacs/")
        url-history-file (expand-file-name "url/history" user-emacs-directory))
  
  ;; Use no-littering to automatically set common paths to the new user-emacs-directory
  (setup (:pkg no-littering)
    (require 'no-littering))
  
  ;; Keep customization settings in a temporary file (thanks Ambrevar!)
  (setq custom-file
        (if (boundp 'server-socket-dir)
            (expand-file-name "custom.el" server-socket-dir)
          (expand-file-name (format "emacs-custom-%s.el" (user-uid)) temporary-file-directory)))
  (load custom-file t)

  ;; Add my library path to load-path
  (push "~/.dotfiles/.guix.emacs.d/lisp" load-path)

  (set-default-coding-systems 'utf-8)

  (server-start)

  (setq dw/exwm-enabled (and (not dw/is-termux)
                             (eq window-system 'x)
                             (seq-contains command-line-args "--use-exwm")))

  (when dw/exwm-enabled
    (require 'dw-desktop))

  (global-set-key (kbd "<escape>") 'keyboard-escape-quit)

  (global-set-key (kbd "C-M-u") 'universal-argument)

  (setup (:pkg undo-tree)
    (setq undo-tree-auto-save-history nil)
    (global-undo-tree-mode 1))

  (setup (:pkg evil)
    ;; Pre-load configuration
    (setq evil-want-integration t)
    (setq evil-want-keybinding nil)
    (setq evil-want-C-u-scroll t)
    (setq evil-want-C-i-jump nil)
    (setq evil-respect-visual-line-mode t)
    (setq evil-undo-system 'undo-tree)

    ;; Activate the Evil
    (evil-mode 1)

    ;; Set Emacs state modes
    (dolist (mode '(custom-mode
                    eshell-mode
                    git-rebase-mode
                    erc-mode
                    circe-server-mode
                    circe-chat-mode
                    circe-query-mode
                    sauron-mode
                    term-mode))
      (add-to-list 'evil-emacs-state-modes mode))

    (define-key evil-insert-state-map (kbd "C-g") 'evil-normal-state)
    (define-key evil-insert-state-map (kbd "C-h") 'evil-delete-backward-char-and-join)

    ;; Use visual line motions even outside of visual-line-mode buffers
    (evil-global-set-key 'motion "j" 'evil-next-visual-line)
    (evil-global-set-key 'motion "k" 'evil-previous-visual-line)

    (unless dw/is-termux
      (defun dw/dont-arrow-me-bro ()
        (interactive)
        (message "Arrow keys are bad, you know?"))

      ;; Disable arrow keys in normal and visual modes
      (define-key evil-normal-state-map (kbd "<left>") 'dw/dont-arrow-me-bro)
      (define-key evil-normal-state-map (kbd "<right>") 'dw/dont-arrow-me-bro)
      (define-key evil-normal-state-map (kbd "<down>") 'dw/dont-arrow-me-bro)
      (define-key evil-normal-state-map (kbd "<up>") 'dw/dont-arrow-me-bro)
      (evil-global-set-key 'motion (kbd "<left>") 'dw/dont-arrow-me-bro)
      (evil-global-set-key 'motion (kbd "<right>") 'dw/dont-arrow-me-bro)
      (evil-global-set-key 'motion (kbd "<down>") 'dw/dont-arrow-me-bro)
      (evil-global-set-key 'motion (kbd "<up>") 'dw/dont-arrow-me-bro))

    (evil-set-initial-state 'messages-buffer-mode 'normal)
    (evil-set-initial-state 'dashboard-mode 'normal))

  (setup (:pkg evil-collection)
    ;; Is this a bug in evil-collection?
    (setq evil-collection-company-use-tng nil)
    (:load-after evil
      (:option evil-collection-outline-bind-tab-p nil
               (remove evil-collection-mode-list) 'lispy
               (remove evil-collection-mode-list) 'org-present)
      (evil-collection-init)))

  (setup (:pkg which-key)
    (diminish 'which-key-mode)
    (which-key-mode)
    (setq which-key-idle-delay 0.3))

  (setup (:pkg general)
    (general-evil-setup t)

    (general-create-definer dw/leader-key-def
      :keymaps '(normal insert visual emacs)
      :prefix "SPC"
      :global-prefix "C-SPC")

    (general-create-definer dw/ctrl-c-keys
      :prefix "C-c"))

  ;; Thanks, but no thanks
  (setq inhibit-startup-message t)

  (unless dw/is-termux
    (scroll-bar-mode -1)        ; Disable visible scrollbar
    (tool-bar-mode -1)          ; Disable the toolbar
    (tooltip-mode -1)           ; Disable tooltips
    (set-fringe-mode 10))       ; Give some breathing room

  (menu-bar-mode -1)            ; Disable the menu bar

  ;; Set up the visible bell
  (setq visible-bell t)

  (unless dw/is-termux
    (setq mouse-wheel-scroll-amount '(1 ((shift) . 1))) ;; one line at a time
    (setq mouse-wheel-progressive-speed nil) ;; don't accelerate scrolling
    (setq mouse-wheel-follow-mouse 't) ;; scroll window under mouse
    (setq scroll-step 1) ;; keyboard scroll one line at a time
    (setq use-dialog-box nil)) ;; Disable dialog boxes since they weren't working in Mac OSX

  (unless dw/is-termux
    (set-frame-parameter (selected-frame) 'alpha '(90 . 90))
    (add-to-list 'default-frame-alist '(alpha . (90 . 90)))
    (set-frame-parameter (selected-frame) 'fullscreen 'maximized)
    (add-to-list 'default-frame-alist '(fullscreen . maximized)))

  (column-number-mode)

  ;; Enable line numbers for some modes
  (dolist (mode '(text-mode-hook
                  prog-mode-hook
                  conf-mode-hook))
    (add-hook mode (lambda () (display-line-numbers-mode 1))))

  ;; Override some modes which derive from the above
  (dolist (mode '(org-mode-hook))
    (add-hook mode (lambda () (display-line-numbers-mode 0))))

  (setq large-file-warning-threshold nil)

  (setq vc-follow-symlinks t)

  (setq ad-redefinition-action 'accept)

  (setup (:pkg spacegray-theme))
  (setup (:pkg doom-themes))
  (unless dw/is-termux
    (load-theme 'doom-palenight t)
    (doom-themes-visual-bell-config))

  ;; Set the font face based on platform
  (pcase system-type
    ((or 'gnu/linux 'windows-nt 'cygwin)
     (set-face-attribute 'default nil
                         :font "JetBrains Mono"
                         :weight 'light
                         :height (dw/system-settings-get 'emacs/default-face-size)))
    ('darwin (set-face-attribute 'default nil :font "Fira Mono" :height 170)))

  ;; Set the fixed pitch face
  (set-face-attribute 'fixed-pitch nil
                      :font "JetBrains Mono"
                      :weight 'light
                      :height (dw/system-settings-get 'emacs/fixed-face-size))

  ;; Set the variable pitch face
  (set-face-attribute 'variable-pitch nil
                      ;; :font "Cantarell"
                      :font "Iosevka Aile"
                      :height (dw/system-settings-get 'emacs/variable-face-size)
                      :weight 'light)

  (setup (:pkg emojify)
    (:hook erc-mode))

  (setq display-time-format "%l:%M %p %b %y"
        display-time-default-load-average nil)

  (setup (:pkg diminish))

    ;; You must run (all-the-icons-install-fonts) one time after
    ;; installing this package!
  
  (setup (:pkg minions)
    (:hook-into doom-modeline-mode))
  
  (setup (:pkg doom-modeline)
    (:hook-into after-init-hook)
    (:option doom-modeline-height 15
             doom-modeline-bar-width 6
             doom-modeline-lsp t
             doom-modeline-github nil
             doom-modeline-mu4e nil
             doom-modeline-irc t
             doom-modeline-minor-modes t
             doom-modeline-persp-name nil
             doom-modeline-buffer-file-name-style 'truncate-except-project
             doom-modeline-major-mode-icon nil)
    (custom-set-faces '(mode-line ((t (:height 0.85))))
                      '(mode-line-inactive ((t (:height 0.85))))))

  (setup (:pkg perspective)
    (:global "C-M-k" persp-switch
             "C-M-n" persp-next
             "C-x k" persp-kill-buffer*)
    (:option persp-initial-frame-name "Main")
    ;; Running `persp-mode' multiple times resets the perspective list...
    (unless (equal persp-mode t)
      (persp-mode)))

  (setup (:pkg alert)
    (:option alert-default-style 'notifications))

  (setup (:pkg super-save)
    (:delay)
    (:when-loaded
      (super-save-mode +1)
      (diminish 'super-save-mode)
      (setq super-save-auto-save-when-idle t)))

  ;; Revert Dired and other buffers
  (setq global-auto-revert-non-file-buffers t)

  ;; Revert buffers when the underlying file has changed
  (global-auto-revert-mode 1)

  (dw/leader-key-def
    "t"  '(:ignore t :which-key "toggles")
    "tw" 'whitespace-mode
    "tt" '(counsel-load-theme :which-key "choose theme"))

  (setup (:require paren)
    (set-face-attribute 'show-paren-match-expression nil :background "#363e4a")
    (show-paren-mode 1))

  (setq display-time-world-list
    '(("Etc/UTC" "UTC")
      ("America/Los_Angeles" "Seattle")
      ("America/New_York" "New York")
      ("Europe/Athens" "Athens")
      ("Pacific/Auckland" "Auckland")
      ("Asia/Shanghai" "Shanghai")
      ("Asia/Kolkata" "Hyderabad")))
  (setq display-time-world-time-format "%a, %d %b %I:%M %p %Z")

  (unless (or dw/is-termux
              (eq system-type 'windows-nt))
    (setq epa-pinentry-mode 'loopback)
    (pinentry-start))

  ;; Set default connection mode to SSH
  (setq tramp-default-method "ssh")

  (defun dw/show-server-edit-buffer (buffer)
    ;; TODO: Set a transient keymap to close with 'C-c C-c'
    (split-window-vertically -15)
    (other-window 1)
    (set-buffer buffer))
  
  ;; (setq server-window #'dw/show-server-edit-buffer)

  (setq-default tab-width 2)
  (setq-default evil-shift-width tab-width)

  (setq-default indent-tabs-mode nil)

  (setup (:pkg evil-nerd-commenter)
    (:global "M-/" evilnc-comment-or-uncomment-lines))

  (setup (:pkg ws-butler)
    (:hook-into text-mode prog-mode))

  (setup (:pkg parinfer :guix "emacs-parinfer-mode")
    (:disabled)
    (:hook-into clojure-mode
                emacs-lisp-mode
                common-lisp-mode
                scheme-mode
                lisp-mode)
    (setq parinfer-extensions
          '(defaults                 ; should be included.
             pretty-parens           ; different paren styles for different modes.
             evil                    ; If you use Evil.
             smart-tab               ; C-b & C-f jump positions and smart shift with tab & S-tab.
             smart-yank))            ; Yank behavior depend on mode.

    (dw/leader-key-def
      "tp" 'parinfer-toggle-mode))

  (setup (:pkg origami :guix "emacs-origami-el")
    (:hook-into yaml-mode))

  (setup (:pkg dotcrafter
               :host github
               :repo "daviwil/dotcrafter.el"
               :branch "main")
    (:option dotcrafter-org-files '("Emacs.org"
                                    "Desktop.org"
                                    "Systems.org"
                                    "Mail.org"
                                    "Workflow.org"))
    (require 'dotcrafter)
    (dotcrafter-mode))

  (defun dw/org-file-jump-to-heading (org-file heading-title)
    (interactive)
    (find-file (expand-file-name org-file))
    (goto-char (point-min))
    (search-forward (concat "* " heading-title))
    (org-overview)
    (org-reveal)
    (org-show-subtree)
    (forward-line))

  (defun dw/org-file-show-headings (org-file)
    (interactive)
    (find-file (expand-file-name org-file))
    (counsel-org-goto)
    (org-overview)
    (org-reveal)
    (org-show-subtree)
    (forward-line))

  (dw/leader-key-def
    "fn" '((lambda () (interactive) (counsel-find-file "~/Notes/")) :which-key "notes")
    "fd"  '(:ignore t :which-key "dotfiles")
    "fdd" '((lambda () (interactive) (find-file "~/.dotfiles/Desktop.org")) :which-key "desktop")
    "fde" '((lambda () (interactive) (find-file (expand-file-name "~/.dotfiles/Emacs.org"))) :which-key "edit config")
    "fdE" '((lambda () (interactive) (dw/org-file-show-headings "~/.dotfiles/Emacs.org")) :which-key "edit config")
    "fdm" '((lambda () (interactive) (find-file "~/.dotfiles/Mail.org")) :which-key "mail")
    "fdM" '((lambda () (interactive) (counsel-find-file "~/.dotfiles/.config/guix/manifests/")) :which-key "manifests")
    "fds" '((lambda () (interactive) (dw/org-file-jump-to-heading "~/.dotfiles/Systems.org" "Base Configuration")) :which-key "base system")
    "fdS" '((lambda () (interactive) (dw/org-file-jump-to-heading "~/.dotfiles/Systems.org" system-name)) :which-key "this system")
    "fdp" '((lambda () (interactive) (dw/org-file-jump-to-heading "~/.dotfiles/Desktop.org" "Panel via Polybar")) :which-key "polybar")
    "fdw" '((lambda () (interactive) (find-file (expand-file-name "~/.dotfiles/Workflow.org"))) :which-key "workflow")
    "fdv" '((lambda () (interactive) (find-file "~/.dotfiles/.config/vimb/config")) :which-key "vimb"))

  (setup (:pkg hydra)
    (require 'hydra))

  (setup savehist
    (setq history-length 25)
    (savehist-mode 1))
  
  ;; Individual history elements can be configured separately
  ;;(put 'minibuffer-history 'history-length 25)
  ;;(put 'evil-ex-history 'history-length 50)
  ;;(put 'kill-ring 'history-length 25))

  (defun dw/minibuffer-backward-kill (arg)
    "When minibuffer is completing a file name delete up to parent
  folder, otherwise delete a word"
    (interactive "p")
    (if minibuffer-completing-file-name
        ;; Borrowed from https://github.com/raxod502/selectrum/issues/498#issuecomment-803283608
        (if (string-match-p "/." (minibuffer-contents))
            (zap-up-to-char (- arg) ?/)
          (delete-minibuffer-contents))
        (delete-word (- arg))))

  (setup (:pkg vertico)
    ;; :straight '(vertico :host github
    ;;                     :repo "minad/vertico"
    ;;                     :branch "main")
    (vertico-mode)
    (:with-map vertico-map
      (:bind "C-j" vertico-next
             "C-k" vertico-previous
             "C-f" vertico-exit))
    (:with-map minibuffer-local-map
      (:bind "M-h" dw/minibuffer-backward-kill))
    (:option vertico-cycle t)
    (custom-set-faces '(vertico-current ((t (:background "#3a3f5a"))))))

  (setup (:pkg corfu :host github :repo "minad/corfu")
    (:with-map corfu-map
      (:bind "C-j" corfu-next
             "C-k" corfu-previous
             "TAB" corfu-insert
             "C-f" corfu-insert))
    (:option corfu-cycle t)
    (corfu-global-mode))

  (setup (:pkg orderless)
    (require 'orderless)
    (setq completion-styles '(orderless)
          completion-category-defaults nil
          completion-category-overrides '((file (styles . (partial-completion))))))

  (setup (:pkg consult)
    (require 'consult)
    (:global "C-s" consult-line
             "C-M-l" consult-imenu
             "C-M-j" persp-switch-to-buffer*)
  
    (:with-map minibuffer-local-map
      (:bind "C-r" consult-history))
  
    (defun dw/get-project-root ()
      (when (fboundp 'projectile-project-root)
        (projectile-project-root)))
  
    (:option consult-project-root-function #'dw/get-project-root
             completion-in-region-function #'consult-completion-in-region))

  (setup (:pkg consult-dir :straight t)
    (:global "C-x C-d" consult-dir)
    (:with-map vertico-map
      (:bind "C-x C-d" consult-dir
             "C-x C-j" consult-dir-jump-file))
    (:option consult-dir-project-list-function nil))

  ;; Thanks Karthik!
  (defun eshell/z (&optional regexp)
    "Navigate to a previously visited directory in eshell."
    (let ((eshell-dirs (delete-dups (mapcar 'abbreviate-file-name
                                            (ring-elements eshell-last-dir-ring)))))
      (cond
       ((and (not regexp) (featurep 'consult-dir))
        (let* ((consult-dir--source-eshell `(:name "Eshell"
                                                   :narrow ?e
                                                   :category file
                                                   :face consult-file
                                                   :items ,eshell-dirs))
               (consult-dir-sources (cons consult-dir--source-eshell consult-dir-sources)))
          (eshell/cd (substring-no-properties (consult-dir--pick "Switch directory: ")))))
       (t (eshell/cd (if regexp (eshell-find-previous-directory regexp)
                       (completing-read "cd: " eshell-dirs)))))))

  (setup (:pkg marginalia)
    (:option marginalia-annotators '(marginalia-annotators-heavy
                                     marginalia-annotators-light
                                     nil))
    (marginalia-mode))

  (setup (:pkg embark)
    (:also-load embark-consult)
    (:global "C-S-a" embark-act)
    (:with-map minibuffer-local-map
     (:bind "C-d" embark-act))

    ;; Show Embark actions via which-key
    (setq embark-action-indicator
          (lambda (map)
            (which-key--show-keymap "Embark" map nil nil 'no-paging)
            #'which-key--hide-popup-ignore-command)
          embark-become-indicator embark-action-indicator))

  ;; Binding will be set by desktop config
  (setup (:pkg app-launcher))

  (setup (:pkg avy)
    (dw/leader-key-def
      "j"   '(:ignore t :which-key "jump")
      "jj"  '(avy-goto-char :which-key "jump to char")
      "jw"  '(avy-goto-word-0 :which-key "jump to word")
      "jl"  '(avy-goto-line :which-key "jump to line")))

  (setup (:pkg bufler :straight t)
    (:disabled)
    (:global "C-M-j" bufler-switch-buffer
             "C-M-k" bufler-workspace-frame-set)
    (:when-loaded
     (progn
       :config
       (evil-collection-define-key 'normal 'bufler-list-mode-map
         (kbd "RET") 'bufler-list-buffer-switch
         (kbd "M-RET") 'bufler-list-buffer-peek
         "D" 'bufler-list-buffer-kill)

       (setf bufler-groups
             (bufler-defgroups
              ;; Subgroup collecting all named workspaces.
              (group (auto-workspace))
              ;; Subgroup collecting buffers in a projectile project.
              (group (auto-projectile))
              ;; Grouping browser windows
              (group
               (group-or "Browsers"
                         (name-match "Vimb" (rx bos "vimb"))
                         (name-match "Qutebrowser" (rx bos "Qutebrowser"))
                         (name-match "Chromium" (rx bos "Chromium"))))
              (group
               (group-or "Chat"
                         (mode-match "Telega" (rx bos "telega-"))))
              (group
               ;; Subgroup collecting all `help-mode' and `info-mode' buffers.
               (group-or "Help/Info"
                         (mode-match "*Help*" (rx bos (or "help-" "helpful-")))
                         ;; (mode-match "*Helpful*" (rx bos "helpful-"))
                         (mode-match "*Info*" (rx bos "info-"))))
              (group
               ;; Subgroup collecting all special buffers (i.e. ones that are not
               ;; file-backed), except `magit-status-mode' buffers (which are allowed to fall
               ;; through to other groups, so they end up grouped with their project buffers).
               (group-and "*Special*"
                          (name-match "**Special**"
                                      (rx bos "*" (or "Messages" "Warnings" "scratch" "Backtrace" "Pinentry") "*"))
                          (lambda (buffer)
                            (unless (or (funcall (mode-match "Magit" (rx bos "magit-status"))
                                                 buffer)
                                        (funcall (mode-match "Dired" (rx bos "dired"))
                                                 buffer)
                                        (funcall (auto-file) buffer))
                              "*Special*"))))
              ;; Group remaining buffers by major mode.
              (auto-mode))))))

  (setup (:pkg default-text-scale)
    (default-text-scale-mode))

  (setup (:pkg ace-window)
    (:global "M-o" ace-window)
    (:option aw-scope 'frame
             aw-keys '(?a ?s ?d ?f ?g ?h ?j ?k ?l)
             aw-minibuffer-flag t)
    (ace-window-display-mode 1))

  (setup winner
    (winner-mode)
    (define-key evil-window-map "u" 'winner-undo)
    (define-key evil-window-map "U" 'winner-redo))

  (setup (:pkg visual-fill-column)
    (setq visual-fill-column-width 110
          visual-fill-column-center-text t)
    (:hook-into org-mode))

  ;; (setq display-buffer-base-action
  ;;       '(display-buffer-reuse-mode-window
  ;;         display-buffer-reuse-window
  ;;         display-buffer-same-window))

  ;; If a popup does happen, don't resize windows to be equal-sized
  (setq even-window-sizes nil)

  (defun dw/popper-window-height (window)
    (let (buffer-mode (with-current-buffer (window-buffer window)
                        major-mode))
      (pcase buffer-mode
        ('exwm-mode 40)
        (_ 15))))

  (setup (:pkg popper
               :host github
               :repo "karthink/popper"
               :build (:not autoloads))
    (:global "C-M-'" popper-toggle-latest
             "M-'" popper-cycle
             "C-M-\"" popper-toggle-type)
    (:option popper-window-height 12
             ;; (popper-window-height
             ;; (lambda (window)
             ;;   (let ((buffer-mode (with-current-buffer (window-buffer window)
             ;;                        major-mode)))
             ;;     (message "BUFFER MODE: %s" buffer-mode)
             ;;     (pcase buffer-mode
             ;;       ('exwm-mode 40)
             ;;       ('helpful-mode 20)
             ;;       ('eshell-mode (progn (message "eshell!") 10))
             ;;       (_ 15)))))
             popper-reference-buffers '("^\\*eshell\\*"
                                        "^vterm"
                                        help-mode
                                        helpful-mode
                                        compilation-mode))
    (require 'popper) ;; Needed because I disabled autoloads
    (popper-mode 1))

  (setup (:pkg password-store)
    (setq password-store-password-length 12)
    (dw/leader-key-def
      "ap" '(:ignore t :which-key "pass")
      "app" 'password-store-copy
      "api" 'password-store-insert
      "apg" 'password-store-generate))

  (setup (:pkg auth-source-pass)
    (auth-source-pass-enable))

  (setup (:pkg oauth2 :straight t))

  (setup (:pkg all-the-icons-dired))
  (setup (:pkg dired-single))
  (setup (:pkg dired-ranger))
  (setup (:pkg dired-collapse))

  (setup dired
    (setq dired-listing-switches "-agho --group-directories-first"
          dired-omit-files "^\\.[^.].*"
          dired-omit-verbose nil
          dired-hide-details-hide-symlink-targets nil
          delete-by-moving-to-trash t)

    (autoload 'dired-omit-mode "dired-x")

    (add-hook 'dired-load-hook
              (lambda ()
                (interactive)
                (dired-collapse)))

    (add-hook 'dired-mode-hook
              (lambda ()
                (interactive)
                (dired-omit-mode 1)
                (dired-hide-details-mode 1)
                (unless (or dw/is-termux
                            (s-equals? "/gnu/store/" (expand-file-name default-directory)))
                  (all-the-icons-dired-mode 1))
                (hl-line-mode 1)))

    (evil-collection-define-key 'normal 'dired-mode-map
      "h" 'dired-single-up-directory
      "H" 'dired-omit-mode
      "l" 'dired-single-buffer
      "y" 'dired-ranger-copy
      "X" 'dired-ranger-move
      "p" 'dired-ranger-paste))

  (setup (:pkg dired-rainbow)
    (:load-after dired
     (dired-rainbow-define-chmod directory "#6cb2eb" "d.*")
     (dired-rainbow-define html "#eb5286" ("css" "less" "sass" "scss" "htm" "html" "jhtm" "mht" "eml" "mustache" "xhtml"))
     (dired-rainbow-define xml "#f2d024" ("xml" "xsd" "xsl" "xslt" "wsdl" "bib" "json" "msg" "pgn" "rss" "yaml" "yml" "rdata"))
     (dired-rainbow-define document "#9561e2" ("docm" "doc" "docx" "odb" "odt" "pdb" "pdf" "ps" "rtf" "djvu" "epub" "odp" "ppt" "pptx"))
     (dired-rainbow-define markdown "#ffed4a" ("org" "etx" "info" "markdown" "md" "mkd" "nfo" "pod" "rst" "tex" "textfile" "txt"))
     (dired-rainbow-define database "#6574cd" ("xlsx" "xls" "csv" "accdb" "db" "mdb" "sqlite" "nc"))
     (dired-rainbow-define media "#de751f" ("mp3" "mp4" "mkv" "MP3" "MP4" "avi" "mpeg" "mpg" "flv" "ogg" "mov" "mid" "midi" "wav" "aiff" "flac"))
     (dired-rainbow-define image "#f66d9b" ("tiff" "tif" "cdr" "gif" "ico" "jpeg" "jpg" "png" "psd" "eps" "svg"))
     (dired-rainbow-define log "#c17d11" ("log"))
     (dired-rainbow-define shell "#f6993f" ("awk" "bash" "bat" "sed" "sh" "zsh" "vim"))
     (dired-rainbow-define interpreted "#38c172" ("py" "ipynb" "rb" "pl" "t" "msql" "mysql" "pgsql" "sql" "r" "clj" "cljs" "scala" "js"))
     (dired-rainbow-define compiled "#4dc0b5" ("asm" "cl" "lisp" "el" "c" "h" "c++" "h++" "hpp" "hxx" "m" "cc" "cs" "cp" "cpp" "go" "f" "for" "ftn" "f90" "f95" "f03" "f08" "s" "rs" "hi" "hs" "pyc" ".java"))
     (dired-rainbow-define executable "#8cc4ff" ("exe" "msi"))
     (dired-rainbow-define compressed "#51d88a" ("7z" "zip" "bz2" "tgz" "txz" "gz" "xz" "z" "Z" "jar" "war" "ear" "rar" "sar" "xpi" "apk" "xz" "tar"))
     (dired-rainbow-define packaged "#faad63" ("deb" "rpm" "apk" "jad" "jar" "cab" "pak" "pk3" "vdf" "vpk" "bsp"))
     (dired-rainbow-define encrypted "#ffed4a" ("gpg" "pgp" "asc" "bfe" "enc" "signature" "sig" "p12" "pem"))
     (dired-rainbow-define fonts "#6cb2eb" ("afm" "fon" "fnt" "pfb" "pfm" "ttf" "otf"))
     (dired-rainbow-define partition "#e3342f" ("dmg" "iso" "bin" "nrg" "qcow" "toast" "vcd" "vmdk" "bak"))
     (dired-rainbow-define vc "#0074d9" ("git" "gitignore" "gitattributes" "gitmodules"))
     (dired-rainbow-define-chmod executable-unix "#38c172" "-.*x.*")))

  ;; (defun dw/dired-link (path)
  ;;   (lexical-let ((target path))
  ;;     (lambda () (interactive) (message "Path: %s" target) (dired target))))

  ;; (dw/leader-key-def
  ;;   "d"   '(:ignore t :which-key "dired")
  ;;   "dd"  '(dired :which-key "Here")
  ;;   "dh"  `(,(dw/dired-link "~") :which-key "Home")
  ;;   "dn"  `(,(dw/dired-link "~/Notes") :which-key "Notes")
  ;;   "do"  `(,(dw/dired-link "~/Downloads") :which-key "Downloads")
  ;;   "dp"  `(,(dw/dired-link "~/Pictures") :which-key "Pictures")
  ;;   "dv"  `(,(dw/dired-link "~/Videos") :which-key "Videos")
  ;;   "d."  `(,(dw/dired-link "~/.dotfiles") :which-key "dotfiles")
  ;;   "de"  `(,(dw/dired-link "~/.guix.emacs.d") :which-key ".guix.emacs.d"))

  (setup (:pkg openwith)
    (unless dw/is-termux
      (require 'openwith)
      (setq openwith-associations
            (list
             (list (openwith-make-extension-regexp
                    '("mpg" "mpeg" "mp3" "mp4"
                      "avi" "wmv" "wav" "mov" "flv"
                      "ogm" "ogg" "mkv"))
                   "mpv"
                   '(file))
             (list (openwith-make-extension-regexp
                    '("xbm" "pbm" "pgm" "ppm" "pnm"
                      "png" "gif" "bmp" "tif" "jpeg")) ;; Removed jpg because Telega was
                   ;; causing feh to be opened...
                   "feh"
                   '(file))
             (list (openwith-make-extension-regexp
                    '("pdf"))
                   "zathura"
                   '(file))))))

  ;; TODO: Mode this to another section
  (setq-default fill-column 80)
  
  ;; Turn on indentation and auto-fill mode for Org files
  (defun dw/org-mode-setup ()
    (org-indent-mode)
    (variable-pitch-mode 1)
    (auto-fill-mode 0)
    (visual-line-mode 1)
    (setq evil-auto-indent nil)
    (diminish org-indent-mode))
  
  ;; Make sure Straight pulls Org from Guix
  (when dw/is-guix-system
    (straight-use-package '(org :type built-in)))
  
  (setup (:pkg org)
    (:also-load org-tempo dw-org dw-workflow)
    (:hook dw/org-mode-setup)
    (setq org-ellipsis " ▾"
          org-hide-emphasis-markers t
          org-src-fontify-natively t
          org-fontify-quote-and-verse-blocks t
          org-src-tab-acts-natively t
          org-edit-src-content-indentation 2
          org-hide-block-startup nil
          org-src-preserve-indentation nil
          org-startup-folded 'content
          org-cycle-separator-lines 2
          org-capture-bookmark nil)
  
    (setq org-modules
      '(org-crypt
          org-habit
          org-bookmark
          org-eshell
          org-irc))
  
    (setq org-refile-targets '((nil :maxlevel . 1)
                               (org-agenda-files :maxlevel . 1)))
  
    (setq org-outline-path-complete-in-steps nil)
    (setq org-refile-use-outline-path t)
  
    (evil-define-key '(normal insert visual) org-mode-map (kbd "C-j") 'org-next-visible-heading)
    (evil-define-key '(normal insert visual) org-mode-map (kbd "C-k") 'org-previous-visible-heading)
  
    (evil-define-key '(normal insert visual) org-mode-map (kbd "M-j") 'org-metadown)
    (evil-define-key '(normal insert visual) org-mode-map (kbd "M-k") 'org-metaup)
  
    (org-babel-do-load-languages
      'org-babel-load-languages
      '((emacs-lisp . t)
        (ledger . t)))
  
    (push '("conf-unix" . conf-unix) org-src-lang-modes))

  (unless dw/is-termux
    (setup (:pkg org-superstar)
      (:load-after org)
      (:hook-into org-mode)
      (:option org-superstar-remove-leading-stars t
               org-superstar-headline-bullets-list '("◉" "○" "●" "○" "●" "○" "●"))))
  
  ;; Replace list hyphen with dot
  ;; (font-lock-add-keywords 'org-mode
  ;;                         '(("^ *\\([-]\\) "
  ;;                             (0 (prog1 () (compose-region (match-beginning 1) (match-end 1) "•"))))))
  
  (setup org-faces
    ;; Make sure org-indent face is available
    (:also-load org-indent)
    (:when-loaded
      ;; Increase the size of various headings
      (set-face-attribute 'org-document-title nil :font "Iosevka Aile" :weight 'bold :height 1.3)
    
      (dolist (face '((org-level-1 . 1.2)
                      (org-level-2 . 1.1)
                      (org-level-3 . 1.05)
                      (org-level-4 . 1.0)
                      (org-level-5 . 1.1)
                      (org-level-6 . 1.1)
                      (org-level-7 . 1.1)
                      (org-level-8 . 1.1)))
        (set-face-attribute (car face) nil :font "Iosevka Aile" :weight 'medium :height (cdr face)))
  
      ;; Ensure that anything that should be fixed-pitch in Org files appears that way
      (set-face-attribute 'org-block nil :foreground nil :inherit 'fixed-pitch)
      (set-face-attribute 'org-table nil  :inherit 'fixed-pitch)
      (set-face-attribute 'org-formula nil  :inherit 'fixed-pitch)
      (set-face-attribute 'org-code nil   :inherit '(shadow fixed-pitch))
      (set-face-attribute 'org-indent nil :inherit '(org-hide fixed-pitch))
      (set-face-attribute 'org-verbatim nil :inherit '(shadow fixed-pitch))
      (set-face-attribute 'org-special-keyword nil :inherit '(font-lock-comment-face fixed-pitch))
      (set-face-attribute 'org-meta-line nil :inherit '(font-lock-comment-face fixed-pitch))
      (set-face-attribute 'org-checkbox nil :inherit 'fixed-pitch)
  
      ;; Get rid of the background on column views
      (set-face-attribute 'org-column nil :background nil)
      (set-face-attribute 'org-column-title nil :background nil)))
  
  ;; TODO: Others to consider
  ;; '(org-document-info-keyword ((t (:inherit (shadow fixed-pitch)))))
  ;; '(org-meta-line ((t (:inherit (font-lock-comment-face fixed-pitch)))))
  ;; '(org-property-value ((t (:inherit fixed-pitch))) t)
  ;; '(org-special-keyword ((t (:inherit (font-lock-comment-face fixed-pitch)))))
  ;; '(org-table ((t (:inherit fixed-pitch :foreground "#83a598"))))
  ;; '(org-tag ((t (:inherit (shadow fixed-pitch) :weight bold :height 0.8))))
  ;; '(org-verbatim ((t (:inherit (shadow fixed-pitch))))))

  ;; This is needed as of Org 9.2
  (setup org-tempo
    (:when-loaded
      (add-to-list 'org-structure-template-alist '("sh" . "src sh"))
      (add-to-list 'org-structure-template-alist '("el" . "src emacs-lisp"))
      (add-to-list 'org-structure-template-alist '("li" . "src lisp"))
      (add-to-list 'org-structure-template-alist '("sc" . "src scheme"))
      (add-to-list 'org-structure-template-alist '("ts" . "src typescript"))
      (add-to-list 'org-structure-template-alist '("py" . "src python"))
      (add-to-list 'org-structure-template-alist '("go" . "src go"))
      (add-to-list 'org-structure-template-alist '("yaml" . "src yaml"))
      (add-to-list 'org-structure-template-alist '("json" . "src json"))))

  (setup (:pkg org-pomodoro)
    (setq org-pomodoro-start-sound "~/.dotfiles/.guix.emacs.d/sounds/focus_bell.wav")
    (setq org-pomodoro-short-break-sound "~/.dotfiles/.guix.emacs.d/sounds/three_beeps.wav")
    (setq org-pomodoro-long-break-sound "~/.dotfiles/.guix.emacs.d/sounds/three_beeps.wav")
    (setq org-pomodoro-finished-sound "~/.dotfiles/.guix.emacs.d/sounds/meditation_bell.wav")

    (dw/leader-key-def
      "op"  '(org-pomodoro :which-key "pomodoro")))

  (require 'org-protocol)

  (setup (:pkg evil-org)
    (:hook-into org-mode org-agenda-mode)
    (require 'evil-org)
    (require 'evil-org-agenda)
    (evil-org-set-key-theme '(navigation todo insert textobjects additional))
    (evil-org-agenda-set-keys))

  (dw/leader-key-def
    "o"   '(:ignore t :which-key "org mode")

    "oi"  '(:ignore t :which-key "insert")
    "oil" '(org-insert-link :which-key "insert link")

    "on"  '(org-toggle-narrow-to-subtree :which-key "toggle narrow")

    "os"  '(dw/counsel-rg-org-files :which-key "search notes")

    "oa"  '(org-agenda :which-key "status")
    "ot"  '(org-todo-list :which-key "todos")
    "oc"  '(org-capture t :which-key "capture")
    "ox"  '(org-export-dispatch t :which-key "export"))

  (setup (:pkg org-make-toc)
    (:hook-into org-mode))

  (setup (:pkg org-caldav)
    (:delay)
    (setq org-caldav-url "https://caldav.fastmail.com/dav/calendars/user/daviwil@fastmail.fm/"
          ;; org-caldav-files '("~/Notes/Calendar/Personal.org" "~/Notes/Calendar/Work.org")
          ;; org-caldav-inbox '("~/Notes/Calendar/Personal.org" "~/Notes/Calendar/Work.org")
          org-caldav-calendar-id "fe098bfb-0726-4e10-bff2-55f8278c8a56"
          org-caldav-files '("~/Notes/Calendar/Personal.org")
          org-caldav-inbox "~/Notes/Calendar/PersonalInbox.org"
          org-caldav-calendars
           '((:calendar-id "fe098bfb-0726-4e10-bff2-55f8278c8a56"
              :files ("~/Notes/Calendar/Personal.org")
              :inbox "~/Notes/Calendar/PersonalInbox.org"))
             ;; (:calendar-id "8f150437-cc57-4ba0-9200-d1d98389e2e4"
             ;;  :files ("~/Notes/Calendar/Work.org")
             ;;  :inbox "~/Notes/Calendar/Work.org"))
          org-caldav-delete-org-entries 'always
          org-caldav-delete-calendar-entries 'never))

  ;; (use-package org-wild-notifier
  ;;   :after org
  ;;   :config
  ;;   ; Make sure we receive notifications for non-TODO events
  ;;   ; like those synced from Google Calendar
  ;;   (setq org-wild-notifier-keyword-whitelist nil)
  ;;   (setq org-wild-notifier-notification-title "Agenda Reminder")
  ;;   (setq org-wild-notifier-alert-time 15)
  ;;   (org-wild-notifier-mode))

  (defun dw/org-present-prepare-slide ()
    (org-overview)
    (org-show-entry)
    (org-show-children))

  (defun dw/org-present-hook ()
    (setq-local face-remapping-alist '((default (:height 1.5) variable-pitch)
                                       (header-line (:height 4.5) variable-pitch)
                                       (org-document-title (:height 1.75) org-document-title)
                                       (org-code (:height 1.55) org-code)
                                       (org-verbatim (:height 1.55) org-verbatim)
                                       (org-block (:height 1.25) org-block)
                                       (org-block-begin-line (:height 0.7) org-block)))
    (setq header-line-format " ")
    (org-appear-mode -1)
    (org-display-inline-images)
    (dw/org-present-prepare-slide)
    (dw/kill-panel))

  (defun dw/org-present-quit-hook ()
    (setq-local face-remapping-alist '((default variable-pitch default)))
    (setq header-line-format nil)
    (org-present-small)
    (org-remove-inline-images)
    (org-appear-mode 1)
    (dw/start-panel))

  (defun dw/org-present-prev ()
    (interactive)
    (org-present-prev)
    (dw/org-present-prepare-slide))

  (defun dw/org-present-next ()
    (interactive)
    (org-present-next)
    (dw/org-present-prepare-slide)
    (when (fboundp 'live-crafter-add-timestamp)
      (live-crafter-add-timestamp (substring-no-properties (org-get-heading t t t t)))))

  (setup (:pkg org-present)
    (:with-map org-present-mode-keymap
      (:bind "C-c C-j" dw/org-present-next
             "C-c C-k" dw/org-present-prev))
    (:hook dw/org-present-hook)
    (:with-hook org-present-mode-quit-hook
      (:hook dw/org-present-quit-hook)))

  (defvar dw/org-roam-project-template
    '("p" "project" plain "** TODO %?"
      :if-new (file+head+olp "%<%Y%m%d%H%M%S>-${slug}.org"
                             "#+title: ${title}\n#+category: ${title}\n#+filetags: Project\n"
                             ("Tasks"))))
  
  (defun my/org-roam-filter-by-tag (tag-name)
    (lambda (node)
      (member tag-name (org-roam-node-tags node))))
  
  (defun my/org-roam-list-notes-by-tag (tag-name)
    (mapcar #'org-roam-node-file
            (seq-filter
             (my/org-roam-filter-by-tag tag-name)
             (org-roam-node-list))))
  
  (defun org-roam-node-insert-immediate (arg &rest args)
    (interactive "P")
    (let ((args (push arg args))
          (org-roam-capture-templates (list (append (car org-roam-capture-templates)
                                                    '(:immediate-finish t)))))
      (apply #'org-roam-node-insert args)))
  
  (defun dw/org-roam-goto-month ()
    (interactive)
    (org-roam-capture- :goto (when (org-roam-node-from-title-or-alias (format-time-string "%Y-%B")) '(4))
                       :node (org-roam-node-create)
                       :templates '(("m" "month" plain "\n* Goals\n\n%?* Summary\n\n"
                                     :if-new (file+head "%<%Y-%B>.org"
                                                        "#+title: %<%Y-%B>\n#+filetags: Project\n")
                                     :unnarrowed t))))
  
  (defun dw/org-roam-goto-year ()
    (interactive)
    (org-roam-capture- :goto (when (org-roam-node-from-title-or-alias (format-time-string "%Y")) '(4))
                       :node (org-roam-node-create)
                       :templates '(("y" "year" plain "\n* Goals\n\n%?* Summary\n\n"
                                     :if-new (file+head "%<%Y>.org"
                                                        "#+title: %<%Y>\n#+filetags: Project\n")
                                     :unnarrowed t))))
  
  (defun dw/org-roam-capture-task ()
    (interactive)
    ;; Add the project file to the agenda after capture is finished
    (add-hook 'org-capture-after-finalize-hook #'my/org-roam-project-finalize-hook)
  
    ;; Capture the new task, creating the project file if necessary
    (org-roam-capture- :node (org-roam-node-read
                              nil
                              (my/org-roam-filter-by-tag "Project"))
                       :templates (list dw/org-roam-project-template)))
  
  (defun my/org-roam-refresh-agenda-list ()
    (interactive)
    (setq org-agenda-files (my/org-roam-list-notes-by-tag "Project")))
  
  (defhydra dw/org-roam-jump-menu (:hint nil)
    "
  ^Dailies^        ^Capture^       ^Jump^
  ^^^^^^^^-------------------------------------------------
  _t_: today       _T_: today       _m_: current month
  _r_: tomorrow    _R_: tomorrow    _e_: current year
  _y_: yesterday   _Y_: yesterday   ^ ^
  _d_: date        ^ ^              ^ ^
  "
    ("t" org-roam-dailies-goto-today)
    ("r" org-roam-dailies-goto-tomorrow)
    ("y" org-roam-dailies-goto-yesterday)
    ("d" org-roam-dailies-goto-date)
    ("T" org-roam-dailies-capture-today)
    ("R" org-roam-dailies-capture-tomorrow)
    ("Y" org-roam-dailies-capture-yesterday)
    ("m" dw/org-roam-goto-month)
    ("e" dw/org-roam-goto-year)
    ("c" nil "cancel"))
  
  (setup (:pkg org-roam :straight t)
    (setq org-roam-v2-ack t)
    (setq dw/daily-note-filename "%<%Y-%m-%d>.org"
          dw/daily-note-header "#+title: %<%Y-%m-%d %a>\n\n[[roam:%<%Y-%B>]]\n\n")
  
    (:when-loaded
      (org-roam-db-autosync-mode)
      (my/org-roam-refresh-agenda-list))
  
    (:option
     org-roam-directory "~/Notes/Roam/"
     org-roam-dailies-directory "Journal/"
     org-roam-completion-everywhere t
     org-roam-capture-templates
     '(("d" "default" plain "%?"
        :if-new (file+head "%<%Y%m%d%H%M%S>-${slug}.org"
                           "#+title: ${title}\n")
        :unnarrowed t))
     org-roam-dailies-capture-templates
     `(("d" "default" entry
        "* %?"
        :if-new (file+head ,dw/daily-note-filename
                           ,dw/daily-note-header))
       ("t" "task" entry
        "* TODO %?\n  %U\n  %a\n  %i"
        :if-new (file+head+olp ,dw/daily-note-filename
                               ,dw/daily-note-header
                               ("Tasks"))
        :empty-lines 1)
       ("l" "log entry" entry
        "* %<%I:%M %p> - %?"
        :if-new (file+head+olp ,dw/daily-note-filename
                               ,dw/daily-note-header
                               ("Log")))
       ("j" "journal" entry
        "* %<%I:%M %p> - Journal  :journal:\n\n%?\n\n"
        :if-new (file+head+olp ,dw/daily-note-filename
                               ,dw/daily-note-header
                               ("Log")))
       ("m" "meeting" entry
        "* %<%I:%M %p> - %^{Meeting Title}  :meetings:\n\n%?\n\n"
        :if-new (file+head+olp ,dw/daily-note-filename
                               ,dw/daily-note-header
                               ("Log")))))
    (:global "C-c n l" org-roam-buffer-toggle
             "C-c n f" org-roam-node-find
             "C-c n d" dw/org-roam-jump-menu/body
             "C-c n c" org-roam-dailies-capture-today
             "C-c n t" dw/org-roam-capture-task
             "C-c n g" org-roam-graph)
    (:bind "C-c n i" org-roam-node-insert
           "C-c n I" org-roam-insert-immediate))

  (setup (:pkg org-appear)
    (:hook-into org-mode))

  (setup (:pkg magit)
    (:also-load magit-todos)
    (:global "C-M-;" magit-status)
    (:option magit-display-buffer-function #'magit-display-buffer-same-window-except-diff-v1))

  (setup (:pkg forge)
    (:disabled))

  (setup (:pkg magit-todos))

  (setup (:pkg git-link)
    (setq git-link-open-in-browser t)
    (dw/leader-key-def
      "gL"  'git-link))

  (setup (:pkg git-gutter :straight git-gutter-fringe)
    (:hook-into text-mode prog-mode)
    (setq git-gutter:update-interval 2)
    (unless dw/is-termux
      (require 'git-gutter-fringe)
      (set-face-foreground 'git-gutter-fr:added "LightGreen")
      (fringe-helper-define 'git-gutter-fr:added nil
        "XXXXXXXXXX"
        "XXXXXXXXXX"
        "XXXXXXXXXX"
        ".........."
        ".........."
        "XXXXXXXXXX"
        "XXXXXXXXXX"
        "XXXXXXXXXX"
        ".........."
        ".........."
        "XXXXXXXXXX"
        "XXXXXXXXXX"
        "XXXXXXXXXX")

      (set-face-foreground 'git-gutter-fr:modified "LightGoldenrod")
      (fringe-helper-define 'git-gutter-fr:modified nil
        "XXXXXXXXXX"
        "XXXXXXXXXX"
        "XXXXXXXXXX"
        ".........."
        ".........."
        "XXXXXXXXXX"
        "XXXXXXXXXX"
        "XXXXXXXXXX"
        ".........."
        ".........."
        "XXXXXXXXXX"
        "XXXXXXXXXX"
        "XXXXXXXXXX")

      (set-face-foreground 'git-gutter-fr:deleted "LightCoral")
      (fringe-helper-define 'git-gutter-fr:deleted nil
        "XXXXXXXXXX"
        "XXXXXXXXXX"
        "XXXXXXXXXX"
        ".........."
        ".........."
        "XXXXXXXXXX"
        "XXXXXXXXXX"
        "XXXXXXXXXX"
        ".........."
        ".........."
        "XXXXXXXXXX"
        "XXXXXXXXXX"
        "XXXXXXXXXX"))

    ;; These characters are used in terminal mode
    (setq git-gutter:modified-sign "≡")
    (setq git-gutter:added-sign "≡")
    (setq git-gutter:deleted-sign "≡")
    (set-face-foreground 'git-gutter:added "LightGreen")
    (set-face-foreground 'git-gutter:modified "LightGoldenrod")
    (set-face-foreground 'git-gutter:deleted "LightCoral"))

  (defun dw/switch-project-action ()
    "Switch to a workspace with the project name and start `magit-status'."
    ;; TODO: Switch to EXWM workspace 1?
    (persp-switch (projectile-project-name))
    (magit-status))

  (setup (:pkg projectile)
    (when (file-directory-p "~/Projects/Code")
      (setq projectile-project-search-path '("~/Projects/Code")))
    (setq projectile-switch-project-action #'dw/switch-project-action)

    (projectile-mode)

    (:global "C-M-p" projectile-find-file
             "C-c p" projectile-command-map)

    (dw/leader-key-def
      "pf"  'projectile-find-file
      "ps"  'projectile-switch-project
      "pF"  'consult-ripgrep
      "pp"  'projectile-find-file
      "pc"  'projectile-compile-project
      "pd"  'projectile-dired))

  (dir-locals-set-class-variables 'Atom
    `((nil . ((projectile-project-name . "Atom")
              (projectile-project-compilation-dir . nil)
              (projectile-project-compilation-cmd . "script/build")))))

  (dir-locals-set-directory-class (expand-file-name "~/Projects/Code/atom") 'Atom)

  (setup (:pkg lsp-mode :straight t)
    (:hook-into typescript-mode js2-mode web-mode)
    (:bind "TAB" completion-at-point)
    (:option lsp-headerline-breadcrumb-enable nil)

    (dw/leader-key-def
      "l" '(:ignore t :which-key "lsp")
      "ld" 'xref-find-definitions
      "lr" 'xref-find-references
      "ln" 'lsp-ui-find-next-reference
      "lp" 'lsp-ui-find-prev-reference
      "ls" 'counsel-imenu
      "le" 'lsp-ui-flycheck-list
      "lS" 'lsp-ui-sideline-mode
      "lX" 'lsp-execute-code-action))

  (setup (:pkg lsp-ui :straight t)
    (:hook-into lsp-mode)
    (:when-loaded
     (progn
       (setq lsp-ui-sideline-enable t)
       (setq lsp-ui-sideline-show-hover nil)
       (setq lsp-ui-doc-position 'bottom)
       (lsp-ui-doc-show))))

  (setup (:pkg eglot)
    (:disabled)
    (add-hook 'typescript-mode-hook #'eglot-ensure))

  (setup (:pkg dap-mode :straight t)
    ;; Assuming that `dap-debug' will invoke all this
    (:when-loaded
      (:option lsp-enable-dap-auto-configure nil)
      (dap-ui-mode 1)
      (dap-tooltip-mode 1)
      (dap-node-setup)))

  (setup (:pkg lispy)
    (:hook-into emacs-lisp-mode scheme-mode))

  (setup (:pkg lispyville)
    (:hook-into lispy-mode)
    (:when-loaded
      (lispyville-set-key-theme '(operators c-w additional
                                  additional-movement slurp/barf-cp
                                  prettify))))

  (setup (:pkg sly)
    (:disabled)
    (:file-match "\\.lisp\\'"))

  (setup (:pkg slime)
    (:disabled)
    (:file-match "\\.lisp\\'"))

  ;; Include .sld library definition files
  (setup (:pkg scheme-mode)
    (:file-match "\\.sld\\'"))

  (setup (:pkg typescript-mode)
    (:file-match "\\.ts\\'")
    (setq typescript-indent-level 2))

  (defun dw/set-js-indentation ()
    (setq-default js-indent-level 2)
    (setq-default evil-shift-width js-indent-level)
    (setq-default tab-width 2))

  (setup (:pkg js2-mode)
    (:file-match "\\.jsx?\\'")

    ;; Use js2-mode for Node scripts
    (add-to-list 'magic-mode-alist '("#!/usr/bin/env node" . js2-mode))

    ;; Don't use built-in syntax checking
    (setq js2-mode-show-strict-warnings nil)

    ;; Set up proper indentation in JavaScript and JSON files
    (add-hook 'js2-mode-hook #'dw/set-js-indentation)
    (add-hook 'json-mode-hook #'dw/set-js-indentation))

  (setup (:pkg apheleia)
    (apheleia-global-mode +1))

  (setup (:pkg ccls)
    (:hook lsp)
    (:hook-into c-mode c++-mode objc-mode cuda-mode))

  (setup (:pkg go-mode)
    (:hook lsp-deferred))

  (setup (:pkg rust-mode)
    (:file-match "\\.rs\\'")
    (setq rust-format-on-save t))

  (setup (:pkg cargo :straight t))

  (setup emacs-lisp-mode
    (:hook flycheck-mode))

  (setup (:pkg helpful)
    (:option counsel-describe-function-function #'helpful-callable
             counsel-describe-variable-function #'helpful-variable)
    (:global [remap describe-function] helpful-function
             [remap describe-symbol] helpful-symbol
             [remap describe-variable] helpful-variable
             [remap describe-command] helpful-command
             [remap describe-key] helpful-key))

  (dw/leader-key-def
    "e"   '(:ignore t :which-key "eval")
    "eb"  '(eval-buffer :which-key "eval buffer"))

  (dw/leader-key-def
    :keymaps '(visual)
    "er" '(eval-region :which-key "eval region"))

  ;; TODO: This causes issues for some reason.
  ;; :bind (:map geiser-mode-map
  ;;        ("TAB" . completion-at-point))

  (setup (:pkg geiser)
    ;; (setq geiser-default-implementation 'gambit)
    ;; (setq geiser-active-implementations '(gambit guile))
    ;; (setq geiser-implementations-alist '(((regexp "\\.scm$") gambit)
    ;;                                      ((regexp "\\.sld") gambit)))
    ;; (setq geiser-repl-default-port 44555) ; For Gambit Scheme
    (setq geiser-default-implementation 'guile)
    (setq geiser-active-implementations '(guile))
    (setq geiser-repl-default-port 44555) ; For Gambit Scheme
    (setq geiser-implementations-alist '(((regexp "\\.scm$") guile))))

  (setup (:pkg zig-mode :straight t)
    (:disabled)
    (add-to-list 'lsp-language-id-configuration '(zig-mode . "zig"))
    (:load-after lsp-mode
      (lsp-register-client
        (make-lsp-client
          :new-connection (lsp-stdio-connection "~/Projects/Code/zls/zig-cache/bin/zls")
          :major-modes '(zig-mode)
          :server-id 'zls))))

  (setup (:pkg markdown-mode)
    (setq markdown-command "marked")
    (:file-match "\\.md\\'")
    (:when-loaded
      (dolist (face '((markdown-header-face-1 . 1.2)
                      (markdown-header-face-2 . 1.1)
                      (markdown-header-face-3 . 1.0)
                      (markdown-header-face-4 . 1.0)
                      (markdown-header-face-5 . 1.0)))
        (set-face-attribute (car face) nil :weight 'normal :height (cdr face)))))

  (setup (:pkg web-mode)
    (:file-match "(\\.\\(html?\\|ejs\\|tsx\\|jsx\\)\\'")
    (setq-default web-mode-code-indent-offset 2)
    (setq-default web-mode-markup-indent-offset 2)
    (setq-default web-mode-attribute-indent-offset 2))

  ;; 1. Start the server with `httpd-start'
  ;; 2. Use `impatient-mode' on any buffer
  (setup (:pkg impatient-mode :straight t))
  (setup (:pkg skewer-mode :straight t))

  (setup (:pkg yaml-mode)
    (:file-match "\\.ya?ml\\'"))

  (setup adl-mode
    (:file-match "\\.cadl\\'")
    (:hook lsp-deferred)
    (:bind "C-c C-c" recompile))

  (setup compile
    (:option compilation-scroll-output t))

  (defun dw/auto-recompile-buffer ()
    (interactive)
    (if (member #'recompile after-save-hook)
        (remove-hook 'after-save-hook #'recompile t)
      (add-hook 'after-save-hook #'recompile nil t)))

  (setup (:pkg flycheck)
    (:hook-into lsp-mode))

  (setup (:pkg yasnippet)
    (:disabled)
    (require 'yasnippet)
    (add-hook 'prog-mode-hook #'yas-minor-mode)
    (yas-reload-all))

  (setup (:pkg smartparens)
    (:hook-into prog-mode))

  (setup (:pkg rainbow-delimiters)
    (:hook-into prog-mode))

  (setup (:pkg rainbow-mode)
    (:hook-into org-mode
                emacs-lisp-mode
                web-mode
                typescript-mode
                js2-mode))

  ;; TODO: Figure out how to query for 'done' bugs
  (defun dw/debbugs-guix-patches ()
    (interactive)
    (debbugs-gnu '("serious" "important" "normal") "guix-patches" nil t))

  ;; (setup substratic-forge
  ;;   :if (file-exists-p "~/Projects/Code/crash-the-stack/lib/github.com/substratic/forge/@/")
  ;;   :load-path "~/Projects/Code/crash-the-stack/lib/github.com/substratic/forge/@/"
  ;;   :bind (:map substratic-forge-mode-map
  ;;          ("C-c C-m" . substratic-reload-module)))

  (add-to-list 'auto-mode-alist '("\\.info\\'" . Info-on-current-buffer))

  (setup (:pkg posframe))
  (setup (:pkg command-log-mode :straight t))

  (setq dw/command-window-frame nil)

  (defun dw/toggle-command-window ()
    (interactive)
    (if dw/command-window-frame
        (progn
          (posframe-delete-frame clm/command-log-buffer)
          (setq dw/command-window-frame nil))
        (progn
          (global-command-log-mode t)
          (with-current-buffer
            (setq clm/command-log-buffer
                  (get-buffer-create " *command-log*"))
            (text-scale-set -1))
          (setq dw/command-window-frame
            (posframe-show
              clm/command-log-buffer
              :position `(,(- (x-display-pixel-width) 590) . 15)
              :width 38
              :height 5
              :min-width 38
              :min-height 5
              :internal-border-width 2
              :internal-border-color "#c792ea"
              :override-parameters '((parent-frame . nil)))))))

  (dw/leader-key-def
   "tc" 'dw/toggle-command-window)

  (setup (:pkg keycast)
    ;; This works with doom-modeline, inspired by this comment:
    ;; https://github.com/tarsius/keycast/issues/7#issuecomment-627604064
    (define-minor-mode keycast-mode
      "Show current command and its key binding in the mode line."
      :global t
      (require 'keycast)
      (if keycast-mode
          (add-hook 'pre-command-hook 'keycast-mode-line-update)
          (remove-hook 'pre-command-hook 'keycast-mode-line-update)))

    (add-to-list 'global-mode-string '("" mode-line-keycast " ")))

  (setup (:pkg obs-websocket :guix "emacs-obs-websocket-el")
    (require 'obs-websocket)
    (defhydra dw/stream-keys (:exit t)
      "Stream Commands"
      ("c" (obs-websocket-connect) "Connect")
      ("l" (obs-websocket-send "SetCurrentScene" :scene-name "Logo Screen") "Logo Screen" :exit nil)
      ("s" (obs-websocket-send "SetCurrentScene" :scene-name "Screen") "Screen")
      ("w" (obs-websocket-send "SetCurrentScene" :scene-name "Webcam") "Webcam")
      ("p" (obs-websocket-send "SetCurrentScene" :scene-name "Sponsors") "Sponsors")
      ("e" (obs-websocket-send "SetCurrentScene" :scene-name "Thanks For Watching") "Thanks For Watching")
      ("Ss" (obs-websocket-send "StartStreaming") "Start Stream")
      ("Se" (obs-websocket-send "StopStreaming") "End Stream"))
  
    ;; This is Super-s (for now)
    (global-set-key (kbd "s-s") #'dw/stream-keys/body))

  (setup (:pkg live-crafter
               :host github
               :repo "SystemCrafters/live-crafter")
    (:load-after mpv))

  (dw/leader-key-def
    "a"  '(:ignore t :which-key "apps"))

  ;; Only fetch mail on zerocool
  (setq dw/mail-enabled (member system-name '("zerocool" "acidburn")))
  (setq dw/mu4e-inbox-query nil)
  (when dw/mail-enabled
    (require 'dw-mail))

  (setup (:pkg ledger-mode)
    (:file-match "\\.lgr\\'")
    (:bind "TAB" completion-at-point)
    (:option
     ledger-reports '(("bal" "%(binary) -f %(ledger-file) bal")
                      ("bal this quarter" "%(binary) -f %(ledger-file) --period \"this quarter\" bal")
                      ("bal last quarter" "%(binary) -f %(ledger-file) --period \"last quarter\" bal")
                      ("reg" "%(binary) -f %(ledger-file) reg")
                      ("payee" "%(binary) -f %(ledger-file) reg @%(payee)")
                      ("account" "%(binary) -f %(ledger-file) reg %(account)"))))

  (setup (:pkg hledger-mode :straight t)
    (:bind "TAB" completion-at-point))

  (defun read-file (file-path)
    (with-temp-buffer
      (insert-file-contents file-path)
      (buffer-string)))

  (defun dw/get-current-package-version ()
    (interactive)
    (let ((package-json-file (concat (eshell/pwd) "/package.json")))
      (when (file-exists-p package-json-file)
        (let* ((package-json-contents (read-file package-json-file))
               (package-json (ignore-errors (json-parse-string package-json-contents))))
          (when package-json
            (ignore-errors (gethash "version" package-json)))))))

  (defun dw/map-line-to-status-char (line)
    (cond ((string-match "^?\\? " line) "?")))

  (defun dw/get-git-status-prompt ()
    (let ((status-lines (cdr (process-lines "git" "status" "--porcelain" "-b"))))
      (seq-uniq (seq-filter 'identity (mapcar 'dw/map-line-to-status-char status-lines)))))

  (defun dw/get-prompt-path ()
    (let* ((current-path (eshell/pwd))
           (git-output (shell-command-to-string "git rev-parse --show-toplevel"))
           (has-path (not (string-match "^fatal" git-output))))
      (if (not has-path)
        (abbreviate-file-name current-path)
        (string-remove-prefix (file-name-directory git-output) current-path))))

  ;; This prompt function mostly replicates my custom zsh prompt setup
  ;; that is powered by github.com/denysdovhan/spaceship-prompt.
  (defun dw/eshell-prompt ()
    (let ((current-branch (magit-get-current-branch))
          (package-version (dw/get-current-package-version)))
      (concat
       "\n"
       (propertize (system-name) 'face `(:foreground "#62aeed"))
       (propertize " ॐ " 'face `(:foreground "white"))
       (propertize (dw/get-prompt-path) 'face `(:foreground "#82cfd3"))
       (when current-branch
         (concat
          (propertize " • " 'face `(:foreground "white"))
          (propertize (concat " " current-branch) 'face `(:foreground "#c475f0"))))
       (when package-version
         (concat
          (propertize " @ " 'face `(:foreground "white"))
          (propertize package-version 'face `(:foreground "#e8a206"))))
       (propertize " • " 'face `(:foreground "white"))
       (propertize (format-time-string "%I:%M:%S %p") 'face `(:foreground "#5a5b7f"))
       (if (= (user-uid) 0)
           (propertize "\n#" 'face `(:foreground "red2"))
         (propertize "\nλ" 'face `(:foreground "#aece4a")))
       (propertize " " 'face `(:foreground "white")))))

  (unless dw/is-termux
    (add-hook 'eshell-banner-load-hook
              (lambda ()
                 (setq eshell-banner-message
                       (concat "\n" (propertize " " 'display (create-image "~/.dotfiles/.guix.emacs.d/images/flux_banner.png" 'png nil :scale 0.2 :align-to "center")) "\n\n")))))

  (defun dw/eshell-configure ()
    ;; Make sure magit is loaded
    (require 'magit)

    (require 'evil-collection-eshell)
    (evil-collection-eshell-setup)

    (setup (:pkg xterm-color))

    (push 'eshell-tramp eshell-modules-list)
    (push 'xterm-color-filter eshell-preoutput-filter-functions)
    (delq 'eshell-handle-ansi-color eshell-output-filter-functions)

    ;; Save command history when commands are entered
    (add-hook 'eshell-pre-command-hook 'eshell-save-some-history)

    (add-hook 'eshell-before-prompt-hook
              (lambda ()
                (setq xterm-color-preserve-properties t)))

    ;; Truncate buffer for performance
    (add-to-list 'eshell-output-filter-functions 'eshell-truncate-buffer)

    ;; We want to use xterm-256color when running interactive commands
    ;; in eshell but not during other times when we might be launching
    ;; a shell command to gather its output.
    (add-hook 'eshell-pre-command-hook
              (lambda () (setenv "TERM" "xterm-256color")))
    (add-hook 'eshell-post-command-hook
              (lambda () (setenv "TERM" "dumb")))

    ;; Use completion-at-point to provide completions in eshell
    (define-key eshell-mode-map (kbd "<tab>") 'completion-at-point)

    ;; Initialize the shell history
    (eshell-hist-initialize)

    (evil-define-key '(normal insert visual) eshell-mode-map (kbd "C-r") 'consult-history)
    (evil-define-key '(normal insert visual) eshell-mode-map (kbd "<home>") 'eshell-bol)
    (evil-normalize-keymaps)

    (setenv "PAGER" "cat")

    (setq eshell-prompt-function      'dw/eshell-prompt
          eshell-prompt-regexp        "^λ "
          eshell-history-size         10000
          eshell-buffer-maximum-lines 10000
          eshell-hist-ignoredups t
          eshell-highlight-prompt t
          eshell-scroll-to-bottom-on-input t
          eshell-prefer-lisp-functions nil))

  (setup eshell
    (add-hook 'eshell-first-time-mode-hook #'dw/eshell-configure)
    (setq eshell-directory-name "~/.dotfiles/.guix.emacs.d/eshell/"
          eshell-aliases-file (expand-file-name "~/.dotfiles/.guix.emacs.d/eshell/alias")))

  (setup (:pkg eshell-z)
    (:disabled) ;; Using consult-dir for this now
    (add-hook 'eshell-mode-hook (lambda () (require 'eshell-z)))
    (add-hook 'eshell-z-change-dir-hook (lambda () (eshell/pushd (eshell/pwd)))))

  (setup (:pkg exec-path-from-shell)
    (setq exec-path-from-shell-check-startup-files nil)
    (when (memq window-system '(mac ns x))
      (exec-path-from-shell-initialize)))

  (dw/leader-key-def
    "SPC" 'eshell)

  (with-eval-after-load 'esh-opt
    (setq eshell-destroy-buffer-when-process-dies t)
    (setq eshell-visual-commands '("htop" "zsh" "vim" "rush")))

  (setup (:pkg fish-completion)
    (:disabled)
    (:hook-into eshell-mode))

  (setup (:pkg eshell-syntax-highlighting)
    (:load-after eshell
      (eshell-syntax-highlighting-global-mode +1)))

  (defun dw/esh-autosuggest-setup ()
    (require 'company)
    (set-face-foreground 'company-preview-common "#4b5668")
    (set-face-background 'company-preview nil))

  (setup (:pkg esh-autosuggest)
    (require 'esh-autosuggest)
    (setq esh-autosuggest-delay 0.5)
    (:hook dw/esh-autosuggest-setup)
    (:hook-into eshell-mode))

  (setup (:pkg eshell-toggle)
    (:disabled)
    (:global "C-M-'" eshell-toggle)
    (:option eshell-toggle-size-fraction 3
             eshell-toggle-use-projectile-root t
             eshell-toggle-run-command nil))

  (setup (:pkg vterm)
    (:when-loaded
     (progn
       (setq vterm-max-scrollback 10000)
       (advice-add 'evil-collection-vterm-insert :before #'vterm-reset-cursor-point))))

  ;; Don't let ediff break EXWM, keep it in one frame
  (setq ediff-diff-options "-w"
        ediff-split-window-function 'split-window-horizontally
        ediff-window-setup-function 'ediff-setup-windows-plain)

  (setup (:pkg tracking)
    (require 'tracking)
    (setq tracking-faces-priorities '(all-the-icons-pink
                                      all-the-icons-lgreen
                                      all-the-icons-lblue))
    (setq tracking-frame-behavior nil))

  ;; Add faces for specific people in the modeline.  There must
  ;; be a better way to do this.
  (defun dw/around-tracking-add-buffer (original-func buffer &optional faces)
    (let* ((name (buffer-name buffer))
           (face (cond ((s-contains? "Maria" name) '(all-the-icons-pink))
                       ((s-contains? "Alex " name) '(all-the-icons-lgreen))
                       ((s-contains? "Steve" name) '(all-the-icons-lblue))))
           (result (apply original-func buffer (list face))))
      (dw/update-polybar-telegram)
      result))

  (defun dw/after-tracking-remove-buffer (buffer)
    (dw/update-polybar-telegram))

  (advice-add 'tracking-add-buffer :around #'dw/around-tracking-add-buffer)
  (advice-add 'tracking-remove-buffer :after #'dw/after-tracking-remove-buffer)
  (advice-remove 'tracking-remove-buffer #'dw/around-tracking-remove-buffer)

  ;; Advise exwm-workspace-switch so that we can more reliably clear tracking buffers
  ;; NOTE: This is a hack and I hate it.  It'd be great to find a better solution.
  (defun dw/before-exwm-workspace-switch (frame-or-index &optional force)
    (when (fboundp 'tracking-remove-visible-buffers)
      (when (eq exwm-workspace-current-index 0)
        (tracking-remove-visible-buffers))))

  (advice-add 'exwm-workspace-switch :before #'dw/before-exwm-workspace-switch)

  (setup (:pkg telega)
    (setq telega-user-use-avatars nil
          telega-use-tracking-for '(any pin unread)
          telega-emoji-use-images t
          telega-completing-read-function #'ivy-completing-read
          telega-msg-rainbow-title nil
          telega-chat-fill-column 75))

  (defun dw/on-erc-track-list-changed ()
    (dolist (buffer erc-modified-channels-alist)
      (tracking-add-buffer (car buffer))))

  (setup (:pkg erc-hl-nicks)
    (:load-after erc))

  (setup (:pkg erc-image)
    (:load-after erc))

  (setup erc
    (add-hook 'erc-track-list-changed-hook #'dw/on-erc-track-list-changed)
    (setq
        erc-nick "daviwil"
        erc-user-full-name "David Wilson"
        erc-prompt-for-password nil
        erc-auto-query 'bury
        erc-join-buffer 'bury
        erc-track-shorten-start 8
        erc-interpret-mirc-color t
        erc-rename-buffers t
        erc-kill-buffer-on-part t
        erc-track-exclude '("#twitter_daviwil")
        erc-track-exclude-types '("JOIN" "NICK" "PART" "QUIT" "MODE" "AWAY")
        erc-track-enable-keybindings nil
        erc-track-visibility nil ; Only use the selected frame for visibility
        erc-track-exclude-server-buffer t
        erc-fill-column 120
        erc-fill-function 'erc-fill-static
        erc-fill-static-center 20
        erc-image-inline-rescale 400
        erc-server-reconnect-timeout 10
        erc-server-reconnect-attempts 5
        erc-autojoin-channels-alist '(("irc.libera.chat" "#systemcrafters" "#emacs" "#guix"))
        erc-quit-reason (lambda (s) (or s "Ejecting from cyberspace"))
        erc-modules
        '(autoaway autojoin button completion fill irccontrols keep-place
            list match menu move-to-prompt netsplit networks noncommands
            readonly ring stamp track image hl-nicks notify notifications))

    (add-hook 'erc-join-hook 'bitlbee-identify)
    (defun bitlbee-identify ()
      "If we're on the bitlbee server, send the identify command to the &bitlbee channel."
      (when (and (string= "127.0.0.1" erc-session-server)
                 (string= "&bitlbee" (buffer-name)))
        (erc-message "PRIVMSG" (format "%s identify %s"
                                       (erc-default-target)
                                       (password-store-get "IRC/Bitlbee"))))))

  (defun dw/connect-irc ()
    (interactive)
    (erc-tls :server "crafter.mx" :port 3110 :nick "daviwil"))
    ;; (erc
    ;;    :server "127.0.0.1" :port 6667
    ;;    :nick "daviwil" :password (password-store-get "IRC/Bitlbee")))

  ;; Thanks karthik!
  (defun erc-image-create-image (file-name)
    "Create an image suitably scaled according to the setting of
  'ERC-IMAGE-RESCALE."
    (let* ((positions (window-inside-absolute-pixel-edges))
          (width (- (nth 2 positions) (nth 0 positions)))
          (height (- (nth 3 positions) (nth 1 positions)))
          (image (create-image file-name))
          (dimensions (image-size image t))
          (imagemagick-p (and (fboundp 'imagemagick-types) 'imagemagick)))
                                          ; See if we want to rescale the image
      (if (and erc-image-inline-rescale
              (not (image-multi-frame-p image)))
          ;; Rescale based on erc-image-rescale
          (cond (;; Numeric: scale down to that size
                (numberp erc-image-inline-rescale)
                (if (> (cdr dimensions) erc-image-inline-rescale)
                    (create-image file-name imagemagick-p nil :height erc-image-inline-rescale)
                  image))
                (;; 'window: scale down to window size, if bigger
                (eq erc-image-inline-rescale 'window)
                ;; But only if the image is greater than the window size
                (if (or (> (car dimensions) width)
                        (> (cdr dimensions) height))
                    ;; Figure out in which direction we need to scale
                    (if (> width height)
                        (create-image file-name imagemagick-p nil :height  height)
                      (create-image file-name imagemagick-p nil :width width))
                  ;; Image is smaller than window, just give that back
                  image))
                (t (progn (message "Error: none of the rescaling options matched") image)))
        ;; No rescale
        image)))

  (dw/ctrl-c-keys
    "c"  '(:ignore t :which-key "chat")
    "cb" 'erc-switch-to-buffer
    "cc" 'dw/connect-irc
    "ca" 'erc-track-switch-buffer)

  (setup (:pkg 0x0 :host gitlab :repo "willvaughn/emacs-0x0"))

  (setup (:pkg elfeed)
    (setq elfeed-feeds
      '("https://nullprogram.com/feed/"
        "https://ambrevar.xyz/atom.xml"
        "https://guix.gnu.org/feeds/blog.atom"
        "https://valdyas.org/fading/feed/"
        "https://www.reddit.com/r/emacs/.rss")))

  (setup (:pkg mpv :straight t))

  (setup (:pkg emms)
    (require 'emms-setup)
    (emms-standard)
    (emms-default-players)
    (emms-mode-line-disable)
    (setq emms-source-file-default-directory "~/Music/")
    (dw/leader-key-def
      "am"  '(:ignore t :which-key "media")
      "amp" '(emms-pause :which-key "play / pause")
      "amf" '(emms-play-file :which-key "play file")))

  (setup (:pkg elpher))

  (setup (:pkg guix))

  (dw/leader-key-def
    "G"  '(:ignore t :which-key "Guix")
    "Gg" '(guix :which-key "Guix")
    "Gi" '(guix-installed-user-packages :which-key "user packages")
    "GI" '(guix-installed-system-packages :which-key "system packages")
    "Gp" '(guix-packages-by-name :which-key "search packages")
    "GP" '(guix-pull :which-key "pull"))

  (setup (:pkg daemons))

  (setup (:pkg pulseaudio-control)
    (setq pulseaudio-control-pactl-path "/run/current-system/profile/bin/pactl"))

  (defun dw/bluetooth-connect-q30 ()
    (interactive)
    (start-process-shell-command "bluetoothctl" nil "bluetoothctl -- connect 11:14:00:00:1E:1A"))

  (defun dw/bluetooth-connect-qc35 ()
    (interactive)
    (start-process-shell-command "bluetoothctl" nil "bluetoothctl -- connect 04:52:C7:5E:5C:A8"))

  (defun dw/bluetooth-disconnect ()
    (interactive)
    (start-process-shell-command "bluetoothctl" nil "bluetoothctl -- disconnect"))

  (setup proced
    (setq proced-auto-update-interval 1)
    (add-hook 'proced-mode-hook
              (lambda ()
                (proced-toggle-auto-update 1))))

  (setup (:pkg docker)
    (:also-load docker-tramp))

  (setup (:pkg docker-tramp))

  ;; Make gc pauses faster by decreasing the threshold.
  (setq gc-cons-threshold (* 2 1000 1000))
