# Q4: Container Network Interface (CNI) Installation Lab

This lab demonstrates installing and configuring a Container Network Interface (CNI) plugin in a Kubernetes cluster. CNI plugins are essential for pod-to-pod networking in Kubernetes.

## Overview

Install and configure a CNI plugin of your choice:
- **Flannel (v0.26.1)** - A simple and easy-to-use CNI plugin
- **Calico (v3.28.2)** - A more feature-rich CNI with network policies

Both options meet the requirements. Choose based on your needs:
- **Flannel**: Simpler, faster to install, good for basic networking
- **Calico**: More features, supports network policies, better for production

## What is CNI?

Container Network Interface (CNI) is a specification and library for writing plugins to configure network interfaces in Linux containers. In Kubernetes:

- **Pods need networking** to communicate with each other and external services
- **CNI plugins** provide the networking layer
- **Without CNI**, pods cannot communicate (they'll be in `Pending` or `ContainerCreating` state)

## Prerequisites

- `kubectl` configured to access a Kubernetes cluster
- `make` installed
- Cluster admin permissions (CNI installation requires cluster-level access)
- A Kubernetes cluster without an existing CNI (or permission to replace it)

**Important Notes:**
- CNI installation is a **cluster-level operation**
- Only one CNI should be active at a time
- Installing a CNI may affect all pods in the cluster
- Ensure you have the necessary permissions

## Setting Up a Test Cluster

### Option 1: Using Kind (Recommended)

Kind (Kubernetes in Docker) is ideal for CNI labs as it allows creating clusters without a default CNI.

**Install Kind:**
```bash
# macOS
brew install kind

# Or download binary
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-darwin-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind
```

**Create a Kind Cluster (without CNI):**
```bash
# Single node cluster
kind create cluster --name cka-lab --config=- <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
networking:
  disableDefaultCNI: true
nodes:
- role: control-plane
EOF

# Multi-node cluster (control-plane + worker)
kind create cluster --name cka-lab --config=- <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
networking:
  disableDefaultCNI: true
nodes:
- role: control-plane
- role: worker
EOF
```

**Switch kubectl context:**
```bash
kubectl config use-context kind-cka-lab
```

**Delete cluster when done:**
```bash
kind delete cluster --name cka-lab
```

### Option 2: Using Minikube

**Start Minikube without CNI:**
```bash
minikube start --driver=docker --network-plugin=cni
kubectl config use-context minikube
```

### Option 3: Docker Desktop

**Docker Desktop Users:**
- Docker Desktop on macOS may have networking limitations
- Flannel may require additional configuration (see Troubleshooting)
- Calico generally works better with Docker Desktop
- If you encounter issues, try Calico first or use Kind instead

## Quick Start

### 1. Set up the test environment

```bash
make all
```

This will:
- Create a test namespace (`cni-test`)
- Deploy test pods to verify CNI functionality
- Prepare the environment for CNI installation

### 2. Install a CNI (Choose one)

**Option A: Install Flannel (Recommended for beginners)**
```bash
make solution-flannel
```

**Option B: Install Calico (More features)**
```bash
make solution-calico
```

### 3. Verify the installation

```bash
make verify
```

This checks:
- CNI daemonsets/deployments are running
- CNI pods are healthy
- Test pods can start and communicate

## Available Make Targets

- `make all` - Full lab setup (clean, setup)
- `make setup` - Create test namespace and pods
- `make solution-flannel` - Install Flannel CNI v0.26.1
- `make solution-calico` - Install Calico CNI v3.28.2
- `make solution` - Default to Flannel (alias for solution-flannel)
- `make fix-flannel-docker` - Fix Flannel for Docker Desktop (configures interface)
- `make verify` - Verify CNI installation and test pods
- `make status` - Show environment summary
- `make clean` - Clean up test resources (does NOT remove CNI)

## Detailed Installation Steps

### Installing Flannel (v0.26.1)

Flannel is a simple overlay network that provides a flat network for pods.

1. **Install Flannel:**
   ```bash
   make solution-flannel
   ```

2. **What happens:**
   - Downloads and applies the Flannel manifest
   - Creates `kube-flannel` namespace
   - Deploys Flannel daemonset on all nodes
   - Configures pod networking

3. **Verify installation:**
   ```bash
   # Check Flannel daemonset
   kubectl get daemonset -n kube-flannel kube-flannel-ds
   
   # Check Flannel pods
   kubectl get pods -n kube-flannel
   
   # Check test pods
   kubectl get pods -n cni-test
   ```

4. **Manual installation (alternative):**
   ```bash
   kubectl apply -f https://github.com/flannel-io/flannel/releases/download/v0.26.1/kube-flannel.yml
   ```

### Installing Calico (v3.28.2)

Calico provides networking and network policy enforcement.

1. **Install Calico:**
   ```bash
   make solution-calico
   ```

2. **What happens:**
   - Installs Tigera Operator (manages Calico)
   - Applies Calico custom resources
   - Deploys Calico components across the cluster
   - Configures pod networking and policies

3. **Verify installation:**
   ```bash
   # Check Tigera Operator
   kubectl get deployment -n tigera-operator tigera-operator
   
   # Check Calico pods
   kubectl get pods -n tigera-system
   # or
   kubectl get pods -n calico-system
   
   # Check test pods
   kubectl get pods -n cni-test
   ```

4. **Manual installation (alternative):**
   ```bash
   # Step 1: Install Tigera Operator
   kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.2/manifests/tigera-operator.yaml
   
   # Step 2: Install Calico resources
   kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.2/manifests/custom-resources.yaml
   ```

## Verification and Testing

### Check CNI Status

```bash
make verify
```

This command checks:
- Flannel daemonset status (if Flannel is installed)
- Calico operator status (if Calico is installed)
- CNI pods health
- Test pod connectivity

### Manual Verification

**Check if pods can start:**
```bash
kubectl get pods -n cni-test
```

All pods should be in `Running` state. If they're stuck in `Pending` or `ContainerCreating`, the CNI may not be working.

**Check pod networking:**
```bash
# Get pod IPs
kubectl get pods -n cni-test -o wide

# Test connectivity between pods
kubectl exec -n cni-test <pod-name> -- ping <other-pod-ip>
```

**Check CNI components:**
```bash
# For Flannel
kubectl get all -n kube-flannel

# For Calico
kubectl get all -n tigera-operator
kubectl get all -n tigera-system
```

## Understanding CNI Components

### Flannel Components

- **kube-flannel-ds**: Daemonset that runs on every node
- **ConfigMap**: Contains Flannel configuration
- **ServiceAccount**: RBAC permissions for Flannel

### Calico Components

- **tigera-operator**: Manages Calico installation and updates
- **calico-node**: Daemonset running on each node
- **calico-kube-controllers**: Central controller for Calico
- **Custom Resources**: CalicoNetworkPolicy, IPPool, etc.

## Troubleshooting

### Flannel: "Unable to find default route" (Docker Desktop)

**Symptom:** Flannel pods in `CrashLoopBackOff` with error: `Failed to find any valid interface to use: failed to get default interface: Unable to find default route`

**Cause:** Docker Desktop on macOS uses a VM with different networking, and Flannel can't detect the default route.

**Solution for Docker Desktop:**
1. Configure Flannel to use a specific interface. Edit the Flannel ConfigMap:
   ```bash
   kubectl edit configmap kube-flannel-cfg -n kube-flannel
   ```

2. Add `"iface": "eth0"` or `"iface": "enp0s8"` to the `net-conf.json` section:
   ```json
   {
     "Network": "10.244.0.0/16",
     "Backend": {
       "Type": "vxlan"
     }
   }
   ```
   Change to:
   ```json
   {
     "Network": "10.244.0.0/16",
     "Backend": {
       "Type": "vxlan"
     },
     "iface": "eth0"
   }
   ```

3. Restart Flannel pods:
   ```bash
   kubectl delete pods -n kube-flannel --all
   ```

**Quick Fix (Automated):**
```bash
make fix-flannel-docker
```

This command automatically:
- Updates the Flannel ConfigMap to use `eth0` interface
- Restarts Flannel pods
- Applies the fix for Docker Desktop

**Alternative:** Use Calico instead, which handles Docker Desktop networking better.

### Pods stuck in Pending state

**Symptom:** Pods remain in `Pending` state with message about network not ready.

**Solution:**
1. Check if CNI is installed:
   ```bash
   kubectl get pods -n kube-flannel  # For Flannel
   kubectl get pods -n tigera-system  # For Calico
   ```

2. Check CNI pods logs:
   ```bash
   kubectl logs -n kube-flannel -l app=flannel
   kubectl logs -n tigera-system -l k8s-app=calico-node
   ```

3. Verify nodes are ready:
   ```bash
   kubectl get nodes
   ```

### CNI installation fails

**Symptom:** `kubectl apply` fails or pods don't start.

**Possible causes:**
- Insufficient permissions (need cluster-admin)
- Existing CNI conflict
- Network connectivity issues
- Node resources insufficient
- CustomResourceDefinition annotation too long (Calico)

**Solution:**
1. Check permissions:
   ```bash
   kubectl auth can-i create daemonsets --all-namespaces
   ```

2. Check for existing CNI:
   ```bash
   kubectl get pods -A | grep -E "flannel|calico|weave|cilium"
   ```

3. Check node resources:
   ```bash
   kubectl describe nodes
   ```

### Calico: "CustomResourceDefinition annotations too long"

**Symptom:** Error: `The CustomResourceDefinition "installations.operator.tigera.io" is invalid: metadata.annotations: Too long: may not be more than 262144 bytes`

**Cause:** Some Kubernetes versions have limits on annotation sizes. This is a known issue with Calico v3.28.2 on certain Kubernetes versions.

**Solution:**
1. Try a different Calico version (v3.27.x or v3.26.x)
2. Or use Flannel instead
3. Or manually apply the manifest and skip the problematic CRD if it's not critical

**Workaround:**
```bash
# Try installing Calico v3.27.0 instead
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/tigera-operator.yaml
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/custom-resources.yaml
```

### Multiple CNI plugins installed

**Symptom:** Network conflicts, pods can't communicate.

**Solution:** Remove one CNI before installing another:
```bash
# Remove Flannel
kubectl delete -f https://github.com/flannel-io/flannel/releases/download/v0.26.1/kube-flannel.yml

# Remove Calico
kubectl delete -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.2/manifests/custom-resources.yaml
kubectl delete -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.2/manifests/tigera-operator.yaml
```

### Test pods not starting

**Symptom:** Test pods in `cni-test` namespace don't start.

**Solution:**
1. Check CNI is installed and running
2. Check pod events:
   ```bash
   kubectl describe pod -n cni-test <pod-name>
   ```
3. Check node conditions:
   ```bash
   kubectl get nodes -o wide
   ```

## Files

- `q4.yaml` - Test environment setup (namespace and test pods)
- `solution.yaml` - Reference file with installation commands
- `Makefile` - Automation for lab setup and CNI installation

## Cleanup

### Remove test resources

```bash
make clean
```

This removes:
- Test namespace and pods
- Does NOT remove the CNI (cluster-level component)

### Remove CNI (if needed)

**Remove Flannel:**
```bash
kubectl delete -f https://github.com/flannel-io/flannel/releases/download/v0.26.1/kube-flannel.yml
```

**Remove Calico:**
```bash
kubectl delete -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.2/manifests/custom-resources.yaml
kubectl delete -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.2/manifests/tigera-operator.yaml
```

**Warning:** Removing CNI will break pod networking. Only do this if you're replacing it with another CNI or cleaning up a test cluster.

## Additional Resources

- **Flannel Documentation:** https://github.com/flannel-io/flannel
- **Calico Documentation:** https://docs.tigera.io/calico/latest/about/
- **CNI Specification:** https://github.com/containernetworking/cni

## Notes

- CNI installation is **irreversible** without manual removal
- Only **one CNI** should be active at a time
- CNI affects **all pods** in the cluster
- Installation may take **2-5 minutes** to complete
- Some CNI features (like Network Policies) require additional configuration
- In production, CNI is typically installed during cluster setup, not after

## Expected Outcomes

After successful CNI installation:

✅ All nodes show `Ready` status  
✅ CNI pods are running on all nodes  
✅ Test pods in `cni-test` namespace are `Running`  
✅ Pods can communicate with each other  
✅ Pods can reach external networks  

If all these conditions are met, the CNI is properly installed and configured!

