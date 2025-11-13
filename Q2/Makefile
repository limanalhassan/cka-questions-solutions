# =========================
# CKA LAB - QUESTION 2 (Ingress → Gateway API Migration)
# =========================
QUESTION := Q2
NAMESPACE := web-ns
NAMESPACE_GATEWAY := nginx-gateway
DEPLOY := web
SECRET := web-tls
CERT := web.crt
KEY := web.key
YAML := q2.yaml
SOLUTION := solution.yaml
PORT := 8080

# Gateway API CRD + Controller (v2.2.0)
GATEWAY_VERSION := v1.1.0
GATEWAY_MANIFEST := https://github.com/kubernetes-sigs/gateway-api/releases/download/$(GATEWAY_VERSION)/standard-install.yaml
NGINX_CONTROLLER_REF := v2.2.0
NGINX_CONTROLLER_MANIFEST := https://raw.githubusercontent.com/nginx/nginx-gateway-fabric/$(NGINX_CONTROLLER_REF)/deploy/default/deploy.yaml
NGINX_CRD_MANIFEST := https://raw.githubusercontent.com/nginx/nginx-gateway-fabric/$(NGINX_CONTROLLER_REF)/deploy/crds.yaml
NGINX_GATEWAY_NS := nginx-gateway

# =========================
# Default workflow
# =========================
.PHONY: all
all: clean cert gateway-crds nginx-crds gateway-controller setup deploy test
	@echo "\n✅ $(QUESTION) base (Ingress) environment ready.\n"

# =========================
# Gateway API CRDs (core)
# =========================
.PHONY: gateway-crds
gateway-crds:
	@echo "\n🔍 Checking if Gateway API CRDs are installed..."
	@if ! kubectl get crd gateways.gateway.networking.k8s.io >/dev/null 2>&1; then \
		echo "\n📦 Installing Gateway API CRDs ($(GATEWAY_VERSION))..."; \
		kubectl apply -f $(GATEWAY_MANIFEST); \
	else \
		echo "✅ Gateway API CRDs already installed."; \
	fi
	@echo "\n🔎 Verifying CRDs..."
	kubectl get crd | grep gateway.networking.k8s.io || echo "⚠️ Gateway CRDs not found — check install."

# =========================
# NGINX Gateway Fabric CRDs
# =========================
.PHONY: nginx-crds
nginx-crds:
	@echo "\n🔍 Checking if NGINX Gateway Fabric CRDs are installed..."
	@if ! kubectl get crd nginxgateways.gateway.nginx.org >/dev/null 2>&1; then \
		echo "\n📦 Installing NGINX Gateway Fabric CRDs ($(NGINX_CONTROLLER_REF))..."; \
		kubectl apply --server-side -f $(NGINX_CRD_MANIFEST); \
		echo "✅ NGINX Gateway Fabric CRDs installed."; \
	else \
		echo "✅ NGINX Gateway Fabric CRDs already installed."; \
	fi
	@echo "\n🔎 Verifying NGINX CRDs..."
	kubectl get crd | grep gateway.nginx.org || echo "⚠️ NGINX Gateway CRDs not found."

# =========================
# NGINX Gateway Fabric Controller
# =========================
.PHONY: gateway-controller
gateway-controller: nginx-crds
	@echo "\n🔍 Checking for NGINX Gateway controller..."
	@if ! kubectl get deployment -n $(NGINX_GATEWAY_NS) nginx-gateway >/dev/null 2>&1; then \
		echo "\n📦 Installing NGINX Gateway Fabric (ref: $(NGINX_CONTROLLER_REF))..."; \
		kubectl apply -f $(NGINX_CONTROLLER_MANIFEST); \
		echo "\n⏳ Waiting for cert-generator job to complete..."; \
		timeout=60; \
		while [ $$timeout -gt 0 ] && ! kubectl get secret -n $(NGINX_GATEWAY_NS) server-tls >/dev/null 2>&1; do \
			echo "   Waiting for server-tls secret... ($$timeout seconds remaining)"; \
			sleep 2; \
			timeout=$$((timeout-2)); \
		done; \
		if kubectl get secret -n $(NGINX_GATEWAY_NS) server-tls >/dev/null 2>&1; then \
			echo "✅ server-tls secret created."; \
		else \
			echo "⚠️  server-tls secret not found, but continuing..."; \
		fi; \
		echo "\n⏳ Waiting for controller to become ready..."; \
		kubectl rollout status deploy/nginx-gateway -n $(NGINX_GATEWAY_NS) --timeout=180s; \
	else \
		echo "✅ NGINX Gateway controller already installed."; \
	fi

# =========================
# Environment Setup / Cleanup
# =========================
.PHONY: clean
clean:
	@echo "\n🧹 Cleaning up $(QUESTION) lab resources..."
	@echo "→ Deleting lab namespace $(NAMESPACE)..."
	-kubectl delete ns $(NAMESPACE) --ignore-not-found
	@echo "→ Removing TLS cert and key..."
	rm -f $(CERT) $(KEY)
	@echo "→ Removing Gateway API CRDs ($(GATEWAY_VERSION))..."
	-kubectl delete -f $(GATEWAY_MANIFEST) --ignore-not-found
	@echo "→ Removing Solution deployment ($(SOLUTION))..."
	-kubectl delete -f $(SOLUTION) --ignore-not-found
	@echo "→ Removing NGINX Gateway Fabric controller (ref: $(NGINX_CONTROLLER_REF))..."
	-kubectl delete -f $(NGINX_CONTROLLER_MANIFEST) --ignore-not-found
	@echo "→ Removing NGINX Gateway Fabric CRDs..."
	-kubectl delete -f $(NGINX_CRD_MANIFEST) --ignore-not-found
	@echo "✅ Full cleanup completed for $(QUESTION).\n"


