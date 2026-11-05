(define-module (hollix packages gog)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix base32)
  #:use-module (guix build-system copy)
  #:use-module (guix build-system go)
  #:use-module (guix download)
  #:use-module (guix git-download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages golang)
  #:use-module (gnu packages golang-build)
  #:use-module (gnu packages golang-check)
  #:use-module (gnu packages golang-crypto)
  #:use-module (gnu packages golang-web)
  #:use-module (gnu packages golang-xyz)
  #:export (gog gdrivemd))

;; Gog's Google API v0.308.0 and Cloud Auth dependency require GAX telemetry
;; helpers newer than Guix's packaged v2.19.0.
(define-public go-github-com-googleapis-gax-go-v2-2.27.0
  (package
    (inherit go-github-com-googleapis-gax-go-v2)
    (name "go-github-com-googleapis-gax-go-v2")
    (version "2.27.0")
    (source
     (origin
       (method url-fetch)
       (uri "https://proxy.golang.org/github.com/googleapis/gax-go/v2/@v/v2.27.0.zip")
       (file-name "go-github-com-googleapis-gax-go-v2-2.27.0.zip")
       (sha256
        (base32 "1z6h71apk172bda3d5hvyyv0l8sj0d9ga15h7q1vddf689yrd8xa"))))
    (arguments
     (list #:import-path "github.com/googleapis/gax-go/v2"
           #:unpack-path "github.com/googleapis/gax-go/v2"
           #:tests? #f
           #:phases
           #~(modify-phases %standard-phases
               (add-after 'unpack 'normalize-module-zip-layout
                 (lambda _
                   (rename-file
                    "src/github.com/googleapis/gax-go/v2/googleapis/gax-go/v2@v2.27.0"
                    "src/google-gax-module")
                   (delete-file-recursively
                    "src/github.com/googleapis/gax-go/v2")
                   (mkdir-p "src/github.com/googleapis/gax-go")
                   (rename-file "src/google-gax-module"
                                "src/github.com/googleapis/gax-go/v2"))))))
    (propagated-inputs
     (modify-inputs
      (package-propagated-inputs go-github-com-googleapis-gax-go-v2)
      (prepend go-google-golang-org-api)))
    (native-inputs (list unzip))))

;; Google API v0.308.0 requires a transport option absent from Guix's
;; packaged Google Cloud Auth module.
(define-public go-cloud-google-com-go-auth-0.24.1
  (package
    (inherit go-cloud-google-com-go-auth)
    (name "go-cloud-google-com-go-auth")
    (version "0.24.1")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://proxy.golang.org/cloud.google.com/go/auth/@v/v"
             version ".zip"))
       (file-name (string-append name "-" version ".zip"))
       (sha256
        (base32 "1imfcqwn3n62wc8azqhh4v1rw9jgf7rznli0863yxw0bi61lckd0"))))
    (arguments
     (list #:import-path "cloud.google.com/go/auth"
           #:unpack-path "cloud.google.com/go/auth"
           #:tests? #f
           #:phases
           #~(modify-phases %standard-phases
               (add-after 'unpack 'normalize-module-zip-layout
                 (lambda _
                   (rename-file
                    "src/cloud.google.com/go/auth/go/auth@v0.24.1"
                    "src/google-cloud-auth-module")
                   (delete-file-recursively "src/cloud.google.com/go/auth")
                   (mkdir-p "src/cloud.google.com/go")
                   (rename-file "src/google-cloud-auth-module"
                                "src/cloud.google.com/go/auth"))))))
    (native-inputs (list unzip))))

