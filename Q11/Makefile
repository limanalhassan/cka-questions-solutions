# =========================
# CKA LAB - QUESTION 11 (cert-manager CRD Documentation)
# =========================
QUESTION := Q11
NAMESPACE := cert-manager
RESOURCES_FILE := ~/resources.yaml
SUBJECT_FILE := ~/subject.yaml
CRD_PREFIX := cert-manager

# =========================
# Default workflow
# =========================
.PHONY: all
all: clean setup
	@echo "\n✅ $(QUESTION) environment ready."
	@echo "   Complete the tasks manually or run 'make solution'.\n"

# =========================
# Environment Setup
# =========================
.PHONY: setup
setup:
	@echo "\n🔧 Setting up $(QUESTION) environment..."
	kubectl apply -f q11.yaml
	@echo "\n⏳ Checking if cert-manager is installed..."
	@if kubectl get crd | grep -q cert-manager; then \
		echo "   ✅ cert-manager CRDs found"; \
	else \
		echo "   ⚠️  cert-manager CRDs not found"; \
		echo "   Install cert-manager first:"; \
		echo "   kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml"; \
	fi
	@echo "✅ Environment setup complete.\n"

# =========================
# Solution Application
# =========================
.PHONY: solution
solution:
	@echo "\n🚀 Applying solution:"
	@echo "\n   Task 1: Creating list of cert-manager CRDs..."
	@echo "   IMPORTANT: Using default kubectl output format (no --output flag)"
	kubectl get crd | grep $(CRD_PREFIX) > $(RESOURCES_FILE) || \
		kubectl api-resources --api-group=cert-manager.io -o name > $(RESOURCES_FILE) || \
		(echo "   ⚠️  No cert-manager CRDs found. Install cert-manager first." && exit 1)
	@echo "   ✅ Saved to $(RESOURCES_FILE)"
	@echo "\n   Task 2: Extracting documentation for 'subject' field..."
	kubectl explain certificate.spec.subject > $(SUBJECT_FILE) 2>/dev/null || \
		(echo "   ⚠️  Certificate CRD not found. Install cert-manager first." && exit 1)
	@echo "   ✅ Saved to $(SUBJECT_FILE)"
	@echo "\n✅ Solution applied. Run 'make verify' to confirm.\n"

.PHONY: task1
task1:
	@echo "\n📋 Task 1: Creating list of cert-manager CRDs..."
	@echo "   Using default kubectl output format (no --output flag)"
	kubectl get crd | grep $(CRD_PREFIX) > $(RESOURCES_FILE) || \
		kubectl api-resources --api-group=cert-manager.io -o name > $(RESOURCES_FILE) || \
		(echo "   ⚠️  No cert-manager CRDs found" && exit 1)
	@echo "   ✅ Saved to $(RESOURCES_FILE)"
	@echo "\n   Contents:"
	@cat $(RESOURCES_FILE) || echo "   File not found"

.PHONY: task2
task2:
	@echo "\n📋 Task 2: Extracting documentation for 'subject' field..."
	kubectl explain certificate.spec.subject > $(SUBJECT_FILE) 2>/dev/null || \
		(echo "   ⚠️  Certificate CRD not found" && exit 1)
	@echo "   ✅ Saved to $(SUBJECT_FILE)"
	@echo "\n   Contents:"
	@cat $(SUBJECT_FILE) || echo "   File not found"

# =========================
# Verification
# =========================
.PHONY: status
status:
	@echo "\n📊 $(QUESTION) Environment Summary:"
	@echo "\nNamespace:"
	kubectl get ns $(NAMESPACE) 2>/dev/null || echo "   Namespace not found"
	@echo "\ncert-manager CRDs:"
	kubectl get crd | grep $(CRD_PREFIX) || echo "   No cert-manager CRDs found"
	@echo "\nGenerated files:"
	@if [ -f $(RESOURCES_FILE) ]; then \
		echo "   ✅ $(RESOURCES_FILE) exists"; \
		echo "   Lines: $$(wc -l < $(RESOURCES_FILE))"; \
	else \
		echo "   ❌ $(RESOURCES_FILE) not found"; \
	fi
	@if [ -f $(SUBJECT_FILE) ]; then \
		echo "   ✅ $(SUBJECT_FILE) exists"; \
		echo "   Lines: $$(wc -l < $(SUBJECT_FILE))"; \
	else \
		echo "   ❌ $(SUBJECT_FILE) not found"; \
	fi

