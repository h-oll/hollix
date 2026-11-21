(define-module (hollix packages codex-acp)
  #:use-module (guix base32)
  #:use-module (guix build-system node)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix packages)
  #:use-module (gnu packages node-xyz)
  #:use-module (hollix packages codex)
  #:use-module ((hollix packages codex-acp-version-270)
                #:prefix old:)
  #:export (codex-acp codex-acp-2.7.0 codex-acp-2.8.0))

(define-public codex-acp-2.7.0 old:codex-acp-2.7.0)

;; Guix's upstream codex-acp package tracks the older Rust implementation from
;; zed-industries/codex-acp.  The current upstream package lives under the
;; Agent Client Protocol project and is distributed as an npm package.

(define node-delete-dev-dependencies-phase
  `(add-after 'patch-dependencies 'delete-dev-dependencies
     (lambda _
       (modify-json "package.json" (delete-dev-dependencies)))))

;; The Node build system promotes peer dependencies to dependencies before
;; installing.  The SDK marks its MCP server peer as optional and ACP does not
;; use it, so remove it after that promotion to keep the install offline.
(define node-delete-sdk-optional-mcp-server-phase
  `(add-after 'patch-dependencies 'delete-sdk-optional-mcp-server
     (lambda _
       (modify-json "package.json"
         (delete-dependencies '("@modelcontextprotocol/server"))))))

(define (npm-binary-source scope name version hash)
  (origin
    (method url-fetch)
    (uri (string-append "https://registry.npmjs.org/"
                        (if scope
                            (string-append "@" scope "/" name)
                            name)
                        "/-/" name "-" version ".tgz"))
    (sha256
     (base32 hash))))

(define node-zod-4.4.3
  (package
    (name "node-zod")
    (version "4.4.3")
    (source
     (npm-binary-source #f "zod" version
                        "17171zbchqs56621d99kxgs2cg215yp879450rhh1m9zadzz2f7f"))
    (build-system node-build-system)
    (arguments
     (list #:tests? #f
           #:phases #~(modify-phases %standard-phases
                        (delete 'build))))
    (home-page "https://zod.dev")
    (synopsis "TypeScript-first schema validation library")
    (description
     "Zod is a TypeScript-first schema declaration and validation library.")
    (license license:expat)))

(define node-agentclientprotocol-sdk
  (package
    (name "node-agentclientprotocol-sdk")
    (version "2.8.0")
    (source
     (npm-binary-source "agentclientprotocol" "sdk" version
                        "122bx0hsgqywmkcnrl5yp2fp5b1gw5xxpm02wvqgn8fv7pxc1v09"))
    (build-system node-build-system)
    (arguments
     (list #:tests? #f
           #:phases #~(modify-phases %standard-phases
                        (delete 'build)
                        #$node-delete-sdk-optional-mcp-server-phase
                        #$node-delete-dev-dependencies-phase)))
    (inputs (list node-zod-4.4.3))
    (home-page "https://github.com/agentclientprotocol/typescript-sdk")
    (synopsis "Agent Client Protocol TypeScript SDK")
    (description
     "This package provides the TypeScript SDK for the Agent Client Protocol.")
    (license license:asl2.0)))

(define node-diff-9.0.0
  (package
    (name "node-diff")
    (version "9.0.0")
    (source
     (npm-binary-source #f "diff" version
                        "13xmnf3hr0qm51rz1ak2x381xmgi2d0dspg2frsn152mr4ivz65q"))
    (build-system node-build-system)
    (arguments
     (list #:tests? #f
           #:phases #~(modify-phases %standard-phases
                        (delete 'build)
                        #$node-delete-dev-dependencies-phase)))
    (home-page "https://github.com/kpdecker/jsdiff")
    (synopsis "JavaScript text diff implementation")
    (description "This package provides a JavaScript text diff implementation.")
    (license license:bsd-3)))

(define node-path-key-3.1.1
  (package
    (name "node-path-key")
    (version "3.1.1")
    (source
     (npm-binary-source #f "path-key" version
                        "14kvp849wnkg6f3dqgmcb73nnb5k6b3gxf65sgf0x0qlp6n9k2ab"))
    (build-system node-build-system)
    (arguments
     (list #:tests? #f
           #:phases #~(modify-phases %standard-phases
                        (delete 'build)
                        #$node-delete-dev-dependencies-phase)))
    (home-page "https://github.com/sindresorhus/path-key")
    (synopsis "Cross-platform PATH environment variable key")
    (description "This package provides the platform-specific PATH key.")
    (license license:expat)))

(define node-shebang-regex-3.0.0
  (package
    (name "node-shebang-regex")
    (version "3.0.0")
    (source
     (npm-binary-source #f "shebang-regex" version
                        "13wmb23w5srjpn9xx1c85yk5jbc5z9ypg0iz33h6nv5jdnmapnzy"))
    (build-system node-build-system)
    (arguments
     (list #:tests? #f
           #:phases #~(modify-phases %standard-phases
                        (delete 'build)
                        #$node-delete-dev-dependencies-phase)))
    (home-page "https://github.com/sindresorhus/shebang-regex")
    (synopsis "Regular expression for matching a shebang")
    (description "This package provides a regular expression for shebang lines.")
    (license license:expat)))

(define node-shebang-command-2.0.0
  (package
    (name "node-shebang-command")
    (version "2.0.0")
    (source
     (npm-binary-source #f "shebang-command" version
                        "0vjmdpwcz23glkhlmxny8hc3x01zyr6hwf4qb3grq7m532ysbjws"))
    (build-system node-build-system)
    (arguments
     (list #:tests? #f
           #:phases #~(modify-phases %standard-phases
                        (delete 'build)
                        #$node-delete-dev-dependencies-phase)))
    (inputs (list node-shebang-regex-3.0.0))
    (home-page "https://github.com/sindresorhus/shebang-command")
    (synopsis "Get the command from a shebang")
    (description "This package extracts the command named by a shebang line.")
    (license license:expat)))

(define node-which-2.0.2
  (package
    (name "node-which")
    (version "2.0.2")
    (source
     (npm-binary-source #f "which" version
                        "1p2fkm4lr36s85gdjxmyr6wh86dizf0iwmffxmarcxpbvmgxyfm1"))
    (build-system node-build-system)
    (arguments
     (list #:tests? #f
           #:phases #~(modify-phases %standard-phases
                        (delete 'build)
                        #$node-delete-dev-dependencies-phase)))
    (inputs (list node-isexe))
    (home-page "https://github.com/npm/node-which")
    (synopsis "Find an executable in PATH")
    (description "This package locates the first instance of an executable in PATH.")
    (license license:isc)))

(define node-cross-spawn-7.0.6
  (package
    (name "node-cross-spawn")
    (version "7.0.6")
    (source
     (npm-binary-source #f "cross-spawn" version
                        "1siqxlydjwpihy7klgd15cah56vsmxrdm3q90gndyfj1vh63530q"))
    (build-system node-build-system)
    (arguments
     (list #:tests? #f
           #:phases #~(modify-phases %standard-phases
                        (delete 'build)
                        #$node-delete-dev-dependencies-phase)))
    (inputs (list node-path-key-3.1.1
                  node-shebang-command-2.0.0
                  node-which-2.0.2))
    (home-page "https://github.com/moxystudio/node-cross-spawn")
    (synopsis "Cross-platform child process spawning")
    (description "This package provides cross-platform child process spawning.")
    (license license:expat)))

(define node-vscode-jsonrpc-9.0.1
  (package
    (name "node-vscode-jsonrpc")
    (version "9.0.1")
    (source
     (npm-binary-source #f "vscode-jsonrpc" version
                        "1hl9ai2zd2ik4nkpmq1mkmb7v2qq1v6zhhz7y5wgmib30vy1f7bz"))
    (build-system node-build-system)
    (arguments
     (list #:tests? #f
           #:phases #~(modify-phases %standard-phases
                        (delete 'build)
                        #$node-delete-dev-dependencies-phase)))
    (home-page "https://github.com/Microsoft/vscode-languageserver-node")
    (synopsis "JSON-RPC implementation over streams")
    (description "This package provides a JSON-RPC implementation over streams.")
    (license license:expat)))

(define node-define-lazy-prop-3.0.0
  (package
    (name "node-define-lazy-prop")
    (version "3.0.0")
    (source
     (npm-binary-source #f "define-lazy-prop" version
                        "1da99k4vnnn9bxpgjniai8248bcf4w9cwyn7p3wlzii9l9kzxsdv"))
    (build-system node-build-system)
    (arguments
     (list #:tests? #f
           #:phases #~(modify-phases %standard-phases
                        (delete 'build)
                        #$node-delete-dev-dependencies-phase)))
    (home-page "https://github.com/sindresorhus/define-lazy-prop")
    (synopsis "Define lazily evaluated object properties")
    (description
     "This package defines lazily evaluated properties on JavaScript objects.")
    (license license:expat)))

(define node-is-docker-3.0.0
  (package
    (name "node-is-docker")
    (version "3.0.0")
    (source
     (npm-binary-source #f "is-docker" version
                        "1vnxw8y4p31nx66rbgxhd40jc5zx8akmcf7fpl3gy7n84l5hn8qs"))
    (build-system node-build-system)
    (arguments
     (list #:tests? #f
           #:phases #~(modify-phases %standard-phases
                        (delete 'build)
                        #$node-delete-dev-dependencies-phase)))
    (home-page "https://github.com/sindresorhus/is-docker")
    (synopsis "Check if the process is running inside Docker")
    (description
     "This package checks whether the current process is running inside Docker.")
    (license license:expat)))

(define node-is-inside-container-1.0.0
  (package
    (name "node-is-inside-container")
    (version "1.0.0")
    (source
     (npm-binary-source #f "is-inside-container" version
                        "0yz0fbbkypqsx5d5cls1ik8928zkqhwl2kcp4iv7bi2g8fw9bpnv"))
    (build-system node-build-system)
    (arguments
     (list #:tests? #f
           #:phases #~(modify-phases %standard-phases
                        (delete 'build)
                        #$node-delete-dev-dependencies-phase)))
    (inputs (list node-is-docker-3.0.0))
    (home-page "https://github.com/sindresorhus/is-inside-container")
    (synopsis "Check if the process is running inside a container")
    (description
     "This package checks whether the current process is running inside a
container.")
    (license license:expat)))

(define node-powershell-utils-0.2.0
  (package
    (name "node-powershell-utils")
    (version "0.2.0")
    (source
     (npm-binary-source #f "powershell-utils" version
                        "0af0lh2g1r81s9ds9y55v8v79wv7pndi8z1dli092x770mna3494"))
    (build-system node-build-system)
    (arguments
     (list #:tests? #f
           #:phases #~(modify-phases %standard-phases
                        (delete 'build)
                        #$node-delete-dev-dependencies-phase)))
    (home-page "https://github.com/sindresorhus/powershell-utils")
    (synopsis "Utilities for executing PowerShell commands")
    (description "This package provides utilities for executing PowerShell.")
    (license license:expat)))

(define node-powershell-utils-0.1.0
  (package
    (inherit node-powershell-utils-0.2.0)
    (version "0.1.0")
    (source
     (npm-binary-source #f "powershell-utils" version
                        "0aqrjbd5ib1h3iv9lqmkcc50cfl3303b71l152nxcwr17qvypfdb"))))

(define node-is-wsl-3.1.1
  (package
    (name "node-is-wsl")
    (version "3.1.1")
    (source
     (npm-binary-source #f "is-wsl" version
                        "1cifp5r1mabbd24d1b81xgnh7dy0js7vwnx3hyj6iry2jsbkzygh"))
    (build-system node-build-system)
    (arguments
     (list #:tests? #f
           #:phases #~(modify-phases %standard-phases
                        (delete 'build)
                        #$node-delete-dev-dependencies-phase)))
    (inputs (list node-is-inside-container-1.0.0))
    (home-page "https://github.com/sindresorhus/is-wsl")
    (synopsis "Check if the process is running inside WSL")
    (description
     "This package checks whether the current process is running inside Windows
Subsystem for Linux.")
    (license license:expat)))

(define node-run-applescript-7.1.0
  (package
    (name "node-run-applescript")
    (version "7.1.0")
    (source
     (npm-binary-source #f "run-applescript" version
                        "17ccrallz3df13sh6pdkpfcni3i3gharlzh236qxd85a2xqwx6nj"))
    (build-system node-build-system)
    (arguments
     (list #:tests? #f
           #:phases #~(modify-phases %standard-phases
                        (delete 'build)
                        #$node-delete-dev-dependencies-phase)))
    (home-page "https://github.com/sindresorhus/run-applescript")
    (synopsis "Run AppleScript and return its result")
    (description "This package runs AppleScript and returns its result.")
    (license license:expat)))

(define node-bundle-name-4.1.0
  (package
    (name "node-bundle-name")
    (version "4.1.0")
    (source
     (npm-binary-source #f "bundle-name" version
                        "0489x4n9f6z8v4qpycgakqp30j58xsgi69lrl96bw7698119vr1m"))
    (build-system node-build-system)
    (arguments
     (list #:tests? #f
           #:phases #~(modify-phases %standard-phases
                        (delete 'build)
                        #$node-delete-dev-dependencies-phase)))
    (inputs (list node-run-applescript-7.1.0))
    (home-page "https://github.com/sindresorhus/bundle-name")
    (synopsis "Get bundle names from bundle identifiers")
    (description
     "This package gets macOS bundle names from bundle identifiers.")
    (license license:expat)))

(define node-default-browser-id-5.0.1
  (package
    (name "node-default-browser-id")
    (version "5.0.1")
    (source
     (npm-binary-source #f "default-browser-id" version
                        "0ablblhrzy81aixklbvdvq5fzdybh33q1086vkk0sq8bv7hgp51w"))
    (build-system node-build-system)
    (arguments
     (list #:tests? #f
           #:phases #~(modify-phases %standard-phases
                        (delete 'build)
                        #$node-delete-dev-dependencies-phase)))
    (home-page "https://github.com/sindresorhus/default-browser-id")
    (synopsis "Get the default browser bundle identifier")
    (description
     "This package gets the bundle identifier of the default browser on macOS.")
    (license license:expat)))

(define node-default-browser-5.5.1
  (package
    (name "node-default-browser")
    (version "5.5.1")
    (source
     (npm-binary-source #f "default-browser" version
                        "09myy4lzx9mr19yr5vl3c5kazvmahpnz3mnxf2l4ddv5a0c9f692"))
    (build-system node-build-system)
    (arguments
     (list #:tests? #f
           #:phases #~(modify-phases %standard-phases
                        (delete 'build)
                        #$node-delete-dev-dependencies-phase)))
    (inputs (list node-default-browser-id-5.0.1
                  node-bundle-name-4.1.0))
    (home-page "https://github.com/sindresorhus/default-browser")
    (synopsis "Get the default browser")
    (description "This package gets the default browser.")
    (license license:expat)))

(define node-wsl-utils-1.0.0
  (package
    (name "node-wsl-utils")
    (version "1.0.0")
    (source
     (npm-binary-source #f "wsl-utils" version
                        "1kp2fih73a3k49xn64wfcfpaimlqwrcvd1n6mqqx8jd6vk73jc5r"))
    (build-system node-build-system)
    (arguments
     (list #:tests? #f
           #:phases #~(modify-phases %standard-phases
                        (delete 'build)
                        #$node-delete-dev-dependencies-phase)))
    (inputs (list node-powershell-utils-0.1.0
                  node-is-wsl-3.1.1))
    (home-page "https://github.com/sindresorhus/wsl-utils")
    (synopsis "Utilities for working with WSL")
    (description
     "This package provides utilities for working with Windows Subsystem for
Linux.")
    (license license:expat)))

(define node-is-in-ssh-1.0.0
  (package
    (name "node-is-in-ssh")
    (version "1.0.0")
    (source
     (npm-binary-source #f "is-in-ssh" version
                        "0m6r0p35lv8prm60i7sivbz3606yhsbjv3s0pmqqvzjl33j9l5fd"))
    (build-system node-build-system)
    (arguments
     (list #:tests? #f
           #:phases #~(modify-phases %standard-phases
                        (delete 'build)
                        #$node-delete-dev-dependencies-phase)))
    (home-page "https://github.com/sindresorhus/is-in-ssh")
    (synopsis "Check if the process is running in SSH")
    (description
     "This package checks whether the current process is running in an SSH
session.")
    (license license:expat)))

(define node-open-11.0.1
  (package
    (name "node-open")
    (version "11.0.1")
    (source
     (npm-binary-source #f "open" version
                        "0a3cq49303j5i7vgmzcyk208v0byhavfqid9q4h7fpmf8qv2lv2k"))
    (build-system node-build-system)
    (arguments
     (list #:tests? #f
           #:phases #~(modify-phases %standard-phases
                        (delete 'build)
                        #$node-delete-dev-dependencies-phase)))
    (inputs (list node-is-inside-container-1.0.0
                  node-powershell-utils-0.2.0
                  node-define-lazy-prop-3.0.0
                  node-default-browser-5.5.1
                  node-wsl-utils-1.0.0
                  node-is-in-ssh-1.0.0))
    (home-page "https://github.com/sindresorhus/open")
    (synopsis "Open URLs, files, and executables")
    (description
     "This package opens URLs, files, and executables from Node.js.")
    (license license:expat)))

(define-public codex-acp
  (package
    (name "codex-acp")
    (version "2.8.0")
    (source
     (npm-binary-source "agentclientprotocol" "codex-acp" version
                        "10jpx9prlfm7isbg7ga04bchnb9rd2yl6lvmhhjmpfnpaby1qa2c"))
    (build-system node-build-system)
    (arguments
     (list
      #:tests? #f
      #:phases
      #~(modify-phases %standard-phases
          (delete 'build)
          (add-after 'patch-dependencies 'remove-bundled-codex-dependency
            (lambda _
              ;; Prefer this channel's reproducible Rust Codex package over
              ;; the npm package's bundled @openai/codex fallback.
              (modify-json (delete-dependencies '("@openai/codex")))))
          #$node-delete-dev-dependencies-phase
          (add-after 'link-bins 'wrap-codex-acp
            (lambda* (#:key outputs inputs #:allow-other-keys)
              (let ((out (assoc-ref outputs "out"))
                    (codex (search-input-file inputs "/bin/codex")))
                (wrap-program (string-append out "/bin/codex-acp")
                  `("CODEX_PATH" = (,codex)))))))))
    (inputs
     (list codex
           node-agentclientprotocol-sdk
           node-vscode-jsonrpc-9.0.1
           node-open-11.0.1
           node-diff-9.0.0
           node-zod-4.4.3
           node-cross-spawn-7.0.6))
    (home-page "https://github.com/agentclientprotocol/codex-acp")
    (synopsis "ACP adapter for Codex CLI")
    (description
     "codex-acp is an Agent Client Protocol server for Codex.  It starts the
Codex app server, translates ACP requests into Codex operations, and maps
Codex events back into ACP clients.")
    (license license:asl2.0)))

(define-public codex-acp-2.8.0 codex-acp)
