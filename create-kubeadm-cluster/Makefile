CONTROL_PLANE_VM := kubeadm-cp
WORKER_VM_PREFIX := kubeadm-worker
SETUP_SCRIPT := setup-multipass-cluster.sh
WORKER_SCRIPT := add-worker-node.sh
KUBECONFIG := /tmp/kubeconfig-multipass.yaml

.PHONY: help
help:
	@echo "\n🚀 Kubeadm Cluster Creation Utility"
	@echo "===================================="
	@echo ""
	@echo "Available targets:"
	@echo ""
	@echo "  make cluster    - Create a complete kubeadm cluster using Multipass"
	@echo "  make clean      - Delete all Multipass VMs and cleanup"
	@echo "  make status     - Show cluster status"
	@echo "  make shell      - Access control plane VM shell"
	@echo "  make kubeconfig - Get kubeconfig for local access"
	@echo ""

.PHONY: cluster create
cluster create:
	@echo "\n🚀 Creating kubeadm cluster..."
	@if ! command -v multipass >/dev/null 2>&1; then \
		echo "❌ Multipass is not installed."; \
		echo ""; \
		echo "Install it with:"; \
		echo "  macOS: brew install multipass"; \
		echo "  Windows: choco install multipass"; \
		echo "  Linux: snap install multipass"; \
		exit 1; \
	fi
	@if [ ! -f $(SETUP_SCRIPT) ]; then \
		echo "❌ Setup script not found: $(SETUP_SCRIPT)"; \
		exit 1; \
	fi
	@bash $(SETUP_SCRIPT)

.PHONY: status
status:
	@echo "\n📊 Cluster Status"
	@echo "=================="
	@echo ""
	@if ! command -v multipass >/dev/null 2>&1; then \
		echo "❌ Multipass is not installed."; \
		exit 1; \
	fi
	@if ! multipass list | grep -q "$(CONTROL_PLANE_VM)"; then \
		echo "⚠️  No cluster found. Run 'make cluster' to create one."; \
		exit 0; \
	fi
	@echo "📋 Multipass VMs:"
	@multipass list | grep -E "NAME|$(CONTROL_PLANE_VM)|$(WORKER_VM_PREFIX)" || echo "   No VMs found"
	@echo ""
	@echo "📋 Cluster Status (from control plane):"
	@multipass exec $(CONTROL_PLANE_VM) -- bash -c "kubectl get nodes 2>/dev/null || echo '   ⚠️  kubectl not available or cluster not ready'" || echo "   ⚠️  Could not connect to control plane"
	@echo ""
	@echo "📋 System Pods:"
	@multipass exec $(CONTROL_PLANE_VM) -- bash -c "kubectl get pods -n kube-system 2>/dev/null | head -10 || echo '   ⚠️  kubectl not available'" || echo "   ⚠️  Could not connect to control plane"
	@echo ""

.PHONY: shell
shell:
	@echo "\n🔌 Accessing control plane VM..."
	@if ! command -v multipass >/dev/null 2>&1; then \
		echo "❌ Multipass is not installed."; \
		exit 1; \
	fi
	@if ! multipass list | grep -q "$(CONTROL_PLANE_VM)"; then \
		echo "❌ Control plane VM not found. Run 'make cluster' first."; \
		exit 1; \
	fi
	@multipass shell $(CONTROL_PLANE_VM)

.PHONY: kubeconfig
kubeconfig:
	@echo "\n📋 Getting kubeconfig..."
	@if ! command -v multipass >/dev/null 2>&1; then \
		echo "❌ Multipass is not installed."; \
		exit 1; \
	fi
	@if ! multipass list | grep -q "$(CONTROL_PLANE_VM)"; then \
		echo "❌ Control plane VM not found. Run 'make cluster' first."; \
		exit 1; \
	fi
	@echo "📤 Copying kubeconfig from control plane..."
	@multipass exec $(CONTROL_PLANE_VM) -- cat /home/ubuntu/.kube/config > $(KUBECONFIG) 2>/dev/null || \
		multipass exec $(CONTROL_PLANE_VM) -- sudo cat /etc/kubernetes/admin.conf > $(KUBECONFIG) 2>/dev/null || \
		(echo "❌ Could not get kubeconfig" && exit 1)
	@CP_IP=$$(multipass info $(CONTROL_PLANE_VM) | grep IPv4 | awk '{print $$2}'); \
	if [ -n "$$CP_IP" ]; then \
		echo "🔧 Updating kubeconfig with control plane IP: $$CP_IP"; \
		if [[ "$$OSTYPE" == "darwin"* ]]; then \
			sed -i.bak "s/127.0.0.1/$$CP_IP/g" $(KUBECONFIG); \
			sed -i.bak "s/localhost/$$CP_IP/g" $(KUBECONFIG); \
			rm -f $(KUBECONFIG).bak; \
		else \
			sed -i "s/127.0.0.1/$$CP_IP/g" $(KUBECONFIG); \
			sed -i "s/localhost/$$CP_IP/g" $(KUBECONFIG); \
		fi; \
	fi
	@echo "✅ Kubeconfig saved to: $(KUBECONFIG)"
	@echo "   export KUBECONFIG=$(KUBECONFIG)"

.PHONY: clean
clean:
	@echo "\n🧹 Cleaning up VMs..."
	@if ! command -v multipass >/dev/null 2>&1; then \
		echo "❌ Multipass is not installed."; \
		exit 1; \
	fi
	@if ! multipass list | grep -q "$(CONTROL_PLANE_VM)"; then \
		echo "⚠️  No VMs found. Nothing to clean up."; \
		exit 0; \
	fi
	@echo "⚠️  This will delete all VMs:"
	@multipass list | grep -E "NAME|$(CONTROL_PLANE_VM)|$(WORKER_VM_PREFIX)" || echo "   No VMs found"
	@echo ""
	@read -p "Are you sure? (y/N) " -n 1 -r; \
	echo; \
	if [[ ! $$REPLY =~ ^[Yy]$$ ]]; then \
		echo "Cancelled."; \
		exit 0; \
	fi
	@echo "🗑️  Deleting VMs..."
	@multipass delete $(CONTROL_PLANE_VM) 2>/dev/null || true
	@for i in 1 2 3 4 5; do \
		multipass delete "$(WORKER_VM_PREFIX)-$$i" 2>/dev/null || true; \
	done
	@multipass purge 2>/dev/null || true
	@rm -f $(KUBECONFIG)

.DEFAULT_GOAL := help
