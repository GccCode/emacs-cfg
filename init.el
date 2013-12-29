;; define symbol "emacs-start-time" with value current-time
(defconst emacs-start-time (current-time))
(defconst emacs-start-time (current-time))

;; add some plugin path to @list "load path"
(add-to-list 'load-path "~/.emacs.d")
(add-to-list 'load-path "~/.emacs.d/lisp") ; personal elisp snippets
(add-to-list 'load-path "~/.emacs.d/site-lisp")

;;;_, package server mirror
(package-initialize)
(add-to-list 'package-archives '("marmalade" . "http://marmalade-repo.org/packages/"))
(add-to-list 'package-archives '("org" . "http://orgmode.org/elpa/"))
(add-to-list 'package-archives '("melpa" . "http://melpa.milkbox.net/packages/"))

;; a combined installer and configurer
(require 'use-package)

;; functions defined by lion.kuo
(require 'my-misc)

;; This tell Emacs to set use-package-verbose before using it, so that the macro
;; definition is available during compilation.
(eval-when-compile
  (setq use-package-verbose (null byte-compile-current-file)))

;; defmacro function for hook-inio-modes (func modes)
;; it actually means to call "add-hook (modes func) "
(defmacro hook-into-modes (func modes)
  `(dolist (mode-hook ,modes)
     (add-hook mode-hook ,func)))

;; function to clean terminal symbol like '^M'
(defun cleanup-term-log ()
  "Do not show ^M in files containing mixed UNIX and DOS line endings."
  (interactive)
  (require 'ansi-color)
  (ansi-color-apply-on-region (point-min) (point-max))
  (goto-char (point-min))
  (while (re-search-forward "\\(.\\|
$\\|P.+\\\\\n\\)" nil t)
    (overlay-put (make-overlay (match-beginning 0) (match-end 0))
                 'invisible t))
  (set-buffer-modified-p nil))


;; add hook "clean-term-log" to find-file-hooks
(add-hook 'find-file-hooks
          (function
           (lambda ()
             (if (string-match "/\\.iTerm/.*\\.log\\'"
                               (buffer-file-name))
                 (cleanup-term-log)))))

;;;_ , Enable disabled commands
(put 'downcase-region  'disabled nil)   ; Let downcasing work
(put 'erase-buffer     'disabled nil)
(put 'eval-expression  'disabled nil)   ; Let ESC-ESC work
(put 'narrow-to-page   'disabled nil)   ; Let narrowing work
(put 'narrow-to-region 'disabled nil)   ; Let narrowing work
(put 'set-goal-column  'disabled nil)
(put 'upcase-region    'disabled nil)   ; Let upcasing work

;;;_ remap C-z to a prefix command
(defvar ctl-period-map)
(define-prefix-command 'ctl-z-map)
(bind-key "C-z" 'ctl-z-map)

(defun mark-line (&optional arg)
  (interactive "p")
  (beginning-of-line)
  (let ((here (point)))
    (dotimes (i arg)
      (end-of-line))
    (set-mark (point))
    (goto-char here)))

;; (bind-key "M-L" 'mark-line)

(defun mark-sentence (&optional arg)
  (interactive "P")
  (backward-sentence)
  (mark-end-of-sentence arg))

(bind-key "M-S" 'mark-sentence)
(bind-key "M-X" 'mark-sexp)
(bind-key "M-H" 'mark-paragraph)
(bind-key "M-D" 'mark-defun)
;; (bind-key "M-g c" 'goto-char)
;; (bind-key "M-g l" 'goto-line)

(bind-key "M-s n" 'find-name-dired)

(defun isearch-backward-other-window ()
  (interactive)
  (split-window-vertically)
  (call-interactively 'isearch-backward))

(bind-key "C-z C-s" 'isearch-backward-other-window)

(bind-key "C-c" 'isearch-toggle-case-fold isearch-mode-map)
(bind-key "C-t" 'isearch-toggle-regexp isearch-mode-map)
(bind-key "C-^" 'isearch-edit-string isearch-mode-map)
(bind-key "C-i" 'isearch-complete isearch-mode-map)

(bind-key "C-x t" 'toggle-truncate-lines)

(defun duplicate-line ()
  "Duplicate the line containing point."
  (interactive)
  (save-excursion
    (let (line-text)
      (goto-char (line-beginning-position))
      (let ((beg (point)))
        (goto-char (line-end-position))
        (setq line-text (buffer-substring beg (point))))
      (if (eobp)
          (insert ?\n)
        (forward-line))
      (open-line 1)
      (insert line-text))))

(bind-key "C-x C-d" 'duplicate-line)

(defun find-alternate-file-with-sudo ()
  (interactive)
  (find-alternate-file (concat "/sudo::" (buffer-file-name))))

(bind-key "C-x C-v" 'find-alternate-file-with-sudo)

(defun refill-paragraph (arg)
  (interactive "*P")
  (let ((fun (if (memq major-mode '(c-mode c++-mode))
                 'c-fill-paragraph
               (or fill-paragraph-function
                   'fill-paragraph)))
        (width (if (numberp arg) arg))
        prefix beg end)
    (forward-paragraph 1)
    (setq end (copy-marker (- (point) 2)))
    (forward-line -1)
    (let ((b (point)))
      (skip-chars-forward "^A-Za-z0-9`'\"(")
      (setq prefix (buffer-substring-no-properties b (point))))
    (backward-paragraph 1)
    (if (eolp)
        (forward-char))
    (setq beg (point-marker))
    (delete-horizontal-space)
    (while (< (point) end)
      (delete-indentation 1)
      (end-of-line))
    (let ((fill-column (or width fill-column))
          (fill-prefix prefix))
      (if prefix
          (setq fill-column
                (- fill-column (* 2 (length prefix)))))
      (funcall fun nil)
      (goto-char beg)
      (insert prefix)
      (funcall fun nil))
    (goto-char (+ end 2))))

(bind-key "C-x M-q" 'refill-paragraph)

;; inspired by Erik Naggum's `recursive-edit-with-single-window'
(defmacro recursive-edit-preserving-window-config (body)
  "*Return a command that enters a recursive edit after executing BODY.
 Upon exiting the recursive edit (with\\[exit-recursive-edit] (exit)
 or \\[abort-recursive-edit] (abort)), restore window configuration
 in current frame."
  `(lambda ()
     "See the documentation for `recursive-edit-preserving-window-config'."
     (interactive)
     (save-window-excursion
       ,body
       (recursive-edit))))

(bind-key "C-c 0"
          (recursive-edit-preserving-window-config (delete-window)))
(bind-key "C-c 1"
          (recursive-edit-preserving-window-config
           (if (one-window-p 'ignore-minibuffer)
               (error "Current window is the only window in its frame")
             (delete-other-windows))))

(bind-key "C-c d" 'delete-current-line)

;;;_ lisp mode settings
(defun scratch ()
  (interactive)
  (let ((current-mode major-mode))
    (switch-to-buffer-other-window (get-buffer-create "*scratch*"))
    (goto-char (point-min))
    (when (looking-at ";")
      (forward-line 4)
      (delete-region (point-min) (point)))
    (goto-char (point-max))
    (if (memq current-mode lisp-modes)
        (funcall current-mode))))

(defvar lisp-modes  '(emacs-lisp-mode
                      inferior-emacs-lisp-mode
                      ielm-mode
                      lisp-mode
                      inferior-lisp-mode
                      lisp-interaction-mode
                      slime-repl-mode))

(require 'elisp-slime-nav)
(dolist (hook '(emacs-lisp-mode-hook ielm-mode-hook lisp-interaction-mode))
  (add-hook hook 'elisp-slime-nav-mode))

(defvar lisp-mode-hooks
  (mapcar (function
           (lambda (mode)
             (intern
              (concat (symbol-name mode) "-hook"))))
          lisp-modes))

(defun do-eval-buffer ()
  (interactive)
  (call-interactively 'eval-buffer)
  (message "Buffer has been evaluated"))

(bind-key "C-c e b" 'do-eval-buffer)
(bind-key "C-c e c" 'cancel-debug-on-entry)
(bind-key "C-c e d" 'debug-on-entry)
(bind-key "C-c e e" 'toggle-debug-on-error)
(bind-key "C-c e f" 'emacs-lisp-byte-compile-and-load)
(bind-key "C-c e j" 'emacs-lisp-mode)
(bind-key "C-c e l" 'find-library)
(bind-key "C-c e r" 'eval-region)
(bind-key "C-c e s" 'scratch)
(bind-key "C-c e v" 'edit-variable)

(bind-key "C-h u" 'woman)

(bind-key "M-k" 'kill-current-buffer)
(bind-key "M-a" 'switch-to-buffer)
(bind-key "M-e" 'find-file)
(bind-key "M-0" 'delete-window)
(bind-key "M-1" 'delete-other-windows)
(bind-key "M-*" 'search-current-symbol-or-region)
(define-key isearch-mode-map [(meta *)] 'isearch-repeat-forward)
(define-key isearch-mode-map [(meta &)] 'isearch-repeat-backward)


(bind-key "M-I" 'occur-current-symbol-or-region)

;;; disable menubar toolbar scroll-bar
(if (fboundp 'menu-bar-mode) (menu-bar-mode -1))
(if (fboundp 'tool-bar-mode) (tool-bar-mode -1))
(if (fboundp 'scroll-bar-mode) (scroll-bar-mode -1))

;; global preference for editing etc.
(setq-default
 blink-cursor-delay 0
 inhibit-startup-screen 1
 blink-cursor-interval 0.4
 echo-keystrokes 0.15
 scroll-preserve-screen-position 1
 scroll-conservatively 5
 scroll-step 2
 indicate-empty-lines t
 buffers-menu-max-size 30
 case-fold-search t
 compilation-scroll-output t
 ediff-split-window-function 'split-window-horizontally
 ediff-window-setup-function 'ediff-setup-windows-plain
 grep-highlight-matches t
 grep-scroll-output t
 indent-tabs-mode nil
 make-backup-files nil
 auto-save-default nil
 mouse-yank-at-point t
 highlight-nonselected-windows t
 set-mark-command-repeat-pop t
 show-trailing-whitespace t
 tooltip-delay 1.5
 truncate-lines nil
 truncate-partial-width-windows nil
 x-stretch-cursor t
 completion-cycle-threshold t
 tab-width 4
 major-mode 'text-mode
 visible-bell nil)

(transient-mark-mode t)
(global-visual-line-mode)               ; word wrap
(mouse-avoidance-mode 'animate)
(blink-cursor-mode -1)
(delete-selection-mode t)

(setq linum-format "%d ") ; add a SPC to line number to beautiful display
(global-linum-mode -1)
(global-hi-lock-mode t)                 ; highlight regexp
(which-function-mode t)

(defun toggle-hl-line ()
  (interactive)
  (call-interactively 'global-hl-line-mode))

(bind-key "C-z l" 'toggle-hl-line)

(defun toggle-linum-show ()
  (interactive)
  (if (string= " " linum-format)
      (progn
        (setq linum-format "%d ")
        (global-linum-mode -1)
        (global-linum-mode 1))
    (progn
      (setq linum-format " ")
      (global-linum-mode -1)
      (global-linum-mode 1))))

(toggle-linum-show)
(bind-key "C-c n" 'toggle-linum-show)

(fset 'yes-or-no-p 'y-or-n-p)
(show-paren-mode)
(column-number-mode)

(require 'whitespace)
(setq whitespace-style '(face lines-tail trailing))
(global-whitespace-mode t)

;; jump to file/dir with register
(set-register ?. '(file . "~/.emacs.d/init.el")) ; use C-x r j e to open init.el
(set-register ?, '(file . "~/.emacs.d/"))
(set-register ?d '(file . "~/"))
(set-register ?k '(file . "~/.emacs.d/init-key-binding.el"))
;; (set-register ?g '(file . "~/.gdbinit")) ; for modify gdb debug init file

(bind-key "C-z d" 'delete-trailing-whitespace)
(bind-key "C-z r" 'revert-buffer)
(bind-key "M-Q" 'query-replace-regexp)

(bind-key "C-z C-b" 'split-follow-buffer)

;; smart compile
(defun show-compilation ()
  (interactive)
  (call-interactively 'compile))

(bind-key "M-O" 'show-compilation)
(bind-key "M-?" 'imenu)
(bind-key "M-o" 'reformat-buffer)

(bind-key "M-N" 'next-error)
(bind-key "M-P" 'previous-error)
(bind-key "M-z" 'zap-up-to-char)


(defun turn-on-org-table-mode ()
      (interactive)
      (require 'org-table)
      (orgtbl-mode 1))

(defalias 'otm 'turn-on-org-table-mode)


;; http://www.emacswiki.org/emacs/ZapToISearch
(defun zap-to-isearch (rbeg rend)
  "Kill the region between the mark and the closest portion of
the isearch match string. The behaviour is meant to be analogous
to zap-to-char; let's call it zap-to-isearch. The deleted region
does not include the isearch word. This is meant to be bound only
in isearch mode.  The point of this function is that oftentimes
you want to delete some portion of text, one end of which happens
to be an active isearch word. The observation to make is that if
you use isearch a lot to move the cursor around (as you should,
it is much more efficient than using the arrows), it happens a
lot that you could just delete the active region between the mark
and the point, not include the isearch word."
  (interactive "r")
  (when (not mark-active)
    (error "Mark is not active"))
  (let* ((isearch-bounds (list isearch-other-end (point)))
         (ismin (apply 'min isearch-bounds))
         (ismax (apply 'max isearch-bounds)))
    (if (< (mark) ismin)
        (kill-region (mark) ismin)
      (if (> (mark) ismax)
          (kill-region ismax (mark))
        (error "Internal error in isearch kill function.")))
    (isearch-exit)))

(bind-key "M-z" 'zap-to-isearch isearch-mode-map)

;;;_ align
(use-package align
  :bind (("C-z C-r" . align-regexp)))

;;;_ hideshow
(use-package hideshow
  :bind (("C-z C-f" . hs-toggle-hiding)
         ("C-z C-M-f" . hs-hide-all)))

;;;_ hippie-expand
(use-package hippie-exp
  :bind (("M-/" . hippie-expand))
  :init (progn
          (setq hippie-expand-try-functions-list
                '(try-complete-file-name-partially
                  try-complete-file-name
                  try-expand-all-abbrevs
                  try-expand-list
                  try-expand-line
                  try-expand-dabbrev
                  try-expand-dabbrev-all-buffers
                  try-expand-dabbrev-from-kill
                  try-complete-lisp-symbol-partially
                  try-complete-lisp-symbol))))

;;;_ windmove
(use-package windmove
  :config
  (progn
    (bind-key* "M-L"  'windmove-right)
    (bind-key* "M-H"  'windmove-left)
    (bind-key* "M-K"  'windmove-up)
    (bind-key* "M-J"  'windmove-down)))

;; column editing
(use-package cua-base
  :bind ("M-RET" . cua-set-rectangle-mark)
  :init
  (progn
    (setq-default cua-enable-cua-keys nil)
    (cua-mode)))

;; kconfig
(use-package kconfig-mode
  :mode (("Kbuild\\.?.*$" . makefile-mode)
         ("\\.?.pro$" . makefile-mode)))

(use-package autopair
  :disabled nil
  :commands autopair-mode
  :diminish autopair-mode
  :init
  (hook-into-modes #'autopair-mode '(c-mode-common-hook
                                     text-mode-hook
                                     ruby-mode-hook
                                     python-mode-hook
                                     sh-mode-hook)))
;;;_ , macrostep
(use-package macrostep
  :bind ("C-c e m" . macrostep-expand))

;; (use-package projectile
;;   :diminish projectile-mode
;;   :init
;;   (projectile-global-mode))

;;; redo/undo window configration
(use-package winner
  :diminish winner-mode
  :if (not noninteractive)
  :init
  (progn
    (winner-mode 1)

    ;; copy from winner
    (defun my-winner-redo ()            ; If you change your mind.
      " Restore a more recent window configuration saved by Winner mode."
      (interactive)
      (progn
        (winner-set
         (if (zerop (minibuffer-depth))
             (ring-remove winner-pending-undo-ring 0)
           (ring-ref winner-pending-undo-ring 0)))
        (unless (eq (selected-window) (minibuffer-window))
          (message " Winner undid undo "))))

    (bind-key* "M-R" 'my-winner-redo)
    (bind-key* "M-U" 'winner-undo)))

;;;_ dired
(use-package dired
  :init
  (progn
    (add-hook 'dired-mode-hook
              (lambda ()
                (dired-hide-details-mode 1)
                (require 'dired-x)
                (setq dired-omit-files (concat dired-omit-files "\\|^\\..+$"))
                (dired-omit-mode 1)
                (define-key dired-mode-map "/" 'dired-isearch-filenames-forward)
                (define-key dired-mode-map "?" 'dired-isearch-filenames-backward)
                (define-key dired-mode-map "J" 'find-name-dired)
                (define-key dired-mode-map "K" 'find-grep-dired)))

    (defun dired-isearch-filenames-forward ()
      "Search for a string using Isearch only in file names in the Dired buffer."
      (interactive)
      (let ((dired-isearch-filenames t))
        (isearch-forward)))

    (defun dired-isearch-filenames-backward ()
      "Search for a string using Isearch only in file names in the Dired buffer."
      (interactive)
      (let ((dired-isearch-filenames t))
        (isearch-backward)))

    (defun sof/dired-sort ()
      "Dired sort hook to list directories first."
      (save-excursion
        (let (buffer-read-only)
          (forward-line 2) ;; beyond dir. header
          (sort-regexp-fields t "^.*$" "[ ]*." (point) (point-max))))
      (and (featurep 'xemacs)
           (fboundp 'dired-insert-set-properties)
           (dired-insert-set-properties (point-min) (point-max)))
      (set-buffer-modified-p nil))

    (add-hook 'dired-after-readin-hook 'sof/dired-sort))

  :config
  (progn
    (setq dired-listing-switches "-ahl")))


;;;_ CC mode
(use-package cc-mode
  :mode (("\\.h\\(h?\\|xx\\|pp\\)\\'" . c++-mode)
         ("\\.c+$" . c++-mode)
         ("\\.h+$" . c++-mode))
  :init
  (progn
    ;; init hook
    (add-hook 'c-initialization-hook
              (lambda ()
                (define-key c-mode-base-map "\C-j" 'c-context-line-break)
                (define-key c-mode-base-map "\C-c\C-u" 'c-up-conditional-with-else)
                (define-key c-mode-base-map "\C-c\C-d" 'c-down-conditional-with-else)
                (define-key c-mode-base-map "\C-c\C-i" 'insert-header-guard)
                (define-key c-mode-base-map "\C-z\C-r" 'align-current)
                (setq-default c-electric-pound-behavior (quote (alignleft)))))

    (add-hook 'c-mode-common-hook
              (lambda ()
                (progn
                  (setq c-basic-offset 4)
                  (c-toggle-electric-state 1)
                  (c-toggle-hungry-state 1)
                  (c-toggle-auto-newline 1)
                  (c-toggle-syntactic-indentation 1)
                  (hs-minor-mode t)
                  (add-hook 'write-contents-functions
                            'delete-trailing-whitespace-untabify)
                  (require 'google-c-style)
                  (google-set-c-style)
                  ;; (doxymacs-mode)
                  (define-key c-mode-base-map "\C-c\C-h" 'hif-toggle-block)
                  (setq-default c-echo-syntactic-information-p t)
                  (setq-default c-syntactic-indentation-in-macros t)
                  (hide-ifdef-mode t))))

    (add-hook 'c++-mode-hook
              (lambda ()
                (hs-hide-initial-comment-block)
                ;; (hide-if-0)
                (setq comment-start "/* " comment-end " */")))

    ;; Hook across all luanguage
    (defconst my-c-style
      '((c-basic-offset . 4)
        (c-comment-only-line-offset . 0)
        (c-hanging-braces-alist
         (brace-list-open)
         (topmost-intro-cont after)
         (brace-entry-open)
         (substatement-open after)
         (block-close . c-snug-do-while)
         (class-open after)
         (class-close)
         (arglist-cont-nonempty))
        (c-cleanup-list . (brace-catch-brace
                           defun-close-semi
                           scope-operator
                           compact-empty-funcall
                           comment-close-slash))
        (c-offsets-alist
         (statement-block-intro . +)
         (knr-argdecl-intro . 0)
         (substatement-open . 0)
         (substatement-label . 0)
         (label . 0)
         (inclass . 4)
         (inline-open . 0)
         (arglist-cont-nonempty . c-lineup-arglist)
         (arglist-close . c-lineup-close-paren)
         (statement-cont . +)))
      "My C Programing Style")

    (c-add-style "personal-c-style" my-c-style)) ; :init

  :config
  (progn
    (defun insert-header-guard (&optional arg)
      (interactive "p")
      (if (buffer-file-name)
          (let*
              ((fName (upcase (file-name-nondirectory (file-name-sans-extension buffer-file-name))))
               (ifDef (concat "#ifndef _" fName "_H_" "\n#define _" fName "_H_" "\n"))
               (endDef (concat "\n#endif    " "/* _" fName "_H_ */\n"))
               (insert-cpp-gaurd (equal 4 arg)))
            (progn
              (goto-char (point-min))
              (insert ifDef)
              (when insert-cpp-gaurd (insert "\n#ifdef __cplusplus\nextern \"C\" {\n#endif\n\n"))
              (goto-char (point-max))
              (when insert-cpp-gaurd (insert "\n#ifdef __cplusplus\n}\n#endif\n"))
              (insert endDef)))))))

;;;_ terminal
(use-package term
  :init
  (progn
    (add-hook 'term-mode-hook
              (lambda ()
                (linum-mode -1)
                (setq explicit-shell-file-name "/bin/zsh")
                (setq show-trailing-whitespace nil))))
  :config
  (progn
    (defun my-ansi-term (&optional arg)
      (interactive "p")
      (if (or (eq arg 4)
              (eq nil (get-buffer "*ansi-term*")))
          (progn
            (call-interactively 'ansi-term))
        (progn
          (pop-to-buffer "*ansi-term*"))))

    (bind-key "M-T" 'my-ansi-term)))

;;;_ ag, search accross project
(use-package ag
  :bind
  (("C-z C-a" . ag-project-at-point)
   ("C-z C-M-a" . ag-regexp-project-at-point)))

(use-package magit
  :bind (("C-c C-g" . magit-status))
  :config
  (progn
    (defadvice magit-status (around magit-fullscreen activate)
      (window-configuration-to-register :magit-fullscreen)
      ad-do-it
      (delete-other-windows))

    (defun magit-quit-session ()
      "Restores the previous window configuration and kills the magit buffer"
      (interactive)
      (kill-buffer)
      (jump-to-register :magit-fullscreen))

    (define-key magit-status-mode-map (kbd "q") 'magit-quit-session)))


;;;_ ido
(use-package ido
  :bind
  (("M-2" . switch-to-buffer-vertically)
   ("M-3" . switch-to-buffer-horizontally)
   ("M-4" . switch-to-buffer-other-window))

  :init
  (progn
    (ido-mode)
    (ido-everywhere t)
    (setq ido-enable-flex-matching t)
    (setq ido-use-filename-at-point nil)
    (setq ido-auto-merge-work-directories-length 0)
    (setq ido-use-virtual-buffers t))

  :config
  (progn
    (use-package ido-hacks
      :init
      (ido-hacks-mode 1))

    (use-package flx-ido
      :init
      (progn
        (flx-ido-mode 1)
        (setq ido-use-faces nil)))

    (use-package ido-ubiquitous
      :init
      (ido-ubiquitous-initialize))

    (use-package ido-at-point
      :init
      (ido-at-point-mode))

    (use-package ido-load-library
      :bind (("C-c l" . ido-load-library))
      :config
      (progn
        (defalias 'load-library 'ido-load-library)))

    (use-package smex
      :bind (("M-x" . smex))
      :config
      (progn
        (smex-initialize)))

    (defun find-file-vertically ()
      (interactive)
      (let ((file (ido-read-file-name "Find file vertically: ")))
        (message file)
        (split-window-below)
        (windmove-down)
        (find-file file)))

    (defun find-file-horizontally ()
      (interactive)
      (let ((file (ido-read-file-name "Find file vertically: ")))
        (message file)
        (split-window-right)
        (windmove-right)
        (find-file file)))

    (defun switch-to-buffer-vertically ()
      (interactive)
      (let ((b (ido-read-buffer "Find file vertically: ")))
        (message b)
        (split-window-below)
        (windmove-down)
        (switch-to-buffer b)))

    (defun switch-to-buffer-horizontally ()
      (interactive)
      (let ((b (ido-read-buffer "Find file vertically: ")))
        (message b)
        (split-window-right)
        (windmove-right)
        (switch-to-buffer b)))))

;;;_ my global-hight
(use-package highlight-global
  :bind (("M-\"" . highlight-frame-toggle)
         ("M-+" . clear-highlight-frame)))

;;;_ expand region
(use-package expand-region
  :bind (("M-M" . er/expand-region)))


(use-package org-mode
  :bind (("M-p" . epresent-run)
         ("C-c a" . org-agenda)
         ("C-c C-i" . org-insert-link))

  :init (progn
          (setq-default org-export-babel-evaluate nil)
          (require 'epresent))
  :config (progn
            (bind-key "C-c C-l" 'org-store-link)
            (bind-key "C-c C-M-l" 'org-insert-link)))

;;;_ python
;; (use-package python
;;   :init
;;   :config
;;   (progn
;;     (add-hook 'python-mode-hook
;;               (lambda ()
;;                 (unbind-key "M-o" python-mode-map)
;;                 ;; (define-key python-mode-map (kbd "M-o") 'foo))
;;               ))))


;;;_. Post initialization

(when t
  (let ((elapsed (float-time (time-subtract (current-time)
                                            emacs-start-time))))
    (message "Loading %s...done (%.3fs)" load-file-name elapsed))

  (add-hook 'after-init-hook
            `(lambda ()
               (let ((elapsed (float-time (time-subtract (current-time)
                                                         emacs-start-time))))
                 (message "Loading %s...done (%.3fs) [after-init]"
                          ,load-file-name elapsed)))
            t))

;; Local Variables:
;;   mode: emacs-lisp
;;   mode: allout
;;   outline-regexp: "^;;;_\\([,. ]+\\)"
;; End:

;;; init.el ends here
