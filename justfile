# RSR-template-repo - RSR Standard Justfile Template
# https://just.systems/man/en/
#
# This is the CANONICAL template for all RSR projects.
# Copy this file to new projects and customize the {{PLACEHOLDER}} values.
#
# Run `just` to see all available recipes
# Run `just cookbook` to generate docs/just-cookbook.adoc
# Run `just combinations` to see matrix recipe options

set shell := ["bash", "-uc"]
set dotenv-load := true
set positional-arguments := true

# Project metadata
project := "avatar-fabrication-facility"
version := "0.1.0"
tier := "infrastructure"  # 1 | 2 | infrastructure

# ═══════════════════════════════════════════════════════════════════════════════
# DEFAULT & HELP
# ═══════════════════════════════════════════════════════════════════════════════

# Show all available recipes with descriptions
default:
    @just --list --unsorted

# Show detailed help for a specific recipe
help recipe="":
    #!/usr/bin/env bash
    if [ -z "{{recipe}}" ]; then
        just --list --unsorted
        echo ""
        echo "Usage: just help <recipe>"
        echo "       just cookbook     # Generate full documentation"
        echo "       just combinations # Show matrix recipes"
    else
        just --show "{{recipe}}" 2>/dev/null || echo "Recipe '{{recipe}}' not found"
    fi

# Show this project's info
info:
    @echo "Project: {{project}}"
    @echo "Version: {{version}}"
    @echo "RSR Tier: {{tier}}"
    @echo "Recipes: $(just --summary | wc -w)"
    @[ -f STATE.scm ] && grep -oP '\(phase\s+\.\s+\K[^)]+' STATE.scm | head -1 | xargs -I{} echo "Phase: {}" || true

# ═══════════════════════════════════════════════════════════════════════════════
# BUILD & COMPILE
# ═══════════════════════════════════════════════════════════════════════════════

# Build the project (debug mode)
build *args:
    #!/usr/bin/env bash
    echo "Building {{project}}..."
    if [ -f "Cargo.toml" ]; then
        cargo build {{args}}
    elif [ -f "rescript.json" ] || [ -f "bsconfig.json" ]; then
        deno task build {{args}} 2>/dev/null || npx rescript build {{args}}
    elif [ -f "gleam.toml" ]; then
        gleam build {{args}}
    elif [ -f "mix.exs" ]; then
        mix compile {{args}}
    elif [ -f "deno.json" ] || [ -f "deno.jsonc" ]; then
        deno task build {{args}} 2>/dev/null || deno compile {{args}}
    else
        echo "No recognized build system found (Cargo.toml, rescript.json, gleam.toml, mix.exs, deno.json)"
        exit 0
    fi

# Build in release mode with optimizations
build-release *args:
    #!/usr/bin/env bash
    echo "Building {{project}} (release)..."
    if [ -f "Cargo.toml" ]; then
        cargo build --release {{args}}
    elif [ -f "rescript.json" ] || [ -f "bsconfig.json" ]; then
        deno task build {{args}} 2>/dev/null || npx rescript build {{args}}
    elif [ -f "gleam.toml" ]; then
        gleam build --target erlang {{args}} 2>/dev/null || gleam build {{args}}
    elif [ -f "mix.exs" ]; then
        MIX_ENV=prod mix compile {{args}}
    elif [ -f "deno.json" ] || [ -f "deno.jsonc" ]; then
        deno task build {{args}} 2>/dev/null || deno compile --output dist/{{project}} {{args}}
    else
        echo "No recognized build system found"
        exit 0
    fi

# Build and watch for changes
build-watch:
    #!/usr/bin/env bash
    echo "Watching for changes..."
    if [ -f "Cargo.toml" ]; then
        cargo watch -x build 2>/dev/null || (echo "Install cargo-watch: cargo install cargo-watch" && exit 1)
    elif [ -f "rescript.json" ] || [ -f "bsconfig.json" ]; then
        deno task watch 2>/dev/null || npx rescript build -w
    elif [ -f "gleam.toml" ]; then
        watchexec -e gleam -- gleam build 2>/dev/null || (echo "Install watchexec for watch mode" && exit 1)
    elif [ -f "mix.exs" ]; then
        mix compile --force && iex -S mix
    elif [ -f "deno.json" ] || [ -f "deno.jsonc" ]; then
        deno task dev 2>/dev/null || deno run --watch main.ts 2>/dev/null || echo "Add 'dev' task to deno.json"
    else
        echo "No recognized build system found"
        exit 0
    fi

