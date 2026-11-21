(define-module (hollix packages codex)
  #:use-module (guix build-system trivial)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (gnu packages base)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages compression)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module ((hollix packages codex-source-169)
                #:select (codex-0.169.0))
  #:export (codex codex-0.170.0 codex-0.171.0)
  #:re-export (codex-0.169.0))

;; Use OpenAI's pinned Linux package archive.  It includes the CLI, code-mode
;; host, ripgrep, and sandbox resources in the layout expected by Codex.
(define (codex-release-package version hash)
  (package
    (name "codex")
    (version version)
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://github.com/openai/codex/releases/download/rust-v"
             version "/codex-package-x86_64-unknown-linux-musl.tar.gz"))
       (sha256 (base32 hash))))
    (build-system trivial-build-system)
    (arguments
     (list
      #:modules '((guix build utils))
      #:builder
      #~(begin
          (use-modules (guix build utils))
          (let* ((out #$output)
                 (stage (string-append (getcwd) "/stage"))
                 (root (string-append out "/libexec/codex"))
                 (bin (string-append out "/bin"))
                 (gzip (search-input-file %build-inputs "/bin/gzip"))
                 (tar (search-input-file %build-inputs "/bin/tar"))
                 (bash (search-input-file %build-inputs "/bin/bash")))
            (mkdir-p stage)
            (invoke tar "--use-compress-program" gzip "-xf"
                    #$source "-C" stage)
            (copy-recursively stage root)
            (mkdir-p bin)
            (call-with-output-file (string-append bin "/codex")
              (lambda (port)
                (format port
                        "#!~a\nexport PATH=~a:~a:$PATH\nexec ~a \"$@\"\n"
                        bash
                        (string-append root "/codex-path")
                        (string-append root "/codex-resources")
                        (string-append root "/bin/codex"))))
            (chmod (string-append bin "/codex") #o755)))))
    (inputs (list bash-minimal gzip tar))
    (supported-systems '("x86_64-linux"))
    (home-page "https://github.com/openai/codex")
    (synopsis "AI-powered coding agent for the terminal")
    (description
     "Codex is OpenAI's coding agent for the terminal.  This package uses the
pinned upstream x86-64 Linux release bundle and keeps its companion binaries
and sandbox resources beside the CLI.")
    (license license:asl2.0)))

(define-public codex
  (codex-release-package
   "0.171.0"
   "1cznkq660w4g04gzyrkmcbr4p6cn1jznrjiyi4agsss9axvxd4c3"))

(define-public codex-0.171.0 codex)

(define-public codex-0.170.0
  (codex-release-package
   "0.170.0"
   "1svmhh5vjac9xz8id52j0zf2fdffymw0l9r8axqrv05swxxzhzx7"))
