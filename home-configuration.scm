;; This "home-environment" file can be passed to 'guix home reconfigure'
;; to reproduce the content of your profile.  This is "symbolic": it only
;; specifies package names.  To reproduce the exact same profile, you also
;; need to capture the channels being used, as returned by "guix describe".
;; See the "Replicating Guix" section in the manual.

(use-modules (gnu home)
             (gnu packages)
             (gnu packages gnupg)
             (gnu packages mail)
             (gnu services)
             (guix gexp)
             (gnu packages admin)
             (gnu home services)
             (gnu home services shells)
             (gnu home services gnupg)
             (gnu home services ssh)
             (gnu home services dotfiles)
             (gnu home services shepherd)
             (gnu home services desktop)
             (gnu home services sound)
             (hollix packages tailscale)
             (hollix packages codex)
             (hollix packages codex-acp)
             (hollix packages photogrammetry)
             (hollix packages taskjuggler)
             (hollix packages muscriptor)
             ;; (hollix packages emacs)
             (hollix packages gog)
             (hollix packages audiveris)
             (hollix packages ement-e2ee)
             (hollix packages ollama)
             (hollix packages ollama-shell)
             (hollix packages ollama-vulkan)
             (hollix packages three-column-tiling)
             )

(define sync-and-index-mail
  (program-file
   "sync-and-index-mail"
   #~(let ((status (system* #$(file-append isync "/bin/mbsync") "--all")))
       (if (zero? status)
           (exit (system* #$(file-append notmuch "/bin/notmuch") "new"))
           (exit status)))))

(define mbsync-timer
  (shepherd-service
    (provision '(mbsync-timer))
    (modules '((shepherd service timer)))
    (start #~(make-timer-constructor
               (calendar-event #:minutes '(0 10 20 30 40 50))
               (command '(#$sync-and-index-mail))
               #:wait-for-termination? #t))
    (stop #~(make-timer-destructor))
    (documentation "Synchronize mail and update the Notmuch index.")))

(home-environment
 ;; Below is the list of packages that will show up in your
 ;; Home profile, under ~/.guix-home/profile.
 (packages
  (append (list
           ;;python-basic-pitch
           codex codex-acp
           colmap         
           ruby-taskjuggler-3.8.4
           tailscale
           ;; python-muscriptor
           gog
           gdrivemd
           audiveris
           ement-e2ee
           ollama
           ollama-shell
           ollama-vulkan
           three-column-tiling
           )
          (specifications->packages
           (list
	    "ungoogled-chromium-wayland"
            "audio-to-midi"
            "btop"
            "cmake"
            ;; "codex-acp"
            "cryptsetup"
            "curl"
            ;; "emacs"
            "emacs-next"
	    ;;"emacs-dash"
            ;;"emacs-guix"
            ;;"emacs-lilypond-mode"
            ;;"emacs-magit"
            ;;"emacs-transient"
	    ;;"emacs-marginalia"
            ;;"emacs-notmuch"
            "emacs-pdf-tools"
            "emacs-org-pdftools"
            "emacs-geiser"
	    "emacs-geiser-guile"
            "emacs-vterm"
            "emacs-whisper-el"
            ;;"emacs-org-ref"
            ;;"emacs-ol-notmuch"
            ;;"emacs-ollama-buddy"
            ;;"emacs-pdf-tools"
            ;;"emacs-vertico"
            "ffmpeg"
            "firefox"
            "fuse"
            "ghostscript"
            "git" 
            "git-filter-repo"
            "gnupg"
            "gnuplot"
            "graphviz"
            "guile"
            "hunspell"
            "hunspell-dict-en"
            "hunspell-dict-fr"
            "imagemagick"
            "isync"
            "libreoffice"
            "lilypond"
            "lshw"
            "mu"
            "musescore"
            ;; "nyxt"
            "nmap"
            "notmuch"
            "obs"
            ;;"ollama-linux-amd64"
            "openconnect"
            "openssh"
            "pandoc"
            ;; "pantalaimon"
            "password-store"
            "perl"
            "pipewire"
            "poppler"
            "pre-commit"
            "python"
            "python-yubikey-manager"
            "qpdf"
            "rclone"
            "rosegarden"
            "rsync"
            ;; "ruby-taskjuggler"
            "siril"
	    "sshfs"
            "stellarium"
            "stow"
	    "tailscale"
            "texlive-scheme-full"
	    "texlive-minted"
	    "python-latexminted"
            "torbrowser"
            ;;"unoconv"
            "unzip"
            "v4l-utils"
            "whisper-cpp"
            "xfig"
            "xournalpp"
            ;; "yubikey-manager-qt"
            "yubikey-personalization"
            "yubikey-oath-dmenu"
            ;; "icecat"
	    "zlib"
            ;; "yubico-pam"
            ;; "flatpak" 
            ;; "cura" "pronterface"
	    ;; "nmap" "gnuradio" "dig" "electronic-lab" ; hack
	    ;; "stellarium" "stellarium-data" "gimp" "siril" ; av
	    ;; "tailscale"
          ))))
  
 ;; Below is the list of Home services.  To search for available
 ;; services, run 'guix home search KEYWORD' in a terminal.
 (services
  (append (list
           (simple-service 'setuid-programs-path
                           home-environment-variables-service-type
                           `(("PATH" . "/run/setuid-programs:$PATH")))
           (service home-bash-service-type
                    (home-bash-configuration
                     (aliases '(("grep" . "grep --color=auto")
                                ("ll" . "ls -l")
                                ("ls" . "ls -p --color=auto")))
                     (bashrc (list (local-file
                                    "/home/holl/.config/guix/.bashrc"
                                    "bashrc")))
                     (bash-profile (list (local-file
                                          "/home/holl/.config/guix/.bash_profile"
                                          "bash_profile")))))
	   (service home-gpg-agent-service-type
	            (home-gpg-agent-configuration
        	     (pinentry-program
	              ;;(file-append pinentry-emacs "/bin/pinentry-emacs"))
                      (file-append pinentry "/bin/pinentry"))
                     (default-cache-ttl 3600)
                     (max-cache-ttl 28800)
	             (ssh-support? #t)))
           (service home-openssh-service-type
                    (home-openssh-configuration
                     (hosts
                      (list (openssh-host (name "github.com")
                                          (identity-file "~/dotfiles/ssh/.ssh/h-oll.github.com")
                                          (user "git")
                                          (control-master 'auto))
                            (openssh-host (name "gist.github.com")
                                          (identity-file "~/dotfiles/ssh/.ssh/h-oll.github.com")
                                          (user "git")
                                          (control-master 'auto))
                            (openssh-host (name "github.com-mantize")
                                          (host-name "github.com")
                                          (identity-file "~/dotfiles/ssh/.ssh/mantitze.github.com")
                                          (user "git")
                                          (control-master 'auto))
                            (openssh-host (name "gitlab.inria.fr")
                                          (identity-file "~/dotfiles/ssh/.ssh/hollivie.gitlab.inria.fr")
                                          (user "git")
                                          (control-master 'auto))
                            (openssh-host (name "calcium.neon-betelgeuse.ts.net")
                                          (identity-file "~/dotfiles/ssh/.ssh/calcium-gitlab")
                                          (user "gitlab")
                                          (control-master 'auto))
                            (openssh-host (name "calcium")
                                          (identity-file "~/dotfiles/ssh/.ssh/calcium-gitlab")
                                          (user "gitlab")
                                          (control-master 'auto))
     			    (openssh-host (name "192.168.1.10")
                                          (identity-file "~/dotfiles/ssh/.ssh/hydrogen-git")
                                          (user "git")
                                          (control-master 'auto))
                            (openssh-host (name "hydrogen.neon-betelgeuse.ts.net")
                                          (identity-file "~/dotfiles/ssh/.ssh/hydrogen-git")
                                          (user "git")
                                          (control-master 'auto))
                            (openssh-host (name "hydrogen.neon-betelgeuse.ts.net")
                                          (identity-file "~/dotfiles/ssh/.ssh/holl@hydrogen")
                                          (user "holl")
                                          (control-master 'auto))
                            (openssh-host (name "100.77.246.103")
                                          (identity-file "~/dotfiles/ssh/.ssh/hydrogen-git")
                                          (user "git")
                                          (control-master 'auto))
     			    (openssh-host (name "codeberg.org")
                                          (identity-file "~/dotfiles/ssh/.ssh/codeberg@potassium")
                                          (user "git")
                                          (control-master 'auto))
                            (openssh-host (name "192.168.2.12")
                                          (identity-file "~/dotfiles/ssh/.ssh/calcium-gitlab")
                                          (user "gitlab")
                                          (control-master 'auto))
                            (openssh-host (name "cleps.inria.fr")
                                          (identity-file "~/dotfiles/ssh/.ssh/hollivie@cleps.inria.fr")
                                          (user "hollivie")
                                          (control-master 'auto))))))

           (simple-service 'mbsync-timer
                home-shepherd-service-type
                (list mbsync-timer))
           (service home-dbus-service-type)
           (service home-pipewire-service-type)
           ;; (service home-dotfiles-service-type
           ;;          (home-dotfiles-configuration
           ;;           (directories '("./test"))
           ;;           (layout 'stow)))
           )
          %base-home-services)))
