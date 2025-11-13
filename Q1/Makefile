# =========================
# NGINX TLSv1.3 LAB - MAKEFILE
# =========================
QUESTION := Q1
NAMESPACE := nginx-static
DEPLOY := nginx-static
CONFIG := nginx-config
SECRET := nginx-tls
CERT := tls.crt
KEY := tls.key
PORT := 8443
YAML := q1.yaml
SOLUTION := solution.yaml

# Default target
.PHONY: all
all: clean setup cert deploy
	@echo "\n✅ $(QUESTION) environment ready."
	@echo "   Run 'make solution' to apply the fix, or create the ConfigMap manually.\n"

# -------------------------
# Step 1: Create Namespace and ConfigMap
# -------------------------
.PHONY: setup
setup:
	@echo "\n🔧 Creating namespace and configmap..."
	kubectl create ns $(NAMESPACE) --dry-run=client -o yaml | kubectl apply -f -
	kubectl apply -f $(YAML)

# -------------------------
# Step 2: Create TLS Secret
# -------------------------
.PHONY: cert
cert:
	@echo "\n🔐 Generating self-signed TLS cert..."
	# Ensure namespace exists first
	kubectl get ns $(NAMESPACE) >/dev/null 2>&1 || kubectl create ns $(NAMESPACE)
	openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
		-subj "/CN=web.k8s.local" \
		-keyout $(KEY) -out $(CERT)
	kubectl -n $(NAMESPACE) create secret tls $(SECRET) \
		--cert=$(CERT) --key=$(KEY) --dry-run=client -o yaml | kubectl apply -f -
	@echo "\n✅ Secret $(SECRET) created in namespace $(NAMESPACE)."

# -------------------------
# Step 3: Deploy NGINX
# -------------------------
.PHONY: deploy
deploy:
	@echo "\n🚀 Deploying NGINX..."
	kubectl apply -f $(YAML)
	@echo "\n🔁 Waiting for pods to be ready..."
	kubectl -n $(NAMESPACE) rollout status deploy/$(DEPLOY)

# -------------------------
# Step 4: Port-forward
# -------------------------
.PHONY: forward
forward:
	@echo "\n🌐 Port-forwarding to localhost:$(PORT)..."
	@echo "Press Ctrl+C to stop forwarding."
	kubectl -n $(NAMESPACE) port-forward deploy/$(DEPLOY) $(PORT):443

# -------------------------
# Step 5: Test TLS 1.2 (should succeed before fix, fail after)
# -------------------------
.PHONY: test
test:
	@echo "\n🧪 Testing TLS 1.2 connection..."
	curl -k --tls-max 1.2 https://localhost:$(PORT) || true

# -------------------------
# Step 6: Apply Solution
# -------------------------
.PHONY: solution
solution:
	@echo "\n🚀 Applying solution (TLSv1.3 only ConfigMap)..."
	kubectl apply -f $(SOLUTION)
	@echo "\n✅ Solution applied. Restarting deployment to apply changes..."
	kubectl -n $(NAMESPACE) rollout restart deploy/$(DEPLOY)
	kubectl -n $(NAMESPACE) rollout status deploy/$(DEPLOY)
	@echo "\n✅ Solution applied successfully."
	@echo "   TLS 1.2 connections should now fail."
	@echo "   TLS 1.3 connections should still work.\n"

# -------------------------
# Step 7: Restart deployment after config changes
# -------------------------
.PHONY: restart
restart:
	@echo "\n🔁 Restarting deployment..."
	kubectl -n $(NAMESPACE) rollout restart deploy/$(DEPLOY)
	kubectl -n $(NAMESPACE) rollout status deploy/$(DEPLOY)

# -------------------------
# Step 8: Cleanup everything
# -------------------------
.PHONY: clean
clean:
	@echo "\n🧹 Cleaning up all lab resources..."
	kubectl delete ns $(NAMESPACE) --ignore-not-found
	rm -f $(CERT) $(KEY)
