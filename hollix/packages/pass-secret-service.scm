(define-module (hollix packages pass-secret-service)
  #:use-module ((guix build utils) #:select (call-with-temporary-output-file))
  #:use-module (guix build-system cargo)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix import crate)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages gnupg)
  #:use-module (hollix packages lockfile)
  #:export (pass-secret-service))

(define pass-secret-service-version "0.7.1")
(define pass-secret-service-lockfile-contents
  (embed-file-contents "pass-secret-service-Cargo.lock"))

(define (pass-secret-service-cargo-inputs)
  (call-with-temporary-output-file
   (lambda (lockfile port)
     (display pass-secret-service-lockfile-contents port)
     (force-output port)
     (cargo-inputs-from-lockfile lockfile))))

(define-public pass-secret-service
  (package
    (name "pass-secret-service")
    (version pass-secret-service-version)
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://github.com/grimsteel/pass-secret-service/archive/refs/tags/v"
             version ".tar.gz"))
       (sha256
        (base32 "1ifrw9c9hamqlna8bvm5l3pz6j5v77x7gc2skhhar0dsxl9p1jsr"))))
    (build-system cargo-build-system)
    (arguments
     (list
      #:install-source? #f
      #:cargo-build-flags ''("--release")
      #:cargo-install-paths ''(".")
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'install 'wrap-and-install-dbus-activation
            (lambda* (#:key outputs #:allow-other-keys)
              (let ((out (assoc-ref outputs "out")))
                ;; The service invokes gpg and gpg-connect-agent by name.
                (wrap-program (string-append out "/bin/pass-secret-service")
                  `("PATH" ":" prefix (,(string-append #$gnupg "/bin"))))
                ;; Let session D-Bus activate this provider directly.
                (let ((services (string-append out
                                               "/share/dbus-1/services")))
                  (mkdir-p services)
                  (call-with-output-file
                      (string-append services
                                     "/org.freedesktop.secrets.service")
                    (lambda (port)
                      (format port
                              "[D-BUS Service]~%Name=org.freedesktop.secrets~%Exec=~a/bin/pass-secret-service~%"
                              out))))))))))
    (inputs (cons gnupg (pass-secret-service-cargo-inputs)))
    (home-page "https://github.com/grimsteel/pass-secret-service")
    (synopsis "Secret Service implementation backed by pass-format storage")
    (description
     "Pass Secret Service provides an implementation of the D-Bus Secret
Service API.  It stores encrypted secret values in a password-store-compatible
directory and uses GnuPG for encryption and decryption.  Session D-Bus can
activate the service through the installed service definition.")
    (license license:gpl3)))
