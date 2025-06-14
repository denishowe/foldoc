;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Denis Howe <dbh@doc.ic.ac.uk>'s amazing expanding .emacs file.
;;
;; See /usr/local/[lib]/{emacs,epoch}/lisp/startup.el,
;; site-init.el, loaddefs.el for other configuration gumf.
;;
;; Last updated: 2006-10-11 09:13
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; Frequently changed things

;; Menu of favourite files

(setq favourite-files '(
  "~/mail/pending"
  "~/Dictionary"
  "~/foldoc/foldoc/missing.html"
  "~/foldoc/foldoc/index.html"
  "~/foldoc/europa.links"
  "~/bin/mail.pl"
  "~/.emacs"
  ))

;; Where to save mail

(setq rmail-boxes '( ;; in order of increasing probability
  "amazon"     "commerce"
  "europa"     "europa"
  "kenelise"   "ex-ic"
  "jeffcock"   "ex-ic"
  "claire"     "ex-ic"
))

;; What to do to a file

(setq dired-auto-shell-command-alist
 '(("\\.[Tt].*[Zz]$"    "zcat * | tar tvf -")
   ("\\.shar.g*[Zz]$"	"zcat * | unshar")
   ("\\.ps$"		"gv &")
   ("\\.ps[.gZz]*$"	"zxdvi")
   ("\\.dvi$"		"xdvi &")
   ("\\.dvi$"		"dvitty -q -w132")
   ("\\.dvi[.gZz]*$"	"zxdvi")
   ("\\.au$"		"play")
   ("\\.tar$"		"tar tvf")
   ("\\.u*e*$"		"uudecode")
   ("\\.gif$"		"xv -root -quit &")
   ("\.tex$"		"latex")
   ("\\.shar$"		"unshar")
   ("^![Rr][Uu][Nn][Ii][Mm]" "baslist -n")	; Tokenised BASIC program
   ("\\.defaults$"	"xrdb")
   ("^a\\.out$"		"*")
   ("uucode$"		"spark -tv")
   ("\\.hp$"		"hp2ps *; gv -sea *b.ps &")
   ("\\.jpe?g$"		"xv -root -quit &")
   ("\\.html?"		"uphtml")))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Miscellaneous variables

;; Bind this here in case of .emacs bug
(global-set-key "\M-e" 'eval-current-buffer)

(setq message-log-max nil)			; Disable message logging

;; Where to find elisp files

(defvar default-load-path load-path
  "Standard places to look for lisp files.  Initialised from ``load-path''.")
(setq load-path (append (list "~dbh/lisp/") default-load-path))

(setq after-load-alist nil)			; Clear all eval-after-load's

;(standard-display-european 1)			; Eight-bit characters

;; add-hook doesn't seem to assume anything much about its arguments
(defalias 'add-item 'add-hook)
; (setq visible-bell t)				; Quiet, the baby's asleep
(setq next-line-add-newlines nil)		; Don't extend buffer
(setq inhibit-startup-message t)		; I know it by heart
(setq completion-ignored-extensions
  '("~" ".aux" ".a" ".bbl" ".blg" ".dvi" ".elc"
    ".hc" ".hi" ".log" ".mlc" ".o" ".toc"))
(put 'eval-expression 'disabled nil)		; Let's talk sexps
(put 'upcase-region 'disabled nil)		; No need to SHOUT
(put 'downcase-region 'disabled nil)
(put 'narrow-to-region 'disabled nil)
(setq enable-local-eval t)
;; (setq term-file-prefix nil)			; Don't load term specific code

