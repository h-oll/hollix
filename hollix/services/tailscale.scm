(define-module (hollix services tailscale)
  #:use-module (gnu services)
  #:use-module (gnu services shepherd)
  #:use-module (guix gexp)
  #:use-module (guix records)
  #:use-module (hollix packages tailscale)
  #:export (tailscale-configuration tailscale-service-type))

;; A service configuration record is the usual Guix pattern for system
;; services.  It gives users a typed place to customize the package, state
;; location, daemon flags, and logging behavior.
(define-record-type* <tailscale-configuration>
  tailscale-configuration
  make-tailscale-configuration
  tailscale-configuration?
  (tailscaled tailscale-configuration-tailscaled
              (default tailscaled))
  (state-directory tailscale-configuration-state-directory
                   (default "/var/lib/tailscale"))
  (extra-arguments tailscale-configuration-extra-arguments
                   (default '()))
  (log-file tailscale-configuration-log-file
            (default #f)))

;; Activation runs during system reconfigure before Shepherd starts services.
;; Here it ensures the daemon state directory exists.
(define (tailscale-activation config)
  #~(begin
      (use-modules (guix build utils))
      (mkdir-p #$(tailscale-configuration-state-directory config))))

;; Build the command line for Shepherd.  `make-forkexec-constructor` is the
;; common Guix helper for long-running daemons.
(define (tailscale-shepherd-start config)
  (if (tailscale-configuration-log-file config)
      #~(make-forkexec-constructor
         '(#$(file-append (tailscale-configuration-tailscaled config)
                          "/bin/tailscaled")
           #$(string-append
              "--statedir="
              (tailscale-configuration-state-directory config))
           #$@(tailscale-configuration-extra-arguments config))
         #:log-file #$(tailscale-configuration-log-file config))
      #~(make-forkexec-constructor
         '(#$(file-append (tailscale-configuration-tailscaled config)
                          "/bin/tailscaled")
           #$(string-append
              "--statedir="
              (tailscale-configuration-state-directory config))
           #$@(tailscale-configuration-extra-arguments config)))))

;; A Shepherd service is the runtime piece that actually starts and stops the
;; daemon once the operating system is booted.
(define (tailscale-shepherd-service config)
  (list
   (shepherd-service
    (documentation "Run the Tailscale daemon.")
    (provision '(tailscaled tailscale))
    (requirement '(user-processes))
    (start (tailscale-shepherd-start config))
    (stop #~(make-kill-destructor)))))

;; A Guix service type ties together configuration data and the lower-level
;; extensions it needs.  This one creates the state directory at activation
;; time and registers a root Shepherd service.
(define-public tailscale-service-type
  (service-type
   (name 'tailscale)
   (extensions
    (list
     (service-extension activation-service-type
                        tailscale-activation)
     (service-extension shepherd-root-service-type
                        tailscale-shepherd-service)))
   (default-value (tailscale-configuration))
   (description "Run the Tailscale daemon.")))
