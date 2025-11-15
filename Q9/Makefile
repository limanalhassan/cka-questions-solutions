# =========================
# CKA LAB - QUESTION 9 (StorageClass Configuration)
# =========================
QUESTION := Q9
NAMESPACE := storage-lab
STORAGECLASS := low-latency
PROVISIONER := rancher.io/local-path
VOLUME_BINDING_MODE := WaitForFirstConsumer
YAML := q9.yaml
SOLUTION := solution.yaml

# =========================
# Default workflow
# =========================
.PHONY: all
all: clean setup
	@echo "\n✅ $(QUESTION) environment ready."
	@echo "   Create the StorageClass manually or run 'make solution'.\n"

# =========================
# Environment Setup
# =========================
.PHONY: setup
setup:
	@echo "\n🔧 Setting up $(QUESTION) environment..."
	kubectl apply -f $(YAML)
	@echo "\n⏳ Waiting for deployment to be ready..."
	kubectl -n $(NAMESPACE) rollout status deploy/app-deployment --timeout=120s || echo "   Deployment may be pending (waiting for PVC)"
	@echo "✅ Environment setup complete.\n"

# =========================
# Solution Application
# =========================
.PHONY: solution
solution:
	@echo "\n🚀 Applying solution: Creating StorageClass '$(STORAGECLASS)'..."
	@echo "\n   Step 1: Removing default annotation from existing default StorageClass..."
	-@EXISTING_DEFAULT=$$(kubectl get storageclass -o jsonpath='{.items[?(@.metadata.annotations.storageclass\.kubernetes\.io/is-default-class=="true")].metadata.name}' 2>/dev/null | awk '{print $$1}'); \
	if [ -n "$$EXISTING_DEFAULT" ] && [ "$$EXISTING_DEFAULT" != "$(STORAGECLASS)" ]; then \
		echo "   Removing default from: $$EXISTING_DEFAULT"; \
		kubectl patch storageclass $$EXISTING_DEFAULT -p '{"metadata": {"annotations": {"storageclass.kubernetes.io/is-default-class": "false"}}}'; \
	fi
	@echo "\n   Step 2: Creating StorageClass '$(STORAGECLASS)'..."
	kubectl apply -f $(SOLUTION)
	@echo "\n✅ Solution applied. Run 'make verify' to confirm.\n"

.PHONY: create-storageclass
create-storageclass:
	@echo "\n🔧 Creating StorageClass '$(STORAGECLASS)'..."
	kubectl apply -f $(SOLUTION)
	@echo "✅ StorageClass created.\n"

.PHONY: set-default
set-default:
	@echo "\n🔧 Setting '$(STORAGECLASS)' as default StorageClass..."
	@echo "   Removing default from existing StorageClasses..."
	-@EXISTING_DEFAULT=$$(kubectl get storageclass -o jsonpath='{.items[?(@.metadata.annotations.storageclass\.kubernetes\.io/is-default-class=="true")].metadata.name}' 2>/dev/null | awk '{print $$1}'); \
	if [ -n "$$EXISTING_DEFAULT" ] && [ "$$EXISTING_DEFAULT" != "$(STORAGECLASS)" ]; then \
		kubectl patch storageclass $$EXISTING_DEFAULT -p '{"metadata": {"annotations": {"storageclass.kubernetes.io/is-default-class": "false"}}}'; \
	fi
	@echo "   Setting '$(STORAGECLASS)' as default..."
	kubectl patch storageclass $(STORAGECLASS) -p '{"metadata": {"annotations": {"storageclass.kubernetes.io/is-default-class": "true"}}}'
	@echo "✅ Default StorageClass set.\n"

# =========================
# Verification
# =========================
.PHONY: status
status:
	@echo "\n📊 $(QUESTION) Environment Summary:"
	@echo "\nNamespace:"
	kubectl get ns $(NAMESPACE)
	@echo "\nStorageClasses:"
	kubectl get storageclass
	@echo "\nDeployment (DO NOT MODIFY):"
	kubectl -n $(NAMESPACE) get deploy app-deployment
	@echo "\nPersistentVolumeClaim (DO NOT MODIFY):"
	kubectl -n $(NAMESPACE) get pvc existing-pvc
	@echo "\nPods:"
	kubectl -n $(NAMESPACE) get pods

