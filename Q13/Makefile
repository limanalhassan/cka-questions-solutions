# =========================
# CKA LAB - QUESTION 13 (NetworkPolicy Configuration)
# =========================
QUESTION := Q13
FRONTEND_NS := frontend
BACKEND_NS := backend
NETPOL_DIR := ~/netpol
YAML := q13.yaml
SOLUTION := solution.yaml

# =========================
# Default workflow
# =========================
.PHONY: all
all: clean setup
	@echo "\n✅ $(QUESTION) environment ready."
	@echo "   Inspect deployments and choose a NetworkPolicy from $(NETPOL_DIR) to apply.\n"

# =========================
# Environment Setup
# =========================
.PHONY: setup
setup:
	@echo "\n🔧 Setting up $(QUESTION) environment..."
	kubectl apply -f $(YAML)
	@echo "\n⏳ Waiting for deployments to be ready..."
	kubectl -n $(FRONTEND_NS) rollout status deploy/frontend --timeout=120s
	kubectl -n $(BACKEND_NS) rollout status deploy/backend --timeout=120s
	@echo "\n📁 Creating NetworkPolicy files in $(NETPOL_DIR)..."
	@./create-netpol-files.sh $(NETPOL_DIR)
	@echo "   ✅ NetworkPolicy files created in $(NETPOL_DIR)"
	@echo "   Files: netpol-1.yaml (most restrictive), netpol-2.yaml (least restrictive), netpol-3.yaml (moderate)"
	@echo "✅ Environment setup complete.\n"

# =========================
# Solution Application
# =========================
.PHONY: solution
solution:
	@echo "\n🚀 Applying solution:"
	@echo "\n   Step 1: Inspecting deployments..."
	@echo "   Frontend deployment:"
	kubectl get deploy frontend -n $(FRONTEND_NS) -o wide
	@echo "\n   Backend deployment:"
	kubectl get deploy backend -n $(BACKEND_NS) -o wide
	@echo "\n   Backend service:"
	kubectl get svc backend -n $(BACKEND_NS)
	@echo "\n   Step 2: Applying most restrictive NetworkPolicy (netpol-1.yaml)..."
	kubectl apply -f $(NETPOL_DIR)/netpol-1.yaml
	@echo "\n   Step 3: Verifying NetworkPolicies..."
	kubectl get netpol -n $(FRONTEND_NS)
	kubectl get netpol -n $(BACKEND_NS)
	@echo "\n   Step 4: Testing communication..."
	@sleep 3
	@POD=$$(kubectl -n $(FRONTEND_NS) get pods -l app=frontend -o jsonpath='{.items[0].metadata.name}' 2>/dev/null); \
	if [ -n "$$POD" ]; then \
		echo "   Testing from frontend pod: $$POD"; \
		kubectl -n $(FRONTEND_NS) exec $$POD -- curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" --max-time 5 http://backend.backend.svc.cluster.local:8080 || \
		echo "   ⚠️  Connection test failed (may need to wait for policies to propagate)"; \
	else \
		echo "   ⚠️  No frontend pods found"; \
	fi
	@echo "\n✅ Solution applied. Run 'make verify' to confirm.\n"

