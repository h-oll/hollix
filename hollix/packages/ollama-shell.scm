(define-module (hollix packages ollama-shell)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix build-system pyproject)
  #:use-module (guix git-download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (gnu packages python-build)
  #:use-module (gnu packages python-web)
  #:use-module (gnu packages python-xyz)
  #:export (ollama-shell))

(define-public ollama-shell
  (package
    (name "ollama-shell")
    (version "0.2.0")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/sunkencity999/ollama_shell")
             (commit "9dcae425c43e10c630b9eb44143cffac14ed5827")))
       (file-name (git-file-name name version))
       (sha256
        (base32 "1g0jj0is65kmzixxijijl529l5whsain9398pn96nbj6hxg2m38l"))))
    (build-system pyproject-build-system)
    (arguments
     (list
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'unpack 'drop-unpackaged-search-dependency
            (lambda _
              ;; Guix does not currently provide ddgs; web_search reports its
              ;; absence at runtime, while the rest of the CLI remains usable.
              (substitute* "pyproject.toml"
                (("    \"ddgs>=2[.]0\",.*") "")))))
      ;; The upstream test suite exercises optional integrations and live model
      ;; access, which are not part of this package's build environment.
      #:tests? #f))
    (native-inputs
     (list python-hatchling))
    (propagated-inputs
     (list python-beautifulsoup4
           python-prompt-toolkit
           python-pydantic
           python-requests
           python-rich
           python-textual
           python-typer))
    (home-page "https://github.com/sunkencity999/ollama_shell")
    (synopsis "Local-first AI shell for Ollama")
    (description
     "Ollama Shell is a Python command-line agent that connects to a local
Ollama server and provides an interactive shell, tools, and a terminal user
interface.  This package includes the Textual interface.  Web search through
DuckDuckGo is unavailable because its ddgs dependency is not packaged in this
channel; page fetching remains available.")
    (license license:expat)))