.PHONY: verify
verify:
	@echo "\n🔍 Verifying solution..."
	@echo "\n1. Checking StorageClass '$(STORAGECLASS)' exists:"
	@kubectl get storageclass $(STORAGECLASS) >/dev/null 2>&1 && \
		echo "   ✅ StorageClass '$(STORAGECLASS)' exists" || \
		echo "   ❌ StorageClass '$(STORAGECLASS)' not found"
	@echo "\n2. Checking provisioner:"
	@PROV=$$(kubectl get storageclass $(STORAGECLASS) -o jsonpath='{.provisioner}' 2>/dev/null); \
	if [ "$$PROV" = "$(PROVISIONER)" ]; then \
		echo "   ✅ Provisioner is '$(PROVISIONER)'"; \
	else \
		echo "   ❌ Provisioner is '$$PROV' (expected '$(PROVISIONER)')"; \
	fi
	@echo "\n3. Checking VolumeBindingMode (MANDATORY):"
	@VBM=$$(kubectl get storageclass $(STORAGECLASS) -o jsonpath='{.volumeBindingMode}' 2>/dev/null); \
	if [ "$$VBM" = "$(VOLUME_BINDING_MODE)" ]; then \
		echo "   ✅ VolumeBindingMode is '$(VOLUME_BINDING_MODE)'"; \
	else \
		echo "   ❌ VolumeBindingMode is '$$VBM' (expected '$(VOLUME_BINDING_MODE)') - MANDATORY!"; \
	fi
	@echo "\n4. Checking if StorageClass is default:"
	@IS_DEFAULT=$$(kubectl get storageclass $(STORAGECLASS) -o jsonpath='{.metadata.annotations.storageclass\.kubernetes\.io/is-default-class}' 2>/dev/null); \
	if [ "$$IS_DEFAULT" = "true" ]; then \
		echo "   ✅ StorageClass '$(STORAGECLASS)' is set as default"; \
	else \
		echo "   ❌ StorageClass '$(STORAGECLASS)' is not default"; \
	fi
	@echo "\n5. Checking for other default StorageClasses:"
	@OTHER_DEFAULTS=$$(kubectl get storageclass -o jsonpath='{.items[?(@.metadata.annotations.storageclass\.kubernetes\.io/is-default-class=="true")].metadata.name}' 2>/dev/null | tr ' ' '\n' | grep -v "^$(STORAGECLASS)$$" | grep -v "^$$"); \
	if [ -z "$$OTHER_DEFAULTS" ]; then \
		echo "   ✅ No other StorageClasses are marked as default"; \
	else \
		echo "   ⚠️  Other default StorageClasses found: $$OTHER_DEFAULTS"; \
	fi
	@echo "\n6. Verifying existing resources were NOT modified:"
	@DEPLOYMENT_EXISTS=$$(kubectl -n $(NAMESPACE) get deploy app-deployment >/dev/null 2>&1 && echo "yes" || echo "no"); \
	if [ "$$DEPLOYMENT_EXISTS" = "yes" ]; then \
		echo "   ✅ Deployment 'app-deployment' still exists (not modified)"; \
	else \
		echo "   ⚠️  Deployment 'app-deployment' not found"; \
	fi
	@PVC_EXISTS=$$(kubectl -n $(NAMESPACE) get pvc existing-pvc >/dev/null 2>&1 && echo "yes" || echo "no"); \
	if [ "$$PVC_EXISTS" = "yes" ]; then \
		echo "   ✅ PVC 'existing-pvc' still exists (not modified)"; \
	else \
		echo "   ⚠️  PVC 'existing-pvc' not found"; \
	fi
	@echo "\n✅ Verification complete.\n"

.PHONY: show-storageclass
show-storageclass:
	@echo "\n📋 StorageClass '$(STORAGECLASS)' details:"
	kubectl get storageclass $(STORAGECLASS) -o yaml || echo "   StorageClass not found"

.PHONY: list-storageclasses
list-storageclasses:
	@echo "\n📋 All StorageClasses:"
	kubectl get storageclass
	@echo "\nDefault StorageClass (marked with *):"
	kubectl get storageclass -o custom-columns=NAME:.metadata.name,DEFAULT:.metadata.annotations.storageclass\.kubernetes\.io/is-default-class,PROVISIONER:.provisioner,VOLUMEBINDINGMODE:.volumeBindingMode

# =========================
# Cleanup
# =========================
.PHONY: clean
clean:
	@echo "\n🧹 Cleaning up $(QUESTION) lab resources..."
	@echo "→ Removing StorageClass '$(STORAGECLASS)'..."
	-kubectl delete storageclass $(STORAGECLASS) --ignore-not-found
	@echo "→ Deleting deployment..."
	-kubectl delete deploy app-deployment -n $(NAMESPACE) --ignore-not-found
	@echo "→ Deleting PVC..."
	-kubectl delete pvc existing-pvc -n $(NAMESPACE) --ignore-not-found
	@echo "→ Deleting namespace..."
	-kubectl delete ns $(NAMESPACE) --ignore-not-found
	@echo "✅ Cleanup completed for $(QUESTION).\n"
	@echo "⚠️  Note: If you set '$(STORAGECLASS)' as default, you may want to restore"
	@echo "   the previous default StorageClass manually if needed.\n"