.PHONY: apply-netpol
apply-netpol:
	@echo "\n🔧 Applying NetworkPolicy from $(NETPOL_DIR)..."
	@if [ -z "$(FILE)" ]; then \
		echo "   Usage: make apply-netpol FILE=netpol-1.yaml"; \
		echo "   Available files:"; \
		ls -1 $(NETPOL_DIR)/*.yaml 2>/dev/null || echo "   No files found"; \
		exit 1; \
	fi
	kubectl apply -f $(NETPOL_DIR)/$(FILE)
	@echo "✅ NetworkPolicy applied.\n"

# =========================
# Verification
# =========================
.PHONY: status
status:
	@echo "\n📊 $(QUESTION) Environment Summary:"
	@echo "\nNamespaces:"
	kubectl get ns $(FRONTEND_NS) $(BACKEND_NS)
	@echo "\nFrontend Deployment:"
	kubectl -n $(FRONTEND_NS) get deploy frontend
	@echo "\nBackend Deployment:"
	kubectl -n $(BACKEND_NS) get deploy backend
	@echo "\nBackend Service:"
	kubectl -n $(BACKEND_NS) get svc backend
	@echo "\nNetworkPolicies in frontend namespace:"
	kubectl -n $(FRONTEND_NS) get netpol
	@echo "\nNetworkPolicies in backend namespace:"
	kubectl -n $(BACKEND_NS) get netpol
	@echo "\nNetworkPolicy files in $(NETPOL_DIR):"
	@ls -la $(NETPOL_DIR)/*.yaml 2>/dev/null || echo "   No files found"

.PHONY: verify
verify:
	@echo "\n🔍 Verifying solution..."
	@echo "\n1. Checking deny-all NetworkPolicies exist (must not be deleted):"
	@if kubectl -n $(FRONTEND_NS) get netpol deny-all >/dev/null 2>&1; then \
		echo "   ✅ deny-all NetworkPolicy exists in frontend namespace"; \
	else \
		echo "   ❌ deny-all NetworkPolicy missing in frontend namespace (should not be deleted!)"; \
	fi
	@if kubectl -n $(BACKEND_NS) get netpol deny-all >/dev/null 2>&1; then \
		echo "   ✅ deny-all NetworkPolicy exists in backend namespace"; \
	else \
		echo "   ❌ deny-all NetworkPolicy missing in backend namespace (should not be deleted!)"; \
	fi
	@echo "\n2. Checking for additional NetworkPolicies:"
	@FRONTEND_OTHER=$$(kubectl -n $(FRONTEND_NS) get netpol --no-headers 2>/dev/null | grep -v deny-all | wc -l | tr -d ' '); \
	BACKEND_OTHER=$$(kubectl -n $(BACKEND_NS) get netpol --no-headers 2>/dev/null | grep -v deny-all | wc -l | tr -d ' '); \
	if [ "$$FRONTEND_OTHER" -gt 0 ] || [ "$$BACKEND_OTHER" -gt 0 ]; then \
		echo "   ✅ Additional NetworkPolicies found (frontend: $$FRONTEND_OTHER, backend: $$BACKEND_OTHER)"; \
	else \
		echo "   ⚠️  No additional NetworkPolicies found (may need to apply one)"; \
	fi
	@echo "\n3. Testing frontend to backend communication:"
	@POD=$$(kubectl -n $(FRONTEND_NS) get pods -l app=frontend -o jsonpath='{.items[0].metadata.name}' 2>/dev/null); \
	if [ -n "$$POD" ]; then \
		echo "   Testing from frontend pod: $$POD"; \
		RESULT=$$(kubectl -n $(FRONTEND_NS) exec $$POD -- curl -s -o /dev/null -w "%{http_code}" --max-time 5 http://backend.backend.svc.cluster.local:8080 2>/dev/null || echo "000"); \
		if [ "$$RESULT" = "200" ] || [ "$$RESULT" = "403" ] || [ "$$RESULT" = "404" ]; then \
			echo "   ✅ Communication successful (HTTP $$RESULT)"; \
		else \
			echo "   ⚠️  Communication test returned: $$RESULT (may indicate policy issue)"; \
		fi; \
	else \
		echo "   ⚠️  No frontend pods found"; \
	fi
	@echo "\n✅ Verification complete.\n"

.PHONY: inspect
inspect:
	@echo "\n🔍 Inspecting deployments and services..."
	@echo "\nFrontend Deployment:"
	kubectl -n $(FRONTEND_NS) get deploy frontend -o yaml | grep -A 10 "labels:\|ports:\|env:"
	@echo "\nBackend Deployment:"
	kubectl -n $(BACKEND_NS) get deploy backend -o yaml | grep -A 10 "labels:\|ports:"
	@echo "\nBackend Service:"
	kubectl -n $(BACKEND_NS) get svc backend -o yaml | grep -A 5 "selector:\|ports:"

.PHONY: list-netpol
list-netpol:
	@echo "\n📋 NetworkPolicy files in $(NETPOL_DIR):"
	@ls -la $(NETPOL_DIR)/*.yaml 2>/dev/null || echo "   No files found"
	@echo "\n📄 Contents:"
	@for file in $(NETPOL_DIR)/*.yaml; do \
		if [ -f "$$file" ]; then \
			echo "\n--- $$file ---"; \
			cat $$file; \
		fi; \
	done

.PHONY: test-communication
test-communication:
	@echo "\n🧪 Testing frontend to backend communication..."
	@POD=$$(kubectl -n $(FRONTEND_NS) get pods -l app=frontend -o jsonpath='{.items[0].metadata.name}' 2>/dev/null); \
	if [ -n "$$POD" ]; then \
		echo "   Frontend pod: $$POD"; \
		echo "   Testing connection to backend.backend.svc.cluster.local:8080..."; \
		kubectl -n $(FRONTEND_NS) exec $$POD -- curl -v --max-time 5 http://backend.backend.svc.cluster.local:8080 2>&1 | head -20 || \
		echo "   ⚠️  Connection failed"; \
	else \
		echo "   ❌ No frontend pods found"; \
	fi

# =========================
# Cleanup
# =========================
.PHONY: clean
clean:
	@echo "\n🧹 Cleaning up $(QUESTION) lab resources..."
	@echo "→ Deleting NetworkPolicies (except deny-all)..."
	-kubectl delete netpol -n $(FRONTEND_NS) --field-selector metadata.name!=deny-all --ignore-not-found
	-kubectl delete netpol -n $(BACKEND_NS) --field-selector metadata.name!=deny-all --ignore-not-found
	@echo "→ Deleting deployments..."
	-kubectl delete deploy frontend -n $(FRONTEND_NS) --ignore-not-found
	-kubectl delete deploy backend -n $(BACKEND_NS) --ignore-not-found
	@echo "→ Deleting services..."
	-kubectl delete svc backend -n $(BACKEND_NS) --ignore-not-found
	@echo "→ Deleting namespaces..."
	-kubectl delete ns $(FRONTEND_NS) --ignore-not-found
	-kubectl delete ns $(BACKEND_NS) --ignore-not-found
	@echo "→ Removing NetworkPolicy files..."
	-rm -rf $(NETPOL_DIR)
	@echo "✅ Cleanup completed for $(QUESTION).\n"