;; gogcli's Google Cloud Pub/Sub v2 dependency is not yet present in Guix.
(define-public go-cloud-google-com-go-pubsub-v2
  (package
    (name "go-cloud-google-com-go-pubsub-v2")
    (version "2.8.0")
    (source
     (origin
       ;; The module proxy archive contains only this module.  Fetching the
       ;; monorepo would collide with propagated dependencies that own other
       ;; cloud.google.com/go module paths.
       (method url-fetch)
       (uri (string-append
             "https://proxy.golang.org/cloud.google.com/go/pubsub/v2/@v/v"
             version ".zip"))
       (file-name (string-append name "-" version ".zip"))
       (sha256
        (base32 "01aqm6qzmpwgc29xa4a49hqjg6j2w6h4mayfgsds2f0kxf9rnmvm"))))
    (build-system go-build-system)
    (arguments
     (list #:import-path "cloud.google.com/go/pubsub/v2"
           #:unpack-path "cloud.google.com/go/pubsub/v2"
           #:phases
           #~(modify-phases %standard-phases
               ;; Go module ZIPs are rooted at
               ;; cloud.google.com/go/pubsub/v2@<version>.  The Go build
               ;; system strips one level, so place its contents at the
               ;; expected GOPATH import location.
               (add-after 'unpack 'normalize-module-zip-layout
                 (lambda _
                   (rename-file
                    "src/cloud.google.com/go/pubsub/v2/go/pubsub/v2@v2.8.0"
                    "src/pubsub-v2-module")
                   (delete-file-recursively
                    "src/cloud.google.com/go/pubsub/v2")
                   (mkdir-p "src/cloud.google.com/go/pubsub")
                   (rename-file "src/pubsub-v2-module"
                                "src/cloud.google.com/go/pubsub/v2"))))))
    (native-inputs (list unzip))
    (propagated-inputs
     (list go-cloud-google-com-go-iam
           go-github-com-google-go-cmp
           go-github-com-google-uuid
           go-github-com-googleapis-gax-go-v2
           go-go-opencensus-io
           go-go-opentelemetry-io-otel
           go-go-opentelemetry-io-otel-sdk
           go-go-opentelemetry-io-otel-trace
           go-golang-org-x-sync
           go-google-golang-org-api
           go-google-golang-org-genproto-googleapis-api
           go-google-golang-org-grpc
           go-google-golang-org-protobuf))
    (home-page "https://cloud.google.com/go")
    (synopsis "Google Cloud Pub/Sub client library for Go")
    (description "This package provides the Google Cloud Pub/Sub client library for Go.")
    (license license:asl2.0)))

;; The Git checkout used by Guix omits the JSON files required by this
;; module's go:embed directive.  The canonical module archive includes them.
(define-public go-github-com-santhosh-tekuri-jsonschema-v6-complete
  (package
    (name "go-github-com-santhosh-tekuri-jsonschema-v6-complete")
    (version "6.0.3")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://proxy.golang.org/github.com/santhosh-tekuri/jsonschema/v6/@v/v"
             version ".zip"))
       (file-name (string-append name "-" version ".zip"))
       (sha256
        (base32 "1ghykckhhxp9i1313lj2d6bjicnkkgh02gsidqagvrldi21jaa3r"))))
    (build-system go-build-system)
    (arguments
     (list #:import-path "github.com/santhosh-tekuri/jsonschema/v6"
           #:unpack-path "github.com/santhosh-tekuri/jsonschema/v6"
           #:tests? #f
           #:phases
           #~(modify-phases %standard-phases
               (add-after 'unpack 'normalize-module-zip-layout
                 (lambda _
                   (rename-file
                    "src/github.com/santhosh-tekuri/jsonschema/v6/santhosh-tekuri/jsonschema/v6@v6.0.3"
                    "src/jsonschema-v6-module")
                   (delete-file-recursively
                    "src/github.com/santhosh-tekuri/jsonschema/v6")
                   (mkdir-p "src/github.com/santhosh-tekuri/jsonschema")
                   (rename-file "src/jsonschema-v6-module"
                                "src/github.com/santhosh-tekuri/jsonschema/v6"))))))
    (native-inputs (list unzip))
    (propagated-inputs
     (list go-github-com-dlclark-regexp2
           go-golang-org-x-text))
    (home-page "https://github.com/santhosh-tekuri/jsonschema")
    (synopsis "JSON Schema validation library for Go")
    (description "This package provides JSON Schema compilation and validation for Go.")
    (license license:asl2.0)))

