;; SPDX-License-Identifier: AGPL-3.0-or-later
;; PLAYBOOK.scm - Operational runbook for avatar-fabrication-facility

(define playbook
  `((version . "1.0.0")
    (procedures
      ((deploy . (("deps" . "just deps")
                  ("build" . "just build")
                  ("test" . "just test")
                  ("lint" . "just lint")
                  ("release" . "just build-release")))
       (quality . (("format" . "just fmt")
                   ("lint" . "just lint")
                   ("test" . "just test")
                   ("coverage" . "just test-coverage")))
       (development . (("dev" . "just dev")
                       ("watch" . "just build-watch")
                       ("repl" . "just repl")))
       (security . (("audit" . "just deps-audit")
                    ("sbom" . "just sbom")
                    ("scan" . "just security")))
       (rollback . (("clean" . "just clean")
                    ("git-reset" . "git checkout .")))
       (debug . (("verbose-test" . "just test-verbose")
                 ("repl" . "just repl")))))
    (alerts . ())
    (contacts . ())))
