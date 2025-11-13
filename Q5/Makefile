# =========================
# CKA LAB - QUESTION 5 (PriorityClass)
# =========================
QUESTION := Q5
NAMESPACE := priority
DEPLOY := busybox-logger
YAML := q5.yaml
SOLUTION := solution.yaml

# =========================
# Default workflow
# =========================
.PHONY: all
all: clean setup deploy
	@echo "\n✅ $(QUESTION) environment ready."
	@echo "   Create the PriorityClass and patch the deployment manually, or run 'make solution'.\n"

# =========================
# Environment Setup
# =========================
.PHONY: setup
setup:
	@echo "\n🔧 Setting up $(QUESTION) environment..."
	kubectl apply -f $(YAML)
	@echo "✅ Environment setup complete.\n"

.PHONY: deploy
deploy:
	@echo "\n🚀 Waiting for deployments..."
	kubectl -n $(NAMESPACE) rollout status deploy/$(DEPLOY) --timeout=60s || echo "⚠️  Deployment may take longer to be ready."
	kubectl -n $(NAMESPACE) rollout status deploy/low-priority-app --timeout=60s || true
	kubectl -n $(NAMESPACE) rollout status deploy/medium-priority-app --timeout=60s || true
	@echo "✅ Deployments ready.\n"

# =========================
# Solution Application
# =========================
.PHONY: solution
solution:
	@echo "\n🚀 Applying PriorityClass solution..."
	@echo "   Step 1: Finding highest existing PriorityClass value..."
	@HIGHEST=$$(kubectl get priorityclass -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.value}{"\n"}{end}' | grep -v "system-" | sort -k2 -n | tail -1 | awk '{print $$2}'); \
	if [ -z "$$HIGHEST" ]; then \
		HIGHEST=1000; \
		echo "   No user-defined PriorityClass found, using default: 1000"; \
	else \
		echo "   Highest PriorityClass value: $$HIGHEST"; \
	fi; \
	NEW_VALUE=$$((HIGHEST - 1)); \
	echo "   Creating high-priority PriorityClass with value: $$NEW_VALUE"; \
	kubectl apply -f - <<EOF || echo "⚠️  Failed to create PriorityClass"; \
apiVersion: scheduling.k8s.io/v1 \
kind: PriorityClass \
metadata: \
  name: high-priority \
value: $$NEW_VALUE \
description: "High priority class for user-workloads" \
globalDefault: false \
EOF
	@echo "\n   Step 2: Patching busybox-logger deployment..."
	kubectl patch deployment $(DEPLOY) -n $(NAMESPACE) \
		-p '{"spec":{"template":{"spec":{"priorityClassName":"high-priority"}}}}'
	@echo "\n   Step 3: Waiting for rollout..."
	kubectl -n $(NAMESPACE) rollout status deploy/$(DEPLOY) --timeout=120s
	@echo "\n✅ Solution applied successfully."
	@echo "   Check pod status with 'make status' to see eviction effects.\n"

# =========================
# Verification
# =========================
.PHONY: status
status:
	@echo "\n📊 $(QUESTION) Environment Summary:"
	@echo "\nNamespace:"
	kubectl get ns $(NAMESPACE)
	@echo "\nPriorityClasses:"
	kubectl get priorityclass
	@echo "\nDeployments:"
	kubectl -n $(NAMESPACE) get deployments
	@echo "\nPods (showing priority):"
	kubectl -n $(NAMESPACE) get pods -o custom-columns=NAME:.metadata.name,STATUS:.status.phase,PRIORITY:.spec.priorityClassName,NODE:.spec.nodeName
	@echo "\nPod Details:"
	kubectl -n $(NAMESPACE) get pods -o wide

.PHONY: verify
verify:
	@echo "\n🔍 Verifying solution..."
	@echo "\n1. Checking if high-priority PriorityClass exists:"
	@kubectl get priorityclass high-priority && echo "   ✅ high-priority PriorityClass found" || echo "   ❌ high-priority PriorityClass not found"
	@echo "\n2. Checking busybox-logger deployment priority:"
	@PRIORITY=$$(kubectl -n $(NAMESPACE) get deployment $(DEPLOY) -o jsonpath='{.spec.template.spec.priorityClassName}'); \
	if [ "$$PRIORITY" = "high-priority" ]; then \
		echo "   ✅ busybox-logger uses high-priority"; \
	else \
		echo "   ❌ busybox-logger does not use high-priority (current: $$PRIORITY)"; \
	fi
	@echo "\n3. Checking deployment rollout status:"
	@kubectl -n $(NAMESPACE) rollout status deploy/$(DEPLOY) --timeout=5s && echo "   ✅ Deployment rolled out successfully" || echo "   ⚠️  Deployment may still be rolling out"
	@echo "\n4. Pod status:"
	@kubectl -n $(NAMESPACE) get pods -l app=$(DEPLOY) -o custom-columns=NAME:.metadata.name,STATUS:.status.phase,PRIORITY:.spec.priorityClassName
	@echo "\n✅ Verification complete.\n"

# =========================
# Cleanup
# =========================
.PHONY: clean
clean:
	@echo "\n🧹 Cleaning up $(QUESTION) lab resources..."
	@echo "→ Deleting namespace $(NAMESPACE)..."
	-kubectl delete ns $(NAMESPACE) --ignore-not-found
	@echo "→ Removing PriorityClasses..."
	-kubectl delete priorityclass low-priority medium-priority default-priority high-priority --ignore-not-found
	@echo "✅ Cleanup completed for $(QUESTION).\n"