.PHONY: cert
cert:
	@echo "\n🔐 Generating TLS cert for $(QUESTION)..."
	kubectl get ns $(NAMESPACE) >/dev/null 2>&1 || kubectl create ns $(NAMESPACE)
	kubectl get ns $(NAMESPACE_GATEWAY) >/dev/null 2>&1 || kubectl create ns $(NAMESPACE_GATEWAY)
	openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
		-subj "/CN=gateway.web.k8s.local" \
		-keyout $(KEY) -out $(CERT)
	kubectl -n $(NAMESPACE) create secret tls $(SECRET) \
		--cert=$(CERT) --key=$(KEY) --dry-run=client -o yaml | kubectl apply -f -
	@echo "✅ TLS secret $(SECRET) created in $(NAMESPACE).\n"
	

.PHONY: setup
setup:
	@echo "\n🔧 Applying $(QUESTION) base YAML ($(YAML))..."
	kubectl create ns $(NAMESPACE) --dry-run=client -o yaml | kubectl apply -f -
	kubectl apply -f $(YAML)
	@echo "✅ Ingress-based setup applied.\n"

.PHONY: deploy
deploy:
	@echo "\n🚀 Waiting for $(DEPLOY) pods..."
	kubectl -n $(NAMESPACE) rollout status deploy/$(DEPLOY)
	@echo "✅ $(DEPLOY) deployment ready.\n"

# =========================
# Testing / Validation
# =========================
.PHONY: test
test:
	@echo "\n🧪 Testing via port-forward (Ingress setup)..."
	kubectl -n $(NAMESPACE) port-forward svc/web $(PORT):80 & \
	sleep 3 && curl -s http://localhost:$(PORT) && pkill -f "port-forward"
	@echo "\n✅ Basic Ingress connectivity OK.\n"

.PHONY: forward
forward:
	@kubectl -n $(NAMESPACE) port-forward svc/web $(PORT):80

.PHONY: validate
validate:
	@echo "\n🔍 Checking Gateway/HTTPRoute status..."
	kubectl -n $(NAMESPACE) get gateway,httproute
	kubectl -n $(NAMESPACE) get events --sort-by=.metadata.creationTimestamp | tail -n 10

# =========================
# Gateway Solution Application
# =========================
.PHONY: solution
solution: gateway-crds nginx-crds gateway-controller
	@echo "\n🚀 Applying Gateway + HTTPRoute solution..."
	kubectl -n $(NAMESPACE) apply -f $(SOLUTION)
	@echo "\n✅ Solution applied. Checking resources..."
	kubectl -n $(NAMESPACE) get gateway,httproute | grep -E "web-gateway|web-route"
	@echo "\n🔎 Run 'make validate' or 'make test-gateway' to confirm functionality.\n"

.PHONY: test-gateway
test-gateway:
	@echo "\n🌐 Testing Gateway API via port-forward..."
	@GATEWAY_SVC=$$(kubectl -n $(NAMESPACE) get svc -l gateway.nginx.org/owning-gateway-name=web-gateway -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "web-gateway-nginx"); \
	if [ -z "$$GATEWAY_SVC" ] || [ "$$GATEWAY_SVC" = "web-gateway-nginx" ]; then \
		GATEWAY_SVC="web-gateway-nginx"; \
	fi; \
	echo "Port-forwarding Gateway service: $$GATEWAY_SVC"; \
	kubectl -n $(NAMESPACE) port-forward svc/$$GATEWAY_SVC 8443:443 & \
	sleep 3 && curl -k --resolve gateway.web.k8s.local:8443:127.0.0.1 https://gateway.web.k8s.local:8443 && pkill -f "port-forward"
	@echo "\n✅ Gateway HTTPS routing verified.\n"

.PHONY: forward-gateway
forward-gateway:
	@echo "\n🔌 Port-forwarding Gateway service to localhost:8443..."
	@echo "   Access via: curl -k --resolve gateway.web.k8s.local:8443:127.0.0.1 https://gateway.web.k8s.local:8443"
	@echo "   Press Ctrl+C to stop\n"
	@GATEWAY_SVC=$$(kubectl -n $(NAMESPACE) get svc -l gateway.nginx.org/owning-gateway-name=web-gateway -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "web-gateway-nginx"); \
	if [ -z "$$GATEWAY_SVC" ] || [ "$$GATEWAY_SVC" = "web-gateway-nginx" ]; then \
		GATEWAY_SVC="web-gateway-nginx"; \
	fi; \
	kubectl -n $(NAMESPACE) port-forward svc/$$GATEWAY_SVC 8443:443

.PHONY: delete-ingress
delete-ingress:
	@echo "\n🗑️  Deleting Ingress resource 'web' (step 4 of migration)..."
	kubectl -n $(NAMESPACE) delete ingress web
	@echo "✅ Ingress resource deleted. Migration complete!\n"

.PHONY: status
status:
	@echo "\n📊 $(QUESTION) Environment Summary:"
	kubectl get ns $(NAMESPACE)
	kubectl -n $(NAMESPACE) get all
	kubectl get gatewayclass
	kubectl -n $(NAMESPACE) get gateway,httproute
	kubectl -n $(NAMESPACE) get ingress