;; Gog's Google Chat APIs need a newer Google API client than Guix provides.
(define-public go-google-golang-org-api-0.308.0
  (package
    (name "go-google-golang-org-api")
    (version "0.308.0")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://proxy.golang.org/google.golang.org/api/@v/v"
             version ".zip"))
       (file-name (string-append name "-" version ".zip"))
       (sha256
        (base32 "19z29f0ia5hafjbfkdh203lvlizj8r35ay9r2g2jylh6gc5xb4wv"))))
    (build-system go-build-system)
    (arguments
     (list #:import-path "google.golang.org/api"
           #:unpack-path "google.golang.org/api"
           #:tests? #f
           #:phases
           #~(modify-phases %standard-phases
               (add-after 'unpack 'normalize-module-zip-layout
                 (lambda _
                   (rename-file "src/google.golang.org/api/api@v0.308.0"
                                "src/google-api-module")
                   (delete-file-recursively "src/google.golang.org/api")
                   (mkdir-p "src/google.golang.org")
                   (rename-file "src/google-api-module"
                                "src/google.golang.org/api")))
               ;; This module has packages below its root and supplies their
               ;; source to Gog; there is no root package to install.
               (replace 'build (lambda _ #t)))))
    (native-inputs (list unzip))
    (home-page "https://pkg.go.dev/google.golang.org/api")
    (synopsis "Google APIs client library for Go")
    (description "This package provides the Google APIs client library required by Gog.")
    (license license:bsd-3)))

;; gogcli exposes a typed MCP server and requires this library at build time.
(define-public go-github-com-mark3labs-mcp-go
  (package
    (name "go-github-com-mark3labs-mcp-go")
    (version "1.3.0")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/mark3labs/mcp-go")
             (commit (string-append "v" version))))
       (file-name (git-file-name name version))
       (sha256
        (base32 "1gzadw8pams0llzvqbbfc9s5hhak0valy1h8fxpwc0y418cyfam5"))))
    (build-system go-build-system)
    (arguments
     (list #:import-path "github.com/mark3labs/mcp-go"
           #:tests? #f
           ;; This module has no Go files at its root; it exports packages
           ;; below it (for example mcp and server) for consumers such as gog.
           #:phases
           #~(modify-phases %standard-phases
               (replace 'build (lambda _ #t)))))
    (propagated-inputs
     (list go-github-com-google-jsonschema-go
           go-github-com-google-uuid
           go-github-com-rogpeppe-go-internal
           go-github-com-santhosh-tekuri-jsonschema-v6-complete
           go-github-com-spf13-cast
           go-github-com-stretchr-testify
           go-github-com-yosida95-uritemplate-v3
           go-google-golang-org-api-0.308.0))
    (home-page "https://github.com/mark3labs/mcp-go")
    (synopsis "Go implementation of the Model Context Protocol")
    (description "This package provides an implementation of the Model Context Protocol for Go.")
    (license license:expat)))

(define-public gog
  (package
    (name "gog")
    (version "0.47.1")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/openclaw/gogcli")
             (commit (string-append "v" version))))
       (file-name (git-file-name name version))
       (sha256
        (base32 "0p36mvdp4r142359nbxlxhv248qgm4f1zpqjzzzblpvvdlskjfw6"))))
    (build-system go-build-system)
    (arguments
     (list #:go go-1.27
           #:import-path "github.com/openclaw/gogcli/cmd/gog"
           #:unpack-path "github.com/openclaw/gogcli"
           #:install-source? #f
           #:phases
           #~(modify-phases %standard-phases
               (add-after 'setup-go-environment 'use-complete-jsonschema
                 (lambda _
                   ;; A transitive input also provides jsonschema at this Go
                   ;; path, but its Git checkout lacks the files used by
                   ;; go:embed.  Ensure the complete module archive wins.
                   (delete-file-recursively
                    "src/github.com/santhosh-tekuri/jsonschema/v6")
                   (copy-recursively
                    #$(file-append
                       go-github-com-santhosh-tekuri-jsonschema-v6-complete
                       "/src/github.com/santhosh-tekuri/jsonschema/v6")
                    "src/github.com/santhosh-tekuri/jsonschema/v6")))
               (add-after 'use-complete-jsonschema 'use-required-google-api
                 (lambda _
                   ;; Enforce the version required by Gog at this Go import
                   ;; path, regardless of the order in which inputs were
                   ;; staged.
                   (delete-file-recursively "src/google.golang.org/api")
                   (copy-recursively
                    #$(file-append go-google-golang-org-api-0.308.0
                                   "/src/google.golang.org/api")
                    "src/google.golang.org/api")))
               (add-after 'use-required-google-api 'use-isolated-pubsub
                 (lambda _
                   ;; Avoid the older Pub/Sub files propagated through the
                   ;; Cloud Go dependency closure.  They conflict with v2.8.
                   (delete-file-recursively "src/cloud.google.com/go/pubsub/v2")
                   (copy-recursively
                    #$(file-append go-cloud-google-com-go-pubsub-v2
                                   "/src/cloud.google.com/go/pubsub/v2")
                    "src/cloud.google.com/go/pubsub/v2")))
               (add-after 'use-required-google-api 'use-required-google-cloud-auth
                 (lambda _
                   ;; Match the transport API expected by google.golang.org/api.
                   (rename-file "src/cloud.google.com/go/auth/oauth2adapt"
                                "src/auth-oauth2adapt")
                   (delete-file-recursively "src/cloud.google.com/go/auth")
                   (copy-recursively
                    #$(file-append
                       go-cloud-google-com-go-auth-0.24.1
                                   "/src/cloud.google.com/go/auth")
                    "src/cloud.google.com/go/auth")
                   (rename-file "src/auth-oauth2adapt"
                                "src/cloud.google.com/go/auth/oauth2adapt")))
               (add-after 'use-required-google-api 'use-required-google-gax
                 (lambda _
                   ;; The newer Auth and API packages use the newer telemetry API.
                   (delete-file-recursively
                    "src/github.com/googleapis/gax-go/v2")
                   (copy-recursively
                    #$(file-append go-github-com-googleapis-gax-go-v2-2.27.0
                                   "/src/github.com/googleapis/gax-go/v2")
                    "src/github.com/googleapis/gax-go/v2")))
               (add-before 'build 'use-packaged-go-toolchain
                 (lambda _
                   ;; Go must not download the toolchain declared in go.mod.
                   (setenv "GOTOOLCHAIN" "local"))))))
    ;; Go sources are needed to compile Gog, not at runtime.  Keeping these as
    ;; ordinary inputs prevents Go libraries from leaking into user profiles.
    (inputs
     (list go-cloud-google-com-go-pubsub-v2
           go-cloud-google-com-go-auth-0.24.1
           go-github-com-googleapis-gax-go-v2-2.27.0
           go-filippo-io-age
           go-github-com-99designs-keyring
           go-github-com-alecthomas-kong
           go-github-com-google-uuid
           go-github-com-mark3labs-mcp-go
           go-github-com-muesli-termenv
           go-github-com-stretchr-testify
           go-github-com-yosuke-furukawa-json5
           go-github-com-yuin-goldmark
           go-go-yaml-in-yaml-v3
           go-golang-org-x-net
           go-golang-org-x-oauth2
           go-golang-org-x-sys
           go-golang-org-x-term
           go-golang-org-x-text
           go-google-golang-org-api-0.308.0))
    (home-page "https://github.com/openclaw/gogcli")
    (synopsis "Google Workspace command-line client")
    (description
     "Gog is a command-line client for Google Workspace services, including Drive
and Docs.  OAuth credentials and tokens remain in user state and are not part
of this package.")
    (license license:expat)))

