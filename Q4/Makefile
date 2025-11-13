# =========================
# CKA LAB - QUESTION 4 (CNI Installation)
# =========================
QUESTION := Q4
NAMESPACE := cni-test
YAML := q4.yaml
SOLUTION := solution.yaml

# CNI Options
FLANNEL_VERSION := v0.26.1
FLANNEL_MANIFEST := https://github.com/flannel-io/flannel/releases/download/$(FLANNEL_VERSION)/kube-flannel.yml
CALICO_VERSION := v3.28.2
CALICO_OPERATOR := https://raw.githubusercontent.com/projectcalico/calico/$(CALICO_VERSION)/manifests/tigera-operator.yaml
CALICO_RESOURCES := https://raw.githubusercontent.com/projectcalico/calico/$(CALICO_VERSION)/manifests/custom-resources.yaml

# =========================
# Default workflow
# =========================
.PHONY: all
all: clean setup
	@echo "\n✅ $(QUESTION) environment ready."
	@echo "   Install a CNI manually or run 'make solution-flannel' or 'make solution-calico'.\n"

# =========================
# Environment Setup
# =========================
.PHONY: setup
setup:
	@echo "\n🔧 Setting up $(QUESTION) test environment..."
	kubectl apply -f $(YAML)
	@echo "\n⏳ Waiting for test pods..."
	kubectl -n $(NAMESPACE) rollout status deploy/test-pod --timeout=60s || echo "⚠️  Pods may not be ready if CNI is not installed."
	@echo "✅ Test environment setup complete.\n"

# =========================
# Solution Application
# =========================
.PHONY: solution-flannel
solution-flannel:
	@echo "\n🚀 Installing Flannel CNI $(FLANNEL_VERSION)..."
	@echo "   Applying manifest from: $(FLANNEL_MANIFEST)"
	kubectl apply -f $(FLANNEL_MANIFEST)
	@echo "\n⏳ Waiting for Flannel to be ready..."
	@echo "   Checking Flannel daemonset..."
	kubectl rollout status daemonset/kube-flannel-ds -n kube-flannel --timeout=120s || echo "⚠️  Flannel may take a few minutes to fully initialize."
	@echo "\n✅ Flannel CNI installation initiated."
	@echo "   Run 'make verify' to check installation status."
	@echo "\n⚠️  Note: If Flannel pods are in CrashLoopBackOff with 'Unable to find default route' error,"
	@echo "   run 'make fix-flannel-docker' to apply Docker Desktop fix.\n"

