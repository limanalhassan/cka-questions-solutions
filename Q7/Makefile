# =========================
# CKA LAB - QUESTION 7 (Deployment Port & NodePort Service)
# =========================
QUESTION := Q7
NAMESPACE := sp-culator
DEPLOYMENT := front-end
CONTAINER := nginx
SERVICE := front-end-svc
PORT := 80
YAML := q7.yaml
SOLUTION := solution.yaml

# =========================
# Default workflow
# =========================
.PHONY: all
all: clean setup
	@echo "\n✅ $(QUESTION) environment ready."
	@echo "   Reconfigure the deployment and create the service manually or run 'make solution'.\n"

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
	@echo "\n🚀 Applying solution:"
	@echo "\n   Step 1: Reconfiguring deployment to expose port $(PORT)/tcp..."
	kubectl patch deployment $(DEPLOYMENT) -n $(NAMESPACE) --type='json' \
		-p='[{"op": "add", "path": "/spec/template/spec/containers/0/ports", "value": [{"containerPort": $(PORT), "protocol": "TCP"}]}]'
	@echo "\n   Step 2: Creating NodePort service '$(SERVICE)'..."
	kubectl expose deployment $(DEPLOYMENT) -n $(NAMESPACE) \
		--name=$(SERVICE) \
		--port=$(PORT) \
		--target-port=$(PORT) \
		--type=NodePort || \
		(kubectl apply -f $(SOLUTION) && \
		 echo "   Service created from solution.yaml")
	@echo "\n⏳ Waiting for deployment rollout to complete..."
	kubectl -n $(NAMESPACE) rollout status deploy/$(DEPLOYMENT) --timeout=120s
	@echo "\n✅ Solution applied. Run 'make verify' to confirm.\n"

.PHONY: patch-deployment
patch-deployment:
	@echo "\n🔧 Patching deployment to expose port $(PORT)/tcp..."
	kubectl patch deployment $(DEPLOYMENT) -n $(NAMESPACE) --type='json' \
		-p='[{"op": "add", "path": "/spec/template/spec/containers/0/ports", "value": [{"containerPort": $(PORT), "protocol": "TCP"}]}]'
	@echo "✅ Deployment patched.\n"

.PHONY: create-service
create-service:
	@echo "\n🔧 Creating NodePort service..."
	kubectl expose deployment $(DEPLOYMENT) -n $(NAMESPACE) \
		--name=$(SERVICE) \
		--port=$(PORT) \
		--target-port=$(PORT) \
		--type=NodePort
	@echo "✅ Service created.\n"

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
	@echo "\nService:"
	kubectl -n $(NAMESPACE) get svc $(SERVICE) 2>/dev/null || echo "   Service '$(SERVICE)' not found"
	@echo "\nDeployment Container Ports:"
	kubectl -n $(NAMESPACE) get deploy $(DEPLOYMENT) -o jsonpath='{.spec.template.spec.containers[0].ports}' || echo "   No ports configured"

.PHONY: verify
verify:
	@echo "\n🔍 Verifying solution..."
	@echo "\n1. Checking deployment port configuration:"
	@PORTS=$$(kubectl -n $(NAMESPACE) get deploy $(DEPLOYMENT) -o jsonpath='{.spec.template.spec.containers[0].ports[0].containerPort}' 2>/dev/null); \
	if [ "$$PORTS" = "$(PORT)" ]; then \
		echo "   ✅ Port $(PORT)/tcp is exposed in deployment"; \
	else \
		echo "   ❌ Port $(PORT)/tcp is not configured in deployment"; \
	fi
	@echo "\n2. Checking service exists:"
	@kubectl -n $(NAMESPACE) get svc $(SERVICE) >/dev/null 2>&1 && \
		echo "   ✅ Service '$(SERVICE)' exists" || \
		echo "   ❌ Service '$(SERVICE)' not found"
	@echo "\n3. Checking service type:"
	@SVC_TYPE=$$(kubectl -n $(NAMESPACE) get svc $(SERVICE) -o jsonpath='{.spec.type}' 2>/dev/null); \
	if [ "$$SVC_TYPE" = "NodePort" ]; then \
		echo "   ✅ Service type is NodePort"; \
	else \
		echo "   ⚠️  Service type is '$$SVC_TYPE' (expected NodePort)"; \
	fi
	@echo "\n4. Checking service port:"
	@SVC_PORT=$$(kubectl -n $(NAMESPACE) get svc $(SERVICE) -o jsonpath='{.spec.ports[0].port}' 2>/dev/null); \
	if [ "$$SVC_PORT" = "$(PORT)" ]; then \
		echo "   ✅ Service port is $(PORT)"; \
	else \
		echo "   ⚠️  Service port is '$$SVC_PORT' (expected $(PORT))"; \
	fi
	@echo "\n5. Checking service target port:"
	@TARGET_PORT=$$(kubectl -n $(NAMESPACE) get svc $(SERVICE) -o jsonpath='{.spec.ports[0].targetPort}' 2>/dev/null); \
	if [ "$$TARGET_PORT" = "$(PORT)" ] || [ "$$TARGET_PORT" = "\"$(PORT)\"" ]; then \
		echo "   ✅ Service target port is $(PORT)"; \
	else \
		echo "   ⚠️  Service target port is '$$TARGET_PORT' (expected $(PORT))"; \
	fi
	@echo "\n6. Checking service selector:"
	@SELECTOR=$$(kubectl -n $(NAMESPACE) get svc $(SERVICE) -o jsonpath='{.spec.selector.app}' 2>/dev/null); \
	if [ "$$SELECTOR" = "$(DEPLOYMENT)" ]; then \
		echo "   ✅ Service selector matches deployment labels"; \
	else \
		echo "   ⚠️  Service selector is '$$SELECTOR'"; \
	fi
	@echo "\n✅ Verification complete.\n"

.PHONY: test
test:
	@echo "\n🧪 Testing NodePort service..."
	@NODE_PORT=$$(kubectl -n $(NAMESPACE) get svc $(SERVICE) -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null); \
	if [ -z "$$NODE_PORT" ]; then \
		echo "   ❌ Service not found or NodePort not assigned"; \
		exit 1; \
	fi; \
	echo "   NodePort: $$NODE_PORT"; \
	echo "   Testing connection..."; \
	kubectl -n $(NAMESPACE) run test-curl --image=curlimages/curl:latest --rm -i --restart=Never -- \
		curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" http://$(SERVICE).$(NAMESPACE).svc.cluster.local:$(PORT) || \
		echo "   ⚠️  Could not test service (pods may still be starting)"

# =========================
# Cleanup
# =========================
.PHONY: clean
clean:
	@echo "\n🧹 Cleaning up $(QUESTION) lab resources..."
	@echo "→ Deleting service..."
	-kubectl delete svc $(SERVICE) -n $(NAMESPACE) --ignore-not-found
	@echo "→ Deleting deployment..."
	-kubectl delete deploy $(DEPLOYMENT) -n $(NAMESPACE) --ignore-not-found
	@echo "→ Deleting namespace..."
	-kubectl delete ns $(NAMESPACE) --ignore-not-found
	@echo "✅ Cleanup completed for $(QUESTION).\n"

