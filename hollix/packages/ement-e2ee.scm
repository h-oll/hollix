(define-module (hollix packages ement-e2ee)
  #:use-module ((guix build utils) #:select (call-with-temporary-output-file))
  #:use-module (guix build-system cargo)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix import crate)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages nss)
  #:use-module (gnu packages rust)
  #:use-module (gnu packages sqlite)
  #:use-module (hollix packages lockfile)
  #:export (ement-e2ee))

;; Pin this channel snapshot to the upstream commit; update its revision and
;; hash together.
(define ement-e2ee-version "0.1.0-0.20261013.7075a0e")
(define ement-e2ee-commit "7075a0e9e1a18f088a6faf1cc280530df4c826ce")
(define ement-e2ee-source-hash
  "1n4yw5w6gbq5a1a2ciyalfz7iifn40y1a92spc4s5s7ffw3kqkiz")

;; Cargo resolves dependencies offline from this exact upstream lockfile.
(define ement-e2ee-lockfile-contents
  (embed-file-contents "ement-e2ee-Cargo.lock"))

(define (ement-e2ee-cargo-inputs)
  (call-with-temporary-output-file
   (lambda (lockfile port)
     (display ement-e2ee-lockfile-contents port)
     (force-output port)
     (cargo-inputs-from-lockfile lockfile))))

(define-public ement-e2ee
  (package
    (name "ement-e2ee")
    (version ement-e2ee-version)
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/bhwdev/ement-e2ee")
             (commit ement-e2ee-commit)))
       (file-name (git-file-name name version))
       (sha256 (base32 ement-e2ee-source-hash))))
    (build-system cargo-build-system)
    (arguments
     (list
      ;; Upstream declares Rust 1.93 as its minimum compiler version.
      #:rust rust-1.93
      #:install-source? #f
      #:cargo-build-flags ''("--release")
      #:cargo-install-paths ''(".")
      #:phases
      #~(modify-phases %standard-phases
          (add-before 'check 'set-ca-certificate-directory
            (lambda _
              (setenv "SSL_CERT_DIR"
                      (string-append #$nss-certs "/etc/ssl/certs")))))))
    ;; rusqlite's bundled feature still leaves the final executable linked
    ;; against libsqlite3 in this Cargo build; declare the library explicitly.
    (inputs (cons sqlite (ement-e2ee-cargo-inputs)))
    ;; Provide the Mozilla CA store during checks and to users of the package.
    (native-inputs (list nss-certs))
    (propagated-inputs (list nss-certs))
    (home-page "https://github.com/bhwdev/ement-e2ee")
    (synopsis "End-to-end encryption proxy for Ement.el")
    (description
     "Ement-e2ee is a local Matrix reverse proxy that adds end-to-end
encryption support to the Ement.el Emacs client.  It encrypts and decrypts
Matrix events and media while keeping cryptographic state in a local SQLite
store.")
    (license license:expat)))
