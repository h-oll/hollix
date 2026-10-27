(define-module (hollix packages ollama-vulkan)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix build-system trivial)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages gl)
  #:use-module (gnu packages vulkan)
  #:use-module (hollix packages ollama)
  #:export (ollama-vulkan))

;; Use Ollama's bundled Vulkan backend with Mesa's Intel ICD for Iris Xe.
(define-public ollama-vulkan
  (package
    (name "ollama-vulkan")
    (version (package-version ollama))
    (source #f)
    (build-system trivial-build-system)
    (arguments
     (list
      #:modules '((guix build utils))
      #:builder
      #~(begin
          (use-modules (guix build utils))
          (let* ((out #$output)
                 (ollama (assoc-ref %build-inputs "ollama"))
                 (loader (assoc-ref %build-inputs "vulkan-loader"))
                 (mesa (assoc-ref %build-inputs "mesa"))
                 (launcher (string-append out "/bin/ollama")))
            (mkdir-p (dirname launcher))
            (call-with-output-file launcher
              (lambda (port)
                (format port
                        (string-append
                         "#!~a/bin/sh\n"
                         "export OLLAMA_VULKAN=\"${OLLAMA_VULKAN:-1}\"\n"
                         "export OLLAMA_LLM_LIBRARY=\"${OLLAMA_LLM_LIBRARY:-vulkan}\"\n"
                         "export OLLAMA_IGPU_ENABLE=\"${OLLAMA_IGPU_ENABLE:-1}\"\n"
                         "export LD_LIBRARY_PATH=\"~a/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}\"\n"
                         "export VK_DRIVER_FILES=\"${VK_DRIVER_FILES:-~a/share/vulkan/icd.d/intel_icd.x86_64.json}\"\n"
                         "exec ~a/bin/ollama \"$@\"\n")
                        #$(file-append bash-minimal)
                        loader mesa ollama)))
            (chmod launcher #o755)))))
    (inputs (list bash-minimal ollama mesa vulkan-loader))
    (supported-systems '("x86_64-linux"))
    (home-page (package-home-page ollama))
    (synopsis "Run Ollama with the Mesa Intel Vulkan driver")
    (description
     "This package launches the channel's Ollama package with Vulkan enabled
by default and includes the Vulkan loader and Mesa runtime.  Mesa supplies the
Intel ANV Vulkan driver used by Iris Xe graphics.  The launcher enables
integrated GPU use by default.  The Vulkan SDK is not needed
at runtime because Ollama's release already includes its Vulkan backend.  The
Intel Vulkan ICD can be selected with the VK_DRIVER_FILES environment variable;
OLLAMA_VULKAN, OLLAMA_LLM_LIBRARY, and OLLAMA_IGPU_ENABLE can also be
overridden by the user.")
    (license (package-license ollama))))
