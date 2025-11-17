# =========================
# CKA LAB - QUESTION 8 (Sidecar Container for Logging)
# =========================
QUESTION := Q8
NAMESPACE := synergy
DEPLOYMENT := synergy-deployment
CONTAINER := app
SIDECAR := sidecar
YAML := q8.yaml
SOLUTION := solution.yaml

# =========================
# Default workflow
# =========================
.PHONY: all
all: clean setup
	@echo "\n✅ $(QUESTION) environment ready."
	@echo "   Add the sidecar container manually or run 'make solution'.\n"

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
	@echo "\n🚀 Applying solution: Adding sidecar container for logging..."
	@echo "\n   Step 1: Adding shared volume and sidecar container..."
	kubectl patch deployment $(DEPLOYMENT) -n $(NAMESPACE) --type='json' \
		-p='[{"op": "add", "path": "/spec/template/spec/volumes", "value": [{"name": "log-volume", "emptyDir": {}}]}, {"op": "add", "path": "/spec/template/spec/containers/0/volumeMounts", "value": [{"name": "log-volume", "mountPath": "/var/log"}]}, {"op": "add", "path": "/spec/template/spec/containers/-", "value": {"name": "$(SIDECAR)", "image": "busybox:stable", "command": ["/bin/sh", "-c"], "args": ["tail -n+l -f /var/log/synergy-deployment.log"], "volumeMounts": [{"name": "log-volume", "mountPath": "/var/log"}]}}]'
	@echo "\n⏳ Waiting for deployment rollout to complete..."
	kubectl -n $(NAMESPACE) rollout status deploy/$(DEPLOYMENT) --timeout=120s
	@echo "\n✅ Solution applied. Run 'make verify' to confirm.\n"

.PHONY: add-volume
add-volume:
	@echo "\n🔧 Adding shared volume to deployment..."
	kubectl patch deployment $(DEPLOYMENT) -n $(NAMESPACE) --type='json' \
		-p='[{"op": "add", "path": "/spec/template/spec/volumes", "value": [{"name": "log-volume", "emptyDir": {}}]}]'
	@echo "✅ Volume added.\n"

.PHONY: mount-volume-app
mount-volume-app:
	@echo "\n🔧 Mounting volume in app container..."
	kubectl patch deployment $(DEPLOYMENT) -n $(NAMESPACE) --type='json' \
		-p='[{"op": "add", "path": "/spec/template/spec/containers/0/volumeMounts", "value": [{"name": "log-volume", "mountPath": "/var/log"}]}]'
	@echo "✅ Volume mounted in app container.\n"

.PHONY: add-sidecar
add-sidecar:
	@echo "\n🔧 Adding sidecar container..."
	kubectl patch deployment $(DEPLOYMENT) -n $(NAMESPACE) --type='json' \
		-p='[{"op": "add", "path": "/spec/template/spec/containers/-", "value": {"name": "$(SIDECAR)", "image": "busybox:stable", "command": ["/bin/sh", "-c"], "args": ["tail -n+l -f /var/log/synergy-deployment.log"], "volumeMounts": [{"name": "log-volume", "mountPath": "/var/log"}]}}]'
	@echo "✅ Sidecar container added.\n"

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
	kubectl -n $(NAMESPACE) get pods -l app=synergy
	@echo "\nPod Containers:"
	@for pod in $$(kubectl -n $(NAMESPACE) get pods -l app=synergy -o name); do \
		echo "\n   $$pod:"; \
		kubectl -n $(NAMESPACE) get $$pod -o jsonpath='{.spec.containers[*].name}' | tr ' ' '\n' | sed 's/^/     - /'; \
	done

