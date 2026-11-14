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
  #:export (tailscale tailscale-1.104.5
            tailscaled tailscaled-1.104.5))

;; Keep frequently changed packaging values near the top of the file.
;; In Guix, version bumps often mean updating the version string and one or
;; more fixed-output hashes, so centralizing them makes maintenance easier.
(define go-package
  ;; Tailscale 1.104.7 requires Go 1.27.4; the current Guix binding is 1.27.3.
  ;; Reuse Guix's Go build recipe with the official 1.27.4 source release.
  (package
    (inherit go-1.27)
    (version "1.27.4")
    (source
     (origin
       (method url-fetch)
       (uri "https://go.dev/dl/go1.27.4.src.tar.gz")
       (sha256
        (base32 "16b0k96na5xaj4l7fwlnfzlj1aj67lb8gnw7fqbh237c39bvikvk"))))
    (arguments
     ;; This compiler is an internal Tailscale build tool; skip its own suite.
     (substitute-keyword-arguments (package-arguments go-1.27)
       ((#:phases phases #~%standard-phases)
        #~(modify-phases #$phases
            (delete 'check)))))))

(define tailscale-1.104.5-go-git-ref-hash
  "0wwr54km7hri7aa67rickjqlp47yv8h93ds61i2x9h7rxq2jkbka")
(define tailscale-1.104.5-go-fetch-vendor-hash
  "19w2fnygfx171wlyccg18z1dfqgmzm6sb0h6x3dwyzd1n8vi7z9j")
(define tailscale-1.104.5-commit
  "73a48057aaf5f60e4f770b398e9b7af576b01dbe")
(define tailscale-1.104.7-go-git-ref-hash
  "0zzfypfpmaibvfjgjgh8fbrim83acyp6pzswwl2qdq2qcsjrkc79")
(define tailscale-1.104.7-go-fetch-vendor-hash
  "13qzagqbr42cnpy6m66bg1r45jd7gifi1srm96xka9vi6ygbvacr")
(define tailscale-1.104.7-commit
  "cbc74fe48ef1b1649f69a4d9a602319427e25102")

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
(define (make-tailscale-source version git-ref-hash vendor-hash)
  (origin
    (method go-fetch-vendored)
    (uri (go-git-reference
          (url "https://github.com/tailscale/tailscale")
          (commit (string-append "v" version))
          (sha (base32 git-ref-hash))))
    (sha256
     (base32 vendor-hash))))

(define (make-tailscale version commit source)
  (package
    (name "tailscale")
    (version version)
    (source source)
    (build-system go-build-system)
    (arguments
     `(#:import-path "tailscale.com/cmd/tailscale"
       #:unpack-path "tailscale.com"
       #:install-source? #f
       #:phases
       (modify-phases %standard-phases
         (delete 'check)
         (replace 'build
           (lambda* (#:key import-path #:allow-other-keys)
             (setenv "GOTOOLCHAIN" "local")
             (chdir "./src/tailscale.com")
             (invoke "go" "install"
                     "-trimpath"
                     "-ldflags"
                     (string-append
                      "-s -w -X tailscale.com/version.longStamp="
                      ,version "-t" ,(substring commit 0 9)
                      " -X tailscale.com/version.shortStamp=" ,version)
                     import-path)
             (chdir "../.."))))
       #:go ,go-package))
    (home-page "https://tailscale.com")
    (synopsis "Tailscale client")
    (description "Tailscale client")
     (license license:bsd-3)))

(define-public tailscale-1.104.5
  (make-tailscale
   "1.104.5"
   tailscale-1.104.5-commit
   (make-tailscale-source
    "1.104.5"
    tailscale-1.104.5-go-git-ref-hash
    tailscale-1.104.5-go-fetch-vendor-hash)))

(define-public tailscale
  (make-tailscale
   "1.104.7"
   tailscale-1.104.7-commit
   (make-tailscale-source
    "1.104.7"
    tailscale-1.104.7-go-git-ref-hash
    tailscale-1.104.7-go-fetch-vendor-hash)))

;; `tailscaled` is almost the same source package as the CLI client, but it
;; builds a different Go command and installs a different binary.
(define (make-tailscaled tailscale-package)
  (let ((import-path "tailscale.com/cmd/tailscaled"))
    (package
      (inherit tailscale-package)
      (name "tailscaled")
      (arguments
       (substitute-keyword-arguments (package-arguments tailscale-package)
         ((#:import-path _ #f)
          import-path)))
      (synopsis "Tailscale daemon")
      (description "Tailscale daemon"))))

(define-public tailscaled-1.104.5
  (make-tailscaled tailscale-1.104.5))

(define-public tailscaled
  (make-tailscaled tailscale))
