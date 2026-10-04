(define-module (hollix packages basic-pitch)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix build-system pyproject)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (gnu packages audio)
  #:use-module (gnu packages machine-learning)
  #:use-module (gnu packages python-build)
  #:use-module (gnu packages python-science)
  #:use-module (gnu packages python-xyz)
  #:export (python-pretty-midi python-basic-pitch))

;; Basic Pitch is a Python audio-to-MIDI library.  Its release tarball includes
;; the model serializations, and this GNU/Linux package selects the bundled
;; TensorFlow Lite model through the packaged tflite-runtime dependency.
;;
;; Basic Pitch's direct MIDI dependency is not yet packaged in the Guix
;; revisions used by this channel.  Keep it next to its sole local consumer.
(define-public python-pretty-midi
  (package
    (name "python-pretty-midi")
    (version "0.2.11.post0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "pretty_midi" version))
       (sha256
        (base32 "1gx069b9dfpnrgfay743ih2ffh9bi6xgngiwa0gm3c47n34l07n9"))))
    (build-system pyproject-build-system)
    (arguments
     (list
      ;; This release's test phase calls the removed `setup.py test` command;
      ;; upstream does not declare the corresponding test runner.
      #:tests? #f
      ;; Guix's python-mido distribution identifies itself as 0.0.0 even
      ;; though it is packaged at 1.3.2.  PrettyMIDI's runtime import works,
      ;; but the metadata-only sanity check rejects that discrepancy.
      #:phases
      #~(modify-phases %standard-phases
          (delete 'sanity-check))))
    (propagated-inputs
     (list python-importlib-resources
           python-mido
           python-numpy
           python-six))
    (native-inputs
     (list python-setuptools))
    (home-page "https://github.com/craffel/pretty-midi")
    (synopsis "Convenient MIDI data handling for Python")
    (description
     "PrettyMIDI provides functions and classes for working with MIDI data in
Python.")
    (license license:expat)))

(define-public python-basic-pitch
  (package
    (name "python-basic-pitch")
    (version "0.4.0")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "basic_pitch" version))
       (sha256
        (base32 "1rb8mdvab3bhf5ffdwxikf17r19vl0vj2qk0jkahz6cwj15sqj3g"))))
    (build-system pyproject-build-system)
    (arguments
     (list
      ;; The upstream tests require the optional data-processing dependency
      ;; set and run model inference.  The installed CLI is covered by the
      ;; package's normal Python build and wrapper checks.
      #:tests? #f
      ;; Basic Pitch's metadata requires TensorFlow on Python 3.11 and newer,
      ;; even though this GNU/Linux package deliberately uses TFLite instead.
      ;; Avoid rejecting the valid runtime configuration during metadata-only
      ;; validation.
      #:phases
      #~(modify-phases %standard-phases
          (delete 'sanity-check))))
    (propagated-inputs
     (list python-librosa
           python-mir-eval
           python-numpy
           python-pretty-midi
           python-resampy
           python-scikit-learn
           python-scipy
           python-tflite-runtime
           python-typing-extensions))
    (native-inputs
     (list python-cython
           python-setuptools
           python-wheel))
    (home-page "https://github.com/spotify/basic-pitch")
    (synopsis "Audio-to-MIDI converter with pitch-bend detection")
    (description
     "Basic Pitch is a lightweight automatic music transcription library.  It
converts audio to MIDI with pitch bends and supports polyphonic,
instrument-agnostic transcription.  This package includes the command-line
program @command{basic-pitch} and uses TensorFlow Lite to run the bundled
model on GNU/Linux.")
    (license license:asl2.0)))
