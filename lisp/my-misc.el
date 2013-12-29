;;; misc commands/utils
(defun delete-this-file ()
  "Delete the current file, and kill the buffer."
  (interactive)
  (or (buffer-file-name) (error "No file is currently being edited"))
  (when (yes-or-no-p (format "Really delete '%s'?"
                             (file-name-nondirectory buffer-file-name)))
    (delete-file (buffer-file-name))
    (kill-this-buffer)))

(defun rename-this-file-and-buffer (new-name)
  "Renames both current buffer and file it' s visiting to NEW - NAME."
  (interactive " sNew name:")
  (let ((name (buffer-name))
        (filename (buffer-file-name)))
    (unless filename
      (error " Buffer '%s' is not visiting a file ! " name))
    (if (get-buffer new-name)
        (message " A buffer named '%s' already exists ! " new-name)
      (progn
        (rename-file filename new-name 1)
        (rename-buffer new-name)
        (set-visited-file-name new-name)
        (set-buffer-modified-p nil)))))

(defun zap-up-to-char (arg char)
  "Kill up to and including ARGth occurrence of CHAR.
Case is ignored if `case-fold-search' is non-nil in the current
buffer.  Goes backward if ARG is negative; error if CHAR not
found."
  (interactive "p\ncZap to char: ")
  (with-no-warnings
    (if (char-table-p translation-table-for-input)
        (setq char (or (aref translation-table-for char) char))))
  (kill-region (point)
               (progn
                 (search-forward (char-to-string char) nil nil arg)
                 (goto-char
                  (if (> arg 0) (1- (point))
                    (1+ (point))))
                 (point))))

(require 'misc)
(defun copy-above-line ()
  (interactive)
  (copy-from-above-command 1))

(defun delete-trailing-whitespace-untabify ()
  "Delete trailing whitespace and untabify"
  (interactive)
  (save-excursion
    (mark-whole-buffer)
    (let ((start (region-beginning))
          (end (region-end)))
      (untabify start end)
      (delete-trailing-whitespace start end))))

(defun foo ()
  (interactive)
  (message "foo"))

(defun bar ()
  (interactive)
  (message "bar"))

(defun kill-current-buffer ()
  "Kill current buffer"
  (interactive)
  (kill-buffer (current-buffer)))

(defun split-follow-buffer ()
  " Split current buffer into 2 and enter follow mode to make use
of modern wide display"
  (interactive)
  (keyboard-escape-quit)
  (split-window-right)
  (follow-mode)
  (message "split-follow-file"))

(defun reformat-buffer ()
  " Reformat buffer using emacs indent - region "
  (interactive)
  (delete-trailing-whitespace)
  (save-excursion
    (mark-whole-buffer)
    (indent-region (region-beginning) (region-end))))

(defun delete-current-line (&optional arg)
  (interactive "p")
  (let ((here (point)))
    (beginning-of-line)
    (kill-line arg)
    (goto-char here)))


(defun search-selection (beg end)
  " search for selected text "
  (interactive "r")
  (let ((selection (buffer-substring-no-properties beg end)))
    (deactivate-mark)
    (isearch-mode t nil nil nil)
    (isearch-yank-string selection)))


(defun search-current-symbol-or-region ()
  "Emulate VIM' s * to search current symbol under cursor "
  (interactive)
  (if (use-region-p)
      (search-selection (region-beginning) (region-end))
    (let ((symbol (thing-at-point 'symbol)))
      (if symbol
          (progn
            (beginning-of-sexp)
            (isearch-mode t nil nil nil)
            (isearch-yank-string symbol))
        (message " nillll ")))))


(defun occur-current-symbol-or-region ()
  " Emulate VIM 's * to search current symbol under cursor"
  (interactive)
  (if (use-region-p)
      (occur-selection (region-beginning) (region-end))
    (let ((symbol (thing-at-point ' symbol)))
      (if symbol
          (occur-1 symbol list-matching-lines-default-context-lines (list (current-buffer))))
      (message "nillll"))))


(defun turn-on-org-table-mode ()
  (interactive)
  (require 'org-table)
  (orgtbl-mode 1))

(defalias 'otm 'turn-on-org-table-mode)

(provide 'my-misc)