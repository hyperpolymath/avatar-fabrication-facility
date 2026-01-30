;; SPDX-License-Identifier: PMPL-1.0-or-later
;; STATE.scm - Project state for avatar-fabrication-facility

(state
  (metadata
    (version "0.1.0")
    (schema-version "1.0")
    (created "2024-06-01")
    (updated "2025-01-16")
    (project "avatar-fabrication-facility")
    (repo "hyperpolymath/avatar-fabrication-facility"))

  (project-context
    (name "Avatar Fabrication Facility")
    (tagline "Project specification pending")
    (tech-stack ("rust" "rescript" "gleam" "elixir" "julia" "deno")))

  (current-position
    (phase "initialization")
    (overall-completion 10)
    (components
      ((infrastructure . 100)
       (specification . 0)
       (implementation . 0)))
    (working-features
      ("RSR-compliant justfile"
       "CI/CD pipeline (16 workflows)"
       "Machine-readable metadata"
       "Documentation templates")))

  (route-to-mvp
    (milestones
      ((name "Specification")
       (status "pending")
       (items
         ("Define project purpose"
          "Architecture design"
          "Tech stack selection")))
      ((name "Foundation")
       (status "pending")
       (items
         ("Core implementation"
          "Tests"
          "Documentation")))
      ((name "MVP")
       (status "pending")
       (items
         ("Working prototype"
          "User documentation"
          "Release")))))

  (blockers-and-issues
    (critical
      (("Specification" . "Project specification not yet uploaded")))
    (high ())
    (medium ())
    (low ()))

  (critical-next-actions
    (immediate
      ("Upload project specification"))
    (this-week
      ("Define architecture and objectives"))
    (this-month
      ("Begin Phase 1 (Foundation)"))))
