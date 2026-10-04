(define-module (hollix packages lockfile)
  #:use-module (ice-9 textual-ports)
  #:export (embed-file-contents))

;; Embed a sibling data file while this module's caller is compiled.  Guix
;; channels install compiled Scheme modules but not arbitrary adjacent files,
;; so consumers can safely use the resulting string after `guix pull`.
(define-syntax embed-file-contents
  (lambda (stx)
    (syntax-case stx ()
      ((_ file-name)
       (let* ((source-file (assq-ref (syntax-source stx) 'filename))
              (file-name (syntax->datum #'file-name))
              (relative-file
               (string-append (dirname source-file) "/" file-name))
              ;; Guix's channel compiler records source locations relative to
              ;; the channel root.  Resolve those through its load path rather
              ;; than through the compiler's working directory.
              (file (or (search-path %load-path relative-file)
                        relative-file)))
         (datum->syntax
          stx
          (call-with-input-file file get-string-all)))))))
