;; better find-file-in-repository
;; assumes you have magit and maybe other stuff
(defun choose/find-file-in-git-repo ()
  (interactive)
  (require 's)
  (let ((root-dir (magit-toplevel default-directory)))
    (if root-dir
        (let ((default-directory root-dir))
          (let ((f (s-trim
                    (shell-command-to-string
                     "git ls-files -co --exclude-standard | choose"))))
            (unless (string= "" f)
              (find-file f))))
      (call-interactively 'find-file))))
(global-set-key (kbd "C-x f") 'choose/find-file-in-git-repo)
