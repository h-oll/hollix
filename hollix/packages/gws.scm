(define-module (hollix packages gws)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module ((guix build utils) #:select (call-with-temporary-output-file))
  #:use-module (guix build-system cargo)
  #:use-module (guix git-download)
  #:use-module (guix import crate)
  #:use-module (guix packages)
  #:use-module (gnu packages gnome)
  #:use-module (gnu packages pkg-config)
  #:use-module (hollix packages lockfile)
  #:use-module (ice-9 ftw)
  #:export (gws))

;; Keep the main package values together so future version bumps are localized.
;; For Git-based packages this usually means the version tag and the fixed
;; output hash of the fetched source.
(define gws-version "0.22.5")
(define gws-source-hash
  "0nc6wiakv5v7gairv7sj13payn21zfl3fvwsv2llwzbf94z20gh6")

;; Bundle the upstream Cargo.lock next to this module so cargo inputs can be
;; derived reproducibly no matter where the channel is installed from.
;; Embed its contents while this module is compiled: a pulled channel contains
;; the resulting compiled module, but not arbitrary adjacent data files.
(define gws-lockfile-contents
  (embed-file-contents "gws-Cargo.lock"))

(define (gws-cargo-inputs)
  (call-with-temporary-output-file
   (lambda (lockfile port)
     (display gws-lockfile-contents port)
     (force-output port)
     (cargo-inputs-from-lockfile lockfile))))

(define-public gws
  (package
    (name "gws")
    (version gws-version)
    (source
     (origin
       (method git-fetch)
       ;; The upstream project tags releases as `v<version>`, so the package
       ;; version string is turned into the matching Git tag here.
       (uri (git-reference
             (url "https://github.com/googleworkspace/cli")
             (commit (string-append "v" version))))
       (file-name (git-file-name name version))
       (sha256
        (base32 gws-source-hash))))
    (build-system cargo-build-system)
    (arguments
     (list
      ;; Upstream disables tests in its Nix packaging and the workspace is
      ;; built as a release-oriented CLI package.
      #:tests? #f
      #:install-source? #f
      ;; The repository root is a Cargo workspace, so Guix must build and
      ;; install the CLI crate explicitly instead of assuming a root package.
      #:cargo-build-flags ''("--release" "--package" "google-workspace-cli")
      #:cargo-install-paths ''("crates/google-workspace-cli")))
    (native-inputs
     ;; `pkg-config` is needed at build time so Rust crates can discover the
     ;; system libraries they link against.
     (list pkg-config))
    (inputs
     ;; In this Guix version, `cargo-inputs-from-lockfile` returns crate
     ;; sources derived from Cargo.lock.  Adding them to `inputs` lets the
     ;; cargo build system vendor the exact Rust dependency graph recorded by
     ;; upstream, while `libsecret` provides the Linux runtime dependency.
     (cons libsecret
           (gws-cargo-inputs)))
    (home-page "https://github.com/googleworkspace/cli")
    (synopsis "Google Workspace CLI")
    (description
     "GWS is the Google Workspace command-line interface.  This package builds
the upstream Rust workspace and installs the @command{gws} executable from the
@code{google-workspace-cli} crate.")
    (license license:asl2.0)))
