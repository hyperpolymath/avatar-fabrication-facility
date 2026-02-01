;; SPDX-License-Identifier: PMPL-1.0-or-later
;; META.scm - Meta-level information for avatar-fabrication-facility
;; Media-Type: application/meta+scheme

(meta
  (architecture-decisions
    (("ADR-001" . "Multi-language auto-detection in justfile")
     ("ADR-002" . "RSR language policy enforcement")))

  (development-practices
    (code-style
      ("rust-fmt" "gleam-format" "deno-fmt" "mix-format"))
    (security
      (principle "Defense in depth")
      (practices
        ("SHA256+ for hashing"
         "HTTPS only"
         "No hardcoded secrets"
         "SHA-pinned dependencies")))
    (testing
      ("cargo test" "deno test" "gleam test" "mix test"))
    (versioning "SemVer")
    (documentation "AsciiDoc")
    (branching "main for stable")
    (package-management
      ("guix" "nix-flakes" "deno-imports")))

  (design-rationale
    (("justfile-auto-detect" . "Supports Rust, ReScript, Gleam, Elixir, Deno, Julia with automatic detection")
     ("no-python" . "RSR policy bans Python; use Julia/Rust/ReScript instead")
     ("no-typescript" . "RSR policy bans TypeScript; use ReScript instead")
     ("deno-over-node" . "Deno replaces Node.js/npm/bun per RSR policy"))))
