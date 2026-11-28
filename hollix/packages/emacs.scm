(define-module (hollix packages emacs)
  #:use-module (guix base32)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (guix utils)
  #:use-module (gnu packages emacs))

;; Disabled local Emacs variant retained here for reference.  It is not
;; exported; use the Emacs package supplied by Guix.
#; (define-public emacs-31.1
  (package/inherit emacs
    (version "31.1")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "mirror://gnu/emacs/emacs-" version ".tar.xz"))
       (sha256
        (base32 "11j59ybvzbkxfsm9zmhj6ixxls2424rhcw5znlr1kj40jl6pk98x"))))
    ;; The inherited suite has 47 release-suite failures here, and Emacs 31.1
    ;; does not produce native code expected by the inherited integrity check.
    ;; Retain the rest of Guix's build setup.
    (arguments
     (substitute-keyword-arguments (package-arguments emacs)
       ((#:tests? tests? #t) #f)
       ((#:phases phases #~%standard-phases)
        #~(modify-phases #$phases
            (delete 'validate-comp-integrity)))))
    ;; Native compilation and linking can be quiet for a long time.
    (properties
     `((max-silent-time . 36000)
       (timeout . 108000)
       ,@(package-properties emacs)))))
