# =========================
# CKA LAB - QUESTION 10 (WordPress Resource Requests)
# =========================
QUESTION := Q10
NAMESPACE := relative-fawn
DEPLOYMENT := wordpress
CPU_REQUEST := 300m
MEMORY_REQUEST := 589Mi
REPLICAS := 3
YAML := q10.yaml
SOLUTION := solution.yaml

# Node resources (for reference)
NODE_CPU := 1000m
NODE_MEMORY := 2015360ki
OVERHEAD_CPU := 100m
OVERHEAD_MEMORY := 200Mi

# =========================
# Default workflow
# =========================
.PHONY: all
all: clean setup
	@echo "\n✅ $(QUESTION) environment ready."
	@echo "   Adjust resource requests manually or run 'make solution'.\n"

# =========================
# Environment Setup
# =========================
.PHONY: setup
setup:
	@echo "\n🔧 Setting up $(QUESTION) environment..."
	kubectl apply -f $(YAML)
	@echo "\n⏳ Waiting for deployment to be ready..."
	kubectl -n $(NAMESPACE) rollout status deploy/$(DEPLOYMENT) --timeout=120s
	@echo "✅ Environment setup complete.\n"

# =========================
# Solution Application
# =========================
.PHONY: solution
solution:
	@echo "\n🚀 Applying solution: Adjusting resource requests..."
	@echo "\n   Node Resources:"
	@echo "     CPU: $(NODE_CPU)"
	@echo "     Memory: $(NODE_MEMORY)"
	@echo "\n   Calculation:"
	@echo "     Overhead: $(OVERHEAD_CPU) CPU, $(OVERHEAD_MEMORY) memory"
	@echo "     Available for pods: $$(($(NODE_CPU:%=%)) - $(OVERHEAD_CPU:%=%))m CPU, ~1768 MiB memory"
	@echo "     Per pod ($(REPLICAS) replicas): $(CPU_REQUEST) CPU, $(MEMORY_REQUEST) memory"
	@echo "\n   Step 1: Scaling deployment to 0 replicas (helper tip)..."
	kubectl scale deployment $(DEPLOYMENT) -n $(NAMESPACE) --replicas=0
	@echo "\n   Step 2: Adding resource requests to all containers..."
	kubectl patch deployment $(DEPLOYMENT) -n $(NAMESPACE) --type='json' \
		-p='[{"op": "add", "path": "/spec/template/spec/initContainers/0/resources", "value": {"requests": {"cpu": "$(CPU_REQUEST)", "memory": "$(MEMORY_REQUEST)"}}}, {"op": "add", "path": "/spec/template/spec/initContainers/1/resources", "value": {"requests": {"cpu": "$(CPU_REQUEST)", "memory": "$(MEMORY_REQUEST)"}}}, {"op": "add", "path": "/spec/template/spec/containers/0/resources/requests", "value": {"cpu": "$(CPU_REQUEST)", "memory": "$(MEMORY_REQUEST)"}}]'
	@echo "\n   Step 3: Scaling back to $(REPLICAS) replicas..."
	kubectl scale deployment $(DEPLOYMENT) -n $(NAMESPACE) --replicas=$(REPLICAS)
	@echo "\n⏳ Waiting for deployment rollout to complete..."
	kubectl -n $(NAMESPACE) rollout status deploy/$(DEPLOYMENT) --timeout=120s
	@echo "\n✅ Solution applied. Run 'make verify' to confirm.\n"

.PHONY: scale-down
scale-down:
	@echo "\n🔧 Scaling deployment to 0 replicas..."
	kubectl scale deployment $(DEPLOYMENT) -n $(NAMESPACE) --replicas=0
	@echo "✅ Deployment scaled down.\n"

.PHONY: add-requests
add-requests:
	@echo "\n🔧 Adding resource requests to all containers..."
	kubectl patch deployment $(DEPLOYMENT) -n $(NAMESPACE) --type='json' \
		-p='[{"op": "add", "path": "/spec/template/spec/initContainers/0/resources", "value": {"requests": {"cpu": "$(CPU_REQUEST)", "memory": "$(MEMORY_REQUEST)"}}}, {"op": "add", "path": "/spec/template/spec/initContainers/1/resources", "value": {"requests": {"cpu": "$(CPU_REQUEST)", "memory": "$(MEMORY_REQUEST)"}}}, {"op": "add", "path": "/spec/template/spec/containers/0/resources/requests", "value": {"cpu": "$(CPU_REQUEST)", "memory": "$(MEMORY_REQUEST)"}}]'
	@echo "✅ Resource requests added.\n"