;; List full filename, with path
; (setq-default mode-line-buffer-identification '(buffer-file-name ("%f") ("%b")))
(setq indent-line-function 'indent-or-insert)
(setq european-calendar-style t)		; For diary
(setq enable-recursive-minibuffers t)

(autoload 'defadvice "advice" "Define a piece of advice" nil t)
(autoload 'ad-add-advice "advice" "Add a piece of advice")
(autoload 'ad-start-advice "advice" "Start advice magic" t)
(setq ad-start-advice-on-load t)
(setq ad-activate-on-definition t)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Misc modes

(setq auto-mode-alist '(
  ("\\.el\\'" 	 . emacs-lisp-mode)
  ("\\.emacs\\'" . emacs-lisp-mode)
  ("\\.l?hs$"    . gofer-mode)
  ("\\.gp$"      . gofer-project-mode)
  ("Dictionary$" . foldoc-mode)
  ("[-.]info$"   . info-file-mode)
;; too loose  ("/info/" 	 . info-file-mode)
  ("\\.m$"  	 . mira-mode)
  ("\\.c\\'" 	 . c-mode)
  ("\\.h\\'" 	 . c-mode)
  ("\\.tex\\'"   . LaTeX-mode)
  ("\\.sty\\'" 	 . LaTeX-mode)
  ("\\.bbl\\'" 	 . LaTeX-mode)
  ("\\.bib\\'" 	 . bibtex-mode)
  ("\\.texi"     . texinfo-mode)
  ("\\.pl\\'" 	 . perl-mode)
  ("\\.awk\\'" 	 . awk-mode)
  ("\\.tar\\'" 	 . tar-mode)
  ("\\.y\\'"   	 . c-mode)
  ("\\.f?lex\\'"  . c-mode)
  ("\\*mail\\*"  . mail-mode)
  ("\\.html\\'"  . html-helper-mode)
))

(setq c-continued-brace-offset -4)	; Don't indent braces

(add-hook 'c-mode-hook (function (lambda () (setq comment-column 40))))

(eval-after-load "perl-mode" '(progn
  ; (setq perl-indent-level 4) ; This is the default anyway
  (setq perl-continued-statement-offset 4)
  ;; (define-key perl-mode-map "\e\C-a" 'find-file-at-point)
  (define-key perl-mode-map "\C-m" 'newline-and-indent)))

;; Set these for every Perl buffer
(add-hook 'perl-mode-hook (function (lambda ()
  (setq tab-width 4)
  (setq comment-column 40))))

;; For editing the Free On-line Dictionary of Computing
(autoload 'foldoc-mode "foldoc-mode" "" t)
(autoload 'foldoc-reply "foldoc-mode" "" t)
(autoload 'foldoc-contributor "foldoc-mode" "" t)
(autoload 'foldoc-copy-def-as-kill "foldoc-mode" "" t)
(global-set-key "\C-c\C-d" 'foldoc-copy-def-as-kill)
(global-set-key "\C-c\C-r" 'foldoc-reply)
(global-set-key "\C-cc" 'foldoc-contributor)

(autoload 'blackbox "blackbox" "" t nil)	; A fun game

(autoload 'calc "calc" "" t)

(setq resize-minibuffer-mode t)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Lisp functions

(autoload 'which "which" "Show where FUNCTION will be loaded from" t)

(defun lisp-play ()
  "Create a temporary buffer to play Lisp in."
  (interactive)
  (switch-to-buffer "Lisp playpen")
  (lisp-interaction-mode))

(defun debug-on-error ()
  "Toggle variable ``debug-on-error''."
  (interactive)
  (setq debug-on-error (not debug-on-error))
  (message "debug-on-error=%s" debug-on-error))

(global-set-key "\C-cd" 'debug-on-error)

(defun ignore (&rest rest)
  "Do nothing and return nil.
Accept any number of arguments, ignore them and do nothing.  Do not
change variable this-command.

If you accidentally drag the mouse, mouse-set-point uses the end
position when usually you want the start.  One solution is to bind
commands to the down event and bind ignore to the up event.  This is
almost like binding the event to the null keyboard macro, \"\", but
that changes \"this-command\"."
  (interactive)
  (setq this-command last-command)
  nil)

(defmacro value (symbol)
  "Return a variable's value if it has one else nil."
  (and (boundp symbol) symbol))

(defun ok (&optional string)
  "Display a debugging message optionally containing STRING."
  (interactive "P")
  (if (interactive-p)
      (progn
	(beginning-of-line)
	(insert (format "(ok \"%s\")\n" (what-line)))))
  (message "%s" (concat "OK " string))
  (sit-for 2))

(defun right (n s)
  "Return the last N charcters of STRING."
  (substring s (- (length s) n)))

(defun init-string (s)
  "Return a string minus its last character."
  (substring s 0 -1))

(defun last (s)
  "Return the last element of a vector, list or string SEQUENCE."
  (elt s (1- (length s))))

(defun any (f l)
  "Apply FUNCTION to each element of LIST and return the first result
that is non-nil.  Return nil if all results are nil."
  (and l (or (apply f (list (car l))) (any f (cdr l)))))

(defun set-function (new old)
  "If symbol NEW has no function value then set it to that of OLD."
  (or (fboundp new)
      (fset new (symbol-function old))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; X Window System

;; (shell-command "xfontsel -print &")

(defun frame-title (name &optional frame)
  "Set the name of the currently selected frame to NAME (a string).
Optional second argument FRAME specifies frame whose name should be
set."
  (interactive "sFrame title: ")
  (modify-frame-parameters (or frame (selected-frame))
			   (list (cons 'name name))))

;; From term/x-win.el
;; VNC doesn't seem to update the selection so go straight to the cut buffer

(defun x-cut-buffer-or-selection-value ()
  (let ((text (x-get-cut-buffer)))
    (cond
     ((string= text "") nil)
     ((not text) nil)
     ((eq text x-last-selected-text) nil)
     ((string= text x-last-selected-text)
      ;; Record the newer string, so subsequent calls can use eq
      (setq x-last-selected-text text)
      nil)
     (t (setq x-last-selected-text text)))))

(defun make-cd-command ()
  "Set the X selection to a shell \"cd\" command that will change to the
current buffer's default directory."
  (interactive)
  (kill-new (concat "cd " default-directory "\n")))

(defun mouse-match-point (event)
  "Set the point at the mouse position.
If it was on a parenthesis, show the matching one and save the
parenthesised expression on the kill ring."
  (interactive "@e")
  (mouse-set-point event)
  (save-excursion
    (let ((beg (point)) end
	  last-command)				; Don't append next kill.
      (cond ((match-paren)
	     (undo-boundary)
	     (setq end (point))
	     (if (> beg end) (setq end beg  beg (point)))
	     (kill-ring-save beg (1+ end))
	     (sit-for 1))))))

(defun mouse-save-then-yank (event)
  "Save the secondary region and yank it at point.

Copy the text between the secondary mark and the mouse to the kill
ring and the secondary X selection then yank it at point.

Clicking again at the same point deletes the text as well."
  (interactive "e")
  (let* ((pos (event-start event))
	 (mouse (posn-point pos))
	 (start (marker-position mouse-secondary-start))
	 (again (eq last-command this-command)))
    (save-excursion
      (set-buffer (window-buffer (posn-window pos)))
      (if again
	  (delete-region start mouse)		; Second time just delete.
	(let ((text (buffer-substring start mouse)))
	  (kill-new text)
	  (x-set-selection 'SECONDARY text))))
    (or again (yank))))				; Outside the save-excursion.


(defun mouse-toggle-subtree (event)
  "Show the current line's subtree if it's hidden else hide it."
  (interactive "@e")
  (cond ((same-place event)
	 (outline-back-to-heading)
	 (outline-end-of-heading)
	 (if (looking-at "\r")
	     (progn (show-entry) (show-children))
	   (hide-subtree)))))

(defun mouse-command-p ()
  "Was the current command invoked from a mouse event?
Ie. does `last-command-event' contain a list?"
  (listp last-command-event))

(defun mouse-yes-or-no-p (prompt)
  "Display a popup menu with choices `yes' and `no' and title PROMPT.
Return t if yes is selected."
  (x-popup-menu t (list "yes-no menu"
			(list prompt
			      (cons "Yes" t)
			      (cons "No" nil)))))

;; Save the original built-in keyboard yes-or-no-p.

(or (fboundp 'key-yes-or-no-p)
    (fset 'key-yes-or-no-p (symbol-function 'yes-or-no-p)))

(defun yes-or-no-p (prompt)
  "Ask a yes/no question.
If the current command was invoked with a mouse click, display a popup
menu else prompt in the minibuffer.  Take one argument - the string to
display to ask the question.  Return t if answer is yes."
  (if (mouse-command-p)
      (mouse-yes-or-no-p prompt)
    (key-yes-or-no-p prompt)))

;; Save the original built-in keyboard y-or-n-p.

(or (fboundp 'key-y-or-n-p)
    (fset 'key-y-or-n-p (symbol-function 'y-or-n-p)))

(defun y-or-n-p (prompt)
  "Ask user a y/n question.
Take one argument, a prompt string to display to ask the question.  It
should end in a space; `y-or-n-p' adds `(y or n) ' to it.  No
confirmation of the answer is requested; a single character is enough.
Also accepts Space to mean yes, or Delete to mean no.  If the current
command was invoked with a mouse click, display a popup menu else
prompt in the minibuffer.  Return t if answer is `y'."
  (if (mouse-command-p)
      (mouse-yes-or-no-p prompt)
    (key-y-or-n-p prompt)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Dired

;; See also dired-auto-shell-command-alist at top of file.

(setq dired-keep-marker-copy nil)
(setq dired-dwim-target t)

(eval-after-load "dired" '(progn
;   (add-hook 'dired-before-readin-hook 'abbreviate-buffer-directory-name)
;   (setq dired-compression-method 'gzip)
  (define-key dired-mode-map "c"		'dired-do-copy)
  (define-key dired-mode-map "r"		'dired-do-rename)
  (define-key dired-mode-map "n"		'dired-copy-filename-as-kill)
  (define-key dired-mode-map "\M-s"		'symbolic-link)
  (define-key dired-mode-map [mouse-2]		'dired-mouse)
;   (define-key dired-mode-map [down-mouse-3]	nil)
;   (define-key dired-mode-map [pause]		'dired-do-delete)
;   (define-key dired-mode-map [up]		'dired-previous-line) ;move to filename
;   (define-key dired-mode-map [down]		'dired-next-line)
  (fset 'dired-mark-read-file-name 'my-dired-mark-read-file-name)
))

(defun abbreviate-buffer-directory-name ()
  "Abbreviate the current buffer's true directory name."
  (setq default-directory
	(file-name-directory
	 (abbreviate-file-name (file-truename default-directory)))))

(eval-after-load "dired-aux"
  '(fset 'dired-run-shell-command 'compile))

(defun dired-mouse (event)
  "Visit a file clicked on in a Dired buffer.
If there is a filename on the current line, visit the file else
re-read the directory."
  (interactive "e")
  (let ((opoint (point)))
    (mouse-set-point event)
    (cond ((dired-move-to-filename)
	   (sit-for 0)
	   (dired-find-file))
	  (t (dired-revert)
	     (goto-char opoint)))))

;; A version of dired-mark-read-file-name that inserts the name of
;; the single current file as the intial minibuffer contents.

(defun my-dired-mark-read-file-name (prompt dir op-symbol arg files)
  (dired-mark-pop-up
   nil op-symbol files
   (function read-file-name)
   ;; Args for read-file-name:
   (format prompt (dired-mark-prompt arg files))
   dir nil nil				  ; completion dir, no default, needn't match
   (and (null (cdr files)) (car files)))) ; initial contents if single file

(defun dired-copy-filename-as-kill ()
  (interactive)
  (let ((filename (dired-get-filename)))
    (message filename)
    (kill-new filename)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; RMAIL - reading mail

(setq user-mail-address "dbh@doc.ic.ac.uk")
(setq mail-directory "~/mail/")			; My variable.

(setq rmail-file-name (concat mail-directory ".mail"))
(defvar rmail-default-rmail-file (concat mail-directory "pending"))
(setq rmail-ignored-headers (mapconcat (function identity) '(
  "message"
  "received"
  "envelope"
  "mime"
  "precedence"
  "resent"
  "return-path"
  "summary"
  "via:"
  ) "\\|"))
(setq rmail-delete-after-output t)
(setq my-mail-spool-file (concat "/usr/spool/mail/" (user-login-name)))
(setq my-other-mail-spool-file "~/.email")
(setq mail-archive-file-name (concat mail-directory ".sent")) ; before..
(setq my-inboxes (list my-mail-spool-file
		       my-other-mail-spool-file
		       mail-archive-file-name))
(setq rmail-primary-inbox-list my-inboxes)
(defvar rmail-default-file)			; Not done elsewhere?

(autoload 'rmail-set-label "rmailkwd" "Autoload rmail" t)

(add-hook 'rmail-mode-hook (function (lambda ()	; rmail-mode startup
  ; (define-key rmail-mode-map [mouse-2] 'browse-url-at-mouse)
  (define-key rmail-mode-map "\C-o" 'my-rmail-output)
  (define-key rmail-mode-map "|"    'rmail-pipe)
  ;; (define-key rmail-mode-map "g"    'my-rmail)
  (define-key rmail-mode-map "i"    'my-rmail-input)
  (define-key rmail-mode-map "k"    'my-rmail-kill-label)
  (define-key rmail-mode-map "r"    'my-rmail-reply)
  (fset 'mail-strip-quoted-names 'identity)
  ; rmail-primary-inbox-list gets reset by defconst in rmail.el
  (setq rmail-primary-inbox-list my-inboxes)
  (setq compile-command "mailanal.pl"))))

(defun my-rmail-input () "Run RMAIL on a file"
  (interactive)
  (setq rmail-default-rmail-file
	(read-file-name (concat "Run rmail on RMAIL file ("
				rmail-default-rmail-file "): ")
			mail-directory rmail-default-rmail-file t))
  (rmail rmail-default-rmail-file))

(add-hook 'rmail-summary-mode-hook (function (lambda ()
  (define-key rmail-summary-mode-map "\C-m" 'rmail-summary-goto-msg)
  (define-key rmail-summary-mode-map [mouse-2] 'rmail-summary-mouse)
  (define-key rmail-summary-mode-map "q" 'rmail-summary-wipe)
  )))

(setq rmail-summary-window-size (- (frame-height) 5))

(defun rmail-summary-mouse (event arg)
  "Go to the message under the pointer."
  (interactive "@e\nP")
  (mouse-set-point event)
  (rmail-summary-goto-msg)
  (rmail-summary-wipe))

;; From rmailkwd.el:

(defun rmail-parse-message-labels (&optional n)
  "Returns labels associated with NTH or current RMAIL message.
The result is a list of two lists of strings.  The first is the
message attributes and the second is the message keywords."
  (let (atts keys)
    (save-restriction
      (widen)
      (goto-char (rmail-msgbeg (or n rmail-current-message)))
      (forward-line 1)
      (or (looking-at "[01],") (error "Malformed label line"))
      (forward-char 2)
      (while (looking-at "[ \t]*\\([^ \t\n,]+\\),")
	(setq atts (cons (buffer-substring (match-beginning 1) (match-end 1))
			  atts))
	(goto-char (match-end 0)))
      (or (looking-at ",") (error "Malformed label line"))
      (forward-char 1)
      (while (looking-at "[ \t]*\\([^ \t\n,]+\\),")
	(setq keys (cons (buffer-substring (match-beginning 1) (match-end 1))
			 keys))
	(goto-char (match-end 0)))
      (or (looking-at "[ \t]*$") (error "Malformed label line"))
      (list (nreverse atts) (nreverse keys)))))

(defun my-rmail-kill-label ()
  "Remove LABEL from labels associated with current RMAIL message.
Completion is performed over known labels when reading.
If there is only one label, just kill that one."
  (interactive)
  (let ((labels (apply 'append (rmail-parse-message-labels))))
    (if (= 1 (length labels))
	(rmail-set-label (car labels) nil)
      (call-interactively 'rmail-kill-label))))

(defun rmail-pipe (command)
  "Feed the current message to COMMAND as standard input.  Display the
output in another buffer."
  (interactive "sPipe message to command: ")
  (shell-command-on-region (point-min) (point-max) command))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; RMAIL - sending mail

(setq mail-yank-prefix "> ")

;; Loading sendmail binds ^Xm.  Rebind it to what we want.
;; (eval-after-load "sendmail"
;;   '(progn
;;      (global-set-key "\C-xm" 'my-rmail)
;;      (define-key mail-mode-map "\t" nil)))

(defun my-rmail (&optional send)
  "Read or edit mail.
If called with no argument moves messages into rmail-file-name (a
babyl format file) and edits that file in RMAIL Mode.  Type
\\[describe-mode] once editing that file, for a list of RMAIL
commands.

If called with an argument, select a buffer to send mail."
  (interactive "P")
  (if send
      (rmail-mail)
    (let ((old-messages (value rmail-total-messages)))
      ;; Nil if not in rmail buf
      (rmail))))

(defun rmail-quit-unless-new-messages ()
  (and (eq rmail-total-messages old-messages)
       (not (buffer-modified-p))
	   (rmail-quit)))

(defun my-rmail-reply ()
  "Edit a reply to the current message."
  (interactive)
  (goto-char (point-min))
  ;; Go to line after blank after headers but only if pruned
  (and (rmail-msg-is-pruned) (re-search-forward "\n\n"))
  (let ((message-text (buffer-substring-no-properties
		       (point)
		       (progn (goto-char (point-max))
			      (+ (re-search-backward "\\S-") 2)))))
    (rmail-reply nil)			; Always include CCs
    ; (not (and (re-search-forward "^C[Cc]: ." nil t)
    ; (y-or-n-p "Reply to Cc: recipients? "))))
    (let ((before (point)))
      (insert message-text)
      (goto-char before)))
  (while (not (eobp))
    (insert mail-yank-prefix)
    (forward-line 1))
  (re-search-backward "^FCC")
  (delete-other-windows))

(setq mail-setup-hook (function (lambda ()
  (setq mail-send-actions (cons '(mail-rename-sent-buffer)
				mail-send-actions)))))

(defun mail-rename-sent-buffer ()
  "Rename the current buffer \"*sent*\"."
  (rename-buffer (generate-new-buffer-name "*sent*")))

(defun file-size (file)
  "The number of bytes in FILE.  Returns -1 if file does not exist."
  (if (file-exists-p file)
      (nth 7 (file-attributes (file-chase-links file)))
    -1))

(defun not-empty (file)
  "Returns t if FILE exists and has size > 0."
  (> (file-size file) 0))

(defun my-rmail-output (file-name &optional overwrite)
  "Append this message to Unix mail file named FILE-NAME or, with
optional second argument (prefix if interactive) non-nil, overwrite
the file if it exists."
  (interactive
   (list
    (read-file-name
     (concat (if current-prefix-arg "Overwrite" "Append")
	     " message to Unix mail file"
	     (if rmail-default-file
		 (concat " (default "
			 (file-name-nondirectory rmail-default-file)
			 "): " ) ": "))
     (and rmail-default-file (file-name-directory rmail-default-file))
     rmail-default-file)
    current-prefix-arg))
  (and
   (or (not overwrite)
       (not (not-empty file-name))
       (prog1 (y-or-n-p (concat "Overwrite " file-name "? "))
	 (delete-file file-name)))
   (rmail-output file-name)))

;; See rmail-boxes at top of file

(setq rmail-output-file-alist
      (let ((pbs rmail-boxes) res)
	(while pbs
	  (setq res (append res (list (cons (car pbs)
					    (concat mail-directory (car (cdr pbs))))))
		pbs (cdr (cdr pbs))))
	res))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; compile

; (autoload 'compile "compile" "Autoload compile" t)
(autoload 'compile-run-shell-command "compile" "Autoload compile" t)

;; This is used by compile.  It seems that, contrary to the man page,
;; csh *does* pass SIGHUP on to child processes which means that
;; background processes started with compile exit when the compile
;; buffer is killed.  tcsh works though, set it here in case I change
;; my login shell (which is the default for s-f-n).

(setq shell-file-name
      (cond ((file-exists-p "/usr/local/bin/tcsh") "/usr/local/bin/tcsh")
	    (t "/bin/tcsh")))

;; Error message formats:
;; Glasgow Haskell parser
;; "prog.hs", line 2, column 11: parse error on input: "then"
;; Glasgow Haskell compiler
;; "prog.hs", line 2: undefined value: vx
;; Both handled by rule "apollo".

(setq compile-context-lines 0)

(setq grep-files-alist '(
  ("/compiler/$" . "*/*.lhs")
  ("/lisp/" . "*.el")))

;; How next-error finds files
(setq compile-use-tags-table nil)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Shell, rlogin

(setq explicit-shell-file-name "/bin/csh")	; Not default login shell
(setq shell-prompt-pattern "[^ ]* *")		; Prompt terminated by space
(autoload 'shell-mode "shell")			; For su

(setq rlogin-initially-track-cwd 'local)	; Don't use EFS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Comint

(defun comint-setup ()
  "Set up the keymap for comint modes."
  (define-key comint-mode-map [f21]  'comint-kill-input)
  (define-key comint-mode-map [f24]  'comint-bol)
  (define-key comint-mode-map [up] 'comint-previous-matching-input-from-input)
  (define-key comint-mode-map [down] 'comint-next-matching-input-from-input))

;; It seems the new v19 fashion is to set foo-mode-map when foo.el is
;; loaded.  For most modes you can customise the map either in
;; foo-mode-hook, which will repeat the customisation redundantly for
;; each new buffer, or using eval-after-load which will do it once, at
;; load time.  shell-mode copies comint-mode-map before comint-mode-hook
;; gets called so for customisation of comint-mode-map to affect
;; shell-mode-map it must be done with eval-after-load.  I don't think
;; this would work if comint were dumped.

(eval-after-load "comint" '(comint-setup))

(add-hook 'comint-exec-hook (function (lambda ()
  (let ((proc (get-buffer-process (current-buffer))))
    (and proc (process-kill-without-query proc)))
  (setq comint-scroll-show-maximum-output nil))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; EFS / ange-ftp

;; efs-auto seems to drag in shell somehow so this needs to be after
;; the comint customisation.

;; (require 'efs-auto)

;; Defaults to current user name
(setq ange-ftp-default-user "ftp")

;; (setq efs-default-password "dbh@doc.ic.ac.uk")
;; Some hosts don't grok ls "-al /."  Call 'em dumb.
;; (eval-after-load "efs" '(efs-add-host 'dumb-unix "ftp.demon.co.uk"))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Display time and mail notification

(defun display-time-in-icon ()
  "Display the time and presence of new mail as the icon name."
  (let ((s (current-time-string)))
    (frame-title (concat (substring s 11 16)
			 " " (substring s 0 4)
			 (substring s 8 10)
			 (and (new-mail-p) " MAIL"))
		 default-minibuffer-frame))
  (setq display-time-string ""))

(defun new-mail-p ()
  "Return non-nil if there is new mail in my-mail-spool-file."
  (not-empty my-mail-spool-file))

(defun new-mail ()
  "If (new-mail-p) returns non-nil then run RMAIL."
  (and (new-mail-p)
       (zerop (minibuffer-depth))
       (not (string-equal (buffer-file-name)
			  (expand-file-name rmail-file-name)))
       (let ((win (selected-window)))
	 (and (one-window-p) (split-window-vertically))
	 (other-window 1)
	 (rmail)
	 (select-window win))))

;; (if (zerop (user-real-uid))
;;     (frame-title "Root Emacs")
;;   (add-hook 'display-time-hook 'display-time-in-icon)
;;   (if (value mail-server-down)
;;       (add-hook 'auto-save-hook 'display-time-in-icon)
;;     (display-time)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Time and Date

(defconst iso-8601-date-format "%Y-%m-%d"
  "Date format specified by ISO 8601: YYYY-MM-DD.")

(defconst iso-8601-date-time-format (concat iso-8601-date-format " %H:%M:%S")
  "Date-time format specified by ISO 8601: YYYY-MM-DD HH:MM:SS.")

(defconst iso-8601-date-re (concat
  "[0-9]\\{2,4\\}[-./][0-9][0-9][-./][0-9][0-9]"
  "\\( [0-9]\\{1,2\\}\\(:[0-9][0-9]\\)\\{1,2\\}\\)?")
  "Regular expression to match a data in something resembling ISO 8601
YYYY-MM-DD format, e.g. 1960-10-15, optionally followed by a space
and a time like [H]H:MM[:SS].  No attempt is made to validate the
number values.")

; (string-match iso-8601-date-re "1960-10-15") ; = 0
; (string-match iso-8601-date-re "1960-10-15 00:47") ; = 0
; (string-match iso-8601-date-re "1960-10-15 9:99") ; = 0
; (string-match iso-8601-date-re "1960-10-15 00:47:33") ; = 0

(defvar date-time-format iso-8601-date-time-format
  "Date-time format used by `insert-time'.")

(defvar date-format iso-8601-date-format
  "Date format used by `insert-date'.")

(autoload 'thing-at-point-looking-at "thingatpt")

(defun insert-date (&optional arg)
  "Insert today's date or, with an argument, the current date-time, in
  the current buffer.  Formats are specified by the `date-format' and
  'date-time-format' variables."
  (interactive "P")
  (if (thing-at-point-looking-at iso-8601-date-re)
      (delete-region (match-beginning 0) (match-end 0)))
  (insert (format-time-string date-format)))

(global-set-key "\C-Xd" 'insert-date)

;; time-stamp.el

(add-hook 'write-file-hooks 'time-stamp)
(setq time-stamp-start "Last updated: ")
(setq time-stamp-end "$")
(setq time-stamp-line-limit 0)		; Search whole buffer

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Abbreviation

(defun my-expand-abbrev ()
"Expand or define an abbreviation.
If the word before point is not a known abbreviation, prompt for an
expansion and save it.  Expand the new or old abbreviation.  Loads the
abbrev file if not already loaded."
  (interactive)
  ;; save-abbrevs is set by read-abbrev-file
  (or save-abbrevs (read-abbrev-file ""))
  (or (expand-abbrev)
      ;; unknown
      (progn
	(inverse-add-global-abbrev 1)
	(forward-word 1)			; bug in inverse-add-abbrev?
	(write-abbrev-file "")
	(setq abbrevs-changed nil))))

(global-set-key "\C-x'" 'my-expand-abbrev)
(global-set-key "\ea" 'my-expand-abbrev)
(global-set-key "\C-xae" 'edit-abbrevs)

(defun my-edit-abbrevs-redefine ()
 "Redefine abbreviations from the current buffer then save them to the file"
 (interactive)
 (edit-abbrevs-redefine)
 (write-abbrev-file "")
 (setq abbrevs-changed nil))

(define-key edit-abbrevs-map "\C-c\C-c"	'my-edit-abbrevs-redefine)
(define-key edit-abbrevs-map "\C-x\C-s"	'my-edit-abbrevs-redefine)

(defun expand-user-name ()
  "Look up the word before point using \"finger -l WORD@finger\" and
replace it with the person's email address.  Define it as an
abbreviation for future reference."
  (interactive)
  (let* ((word (my-word-at-point))
	 buf user full)
    (message (format "Fingering %s ..." word))
    (save-window-excursion
      (unwind-protect (shell-command (concat "finger -l " word "@finger"))
	(message "Done")
	(setq buf (get-buffer "*Shell Command Output*"))
	(if (null buf) (signal 'search-failed))
	(set-buffer buf)
	(goto-char (point-min))
	(setq full (buffer-substring
		    (re-search-forward "^In real life: *")
		    (progn (re-search-forward " *$") (match-beginning 0)))
	      user (buffer-substring
		    (re-search-forward "^Login: *")
		    (progn (re-search-forward " *$") (match-beginning 0))))))
    ;; Ensure abbrevs are loaded otherwise they get overwritten.
    (or save-abbrevs (read-abbrev-file ""))
    (define-abbrev global-abbrev-table word
      (concat full " <" user "@" gnus-local-domain ">"))
    (write-abbrev-file "")
    (setq abbrevs-changed nil)
    (if buffer-read-only
	(if buf (switch-to-buffer buf))
      (expand-abbrev))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Ispell

(autoload 'ispell-word "ispell"
	  "Check spelling of word at or before point" t)
(autoload 'ispell-complete-word "ispell"
	  "Complete word at or before point" t)
(autoload 'ispell-region "ispell"
	  "Check spelling of every word in the region" t)
(autoload 'ispell-buffer "ispell"
	  "Check spelling of every word in the buffer" t)

(setq ispell-silently-savep t)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Info

;; Info is not designed to be invoked like a normal major mode.
;; This function can run Info on a file outside the info tree.

(defun info-file-mode ()
  "Run Info on the file in the current buffer."
  (let ((oib (get-buffer "*info*")))
    (if oib (save-excursion
	      (set-buffer oib)
	      (rename-buffer "*info 2*" t))))	; Rename any old info buf uniquely.
  (rename-buffer "*info*")			; Make this THE info buffer.
  (Info-find-node (buffer-file-name) "top"))

(autoload 'Info-find-node "info")

(defun info-setup ()
  "Called after Info is loaded."
  (define-key Info-mode-map [mouse-2] 'Info-mouse-follow-nearest-node))

;; (eval-after-load "info" '(info-setup))

;; makeinfo puts Text mode string in info nodes so check for .info file
;; in text mode and switch to info mode.

;; (add-hook 'text-mode-hook (function (lambda ()
;;   (if (string-match "\.info$" (or (buffer-file-name) ""))
;;       (info-mode)))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; PS mode

(autoload 'ps-mode "ps-mode" "Autoload ps mode" t nil)
(add-hook 'ps-mode-hook 'ps-mode-setup)
(defalias 'ps 'ps-mode)				; Avoid print-spool
(defun ps-mode-setup ()
  (setq truncate-lines nil)
  (local-set-key "g" 'ps-mode-build-process-list)
  (local-set-key "f" 'ps-mode-set-args)
  (local-set-key [mouse-2] 'ps-mode-build-process-list))

(defvar ps-mode-program-args "waxwu"
  "Arguments passed to ps-mode-program")

(defun ps-mode-set-args (args)
  "Set ps-mode-program-args, the flags passed to ps-mode-program.
This is a string that may contain one of the following to control
which fields are displayed:
    l	Long	    	F, PPID, CP, PRI, NI, SZ, RSS, WCHAN.
    j	Job	    	PPID, PID, PGID, SID, TT, TPGID,
			STAT, UID, TIME, CMD.
    u	User	    	USER, %CPU, %MEM, SZ, RSS, START
    v	Virtual memory	RE, SL, PAGEIN, SIZE, RSS, LIM, %CPU, %MEM
The following control which processes are listed:
    a	Include processes owned by anyone
    g	Include process group leaders
    r   Only running processes
    x   Include processes with no controlling terminal
For other flags see the ps(1) manual page."
  (interactive (list (read-from-minibuffer "Args for ps: "
				     ps-mode-program-args)))
  (setq ps-mode-program-args args)
  (ps-mode-build-process-list))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; HTML

(autoload 'html-helper-mode "html-helper-mode" "Edit HTML docs" t)
(setq html-helper-do-write-file-hooks t)
(setq html-helper-build-new-buffer t)
(setq html-helper-use-expert-menu t)
(setq tempo-interactive t)
; Tags are hard-coded into h-h-m - h-h-t-tags list is irrelevant

;; (defun html-helper-default-insert-timestamp ()
;;   "Default timestamp insertion function."
;;   (let ((time (current-time-string)))
;;     (insert "Last updated: "
;; 	    (format-time-string date-time-format)
;; 	    "\n")))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Unix command interfaces

(setq terminal-type (or (getenv "TERM") "unknown"))

(defun root-user-p
  "Return true if the current user is the superuser, root, with user
  id zero."
  (zerop (user-real-uid)))

(defvar man-page-history nil
  "History list of previously requested manual pages.")

(defun my-manual-entry (topic)
  "Display Unix manual entry for TOPIC.
Completes from man-page-list."
  (interactive
   (progn
     ;; Load the list of all pages, if it exists.
     (condition-case nil
	 (require 'man-page-list)
       (error (setq man-page-list nil)))
     (require 'man)
     (Man-init-defvars)
     (let* ((default-entry (Man-default-man-entry))
	    (topic
	     (completing-read
	      (concat "Manual-entry: "
		      (and (not (string= default-entry ""))
			   (format "(default: %s) " default-entry)))
	      man-page-list nil nil nil 'man-page-history)))
       (and (string= topic "")
	    (if (string= default-entry "")
		(error "No man args given")
	      (setq topic default-entry)))
       ;; Recognise the subject(section) syntax.
       (setq topic (Man-translate-references topic))
       (list topic))))
  (Man-getpage-in-background topic))

(global-set-key [?\C-x return] 'my-manual-entry)
(global-set-key "\C-x\C-m" 'my-manual-entry)
(eval-after-load "man"
  '(define-key Man-mode-map [mouse-2] 'Man-follow-manual-reference))

;; (setq Man-notify-flag 'aggressive) ; bully puts page in only window

(defun ping (host)
  "Ping the hostname at or before point."
  (interactive
   (let ((command (if current-prefix-arg "traceroute" "ping")))
     (list (read-string "Ping command: "
			(concat command " " (hostname-at-point))))))
  (or (interactive-p) (setq host  (concat "ping " host)))
  (compile host))

;; (ping "eagle.ukc.ac.uk")

(global-set-key "\C-cp"	'ping)

(defun finger (name)
  "Finger the NAME at or before point.
If no host is specified in NAME, append \"@finger\"."
  (interactive (list (read-string "finger: " (my-word-at-point "-.@"))))
  (or (string-match "@" name)
      (setq name (concat name "@finger")))
  (message "%s" (concat "fingering " name " ..."))
  (compile (concat "finger -l " name))
  (message ""))

(global-set-key "\C-cf" 'finger)

(defun crontab ()
  "Edit a crontab file.  Type \\[save-buffer] to feed the buffer to the
crontab command."
  (interactive)
  (switch-to-buffer "*Crontab*")
  (setq mode-name "Crontab")
  (erase-buffer)
  (use-local-map (current-local-map))	; make a copy?
  (local-set-key "\C-x\C-s" 'crontab-update)
  (local-set-key "\C-c\C-c" 'crontab-update)
  (message "Reading crontab file ... ")(sit-for 0) ; redisplay
  (if (eq (call-process-region (point) (point) "crontab" nil t t "-l") 0)
      (message "Reading crontab file ... done")
    (message "No crontab file")
    (erase-buffer)
    (insert "#min hour dom mon dow (0=Sun) cmd\n"))
  (set-buffer-modified-p nil))

(defun crontab-update ()
  "Feed the current buffer to the crontab command to update the crontab file."
  (interactive)
  (message "Updating crontab file ... ")(sit-for 0) ; redisplay
  (shell-command-on-region (point-min) (point-max) "crontab -" nil)
  (message "Updating crontab file ... done")
  (set-buffer-modified-p nil))

(eval-after-load "tar-mode" '(progn
  (define-key tar-mode-map [return] 'tar-extract)
  (define-key tar-mode-map [mouse-2] 'tar-mouse)))

(defun tar-mouse (event)
  (interactive "e")
  (mouse-set-point event)
  (tar-extract))

;; print-buffer normally pipes through pr, lpr-buffer doesn't.

(defalias 'print-buffer 'lpr-buffer)

(defun su ()
  "Start a super-user shell within Emacs."
  (interactive)
  (comint-run "su")
  (setq comint-output-filter-functions
	'(comint-postoutput-scroll-to-bottom
	  comint-watch-for-password-prompt))
  (rename-buffer "*root*")
  (shell-mode))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Files

(setq make-backup-files nil)
(setq view-read-only t)
(global-set-key "\M-," 'find-tag-again)

(setq find-file-visit-truename t)
; (setq directory-abbrev-alist '(("^/a/wombat/home/" . "/home/")))

(defun buffer-file-or-directory-name (&optional buf)
  "Return the file or directory name associated with BUFFER.
If the buffer (default current) contains a file, return the filename.
If it is a Dired buffer return the directory name from the local
variable ``dired-directory'' else return an empty string."
  (or (buffer-file-name buf)
      (save-excursion (and buf (set-buffer buf)) default-directory)
      ""))

(defun find-file-at-point (file)
  "Find the file named around or before point.
A file name is assumed to consist of alphanumerics and [.-/:@_~].

With a prefix argument, look for a hostname using hostname-at-point.
Add '/' before and ':' after to form an efs remote file name for that
host's top directory.

The file name is read from the minibuffer, using the string found
above as initial input.  If called non-interactively, FILE is passed
as an argument, just like find-file."
  (interactive
   (let ((file (if current-prefix-arg (concat "/" (hostname-at-point) ":")
		 (my-word-at-point "-./:@_~"))))
     (setq file (abbreviate-file-name file))
     (list (read-file-name "Find file: " file file))))
  (find-file file))

(defun find-file-read (file)
  "Prompt for the name of a file to load with FILE as the initial
minibuffer contents."
  (find-file-other-window (read-file-name "Find file: " file file)))

(defun dot-emacs ()
  (interactive)
  (let* ((file (expand-file-name "~/.emacs"))
	(src (concat file ".el"))
	(out (concat src "c")))
    (find-file src)
    (delete-other-windows)
    (save-buffer)
    (sit-for 0)
    (eval-current-buffer)
    (byte-compile-file src)
    (rename-file out file t)
    (message (concat out " renamed " file))))

(defun grep-all (&optional arg)
  "List occurrences of the current selection in all files in or below
the current directory.  With a prefix arg, prompt for the string to
search for, defaulting to the first line of the selection."
  (interactive "P")
  (let* ((start (region-beginning))
	 (end (region-end)))
    (if arg (setq end (min (progn (goto-char start) (end-of-line) (point))
			   end)))
    (let ((pat (buffer-substring start end)))
      (if arg (setq pat (read-string "Search files for: " pat)))
      (compile (concat "grep-all " pat)))))

(defun symbolic-link (file &optional name)
  "Make a symbolic link to FILE called NAME.
The link will either be created in the current directory with the same
basename as FILE (which may be a directory) or as specified by the
optional second argument NAME.  The link will either point to an
absolute or relative path, whichever is shorter.

Variable `dired-dwim-target' is used in deciding a default value for
NAME."
  (interactive
   (progn
     (setq file (buffer-file-or-directory-name)
	   leaf (file-name-nondirectory file)
	   file (read-file-name "Old file: " default-directory file nil leaf))
     (let* ((dir default-directory)
	    (dwim (if (fboundp 'dired-dwim-target-directory)
		     (dired-dwim-target-directory) dir)))
       (if (string-equal (file-leaf-name dwim) (file-leaf-name dir))
	   (setq leaf "")
	 (setq dir dwim
	       leaf (file-leaf-name file)))
       (setq name (read-file-name "Link name: " dir leaf nil leaf))
       (list file (if (file-name-absolute-p name) name (concat dir name))))))
  ;; Append file leaf to dir
  (and (not (file-directory-p file))
       (file-directory-p name)
       (setq name (concat (file-name-as-directory name)
			  (file-leaf-name file))))
  (let ((absolute (expand-file-name file))
	(relative (file-relative-name file (file-name-directory name))))
    (setq file (if (< (length relative) (length absolute))
		   relative absolute)))
  (or name (setq name (file-leaf-name file)))
  (message "Linking %s -> %s" name file) ;; (sit-for 2)
  (make-symbolic-link file name))

(defun file-leaf-name (path)
  "Return the last component of PATH.
PATH may be the name of a file or directory.  Return the last string
of non-/s before any trailing /s or just \"/\" if there are none.

This is like file-name-nondirectory unless PATH ends in \"/\"."
  (if (zerop (string-match "\\([^/]*\\)/*$" path))
      "/"
    (substring path (match-beginning 1) (match-end 1))))

(defvar backup-suffix "-gla"
  "The string apended to a filename by the backup command.")

(defun backup-file (file)
  "Create a copy of FILE with `backup-suffix' appended to its name.
Ensure that FILE has write permission."
  (interactive "fFile to backup: ")
  (copy-file file (concat file backup-suffix) nil t)
  (set-file-modes file (logior (file-modes file) 128)))

(defun dired-backup ()
  "Backup the current file using backup-file."
  (interactive)
  (backup-file (my-dired-mark-read-file-name
		"File to backup: " default-directory nil nil
		(list (file-name-nondirectory (dired-get-filename))))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Buffers & windows

(defun kill-empty-buffer (buffer)
  "Kill BUFFER if it exists and is empty."
  (let ((buf (get-buffer buffer)))
    (cond (buf (set-buffer buf)
	       (goto-char (point-max))
	       (and (bobp) (kill-buffer-window buf))))))

(defun switch-to-previous-buffer ()
  "Select the previous buffer in the current window."
  (interactive)
  (let ((buf (next-buffer)))
    (and buf (switch-to-buffer buf))))

(defun another-window ()
  "Select the next window or split the current one."
  (interactive)
  (cond ((one-window-p)
	 (split-window-vertically)
	 (other-window 1)
	 (switch-to-buffer nil))
	(t (other-window 1))))

(defun kill-current-buffer ()
  "Kill the current buffer.
If invoked from a mouse click, kill the buffer clicked on."
  (interactive "@")
  (kill-buffer nil))

(defun kill-buffer-window (&optional buffer)
  "Kill BUFFER & its window (default current buffer) if it exists and is
not the only buffer."
  (interactive "@")
  (let ((target (if buffer (get-buffer buffer)
		  (and (next-buffer) (current-buffer)))))
    (and target
	 (kill-buffer target)
	 ;; Sometimes get errors about window not live
 	 (window-live-p (selected-window))
	 (not (one-window-p))
	 (delete-window))))

(defun next-buffer ()
  "Return another interesting buffer else nil.  Uninteresting buffers
  are dead, current or temporary ones."
  (let ((bufs (buffer-list)) buf)
    (while
	(and bufs
	     (setq buf (car bufs))
	     ;; (or (ok (buffer-name buf)) 1) ;??
	     (or (eq buf (current-buffer))
		 (equal (string-to-char (buffer-name buf)) ? )
		 (equal (buffer-name buf) "Buffers")))
      (setq bufs (cdr bufs)))
    (if bufs (car bufs)
      (message "No other buffer")
      nil)))

(defun my-bury-buffer (&optional buf)
  "Put BUFFER at the end of the list of all buffers.
There it is the least likely candidate for `other-buffer' to return;
thus, the least likely buffer for \\[switch-to-buffer] to select by
default.  If BUFFER is nil or omitted, bury the current buffer.  Also,
if BUFFER is nil or omitted, remove the current buffer from the
selected window if it is displayed there.  If invoked from a mouse
click, bury the buffer clicked on.  If there is no other buffer, do
nothing."
  (interactive "@")
  (and (next-buffer)
       (bury-buffer buf)))

;; The minibuffer often uses the global map so we need to be able to
;; tell when we're reading from the minibuf in order to make keys do
;; different things there.

(defun in-minibuffer-p ()
  (eq (window-buffer) (window-buffer (minibuffer-window))))

(defun my-revert-buffer ()
  "Replace the buffer text with the text of the visited file on disk.
Offer to revert from latest auto-save file, if that is more recent
than the visited file.  Don't ask for confirmation."
  (interactive)
  (revert-buffer nil t))

(defun my-mouse-split-window-vertically (event)
  "Split the window vertically at the mouse position.
Select another buffer (if there is one) in the lower half."
  (interactive "e")
  (mouse-split-window-vertically event)
  (other-window 1)
  (switch-to-buffer (next-buffer)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Filling

(setq adaptive-fill-regexp nil)
(setq adaptive-fill-mode nil)

(defun guess-fill-prefix ()
  "Return a guess at this line's correct fill-prefix.  Does not set
fill-prefix variable."
  (save-excursion
    (beginning-of-line)
    (if (looking-at "[-	 >#]+")
	(buffer-substring (point) (match-end 0))
      "")))

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

(add-hook 'text-mode-hook (function (lambda ()
  (auto-fill-mode 1))))

;; center-line pre-loaded from text-mode.el barfs on long lines

(defun center-line ()
  "Center the line point is on, within the width specified by `fill-column'.
This means adjusting the indentation so that it equals
the distance between the end of the text and `fill-column'.
Leave the line left-justified if it's too long."
  (interactive)
  (save-excursion
    (let ((lm (current-left-margin))
	  line-length indent)
      (beginning-of-line)
      (delete-horizontal-space)
      (end-of-line)
      (delete-horizontal-space)
      (setq line-length (current-column)
	    indent (+ lm (/ (- fill-column lm line-length) 2)))
      (and (natnump indent) (indent-line-to indent)))))

(defun longest-line ()
  "Go to the first longest line in the buffer."
  (interactive)
  (beginning-of-buffer)
  (let ((longest-length -1)
	longest-end start-of-line length)
    (while (not (eobp))
      (setq start-of-line (point))
      (end-of-line)
      (setq length (- (point) start-of-line))
      (if (<= length longest-length) nil
	(setq longest-end (point)
	      longest-length length)
	(message "%d" length)
	(sit-for 1))
      (forward-char))
    (goto-char longest-end)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Lisp Code Directory

(autoload 'lisp-dir-apropos "lispdir" "Autoload LCD apropos" t nil)
(setq elisp-archive-directory "/vol/ukuug/gnu/EmacsBits/elisp-archive/")
(setq lisp-code-directory
      "/vol/ukuug/gnu/EmacsBits/elisp-archive/LCD-datafile.Z")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; General editing

(defun my-beginning-of-buffer (&optional arg)
  "Move point to the beginning of the buffer.
Leave mark at previous position if we moved."
  (interactive "P")
  (unless (equal (point) (point-min))		; No change - preserve mark.
    (push-mark (point) nil)			; Don't activate mark.
    (goto-char (point-min))))

(defun delay (n)
  "Pause for a time proportional to ARG.
ARG = 5000 gives about one second."
  (while (and (> n 0) (not (input-pending-p))) (setq n (- n 1))))

(defun copy-line-as-kill ()
  "Save the line the point is on as if killed but don't kill it.  Also
  move point to start of line.  The killed line will always end with a
  newline.  Subsequent consecutive invocations yank the copied line."
  (interactive)
  (if (equal last-command 'copy-line-as-kill)
      (yank)
    (end-of-line)
    (copy-region-as-kill (point) (progn (beginning-of-line)(point)))
    (kill-append "\n" nil))			; In case at end of buf
  (setq this-command 'copy-line-as-kill))

(defun beginning-of-line-or-next ()
  "Move point to start of current line.  If already there, move
down one line."
  (interactive)
  (if (bolp) (next-line 1))
  (beginning-of-line))			; In case at end of buf

(defun my-end-of-buffer (&optional arg)
  "Move point to the end of the buffer.
Leave mark at previous position if we moved."
  (interactive "P")
  (if (equal (point) (point-max)) nil		; No change - preserve mark.
    (push-mark (point) nil)			; Don't activate mark.
    (goto-char (point-max))))

(defun end-of-line-or-next ()
  "Move point to end of current line.  If already at end of line, move
down one line."
  (interactive)
  (if (eolp) (next-line 1))
  (end-of-line))

(defun isearch-from-top (nwords)
  "Start an incremental search for the N word(s) starting at point.
The search starts from the top of the buffer."
  (interactive "p")
  (isearch-mode t)
  (let ((string
	 (buffer-substring (point) (progn (forward-word nwords) (point)))))
    (goto-char (point-min))
    (setq isearch-string string
	  isearch-message (mapconcat 'isearch-text-char-description
				     isearch-string "")
	  isearch-yank-flag t)
    (isearch-search-and-update)))

(defun just-recenter ()
  "Scroll point to centre of window without redrawing."
  (interactive)
  (recenter '(4)))	; Equivalent to C-U C-L

(defun kill-whole-line (arg)
  "Kill the line the point is on including its newline"
  (interactive "*p")
  (beginning-of-line)
  (kill-line arg))

(defun point-to-top () "Scroll point to top of window"
  (interactive)
  (recenter 0))

(defun match-paren-or-insert (arg)
  "Go to the matching parenthesis if on parenthesis otherwise insert %."
  (interactive "p")
  (or (match-paren) (self-insert-command (or arg 1))))

(defun match-paren ()
  "Move to the parenthesis matching the one under the cursor."
  (cond ((looking-at "\\s\(") (forward-list 1) (backward-char 1) t)
	((looking-at "\\s\)") (forward-char 1) (backward-list 1) t)))

(defun same-place (event)
  "Return non-nil if EVENT ends at (point)."
  (= (point) (nth 1 (event-end event))))

(defun my-transpose-chars () "Transpose chars before point"
  (interactive)
  (backward-char 1)
  (transpose-chars 1))

(defun back-transpose-chars () "Transpose chars 2nd & 3rd back from point"
  (interactive)
  (backward-char 2)
  (transpose-chars 1)
  (forward-char 1))

(defun insert-or-scroll (arg)
  "Call self-insert-command if buffer is writable, else
  scroll-forward."
  (interactive "p")
  (if buffer-read-only (scroll-up ()) (self-insert-command arg)))

(defun delete-space (&optional n)
  "Delete all spaces, tabs and newlines around point.
Leave ARG spaces.  If no prefix argument is given, ARG defaults to 0,
not 1.  If the prefix argument is just \\[universal-argument], leave a
blank line."
  (interactive "*P")
  (skip-chars-backward " \t\n")
  (delete-region (point) (progn (skip-chars-forward " \t\n") (point)))
  (cond
   ((equal n '(4)) (insert "\n\n"))
   (n (insert-char ?  (prefix-numeric-value n)))))

;; TAB -> indent-for-tab-command -> either insert-tab
;;        or calls indent-line-function
;; RET -> newline
;; LF  -> newline-and-indent -> indent-according-to-mode
;;        -> indent-line-function

(defun indent-or-insert ()
  "Indent to the same column as the first non-white on the previous
nonblank line.  If already at or past that column then insert a tab.
This function is typically invoked via the indent-line-function
variable."
  (interactive "*")
  (let ((pos (current-column)))
    (indent-relative-maybe)
    (and (eq this-command 'indent-for-tab-command)
	 (>= pos (current-column))
	 (progn (indent-to pos) (insert-tab)))))

(defmacro save-syntax-excursion (&rest forms)
  "Evaluate FORMS then restore the original syntax table.
Only the buffer that is current on entry will have its syntax table
preserved.  Neither the current buffer, nor other syntax tables will
be restored on exit.  Return the same result as FORMS."
  (let ((old-buffer (current-buffer))
	(old-syntax (syntax-table))
	result)
    (set-syntax-table (copy-syntax-table old-syntax))
    (while forms
      (setq result (eval (car forms))
	    forms (cdr forms)))
    (save-excursion
      (set-buffer old-buffer)
      (set-syntax-table old-syntax))
    result))

;; forward-thing in thingatpt won't work searching for regexps if
;; we're in the middle of a match for a complex regexp.  This should
;; also work for multiple consecutive matches (return the closest).

(defun match-at-point (regexp)
  "Return the buffer substring around point matching REGEXP.
Look for a match starting at or before point.  Move back a character
at a time while still looking at a match ending at the same point.  If
no match is found at or before point, return the first match after
point, or nil if there is no match in the buffer."
  (let ((backup nil) (start nil) (end nil))
    (save-excursion
      (setq backup
	    (or (looking-at regexp)
		(and (re-search-forward regexp nil 'limit)
		     (setq end t)
		     (goto-char (match-beginning 0))
		     nil)
		;; failed search doesn't change match-data
		(re-search-backward regexp nil t)))
      (if (or backup end) (setq start (match-beginning 0)
				end (match-end 0)))
      (if backup
	  (while (and (not (bobp))
		      (progn (backward-char) t)
		      (looking-at regexp)
		      (= (match-end 0) end))
	    (setq start (point)))
	(or (bobp) (re-search-forward regexp nil t))))
    (and start
	 (progn (goto-char end) t)
	 (buffer-substring start end))))

;; (progn (re-search-forward "sdjkfhjdsk" nil t)(match-beginning 0))

;; aaaa
;; (match-at-point "a+")
;; (match-at-point "and")
;; (match-at-point "\\(.\\)\\(.\\)\\2\\1")

(defun number-at-point ()
  "Return the number at or before point as an integer."
  (let ((n (match-at-point "[0-9]+")))
    (if n (string-to-int n) (error "No number found"))))

(defun goto-line-at-point ()
  "Goto the line number at or before point in another buffer."
  (interactive)
  (let ((event (elt (this-command-keys) 0)))
    (and (listp event) (mouse-set-point event)))
  (let ((line (number-at-point)))
    (another-window)
    (message "Line %d" line)
    (goto-line line)))

(global-set-key "\C-xg" 'goto-line-at-point)

;; This could probably be done with thing-at-point from thingatpt.el.

(defun my-word-at-point (&optional chars)
  "Return the word the point is on or after.  If there is no word at or
before point, the empty string is returned.  Optional argument CHARS
is a string of characters to consider as part of a word in addition to
those in the syntax class 'w'."
  (let ((wordre "\\<\\w+"))
    (save-syntax-excursion
     (mapcar (function (lambda (char) (modify-syntax-entry char "w"))) chars)
     (looking-at "")				; Empty match data
     (save-excursion
       (or (looking-at wordre)
	   (and (not (bobp))
		(re-search-backward wordre nil t)
		(looking-at wordre))))))	; Extend match-end past point
  (buffer-substring (match-beginning 0) (match-end 0)))

(defun hostname-at-point ()
  "Return the Internet host name at or before point.
If called interactively, copy hostname to kill ring."
  (interactive)
  (let ((host (my-word-at-point ".-")))
    (and (equal (last host) ?.) (setq host (init-string host)))
    (and (interactive-p) (kill-new host))
    host))

(defun local-variable-template ()
  "Insert \"Local variables:\" in the current comment."
  (interactive)
  (let* ((before (buffer-substring (save-excursion (beginning-of-line) (point))
				   (point)))
	 (after (buffer-substring (point)
				  (save-excursion (end-of-line) (point)))))
    (insert "Local variables:")
    (end-of-line)
    (insert "\n" before "compile-command: \"")
    (save-excursion (insert "\"" after "\n" before "End:" after "\n"))))

(defun toggle-case-fold-search ()
  "Toggle the variable case-fold-search."
  (interactive)
  (set-variable 'case-fold-search (not case-fold-search))
  (message "case-fold-search set to %s" case-fold-search))

(defun previous-line-or-history (arg)
  "In the minibuffer, recall the ARG'th previous input, elsewhere move up
ARG lines."
  (interactive "p")
  (if (in-minibuffer-p)
      (previous-history-element arg)
    (setq this-command 'previous-line)		; Maintain goal-column
    (previous-line arg)))

(defun next-line-or-history (arg)
  "In the minibuffer, recall the ARG'th next input, elsewhere move down
ARG lines."
  (interactive "p")
  ; next-line signals end of buffer even with a -ve arg.
  (previous-line-or-history (- arg)))

(add-hook 'outline-mode-hook (function (lambda ()
  (define-key outline-mode-map [mouse-2] 'mouse-toggle-subtree))))

(add-hook 'outline-minor-mode-hook (function (lambda ()
  (define-key outline-minor-mode-map [mouse-2] 'mouse-toggle-subtree))))

(autoload 'animal "animal" "Play the animal game." t)

(defun least-factor (n)
  "Return the smallest factor of N apart from 1."
  (let ((factor 2))
    (while (and (< factor n) (> (mod n factor) 0))
      (setq factor (1+ factor)))
    factor))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Function key map

;; See also: ~/emacs/lisp/term/lk201.el
;; See also: ~/emacs/lisp/term/x-win.el

(cond ((string-match "vt10." terminal-type)
       ;; \e[7~ seems to be free and vt100 has no home defined
       (define-key function-key-map "\e[2~"  [home])
       (define-key function-key-map "\e[7~"  [home])
       ;; \e[8~ seems to be free and vt100 has no end defined
       (define-key function-key-map "\e[8~"  [end])
       ;; Rename kp-f1 - kp-f4 (PF1 - PF4) to
       ;; num-lock, kp-divide, kp-multiply, kp-subtract
       (define-key function-key-map "\eOP"  [num-lock])
       (define-key function-key-map "\eOQ"  [kp-divide])
       (define-key function-key-map "\eOR"  [kp-multiply])
       (define-key function-key-map "\eOS"  [kp-subtract]))
      ((string-match "xterm" terminal-type)
       (load-library "term/xterm")
       ;; These are generated by Putty:
       (define-key function-key-map "\e[1~" [home])
       (define-key function-key-map "\e[4~" [end])
       (define-key function-key-map "\eOP"  [num-lock])
       (define-key function-key-map "\eOQ"  [kp-divide])
       (define-key function-key-map "\eOR"  [kp-multiply])
       (define-key function-key-map "\eOS"  [kp-subtract])
       (define-key function-key-map "\eOw"  [kp-7])
       (define-key function-key-map "\eOx"  [kp-8])
       (define-key function-key-map "\eOy"  [kp-9])
       (define-key function-key-map "\eOl"  [kp-plus])
       (define-key function-key-map "\eOt"  [kp-4])
       (define-key function-key-map "\eOu"  [kp-5])
       (define-key function-key-map "\eOv"  [kp-6])
       (define-key function-key-map "\eOq"  [kp-1])
       (define-key function-key-map "\eOr"  [kp-2])
       (define-key function-key-map "\eOs"  [kp-3])
       (define-key function-key-map "\eOp"  [kp-0])
       (define-key function-key-map "\eOn"  [kp-decimal])))

;;; Global key bindings for vt100, vt102, terminal emulator, X

(setq key-translation-map nil)			; Don't remap f1 to C-H

(define-key minibuffer-local-isearch-map
			      "\C-f" 'isearch-forward-exit-minibuffer)
(define-key isearch-mode-map "\C-f" 'isearch-repeat-forward)

(global-set-key "\C-]"		'match-paren-or-insert)
(global-set-key "\C-c\C-k"	'kill-compilation)
(global-set-key "\C-ci"		'lisp-interaction-mode)
(global-set-key "\C-f"		'isearch-forward)
(global-set-key "\C-s"		'save-buffer)
(global-set-key "\C-t"		'my-transpose-chars)
(global-set-key "\C-v"		'yank)
(global-set-key "\C-z"		'undo)
(global-set-key " "		'insert-or-scroll)
(global-set-key "\e "		'delete-space)
(global-set-key "\e_"		'advertised-undo)
(global-set-key "\e$"		'ispell-word)
(global-set-key "\e<"		'my-beginning-of-buffer)
(global-set-key "\e="		'ispell-complete-word)
(global-set-key "\e>"		'my-end-of-buffer)
(global-set-key "\eg"		'fill-region)
(global-set-key "\ei"		'my-rmail-input)
(global-set-key "\eo"		'find-file-at-point)
(global-set-key "\ep"		'ps-mode)
(global-set-key "\eq"		'my-fill-paragraph)
(global-set-key "\er"		'query-replace-regexp)
(global-set-key "\et"		'back-transpose-chars)
(global-set-key "\C-x\C-k"	'kill-buffer-window)
(global-set-key "\C-x\C-r"	'my-revert-buffer)
(global-set-key "\C-xl"		'local-variable-template)
;; (global-set-key "\C-xm"		'my-rmail)
(global-set-key "\C-xs"		'isearch-from-top)

(global-set-key [S-return]	'newline)
(global-set-key [C-return]	'newline)
(global-set-key [C-tab]		'tab-to-tab-stop)

(global-set-key [num-lock]	'kill-whole-line)
(global-set-key [kp-f1]		'kill-whole-line)
(global-set-key [kp-divide]	'backward-kill-word)
(global-set-key [kp-f2]		'backward-kill-word)
(global-set-key [kp-multiply] 	'kill-word)
(global-set-key [kp-f3]		'kill-word)
(global-set-key [kp-hash]  	'kill-line)
(global-set-key [kp-7]     	'beginning-of-line-or-next)
(global-set-key [kp-8]		'backward-word)
(global-set-key [kp-9]		'forward-word)
(global-set-key [kp-subtract]	'kill-line)
(global-set-key [kp-5]		'just-recenter)
(global-set-key [kp-6]		'point-to-top)
(global-set-key [kp-plus]  	'end-of-line-or-next)
(global-set-key [kp-add]  	'end-of-line-or-next)
(global-set-key [kp-separator]	'end-of-line-or-next)
(global-set-key [kp-4]  	'kill-whole-line)
(global-set-key [kp-1]  	'end-of-buffer)
(global-set-key [kp-3]  	'repeat-complex-command)
(global-set-key [kp-0]  	'yank)
(global-set-key [kp-decimal]  	'imenu)

(global-set-key [f1]    'delete-other-windows)
(global-set-key [f2]   	'another-window)
(global-set-key [f3]   	'switch-to-previous-buffer)
(global-set-key [f4]   	'bury-buffer)
(global-set-key [f5]   	'goto-line)
(global-set-key [f6]   	'rmail)
(global-set-key [f7]   	'compile)
(global-set-key [f8]   	'undo)
(global-set-key [f9]   	'copy-line-as-kill)
(global-set-key [cancel] 'save-buffers-kill-emacs)	; Stop
(global-set-key [redo]  'repeat-complex-command)	; Again
(global-set-key [props] 'set-variable)			; Props
(global-set-key [undo]  'undo)				; Undo
;; Used for X						; Front
(global-set-key [copy]	'copy-line-as-kill)		; Copy
;; Used for X						; Open
(global-set-key [paste]	'yank)				; Paste
(global-set-key [find]	'grep)				; Find
(global-set-key [cut]	'kill-rectangle)		; Cut
(global-set-key [help]	'describe-key)
(global-set-key [pause]	'kill-whole-line)		; Pause
(global-set-key [print]	'backward-kill-word)		; PrSc
(global-set-key [break]	'kill-word)			; Scrl Lck/Brk
(global-set-key [f35]	'kill-line)			; Num Lock
(global-set-key [f24]	'beginning-of-line-or-next)	; =
(global-set-key [f25]	'backward-word)			; /
(global-set-key [f26]	'forward-word)			; *
(global-set-key [f33]	'end-of-line-or-next)		; -
(global-set-key [S-f33]	'end-of-line-or-next)		; -
(global-set-key [home]	'beginning-of-line-or-next)	; 7 Home
(global-set-key [C-home] 'my-beginning-of-buffer)
(global-set-key "\e\e[1~" 'my-beginning-of-buffer)
(global-set-key "\e\e[4~" 'my-end-of-buffer)
(define-key isearch-mode-map "\C-^" 'isearch-other-control-char)
							; 8 -> up
; (global-set-key [prior] 'scroll-down)			; 9 PgUp
(global-set-key [f34]	'point-to-top)			; +
							; 4 -> left
(global-set-key [f31]	'just-recenter)			; 5
							; 6 -> right
(global-set-key [end]	'end-of-line-or-next)
(global-set-key [C-end]	'my-end-of-buffer)
							; 2 -> down
(global-set-key [next]	'scroll-up)			; 3 PgDn

;; Numeric keypad

(global-set-key [kp-enter] 'grep-all)			; Enter

(global-set-key [up]			'previous-line-or-history)
(global-set-key [down]			'next-line-or-history)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Global mouse bindings

(global-set-key [mode-line mouse-1]	'mouse-delete-other-windows)
(global-set-key [mode-line mouse-2]	'my-bury-buffer)
(global-set-key [mode-line mouse-3]	'kill-buffer-window)

;; (global-unset-key [drag-mouse-1])
(global-set-key [mouse-1] (lambda () (interactive) (deactivate-mark)))
(global-unset-key [S-down-mouse-1])
(global-set-key [S-mouse-1] 'browse-url-at-mouse)
;; S-mouse-2 splits vertically in buffer and horiz on mode line.
(global-set-key [S-mouse-2]		'my-mouse-split-window-vertically)
(global-set-key [M-mouse-3]		'mouse-save-then-yank)
;; Get spurious double-down-mouse-2 on VNC
(global-set-key [double-down-mouse-2]	'ignore)
(global-set-key [double-mouse-2]	'ignore)
(global-set-key [mouse-2]		'mouse-yank-at-click)

(mouse-wheel-mode 1)			; Turn on mouse wheel

;; Mode mouse bindings
(define-key isearch-mode-map [mouse-2] nil)
					; I'd rather mouse-yank-at-click

(define-key completion-list-mode-map
		              [mouse-2]	'mouse-choose-completion)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Menu bar

(put 'revert-buffer 'menu-enable t)

(defun find-menu-entry (file)
  "Create a menu entry for FILE.  The entry is a list containing an
interned symbol for the pseudo-key (this is named after the file) and
the text to display.  The tail of the list is a function that reads a
file name starting from the given one."
  (list (intern file) file 'lambda nil
	'(interactive)
	(list (if (equal (last file) ?/) 'find-file-read 'find-file)
	      file)))

(setq menu-bar-find-menu
      (append '("Find" keymap)
	      (mapcar 'find-menu-entry favourite-files)
	      '("Find")))

;; Menu of frame/buffer commands

(setq menu-bar-misc-menu '("Misc" keymap
  (revert-buffer	"Revert buffer"	. my-revert-buffer)
  (rename-buffer	"Rename buffer" . rename-buffer)
  (recover-file		"Recover file"	. recover-file)
  (make-cd		"Make cd"	. make-cd-command)
  (line			"Line number"	. what-line)
  (position		"Position"	. what-cursor-position)
  (untab		"Untabify"	. untabify)
  (tab			"Tabify"	. tabify)
  (sort			"Sort"		. sort-columns)
  (eprocs		"Emacs procs"	. list-processes)
  "Misc"))

;; Menu of useful modes

(setq menu-bar-mode-menu '("Mode" keymap
  (mail		"Mail"		. rmail)
  (news		"News"		. gnus)
  (shell	"Shell"		. shell)
  (info		"Info"		. info)
  (www		"WWW"		. w3)
  (process	"Procs"		. ps-mode)
  (crontab	"Crontab"	. crontab)
  (fill		"Fill"		. auto-fill-mode)
  (rlogin	"RLogin"	. rlogin)
  (telnet	"Telnet"	. telnet)
  (root		"Root"		. su)
  "Mode"))

(define-key global-map [menu-bar files] menu-bar-find-menu)

; (menu-bar-mode -1)				; Menus are for WIMPS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Initial buffer

(condition-case nil (kill-buffer "*Messages*") (error nil))

;; Load a file unless there were command line arguments (car is
;; "emacs").

(or (not (string-equal (buffer-name) "*scratch*"))
    ;; We're in initial scratch buffer
    (cdr command-line-args)			; No args given
    (zerop (user-real-uid))			; Not running as root
    (progn
      (and (getenv "DIALUP") (load-file "~/lisp/freeterm.el"))
      (rmail)
      (kill-buffer "*scratch*")))

(message ".emacs done")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(custom-set-variables
  ;; custom-set-variables was added by Custom -- don't edit or cut/paste it!
  ;; Your init file should contain only one such instance.
 '(compilation-ask-about-save nil t)
 '(compilation-read-command nil)
 '(dired-recursive-deletes (quote top))
 '(pc-select-meta-moves-sexps t)
 '(pc-select-selection-keys-only t)
 '(pc-selection-mode t t)
 '(rmail-confirm-expunge nil)
 '(rmail-summary-window-size 40)
 '(time-stamp-format "%:y-%02m-%02d %02H:%02M"))

(custom-set-faces
  ;; custom-set-faces was added by Custom -- don't edit or cut/paste it!
  ;; Your init file should contain only one such instance.
 '(custom-comment-face ((((class grayscale color) (background light)) (:background "red"))))
 '(custom-comment-tag-face ((((class color) (background light)) (:foreground "green"))))
 '(custom-documentation-face ((t (:foreground "black"))))
 '(custom-state-face ((((class color) (background light)) (:foreground "blue")))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; End of .emacs
