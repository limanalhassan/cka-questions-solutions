# =========================
# CKA LAB - QUESTION 14 (Kubeadm Cluster Migration Troubleshooting)
# =========================
QUESTION := Q14
NAMESPACE := cluster-troubleshooting
YAML := q14.yaml
SOLUTION := solution.yaml
SETUP_SCRIPT := setup-kubeadm-cluster.sh
BREAK_SCRIPT := break-cluster.sh
FIX_SCRIPT := fix-cluster.sh
WORKER_SCRIPT := add-worker-node.sh
MULTIPASS_SCRIPT := setup-multipass-cluster.sh

# =========================
# Default workflow
# =========================
.PHONY: all
all: clean setup
	@echo "\n✅ $(QUESTION) environment ready."
	@echo "   This lab requires a real kubeadm cluster."
	@echo "   Use 'make setup-cluster' to set up a kubeadm cluster."
	@echo "   Use 'make break-cluster' to simulate migration issues."
	@echo "   Review the README for detailed troubleshooting steps.\n"

# =========================
# Environment Setup
# =========================
.PHONY: setup
setup:
	@echo "\n🔧 Setting up $(QUESTION) environment..."
	kubectl apply -f $(YAML)
	@echo "\n⏳ Waiting for deployment to be ready..."
	kubectl -n $(NAMESPACE) rollout status deploy/cluster-status-checker --timeout=60s
	@echo "\n📋 Environment setup complete."
	@echo "\n📝 Note: This lab requires a real kubeadm cluster."
	@echo "   Use 'make setup-cluster' to set up a kubeadm cluster."
	@echo "   Use 'make break-cluster' to simulate migration issues."
	@echo "\n   See README.md for detailed instructions.\n"

.PHONY: setup-cluster
setup-cluster:
	@echo "\n🚀 Setting up kubeadm cluster for $(QUESTION)..."
	@echo "\n⚠️  This script requires:"
	@echo "   - Root/sudo privileges"
	@echo "   - Ubuntu/Debian or CentOS/RHEL"
	@echo "   - Internet connection"
	@echo "   - At least 2GB RAM and 2 CPU cores"
	@echo ""
	@if [ -f $(SETUP_SCRIPT) ]; then \
		echo "📋 Running setup script..."; \
		echo "   Run: sudo bash $(SETUP_SCRIPT)"; \
		sudo bash $(SETUP_SCRIPT); \
	else \
		echo "❌ Setup script not found: $(SETUP_SCRIPT)"; \
		echo "   Please ensure the script exists in the current directory."; \
		exit 1; \
	fi

.PHONY: break-cluster
break-cluster:
	@echo "\n⚠️  This will simulate cluster migration issues by changing IPs."
	@echo "   A backup will be created before making changes."
	@echo ""
	@if [ -f $(BREAK_SCRIPT) ]; then \
		echo "🔧 Running break script..."; \
		echo "   Run: sudo bash $(BREAK_SCRIPT)"; \
		sudo bash $(BREAK_SCRIPT); \
	else \
		echo "❌ Break script not found: $(BREAK_SCRIPT)"; \
		echo "   Please ensure the script exists in the current directory."; \
		exit 1; \
	fi

.PHONY: fix-cluster fix
fix-cluster fix:
	@echo "\n🔧 Fixing broken kubeadm cluster..."
	@echo "\n⚠️  This will fix cluster migration issues by updating IPs."
	@echo ""
	@if command -v multipass >/dev/null 2>&1; then \
		if multipass list | grep -q "kubeadm-cp"; then \
			if [ ! -f $(FIX_SCRIPT) ]; then \
				echo "❌ Fix script not found: $(FIX_SCRIPT)"; \
				exit 1; \
			fi; \
			echo "📤 Transferring fix script to control plane VM..."; \
			multipass transfer $(FIX_SCRIPT) kubeadm-cp:/home/ubuntu/ || echo "   ⚠️  Script may already exist"; \
			echo "🔧 Running fix script on control plane VM..."; \
			multipass exec kubeadm-cp -- sudo bash /home/ubuntu/fix-cluster.sh || echo "   ⚠️  Fix script failed"; \
			echo ""; \
			echo "✅ Cluster fixes applied!"; \
			echo ""; \
			echo "📋 Verify cluster status:"; \
			echo "   multipass shell kubeadm-cp"; \
			echo "   kubectl get nodes"; \
			echo "   kubectl get pods -n kube-system"; \
		else \
			echo "⚠️  No Multipass VMs found."; \
			echo "   This script is designed to run on the control plane node."; \
			echo "   If you're on the control plane node, run: sudo bash $(FIX_SCRIPT)"; \
		fi \
	else \
		if [ -f $(FIX_SCRIPT) ]; then \
			echo "🔧 Running fix script..."; \
			echo "   Run: sudo bash $(FIX_SCRIPT)"; \
			sudo bash $(FIX_SCRIPT); \
		else \
			echo "❌ Fix script not found: $(FIX_SCRIPT)"; \
			echo "   Please ensure the script exists in the current directory."; \
			exit 1; \
		fi \
	fi

