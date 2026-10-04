(define-module (hollix packages audiveris)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix build-system trivial)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (guix build utils)
  #:use-module (gnu packages audio)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages base)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages commencement)
  #:use-module (gnu packages elf)
  #:use-module (gnu packages gtk)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages xorg)
  #:export (audiveris))

;; The upstream Linux release is a jpackage-generated Debian archive.  It
;; contains the application jars, native OCR libraries, and a minimized Java
;; runtime.  Building Audiveris from source would require reproducing its
;; Gradle/Maven dependency repository, so package the fixed upstream payload
;; while adapting its FHS paths to Guix.
(define-public audiveris
  (package
    (name "audiveris")
    (version "5.11.0")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://github.com/Audiveris/audiveris/releases/download/"
             version "/Audiveris-" version "-ubuntu24.04-x86_64.deb"))
       (sha256
        (base32 "18y77sy5pa47k4w6jbfrmxgycq1kjskv42baipn4jc9vlfm160gj"))))
    (build-system trivial-build-system)
    (native-inputs
     (list bash-minimal binutils patchelf tar zstd))
    ;; These libraries are loaded by the jpackage launcher and by the
    ;; Java2D/native OCR components at run time.  They are referenced from the
    ;; wrapper below, so Guix retains them in the runtime closure.
    (inputs
     (list alsa-lib
           gcc-toolchain
           gtk+
           libx11
           libxau
           libxcb
           libxdmcp
           libxext
           libxi
           libxrender
           libxtst
           glibc
           zlib))
    (arguments
     (list
      #:modules '((guix build utils))
      #:builder
      #~(begin
          (use-modules (guix build utils))
          (let* ((source (assoc-ref %build-inputs "source"))
                 ;; Keep jpackage's expected layout: bin/ and lib/ must be
                 ;; siblings beneath the application prefix.
                 (payload #$output)
                 (desktop (string-append payload
                                         "/lib/audiveris-Audiveris.desktop"))
                 (library-path
                  (string-join
                   (map (lambda (input)
                          (string-append input "/lib"))
                        (list (assoc-ref %build-inputs "alsa-lib")
                              (assoc-ref %build-inputs "gcc-toolchain")
                              (assoc-ref %build-inputs "gtk+")
                              (assoc-ref %build-inputs "libx11")
                              (assoc-ref %build-inputs "libxau")
                              (assoc-ref %build-inputs "libxcb")
                              (assoc-ref %build-inputs "libxdmcp")
                              (assoc-ref %build-inputs "libxext")
                              (assoc-ref %build-inputs "libxi")
                              (assoc-ref %build-inputs "libxrender")
                              (assoc-ref %build-inputs "libxtst")
                              (assoc-ref %build-inputs "glibc")
                              (assoc-ref %build-inputs "zlib")))
                   ":")))
            (mkdir-p #$output)
            (invoke (string-append (assoc-ref %build-inputs "binutils")
                                   "/bin/ar")
                    "x" source)
            (invoke (string-append (assoc-ref %build-inputs "zstd")
                                   "/bin/zstd")
                    "-d" "data.tar.zst" "-o" "data.tar")
            (invoke (string-append (assoc-ref %build-inputs "tar")
                                   "/bin/tar")
                    "-xf" "data.tar")
            (mkdir-p payload)
            (copy-recursively "opt/audiveris" payload)
            (mkdir-p (string-append #$output "/bin"))
            (invoke (string-append (assoc-ref %build-inputs "patchelf")
                                   "/bin/patchelf")
                    "--set-interpreter"
                    (string-append (assoc-ref %build-inputs "glibc")
                                   "/lib/ld-linux-x86-64.so.2")
                    (string-append payload "/bin/Audiveris"))
            (substitute* desktop
              (("Exec=/opt/audiveris/bin/Audiveris")
               (string-append "Exec=" #$output "/bin/audiveris"))
              (("Icon=/opt/audiveris/lib/Audiveris.png")
               (string-append "Icon=" payload "/lib/Audiveris.png"))
              (("Categories=Unknown") "Categories=Office;"))
            (mkdir-p (string-append #$output "/share/applications"))
            (copy-file desktop
                        (string-append #$output
                                       "/share/applications/audiveris.desktop"))
            (mkdir-p (string-append #$output "/share/icons/hicolor/256x256/apps"))
            (copy-file (string-append payload "/lib/Audiveris.png")
                       (string-append #$output
                                      "/share/icons/hicolor/256x256/apps/audiveris.png"))
            ;; Do not use wrap-program here: it renames the native jpackage
            ;; launcher, which makes it search for .audiveris-real.cfg.
            (call-with-output-file (string-append #$output "/bin/audiveris")
              (lambda (port)
                (format port "#!~a/bin/bash~%export LD_LIBRARY_PATH=\"~a${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}\"~%exec ~a/bin/Audiveris \"$@\"~%"
                        (assoc-ref %build-inputs "bash-minimal")
                        library-path
                        payload)))
            (chmod (string-append #$output "/bin/audiveris") #o755)))))
    (home-page "https://audiveris.github.io/audiveris/")
    (synopsis "Optical music recognition application")
    (description
     "Audiveris is an optical music recognition application.  It converts
images of printed musical scores into editable symbolic notation and can
export the result as MusicXML.  This package uses the official GNU/Linux
release payload, including its minimized Java runtime and native OCR support.")
    (license license:agpl3+)))
