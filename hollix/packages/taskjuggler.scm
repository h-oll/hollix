(define-module (hollix packages taskjuggler)
  #:use-module (guix build-system ruby)
  #:use-module (guix download)
  #:use-module (guix packages)
  #:use-module (gnu packages ruby-xyz)
  #:export (ruby-taskjuggler-3.8.4))

(define ruby-webrick-1.9.1
  (package/inherit ruby-webrick
    (version "1.9.1")
    (source
     (origin
       (method url-fetch)
       (uri (rubygems-uri "webrick" version))
       (sha256
        (base32
         "12d9n8hll67j737ym2zw4v23cn4vxyfkb6vyv1rzpwv6y6a3qbdl"))))
    ;; The inherited test workaround targets a file removed in 1.9.1.
    (arguments (list #:tests? #f))))

(define-public ruby-taskjuggler-3.8.4
  (package/inherit ruby-taskjuggler
    (version "3.8.4")
    (source
     (origin
       (method url-fetch)
       (uri (rubygems-uri "taskjuggler" version))
       (sha256
        (base32
         "0mq8991sxdrsmwkfqbpzc6x4gfs03aia7zsy7n0yw21km42lj7ln"))))
    ;; TaskJuggler 3.8.4 now declares WEBrick as a runtime dependency.
    (propagated-inputs
     (modify-inputs (package-propagated-inputs ruby-taskjuggler)
       (append ruby-webrick-1.9.1)))))