(define-public gdrivemd
  (package
    (name "gdrivemd")
    (version "0.0.0-c30910a")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/zonca/gdrivemd")
             (commit "c30910ad54358224bae89f7b34d3fa72bba9d073")))
       (file-name (git-file-name name version))
       (sha256
        (base32 "1n8n0lwzk5xk08ckc18vhnqprdygp1mambds17sc8xczfjpgkba9"))))
    (build-system copy-build-system)
    (arguments
     (list #:install-plan
           #~'(("scripts/pull_from_gdoc.sh" "bin/pull_from_gdoc")
               ("scripts/push_to_gdoc.sh" "bin/push_to_gdoc"))
           #:phases
           #~(modify-phases %standard-phases
               (add-after 'install 'use-packaged-gog
                 (lambda _
                   (for-each
                    (lambda (program)
                      (substitute* program
                        (("gog docs")
                         (string-append #$(file-append gog "/bin/gog") " docs")))
                      (chmod program #o555))
                    (list (string-append #$output "/bin/pull_from_gdoc")
                          (string-append #$output "/bin/push_to_gdoc"))))))))
    (inputs (list bash gog))
    (home-page "https://github.com/zonca/gdrivemd")
    (synopsis "Synchronize a Google Doc and Markdown file")
    (description
     "Gdrivemd provides small command-line wrappers that export a Google Doc to
Markdown or write Markdown back to a Google Doc using Gog.")
    ;; The upstream repository has no declared license.  This private-channel
    ;; package is intentionally not presented as suitable for redistribution.
    (license #f)))
