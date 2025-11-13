# =========================
# NGINX TLSv1.3 LAB - MAKEFILE
# =========================
NAMESPACE := nginx-static
DEPLOY := nginx-static
CONFIG := nginx-config
SECRET := nginx-tls
CERT := tls.crt
KEY := tls.key
PORT := 8443

# Default target
.PHONY: all
all: setup cert deploy forward test

# -------------------------
# Step 1: Create Namespace and ConfigMap
# -------------------------
.PHONY: setup
setup:
	@echo "\n🔧 Creating namespace and configmap..."
	kubectl create ns $(NAMESPACE) --dry-run=client -o yaml | kubectl apply -f -
	kubectl apply -f q1.yaml

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
	kubectl apply -f q1.yaml
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
# Step 6: Restart deployment after config changes
# -------------------------
.PHONY: restart
restart:
	@echo "\n🔁 Restarting deployment..."
	kubectl -n $(NAMESPACE) rollout restart deploy/$(DEPLOY)
	kubectl -n $(NAMESPACE) rollout status deploy/$(DEPLOY)

# -------------------------
# Step 7: Cleanup everything
# -------------------------
.PHONY: clean
clean:
	@echo "\n🧹 Cleaning up all lab resources..."
	kubectl delete ns $(NAMESPACE) --ignore-not-found
	rm -f $(CERT) $(KEY)