.PHONY: verify
verify:
	@echo "\n🔍 Verifying solution..."
	@echo "\n1. Checking Task 1: List of cert-manager CRDs"
	@if [ -f $(RESOURCES_FILE) ]; then \
		echo "   ✅ File $(RESOURCES_FILE) exists"; \
		FILE_SIZE=$$(wc -l < $(RESOURCES_FILE) | tr -d ' '); \
		if [ "$$FILE_SIZE" -gt 0 ]; then \
			echo "   ✅ File contains $$FILE_SIZE line(s)"; \
			echo "   First few lines:"; \
			head -5 $(RESOURCES_FILE) | sed 's/^/     /'; \
		else \
			echo "   ⚠️  File is empty"; \
		fi; \
		echo "   Checking if default output format was used..."; \
		if grep -q "^[a-z].*cert-manager" $(RESOURCES_FILE) || grep -q "cert-manager" $(RESOURCES_FILE); then \
			echo "   ✅ File appears to contain CRD names"; \
		else \
			echo "   ⚠️  File format may be incorrect"; \
		fi; \
	else \
		echo "   ❌ File $(RESOURCES_FILE) not found"; \
	fi
	@echo "\n2. Checking Task 2: Documentation for 'subject' field"
	@if [ -f $(SUBJECT_FILE) ]; then \
		echo "   ✅ File $(SUBJECT_FILE) exists"; \
		FILE_SIZE=$$(wc -l < $(SUBJECT_FILE) | tr -d ' '); \
		if [ "$$FILE_SIZE" -gt 0 ]; then \
			echo "   ✅ File contains $$FILE_SIZE line(s)"; \
			if grep -qi "subject" $(SUBJECT_FILE); then \
				echo "   ✅ File contains 'subject' documentation"; \
			else \
				echo "   ⚠️  File may not contain subject documentation"; \
			fi; \
		else \
			echo "   ⚠️  File is empty"; \
		fi; \
	else \
		echo "   ❌ File $(SUBJECT_FILE) not found"; \
	fi
	@echo "\n✅ Verification complete.\n"

.PHONY: show-resources
show-resources:
	@echo "\n📋 Contents of $(RESOURCES_FILE):"
	@if [ -f $(RESOURCES_FILE) ]; then \
		cat $(RESOURCES_FILE); \
	else \
		echo "   File not found"; \
	fi

.PHONY: show-subject
show-subject:
	@echo "\n📋 Contents of $(SUBJECT_FILE):"
	@if [ -f $(SUBJECT_FILE) ]; then \
		cat $(SUBJECT_FILE); \
	else \
		echo "   File not found"; \
	fi

.PHONY: check-cert-manager
check-cert-manager:
	@echo "\n🔍 Checking cert-manager installation..."
	@echo "\nCRDs:"
	kubectl get crd | grep cert-manager || echo "   No cert-manager CRDs found"
	@echo "\nAPI Resources:"
	kubectl api-resources --api-group=cert-manager.io || echo "   No cert-manager API resources found"
	@echo "\nCertificate CRD:"
	kubectl get crd certificates.cert-manager.io 2>/dev/null && \
		echo "   ✅ Certificate CRD exists" || \
		echo "   ❌ Certificate CRD not found"

# =========================
# Cleanup
# =========================
.PHONY: clean
clean:
	@echo "\n🧹 Cleaning up $(QUESTION) lab resources..."
	@echo "→ Deleting namespace..."
	-kubectl delete ns $(NAMESPACE) --ignore-not-found
	@echo "→ Removing generated files..."
	-rm -f $(RESOURCES_FILE) $(SUBJECT_FILE)
	@echo "✅ Cleanup completed for $(QUESTION).\n"
	@echo "⚠️  Note: cert-manager installation is not removed."
	@echo "   To remove cert-manager: kubectl delete -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml\n"