.PHONY: break
break:
	@echo "\n⚠️  This will break the cluster (simulate migration issues)."
	@echo "   A backup will be created before making changes."
	@echo ""
	@if command -v multipass >/dev/null 2>&1; then \
		if multipass list | grep -q "kubeadm-cp"; then \
			if [ ! -f $(BREAK_SCRIPT) ]; then \
				echo "❌ Break script not found: $(BREAK_SCRIPT)"; \
				exit 1; \
			fi; \
			echo "📤 Transferring break script to control plane VM..."; \
			multipass transfer $(BREAK_SCRIPT) kubeadm-cp:/home/ubuntu/ || echo "   ⚠️  Script may already exist"; \
			echo "🔧 Breaking cluster on control plane VM..."; \
			multipass exec kubeadm-cp -- sudo bash /home/ubuntu/break-cluster.sh || echo "   ⚠️  Break script failed or cluster already broken"; \
			echo ""; \
			echo "✅ Cluster has been broken and is ready for troubleshooting!"; \
			echo ""; \
			echo "📋 Next steps:"; \
			echo "   1. Access the control plane VM: multipass shell kubeadm-cp"; \
			echo "   2. Try kubectl commands (they should fail now): kubectl get nodes"; \
			echo "   3. Identify broken components: check /etc/kubernetes/manifests/kube-apiserver.yaml"; \
			echo "   4. Fix the cluster: make fix"; \
		else \
			echo "⚠️  No Multipass VMs found. Nothing to break."; \
		fi \
	else \
		echo "❌ Multipass is not installed."; \
		exit 1; \
	fi

.PHONY: add-worker
add-worker:
	@echo "\n🚀 Adding worker node to kubeadm cluster..."
	@echo "\n⚠️  This script should be run on the worker node machine."
	@echo "   It will install kubeadm, kubelet, kubectl and join the node to the cluster."
	@echo ""
	@if [ -f $(WORKER_SCRIPT) ]; then \
		echo "📋 Running worker node script..."; \
		echo "   Run: sudo bash $(WORKER_SCRIPT)"; \
		sudo bash $(WORKER_SCRIPT); \
	else \
		echo "❌ Worker script not found: $(WORKER_SCRIPT)"; \
		echo "   Please ensure the script exists in the current directory."; \
		exit 1; \
	fi

.PHONY: setup-multipass cluster
setup-multipass cluster:
	@echo "\n🚀 End-to-end kubeadm cluster setup using Multipass..."
	@echo "\n⚠️  This will:"
	@echo "   - Create control plane VM"
	@echo "   - Create worker VM(s)"
	@echo "   - Set up kubeadm cluster"
	@echo "   - Install CNI plugin"
	@echo "   - Join worker nodes"
	@echo ""
	@if [ -f $(MULTIPASS_SCRIPT) ]; then \
		echo "📋 Running multipass setup script..."; \
		bash $(MULTIPASS_SCRIPT); \
	else \
		echo "❌ Multipass setup script not found: $(MULTIPASS_SCRIPT)"; \
		echo "   Please ensure the script exists in the current directory."; \
		exit 1; \
	fi

