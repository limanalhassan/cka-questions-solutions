# =========================
# CKA LAB - QUESTION 3 (Horizontal Pod Autoscaler)
# =========================
QUESTION := Q3
NAMESPACE := autoscale
DEPLOY := apache-server
YAML := q3.yaml
SOLUTION := solution.yaml

# =========================
# Default workflow
# =========================
.PHONY: all
all: clean setup deploy
	@echo "\n✅ $(QUESTION) environment ready."
	@echo "   Deployment '$(DEPLOY)' is running in namespace '$(NAMESPACE)'."
	@echo "   Create the HPA manually or run 'make solution' to apply the solution.\n"

# =========================
# Environment Setup
# =========================
.PHONY: setup
setup:
	@echo "\n🔧 Setting up $(QUESTION) environment..."
	kubectl create ns $(NAMESPACE) --dry-run=client -o yaml | kubectl apply -f -
	kubectl apply -f $(YAML)
	@echo "✅ Environment setup complete.\n"

.PHONY: deploy
deploy:
	@echo "\n🚀 Waiting for $(DEPLOY) deployment..."
	kubectl -n $(NAMESPACE) rollout status deploy/$(DEPLOY)
	@echo "✅ $(DEPLOY) deployment ready.\n"

# =========================
# Solution Application
# =========================
.PHONY: solution
solution:
	@echo "\n🚀 Applying HPA solution..."
	kubectl apply -f $(SOLUTION)
	@echo "\n✅ HPA solution applied."
	@echo "\n🔍 Checking HPA status..."
	kubectl -n $(NAMESPACE) get hpa $(DEPLOY)
	@echo "\n📊 HPA Details:"
	kubectl -n $(NAMESPACE) describe hpa $(DEPLOY)
	@echo "\n✅ Solution applied successfully.\n"

# =========================
# Testing / Validation
# =========================
.PHONY: status
status:
	@echo "\n📊 $(QUESTION) Environment Summary:"
	@echo "\nNamespace:"
	kubectl get ns $(NAMESPACE)
	@echo "\nDeployment:"
	kubectl -n $(NAMESPACE) get deploy $(DEPLOY)
	@echo "\nPods:"
	kubectl -n $(NAMESPACE) get pods -l app=$(DEPLOY)
	@echo "\nHPA:"
	kubectl -n $(NAMESPACE) get hpa $(DEPLOY) 2>/dev/null || echo "   No HPA found. Run 'make solution' to create it."
	@echo "\nService:"
	kubectl -n $(NAMESPACE) get svc $(DEPLOY)

.PHONY: watch
watch:
	@echo "\n👀 Watching HPA and Pods (Press Ctrl+C to stop)..."
	@echo "   HPA Status:"
	kubectl -n $(NAMESPACE) get hpa $(DEPLOY) -w &
	@echo "\n   Pod Status:"
	kubectl -n $(NAMESPACE) get pods -l app=$(DEPLOY) -w

# =========================
# Cleanup
# =========================
.PHONY: clean
clean:
	@echo "\n🧹 Cleaning up $(QUESTION) lab resources..."
	@echo "→ Deleting namespace $(NAMESPACE)..."
	-kubectl delete ns $(NAMESPACE) --ignore-not-found
	@echo "✅ Cleanup completed for $(QUESTION).\n"

