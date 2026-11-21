(define-module (hollix packages claude-code-acp)
  #:use-module (guix build-system copy)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (gnu packages base)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages elf)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module ((hollix packages claude-code)
                #:select (claudecode claudecode-2.1.327))
  #:export (claude-code-acp claudecode-acp claudecode-acp-0.108.0
            claudecode-acp-0.109.0))

;; The official standalone release contains both the ACP server and a bundled
;; Claude CLI.  Install only the server and select this channel's CLI through
;; the upstream-supported CLAUDE_CODE_EXECUTABLE setting.
(define-public claudecode-acp
  (package
    (name "claude-code-acp")
    (version "0.109.0")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://github.com/agentclientprotocol/claude-agent-acp/releases/download/v"
             version "/claude-agent-acp-linux-x64.tar.gz"))
       ;; SHA-256 digest published in the GitHub release asset metadata.
       (sha256
        (base32 "1jkq2phzgb50gmrxfn9zisl1x9r1rzf05mhaddxr22k3masq2jzv"))))
    (build-system copy-build-system)
    (arguments
     (list
      ;; Bun's standalone ELF has dynamic entries that the generic Guix
      ;; RUNPATH scanner misreads as empty library names.  Its shared-library
      ;; dependencies are provided by glibc.
      #:validate-runpath? #f
      #:install-plan #~'(("claude-agent-acp" "libexec/"))
      #:phases
      #~(modify-phases %standard-phases
          ;; Preserve the upstream Bun executable.  Besides being unnecessary
          ;; for this prebuilt program, stripping changes its behavior.
          (delete 'strip)
          (add-after 'install 'patch-and-wrap-server
            (lambda* (#:key inputs outputs #:allow-other-keys)
              (let* ((out (assoc-ref outputs "out"))
                     (payload (string-append out
                                             "/libexec/claude-agent-acp"))
                     (bin (string-append out "/bin"))
                     (bash (search-input-file inputs "/bin/bash"))
                     (patchelf (search-input-file inputs "/bin/patchelf"))
                     (loader (search-input-file
                              inputs "/lib/ld-linux-x86-64.so.2"))
                     (claude (search-input-file inputs "/bin/claude")))
                (invoke patchelf "--set-interpreter" loader payload)
                (mkdir-p bin)
                (call-with-output-file (string-append bin "/claude-agent-acp")
                  (lambda (port)
                    (format port
                            "#!~a\nexport CLAUDE_CODE_EXECUTABLE=~a\nexport DISABLE_AUTOUPDATER=1\nexec ~a \"$@\"\n"
                            bash claude payload)))
                (chmod (string-append bin "/claude-agent-acp") #o755)))))))
    (native-inputs (list patchelf))
    (inputs (list bash-minimal claudecode glibc))
    (supported-systems '("x86_64-linux"))
    (home-page "https://github.com/agentclientprotocol/claude-agent-acp")
    (synopsis "Agent Client Protocol adapter for Claude Code")
    (description
     "Claude Agent ACP adapts Anthropic's Claude Agent SDK to the Agent Client
Protocol.  The package uses the fixed standalone server release and directs it
to Hollix's Claude Code package.  Automatic updates are disabled.")
    (license license:asl2.0)))

(define-public claudecode-acp-0.109.0 claudecode-acp)

(define-public claude-code-acp claudecode-acp)

(define-public claudecode-acp-0.108.0
  (package
    (inherit claudecode-acp)
    (version "0.108.0")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://github.com/agentclientprotocol/claude-agent-acp/releases/download/v"
             version "/claude-agent-acp-linux-x64.tar.gz"))
       (sha256
        (base32 "0sfzyx2iq3d04xbxjilcx4rnw7zpvz6gp3a1xcdmak58rg0l99rh"))))
    (inputs (list bash-minimal claudecode-2.1.327 glibc))))