.PHONY: scale-up
scale-up:
	@echo "\n🔧 Scaling deployment to $(REPLICAS) replicas..."
	kubectl scale deployment $(DEPLOYMENT) -n $(NAMESPACE) --replicas=$(REPLICAS)
	@echo "✅ Deployment scaled up.\n"

# =========================
# Verification
# =========================
.PHONY: status
status:
	@echo "\n📊 $(QUESTION) Environment Summary:"
	@echo "\nNamespace:"
	kubectl get ns $(NAMESPACE)
	@echo "\nDeployment:"
	kubectl -n $(NAMESPACE) get deploy $(DEPLOYMENT)
	@echo "\nPods:"
	kubectl -n $(NAMESPACE) get pods -l app=$(DEPLOYMENT)
	@echo "\nResource Requests (from deployment spec):"
	@echo "  Init Containers:"
	kubectl -n $(NAMESPACE) get deploy $(DEPLOYMENT) -o jsonpath='{.spec.template.spec.initContainers[*].resources.requests}' || echo "    Not set"
	@echo "\n  Main Container:"
	kubectl -n $(NAMESPACE) get deploy $(DEPLOYMENT) -o jsonpath='{.spec.template.spec.containers[0].resources.requests}' || echo "    Not set"

.PHONY: verify
verify:
	@echo "\n🔍 Verifying solution..."
	@echo "\n1. Checking deployment replicas:"
	@REPLICAS_COUNT=$$(kubectl -n $(NAMESPACE) get deploy $(DEPLOYMENT) -o jsonpath='{.spec.replicas}' 2>/dev/null); \
	if [ "$$REPLICAS_COUNT" = "$(REPLICAS)" ]; then \
		echo "   ✅ Deployment has $(REPLICAS) replicas"; \
	else \
		echo "   ⚠️  Deployment has $$REPLICAS_COUNT replicas (expected $(REPLICAS))"; \
	fi
	@echo "\n2. Checking pod status:"
	@READY_PODS=$$(kubectl -n $(NAMESPACE) get pods -l app=$(DEPLOYMENT) --field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l | tr -d ' '); \
	TOTAL_PODS=$$(kubectl -n $(NAMESPACE) get pods -l app=$(DEPLOYMENT) --no-headers 2>/dev/null | wc -l | tr -d ' '); \
	if [ "$$READY_PODS" = "$(REPLICAS)" ] && [ "$$TOTAL_PODS" = "$(REPLICAS)" ]; then \
		echo "   ✅ All $(REPLICAS) pods are running"; \
	else \
		echo "   ⚠️  $$READY_PODS/$$TOTAL_PODS pods running (expected $(REPLICAS))"; \
	fi
	@echo "\n3. Checking init container 1 resource requests:"
	@INIT1_CPU=$$(kubectl -n $(NAMESPACE) get deploy $(DEPLOYMENT) -o jsonpath='{.spec.template.spec.initContainers[0].resources.requests.cpu}' 2>/dev/null); \
	INIT1_MEM=$$(kubectl -n $(NAMESPACE) get deploy $(DEPLOYMENT) -o jsonpath='{.spec.template.spec.initContainers[0].resources.requests.memory}' 2>/dev/null); \
	if [ "$$INIT1_CPU" = "$(CPU_REQUEST)" ] && [ "$$INIT1_MEM" = "$(MEMORY_REQUEST)" ]; then \
		echo "   ✅ Init container 1: CPU=$(CPU_REQUEST), Memory=$(MEMORY_REQUEST)"; \
	else \
		echo "   ⚠️  Init container 1: CPU=$$INIT1_CPU, Memory=$$INIT1_MEM (expected CPU=$(CPU_REQUEST), Memory=$(MEMORY_REQUEST))"; \
	fi
	@echo "\n4. Checking init container 2 resource requests:"
	@INIT2_CPU=$$(kubectl -n $(NAMESPACE) get deploy $(DEPLOYMENT) -o jsonpath='{.spec.template.spec.initContainers[1].resources.requests.cpu}' 2>/dev/null); \
	INIT2_MEM=$$(kubectl -n $(NAMESPACE) get deploy $(DEPLOYMENT) -o jsonpath='{.spec.template.spec.initContainers[1].resources.requests.memory}' 2>/dev/null); \
	if [ "$$INIT2_CPU" = "$(CPU_REQUEST)" ] && [ "$$INIT2_MEM" = "$(MEMORY_REQUEST)" ]; then \
		echo "   ✅ Init container 2: CPU=$(CPU_REQUEST), Memory=$(MEMORY_REQUEST)"; \
	else \
		echo "   ⚠️  Init container 2: CPU=$$INIT2_CPU, Memory=$$INIT2_MEM (expected CPU=$(CPU_REQUEST), Memory=$(MEMORY_REQUEST))"; \
	fi
	@echo "\n5. Checking main container resource requests:"
	@MAIN_CPU=$$(kubectl -n $(NAMESPACE) get deploy $(DEPLOYMENT) -o jsonpath='{.spec.template.spec.containers[0].resources.requests.cpu}' 2>/dev/null); \
	MAIN_MEM=$$(kubectl -n $(NAMESPACE) get deploy $(DEPLOYMENT) -o jsonpath='{.spec.template.spec.containers[0].resources.requests.memory}' 2>/dev/null); \
	if [ "$$MAIN_CPU" = "$(CPU_REQUEST)" ] && [ "$$MAIN_MEM" = "$(MEMORY_REQUEST)" ]; then \
		echo "   ✅ Main container: CPU=$(CPU_REQUEST), Memory=$(MEMORY_REQUEST)"; \
	else \
		echo "   ⚠️  Main container: CPU=$$MAIN_CPU, Memory=$$MAIN_MEM (expected CPU=$(CPU_REQUEST), Memory=$(MEMORY_REQUEST))"; \
	fi
	@echo "\n6. Verifying all containers have same requests:"
	@ALL_SAME=$$(kubectl -n $(NAMESPACE) get deploy $(DEPLOYMENT) -o jsonpath='{.spec.template.spec.initContainers[0].resources.requests.cpu}{" "}{.spec.template.spec.initContainers[1].resources.requests.cpu}{" "}{.spec.template.spec.containers[0].resources.requests.cpu}' 2>/dev/null); \
	if echo "$$ALL_SAME" | grep -q "^$(CPU_REQUEST) $(CPU_REQUEST) $(CPU_REQUEST)$$"; then \
		echo "   ✅ All containers have the same CPU request ($(CPU_REQUEST))"; \
	else \
		echo "   ⚠️  CPU requests are not consistent"; \
	fi
	@echo "\n✅ Verification complete.\n"

