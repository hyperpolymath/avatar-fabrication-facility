;; SPDX-License-Identifier: PMPL-1.0-or-later
;; AGENTIC.scm - AI agent interaction patterns for avatar-fabrication-facility

(define agentic-config
  `((version . "1.0.0")
    (claude-code
      ((model . "claude-opus-4-5-20251101")
       (tools . ("read" "edit" "bash" "grep" "glob"))
       (permissions . "read-all")))
    (patterns
      ((code-review . "thorough")
       (refactoring . "conservative")
       (testing . "comprehensive")))
    (constraints
      ((languages . ("rust" "rescript" "gleam" "elixir" "julia" "deno" "bash" "guile-scheme" "nickel" "ocaml" "ada"))
       (banned . ("typescript" "go" "python" "makefile" "nodejs" "npm" "bun" "pnpm" "yarn" "java" "kotlin" "swift" "dart" "flutter"))))))