.PHONY: lab
lab:
	@echo "\n🎓 Setting up Q14 lab environment..."
	@echo "\n⚠️  This will:"
	@echo "   1. Create and set up a kubeadm cluster"
	@echo "   2. Break the cluster (simulate migration issues)"
	@echo "   3. Make it ready for troubleshooting"
	@echo ""
	@if command -v multipass >/dev/null 2>&1; then \
		if multipass list | grep -q "kubeadm-cp"; then \
			echo "⚠️  Cluster already exists. Breaking it now..."; \
			multipass exec kubeadm-cp -- sudo bash /home/ubuntu/break-cluster.sh || echo "   ⚠️  Break script failed or cluster already broken"; \
			echo ""; \
			echo "✅ Cluster is now broken and ready for troubleshooting!"; \
			echo ""; \
			echo "📋 Next steps:"; \
			echo "   1. Access the control plane VM: multipass shell kubeadm-cp"; \
			echo "   2. Identify broken components: kubectl get nodes, kubectl get pods -n kube-system"; \
			echo "   3. Check logs: sudo journalctl -u kubelet -n 100"; \
			echo "   4. Fix the issues:"; \
			echo "      - Automated: make fix (from macOS)"; \
			echo "      - Manual: Follow solution.yaml steps"; \
			echo "   5. Verify: kubectl get nodes, kubectl get pods --all-namespaces"; \
		else \
			echo "🚀 Creating cluster first..."; \
			$(MAKE) cluster; \
			echo ""; \
			echo "⏳ Waiting for cluster to stabilize..."; \
			sleep 15; \
			echo ""; \
			echo "🔧 Breaking cluster (simulating migration issues)..."; \
			multipass exec kubeadm-cp -- sudo bash /home/ubuntu/break-cluster.sh || echo "   ⚠️  Break script failed"; \
			echo ""; \
			echo "✅ Cluster is now broken and ready for troubleshooting!"; \
			echo ""; \
			echo "📋 Next steps:"; \
			echo "   1. Access the control plane VM: multipass shell kubeadm-cp"; \
			echo "   2. Identify broken components: kubectl get nodes, kubectl get pods -n kube-system"; \
			echo "   3. Check logs: sudo journalctl -u kubelet -n 100"; \
			echo "   4. Fix the issues:"; \
			echo "      - Automated: make fix (from macOS)"; \
			echo "      - Manual: Follow solution.yaml steps"; \
			echo "   5. Verify: kubectl get nodes, kubectl get pods --all-namespaces"; \
		fi \
	else \
		echo "❌ Multipass is not installed."; \
		echo "   Install it first: brew install multipass (macOS) or choco install multipass (Windows)"; \
		exit 1; \
	fi

# =========================
# Solution Application
# =========================
.PHONY: solution
solution:
	@echo "\n🚀 Solution Guide for $(QUESTION):"
	@echo "\n   This lab requires manual troubleshooting of a kubeadm cluster."
	@echo "   The solution involves:"
	@echo "\n   1. IDENTIFY broken components:"
	@echo "      - Check cluster status: kubectl get nodes"
	@echo "      - Check pods: kubectl get pods -n kube-system"
	@echo "      - Check kubelet: systemctl status kubelet"
	@echo "      - Check logs: journalctl -u kubelet -n 100"
	@echo "\n   2. IDENTIFY common issues:"
	@echo "      - etcd endpoints pointing to old IP"
	@echo "      - API server certificate SANs missing new IP"
	@echo "      - kubelet config pointing to old API server"
	@echo "      - kubeconfig files with old server addresses"
	@echo "\n   3. FIX configurations:"
	@echo "      - Update /etc/kubernetes/manifests/kube-apiserver.yaml"
	@echo "      - Update /etc/kubernetes/kubelet.conf"
	@echo "      - Update /etc/kubernetes/admin.conf"
	@echo "      - Update ~/.kube/config"
	@echo "\n   4. RESTART services:"
	@echo "      - sudo systemctl restart kubelet"
	@echo "\n   5. VERIFY cluster health:"
	@echo "      - kubectl get nodes"
	@echo "      - kubectl get pods --all-namespaces"
	@echo "      - kubectl cluster-info"
	@echo "\n   See solution.yaml and README.md for detailed steps.\n"

