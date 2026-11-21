(define-module (hollix packages ollama)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix build-system trivial)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (gnu packages base)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages commencement)
  #:use-module (gnu packages elf)
  #:use-module (gnu packages gcc)
  #:export (ollama ollama-0.40.14 ollama-0.40.16 ollama-0.40.17))

;; Ollama's Linux release bundles the server and its CPU/GPU runners.  Keep
;; this package scoped to the official x86-64 GNU/Linux release archive.
(define (make-ollama version hash)
  (package
    (name "ollama")
    (version version)
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://github.com/ollama/ollama/releases/download/v"
             version "/ollama-linux-amd64.tar.zst"))
       (sha256
        (base32 hash))))
    (build-system trivial-build-system)
    (arguments
     (list
      #:modules '((guix build utils)
                  (ice-9 ftw)
                  (srfi srfi-1))
      #:builder
      #~(begin
          (use-modules (guix build utils)
                       (ice-9 ftw)
                            (srfi srfi-1))
          (let* ((out #$output)
                 (zstd (search-input-file %build-inputs "/bin/zstd"))
                 (tar (search-input-file %build-inputs "/bin/tar"))
                 (patchelf (search-input-file %build-inputs "/bin/patchelf"))
                 (bash (search-input-file %build-inputs "/bin/bash"))
                 (loader (search-input-file
                          %build-inputs "/lib/ld-linux-x86-64.so.2")))
            (mkdir-p out)
            (invoke zstd "-d" #$source "-o" "ollama.tar")
            (invoke tar "-xf" "ollama.tar" "-C" out)

            ;; Official binaries expect a conventional Linux interpreter.
            ;; Point executable files at Guix's loader; static files and
            ;; scripts do not have a PT_INTERP segment and are left alone.
            (for-each
             (lambda (file)
               (when (and (file-exists? file)
                          (not (file-is-directory? file))
                          (access? file X_OK))
                 (false-if-exception
                  (invoke patchelf "--set-interpreter" loader file))))
             (find-files out))

            ;; The release archive has the executable at bin/ollama and
            ;; runner files under lib/ollama.  Preserve the executable before
            ;; replacing its path with a launcher that passes the runner
            ;; directory explicitly.
            (let* ((library-directories
                    (delete-duplicates
                     (append (map dirname
                                  (find-files (string-append out "/lib/ollama")
                                              "\\.so([.].*)?$"))
                             (list (dirname loader)
                                   #$(file-append gcc-toolchain "/lib")
                                   #$(file-append gcc-toolchain "/lib64")))
                     string=?))
                   (library-path (string-join library-directories ":"))
                   (launcher (string-append out "/bin/ollama")))
              (rename-file launcher (string-append out "/ollama"))
              (mkdir-p (dirname launcher))
              (call-with-output-file launcher
                (lambda (port)
                  (format port
                          "#!~a/bin/sh\nexport OLLAMA_RUNNERS_DIR=\"${OLLAMA_RUNNERS_DIR:-~a/lib/ollama/runners}\"\nexport LD_LIBRARY_PATH=\"~a${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}\"\nexec ~a/ollama \"$@\"\n"
                          #$(file-append bash-minimal)
                          out library-path out)))
              (chmod launcher #o755))))))
    (inputs (list bash-minimal gcc-toolchain glibc patchelf tar zstd))
    (supported-systems '("x86_64-linux"))
    (home-page "https://ollama.com")
    (synopsis "Run large language models locally")
    (description
     "Ollama serves and runs large language models locally.  This package
uses Ollama's official GNU/Linux x86-64 release bundle, including its CPU
and CUDA runner components.  NVIDIA GPU use requires a compatible host
driver; Ollama distributes AMD ROCm runners separately.  Model files are
downloaded by the user at runtime and are kept in Ollama's user data
directory.")
    (license license:expat)))

(define-public ollama-0.40.14
  (make-ollama "0.40.14"
               "0zg6pimbnnpgifkc7bj4wr2m98n8chk3x6h0amyd24rxik886glr"))

(define-public ollama-0.40.16
  (make-ollama "0.40.16"
               "13bqix2gqrbf8ay8cvv9a2s5z9vavr1r02myl7kb52dwmjrazgw7"))

(define-public ollama
  (make-ollama "0.40.17"
               "1bvr9q7pchba8jfvkflpvf3bir8h1n670hmj43j24nmciciddy8x"))

(define-public ollama-0.40.17 ollama)
