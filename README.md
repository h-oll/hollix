# hollix

Personal GNU Guix channel for custom packages and selected newer variants.
Packages are exported under `(hollix ...)` and selected explicitly; this
channel does not shadow Guix packages by default.

## Using the channel

The channel is authenticated through its `keyring` branch. Add the channel
record below to `~/.config/guix/channels.scm` (retain any other channels you
already use):

```scheme
(cons (channel
       (name 'hollix)
       (url "https://codeberg.org/holl/hollix.git")
       (introduction
        (make-channel-introduction
         "b021b684b97c26f4368cd11d7a96ff0585fa9623"
         (openpgp-fingerprint
          "3D44 1408 48F7 C50F A1C9  889A E1B0 E029 62C1 D611"))))
      %default-channels)
```

Then run `guix pull`. To evaluate a package from this checkout without
installing the channel, use `guix show -L . PACKAGE` or `guix build -L .
PACKAGE`. The package names and bindings below identify which variant to
select.

## Package modules

### `(hollix packages audiveris)` — `hollix/packages/audiveris.scm`

- **Upstream:** [Audiveris](https://github.com/Audiveris/audiveris), an optical
  music recognition application that converts sheet music images to notation
  and MusicXML.
- **Packaged version:** `audiveris` 5.11.0.
- **Scheme code:** repacks the upstream Linux `.deb`, retains the required Java
  and OCR payload, relocates files and native libraries for Guix, and supplies
  a launcher and desktop entry. The current upstream payload is x86_64-specific.
- **Updating:** select a matching upstream `.deb`, update its fixed-output hash,
  and recheck the archive layout, native-library references, launcher, and
  desktop entry. Build and launch-test the package.

### `(hollix packages basic-pitch)` — `hollix/packages/basic-pitch.scm`

- **Upstream:** [Spotify Basic Pitch](https://github.com/spotify/basic-pitch),
  for audio-to-MIDI transcription, and [Pretty MIDI](https://github.com/craffel/pretty-midi),
  a MIDI utility library.
- **Packaged versions:** `python-basic-pitch` 0.4.0; `python-pretty-midi`
  0.2.11.post0.
- **Scheme code:** defines the Python packages and their dependency metadata;
  Pretty MIDI is included because it is not available in the Guix revision
  targeted by this channel. Basic Pitch uses the Linux TensorFlow Lite runtime;
  other upstream inference backends are not packaged here.
- **Updating:** update the source version and hash for each changed release,
  reconcile Python runtime dependencies and test requirements, then build and
  smoke-test `basic-pitch --help`. The upstream test suites require optional
  data or inference setup and are disabled in these definitions.

### `(hollix packages canorus)` — `hollix/packages/canorus.scm`

- **Upstream:** [Canorus](https://github.com/canorusmusic/canorus), a graphical
  music score editor.
- **Packaged version:** `0.7.3rc3`.
- **Scheme code:** builds the upstream CMake project against Guix's Qt 5
  packages. Canorus installs its toolbar artwork under `share/canorus/images`
  and refers to those files through Qt search paths. The launcher is Qt-wrapped
  so Qt can find the SVG icon plugin supplied by `qtsvg`; without that plugin,
  SVG toolbar icons can appear blank. The desktop entry and application icon
  are installed separately. The release's legacy SWIG detection found no
  usable executable in the Guix build environment, so optional Python/Ruby
  scripting modules are disabled. Qt WebEngine is also optional upstream and
  is not enabled in this package.
- **Updating:** update the pinned source version and hash together. Recheck the
  Qt 5 module requirements, Python/SWIG support, installed resources, and
  desktop integration.

### `(hollix packages codex)` — `hollix/packages/codex.scm`

- **Upstream:** [OpenAI Codex](https://github.com/openai/codex), a coding agent
  with terminal and editor workflows.
- **Packaged versions:** `codex` defaults to 0.172.0; `codex@0.171.0`,
  `codex@0.170.0`,
  `codex@0.169.0`, `codex@0.167.1`, and `codex@0.165.0` remain selectable.
  All versions enable the V8-backed code-mode path.
- **Scheme code:** uses a static offline Cargo input table per Codex release,
  Rust 1.95, pinned local workspace sources, and the V8-backed code-mode path
  by default. Earlier source archives and crate tables remain in versioned
  modules.
- **Selecting a version:** use `guix build -L . codex@0.171.0`,
  `guix build -L . codex@0.170.0`,
  `guix build -L . codex@0.169.0`, `guix build -L . codex@0.167.1`, or
  `guix build -L . codex@0.165.0` for retained releases, or `guix build -L .
  codex` for the default.
- **Updating:** update the source version and hash, matching
  `hollix/packages/codex-Cargo.lock` and its release snapshot
  `hollix/packages/codex-0.169.0-Cargo.lock`, and generated table in
  `hollix/packages/codex-cargo-inputs-169.scm` together. Review Git dependencies,
  workspace/source adapters, executable names, and install paths; evaluate and
  fully build both variants. Do not generate Cargo inputs dynamically while
  Guix loads the package module: `guix pull` may evaluate it without a daemon
  socket.

Codex's static crate table requires several source adapters (including
`nucleo`, `runfiles`, `h3`, and the `mxc-sdk` workspace crates). The `mxc`
source remains a separate fixed input because its workspace dependencies
require the upstream workspace root. Review and preserve these adaptations
when regenerating the table. The build also removes Cargo patch tables,
replaces workspace Git dependencies with fixed vendored inputs, regenerates
`Cargo.lock` offline, and disables the generic pre-generated-file scan because
the vendored tree contains upstream binary fixtures.

- **Build and smoke check:** Codex 0.169.0 built successfully with
  `--max-silent-time=36000`; `codex --version` reports `codex-cli 0.169.0`.
  Codex 0.171.0 and 0.172.0 also build; `codex --version` reports their
  matching versions. Codex 0.167.1 also built previously, and its
  version-tagged package still resolves. The install phase copies the
  already-built workspace binaries to avoid recompiling each package
  separately and exhausting temporary storage.

### `(hollix packages codex-acp)` — `hollix/packages/codex-acp.scm`

- **Upstream:** [Codex ACP](https://github.com/agentclientprotocol/codex-acp),
  an Agent Client Protocol adapter for Codex.
- **Packaged versions:** `codex-acp` defaults to 2.12.1; `codex-acp@2.8.0`,
  `codex-acp@2.7.0`, and Guix's older `codex-acp@2.3.0` remain selectable.
- **Scheme code:** packages the published npm JavaScript bundle and fixed Node
  dependencies, including `cross-spawn`, removes its bundled `@openai/codex`,
  and wraps the executable so `CODEX_PATH` selects this channel's `codex`
  package. ACP 2.12.1 uses ACP SDK 2.9.1; ACP 2.8.0 retains SDK 2.8.0 and ACP
  2.7.0 retains its SDK 2.6.0 and
  Codex 0.170.0 dependency set.
- **Selecting a version:** use `guix build -L . codex-acp@2.8.0`,
  `guix build -L . codex-acp@2.7.0` or
  `guix build -L . codex-acp@2.3.0` for retained releases, or
  `guix build -L . codex-acp` for the default.
- **Updating:** compare the release's npm runtime dependency metadata with the
  channel's Node package definitions; update the release tarball hash and any
  changed dependency graph. Build `codex-acp` and verify it resolves the
  channel's Codex executable.
- **Build and smoke check:** ACP 2.12.1, 2.8.0, and 2.7.0 all build;
  `codex-acp --version` reports each matching version. The 2.3.0 package
  resolves through its version selector.

### `(hollix packages claude-code)` — `hollix/packages/claude-code.scm`

- **Upstream:** [Claude Code](https://github.com/anthropics/claude-code),
  Anthropic's terminal coding agent.
- **Packaged versions:** `claude-code` defaults to 2.1.332 for x86-64
  GNU/Linux; `claude-code@2.1.330` and `claude-code@2.1.327` preserve prior
  releases.
- **Scheme code:** installs Anthropic's fixed native release binary directly;
  it does not run the network installer. The launcher sets
  `DISABLE_AUTOUPDATER=1`. Anthropic's CLI is proprietary and has no
  Guix-recognized free software license.
- **Selecting a version:** use `guix build -L . claude-code@2.1.330` or
  `guix build -L . claude-code@2.1.327` to select a retained release.
- **Updating:** update the version and the matching Linux x64 checksum from
  Anthropic's release manifest together. Review the binary's interpreter and
  runtime library requirements; evaluate and build the package.
- **Build and smoke check:** versions 2.1.332, 2.1.330, and 2.1.327 build and
  pass `claude --version`; 2.1.332 also passes `claude --help`.

### `(hollix packages claude-code-acp)` — `hollix/packages/claude-code-acp.scm`

- **Upstream:** [Claude Agent ACP](https://github.com/agentclientprotocol/claude-agent-acp),
  an Agent Client Protocol adapter for Claude Code.
- **Packaged versions:** `claude-code-acp` defaults to 0.113.0 for x86-64
  GNU/Linux; versions 0.109.0 and 0.108.0 remain selectable with matching CLI
  dependencies.
- **Scheme code:** installs the standalone ACP server from its fixed release
  archive and selects this channel's `claude-code` through
  `CLAUDE_CODE_EXECUTABLE`. The archive's bundled Claude CLI is not installed.
  The wrapper sets `DISABLE_AUTOUPDATER=1` for the CLI it starts.
- **Selecting a version:** use `guix build -L . claude-code-acp@0.109.0` or
  `guix build -L . claude-code-acp@0.108.0` to select a retained ACP server
  and its matching Claude Code dependency.
- **Updating:** update the release version and archive SHA-256 together. Check
  the standalone archive layout, its runtime libraries, and compatibility with
  the channel's Claude Code; evaluate and build both packages.
- **Build and smoke check:** versions 0.113.0, 0.109.0, and 0.108.0 build and
  report their matching versions. No authenticated Claude session was started.

### `(hollix packages ement-e2ee)` — `hollix/packages/ement-e2ee.scm`

- **Upstream:** [bhwdev/ement-e2ee](https://github.com/bhwdev/ement-e2ee), a
  local Matrix proxy that adds end-to-end encryption support to Ement.el.
- **Packaged version:** snapshot `0.1.0-0.20261013.7075a0e`, pinned to upstream
  commit `7075a0e9e1a18f088a6faf1cc280530df4c826ce`.
- **Scheme code:** builds the Rust CLI with Rust 1.93 and the registry
  dependencies in the matching `Cargo.lock`. Upstream's MIT license applies.
- **Updating:** update the source commit, hash, version, and
  `hollix/packages/ement-e2ee-Cargo.lock` together. Recheck the Rust minimum,
  Cargo sources, executable, and service interface.

### `(hollix services ement-e2ee)` — `hollix/services/ement-e2ee.scm`

This module defines `ement-e2ee-service-type` for Guix Home. It installs the
package in the Home profile and runs `ement-e2ee serve` under the user's
Shepherd. The default `~/.config/ement-e2ee/config.toml` must exist and name a
Matrix homeserver before the service starts. Set `config-file` to use a
different path. Extra service arguments follow the optional config argument.
With `config-file` unset, the program uses its default configuration path.

Example service entry in a Guix Home configuration:

```scheme
(use-modules (hollix services ement-e2ee))

(service ement-e2ee-service-type
         (ement-e2ee-configuration))
```

### `(hollix packages emacs)` — `hollix/packages/emacs.scm` (disabled)

- **Upstream:** [GNU Emacs](https://www.gnu.org/software/emacs/), a
  customizable text editor.
- **Status:** the local `emacs-31.1` definition is commented out; use Guix's
  Emacs package instead.

### `(hollix packages gog)` — `hollix/packages/gog.scm`

- **Upstreams:** [gog](https://github.com/openclaw/gogcli), a Google Workspace
  CLI; and [gdrivemd](https://github.com/zonca/gdrivemd), scripts for syncing
  Google Docs and Markdown.
- **Packaged versions:** `gog` defaults to 0.48.1; `gog@0.48.0` and
  `gog@0.47.1` remain available. `gdrivemd` is from commit `c30910a` and
  follows the default Gog.
- **Scheme code:** retains the 0.47.1 Go dependency set and builds 0.48.0 and
  0.48.1 from pinned sources with fixed vendor snapshots generated from each
  release's module graph. Both use Guix's Go 1.27 toolchain, and Go dependencies
  remain build-only. The module also builds the `gdrivemd` scripts and wraps
  them to invoke the default packaged `gog` binary. OAuth credentials and tokens
  are user data and are not included.
- **Selecting a version:** use `guix build -L . gog@0.48.0` or
  `guix build -L . gog@0.47.1` for retained packages, or
  `guix build -L . gog` for the default.
- **Build and smoke check:** Gog 0.48.1 builds; `gog --version` reports
  `v0.48.1`. The 0.48.0 and 0.47.1 bindings resolve.
- **Updating:** bump the pinned source revision and hash, reconcile `go.mod`
  dependencies and embedded assets, and keep the Go toolchain local to the
  declared version. Update and test `gdrivemd` separately. Its source currently
  has no declared license in the package definition (`#f`); resolve the license
  before redistributing it beyond the intended private channel.

OAuth setup for `gdrivemd` use:

```sh
gog auth setup
gog auth add you@example.com --services=docs,drive
gog auth status
pull_from_gdoc DOCUMENT_ID local-file.md
push_to_gdoc local-file.md DOCUMENT_ID replace  # or append
```

### `(hollix packages gws)` — `hollix/packages/gws.scm`

- **Upstream:** [Google Workspace CLI](https://github.com/googleworkspace/cli),
  a command-line client for Google Workspace.
- **Packaged version:** `gws` 0.22.5.
- **Scheme code:** builds the Rust application from a pinned tag and embeds its
  Cargo lockfile through the channel's lockfile helper so package evaluation
  does not rely on a sidecar file being installed with the module. The package
  uses `libsecret` at runtime.
- **Updating:** update the source reference and hash, refresh the committed
  `gws-Cargo.lock` and corresponding dependency data together, and verify
  module evaluation plus a build. Keep lockfile embedding synchronized with
  the source release.

### `(hollix packages muscriptor)` — `hollix/packages/muscriptor.scm`

- **Upstreams:** [MuScriptor](https://github.com/muscriptor/muscriptor),
  [Beat This](https://github.com/CPJKU/beat_this), and
  [rotary-embedding-torch](https://github.com/lucidrains/rotary-embedding-torch).
- **Packaged versions:** `python-muscriptor` defaults to 0.4.0, with
  `python-muscriptor@0.3.0` retained; `python-beat-this` 1.1.0;
  `python-rotary-embedding-torch` 0.9.1. Both MuScriptor versions use the
  local `python-soundfile` 0.14.0 variant. Hollix's torchaudio variant also
  uses 0.14.0. Install the `muscriptor` CLI package in shared profiles; it
  keeps Python dependencies out of the profile union, avoiding collisions with
  other channels that provide SoundFile 0.13.x.
- **Scheme code:** defines MuScriptor and its Python dependencies, including a
  torchaudio variant aligned to SoundFile 0.14.0. MuScriptor performs
  multi-instrument music transcription. Model weights are not packaged;
  downloading them requires Hugging Face authentication and acceptance of
  their separate CC BY-NC 4.0 terms. Sheet output optionally requires
  MuseScore 4 or newer.
- **Updating:** update each changed Python release and source hash, reconcile
  the dependency chain, then build and test the CLI. Keep model weights and
  their separate terms out of the package unless their distribution terms
  change and are reviewed.
- **Selecting a version:** use `guix build -L . python-muscriptor@0.3.0` for
  the retained version or `guix build -L . python-muscriptor` for the default.

### `(hollix packages ollama)` — `hollix/packages/ollama.scm`

- **Upstream:** [Ollama](https://github.com/ollama/ollama), for running large
  language models locally.
- **Packaged versions:** `ollama` defaults to 0.40.19; `ollama@0.40.17`,
  `ollama@0.40.16`, and `ollama@0.40.14` remain available.
- **Scheme code:** repacks the official x86-64 Linux release archive, patches
  dynamic executables for Guix's loader, and provides a launcher for the
  bundled CPU and CUDA runners. NVIDIA GPU use requires a compatible host
  driver; AMD ROCm runners are not included. Model files are downloaded at
  runtime.
- **Updating:** update the release version and archive hash together. Check
  the archive layout, executable and runner paths, and shared-library
  requirements; build the package and smoke-test the CLI and server startup.
- **Selecting a version:** use `guix build -L . ollama@0.40.17`,
  `guix build -L . ollama@0.40.16` or
  `guix build -L . ollama@0.40.14` for retained definitions, or
  `guix build -L . ollama` for the default.
- **Build and smoke check:** versions 0.40.19, 0.40.17, 0.40.16, and 0.40.14
  build from the upstream x86-64 archives. `ollama --version` reports each
  matching version and notes when no local server is running.

### `(hollix packages ollama-shell)` — `hollix/packages/ollama-shell.scm`

- **Upstream:** [Ollama Shell](https://github.com/sunkencity999/ollama_shell),
  a Python command-line agent for a local Ollama server.
- **Packaged version:** `ollama-shell` 0.2.0, pinned to its upstream tag.
- **Scheme code:** builds the Hatchling project with its core CLI dependencies
  and Textual interface. The `ddgs` dependency is not available in Guix and is
  removed from package metadata; `web_search` is unavailable, while page
  fetching remains available. Ollama itself must be installed separately;
  optional integrations and model downloads are not packaged.
- **Updating:** update the source tag, commit, and fixed-output hash together.
  Recheck project dependencies and optional feature imports; build the package
  and smoke-test `oshell --help`.

### `(hollix packages ollama-vulkan)` — `hollix/packages/ollama-vulkan.scm`

- **Upstream:** uses the channel's `ollama` package and its bundled Vulkan
  backend.
- **Packaged version:** follows the default `ollama` package, currently 0.40.19.
- **Scheme code:** wraps Ollama with Vulkan enabled by default and adds Guix's
  `vulkan-loader` and Mesa runtime. Mesa provides the Intel ANV Vulkan ICD for
  Iris Xe. The Vulkan SDK headers and tools are available from Guix but are not
  runtime requirements for this prebuilt backend. `nonguix`'s Intel media
  driver is for VA-API and is not required for Vulkan.
- **Using:** install `ollama-vulkan` and start `ollama serve`; model downloads
  and inference still require a local model and accessible `/dev/dri` device.
  `OLLAMA_VULKAN`, `OLLAMA_LLM_LIBRARY`, `OLLAMA_IGPU_ENABLE`, and
  `VK_DRIVER_FILES` may be set to override the launcher defaults.
- **Updating:** keep the base Ollama version and Vulkan backend compatible.
  Check Mesa's Intel ICD manifest path and loader environment variables, build
  the package, and verify Vulkan device discovery on the target hardware.

### `(hollix packages pass-secret-service)` — `hollix/packages/pass-secret-service.scm`

- **Upstream:** [Pass Secret Service](https://github.com/grimsteel/pass-secret-service),
  an implementation of the D-Bus Secret Service API backed by password-store
  format files.
- **Packaged version:** `pass-secret-service` 0.7.1, pinned to the upstream
  release archive with its Cargo dependency graph taken from the release lockfile.
- **Runtime:** GnuPG is included for secret encryption/decryption. Secret data
  remains in the user's `~/.password-store/secret-service` directory; this
  package does not include password-store data or GPG credentials. The package
  installs a session D-Bus activation definition for `org.freedesktop.secrets`.
- **Using:** install `pass-secret-service` in the user profile. Ensure the
  password-store directory has a valid `.gpg-id` and that a D-Bus session is
  available before an application requests the Secret Service API.
- **Updating:** update the release version and source hash together, copy the
  matching `Cargo.lock`, and rebuild the package with its full locked crate
  closure.

### `(hollix packages photogrammetry)` — `hollix/packages/photogrammetry.scm`

- **Upstreams:** [PoseLib](https://github.com/PoseLib/PoseLib), calibrated pose
  estimators; and [COLMAP](https://github.com/colmap/colmap), a structure-from-
  motion and multi-view-stereo application.
- **Packaged versions:** `poselib` 2.0.5 at commit `fa7280f`; `colmap` 4.2.1.
- **Scheme code:** builds both CMake projects. PoseLib is pinned to the
  revision COLMAP expects. COLMAP's GUI build disables unavailable optional
  dependencies and network fallbacks, and applies local fixes for MVS linking,
  shared-library placement, RUNPATH, and its desktop entry.
- **Updating:** check COLMAP's required PoseLib revision, update both source
  pins and hashes as needed, and revalidate each local patch. Configure and
  build without network access, then test the GUI/package outputs.

### `(hollix packages minecraft-rl)` — `hollix/packages/minecraft-rl.scm`

- **Upstream:** [Stable-Baselines3](https://github.com/DLR-RM/stable-baselines3),
  PyTorch implementations of reinforcement-learning algorithms.
- **Packaged version:** `python-stable-baselines3` 2.9.2.
- **Scheme code:** adds the missing Python package using Guix's Gymnasium,
  NumPy, CPU PyTorch, and cloudpickle packages as propagated runtime inputs.
- **Consumer project:** project-specific manifests, npm lockfiles, and smoke
  checks are maintained outside this channel repository.
- **Updating:** verify SB3's Python, Gymnasium, NumPy, and PyTorch requirements;
  update the fixed PyPI source hash and manifest versions together, then build
  the package and run the experiment's CPU smoke check.

### `(hollix packages tailscale)` — `hollix/packages/tailscale.scm`

- **Upstream:** [Tailscale](https://github.com/tailscale/tailscale), a mesh
  VPN client and daemon.
- **Packaged versions:** `tailscale` and `tailscaled` default to 1.104.7;
  version 1.104.5 remains available for both packages.
- **Scheme code:** builds the CLI and daemon from one fixed, vendored Go source
  snapshot; their commands are separate packages. Version 1.104.7 requires
  Go 1.27.4, supplied by a local variant of Guix's Go package.
- **Updating:** update the release revision, source hash, vendored-tree hash,
  Go module dependencies, and toolchain requirement together. Rebuild both
  packages and check the daemon's runtime behavior.
- **Selecting a version:** use `guix build -L . tailscale@1.104.5` or
  `guix build -L . tailscaled@1.104.5` for the retained definitions. The
  unqualified package names select 1.104.7.

### `(hollix packages taskjuggler)` — `hollix/packages/taskjuggler.scm`

- **Upstream:** [TaskJuggler](https://github.com/taskjuggler/TaskJuggler), a
  project scheduling and resource-management tool.
- **Packaged version:** `ruby-taskjuggler-3.8.4` 3.8.4.
- **Scheme code:** inherits Guix's TaskJuggler package and adds WEBrick 1.9.1,
  the runtime version required by this release. It removes an inherited test
  phase that refers to a file absent from the newer source.
- **Updating:** bump the gem source and hash, check whether the WEBrick
  dependency or phase workaround is still needed, and verify the executable
  with `tj3 --version` after building.

### `(hollix services tailscale)` — `hollix/services/tailscale.scm`

- **Upstream:** [Tailscale](https://github.com/tailscale/tailscale); this is a
  service definition, not a separately versioned upstream application.
- **Version:** follows the channel's default `tailscaled` package, currently
  1.104.7.
- **Scheme code:** defines `tailscale-service-type`, which starts the packaged
  daemon under Shepherd and configures its state directory, extra arguments,
  and optional log file.
- **Updating:** review this service when the daemon command-line interface or
  Guix Shepherd/service APIs change. Validate a generated system configuration
  and activation behavior after changes.

Example service configuration:

```scheme
(use-modules (hollix services tailscale))

(service tailscale-service-type
         (tailscale-configuration
          (state-directory "/var/lib/tailscale")
          (extra-arguments '("--port=41641"))
          (log-file "/var/log/tailscaled.log")))
```

## Support modules

### `(hollix packages codex-cargo-inputs-169)` — `hollix/packages/codex-cargo-inputs-169.scm`

This generated helper exports Codex's static Cargo input table. It has no
independent upstream version: regenerate it from the exact `Cargo.lock` for the
Codex release being packaged, then review and retain required source adapters.
See the Codex update notes above.

### `(hollix packages lockfile)` — `hollix/packages/lockfile.scm`

This internal helper embeds a sibling lockfile into a module at load time,
avoiding reliance on arbitrary sidecar files being present in a channel module
cache. It has no upstream application or version. Change it only if Guix's
channel-module loading behavior requires it; when its embedded data changes,
keep the lockfile synchronized with the package source.

## Validation

Evaluate and build packages from this checkout with `guix -L .`; `-n` performs
a dry run and does not establish that the build succeeds. For example:

```sh
guix show -L . codex
guix build -L . -e '(@ (hollix packages codex) codex)' -n
guix build -L . -e '(@ (hollix packages codex) codex)'
guix shell -L . audiveris -- audiveris -help
guix shell -L . python-basic-pitch -- basic-pitch --help
guix shell -L . ollama -- ollama --version
guix build -L . ollama@0.40.14
guix build -L . tailscale
guix build -L . tailscale@1.104.5
guix build -L . tailscaled
guix build -L . tailscaled@1.104.5
guix build -L . gog
guix build -L . gog@0.47.1
guix shell -L . ollama-shell -- oshell --help
guix build -L . -e '(@ (hollix packages ollama-vulkan) ollama-vulkan)'
guix build -L . -e '(@ (hollix packages minecraft-rl) python-stable-baselines3)'
guix shell -L . ruby-taskjuggler-3.8.4 -- tj3 --version
```

For other modules, use the package names or module bindings listed above.
When recording verification, distinguish evaluation, dry-run, completed build,
and runtime smoke test; passing one does not imply the others.
