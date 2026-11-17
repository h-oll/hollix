(define-module (hollix packages muscriptor)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix build-system pyproject)
  #:use-module (guix build-system trivial)
  #:use-module (guix base32)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (gnu packages audio)
  #:use-module (gnu packages machine-learning)
  #:use-module (gnu packages python-build)
  #:use-module (gnu packages python-science)
  #:use-module (gnu packages python-web)
  #:use-module (gnu packages python-xyz)
  #:export (python-rotary-embedding-torch
            python-beat-this
            python-muscriptor-0.3.0
            python-muscriptor
            muscriptor))

;; MuScriptor uses Beat This! for tempo and downbeat tracking.  Beat This! and
;; its rotary-embedding dependency are kept here because they are not in Guix.
(define-public python-rotary-embedding-torch
  (package
    (name "python-rotary-embedding-torch")
    (version "0.9.1")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "rotary_embedding_torch" version))
       (sha256
        (base32 "0sdzm1zavdsa907rirrmmzc3s81aandbhvc7gva1gahakk6kjg7l"))))
    (build-system pyproject-build-system)
    (arguments (list #:tests? #f))
    (propagated-inputs
     (list python-einops python-pytorch))
    (native-inputs
     (list python-hatchling))
    (home-page "https://github.com/lucidrains/rotary-embedding-torch")
    (synopsis "Rotary positional embeddings for PyTorch")
    (description
     "This package provides rotary positional embeddings for PyTorch models.")
    (license license:expat)))

;; MuScriptor 0.4.0 requires soundfile >=0.14.0.  Guix's torchaudio pins
;; soundfile 0.13.1, so use a private variant to keep MuScriptor's Python
;; closure on one SoundFile release.
(define python-soundfile-0.14.0
  (package
    (inherit python-soundfile)
    (version "0.14.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "soundfile" version))
       (sha256
        (base32 "04fyq4qa2fwrlqi0d986ll7q3j3wy24kpj27cr05rjlbc4nil75s"))))
    (propagated-inputs
     (modify-inputs (package-propagated-inputs python-soundfile)
       (append python-typing-extensions)))))

(define python-torchaudio-soundfile-0.14.0
  (package
    (inherit python-torchaudio)
    (propagated-inputs
     (modify-inputs (package-propagated-inputs python-torchaudio)
       (replace "python-soundfile" python-soundfile-0.14.0)))))

(define-public python-beat-this
  (package
    (name "python-beat-this")
    (version "1.1.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "beat_this" version))
       (sha256
        (base32 "0p23q9kgi43di6camzl7am7zx1q6fvjwzb6w1rjjm5vjz50wf5rh"))))
    (build-system pyproject-build-system)
    (arguments (list #:tests? #f))
    (propagated-inputs
     (list python-einops
           python-numpy
           python-rotary-embedding-torch
           python-soxr
           python-pytorch
           python-torchaudio-soundfile-0.14.0))
    (native-inputs
     (list python-setuptools))
    (home-page "https://github.com/CPJKU/beat_this")
    (synopsis "Neural beat and downbeat tracker")
    (description
     "Beat This! is a neural network for beat and downbeat tracking in audio.")
    (license license:expat)))

(define (make-python-muscriptor version source-hash)
  (package
    (name "python-muscriptor")
    (version version)
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "muscriptor" version))
       (sha256 source-hash)))
    (build-system pyproject-build-system)
    (arguments
     (list
      ;; Tests require gated Hugging Face model weights and network access.
      #:tests? #f))
    (propagated-inputs
     (list python-beat-this
           python-einops
           python-fastapi
           python-httpx
           python-huggingface-hub
           python-mido
           python-numpy
           python-packaging
           python-multipart
           python-safetensors
           python-soundfile-0.14.0
           python-pytorch
           python-typer
           python-uvicorn))
    (native-inputs
     (list python-hatchling))
    (home-page "https://github.com/muscriptor/muscriptor")
    (synopsis "Multi-instrument music transcription to MIDI and notation")
    (description
     "MuScriptor transcribes recordings containing multiple instruments to MIDI
and sheet music using a transformer model.  Its separately downloaded model
weights require accepting their CC BY-NC 4.0 license on Hugging Face.")
    (license license:expat)))

(define-public python-muscriptor
  (make-python-muscriptor
   "0.4.0"
   (nix-base32-string->bytevector
    "0mxv9qdqlczxc50midxxgivkf8m2bsq67ynrr6837mqndqj7nj1d")))

(define-public python-muscriptor-0.3.0
  (package
    (inherit python-muscriptor)
    (version "0.3.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "muscriptor" version))
       (sha256 (nix-base32-string->bytevector
                "1gbmaxwp10bac76kfmmvlwrv4mwa7vi5m3nn3mds3d0sxc2jlz3k"))))))

;; Install only the command in shared profiles.  Keep Python dependencies in
;; the package closure without unioning their site-packages into Home, where
;; other channels may provide a different python-soundfile version.
(define-public muscriptor
  (package
    (name "muscriptor")
    (version (package-version python-muscriptor))
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
            (symlink (string-append #$python-muscriptor "/bin/muscriptor")
                     (string-append bin "/muscriptor"))))))
    (inputs (list python-muscriptor))
    (home-page (package-home-page python-muscriptor))
    (synopsis "MuScriptor CLI with isolated Python dependencies")
    (description
     "This package exposes the MuScriptor command while keeping its Python
dependencies out of shared profiles to avoid conflicting package versions.")
    (license (package-license python-muscriptor))))
