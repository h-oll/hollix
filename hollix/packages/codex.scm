(define-module (hollix packages codex)
  #:use-module (guix base32)
  #:use-module (guix build-system cargo)
  #:use-module (guix build-system trivial)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module (guix utils)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages base)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages perl)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages regex)
  #:use-module (gnu packages rust)
  #:use-module (gnu packages rust-apps)
  #:use-module (gnu packages sqlite)
  #:use-module (gnu packages tls)
  #:use-module (gnu packages version-control)
  #:use-module (gnu packages virtualization)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module ((hollix packages codex-cargo-inputs) #:select (codex-cargo-inputs))
  #:export (codex codex-without-code-mode))

;; Keep the newer Codex package in the `hollix` namespace so callers can
;; select it explicitly without relying on module shadowing against Guix.
;; This local variant tracks a newer upstream release while reusing the Guix
;; packaging logic that already adapts Codex to Guix-specific paths and the
;; offline Cargo build workflow.

;; Keep release details together so future version bumps are easy to review.
;; Update the version and source hash together.  When the lockfile changes,
;; regenerate the static cargo-input module with `guix import crate`.
(define codex-version "0.162.1")
(define codex-source-hash
  "0q3wr6cx7pgylp8kgrs1alzl7kkm35dah1scknk01h4l6jlvs2g7")
(define codex-release-tag
  (string-append "rust-v" codex-version))


;; Codex publishes Rust releases with a `rust-v<version>` Git tag.  Factor the
;; origin out so the package form below stays focused on the variant itself.
(define codex-source
  (origin
    (method url-fetch)
    (uri (string-append "https://github.com/openai/codex/archive/refs/tags/"
                        codex-release-tag ".tar.gz"))
    (sha256
     (base32 codex-source-hash))
    (modules '((guix build utils)))
    (snippet
     '(begin
        ;; Bundled bubblewrap source tree; includes a compiled BPF blob
        ;; (demos/flatpak.bpf), so keep using the system bubblewrap source
        ;; instead of the vendored copy.
        (delete-file-recursively "codex-rs/vendor/bubblewrap")))))

;; Guix removed its `codex` package in commit 29b91c49145 (2026-09-22).
;; Keep the small, release-independent portion that this channel variant
;; needs locally, instead of inheriting a binding that no longer exists.
(define codex-build-base
  (package
    (name "codex-build-base")
    (version "0")
    (source #f)
    (build-system cargo-build-system)
    (arguments
     (list
      #:rust rust-1.95
      #:tests? #f
      #:install-source? #f
      #:cargo-build-flags ''("--release")
      #:cargo-install-paths ''("cli" "exec" "linux-sandbox" "app-server" "tui")
      ;; The channel's release-specific phases replace the normalization
      ;; hooks below.  Naming the hooks here keeps the variant independent
      ;; of the former upstream package while preserving that structure.
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'unpack 'chdir-to-workspace
            (lambda _
              (chdir "codex-rs")))
          (add-after 'chdir-to-workspace 'update-version-in-snapshots
            (lambda _ #t))
          (add-after 'chdir-to-workspace 'patch-git-deps-to-vendor
            (lambda _ #t))
          (add-after 'patch-git-deps-to-vendor 'add-version-to-workspace-deps
            (lambda _ #t)))))
    (native-inputs (list perl pkg-config))
    (home-page "https://github.com/openai/codex")
    (synopsis "Codex build base")
    (description "Internal build base for the Hollix Codex package variants.")
    (license license:asl2.0)))

;; The 0.153 series adds dependencies on the mxc workspace.  Its crate
;; manifests live below the repository's `src` directory, so stage the whole
;; checkout explicitly rather than relying on Cargo's one-crate-per-directory
;; vendor layout.
(define mxc-source
  (origin
    (method git-fetch)
    (uri (git-reference
          (url "https://github.com/microsoft/mxc")
          (commit "6cd3d58f05d3447e67109cfb75e042803b843ca4")))
    (file-name (git-file-name "mxc-source" "0.8.0.6cd3d58"))
    (sha256
     (base32 "0z4wndc2z43rb0drxjlk2gimc0va01i9w2m849b4yqli3zci6jax"))))

;; Codex's TCP tunnel uses two crates from this workspace by Git revision.
;; Stage the workspace intact: h3-quinn has a path dependency on its sibling
;; h3 crate, which cannot be represented by independent single-crate inputs.
(define h3-source
  (origin
    (method git-fetch)
    (uri (git-reference
          (url "https://github.com/hyperium/h3")
          (commit "e07e69412876f7e26f026bd75a48b2704d8c8283")))
    (file-name (git-file-name "h3-source" "0.0.8.e07e694"))
    (sha256
     (base32 "1kgh4vqwbg9xq1xs9y1fw7r9a04w60jgzhnlnsd8hxzrr00380by"))))

;; Codex 0.162.1 uses rmcp 3.3.0 from this workspace revision.  Keep the
;; workspace intact so rmcp's sibling rmcp-macros path dependency resolves
;; locally during Cargo's offline lockfile regeneration.
(define rmcp-source
  (origin
    (method git-fetch)
    (uri (git-reference
          (url "https://github.com/modelcontextprotocol/rust-sdk")
          (commit "3e636cab26c013eca5131103c03d20237f12c4df")))
    (file-name (git-file-name "rmcp-source" "3.3.0.3e636ca"))
    (sha256
     (base32 "0r3mv5hvkwf0s35c8s1hv83w1cx2drsdn7f0y6v4qafm0dpwwlzr"))))

;; The runfiles crate is not at the root of its rules_rust Git repository.
;; Keep the pinned source available separately and point Cargo at the crate's
;; actual manifest instead of treating the whole repository as a registry
;; package.
(define runfiles-source
  (origin
    (method git-fetch)
    (uri (git-reference
          (url "https://github.com/dzbarsky/rules_rust")
          (commit "b56cbaa8465e74127f1ea216f813cd377295ad81")))
    (file-name (git-file-name "rules-rust-runfiles" "0.1.0.b56cbaa"))
    (sha256
     (base32 "1sdmgr8gramp4z1kfsmbx083gpinzk8bz3vi0fchbwr1qhnmb6mq"))))

;; Codex uses both crates from this Nucleo workspace revision.  Keep the
;; checkout intact so nucleo's path dependency on nucleo-matcher resolves.
(define nucleo-source
  (origin
    (method git-fetch)
    (uri (git-reference
          (url "https://github.com/helix-editor/nucleo")
          (commit "4253de9faabb4e5c6d81d946a5e35a90f87347ee")))
    (file-name (git-file-name "nucleo-source" "0.5.0.4253de9"))
    (sha256
     (base32 "1hpy62kgzhswhfrhipka9inh4c6iisklmvbsllbbf1njsk314vhy"))))

(define rusty-v8-version "150.4.0")
(define rusty-v8-target "x86_64-unknown-linux-gnu")

(define rusty-v8-archive
  (origin
    (method url-fetch)
    (uri (string-append "https://github.com/denoland/rusty_v8/releases/download/v"
                        rusty-v8-version "/librusty_v8_release_"
                        rusty-v8-target ".a.gz"))
    (sha256
     (base32 "0v5hi3s56b6yk7nh5n0wygh7fn0j41yyjz5903r227qv0yvzssaq"))))

(define rusty-v8-src-binding
  (origin
    (method url-fetch)
    (uri (string-append "https://github.com/denoland/rusty_v8/releases/download/v"
                        rusty-v8-version "/src_binding_release_"
                        rusty-v8-target ".rs"))
    (sha256
     (base32 "01l53l6nk4p5brpz2v3svqijx3hz5nqry8q7x12vdgbrwim849vp"))))

(define rusty-v8-prebuilt
  (package
    (name "rusty-v8-prebuilt")
    (version rusty-v8-version)
    (source #f)
    (build-system trivial-build-system)
    (arguments
     (list
      #:modules '((guix build utils))
      #:builder
      #~(begin
          (use-modules (guix build utils))
          (mkdir-p #$output)
          (copy-file #$rusty-v8-archive
                     (string-append #$output "/librusty_v8_release_"
                                    #$rusty-v8-target ".a.gz"))
          (copy-file #$rusty-v8-src-binding
                     (string-append #$output "/src_binding_release_"
                                    #$rusty-v8-target ".rs")))))
    (home-page "https://github.com/denoland/rusty_v8")
    (synopsis "Prebuilt rusty_v8 artifacts for Codex code mode")
    (description
     "This package provides the prebuilt rusty_v8 static library and generated
source binding used by the Codex code-mode variant.")
    (license license:asl2.0)))

;; Internal base package for the code-mode-disabled build.  The public
;; `codex-without-code-mode` package below is only a thin renamed wrapper
;; around this build so both variants can coexist in one profile.
(define codex-without-code-mode-base
  (package
    ;; Guix no longer provides a Codex base package, so inherit the local,
    ;; release-independent build base above.
    (inherit codex-build-base)
    (version codex-version)
    (source codex-source)
    (arguments
     (substitute-keyword-arguments (package-arguments codex-build-base)
       ;; The upstream test suite needs services and network-sensitive fixtures
       ;; that are outside this package's reproducible offline build.
       ((#:tests? _ #f)
        #f)
       ;; The repository root is a workspace.  Build the commands inherited
       ;; from Guix explicitly so every installed Codex executable is present.
       ((#:cargo-build-flags _ ''("--release"))
        ''("--release"
           "--package" "codex-cli"
           "--package" "codex-exec"
           "--package" "codex-linux-sandbox"
           "--package" "codex-app-server"
           "--package" "codex-tui"))
       ((#:phases phases #~%standard-phases)
       #~(modify-phases #$phases
            ;; The static Cargo vendor tree includes upstream binary test
            ;; fixtures and cross-platform import libraries.  They are source
            ;; artifacts of dependencies, not pre-generated build outputs.
            (delete 'check-for-pregenerated-files)
            (add-after 'chdir-to-workspace 'add-compat-source-paths
              (lambda _
                ;; Guix's inherited patch-hardcoded-paths phase still rewrites
                ;; two old test helper paths from the inherited Guix package.
                ;; These files are absent from this newer release, so provide
                ;; inert placeholders to keep the inherited substitute* list
                ;; valid.
                (for-each
                 (lambda (legacy-path)
                   (unless (file-exists? legacy-path)
                     (mkdir-p (dirname legacy-path))
                     (call-with-output-file legacy-path
                       (lambda (port)
                         (display
                          "// compatibility placeholder for inherited Guix path rewrites\n"
                          port)))))
                 '("shell-command/src/command_safety/is_safe_command.rs"
                   "core/src/tools/runtimes/shell/unix_escalation_tests.rs"))))
            (replace 'patch-git-deps-to-vendor
              (lambda _
                ;; Normalize every workspace manifest to the static vendored
                ;; crate set.  Cargo must not fetch these Git dependencies in
                ;; Guix's offline build environment.
                (substitute* (find-files "." "^Cargo\\.toml$")
                  ;; Codex uses Windows sandbox support from the mxc workspace.
                  ;; Its source is already staged locally; point each direct
                  ;; workspace dependency at the appropriate checkout so Cargo
                  ;; does not attempt a Git fetch in offline mode.
                  (("learning_mode_windows = \\{ git = \"https://github.com/microsoft/mxc\", rev = [^}]+\\}")
                   (string-append
                    "learning_mode_windows = { version = \"0.8.0\", path = \""
                    #$mxc-source
                    "/src/backends/learning_mode/windows\" }"))
                  (("wxc_common = \\{ git = \"https://github.com/microsoft/mxc\", rev = [^}]+\\}")
                   (string-append
                    "wxc_common = { version = \"0.8.0\", path = \""
                    #$mxc-source
                    "/src/core/wxc_common\" }"))
                  (("appcontainer_common = \\{ git = \"https://github.com/microsoft/mxc\", rev = [^}]+\\}")
                   (string-append
                    "appcontainer_common = { version = \"0.8.0\", path = \""
                    #$mxc-source
                    "/src/backends/appcontainer/common\" }"))
                  ;; The h3 workspace has an internal path dependency between
                  ;; h3-quinn and h3, so keep its checked-out workspace intact.
                  (("h3 = \\{ git = \"https://github.com/hyperium/h3\", rev = [^}]+\\}")
                   (string-append
                    "h3 = { version = \"0.0.8\", path = \""
                    #$h3-source "/h3\" }"))
                  (("h3-quinn = \\{ git = \"https://github.com/hyperium/h3\", rev = [^}]+\\}")
                   (string-append
                    "h3-quinn = { version = \"0.0.10\", path = \""
                    #$h3-source "/h3-quinn\" }"))
                  ;; rmcp 3.3.0 is pinned to a Git revision.  Point Cargo at
                  ;; the staged workspace so its rmcp-macros sibling remains
                  ;; available without fetching Git during the build.
                  (("rmcp = \\{ git = \"https://github.com/modelcontextprotocol/rust-sdk\", rev = [^}]+, version = \"=3\\.3\\.0\", default-features = false \\}")
                   (string-append
                    "rmcp = { version = \"=3.3.0\", path = \""
                    #$rmcp-source "/crates/rmcp\", default-features = false }"))
                  (("crossterm = \\{ git = [^}]+\\}")
                   "crossterm = { version = \"0.29.0\" }")
                  (("ratatui = \\{ git = [^}]+\\}")
                   "ratatui = { version = \"0.30.2\" }")
                  (("tokio-tungstenite = \\{ git = [^}]+\\}")
                   "tokio-tungstenite = { version = \"0.28.0\" }")
                  (("tungstenite = \\{ git = [^}]+\\}")
                   "tungstenite = { version = \"0.27.0\" }")
                  (("nucleo = \\{ git = [^}]+\\}")
                   (string-append "nucleo = { version = \"0.5.0\", path = \""
                                  #$nucleo-source "\" }"))
                  (("runfiles = \\{ git = [^}]+\\}")
                   (string-append "runfiles = { version = \"0.1.0\", path = \""
                                  #$runfiles-source "/rust/runfiles\" }")))
                ;; Keep V8-dependent crates out of the workspace and match
                ;; Guix's existing code-mode disablement for offline builds.
                (substitute* "Cargo.toml"
                  (("\"v8-poc\",") ""))
                (substitute* "Cargo.toml"
                  (("codex-code-mode = \\{ path = \"code-mode\" \\}")
                   "codex-code-mode = { path = \"code-mode\", default-features = false }"))
                ;; Drop the trailing Cargo patch tables wholesale.  They are at
                ;; the end of the root manifest, and leaving them in place
                ;; makes Cargo reject Guix's vendored crates as duplicate patch
                ;; sources.
                (invoke "perl" "-0pi" "-e"
                        "s/\\n\\[patch\\.crates-io\\][\\s\\S]*\\z/\\n/s"
                        "Cargo.toml")
                ;; The upstream lockfile still pins several of those
                ;; dependencies to git URLs.  Once the manifest has been
                ;; normalized to versioned offline sources, let Cargo resolve a
                ;; fresh lock against the vendored crate set instead of trying
                ;; to refresh those git checkouts.
                (when (file-exists? "Cargo.lock")
                  (delete-file "Cargo.lock"))))
            (add-after 'patch-git-deps-to-vendor 'drop-cargo-patch-tables
              (lambda _
                ;; Some member manifests contain trailing patch sections too.
                ;; They would override the normalized registry dependencies.
                (invoke "perl" "-0pi" "-e"
                        "s/\\n\\[patch\\.[^\\n]*\\][\\s\\S]*\\z/\\n/s"
                        "Cargo.toml")))
            (add-before 'build 'normalize-cargo-lockfile
              (lambda _
                ;; The vendored tokio-tungstenite manifest retains a forked
                ;; tungstenite Git dependency.  Normalize it before Cargo
                ;; resolves a replacement lockfile from local sources.
                (let ((cargo-files (find-files "." "^Cargo\\.toml$")))
                  (substitute* cargo-files
                    (("tungstenite = \\{ git = [^}]+\\}")
                     "tungstenite = { version = \"0.27.0\" }"))
                  (substitute* (find-files "guix-vendor" "^Cargo\\.toml$")
                    (("git = \"https://github.com/openai-oss-forks/tungstenite-rs\"")
                     "version = \"0.27.0\"")
                    (("rev = \"4fffad30fe373adbdcffab9545e9e9bf4f2fc19f\"")
                     ""))
                  (for-each
                   (lambda (cargo-file)
                     (invoke "perl" "-0pi" "-e"
                             "s/\\n\\[patch\\.[^\\n]*\\][\\s\\S]*\\z/\\n/s"
                             cargo-file))
                   cargo-files))
                (when (file-exists? "Cargo.lock")
                  (delete-file "Cargo.lock"))))
            (add-before 'build 'raise-codex-exec-recursion-limit
              (lambda _
                ;; Rust 1.94 exceeds its default type-query recursion limit
                ;; while compiling Codex's deeply instrumented async dispatch.
                ;; Keep this release-specific compiler compatibility setting
                ;; in the binary crates rather than weakening global flags.
                (substitute* "exec/src/main.rs"
                  (("^//! Entry-point")
                   "#![recursion_limit = \"256\"]\n\n//! Entry-point"))
                (substitute* "tui/src/main.rs"
                  (("^use clap::Parser;")
                   "#![recursion_limit = \"256\"]\n\nuse clap::Parser;"))))
            (replace 'update-version-in-snapshots
              (lambda _
                ;; Upstream snapshot fixtures still use 0.0.0 placeholders.
                ;; Keep the version normalization aligned with this package's
                ;; source release even though this channel variant skips tests.
                (let ((snap-files (find-files "." "\\.snap$"))
                      (version #$codex-version))
                  (substitute* snap-files
                    (("\\(v0\\.0\\.0\\)   ")
                     (string-append "(v" version ") "))
                    (("Update available! 0\\.0\\.0 -> 9\\.9\\.9  ")
                     (string-append "Update available! " version " -> 9.9.9"))
                    (("Update available! 0\\.0\\.0 -> 9\\.9\\.9")
                     (string-append "Update available! " version " -> 9.9.9"))))))
            (replace 'add-version-to-workspace-deps
              (lambda _
                ;; Cargo needs explicit versions on local path dependencies so
                ;; the vendored offline workspace resolves consistently.
                (let ((cargo-files (find-files "." "^Cargo\\.toml$"))
                      (version #$codex-version))
                  (substitute* cargo-files
                    (("(codex[_-][a-z0-9_-]+|app_test_support|core_test_support|mcp_test_support) = \\{ path = " all name)
                     (string-append name " = { version = \"" version
                                    "\", path = "))
                    (("(codex[_-][a-z0-9_-]+|app_test_support|core_test_support|mcp_test_support) = \\{ package = " all name)
                     (string-append name " = { version = \"" version
                                    "\", package = "))
                    (("^(path = \"\\.\\./[^\"]*\")" all path-line)
                     (string-append path-line "\nversion = \"" version
                                    "\""))))))))))
    (description
     "Codex is an AI-powered coding assistant that runs in the terminal.
It provides an interactive CLI and TUI for conversations with AI models, with
support for shell command execution, file editing, and code generation.
Configure providers via @file{~/.codex/config.toml}.")
    (inputs
     ;; Retain the runtime tools and libraries Guix's Codex package expects,
     ;; then use the static crate-source table generated from this release's
     ;; Cargo.lock rather than the older upstream package closure.  Keeping
     ;; this table static lets `guix pull` inspect the dependency graph while
     ;; it builds its package cache, without evaluating an importer.
     (cons* bash-minimal coreutils git-minimal sed
            libcap oniguruma openssl sqlite zlib `(,zstd "lib")
            mxc-source h3-source rmcp-source runfiles-source nucleo-source
            (codex-cargo-inputs)))
    ;; Keep Guix's canonical upstream name for package metadata and source
    ;; tracking even though this channel provides the newer variant.  The
    ;; generous limits accommodate Codex's quiet final ThinLTO link.
    (properties '((upstream-name . "codex")
                 (timeout . 108000)
                 (max-silent-time . 36000)))))

;; Public code-mode-enabled build.  This remains a separate Cargo package
;; because it needs different features, inputs, installed binaries, and
;; runtime wrapping than the code-mode-disabled base build.
(define-public codex
  (package
    (inherit codex-without-code-mode-base)
    (name "codex")
    (arguments
     (substitute-keyword-arguments (package-arguments codex-without-code-mode-base)
       ((#:cargo-build-flags _ ''("--release"))
        ''("--release"
           "--package" "codex-cli"
           "--package" "codex-exec"
           "--package" "codex-linux-sandbox"
           "--package" "codex-app-server"
           "--package" "codex-tui"
           "--package" "codex-code-mode-host"))
       ((#:cargo-install-paths _ ''())
        ''("cli" "exec" "linux-sandbox" "app-server" "tui"
           "code-mode-host"))
       ((#:phases phases #~%standard-phases)
        #~(modify-phases #$phases
            (add-after 'add-version-to-workspace-deps
                'enable-code-mode-default-features
              (lambda _
                (substitute* "Cargo.toml"
                  (("codex-code-mode = \\{ version = \"[^\"]+\", path = \"code-mode\", default-features = false \\}")
                   (string-append "codex-code-mode = { version = \""
                                  #$codex-version
                                  "\", path = \"code-mode\" }")))))
            (add-before 'build 'set-rusty-v8-artifacts
              (lambda* (#:key inputs #:allow-other-keys)
                (let ((prebuilt (assoc-ref inputs "rusty-v8-prebuilt")))
                  (setenv "RUSTY_V8_ARCHIVE"
                          (string-append prebuilt "/librusty_v8_release_"
                                         #$rusty-v8-target ".a.gz"))
                  (setenv "RUSTY_V8_SRC_BINDING_PATH"
                          (string-append prebuilt "/src_binding_release_"
                                         #$rusty-v8-target ".rs")))))
            (add-after 'install 'wrap-codex-for-bubblewrap
              (lambda* (#:key inputs outputs #:allow-other-keys)
                (let* ((out (assoc-ref outputs "out"))
                       (bwrap (search-input-file inputs "/bin/bwrap"))
                       (rg (search-input-file inputs "/bin/rg"))
                       (resources (string-append out "/codex-resources")))
                  (mkdir-p resources)
                  (symlink bwrap (string-append resources "/bwrap"))
                  (wrap-program (string-append out "/bin/codex")
                    `("PATH" ":" prefix (,(dirname bwrap)
                                         ,(dirname rg)))))))))))
    (native-inputs
     `(("rusty-v8-prebuilt" ,rusty-v8-prebuilt)
       ,@(package-native-inputs codex-without-code-mode-base)))
    (inputs
     `(("bubblewrap" ,bubblewrap)
       ("ripgrep" ,ripgrep)
       ,@(package-inputs codex-without-code-mode-base)))
    (description
     "Codex is an AI-powered coding assistant that runs in the terminal.
This variant enables codex-code-mode's V8 Javascript executor, installs the
codex-code-mode-host companion binary, and makes bubblewrap available to the
runtime sandbox.")))

;; Public wrapper exposing the code-mode-disabled build under a distinct
;; command name.  Use a trivial package here to avoid rebuilding the same
;; Rust workspace just to rename /bin/codex.
(define-public codex-without-code-mode
  (package
    (name "codex-without-code-mode")
    (version codex-version)
    (source #f)
    (build-system trivial-build-system)
    (arguments
     (list
      #:modules '((guix build utils))
      #:builder
      #~(begin
          (use-modules (guix build utils))
          (let ((bin (string-append #$output "/bin")))
            (mkdir-p bin)
            ;; Expose the code-mode-disabled variant under a distinct command
            ;; so it can coexist with the default `codex` package in one
            ;; profile.
            (symlink (string-append #$codex-without-code-mode-base "/bin/codex")
                     (string-append bin "/codex-without-code-mode"))))))
    (home-page (package-home-page codex-without-code-mode-base))
    (synopsis "Code-mode-disabled Codex command")
    (description
     "This package exposes the code-mode-disabled Codex CLI as the
@command{codex-without-code-mode} command so it can be installed alongside the
default @command{codex} package.")
    (license license:asl2.0)
    (properties '((upstream-name . "codex")))))