.PHONY: show-config
show-config:
	@echo "\n📋 Simulated cluster configuration:"
	kubectl -n $(NAMESPACE) get configmap cluster-config -o yaml

.PHONY: check-common-issues
check-common-issues:
	@echo "\n🔍 Common issues to check in a real kubeadm cluster:"
	@echo "\n1. etcd endpoints:"
	@echo "   Check: /etc/kubernetes/manifests/kube-apiserver.yaml"
	@echo "   Look for: --etcd-servers=https://OLD-IP:2379"
	@echo "\n2. API server certificate SANs:"
	@echo "   Check: /etc/kubernetes/manifests/kube-apiserver.yaml"
	@echo "   Check: Certificate includes new control plane IP"
	@echo "\n3. kubelet configuration:"
	@echo "   Check: /etc/kubernetes/kubelet.conf"
	@echo "   Look for: server: https://OLD-IP:6443"
	@echo "\n4. Admin kubeconfig:"
	@echo "   Check: /etc/kubernetes/admin.conf"
	@echo "   Check: /root/.kube/config"
	@echo "   Look for: server: https://OLD-IP:6443"
	@echo "\n5. Static pod manifests:"
	@echo "   Check: /etc/kubernetes/manifests/*.yaml"
	@echo "   Verify all IPs are updated"
	@echo "\n"

# =========================
# Verification
# =========================
.PHONY: status
status:
	@echo "\n📊 $(QUESTION) Environment Summary:"
	@echo "\nNamespace:"
	kubectl get ns $(NAMESPACE)
	@echo "\nDeployment:"
	kubectl -n $(NAMESPACE) get deploy
	@echo "\nPods:"
	kubectl -n $(NAMESPACE) get pods
	@echo "\nConfigMap:"
	kubectl -n $(NAMESPACE) get configmap cluster-config
	@echo "\n"

.PHONY: verify
verify:
	@echo "\n🔍 Verification checklist for kubeadm cluster troubleshooting:"
	@echo "\nIn a real kubeadm cluster, verify:"
	@echo "\n1. Node status:"
	@echo "   kubectl get nodes"
	@echo "   Expected: Node should be Ready"
	@echo "\n2. Control plane pods:"
	@echo "   kubectl get pods -n kube-system"
	@echo "   Expected: kube-apiserver, kube-controller-manager, kube-scheduler should be Running"
	@echo "\n3. All pods:"
	@echo "   kubectl get pods --all-namespaces"
	@echo "   Expected: All pods should be Running or Completed"
	@echo "\n4. API server connectivity:"
	@echo "   kubectl cluster-info"
	@echo "   kubectl get --raw /healthz"
	@echo "   Expected: Should return 'ok'"
	@echo "\n5. etcd connectivity (if accessible):"
	@echo "   kubectl get --raw /healthz/etcd"
	@echo "   Expected: Should return 'ok'"
	@echo "\n6. kubelet service:"
	@echo "   systemctl status kubelet"
	@echo "   Expected: Should be active (running)"
	@echo "\n✅ Verification complete.\n"

.PHONY: simulate-issues
simulate-issues:
	@echo "\n⚠️  Simulated issues in a real kubeadm cluster migration:"
	@echo "\nCommon problems after migration:"
	@echo "1. etcd endpoints still pointing to old machine IP"
	@echo "2. API server certificate doesn't include new control plane IP"
	@echo "3. kubelet configuration has old API server address"
	@echo "4. Admin kubeconfig has old server address"
	@echo "5. Static pod manifests reference old IPs"
	@echo "\nTo fix, you need to:"
	@echo "- Update all IP references to new machine IP"
	@echo "- Update etcd server IP (if using external etcd)"
	@echo "- Regenerate certificates if needed"
	@echo "- Restart kubelet service"
	@echo "\nSee solution.yaml for detailed fix steps."
	@echo "\n💡 Use 'make break-cluster' to automatically simulate these issues.\n"