.PHONY: verify
verify:
	@echo "\n🔍 Verifying solution..."
	@echo "\n1. Checking for shared volume:"
	@VOLUME=$$(kubectl -n $(NAMESPACE) get deploy $(DEPLOYMENT) -o jsonpath='{.spec.template.spec.volumes[0].name}' 2>/dev/null); \
	if [ "$$VOLUME" = "log-volume" ]; then \
		echo "   ✅ Shared volume 'log-volume' exists"; \
	else \
		echo "   ❌ Shared volume not found"; \
	fi
	@echo "\n2. Checking app container volume mount:"
	@APP_MOUNT=$$(kubectl -n $(NAMESPACE) get deploy $(DEPLOYMENT) -o jsonpath='{.spec.template.spec.containers[0].volumeMounts[0].mountPath}' 2>/dev/null); \
	if [ "$$APP_MOUNT" = "/var/log" ]; then \
		echo "   ✅ App container has volume mounted at /var/log"; \
	else \
		echo "   ❌ App container volume mount not found or incorrect"; \
	fi
	@echo "\n3. Checking sidecar container exists:"
	@SIDECAR_EXISTS=$$(kubectl -n $(NAMESPACE) get deploy $(DEPLOYMENT) -o jsonpath='{.spec.template.spec.containers[?(@.name=="$(SIDECAR)")].name}' 2>/dev/null); \
	if [ "$$SIDECAR_EXISTS" = "$(SIDECAR)" ]; then \
		echo "   ✅ Sidecar container '$(SIDECAR)' exists"; \
	else \
		echo "   ❌ Sidecar container '$(SIDECAR)' not found"; \
	fi
	@echo "\n4. Checking sidecar image:"
	@SIDECAR_IMAGE=$$(kubectl -n $(NAMESPACE) get deploy $(DEPLOYMENT) -o jsonpath='{.spec.template.spec.containers[?(@.name=="$(SIDECAR)")].image}' 2>/dev/null); \
	if [ "$$SIDECAR_IMAGE" = "busybox:stable" ]; then \
		echo "   ✅ Sidecar image is busybox:stable"; \
	else \
		echo "   ⚠️  Sidecar image is '$$SIDECAR_IMAGE' (expected busybox:stable)"; \
	fi
	@echo "\n5. Checking sidecar command:"
	@SIDECAR_CMD=$$(kubectl -n $(NAMESPACE) get deploy $(DEPLOYMENT) -o jsonpath='{.spec.template.spec.containers[?(@.name=="$(SIDECAR)")].command[0]}' 2>/dev/null); \
	if [ "$$SIDECAR_CMD" = "/bin/sh" ]; then \
		echo "   ✅ Sidecar command is correct"; \
	else \
		echo "   ⚠️  Sidecar command may be incorrect"; \
	fi
	@echo "\n6. Checking sidecar volume mount:"
	@SIDECAR_MOUNT=$$(kubectl -n $(NAMESPACE) get deploy $(DEPLOYMENT) -o jsonpath='{.spec.template.spec.containers[?(@.name=="$(SIDECAR)")].volumeMounts[0].mountPath}' 2>/dev/null); \
	if [ "$$SIDECAR_MOUNT" = "/var/log" ]; then \
		echo "   ✅ Sidecar has volume mounted at /var/log"; \
	else \
		echo "   ❌ Sidecar volume mount not found or incorrect"; \
	fi
	@echo "\n7. Checking pod containers:"
	@POD=$$(kubectl -n $(NAMESPACE) get pods -l app=synergy -o jsonpath='{.items[0].metadata.name}' 2>/dev/null); \
	if [ -n "$$POD" ]; then \
		CONTAINERS=$$(kubectl -n $(NAMESPACE) get pod $$POD -o jsonpath='{.spec.containers[*].name}'); \
		if echo "$$CONTAINERS" | grep -q "$(SIDECAR)"; then \
			echo "   ✅ Pod has sidecar container"; \
		else \
			echo "   ⚠️  Pod containers: $$CONTAINERS"; \
		fi \
	else \
		echo "   ⚠️  No pods found"; \
	fi
	@echo "\n✅ Verification complete.\n"

.PHONY: logs
logs:
	@echo "\n📋 Viewing logs from sidecar container..."
	@POD=$$(kubectl -n $(NAMESPACE) get pods -l app=synergy -o jsonpath='{.items[0].metadata.name}' 2>/dev/null); \
	if [ -n "$$POD" ]; then \
		echo "   Pod: $$POD"; \
		echo "   Sidecar logs:"; \
		kubectl -n $(NAMESPACE) logs $$POD -c $(SIDECAR) --tail=20 || echo "   ⚠️  Could not retrieve logs (pod may still be starting)"; \
	else \
		echo "   ❌ No pods found"; \
	fi

.PHONY: test
test:
	@echo "\n🧪 Testing sidecar logging..."
	@echo "   Waiting a few seconds for logs to be generated..."
	@sleep 5
	@POD=$$(kubectl -n $(NAMESPACE) get pods -l app=synergy -o jsonpath='{.items[0].metadata.name}' 2>/dev/null); \
	if [ -n "$$POD" ]; then \
		echo "\n   Testing: kubectl logs $$POD -c $(SIDECAR)"; \
		kubectl -n $(NAMESPACE) logs $$POD -c $(SIDECAR) --tail=5 || echo "   ⚠️  Could not retrieve logs"; \
		echo "\n   ✅ If you see log entries above, the sidecar is working!"; \
	else \
		echo "   ❌ No pods found"; \
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

