(define-module (hollix packages canorus)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix build-system cmake)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (gnu packages cmake)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages qt)
  #:export (canorus))

(define-public canorus
  (package
    (name "canorus")
    (version "0.7.3rc3")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://github.com/canorusmusic/canorus/archive/refs/tags/"
             version ".tar.gz"))
       (sha256
        (base32 "1k0q4l7rx2nh59f3v5l46yspnz30iqn5gwvl9rgzaxcmldf5b173"))))
    (build-system cmake-build-system)
    (arguments
     (list
      ;; This release registers no CTest tests; CMake's check phase treats an
      ;; empty test set as a failure.
      #:tests? #f
      #:configure-flags
      #~(list "-DCMAKE_BUILD_TYPE=Release"
              ;; Keep Guix's install prefix so Canorus compiles its data
              ;; directory as the package's share/canorus path.
              "-DCANORUS_DEV_INSTALL=False"
              "-DNO_RUBY=1"
              ;; Legacy SWIG detection found no usable executable in the
              ;; target Guix build environment.
              ;; Keep the core editor build reproducible without the optional
              ;; Python/Ruby extension modules.
              "-DNO_SWIG=1"
              "-DNO_PYTHON=1")
      ;; Canorus references toolbar artwork with images: paths; SVG icons need
      ;; Qt's SVG plugin from qtsvg.  Register plugin directories from inputs
      ;; so the installed launcher can resolve that plugin in Guix.
      #:modules '((guix build cmake-build-system)
                  (guix build qt-utils)
                  (guix build utils))
      #:imported-modules `(,@%cmake-build-system-modules
                           (guix build qt-utils))
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'install 'wrap-qt
            (lambda* (#:key inputs #:allow-other-keys)
              (wrap-qt-program "canorus"
                               #:output #$output
                               #:inputs inputs)))
          (add-after 'install 'install-desktop-entry
            (lambda* (#:key outputs #:allow-other-keys)
              (let* ((out (assoc-ref outputs "out"))
                     (source-dir (string-append "../canorus-" #$version))
                     (applications (string-append out "/share/applications"))
                     (icons (string-append
                             out "/share/icons/hicolor/64x64/apps")))
                (mkdir-p applications)
                (mkdir-p icons)
                (copy-file (string-append source-dir "/canorus.desktop")
                           (string-append applications "/canorus.desktop"))
                (copy-file (string-append source-dir
                                           "/src/ui/images/clogosm.png")
                           (string-append icons "/canorus.png"))))))))
    (inputs
     (list alsa-lib
           qtbase-5
           qtsvg-5
           qttools-5))
    (native-inputs (list cmake))
    (home-page "https://github.com/canorusmusic/canorus")
    (synopsis "Music score editor")
    (description
     "Canorus is a graphical music score editor with support for notation,
MIDI input and playback, and import and export of several score formats.")
    (license license:gpl3+)))