.PHONY: show-scripts
show-scripts:
	@echo "\n📋 Available scripts:"
	@echo "\n1. $(SETUP_SCRIPT):"
	@echo "   - Sets up a kubeadm cluster (control plane node)"
	@echo "   - Installs kubeadm, kubelet, kubectl"
	@echo "   - Configures containerd"
	@echo "   - Initializes the cluster"
	@echo "   Usage: sudo bash $(SETUP_SCRIPT)"
	@echo "   Or: make setup-cluster"
	@echo ""
	@echo "2. $(WORKER_SCRIPT):"
	@echo "   - Adds a worker node to an existing cluster"
	@echo "   - Installs kubeadm, kubelet, kubectl"
	@echo "   - Configures containerd"
	@echo "   - Joins the node to the cluster"
	@echo "   Usage: sudo bash $(WORKER_SCRIPT)"
	@echo "   Or: make add-worker"
	@echo "   Note: Run on the worker node machine"
	@echo ""
	@echo "3. $(BREAK_SCRIPT):"
	@echo "   - Simulates cluster migration issues"
	@echo "   - Changes IPs to simulate old machine"
	@echo "   - Creates backups before changes"
	@echo "   - Restarts kubelet to apply changes"
	@echo "   Usage: sudo bash $(BREAK_SCRIPT)"
	@echo "   Or: make break-cluster"
	@echo ""
	@echo "4. $(FIX_SCRIPT):"
	@echo "   - Fixes broken cluster after migration"
	@echo "   - Updates all IPs to current values"
	@echo "   - Fixes etcd endpoints, API server, kubelet, kubeconfig"
	@echo "   - Restarts kubelet to apply fixes"
	@echo "   Usage: sudo bash $(FIX_SCRIPT)"
	@echo "   Or: make fix (on Multipass VMs)"
	@echo ""
	@echo "5. $(MULTIPASS_SCRIPT):"
	@echo "   - End-to-end automated cluster setup using Multipass"
	@echo "   - Creates VMs, sets up cluster, installs CNI, joins workers"
	@echo "   - Perfect for macOS users"
	@echo "   Usage: bash $(MULTIPASS_SCRIPT)"
	@echo "   Or: make setup-multipass"
	@echo ""
	@echo "💡 Use 'make cluster' for fully automated setup on macOS.\n"

# =========================
# Cleanup
# =========================
.PHONY: clean
clean:
	@echo "\n🧹 Cleaning up $(QUESTION) lab resources..."
	@echo ""
	@# Clean up Kubernetes namespace resources
	-kubectl delete ns $(NAMESPACE) --ignore-not-found 2>/dev/null || true
	@# Clean up Multipass VMs if they exist
	@if command -v multipass >/dev/null 2>&1; then \
		if multipass list 2>/dev/null | grep -q "kubeadm-cp"; then \
			echo "🗑️  Deleting Multipass VMs..."; \
			multipass delete kubeadm-cp 2>/dev/null || true; \
			for i in 1 2 3 4 5; do \
				multipass delete "kubeadm-worker-$$i" 2>/dev/null || true; \
			done; \
			multipass purge 2>/dev/null || true; \
			echo "   ✅ Multipass VMs deleted"; \
		fi; \
		echo "🧹 Removing kubeconfig..."; \
		rm -f /tmp/kubeconfig-multipass.yaml; \
	fi
	@echo "✅ Cleanup completed for $(QUESTION).\n"

.PHONY: clean-cluster
clean-cluster:
	@echo "\n⚠️  This will reset/clean up a kubeadm cluster."
	@echo "   WARNING: This will delete the cluster!"
	@echo ""
	@echo "🔄 Resetting kubeadm cluster..."
	@sudo kubeadm reset -f || echo "   ⚠️  kubeadm reset failed (cluster may not exist)"
	@echo "\n🧹 Cleaning up iptables rules..."
	@sudo iptables -F && sudo iptables -t nat -F && sudo iptables -t mangle -F && sudo iptables -X || echo "   ⚠️  iptables cleanup failed"
	@echo "\n🧹 Removing Kubernetes packages (optional)..."
	@echo "   To remove packages, run manually:"
	@echo "   Ubuntu/Debian: sudo apt-get purge -y kubeadm kubelet kubectl"
	@echo "   CentOS/RHEL: sudo yum remove -y kubeadm kubelet kubectl"
	@echo "\n✅ Cluster reset complete."

