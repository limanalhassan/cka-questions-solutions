# =========================
# CKA LAB - QUESTION 6 (Argo CD Helm Installation)
# =========================
QUESTION := Q6
NAMESPACE := argocd
REPO_NAME := argo
REPO_URL := https://argoproj.github.io/argo-helm
CHART_NAME := argo-cd
RELEASE_NAME := argocd
VERSION := 7.7.3
TEMPLATE_FILE := /argo-helm.yaml
YAML := q6.yaml
SOLUTION := solution.yaml

# =========================
# Default workflow
# =========================
.PHONY: all
all: clean setup
	@echo "\n✅ $(QUESTION) environment ready."
	@echo "   Install Argo CD manually or run 'make solution' to apply the solution.\n"

# =========================
# Environment Setup
# =========================
.PHONY: setup
setup:
	@echo "\n🔧 Setting up $(QUESTION) environment..."
	kubectl apply -f $(YAML)
	@echo "\n⏳ Waiting for CRDs to be established..."
	sleep 5
	@echo "✅ Environment setup complete.\n"

# =========================
# Helm Repository Management
# =========================
.PHONY: repo-add
repo-add:
	@echo "\n📦 Adding Argo CD Helm repository..."
	helm repo add $(REPO_NAME) $(REPO_URL) || helm repo add $(REPO_NAME) $(REPO_URL) --force-update
	helm repo update
	@echo "✅ Helm repository added and updated.\n"

# =========================
# Solution Application
# =========================
.PHONY: solution
solution: repo-add
	@echo "\n🚀 Installing Argo CD using Helm..."
	@echo "\n   Step 1: Generating Helm template..."
	@echo "   Template will be saved to $(TEMPLATE_FILE)"
	@echo "   Note: This requires root access to write to / directory."
	@echo "   For local testing, template will be saved to ./argo-helm.yaml"
	@helm template $(RELEASE_NAME) $(REPO_NAME)/$(CHART_NAME) --version $(VERSION) \
		--namespace $(NAMESPACE) \
		--create-namespace \
		--skip-crds > ./argo-helm.yaml || \
		(sudo helm template $(RELEASE_NAME) $(REPO_NAME)/$(CHART_NAME) --version $(VERSION) \
		--namespace $(NAMESPACE) \
		--create-namespace \
		--skip-crds > $(TEMPLATE_FILE) || \
		echo "⚠️  Could not write to $(TEMPLATE_FILE), saved to ./argo-helm.yaml instead")
	@echo "\n   Step 2: Installing Argo CD..."
	helm install $(RELEASE_NAME) $(REPO_NAME)/$(CHART_NAME) --version $(VERSION) \
		--namespace $(NAMESPACE) \
		--create-namespace \
		--skip-crds
	@echo "\n⏳ Waiting for Argo CD to be ready..."
	sleep 10
	@echo "\n✅ Argo CD installation initiated."
	@echo "   Run 'make status' to check installation status.\n"

.PHONY: template
template: repo-add
	@echo "\n📄 Generating Argo CD Helm template..."
	@echo "   Version: $(VERSION)"
	@echo "   Namespace: $(NAMESPACE)"
	@echo "   CRDs: Skipped (--skip-crds)"
	@helm template $(RELEASE_NAME) $(REPO_NAME)/$(CHART_NAME) --version $(VERSION) \
		--namespace $(NAMESPACE) \
		--create-namespace \
		--skip-crds > ./argo-helm.yaml
	@echo "✅ Template saved to ./argo-helm.yaml"
	@echo "   For exam: Save to $(TEMPLATE_FILE) (requires root access)\n"

.PHONY: install
install: repo-add
	@echo "\n🚀 Installing Argo CD..."
	helm install $(RELEASE_NAME) $(REPO_NAME)/$(CHART_NAME) --version $(VERSION) \
		--namespace $(NAMESPACE) \
		--create-namespace \
		--skip-crds
	@echo "\n✅ Argo CD installation initiated.\n"

# =========================
# Verification
# =========================
.PHONY: status
status:
	@echo "\n📊 $(QUESTION) Environment Summary:"
	@echo "\nNamespace:"
	kubectl get ns $(NAMESPACE)
	@echo "\nHelm Repositories:"
	helm repo list | grep $(REPO_NAME) || echo "   Repository not added yet"
	@echo "\nHelm Releases:"
	helm list -n $(NAMESPACE)
	@echo "\nArgo CD Pods:"
	kubectl -n $(NAMESPACE) get pods
	@echo "\nArgo CD Services:"
	kubectl -n $(NAMESPACE) get svc
	@echo "\nArgo CD CRDs:"
	kubectl get crd | grep argoproj.io

.PHONY: verify
verify:
	@echo "\n🔍 Verifying Argo CD installation..."
	@echo "\n1. Checking Helm repository:"
	@helm repo list | grep -q $(REPO_NAME) && echo "   ✅ Repository '$(REPO_NAME)' exists" || echo "   ❌ Repository '$(REPO_NAME)' not found"
	@echo "\n2. Checking Helm release:"
	@helm list -n $(NAMESPACE) | grep -q $(RELEASE_NAME) && echo "   ✅ Release '$(RELEASE_NAME)' installed" || echo "   ❌ Release '$(RELEASE_NAME)' not found"
	@echo "\n3. Checking Argo CD pods:"
	@PODS=$$(kubectl -n $(NAMESPACE) get pods -l app.kubernetes.io/name=argocd-server --no-headers 2>/dev/null | wc -l); \
	if [ "$$PODS" -gt 0 ]; then \
		echo "   ✅ Argo CD server pods found"; \
	else \
		echo "   ⚠️  Argo CD server pods not found (may still be starting)"; \
	fi
	@echo "\n4. Checking template file:"
	@if [ -f "$(TEMPLATE_FILE)" ]; then \
		echo "   ✅ Template file exists at $(TEMPLATE_FILE)"; \
	elif [ -f "./argo-helm.yaml" ]; then \
		echo "   ✅ Template file exists at ./argo-helm.yaml"; \
	else \
		echo "   ⚠️  Template file not found"; \
	fi
	@echo "\n✅ Verification complete.\n"

# =========================
# Cleanup
# =========================
.PHONY: clean
clean:
	@echo "\n🧹 Cleaning up $(QUESTION) lab resources..."
	@echo "→ Uninstalling Argo CD Helm release..."
	-helm uninstall $(RELEASE_NAME) -n $(NAMESPACE) --ignore-not-found
	@echo "→ Deleting namespace $(NAMESPACE)..."
	-kubectl delete ns $(NAMESPACE) --ignore-not-found
	@echo "→ Removing Argo CD CRDs..."
	-kubectl delete crd applications.argoproj.io applicationsets.argoproj.io appprojects.argoproj.io --ignore-not-found
	@echo "→ Removing template file..."
	-rm -f ./argo-helm.yaml
	-sudo rm -f $(TEMPLATE_FILE) 2>/dev/null || true
	@echo "✅ Cleanup completed for $(QUESTION).\n"
	@echo "⚠️  Note: Helm repository '$(REPO_NAME)' is not removed."
	@echo "   To remove it manually: helm repo remove $(REPO_NAME)\n"

