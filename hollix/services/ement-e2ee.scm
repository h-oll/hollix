(define-module (hollix services ement-e2ee)
  #:use-module (gnu home services)
  #:use-module (gnu home services shepherd)
  #:use-module (gnu services)
  #:use-module (gnu services shepherd)
  #:use-module (guix gexp)
  #:use-module (guix records)
  #:use-module (gnu packages nss)
  #:use-module (hollix packages ement-e2ee)
  #:export (ement-e2ee-configuration
            ement-e2ee-service-type))

(define-record-type* <ement-e2ee-configuration>
  ement-e2ee-configuration make-ement-e2ee-configuration
  ement-e2ee-configuration?
  (package ement-e2ee-configuration-package
           (default ement-e2ee))
  (config-file ement-e2ee-configuration-config-file
               (default #f))
  (extra-arguments ement-e2ee-configuration-extra-arguments
                   (default '())))

(define (ement-e2ee-shepherd-service config)
  (let* ((package (ement-e2ee-configuration-package config))
         (config-file (ement-e2ee-configuration-config-file config))
         (arguments
          (append '("serve")
                  (if config-file (list "--config" config-file) '())
                  (ement-e2ee-configuration-extra-arguments config))))
    (shepherd-service
     (documentation
      "Run the Ement end-to-end encryption proxy as a user service.")
     (provision '(ement-e2ee))
     (respawn-delay 5)
     (start
      #~(make-forkexec-constructor
         (list #$(file-append package "/bin/ement-e2ee")
               #$@arguments)
         #:environment-variables
         (append
          (default-environment-variables)
          (list (string-append "SSL_CERT_DIR="
                               #$(file-append nss-certs "/etc/ssl/certs"))))))
     (stop #~(make-kill-destructor)))))

(define-public ement-e2ee-service-type
  (service-type
   (name 'ement-e2ee)
   (extensions
    (list
     (service-extension home-profile-service-type
                        (lambda (config)
                          (list (ement-e2ee-configuration-package config)
                                nss-certs)))
     (service-extension home-shepherd-service-type
                        (compose list ement-e2ee-shepherd-service))))
   (default-value (ement-e2ee-configuration))
   (description
    "Run ement-e2ee under the user's Shepherd.  The default configuration
file at ~/.config/ement-e2ee/config.toml must exist and name a homeserver.")))
