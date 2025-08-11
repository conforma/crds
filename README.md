# Enterprise Contract Policy CRDs

Custom Resource Definitions (CRDs) for Enterprise Contract Policies in Kubernetes environments.

## Overview

The Enterprise Contract Policy CRD (`EnterpriseContractPolicy`) defines and configures Enterprise Contract policies for validating software supply chain security and compliance. This repository provides the CRD definitions, validation schemas, and tooling needed to work with Enterprise Contract policies in Kubernetes.

## Repository Structure

```
├── api/v1alpha1/                 # CRD type definitions and generated code
├── config/                       # Kubernetes manifests and examples
│   ├── crd/                      # CRD installation manifests
│   └── samples/                  # Example policy instances
├── schema/                       # JSON schema generation
├── tools/                        # Build dependencies
├── docs/                         # Documentation generation
├── .github/workflows/            # CI/CD automation
└── Makefile                      # Build commands
```

## Quick Start

### Installing CRDs

Install the CRDs to your Kubernetes cluster:

```bash
make install
```

Or manually apply the manifests:

```bash
kubectl apply -f config/crd/bases/appstudio.redhat.com_enterprisecontractpolicies.yaml
```

### Creating a Policy

Create an Enterprise Contract Policy:

```yaml
apiVersion: appstudio.redhat.com/v1alpha1
kind: EnterpriseContractPolicy
metadata:
  name: my-policy
  namespace: default
spec:
  description: "My Enterprise Contract Policy"
  sources:
    - name: "default-policies"
      policy:
        - "git::https://github.com/enterprise-contract/ec-policies//policy/lib"
        - "git::https://github.com/enterprise-contract/ec-policies//policy/release"
      data:
        - "git::https://github.com/enterprise-contract/ec-policies//data"
  configuration:
    exclude:
      - "step_image_registries"
    include:
      - "attestation_type.slsa_provenance_02"
```

## Development

### Prerequisites

- Go 1.23 or later
- Make
- kubectl (for cluster operations)

### Building and Testing

```bash
# Generate code and manifests
make generate

# Build (validate) CRDs
make build

# Run tests
make test

# Generate documentation
make docs

# Export JSON schema
make export-schema
```

### Making Changes

1. Edit the CRD types in `api/v1alpha1/enterprisecontractpolicy_types.go`
2. Run `make generate` to update generated code and manifests
3. Run `make test` to validate changes
4. Update documentation if needed

### Multi-Module Structure

The repository uses separate Go modules for different components:

- **`api/`**: Contains the CRD type definitions and core API
- **`schema/`**: JSON schema generation utilities  
- **`tools/`**: Build tool dependencies (controller-gen, etc.)
- **`docs/`**: Documentation and example generation

Each module can be imported and developed independently.

## API Reference

### EnterpriseContractPolicy

The main CRD type in the `appstudio.redhat.com/v1alpha1` API group.

#### Key Fields

- **`spec.sources`**: Array of policy and data sources with configuration options
- **`spec.configuration`**: Global policy inclusions and exclusions  
- **`spec.identity`**: Keyless verification settings for Sigstore
- **`spec.publicKey`**: Public key for signature validation
- **`spec.rekorUrl`**: Rekor transparency log URL

#### Policy Sources

Each source in `spec.sources` can specify:

- **`policy`**: List of policy bundle URLs (required)
- **`data`**: List of data bundle URLs  
- **`config`**: Source-specific include/exclude rules
- **`ruleData`**: Arbitrary data passed to policy rules
- **`volatileConfig`**: Time-based or image-specific rule configurations

#### Example Policy Source

```yaml
sources:
  - name: "release-policies"
    policy:
      - "git::https://github.com/enterprise-contract/ec-policies//policy/release?ref=v0.1.0"
    data:
      - "git::https://github.com/enterprise-contract/ec-policies//data?ref=v0.1.0"
    config:
      include:
        - "attestation_type.slsa_provenance_02"
      exclude:
        - "step_image_registries"
    ruleData:
      allowed_registries:
        - "registry.redhat.io"
        - "quay.io/redhat-prod"
```

## JSON Schema

The repository generates a JSON schema for the `EnterpriseContractPolicySpec` that can be used by external tools for validation and IDE support.

Export the schema:

```bash
make export-schema
```

The schema will be available in `dist/policy_spec.json`.

## Deployment

### Using Kustomize

The repository includes Kustomize configuration for easy deployment:

```bash
# Install CRDs
kustomize build config/crd | kubectl apply -f -

# Uninstall CRDs  
kustomize build config/crd | kubectl delete -f -
```

### RBAC

The repository includes ClusterRole definitions for managing Enterprise Contract Policies:

- **Editor Role**: Full read/write access to EnterpriseContractPolicy resources
- **Viewer Role**: Read-only access to EnterpriseContractPolicy resources

Apply the RBAC configurations as needed for your environment.

## Examples

See the `config/samples/` directory for example EnterpriseContractPolicy resources.

For OpenShift environments, see `config/crd/openshift_console_example.yaml` for console integration examples.

## CI/CD

The repository includes GitHub Actions workflows:

- **Checks**: Runs tests, builds, and validates CRDs on pull requests
- **Schema Publishing**: Publishes the JSON schema to GitHub Pages

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run `make test` to ensure everything works
5. Submit a pull request

### Code Generation

This repository uses Kubernetes code generation tools. After modifying CRD types:

1. Run `make generate` to update generated code
2. Run `make manifests` to update CRD manifests
3. Commit both the source changes and generated files

## License

Licensed under the Apache License, Version 2.0. See LICENSE file for details.