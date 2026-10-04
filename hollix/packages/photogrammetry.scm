(define-module (hollix packages photogrammetry)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix build-system cmake)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (gnu packages algebra)
  #:use-module (gnu packages boost)
  #:use-module (gnu packages gl)
  #:use-module (gnu packages graphics)
  #:use-module (gnu packages graph)
  #:use-module (gnu packages image-processing)
  #:use-module (gnu packages logging)
  #:use-module (gnu packages maths)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages qt)
  #:use-module (gnu packages sqlite)
  #:export (poselib colmap))

;; Photogrammetry packages are kept in the `hollix` namespace so they can be
;; selected explicitly from manifests or shells without shadowing Guix
;; upstream bindings.  The current module exports PoseLib and a GUI-enabled
;; COLMAP build that is patched just enough to build reproducibly in this
;; channel with packaged dependencies only.

;; Keep versioned source details together so release bumps are easy to review.
;; In Guix, version updates usually mean adjusting the version string and one
;; or more fixed-output hashes, so keeping those values near the top makes the
;; maintenance diff smaller and easier to audit.
(define poselib-version "2.0.5-0.fa7280f")
(define poselib-source-hash
  "07sdizz3bxn1di320ga8bami43f5ca3h5i3lmk4lmj5j58s4877z")

(define colmap-version "4.2.0")
(define colmap-source-hash
  "1i9gn8zy4anknxjmk2l7fdmbx0yli7jkydgvcjg60csa3bxk25xn")

;; Keep the GitHub archive layout in one helper so source updates stay focused
;; on version and hash changes instead of repeating origin boilerplate.
(define (github-release-tarball owner repo tag hash)
  (origin
    (method url-fetch)
    (uri (string-append "https://github.com/" owner "/" repo
                        "/archive/refs/tags/" tag ".tar.gz"))
    (sha256
     (base32 hash))))

;; Factor source objects out of the package forms so bumping either package is
;; mostly a top-of-file edit, similar to how the Tailscale module centralizes
;; its source snapshot.
;; COLMAP 4.2.0 explicitly pins this PoseLib revision.  It contains the
;; one-sided focal relative-pose solver introduced after the 2.0.5 release.
(define poselib-source
  (origin
    (method url-fetch)
    (uri (string-append
          "https://github.com/PoseLib/PoseLib/archive/"
          "fa7280fee27f97aff31ae7f98bab7f583fac7d08.tar.gz"))
    (sha256
     (base32 poselib-source-hash))))

(define colmap-source
  (github-release-tarball "colmap" "colmap"
                          colmap-version
                          colmap-source-hash))

(define-public poselib
  (package
    (name "poselib")
    (version poselib-version)
    (source poselib-source)
    (build-system cmake-build-system)
    (arguments
     (list
      #:tests? #f
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'unpack 'drop-upstream-werror
            (lambda _
              ;; PoseLib adds -Werror unconditionally, which is brittle across
              ;; Guix compiler updates and not needed for end-user builds.
              (substitute* "CMakeLists.txt"
                (("-Werror ") "")))))))
    ;; `cmake-build-system` already provides CMake itself.  Only keep
    ;; lightweight helper tools here that the configure step expects.
    (native-inputs
     (list pkg-config))
    ;; PoseLib is a small C++ library with a narrow dependency surface, so the
    ;; packaged variant stays close to upstream instead of carrying extra local
    ;; changes.
    (inputs
     (list eigen))
    (home-page "https://github.com/PoseLib/PoseLib")
    (synopsis "Minimal solvers for calibrated camera pose estimation")
    (description
     "PoseLib provides minimal solvers and robust estimation routines for
calibrated camera pose estimation.")
    (license license:bsd-3)))

(define-public colmap
  (package
    (name "colmap")
    (version colmap-version)
    (source colmap-source)
    (build-system cmake-build-system)
    (arguments
     (list
      #:tests? #f
      ;; Keep the packaged build deterministic: no CUDA, no ONNX, and no
      ;; opportunistic dependency downloads during configure.  The GUI is
      ;; enabled and resolved against packaged Qt modules.
      #:configure-flags
      #~(list "-DBUILD_SHARED_LIBS=ON"
              "-DCUDA_ENABLED=OFF"
              "-DONNX_ENABLED=OFF"
              "-DDOWNLOAD_ENABLED=OFF"
              "-DFETCH_POSELIB=OFF"
              "-DFETCH_FAISS=OFF"
              "-DFETCH_ONNX=OFF")
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'unpack 'patch-build-files
            (lambda _
              ;; Upstream adds `mvs.cc` to the CLI executable when MVS is
              ;; enabled, but the final executable still misses a direct link
              ;; to `colmap_mvs`.  Add it through `OPTIONAL_LIBS`, which is
              ;; already threaded into `colmap_main`'s link list.
              (substitute* "src/colmap/exe/CMakeLists.txt"
                (("list\\(APPEND COLMAP_MAIN_SRCS mvs\\.cc\\)")
                 "list(APPEND COLMAP_MAIN_SRCS mvs.cc)\n    list(APPEND OPTIONAL_LIBS colmap_mvs)"))
              ;; COLMAP installs its exported shared libraries under
              ;; `thirdparty/`, but the installed executable and generated
              ;; RPATH both expect them in the normal library directory.
              ;; Move them to `${CMAKE_INSTALL_LIBDIR}` so Guix's RUNPATH
              ;; validation sees a coherent final layout.
              (substitute* "CMakeLists.txt"
                (("LIBRARY DESTINATION thirdparty/")
                 "LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}"))
              ;; The package ships a desktop entry; make sure it points at the
              ;; installed binary name used by Guix.
              (substitute* "doc/COLMAP.desktop"
                (("Exec=COLMAP gui")
                 "Exec=colmap gui")))))))
    (native-inputs
     (list pkg-config))
    ;; These are the packaged replacements for the dependencies COLMAP would
    ;; otherwise discover ad hoc or fetch itself at configure time.
    (inputs
     (list boost
           ceres
           cgal
           eigen
           faiss
           glew
           glog
           glu
           mesa
           metis
           openimageio
           poselib
           qtbase
           qtsvg
           sqlite
           suitesparse))
    (home-page "https://colmap.github.io/")
    (synopsis "Structure-from-motion and multi-view stereo pipeline")
    (description
     "COLMAP is a general-purpose structure-from-motion and multi-view stereo
pipeline.  This package builds the desktop GUI variant with packaged
dependencies and uses packaged inputs instead of COLMAP's fallback network
downloads.")
    (license license:bsd-3)))
