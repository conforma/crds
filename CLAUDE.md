# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Kubernetes Custom Resource Definitions (CRDs) for Enterprise Contract Policies. Defines the `EnterpriseContractPolicy` CRD in the `appstudio.redhat.com/v1alpha1` API group, used to configure policy sources, include/exclude rules, signing keys, and Rekor URLs for the Conforma (Enterprise Contract) validation system.

## Essential Commands

```bash
make generate       # Regenerate DeepCopy methods and code after changing CRD types
make manifests      # Regenerate CRD YAML manifests
make test           # Run tests (also runs generate, fmt, vet first)
make build          # Validate CRDs (runs generate, fmt, vet)
make docs           # Generate Antora documentation from CRD types
make export-schema  # Export JSON schema to dist/policy_spec.json
make install        # Install CRDs to current kubectl cluster
make fmt            # Run go fmt across all modules
make vet            # Run go vet across all modules
```

## Architecture

Multi-module Go project:
- **`api/v1alpha1/`** — CRD type definitions (`enterprisecontractpolicy_types.go`), generated DeepCopy code, and the published Go API module
- **`schema/`** — JSON schema generation from CRD types
- **`tools/`** — Build tool dependencies (controller-gen, kustomize) pinned via go.mod
- **`docs/`** — Antora documentation and example generation using crd-ref-docs
- **`config/crd/bases/`** — Generated CRD YAML manifests
- **`config/samples/`** — Example EnterpriseContractPolicy resources

## Development Workflow

1. Edit types in `api/v1alpha1/enterprisecontractpolicy_types.go`
2. Run `make generate` to update DeepCopy methods
3. Run `make manifests` to regenerate CRD YAML
4. Run `make test` to validate
5. Commit both source changes and generated files

## Key CRD Fields

- `spec.sources` — policy/data bundle URLs with per-source include/exclude config and ruleData
- `spec.configuration` — global include/exclude rules
- `spec.publicKey` — public key for signature validation
- `spec.identity` — keyless Sigstore verification settings
- `spec.rekorUrl` — Rekor transparency log URL

## Tools

All build tools run via `go run -modfile tools/go.mod` to use pinned versions — no global installs needed.
