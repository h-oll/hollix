(define-module (hollix packages minecraft-rl)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix base32)
  #:use-module (guix build-system pyproject)
  #:use-module (guix download)
  #:use-module (guix packages)
  #:use-module (gnu packages machine-learning)
  #:use-module (gnu packages python-build)
  #:use-module (gnu packages python-xyz)
  #:export (python-stable-baselines3))

;; Stable-Baselines3 is not packaged by the Guix revision pinned for this
;; project.  Keep this definition aligned with the packaged Gymnasium and
;; CPU-only PyTorch versions selected in the experiment manifest.
(define-public python-stable-baselines3
  (package
    (name "python-stable-baselines3")
    (version "2.9.2")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "stable_baselines3" version))
       (sha256
        (base32 "1xrdkayxqbpvm4c4zcixhx3afydd81vhns7hnf0z8hrka7lngwla"))))
    (build-system pyproject-build-system)
    (arguments
     (list
      ;; The release has no setup.py test command; runtime behavior is covered
      ;; by the project's Gymnasium/SB3 learning smoke test.
      #:tests? #f))
    (propagated-inputs
     (list python-cloudpickle
           python-gymnasium
           python-numpy
           python-pytorch))
    (native-inputs
     (list python-setuptools python-wheel))
    (home-page "https://github.com/DLR-RM/stable-baselines3")
    (synopsis "PyTorch implementations of reinforcement learning algorithms")
    (description
     "Stable-Baselines3 provides reliable implementations of reinforcement
learning algorithms in PyTorch.  It supports the Gymnasium environment API.")
    (license license:expat)))
