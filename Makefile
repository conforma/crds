# CRDs Makefile - Enterprise Contract Policy CRDs
# Extracted from enterprise-contract-controller repository

ROOT = $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

CONTROLLER_GEN = go run -modfile $(ROOT)tools/go.mod sigs.k8s.io/controller-tools/cmd/controller-gen
KUSTOMIZE = go run -modfile $(ROOT)tools/go.mod sigs.k8s.io/kustomize/kustomize/v4
CRD_DEF = ./api/v1alpha1

# Setting SHELL to bash allows bash commands to be executed by recipes.
# Options are set to exit when a recipe line exits non-zero or a piped command fails.
SHELL = /usr/bin/env bash -o pipefail
.SHELLFLAGS = -ec

all: build manifests docs

##@ General

.PHONY: help
help: ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

##@ Development

.PHONY: docs
docs: $(wildcard $(CRD_DEF)/*.go) ## Generate documentation
	@go run -modfile tools/go.mod github.com/elastic/crd-ref-docs --max-depth 50 --config=docs/config.yaml --source-path=$(CRD_DEF) --templates-dir=docs/templates --output-path=docs/modules/ROOT/pages/reference.adoc
	@go run ./docs

GEN_DEPS=\
 api/v1alpha1/enterprisecontractpolicy_types.go \
 api/v1alpha1/groupversion_info.go \
 tools/go.sum

config/crd/bases/%.yaml: $(GEN_DEPS)
	$(CONTROLLER_GEN) rbac:roleName=enterprise-contract-role crd webhook paths=./... output:crd:artifacts:config=config/crd/bases
	yq -i 'del(.metadata.annotations["controller-gen.kubebuilder.io/version"])' $@

api/config/%.yaml: config/crd/bases/%.yaml
	@mkdir -p api/config
	@cp $< $@

manifests: api/config/appstudio.redhat.com_enterprisecontractpolicies.yaml ## Generate WebhookConfiguration, ClusterRole and CustomResourceDefinition objects.

.PHONY: generate
generate: $(GEN_DEPS) ## Generate code containing DeepCopy, DeepCopyInto, and DeepCopyObject method implementations.
	$(CONTROLLER_GEN) object:headerFile="hack/boilerplate.go.txt" paths=./...
	cd api && go generate ./...

.PHONY: fmt
fmt: ## Run go fmt against code.
	cd api && go fmt ./...
	cd schema && go fmt ./...
	go fmt ./docs

.PHONY: vet
vet: ## Run go vet against code.
	cd api && go vet ./...
	cd schema && go vet ./...
	go vet ./docs

.PHONY: test
test: manifests generate fmt vet ## Run tests.
	cd api && go test ./... -coverprofile ../api_cover.out
	cd schema && go test ./... -coverprofile ../schema_cover.out

##@ Build

build: generate fmt vet ## Build (validate) CRDs.
	@echo "CRDs built successfully"

.PHONY: export-schema
export-schema: generate ## Export the CRD schema to the schema directory as a json-store.org schema.
	@mkdir -p dist
	cp api/v1alpha1/policy_spec.json dist/

##@ Deployment

ifndef ignore-not-found
  ignore-not-found = false
endif

.PHONY: install
install: manifests ## Install CRDs into the K8s cluster specified in ~/.kube/config.
	$(KUSTOMIZE) build config/crd | kubectl apply -f -

.PHONY: uninstall
uninstall: manifests ## Uninstall CRDs from the K8s cluster specified in ~/.kube/config. Call with ignore-not-found=true to ignore resource not found errors during deletion.
	$(KUSTOMIZE) build config/crd | kubectl delete --ignore-not-found=$(ignore-not-found) -f -
