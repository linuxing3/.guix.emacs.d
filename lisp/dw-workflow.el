  ;; -*- lexical-binding: t; -*-

  (setq org-directory
        (if dw/is-termux
            "~/storage/shared/Notes"
          "~/Notes"))

  ;; (setq org-agenda-files `(,org-directory))
  (defun dw/org-path (path)
    (expand-file-name path org-directory))

  (setq org-default-notes-file (dw/org-path "Inbox.org"))

  (with-eval-after-load 'org-roam
    (defun my/org-roam-project-finalize-hook ()
      "Adds the captured project file to `org-agenda-files' if the
  capture was not aborted."
      ;; Remove the hook since it was added temporarily
      (remove-hook 'org-capture-after-finalize-hook #'my/org-roam-project-finalize-hook)

      ;; Add project file to the agenda list if the capture was confirmed
      (unless org-note-abort
        (with-current-buffer (org-capture-get :buffer)
          (add-to-list 'org-agenda-files (buffer-file-name)))))

    (defun my/org-roam-find-project ()
      (interactive)
      ;; Add the project file to the agenda after capture is finished
      (add-hook 'org-capture-after-finalize-hook #'my/org-roam-project-finalize-hook)

      ;; Select a project file to open, creating it if necessary
      (org-roam-node-find
       nil
       nil
       (my/org-roam-filter-by-tag "Project")
       :templates
       '(("p" "project" plain "* Goals\n\n%?\n\n* Tasks\n\n** TODO Add initial tasks\n\n* Dates\n\n"
          :if-new (file+head "%<%Y%m%d%H%M%S>-${slug}.org" "#+title: ${title}\n#+category: ${title}\n#+filetags: Project")
          :unnarrowed t))))

    (defun my/org-roam-capture-inbox ()
      (interactive)
      (org-roam-capture- :node (org-roam-node-create)
                         :templates '(("i" "inbox" plain "* %?"
                                       :if-new (file+head "Inbox.org" "#+title: Inbox\n")))))

    (defun my/org-roam-copy-todo-to-today ()
      (interactive)
      (let ((org-refile-keep t) ;; Set this to nil to delete the original!
            (org-roam-dailies-capture-templates
             '(("t" "tasks" entry "%?"
                :if-new (file+head+olp "%<%Y-%m-%d>.org" "#+title: %<%Y-%m-%d>\n" ("Tasks")))))
            (org-after-refile-insert-hook #'save-buffer)
            today-file
            pos)
        (save-window-excursion
          (org-roam-dailies--capture (current-time) t)
          (setq today-file (buffer-file-name))
          (setq pos (point)))

        ;; Only refile if the target file is different than the current file
        (unless (equal (file-truename today-file)
                       (file-truename (buffer-file-name)))
          (org-refile nil nil (list "Tasks" today-file nil pos)))))

    ;; (add-to-list 'org-after-todo-state-change-hook
    ;;              (lambda ()
    ;;                (when (equal org-state "DONE")
    ;;                  (my/org-roam-copy-todo-to-today))))
    )

  (setq org-todo-keywords
    '((sequence "TODO(t)" "NEXT(n)" "|" "DONE(d!)")
      (sequence "|" "WAIT(w)" "BACK(b)")))

  ;; TODO: org-todo-keyword-faces
  (setq org-todo-keyword-faces
    '(("NEXT" . (:foreground "orange red" :weight bold))
      ("WAIT" . (:foreground "HotPink2" :weight bold))
      ("BACK" . (:foreground "MediumPurple3" :weight bold))))

  ;; Configure common tags
  (setq org-tag-alist
    '((:startgroup)
       ; Put mutually exclusive tags here
       (:endgroup)
       ("@home" . ?H)
       ("@work" . ?W)
       ("batch" . ?b)
       ("followup" . ?f)))

  (setq org-agenda-window-setup 'current-window)
  (setq org-agenda-span 'day)
  (setq org-agenda-start-with-log-mode t)

  ;; Make done tasks show up in the agenda log
  (setq org-log-done 'time)
  (setq org-log-into-drawer t)

  (setq org-columns-default-format "%20CATEGORY(Category) %65ITEM(Task) %TODO %6Effort(Estim){:}  %6CLOCKSUM(Clock) %TAGS")

  (setq org-agenda-custom-commands
        `(("d" "Dashboard"
           ((agenda "" ((org-deadline-warning-days 7)))
            (tags-todo "+PRIORITY=\"A\""
                       ((org-agenda-overriding-header "High Priority")))
            (tags-todo "+followup" ((org-agenda-overriding-header "Needs Follow Up")))
            (todo "NEXT"
                  ((org-agenda-overriding-header "Next Actions")
                   (org-agenda-max-todos nil)))
            (todo "TODO"
                  ((org-agenda-overriding-header "Unprocessed Inbox Tasks")
                   (org-agenda-files '(,(dw/org-path "Inbox.org")))
                   (org-agenda-text-search-extra-files nil)))))

          ("n" "Next Tasks"
           ((agenda "" ((org-deadline-warning-days 7)))
            (todo "NEXT"
                  ((org-agenda-overriding-header "Next Tasks")))))

          ;; Low-effort next actions
          ("e" tags-todo "+TODO=\"NEXT\"+Effort<15&+Effort>0"
           ((org-agenda-overriding-header "Low Effort Tasks")
            (org-agenda-max-todos 20)
            (org-agenda-files org-agenda-files)))))

  (add-hook 'org-timer-set-hook #'org-clock-in)

  (defun dw/get-todays-journal-file-name ()
    "Gets the journal file name for today's date"
    (interactive)
    (let* ((journal-file-name
             (expand-file-name
               (format-time-string "%Y/%Y-%2m-%B.org")
               (dw/org-path "Journal/")))
           (journal-year-dir (file-name-directory journal-file-name)))
      (if (not (file-directory-p journal-year-dir))
        (make-directory journal-year-dir))
      journal-file-name))


  (defun dw/on-org-capture ()
    ;; Don't show the confirmation header text
    (setq header-line-format nil)

    ;; Control how some buffers are handled
    (let ((template (org-capture-get :key t)))
      (pcase template
        ("jj" (delete-other-windows)))))

  (add-hook 'org-capture-mode-hook 'dw/on-org-capture)

  (setq org-capture-templates
    `(("t" "Tasks")
      ("tt" "Task" entry (file ,(dw/org-path "Inbox.org"))
           "* TODO %?\n  %U\n  %a\n  %i" :empty-lines 1)
      ("ts" "Clocked Entry Subtask" entry (clock)
           "* TODO %?\n  %U\n  %a\n  %i" :empty-lines 1)

      ("j" "Journal Entries")
      ("je" "General Entry" entry
           (file+olp+datetree ,(dw/org-path "Journal.org"))
           "\n* %<%I:%M %p> - %^{Title} \n\n%?\n\n"
           :tree-type week
           :clock-in :clock-resume
           :empty-lines 1)
      ("jt" "Task Entry" entry
           (file+olp+datetree ,(dw/org-path "Journal.org"))
           "\n* %<%I:%M %p> - Task Notes: %a\n\n%?\n\n"
           :tree-type week
           :clock-in :clock-resume
           :empty-lines 1)
      ("jj" "Journal" entry
           (file+olp+datetree ,(dw/org-path "Journal.org"))
           "\n* %<%I:%M %p> - Journal :journal:\n\n%?\n\n"
           :tree-type week
           :clock-in :clock-resume
           :empty-lines 1)))

(provide 'dw-workflow)
