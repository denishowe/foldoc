;; foldoc.el
;; An Emacs major mode for editing the Free On-line Dictionary of+
;; Computing
;; Denis Howe <dbh@doc.ic.ac.uk>
;; 1997-06-17 - 1998-08-25

;; In your ~/.emacs, put:
;; (autoload 'foldoc-mode "foldoc-mode" "" t)
;; and do M-x foldoc-mode to switch to FOLDOC mode.

;; Many of these commands are only relevant to editing the whole
;; dictionary file but a few are also useful for individual entries.


(defvar foldoc-source-file "~/Dictionary"
  "The latest version of the dictionary.")

(defvar foldoc-directory "/home/wombat/etc/www/foldoc"
  "The root of the FOLDOC directory hierarchy")

(defvar foldoc-contributors-file
  (concat foldoc-directory "/contributors.html")
  "File listing names of contributors to the dictionary.")

(defvar foldoc-contents-directory
  (concat foldoc-directory "/contents")
  "Directory containing listings by subject.")

(defvar foldoc-latest-file
  (concat foldoc-directory "/latest")
  "File containing the term updated most recently")

(defvar foldoc-classes nil
  "List of subject strings.
Bulit from contents directory file names on first use.")

;;; Functions

(defun foldoc-mode ()
  "Major mode for editting the Free On-Line Dictionary of Computing.
\\{foldoc-mode-map}"
  (interactive)
  (setq major-mode 'foldoc-mode)
  (setq mode-name "Foldoc")
  (setq foldoc-mode-map (copy-keymap text-mode-map))
  (define-key foldoc-mode-map "\C-]"     'foldoc-make-reference)
  (define-key foldoc-mode-map "\C-c\C-@" 'foldoc-mark-def)
  (define-key foldoc-mode-map "\C-c\C-b" 'foldoc-backward-def)
  (define-key foldoc-mode-map "\C-c\C-c" 'foldoc-clean)
  (define-key foldoc-mode-map "\C-c\C-d" 'foldoc-copy-def-as-kill)
  (define-key foldoc-mode-map "\C-c\C-f" 'foldoc-forward-def)
  (define-key foldoc-mode-map "\C-c\C-k" 'foldoc-kill-def)
  (define-key foldoc-mode-map "\C-c\C-s" 'foldoc-follow)
  (define-key foldoc-mode-map "\C-c\C-w" 'foldoc-date)
  (define-key foldoc-mode-map "\C-ca"  	 'foldoc-abbrev-transpose)
  (define-key foldoc-mode-map "\C-cl"  	 'foldoc-long)
  (define-key foldoc-mode-map "\C-cs"  	 'foldoc-set-subjects)
  (define-key foldoc-mode-map "\t"  	 'self-insert-command)
  (define-key foldoc-mode-map "\e\C-o" 	 'open-paragraph)
  (define-key foldoc-mode-map "\e\t"   	 'foldoc-complete-class)
  (define-key foldoc-mode-map "\e'"    	 'double-quote)
  (use-local-map foldoc-mode-map)
  (set-syntax-table foldoc-syntax-table)
  ;; needed? (setq indent-tabs-mode t)
  (setq fill-prefix "\t")
  (setq fill-column 70)
  (auto-fill-mode 1)
  (setq adaptive-fill-regexp nil)
  (setq adaptive-fill-mode nil))

(defvar foldoc-syntax-table
  (copy-syntax-table)
  "A syntax table for FOLDOC mode.")
;; Make < and > parens
(modify-syntax-entry ?< "(>" foldoc-syntax-table)
(modify-syntax-entry ?> ")<" foldoc-syntax-table)


(setq foldoc-cleanups '(
  ("[ \t]+$"	       "trailing whitespace" (delete-region (match-beginning 0) (match-end 0)))
  ("^  ? ? ? ? ? ? ?[^ 	]" "1-8 leading spaces" (delete-horizontal-space) (insert ?\t))
  ("^ "		       "leading space")
  ("\n\n\n"	       "multiple gaps"	(delete-char 1))
  ("([^)]*\n\n"	       "Missing ')'"	(forward-char) ;; prevent loop
					(or (looking-at "\"\\.") (error msg)))
  ("\\[[^]]*\n\n"      "Missing ']'"	(forward-char) ;; prevent loop
					(or (looking-at "\"\\.") (error msg)))
  ("{[^}]*\n\n"	       "Missing '}'"	(forward-char) ;; prevent loop
					(or (looking-at "\" ") (error msg)))
  ("^[^\t\n].*\n[^\n]" "Missing gap"    (end-of-line) (open-paragraph))))

;; lines which are OK really though they look odd.

(setq foldoc-cleanup-exceptions 
  '("	   o----)||(--+--|<----+----------+"
    "		[1 J^P$L$$"
    "	 {"))

(defvar foldoc-cleanup-number 0)

(defun foldoc-clean (n)
  "Check the dictionary according to foldoc-cleanups.

Start from the current position with cleanup N.  With no argument,
continue with the previous cleanup, given by variable
'foldoc-cleanup-number'."
  (interactive (list (or current-prefix-arg foldoc-cleanup-number)))
  (setq foldoc-cleanup-number n)
  (let (op)
    (while (setq op (elt foldoc-cleanups foldoc-cleanup-number))
      (let ((re (car op))
	    (msg (car (cdr op)))
	    (actions (cdr (cdr op))) line)
	(while (progn (message "Searching for %s..." msg)
		      (re-search-forward re nil t))
	  ;; Found something, what to do?
	  (goto-char (match-beginning 0))
	  (save-excursion
	    (beginning-of-line)
	    (setq line (buffer-substring (point) (progn (end-of-line) (point)))))
	  (if (member line foldoc-cleanup-exceptions)
	      (forward-char)		; prevent loop
	    (if actions
		(let ((actions actions))
		  (message "%s" msg)(sit-for 0.5)
		  (while actions
		    (eval (car actions))
		    (setq actions (cdr actions)))
		  (sit-for 0))
	      (forward-char)		; No action - just error
	      (error msg))))
	;; Next op
	(sit-for 1)
	(setq foldoc-cleanup-number (1+ foldoc-cleanup-number))
	(goto-char (point-min)))))
  (message "Done"))

(defun open-paragraph ()
  "Insert a blank line after point.
Fill the following text as a new paragraph."
  (interactive)
  (delete-space 0)
  (insert "\n\n\t")
  (my-fill-paragraph))

(defun double-quote ()
  "Replace the next group of single quotes (') or grave accents (`)
with double quotes (\")."
  (interactive)
  (let ((quotes "['`]+"))
    (re-search-forward quotes)
    (delete-region (match-beginning 0) (match-end 0))
    (insert ?\")))

(defun double-quotes ()
  (interactive)
  (query-replace-regexp "`+\\([^`']*\\)'+" "\"\\1\"" nil))


(defvar foldoc-date-format "%Y-%m-%d"
  "Date format used in FOLDOC source.")

(defun foldoc-date ()
  "Insert today's date after the current article.
Also update the `most recent update' on the home page."
  (interactive)
  (forward-char)			; Find *next* article's header
  (re-search-forward "^[^\t\n]")
  (beginning-of-line)			; Start of next header
  (let ((next-header (point)))
    (skip-chars-backward " \t\n")	; Just after this article
    (beginning-of-line)			; Start of last line of this article
    (if (or (looking-at "\t(19[0-9][0-9]-[0-9][0-9]-[0-9][0-9])")
	    (looking-at "\t([0-3]?[0-9] [JFMASOND][aepuco][nbrylgptvc] [0-9][0-9][0-9][0-9])"))
	(skip-chars-backward " \t\n")	; After text before date
      (end-of-line))			; After text (no date)
    (delete-region (point) next-header)
    (save-excursion
      (insert-and-inherit
       "\n\n\t(" (format-time-string foldoc-date-format) ")\n\n"))
    (save-excursion (foldoc-latest))))

; (format "\n\n\t(%02d %s %s)\n\n"
;  (string-to-int (substring date 8 10))
;  (substring date 4 7)
;  (substring date -4))))))

(defun foldoc-abbrev-transpose ()
  "Turn an acronym expansion into an expansion plus acronym
Eg.
	TLA

		{Three Letter Acronym}...

becomes

	Three Letter Acronym

	(TLA) ..."
  (interactive)
  (let (start acronym expansion)
    (beginning-of-line)
    (search-forward "{")
    (setq start (point))
    (re-search-forward "[}.\n]+")	; End of expansion
    (setq expansion (buffer-substring start (match-beginning 0)))
    (goto-char (match-end 0))
    (save-excursion
      (re-search-backward "^[^\t\n]")	; Start of title
      (end-of-line)			; End of title
      (setq acronym (buffer-substring (match-beginning 0) (point))))
    (delete-space)
    (insert "\n\n" expansion "\n\n\t(" acronym ") ")
    (backward-char)))

(defun foldoc-follow (nwords)
  "Search for the entry headed with the N word(s) starting at point.
Interactive default is to search for the term in {} around or after
point."
  (interactive "P")
  (isearch-mode t)
  (or nwords
      (and (re-search-backward "[{}]" nil t)
	   (looking-at "{")
	   (goto-char (match-end 0)))
      (and (looking-at "}") (search-forward "{"))
      (error "No term found"))
  (let ((start (point)) string)
    (if nwords
	(forward-word nwords)
      (search-forward "}")
      (backward-char))
    (setq string (buffer-substring start (point)))
    ;; Replace line break with space
    (let ((nl (string-match "\n\t" string)))
      (if nl (setq string (concat (substring string 0 nl) " "
				  (substring string (+ nl 2))))))
    (goto-char (point-min))
    (setq isearch-string (concat "\n" string)
	  isearch-message (mapconcat 'isearch-text-char-description isearch-string "")
	  isearch-yank-flag t)
    (isearch-search-and-update)))

(defun foldoc-long ()
  "Find long lines."
  (interactive)
  (message "Searching...")
  (while
      (progn
	(end-of-line)
	(and (or (<= (current-column) fill-column)
		 (progn
		   (skip-chars-backward "\\.,]")
		   (backward-char 2)
		   (looking-at ")}")))
	     (zerop (forward-line)))))
  (message "Done"))

(defun rmail-from-name ()
  "Return the name from the From header of an rmail-buffer or nil if
none or not in an rmail buffer."
  (and (equal major-mode 'rmail-mode)
       (progn
	 (goto-char (point-min))
	 (or ;; First look for NAME <EMAIL>
	  (re-search-forward "^From: \"?\\([^\"<]*\\)\"? <" nil t)
	  ;; Then try EMAIL (NAME)
	  (re-search-forward "^From: .*(\\(.*\\))"))
	 (buffer-substring (match-beginning 1) (match-end 1)))))

(defun foldoc-contributor (name)
  "Insert NAME in the dictionary acknowledgements."
  (interactive (list (read-from-minibuffer "Contributor: "
					   (rmail-from-name))))
  (find-file foldoc-contributors-file)
  (widen)
  (goto-char (point-min))
  (if (search-forward (concat name ",") nil t)
      (message "%s already present" name)
    (search-forward "<!-- CONTRIBUTORS -->")
    (forward-char 1)
    (let ((start (point)))		; Start of names
      (search-forward "<!-- /CONTRIBUTORS -->")
      (beginning-of-line)
      (narrow-to-region start (point)))	; Region is now just names
    (goto-char (point-min))
    (insert name ",\n")			; Add new entry
    (backward-char 1)
    (while (not (eobp))			; put ':' before family name
      (search-backward " ")
      (forward-char 1)
      (insert ":")
      (end-of-line 2))
    (message "sorting...")
    (shell-command-on-region
     (point-min) (point-max) "/bin/sort -t: -f +1 +0u" t)
    (message "sorting...done")
    (let ((n 0)
	  (new (make-marker)))
      (goto-char (point-min))
      (while (not (eobp))
	(setq n (1+ n))
	(search-forward ":" nil t)	; Zap ":"s
	(backward-delete-char 1)
	(beginning-of-line 1)
	(and (looking-at name)		; Mark new entry
	     (set-marker new (point)))
	(beginning-of-line 2))		; Next line
      (widen)
      (goto-char (point-min))		; Rewrite count
      (search-forward "<!-- NUM -->")
      (kill-word 1)			; Zap old count
      (insert (format "%d" n))		; Insert new count
      (goto-char new)
      (message "%d contributors" n))))

;; (foldoc-contributor "Barney Bear")

(defun delete-space (&optional n)
  "Delete all spaces, tabs and newlines around point.
Leave ARG spaces.  If no prefix argument is given, ARG defaults to 0,
not 1.  If the prefix argument is just \\[universal-argument], leave a blank line."
  (interactive "*P")
  (skip-chars-backward " \t\n")
  (delete-region (point) (progn (skip-chars-forward " \t\n") (point)))
  (cond
   ((equal n '(4)) (insert "\n\n"))
   (n (insert-char ?  (prefix-numeric-value n)))))

;; fill-paragraph works on the paragraph after point which is never
;; what you want.

(defun my-fill-paragraph (&optional arg)
  "Fill paragraph before point."
  (interactive "P")
  (save-excursion
    (backward-paragraph)
    (if (looking-at "\n") (forward-char))
    (let ((fill-prefix (guess-fill-prefix)))
      (fill-paragraph arg))))

(defun guess-fill-prefix ()
  "Return a guess at this line's correct fill-prefix.  Does not set
fill-prefix variable."
  (save-excursion
    (beginning-of-line)
    (if (looking-at "[-	 >#]+")
	(buffer-substring (point) (match-end 0))
      "")))

(defun foldoc-complete-class (init-classes)
  "Complete a subject classification.
Refers to variable foldoc-classes for classes.  If foldoc-classes is
nil or a prefix argument is given call foldoc-find-classes to set it."
  (interactive "P")
  (or (and (not init-classes) foldoc-classes)
      (foldoc-find-classes))
  (complete-expand foldoc-classes))

(defun foldoc-find-classes ()
  "Set the variable foldoc-classes from the files in
  foldoc/contents."
  (setq foldoc-classes
	(mapcar '(lambda (file) (list (substring file 0 -5)))
		(directory-files foldoc-contents-directory nil "..+\\.html"))))

(defun complete-expand (abbrev-alist)
  "Complete the word before point from a user-defined list."
  (interactive)
  (let* ((word (word-before-point))
	 (expansion (try-completion word abbrev-alist)))
    (cond
     ((eq expansion t)
      (message "Complete"))
     ((null expansion)
      (error "No completion"))
     ((not (string= expansion word))
      (backward-kill-word 1)
      (insert expansion))
     (t
      (message "Complete but not unique")
      (with-output-to-temp-buffer "*Completions*"
	(display-completion-list
	 (all-completions word abbrev-alist)))))))

(defun word-before-point ()
  "Return the word before point."
  (buffer-substring
   (save-excursion (forward-word -1) (point))
   (point)))

(defun foldoc-mark-def ()
  "Place mark and point around the definition around or after point."
  (interactive)
  (forward-char)			; In case at start
  (re-search-backward "^[^\t\n]")	; Start of this def
  (backward-char)			; Blank line before def
  (push-mark)				; Mark start
  (forward-char 2)			; Force *next* match
  (and (re-search-forward "^[^\t\n]" nil 'limit) ; Start of next header
       (backward-char 2)))		; Blank line before next match

(defun foldoc-copy-def-as-kill ()
  "Copy the definition around point to the kill-ring."
  (interactive)
  (foldoc-mark-def)
  (copy-region-as-kill (mark) (point)))

(defun foldoc-set-subjects (subjects)
  "Insert SUBJECTS as the subject tags for the current article."
  (interactive
   (list (progn
	   (define-key minibuffer-local-map "\t" 'foldoc-complete-class)
	   (read-from-minibuffer "Subjects: "))))
  (forward-char)
  (re-search-backward "^[^\t\n]")
  (forward-line 2)
  (forward-char)
  (insert "<" subjects "> "))

(defun foldoc-kill-def ()
  "Kill the current definition."
  (interactive)
  (foldoc-mark-def)
  (kill-region (point) (mark)))

(defun foldoc-forward-def (count)
  "Move forward to the end of the Nth definition.
Interactive N is prefix argument.  Negative N means move back."
  (interactive "p")
  (forward-char (if (< count 0) 1 2))	; Skip past start
  (re-search-forward "^[^\t\n]" nil nil count)
  (goto-char (1- (match-beginning 0))))	; Blank line before def

(defun foldoc-backward-def (count)
  "Move back to the end of the Nth definition.
Interactive N is prefix argument.  Negative N means move forwards."
  (interactive "p")
  (foldoc-forward-def (- count)))

(defun foldoc-reply ()
  "Reply to a FOLDOC contributor."
  (interactive)
  (let (def)
    (save-excursion
      (find-file foldoc-source-file)
      (foldoc-mark-def)
      (setq def (buffer-substring (mark) (point))))
    ;; Find an RMAIL buffer to reply to
    (or (equal major-mode 'rmail-mode)
	(set-buffer
	 (or (get-buffer (file-name-nondirectory rmail-file-name))
	     (get-buffer "pending")
	     (get-buffer "delegated")
	     (error "No message to reply to"))))
    (let ((mail-archive-file-name))	; Disable archiving
      (rmail-reply t))
    (delete-other-windows)
    (insert "Thanks very much for the information.\n" def)
    (mail-signature nil)
    (goto-char (point-min))))

(defun foldoc-make-reference (&optional count)
  "Turn the next COUNT (default 1) words into a FOLDOC cross-reference."
  (interactive "p")
  (backward-char 1)
  (if (looking-at "}")
      (delete-char 1)
    (forward-char 1)
    (forward-word 1)
    (backward-word 1)
    (insert "{"))
  (forward-word count)
  (insert "}"))

(defun foldoc-latest ()
  "Write text for the `latest update' notice on the home page."
  (foldoc-backward-def 1)		; Start of entry
  (forward-char 1)			; Start of heading
  (let ((heading (buffer-substring-no-properties
		  (point) (progn (end-of-line) (point)))))
    (set-buffer (generate-new-buffer "latest"))
    (insert heading "\n"))
  (write-file foldoc-latest-file)
  (kill-buffer nil))

;; End of foldoc.el
