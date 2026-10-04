(define-module (hollix packages tailscale)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix build-system go)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module (guix records)
  #:use-module (guix utils)
  #:use-module (gnu packages base)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages golang)
  #:use-module (gnu packages nss)
  #:use-module (ice-9 match)
  #:export (tailscale tailscaled))

;; Keep frequently changed packaging values near the top of the file.
;; In Guix, version bumps often mean updating the version string and one or
;; more fixed-output hashes, so centralizing them makes maintenance easier.
(define go-package go-1.26)
(define tailscale-version "1.102.4")
(define tailscale-go-git-ref-hash
  "0kczp0g2h8clqcagq5bgrfsrr15fgg7q8m6f02sh5x6mvg6a881w")
(define tailscale-go-fetch-vendor-hash
  "1r11vhmp48j45kvxgk3x2iy0m0ymrc879ql7shsi0rfpk9hwhwbs")

;; This record is similar to Guix's built-in git-reference, but it also carries
;; the fixed-output hash of the fetched checkout because the custom fetcher
;; below needs both the repository location and the expected tree hash.
(define-record-type* <go-git-reference>
  go-git-reference
  make-go-git-reference
  go-git-reference?
  (url go-git-reference-url)
  (commit go-git-reference-commit)
  (sha go-git-reference-sha256))

;; The URL case is kept generic so the vendoring helper can be reused later for
;; archives as well as Git checkouts, even though Tailscale currently uses Git.
(define-record-type* <go-url-reference>
  go-url-reference
  make-go-url-reference
  go-url-reference?
  (url go-url-reference-url)
  (sha go-url-reference-sha))

;; Guix normally fetches a source tree and then runs the package build system.
;; Tailscale is easier to package as a fixed vendored source snapshot, so this
;; helper fetches upstream source, runs `go mod vendor`, and then archives the
;; result into a deterministic tarball.
(define* (go-fetch-vendored uri hash-algorithm hash-value name #:key system)
  (let ((src
         (match uri
           (($ <go-git-reference> url commit sha)
            (origin
              (method git-fetch)
              (uri (git-reference
                    (url url)
                    (commit commit)))
              (sha256 sha)))
           (($ <go-url-reference> url sha)
            (origin
              (method url-fetch)
              (uri url)
              (sha256 sha)))))
        (name (or name "go-git-checkout")))
    (gexp->derivation
     (string-append name "-vendored.tar.gz")
     (with-imported-modules '((guix build utils))
       #~(begin
           (use-modules (guix build utils))
           (let ((inputs (list
                          #+go-package
                          #+tar
                          #+bzip2
                          #+gzip)))
             (set-path-environment-variable "PATH" '("/bin") inputs))
           (mkdir "source")
           (chdir "source")
           (if (file-is-directory? #$src)
               (begin
                 ;; Preserve timestamps so vendored archives remain deterministic.
                 (copy-recursively #$src "."
                                   #:keep-mtime? #t)
                 (for-each (lambda (file)
                             (false-if-exception (make-file-writable file)))
                           (find-files ".")))
               (begin
                 (cond
                  ((string-suffix? ".zip" #$src)
                   (invoke "unzip" #$src))
                  ((tarball? #$src)
                   (invoke "tar" "xvf" #$src))
                  (else
                   (let ((name (strip-store-file-name #$src))
                         (command (compressor #$src)))
                     (copy-file #$src name)
                     (when command
                       (invoke command "--decompress" name)))))))

           (setenv "GOCACHE" "/tmp/gc")
           (setenv "GOMODCACHE" "/tmp/gmc")
           ;; Newer Go releases can try to download a different toolchain on
           ;; demand.  Guix builds should use the packaged compiler instead.
           (setenv "GOTOOLCHAIN" "local")
           (setenv "SSL_CERT_DIR"
                   #+(file-append nss-certs "/etc/ssl/certs/"))
           (invoke "go" "mod" "vendor")

           (invoke "tar" "czvf" #$output
                   "--mtime=@0"
                   "--owner=root:0"
                   "--group=root:0"
                   "--sort=name"
                   "--hard-dereference"
                   ".")))
     #:hash hash-value
     #:hash-algo hash-algorithm)))

;; The actual package source is factored out so both `tailscale` and
;; `tailscaled` can share one vendored source definition.
(define tailscale-source
  (origin
    (method go-fetch-vendored)
    (uri (go-git-reference
          (url "https://github.com/tailscale/tailscale")
          (commit (string-append "v" tailscale-version))
          (sha (base32 tailscale-go-git-ref-hash))))
    (sha256
     (base32 tailscale-go-fetch-vendor-hash))))

(define-public tailscale
  (package
    (name "tailscale")
    (version tailscale-version)
    (source tailscale-source)
    (build-system go-build-system)
    (arguments
     `(#:import-path "tailscale.com/cmd/tailscale"
       #:unpack-path "tailscale.com"
       #:install-source? #f
       #:phases
       (modify-phases %standard-phases
         (delete 'check))
       #:go ,go-package))
    (home-page "https://tailscale.com")
    (synopsis "Tailscale client")
    (description "Tailscale client")
     (license license:bsd-3)))

;; `tailscaled` is almost the same source package as the CLI client, but it
;; builds a different Go command and installs a different binary.
(define-public tailscaled
  (let ((import-path "tailscale.com/cmd/tailscaled"))
    (package
      (inherit tailscale)
      (name "tailscaled")
      (arguments
       (substitute-keyword-arguments (package-arguments tailscale)
         ((#:import-path _ #f)
          import-path)
         ((#:phases phases #~%standard-phases)
         #~(modify-phases #$phases
              (replace 'build
                (lambda _
                  ;; Match the vendoring environment and forbid Go from pulling
                  ;; another toolchain behind Guix's back.
                  (setenv "GOTOOLCHAIN" "local")
                  (chdir "./src/tailscale.com")
                  (invoke "go" "build" "-o" "tailscaled"
                          #$import-path)
                  (chdir "../..")))
              (replace 'install
                (lambda _
                  (install-file "src/tailscale.com/tailscaled"
                                (string-append #$output "/bin"))))))))
      (synopsis "Tailscale daemon")
      (description "Tailscale daemon"))))