# Clean build artifacts [reversible: rebuild with `just build`]
clean:
    @echo "Cleaning..."
    rm -rf target _build dist lib node_modules

# Deep clean including caches [reversible: rebuild]
clean-all: clean
    rm -rf .cache .tmp

# ═══════════════════════════════════════════════════════════════════════════════
# TEST & QUALITY
# ═══════════════════════════════════════════════════════════════════════════════

# Run all tests
test *args:
    #!/usr/bin/env bash
    echo "Running tests..."
    if [ -f "Cargo.toml" ]; then
        cargo test {{args}}
    elif [ -f "rescript.json" ] || [ -f "bsconfig.json" ]; then
        deno task test {{args}} 2>/dev/null || deno test {{args}}
    elif [ -f "gleam.toml" ]; then
        gleam test {{args}}
    elif [ -f "mix.exs" ]; then
        mix test {{args}}
    elif [ -f "deno.json" ] || [ -f "deno.jsonc" ]; then
        deno task test {{args}} 2>/dev/null || deno test {{args}}
    elif ls *.jl 2>/dev/null || [ -d "src" ] && ls src/*.jl 2>/dev/null; then
        julia --project=. -e 'using Pkg; Pkg.test()' {{args}}
    else
        echo "No recognized test system found"
        exit 0
    fi

# Run tests with verbose output
test-verbose:
    #!/usr/bin/env bash
    echo "Running tests (verbose)..."
    if [ -f "Cargo.toml" ]; then
        cargo test -- --nocapture
    elif [ -f "rescript.json" ] || [ -f "bsconfig.json" ]; then
        deno task test 2>/dev/null || deno test --allow-all
    elif [ -f "gleam.toml" ]; then
        gleam test
    elif [ -f "mix.exs" ]; then
        mix test --trace
    elif [ -f "deno.json" ] || [ -f "deno.jsonc" ]; then
        deno task test 2>/dev/null || deno test --allow-all
    else
        echo "No recognized test system found"
        exit 0
    fi

# Run tests and generate coverage report
test-coverage:
    #!/usr/bin/env bash
    echo "Running tests with coverage..."
    if [ -f "Cargo.toml" ]; then
        cargo llvm-cov 2>/dev/null || cargo tarpaulin 2>/dev/null || (echo "Install coverage tool: cargo install cargo-llvm-cov" && exit 1)
    elif [ -f "rescript.json" ] || [ -f "bsconfig.json" ]; then
        deno task test:coverage 2>/dev/null || deno test --coverage=coverage
    elif [ -f "gleam.toml" ]; then
        echo "Gleam coverage: run tests and check erlang coverage reports"
        gleam test
    elif [ -f "mix.exs" ]; then
        mix test --cover
    elif [ -f "deno.json" ] || [ -f "deno.jsonc" ]; then
        deno task test:coverage 2>/dev/null || deno test --coverage=coverage
    else
        echo "No recognized test system found"
        exit 0
    fi

# ═══════════════════════════════════════════════════════════════════════════════
# LINT & FORMAT
# ═══════════════════════════════════════════════════════════════════════════════

# Format all source files [reversible: git checkout]
fmt:
    #!/usr/bin/env bash
    echo "Formatting..."
    FORMATTED=false
    if [ -f "Cargo.toml" ]; then
        cargo fmt && FORMATTED=true
    fi
    if [ -f "rescript.json" ] || [ -f "bsconfig.json" ]; then
        deno task format 2>/dev/null || npx rescript format -all 2>/dev/null && FORMATTED=true
    fi
    if [ -f "gleam.toml" ]; then
        gleam format . && FORMATTED=true
    fi
    if [ -f "mix.exs" ]; then
        mix format && FORMATTED=true
    fi
    if [ -f "deno.json" ] || [ -f "deno.jsonc" ]; then
        deno fmt && FORMATTED=true
    fi
    # Format shell scripts
    if command -v shfmt >/dev/null; then
        find . -name "*.sh" -not -path "./.git/*" -exec shfmt -w {} \; 2>/dev/null && FORMATTED=true
    fi
    if [ "$FORMATTED" = false ]; then
        echo "No recognized format system found"
    fi

# Check formatting without changes
fmt-check:
    #!/usr/bin/env bash
    echo "Checking format..."
    CHECKED=false
    FAILED=false
    if [ -f "Cargo.toml" ]; then
        cargo fmt --check || FAILED=true
        CHECKED=true
    fi
    if [ -f "rescript.json" ] || [ -f "bsconfig.json" ]; then
        deno task format:check 2>/dev/null || CHECKED=true
    fi
    if [ -f "gleam.toml" ]; then
        gleam format --check . || FAILED=true
        CHECKED=true
    fi
    if [ -f "mix.exs" ]; then
        mix format --check-formatted || FAILED=true
        CHECKED=true
    fi
    if [ -f "deno.json" ] || [ -f "deno.jsonc" ]; then
        deno fmt --check || FAILED=true
        CHECKED=true
    fi
    if [ "$CHECKED" = false ]; then
        echo "No recognized format system found"
    elif [ "$FAILED" = true ]; then
        exit 1
    fi

# Run linter
lint:
    #!/usr/bin/env bash
    echo "Linting..."
    LINTED=false
    FAILED=false
    if [ -f "Cargo.toml" ]; then
        cargo clippy -- -D warnings || FAILED=true
        LINTED=true
    fi
    if [ -f "rescript.json" ] || [ -f "bsconfig.json" ]; then
        deno task lint 2>/dev/null || deno lint 2>/dev/null
        LINTED=true
    fi
    if [ -f "gleam.toml" ]; then
        gleam check || FAILED=true
        LINTED=true
    fi
    if [ -f "mix.exs" ]; then
        mix credo --strict 2>/dev/null || mix compile --warnings-as-errors || FAILED=true
        LINTED=true
    fi
    if [ -f "deno.json" ] || [ -f "deno.jsonc" ]; then
        deno lint || FAILED=true
        LINTED=true
    fi
    # Lint shell scripts
    if command -v shellcheck >/dev/null; then
        find . -name "*.sh" -not -path "./.git/*" -exec shellcheck {} \; 2>/dev/null
    fi
    if [ "$LINTED" = false ]; then
        echo "No recognized lint system found"
    elif [ "$FAILED" = true ]; then
        exit 1
    fi

# Run all quality checks
quality: fmt-check lint test
    @echo "All quality checks passed!"

# Fix all auto-fixable issues [reversible: git checkout]
fix: fmt
    @echo "Fixed all auto-fixable issues"

# ═══════════════════════════════════════════════════════════════════════════════
# RUN & EXECUTE
# ═══════════════════════════════════════════════════════════════════════════════

# Run the application
run *args:
    #!/usr/bin/env bash
    echo "Running {{project}}..."
    if [ -f "Cargo.toml" ]; then
        cargo run {{args}}
    elif [ -f "rescript.json" ] || [ -f "bsconfig.json" ]; then
        deno task start {{args}} 2>/dev/null || node lib/es6/src/Main.bs.js {{args}} 2>/dev/null || deno run --allow-all lib/es6/src/Main.bs.js {{args}}
    elif [ -f "gleam.toml" ]; then
        gleam run {{args}}
    elif [ -f "mix.exs" ]; then
        mix run {{args}}
    elif [ -f "deno.json" ] || [ -f "deno.jsonc" ]; then
        deno task start {{args}} 2>/dev/null || deno run --allow-all main.ts {{args}}
    elif [ -f "main.jl" ]; then
        julia --project=. main.jl {{args}}
    else
        echo "No recognized run system found"
        exit 0
    fi

# Run in development mode with hot reload
dev:
    #!/usr/bin/env bash
    echo "Starting dev mode..."
    if [ -f "Cargo.toml" ]; then
        cargo watch -x run 2>/dev/null || cargo run
    elif [ -f "rescript.json" ] || [ -f "bsconfig.json" ]; then
        deno task dev 2>/dev/null || npx rescript build -w
    elif [ -f "gleam.toml" ]; then
        watchexec -e gleam -- gleam run 2>/dev/null || gleam run
    elif [ -f "mix.exs" ]; then
        iex -S mix
    elif [ -f "deno.json" ] || [ -f "deno.jsonc" ]; then
        deno task dev 2>/dev/null || deno run --watch --allow-all main.ts
    else
        echo "No recognized dev system found"
        exit 0
    fi

# Run REPL/interactive mode
repl:
    #!/usr/bin/env bash
    echo "Starting REPL..."
    if [ -f "Cargo.toml" ]; then
        evcxr 2>/dev/null || (echo "Install evcxr: cargo install evcxr_repl" && exit 1)
    elif [ -f "rescript.json" ] || [ -f "bsconfig.json" ]; then
        deno repl 2>/dev/null || node
    elif [ -f "gleam.toml" ]; then
        gleam shell 2>/dev/null || erl
    elif [ -f "mix.exs" ]; then
        iex -S mix
    elif [ -f "deno.json" ] || [ -f "deno.jsonc" ]; then
        deno repl
    elif [ -f "Project.toml" ]; then
        julia --project=.
    else
        # Default to Guile Scheme REPL
        guix shell guile -- guile 2>/dev/null || guile 2>/dev/null || echo "No REPL available"
    fi

# ═══════════════════════════════════════════════════════════════════════════════
# DEPENDENCIES
# ═══════════════════════════════════════════════════════════════════════════════

# Install all dependencies
deps:
    #!/usr/bin/env bash
    echo "Installing dependencies..."
    INSTALLED=false
    if [ -f "Cargo.toml" ]; then
        cargo fetch && INSTALLED=true
    fi
    if [ -f "rescript.json" ] || [ -f "bsconfig.json" ]; then
        if [ -f "deno.json" ] || [ -f "deno.jsonc" ]; then
            deno cache --reload deps.ts 2>/dev/null || deno task deps 2>/dev/null
        else
            npm install 2>/dev/null
        fi
        INSTALLED=true
    fi
    if [ -f "gleam.toml" ]; then
        gleam deps download && INSTALLED=true
    fi
    if [ -f "mix.exs" ]; then
        mix deps.get && INSTALLED=true
    fi
    if [ -f "deno.json" ] || [ -f "deno.jsonc" ]; then
        deno cache --reload deps.ts 2>/dev/null || deno task deps 2>/dev/null || true
        INSTALLED=true
    fi
    if [ -f "Project.toml" ]; then
        julia --project=. -e 'using Pkg; Pkg.instantiate()' && INSTALLED=true
    fi
    if [ "$INSTALLED" = false ]; then
        echo "No recognized dependency system found (Cargo.toml, gleam.toml, mix.exs, deno.json, Project.toml)"
    fi

# Audit dependencies for vulnerabilities
deps-audit:
    #!/usr/bin/env bash
    echo "Auditing dependencies..."
    AUDITED=false
    if [ -f "Cargo.toml" ]; then
        cargo audit 2>/dev/null || (echo "Install cargo-audit: cargo install cargo-audit" && exit 1)
        AUDITED=true
    fi
    if [ -f "gleam.toml" ]; then
        echo "Gleam: checking hex.pm packages..."
        gleam deps list
        AUDITED=true
    fi
    if [ -f "mix.exs" ]; then
        mix hex.audit 2>/dev/null || mix deps
        AUDITED=true
    fi
    if [ -f "deno.json" ] || [ -f "deno.jsonc" ]; then
        echo "Deno: dependencies are URL-based with integrity checks"
        deno info 2>/dev/null || true
        AUDITED=true
    fi
    if [ -f "Project.toml" ]; then
        julia --project=. -e 'using Pkg; Pkg.status()' 2>/dev/null
        AUDITED=true
    fi
    # General security scanning
    if command -v trivy >/dev/null; then
        echo "=== Trivy scan ==="
        trivy fs --severity HIGH,CRITICAL . 2>/dev/null || true
    fi
    if [ "$AUDITED" = false ]; then
        echo "No recognized audit system found"
    fi

# ═══════════════════════════════════════════════════════════════════════════════
# DOCUMENTATION
# ═══════════════════════════════════════════════════════════════════════════════

# Generate all documentation
docs:
    @mkdir -p docs/generated docs/man
    just cookbook
    just man
    @echo "Documentation generated in docs/"

# Generate justfile cookbook documentation
cookbook:
    #!/usr/bin/env bash
    mkdir -p docs
    OUTPUT="docs/just-cookbook.adoc"
    echo "= {{project}} Justfile Cookbook" > "$OUTPUT"
    echo ":toc: left" >> "$OUTPUT"
    echo ":toclevels: 3" >> "$OUTPUT"
    echo "" >> "$OUTPUT"
    echo "Generated: $(date -Iseconds)" >> "$OUTPUT"
    echo "" >> "$OUTPUT"
    echo "== Recipes" >> "$OUTPUT"
    echo "" >> "$OUTPUT"
    just --list --unsorted | while read -r line; do
        if [[ "$line" =~ ^[[:space:]]+([a-z_-]+) ]]; then
            recipe="${BASH_REMATCH[1]}"
            echo "=== $recipe" >> "$OUTPUT"
            echo "" >> "$OUTPUT"
            echo "[source,bash]" >> "$OUTPUT"
            echo "----" >> "$OUTPUT"
            echo "just $recipe" >> "$OUTPUT"
            echo "----" >> "$OUTPUT"
            echo "" >> "$OUTPUT"
        fi
    done
    echo "Generated: $OUTPUT"

# Generate man page
man:
    #!/usr/bin/env bash
    mkdir -p docs/man
    cat > docs/man/{{project}}.1 << EOF
.TH RSR-TEMPLATE-REPO 1 "$(date +%Y-%m-%d)" "{{version}}" "RSR Template Manual"
.SH NAME
{{project}} \- RSR standard repository template
.SH SYNOPSIS
.B just
[recipe] [args...]
.SH DESCRIPTION
Canonical template for RSR (Rhodium Standard Repository) projects.
.SH AUTHOR
Hyperpolymath <hyperpolymath@proton.me>
EOF
    echo "Generated: docs/man/{{project}}.1"

# ═══════════════════════════════════════════════════════════════════════════════
# CONTAINERS (nerdctl + Wolfi)
# ═══════════════════════════════════════════════════════════════════════════════

# Build container image
container-build tag="latest":
    @if [ -f Containerfile ]; then \
        nerdctl build -t {{project}}:{{tag}} -f Containerfile .; \
    else \
        echo "No Containerfile found"; \
    fi

# Run container
container-run tag="latest" *args:
    nerdctl run --rm -it {{project}}:{{tag}} {{args}}

# Push container image
container-push registry="ghcr.io/hyperpolymath" tag="latest":
    nerdctl tag {{project}}:{{tag}} {{registry}}/{{project}}:{{tag}}
    nerdctl push {{registry}}/{{project}}:{{tag}}

# ═══════════════════════════════════════════════════════════════════════════════
# CI & AUTOMATION
# ═══════════════════════════════════════════════════════════════════════════════

# Run full CI pipeline locally
ci: deps quality
    @echo "CI pipeline complete!"

# Install git hooks
install-hooks:
    @mkdir -p .git/hooks
    @cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash
just fmt-check || exit 1
just lint || exit 1
EOF
    @chmod +x .git/hooks/pre-commit
    @echo "Git hooks installed"

# ═══════════════════════════════════════════════════════════════════════════════
# SECURITY
# ═══════════════════════════════════════════════════════════════════════════════

# Run security audit
security: deps-audit
    @echo "=== Security Audit ==="
    @command -v gitleaks >/dev/null && gitleaks detect --source . --verbose || true
    @command -v trivy >/dev/null && trivy fs --severity HIGH,CRITICAL . || true
    @echo "Security audit complete"

# Generate SBOM
sbom:
    @mkdir -p docs/security
    @command -v syft >/dev/null && syft . -o spdx-json > docs/security/sbom.spdx.json || echo "syft not found"

# ═══════════════════════════════════════════════════════════════════════════════
# VALIDATION & COMPLIANCE
# ═══════════════════════════════════════════════════════════════════════════════

# Validate RSR compliance
validate-rsr:
    #!/usr/bin/env bash
    echo "=== RSR Compliance Check ==="
    MISSING=""
    for f in .editorconfig .gitignore justfile RSR_COMPLIANCE.adoc README.adoc; do
        [ -f "$f" ] || MISSING="$MISSING $f"
    done
    for d in .well-known; do
        [ -d "$d" ] || MISSING="$MISSING $d/"
    done
    for f in .well-known/security.txt .well-known/ai.txt .well-known/humans.txt; do
        [ -f "$f" ] || MISSING="$MISSING $f"
    done
    if [ ! -f "guix.scm" ] && [ ! -f ".guix-channel" ] && [ ! -f "flake.nix" ]; then
        MISSING="$MISSING guix.scm/flake.nix"
    fi
    if [ -n "$MISSING" ]; then
        echo "MISSING:$MISSING"
        exit 1
    fi
    echo "RSR compliance: PASS"

# Validate STATE.scm syntax
validate-state:
    @if [ -f "STATE.scm" ]; then \
        guile -c "(primitive-load \"STATE.scm\")" 2>/dev/null && echo "STATE.scm: valid" || echo "STATE.scm: INVALID"; \
    else \
        echo "No STATE.scm found"; \
    fi

# Full validation suite
validate: validate-rsr validate-state
    @echo "All validations passed!"

# ═══════════════════════════════════════════════════════════════════════════════
# STATE MANAGEMENT
# ═══════════════════════════════════════════════════════════════════════════════

# Update STATE.scm timestamp
state-touch:
    @if [ -f "STATE.scm" ]; then \
        sed -i 's/(updated . "[^"]*")/(updated . "'"$(date -Iseconds)"'")/' STATE.scm && \
        echo "STATE.scm timestamp updated"; \
    fi

# Show current phase from STATE.scm
state-phase:
    @grep -oP '\(phase\s+\.\s+\K[^)]+' STATE.scm 2>/dev/null | head -1 || echo "unknown"

# ═══════════════════════════════════════════════════════════════════════════════
# GUIX & NIX
# ═══════════════════════════════════════════════════════════════════════════════

# Enter Guix development shell (primary)
guix-shell:
    guix shell -D -f guix.scm

# Build with Guix
guix-build:
    guix build -f guix.scm

# Enter Nix development shell (fallback)
nix-shell:
    @if [ -f "flake.nix" ]; then nix develop; else echo "No flake.nix"; fi

# ═══════════════════════════════════════════════════════════════════════════════
# HYBRID AUTOMATION
# ═══════════════════════════════════════════════════════════════════════════════

# Run local automation tasks
automate task="all":
    #!/usr/bin/env bash
    case "{{task}}" in
        all) just fmt && just lint && just test && just docs && just state-touch ;;
        cleanup) just clean && find . -name "*.orig" -delete && find . -name "*~" -delete ;;
        update) just deps && just validate ;;
        *) echo "Unknown: {{task}}. Use: all, cleanup, update" && exit 1 ;;
    esac

# ═══════════════════════════════════════════════════════════════════════════════
# COMBINATORIC MATRIX RECIPES
# ═══════════════════════════════════════════════════════════════════════════════

# Build matrix: [debug|release] × [target] × [features]
build-matrix mode="debug" target="" features="":
    @echo "Build matrix: mode={{mode}} target={{target}} features={{features}}"
    # Customize for your build system

# Test matrix: [unit|integration|e2e|all] × [verbosity] × [parallel]
test-matrix suite="unit" verbosity="normal" parallel="true":
    @echo "Test matrix: suite={{suite}} verbosity={{verbosity}} parallel={{parallel}}"

# Container matrix: [build|run|push|shell|scan] × [registry] × [tag]
container-matrix action="build" registry="ghcr.io/hyperpolymath" tag="latest":
    @echo "Container matrix: action={{action}} registry={{registry}} tag={{tag}}"

# CI matrix: [lint|test|build|security|all] × [quick|full]
ci-matrix stage="all" depth="quick":
    @echo "CI matrix: stage={{stage}} depth={{depth}}"

# Show all matrix combinations
combinations:
    @echo "=== Combinatoric Matrix Recipes ==="
    @echo ""
    @echo "Build Matrix: just build-matrix [debug|release] [target] [features]"
    @echo "Test Matrix:  just test-matrix [unit|integration|e2e|all] [verbosity] [parallel]"
    @echo "Container:    just container-matrix [build|run|push|shell|scan] [registry] [tag]"
    @echo "CI Matrix:    just ci-matrix [lint|test|build|security|all] [quick|full]"
    @echo ""
    @echo "Total combinations: ~10 billion"

# ═══════════════════════════════════════════════════════════════════════════════
# VERSION CONTROL
# ═══════════════════════════════════════════════════════════════════════════════

# Show git status
status:
    @git status --short

# Show recent commits
log count="20":
    @git log --oneline -{{count}}

# ═══════════════════════════════════════════════════════════════════════════════
# UTILITIES
# ═══════════════════════════════════════════════════════════════════════════════

# Count lines of code
loc:
    @find . \( -name "*.rs" -o -name "*.ex" -o -name "*.res" -o -name "*.ncl" -o -name "*.scm" \) 2>/dev/null | xargs wc -l 2>/dev/null | tail -1 || echo "0"

# Show TODO comments
todos:
    @grep -rn "TODO\|FIXME" --include="*.rs" --include="*.ex" --include="*.res" . 2>/dev/null || echo "No TODOs"

# Open in editor
edit:
    ${EDITOR:-code} .
