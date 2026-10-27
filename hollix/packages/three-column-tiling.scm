(define-module (hollix packages three-column-tiling)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix build-system copy)
  #:use-module (guix git-download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (gnu packages base)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages qt)
  #:export (three-column-tiling))

(define-public three-column-tiling
  (package
    (name "3col-tiling")
    ;; Upstream has no release tag; this version identifies the pinned commit.
    (version "0.0.0-847fdd0")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/h-oll/3col-tiling.git")
             (commit "847fdd07e956b254c02239a7cf05c54f667ae853")))
       (file-name (git-file-name name version))
       (sha256
        (base32 "1s7j5q80ds7ddp5wkw2vv31b8hhdr4np35sn48xbfxk89s4wphjv"))))
    (build-system copy-build-system)
    (arguments
     (list
      #:install-plan #~'(("3col-tiling.sh" "bin/3col-tiling"))
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'install 'wrap-runtime-dependencies
            (lambda* (#:key inputs outputs #:allow-other-keys)
              (let* ((out (assoc-ref outputs "out"))
                     (command-paths
                      (map (lambda (command)
                             (dirname (search-input-file inputs command)))
                           '("/bin/bash"
                             "/bin/cat"
                             "/bin/mktemp"
                             "/bin/qdbus"
                             "/bin/rm"
                             "/bin/sed"))))
                (wrap-program (string-append out "/bin/3col-tiling")
                  `("PATH" ":" prefix ,command-paths))))))))
    (inputs
     (list bash coreutils qttools sed))
    (home-page "https://github.com/h-oll/3col-tiling")
    (synopsis "Tile windows in three columns on KDE Plasma")
    (description
     "3col-tiling arranges the active KDE Plasma window in one of three
columns or in a split or grouped zone.  It uses KWin's scripting interface to
move and resize windows, and requires a running KDE Plasma session.")
    (license license:gpl3)))
