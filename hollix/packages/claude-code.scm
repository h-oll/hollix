(define-module (hollix packages claude-code)
  #:use-module (guix build-system trivial)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (gnu packages base)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages elf)
  #:export (claude-code claudecode))

;; Anthropic's installer downloads a native executable and installs an
;; auto-updater.  Use the versioned release binary directly and force the
;; documented no-auto-update mode in the launcher.
(define claudecode-version "2.1.327")

(define-public claudecode
  (package
    (name "claude-code")
    (version claudecode-version)
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://downloads.claude.ai/claude-code-releases/"
             version "/linux-x64/claude"))
       ;; SHA-256 from Anthropic's 2.1.327 release manifest.
       (sha256
        (base32 "1jbalwcn1rm90fwcb9kdjmwl7w2i223r1jx7hs1d7gqlm95p8g1l"))))
    (build-system trivial-build-system)
    (arguments
     (list
      #:modules '((guix build utils))
      #:builder
      #~(begin
          (use-modules (guix build utils))
          (let* ((out #$output)
                 (payload (string-append out "/libexec/claude-code/claude"))
                 (bin (string-append out "/bin"))
                 (bash (search-input-file %build-inputs "/bin/bash"))
                 (patchelf (search-input-file %build-inputs "/bin/patchelf"))
                 (loader (search-input-file
                          %build-inputs "/lib/ld-linux-x86-64.so.2")))
            (mkdir-p (dirname payload))
            (copy-file #$source payload)
            (chmod payload #o755)
            (invoke patchelf "--set-interpreter" loader payload)
            (mkdir-p bin)
            (call-with-output-file (string-append bin "/claude")
              (lambda (port)
                (format port
                        "#!~a\nexport DISABLE_AUTOUPDATER=1\nexec ~a \"$@\"\n"
                        bash payload)))
            (chmod (string-append bin "/claude") #o755)))))
    (native-inputs (list patchelf))
    (inputs (list bash-minimal glibc))
    (supported-systems '("x86_64-linux"))
    (home-page "https://github.com/anthropics/claude-code")
    (synopsis "Agentic coding tool for the terminal")
    (description
     "Claude Code is Anthropic's agentic coding tool for the terminal.  This
package installs the pinned Linux x86-64 release binary without running
Anthropic's installer, and disables the automatic updater in its launcher.")
    ;; Anthropic distributes the CLI under its commercial terms, not a
    ;; Guix-recognized free software license.
    (license #f)))

;; Keep the binding aligned with the package and module names while also
;; exporting the concise spelling used by this channel's package callers.
(define-public claude-code claudecode)