.PHONY: show-resources
show-resources:
	@echo "\n📋 Resource requests for all containers:"
	@echo "\nInit Container 1 (init-db):"
	kubectl -n $(NAMESPACE) get deploy $(DEPLOYMENT) -o jsonpath='{.spec.template.spec.initContainers[0].resources}' | jq '.' 2>/dev/null || kubectl -n $(NAMESPACE) get deploy $(DEPLOYMENT) -o jsonpath='{.spec.template.spec.initContainers[0].resources}'
	@echo "\n\nInit Container 2 (init-config):"
	kubectl -n $(NAMESPACE) get deploy $(DEPLOYMENT) -o jsonpath='{.spec.template.spec.initContainers[1].resources}' | jq '.' 2>/dev/null || kubectl -n $(NAMESPACE) get deploy $(DEPLOYMENT) -o jsonpath='{.spec.template.spec.initContainers[1].resources}'
	@echo "\n\nMain Container (wordpress):"
	kubectl -n $(NAMESPACE) get deploy $(DEPLOYMENT) -o jsonpath='{.spec.template.spec.containers[0].resources}' | jq '.' 2>/dev/null || kubectl -n $(NAMESPACE) get deploy $(DEPLOYMENT) -o jsonpath='{.spec.template.spec.containers[0].resources}'
	@echo "\n"

.PHONY: pod-resources
pod-resources:
	@echo "\n📋 Resource requests from running pods:"
	@POD=$$(kubectl -n $(NAMESPACE) get pods -l app=$(DEPLOYMENT) -o jsonpath='{.items[0].metadata.name}' 2>/dev/null); \
	if [ -n "$$POD" ]; then \
		echo "\nPod: $$POD"; \
		kubectl -n $(NAMESPACE) describe pod $$POD | grep -A 10 "Requests:" || echo "   No resource requests found"; \
	else \
		echo "   No pods found"; \
	fi

# =========================
# Cleanup
# =========================
.PHONY: clean
clean:
	@echo "\n🧹 Cleaning up $(QUESTION) lab resources..."
	@echo "→ Deleting deployment..."
	-kubectl delete deploy $(DEPLOYMENT) -n $(NAMESPACE) --ignore-not-found
	@echo "→ Deleting namespace..."
	-kubectl delete ns $(NAMESPACE) --ignore-not-found
	@echo "✅ Cleanup completed for $(QUESTION).\n"