.PHONY: fix-flannel-docker
fix-flannel-docker:
	@echo "\n🔧 Fixing Flannel for Docker Desktop (configuring interface)..."
	@echo "   Getting node IP address..."
	@NODE_IP=$$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}'); \
	if [ -z "$$NODE_IP" ]; then \
		NODE_IP=$$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[0].address}'); \
	fi; \
	echo "   Node IP: $$NODE_IP"; \
	echo "   Updating Flannel ConfigMap to use ifaceCanReach..."; \
	kubectl patch configmap kube-flannel-cfg -n kube-flannel --type json \
		-p="[{\"op\": \"replace\", \"path\": \"/data/net-conf.json\", \"value\": \"{\\\"Network\\\": \\\"10.244.0.0/16\\\", \\\"Backend\\\": {\\\"Type\\\": \\\"vxlan\\\"}, \\\"ifaceCanReach\\\": \\\"$$NODE_IP\\\"}\"}]" || \
		(echo "⚠️  Patch failed. Trying alternative method..."; \
		 kubectl get configmap kube-flannel-cfg -n kube-flannel -o json | \
		 jq --arg ip "$$NODE_IP" '.data."net-conf.json" = (.data."net-conf.json" | fromjson | del(.iface) | . + {"ifaceCanReach": $$ip} | tojson)' | \
		 kubectl apply -f - || \
		 echo "⚠️  ConfigMap update failed."); \
	echo "   Patching Flannel daemonset to add --iface-can-reach argument..."; \
	kubectl patch daemonset kube-flannel-ds -n kube-flannel --type='json' \
		-p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--iface-can-reach=$(NODE_IP)"}]' 2>/dev/null || \
		kubectl patch daemonset kube-flannel-ds -n kube-flannel --type='json' \
		-p="[{\"op\": \"add\", \"path\": \"/spec/template/spec/containers/0/args/-\", \"value\": \"--iface-can-reach=$$NODE_IP\"}]" || \
		echo "⚠️  Daemonset patch failed. Flannel may need manual configuration."
	@echo "\n🔄 Restarting Flannel pods to apply changes..."
	kubectl delete pods -n kube-flannel --all --wait=false
	@echo "\n⏳ Waiting for Flannel pods to restart..."
	sleep 15
	@echo "✅ Flannel fix applied. Check status with 'make verify'."
	@echo "   Note: If pods still fail, Docker Desktop may require Calico instead.\n"

.PHONY: solution-calico
solution-calico:
	@echo "\n🚀 Installing Calico CNI $(CALICO_VERSION)..."
	@echo "   Step 1: Installing Tigera Operator..."
	kubectl apply -f $(CALICO_OPERATOR) || (echo "⚠️  Installation failed. This may be due to CRD annotation size limits."; echo "   Try using Calico v3.27.0 or use Flannel instead. See README for details."; exit 1)
	@echo "\n   Step 2: Installing Calico resources..."
	kubectl apply -f $(CALICO_RESOURCES) || echo "⚠️  Some resources may have failed. Check with 'make verify'."
	@echo "\n⏳ Waiting for Calico to be ready..."
	@echo "   This may take several minutes..."
	sleep 10
	kubectl wait --for=condition=available --timeout=300s deployment/tigera-operator -n tigera-operator || echo "⚠️  Calico may take a few minutes to fully initialize."
	@echo "\n✅ Calico CNI installation initiated."
	@echo "   Run 'make verify' to check installation status.\n"

.PHONY: solution
solution: solution-flannel
	@echo "\n💡 To install Calico instead, run: make solution-calico\n"

# =========================
# Verification
# =========================
.PHONY: verify
verify:
	@echo "\n🔍 Verifying CNI installation..."
	@echo "\n📊 Checking for Flannel..."
	@if kubectl get daemonset -n kube-flannel kube-flannel-ds >/dev/null 2>&1; then \
		echo "✅ Flannel is installed:"; \
		kubectl get daemonset -n kube-flannel kube-flannel-ds; \
		echo "\n   Flannel pods:"; \
		kubectl get pods -n kube-flannel; \
	fi
	@echo "\n📊 Checking for Calico..."
	@if kubectl get deployment -n tigera-operator tigera-operator >/dev/null 2>&1; then \
		echo "✅ Calico is installed:"; \
		kubectl get deployment -n tigera-operator tigera-operator; \
		echo "\n   Calico pods:"; \
		kubectl get pods -n tigera-system 2>/dev/null || kubectl get pods -n calico-system 2>/dev/null || echo "   Calico pods may be in different namespace"; \
	fi
	@echo "\n📊 Checking test pods connectivity..."
	kubectl -n $(NAMESPACE) get pods -l app=test-pod
	@echo "\n✅ Verification complete.\n"

.PHONY: status
status:
	@echo "\n📊 $(QUESTION) Environment Summary:"
	@echo "\nTest Namespace:"
	kubectl get ns $(NAMESPACE) 2>/dev/null || echo "   Namespace not found"
	@echo "\nTest Pods:"
	kubectl -n $(NAMESPACE) get pods 2>/dev/null || echo "   No pods found"
	@echo "\nCNI Status:"
	@make verify 2>/dev/null || echo "   Run 'make verify' to check CNI status"

# =========================
# Cleanup
# =========================
.PHONY: clean
clean:
	@echo "\n🧹 Cleaning up $(QUESTION) test resources..."
	@echo "→ Deleting test namespace $(NAMESPACE)..."
	-kubectl delete ns $(NAMESPACE) --ignore-not-found
	@echo "✅ Test resources cleaned up."
	@echo "\n⚠️  Note: CNI components are NOT removed by 'make clean'."
	@echo "   To remove CNI, manually delete the CNI resources:\n"
	@echo "   For Flannel:"
	@echo "   kubectl delete -f $(FLANNEL_MANIFEST)"
	@echo "\n   For Calico:"
	@echo "   kubectl delete -f $(CALICO_RESOURCES)"
	@echo "   kubectl delete -f $(CALICO_OPERATOR)\n"

