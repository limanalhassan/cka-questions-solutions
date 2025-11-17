# Q14: Kubeadm Cluster Migration Troubleshooting Lab

This lab demonstrates how to troubleshoot and fix a kubeadm-provisioned Kubernetes cluster that broke during machine migration. The scenario involves a single-node cluster that was migrated to a new machine and requires configuration updates to function correctly.

## Overview

**Scenario:** A `kubeadm`-provisioned cluster was migrated to a new machine. The cluster is now broken and needs to be fixed.

**Key Details:**
- Single-node cluster
- Used an external etcd server
- Cluster components are not functioning after migration

**Task Breakdown:**
1. **Identify** the broken cluster components and investigate what caused them to break
2. **Fix** the configuration of all broken cluster components
3. **Restart** all necessary services and components for changes to take effect
4. **Verify** the cluster, single node, and all pods are Ready

## What You'll Learn

- **Kubeadm Cluster Architecture**: Understanding how kubeadm sets up Kubernetes components
- **Static Pods**: How control plane components run as static pods managed by kubelet
- **etcd Configuration**: Configuring external etcd endpoints
- **Certificate Management**: Understanding certificate SANs and IP addresses
- **Kubelet Configuration**: How kubelet connects to the API server
- **Kubeconfig Files**: Managing cluster access configurations
- **Service Management**: Restarting kubelet and understanding its role
- **Troubleshooting**: Systematic approach to identifying and fixing cluster issues

## Prerequisites

- Access to a kubeadm-provisioned Kubernetes cluster (or ability to create one)
- SSH access to the control plane node
- `sudo` privileges on the control plane node
- Understanding of Kubernetes cluster architecture
- Basic knowledge of systemd services
- Familiarity with YAML configuration files

**Note:** This lab requires a real kubeadm cluster. The lab includes scripts to help you set up and break a cluster for practice.

## Quick Start

### Option 1: End-to-End Automated Setup with Multipass (macOS/Windows - Recommended)

For macOS and Windows users, this is the easiest way to set up a complete kubeadm cluster:

**First, install Multipass if not already installed:**

- **macOS:**
  ```bash
  brew install multipass
  ```

- **Windows:**
  ```bash
  choco install multipass
  ```

- **Linux:** Multipass is available via snap or apt. See [Multipass documentation](https://multipass.run/install) for details.

**Then set up the cluster:**

For a working cluster:
```bash
cd Q14
make cluster
# Or run directly: bash setup-multipass-cluster.sh
```

**For Q14 Lab (broken cluster ready for troubleshooting):**
```bash
cd Q14
make lab
```

This will automatically:
- ✅ Create control plane VM using Multipass
- ✅ Create worker VM(s) using Multipass
- ✅ Install kubeadm, kubelet, kubectl on all nodes
- ✅ Initialize the cluster
- ✅ Install CNI plugin (Flannel)
- ✅ Join worker nodes to the cluster
- ✅ Configure kubeconfig for local access
- ✅ **Break the cluster** (simulate migration issues)
- ✅ Make it ready for you to troubleshoot and fix

**Requirements:**
- Multipass installed (see installation instructions above)
- At least 8GB RAM (for VMs)
- Internet connection

**After setup:**
```bash
# Use the cluster
export KUBECONFIG=/tmp/kubeconfig-multipass.yaml
kubectl get nodes

# Access control plane VM
multipass shell kubeadm-cp

# To break the cluster for the lab (if using make cluster)
multipass shell kubeadm-cp
cd /home/ubuntu
sudo bash break-cluster.sh

# Or use make lab to set up and break in one command
make lab

# To fix the broken cluster (automated solution)
make fix
# Or manually: multipass shell kubeadm-cp
#              sudo bash /home/ubuntu/fix-cluster.sh

# To break the cluster again (without deleting VMs)
make break

# To clean up when done (deletes VMs)
make clean
```

### Option 2: Using the Provided Scripts (Manual Setup)

#### 1. Set up a kubeadm cluster

```bash
# On a VM or machine with Ubuntu/Debian or CentOS/RHEL
cd Q14
make setup-cluster
# Or run directly: sudo bash setup-kubeadm-cluster.sh
```

This will:
- Install kubeadm, kubelet, kubectl
- Configure containerd
- Initialize a single-node kubeadm cluster
- Set up kubectl access

**Requirements:**
- Root/sudo privileges
- Ubuntu/Debian or CentOS/RHEL
- At least 2GB RAM and 2 CPU cores
- Internet connection

#### 2. Install a CNI plugin (required for pods to start)

```bash
# Install Flannel (or another CNI)
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

# Wait for nodes to be Ready
kubectl get nodes
```

#### 2a. (Optional) Add worker nodes to the cluster

If you want to add worker nodes to your cluster:

**On the control plane node:**
```bash
# Get the join command
kubeadm token create --print-join-command
```

**On each worker node:**
```bash
# Copy the add-worker-node.sh script to the worker node
# Then run:
make add-worker
# Or: sudo bash add-worker-node.sh
```

The script will:
- Install kubeadm, kubelet, kubectl
- Configure containerd
- Set up system prerequisites
- Prompt for the join command
- Join the node to the cluster

**Verify worker nodes:**
```bash
# On control plane node
kubectl get nodes
```

#### 3. Simulate cluster migration issues

```bash
# This will "break" the cluster by changing IPs
make break-cluster
# Or run directly: sudo bash break-cluster.sh
```

This will:
- Create backups of all configuration files
- Change etcd endpoints to old IP
- Change API server advertise address to old IP
- Change kubelet and kubeconfig server addresses to old IP
- Restart kubelet to apply changes

#### 4. Identify broken components

```bash
# Check node status (should show NotReady)
kubectl get nodes

# Check control plane pods (may be in Error/CrashLoopBackOff)
kubectl get pods -n kube-system

# Check kubelet service
sudo systemctl status kubelet

# Check kubelet logs
sudo journalctl -u kubelet -n 100
```

#### 5. Fix the cluster

Follow the solution steps in `solution.yaml` or use `make solution` to see the guide.

#### 6. Verify the fix

```bash
make verify
# Or manually check:
kubectl get nodes
kubectl get pods --all-namespaces
kubectl cluster-info
```

### Option 2: Using an Existing Kubeadm Cluster

If you already have a kubeadm cluster:

#### 1. Set up the lab environment

```bash
make all
```

This creates a simulated environment with documentation and notes about common issues.

#### 2. Access the control plane node

```bash
# SSH into the control plane node
ssh user@control-plane-node

# Or if using a local VM
ssh user@localhost -p <port>
```

#### 3. Simulate migration issues (optional)

```bash
# Run the break script to simulate issues
sudo bash break-cluster.sh
```

#### 4. Identify broken components

```bash
# Check node status
kubectl get nodes

# Check control plane pods
kubectl get pods -n kube-system

# Check kubelet service
sudo systemctl status kubelet

# Check kubelet logs
sudo journalctl -u kubelet -n 100
```

### 4. Investigate common issues

```bash
make check-common-issues
# Or manually check the files mentioned
```

### 5. Apply the solution

**Option A: Automated fix (quick)**
```bash
# Fix the cluster automatically
make fix
# Or manually: multipass shell kubeadm-cp
#              sudo bash /home/ubuntu/fix-cluster.sh
```

**Option B: Manual fix (for learning)**
```bash
# Review solution steps
make solution
# Or read solution.yaml

# Follow the steps to fix configurations manually
# (See detailed steps below)
```

### 6. Verify the fix

```bash
make verify
# Or manually verify cluster health
```

## Available Make Targets

- `make all` - Full lab setup (clean, setup)
- `make setup` - Create simulated environment and documentation
- `make cluster` or `make setup-multipass` - End-to-end automated setup using Multipass (macOS, recommended)
- `make lab` - Set up cluster AND break it (ready for Q14 troubleshooting lab)
- `make fix` or `make fix-cluster` - Fix broken cluster (automated solution)
- `make break` - Break cluster only (simulates migration issues, keeps VMs for troubleshooting)
- `make setup-cluster` - Set up a kubeadm cluster (control plane, requires sudo)
- `make add-worker` - Add a worker node to the cluster (requires sudo, run on worker node)
- `make break-cluster` - Simulate cluster migration issues (requires sudo, run on control plane)
- `make solution` - Show solution guide
- `make show-config` - Display simulated cluster configuration
- `make check-common-issues` - List common issues to check
- `make status` - Show environment summary
- `make verify` - Verification checklist
- `make simulate-issues` - Show simulated issues
- `make show-scripts` - Show available scripts and their usage
- `make clean` - Clean up lab resources and Multipass VMs
- `make clean-cluster` - Reset/clean up kubeadm cluster (requires sudo, run on cluster node)

## Detailed Solution Steps

### Step 1: Identify Broken Components

**Check cluster status:**
```bash
# Check if node is Ready
kubectl get nodes

# Check control plane pods
kubectl get pods -n kube-system

# Check all pods
kubectl get pods --all-namespaces
```

**Check kubelet service:**
```bash
# Check kubelet status
sudo systemctl status kubelet

# Check kubelet logs
sudo journalctl -u kubelet -n 100

# Check for errors
sudo journalctl -u kubelet -n 200 | grep -i "error\|fail\|etcd\|apiserver"
```

**Check API server logs:**
```bash
# Get API server pod name
kubectl get pods -n kube-system | grep kube-apiserver

# Check API server logs (if pod exists)
kubectl logs -n kube-system <apiserver-pod-name>

# Or check kubelet logs for API server errors
sudo journalctl -u kubelet | grep -i apiserver
```

### Step 2: Identify Common Issues

After migration, common issues include:

#### Issue 1: etcd Endpoints Pointing to Old IP

**Check:**
```bash
# View API server manifest
sudo cat /etc/kubernetes/manifests/kube-apiserver.yaml

# Look for etcd server configuration
grep -i etcd /etc/kubernetes/manifests/kube-apiserver.yaml
```

**What to look for:**
- `--etcd-servers=https://OLD-IP:2379`
- The IP address should be the new etcd server IP

#### Issue 2: API Server Certificate SANs Missing New IP

**Check:**
```bash
# View API server manifest
sudo cat /etc/kubernetes/manifests/kube-apiserver.yaml

# Check certificate files
ls -la /etc/kubernetes/pki/apiserver.*

# View certificate (if openssl available)
sudo openssl x509 -in /etc/kubernetes/pki/apiserver.crt -text -noout | grep -A 5 "Subject Alternative Name"
```

**What to look for:**
- Certificate should include the new control plane IP in SANs
- If missing, certificate validation will fail

#### Issue 3: Kubelet Configuration Pointing to Old API Server

**Check:**
```bash
# View kubelet configuration
sudo cat /etc/kubernetes/kubelet.conf

# Look for server address
grep -i server /etc/kubernetes/kubelet.conf
```

**What to look for:**
- `server: https://OLD-IP:6443`
- Should point to new control plane IP

#### Issue 4: Admin Kubeconfig with Old Server Address

**Check:**
```bash
# View admin config
sudo cat /etc/kubernetes/admin.conf

# View user config
cat ~/.kube/config

# Check current context
kubectl config view
```

**What to look for:**
- `server: https://OLD-IP:6443`
- Should point to new control plane IP

#### Issue 5: Static Pod Manifests with Old IPs

**Check:**
```bash
# List all static pod manifests
ls -la /etc/kubernetes/manifests/

# Check each manifest for old IPs
sudo grep -r "OLD-IP" /etc/kubernetes/manifests/
```

### Step 3: Fix Configurations

#### Fix 1: Update etcd Endpoints

**Get new etcd server IP:**
```bash
# If etcd is on the same machine
ETCD_IP=$(hostname -I | awk '{print $1}')

# Or set manually
ETCD_IP="<new-etcd-server-ip>"
```

**Update API server manifest:**
```bash
# Edit the manifest
sudo vi /etc/kubernetes/manifests/kube-apiserver.yaml

# Or use sed
sudo sed -i "s|--etcd-servers=https://.*:2379|--etcd-servers=https://${ETCD_IP}:2379|g" \
  /etc/kubernetes/manifests/kube-apiserver.yaml
```

**Verify the change:**
```bash
sudo grep -i etcd /etc/kubernetes/manifests/kube-apiserver.yaml
```

#### Fix 2: Update API Server Certificate SANs

**Option A: Update existing certificate (if possible)**

Edit the API server manifest to ensure certificate includes new IP:
```bash
sudo vi /etc/kubernetes/manifests/kube-apiserver.yaml
```

**Option B: Regenerate certificates**

```bash
# Get new control plane IP
NODE_IP=$(hostname -I | awk '{print $1}')

# Backup existing certificates
sudo cp -r /etc/kubernetes/pki /etc/kubernetes/pki.backup

# Regenerate API server certificate
sudo kubeadm init phase certs apiserver \
  --apiserver-advertise-address=${NODE_IP} \
  --apiserver-cert-extra-sans=${NODE_IP}

# Or regenerate all certificates (more comprehensive)
sudo kubeadm init phase certs all \
  --apiserver-advertise-address=${NODE_IP} \
  --apiserver-cert-extra-sans=${NODE_IP}
```

#### Fix 3: Update Kubelet Configuration

**Get new control plane IP:**
```bash
NODE_IP=$(hostname -I | awk '{print $1}')
```

**Update kubelet config:**
```bash
# Edit the config
sudo vi /etc/kubernetes/kubelet.conf

# Or use sed
sudo sed -i "s|server: https://.*:6443|server: https://${NODE_IP}:6443|g" \
  /etc/kubernetes/kubelet.conf
```

**Verify:**
```bash
sudo grep -i server /etc/kubernetes/kubelet.conf
```

#### Fix 4: Update Admin Kubeconfig

**Update admin config:**
```bash
NODE_IP=$(hostname -I | awk '{print $1}')

# Edit admin config
sudo vi /etc/kubernetes/admin.conf

# Or use sed
sudo sed -i "s|server: https://.*:6443|server: https://${NODE_IP}:6443|g" \
  /etc/kubernetes/admin.conf
```

**Update user kubeconfig:**
```bash
# Copy admin config to user location
mkdir -p ~/.kube
sudo cp /etc/kubernetes/admin.conf ~/.kube/config
sudo chown $(id -u):$(id -g) ~/.kube/config

# Update server address
kubectl config set-cluster kubernetes --server=https://${NODE_IP}:6443

# Or edit directly
vi ~/.kube/config
```

#### Fix 5: Update Other Static Pod Manifests

**Check and update controller manager and scheduler:**
```bash
# Check controller manager
sudo cat /etc/kubernetes/manifests/kube-controller-manager.yaml

# Check scheduler
sudo cat /etc/kubernetes/manifests/kube-scheduler.yaml

# Update any old IPs found
sudo vi /etc/kubernetes/manifests/kube-controller-manager.yaml
sudo vi /etc/kubernetes/manifests/kube-scheduler.yaml
```

### Step 4: Restart Services

**Restart kubelet:**
```bash
# Restart kubelet service
sudo systemctl restart kubelet

# Check status
sudo systemctl status kubelet

# Enable if not enabled
sudo systemctl enable kubelet
```

**Wait for static pods to restart:**
```bash
# Watch pods come up
watch kubectl get pods -n kube-system

# Or check periodically
kubectl get pods -n kube-system
```

**Note:** When you restart kubelet, it will automatically restart all static pods (API server, controller manager, scheduler) because it watches the `/etc/kubernetes/manifests/` directory.

### Step 5: Verify Cluster Health

**Check node status:**
```bash
# Should show Ready
kubectl get nodes

# Get detailed node info
kubectl describe node <node-name>
```

**Check all pods:**
```bash
# Check all namespaces
kubectl get pods --all-namespaces

# Check control plane pods specifically
kubectl get pods -n kube-system

# All should be Running or Completed
```

**Verify API server connectivity:**
```bash
# Check cluster info
kubectl cluster-info

# Check API server health
kubectl get --raw /healthz

# Should return: ok
```

**Check etcd health (if accessible):**
```bash
# Check etcd health endpoint
kubectl get --raw /healthz/etcd

# Should return: ok
```

**Verify kubelet service:**
```bash
# Check service status
sudo systemctl status kubelet

# Should be: active (running)
```

## Common Issues and Solutions

### Issue: API Server Pod Not Starting

**Symptoms:**
- `kubectl get pods -n kube-system` shows API server pod in `CrashLoopBackOff` or `Error`
- `kubectl get nodes` shows node as `NotReady`

**Possible causes:**
1. etcd endpoints incorrect
2. Certificate issues
3. Network connectivity problems

**Solution:**
```bash
# Check API server logs
sudo journalctl -u kubelet | grep -i apiserver

# Verify etcd connectivity
# (If etcd is accessible)
curl -k https://<etcd-ip>:2379/health

# Check certificate
sudo openssl x509 -in /etc/kubernetes/pki/apiserver.crt -text -noout
```

### Issue: Kubelet Cannot Connect to API Server

**Symptoms:**
- kubelet logs show connection errors
- Node shows as `NotReady`

**Solution:**
```bash
# Check kubelet config
sudo cat /etc/kubernetes/kubelet.conf

# Verify API server is accessible
curl -k https://<api-server-ip>:6443/healthz

# Update kubelet config if IP is wrong
sudo vi /etc/kubernetes/kubelet.conf
sudo systemctl restart kubelet
```

### Issue: Certificate Validation Errors

**Symptoms:**
- Logs show certificate validation errors
- Connections fail with TLS errors

**Solution:**
```bash
# Regenerate certificates with correct SANs
NODE_IP=$(hostname -I | awk '{print $1}')
sudo kubeadm init phase certs apiserver \
  --apiserver-advertise-address=${NODE_IP} \
  --apiserver-cert-extra-sans=${NODE_IP}

# Restart kubelet
sudo systemctl restart kubelet
```

### Issue: etcd Connection Failed

**Symptoms:**
- API server logs show etcd connection errors
- API server pod crashes

**Solution:**
```bash
# Verify etcd server is accessible
# (If etcd is on same machine)
sudo systemctl status etcd

# (If external etcd)
curl -k https://<etcd-ip>:2379/health

# Update etcd endpoints in API server manifest
sudo vi /etc/kubernetes/manifests/kube-apiserver.yaml
sudo systemctl restart kubelet
```

## Verification Checklist

After applying fixes, verify:

- [ ] Node status shows `Ready`
- [ ] All control plane pods are `Running`
- [ ] All pods in `kube-system` namespace are `Running` or `Completed`
- [ ] `kubectl cluster-info` works
- [ ] `kubectl get --raw /healthz` returns `ok`
- [ ] `kubectl get --raw /healthz/etcd` returns `ok` (if accessible)
- [ ] kubelet service is `active (running)`
- [ ] No errors in kubelet logs
- [ ] API server is accessible
- [ ] etcd endpoints are correct
- [ ] Certificates include correct IPs
- [ ] Kubeconfig files have correct server addresses

## Files to Check

In a real kubeadm cluster, check these files:

1. **Static Pod Manifests:**
   - `/etc/kubernetes/manifests/kube-apiserver.yaml`
   - `/etc/kubernetes/manifests/kube-controller-manager.yaml`
   - `/etc/kubernetes/manifests/kube-scheduler.yaml`

2. **Kubelet Configuration:**
   - `/etc/kubernetes/kubelet.conf`
   - `/var/lib/kubelet/config.yaml`

3. **Kubeconfig Files:**
   - `/etc/kubernetes/admin.conf`
   - `/root/.kube/config`
   - `~/.kube/config`

4. **Certificates:**
   - `/etc/kubernetes/pki/apiserver.crt`
   - `/etc/kubernetes/pki/apiserver.key`
   - `/etc/kubernetes/pki/etcd/` (if using external etcd)

5. **Kubeadm Config:**
   - `/etc/kubernetes/kubeadm-config.yaml` (if exists)

## Common kubectl Commands

```bash
# Cluster status
kubectl get nodes
kubectl get pods --all-namespaces
kubectl get pods -n kube-system

# Cluster info
kubectl cluster-info
kubectl get --raw /healthz
kubectl get --raw /healthz/etcd

# Node details
kubectl describe node <node-name>
kubectl get node <node-name> -o yaml

# Pod details
kubectl describe pod <pod-name> -n kube-system
kubectl logs <pod-name> -n kube-system
```

## Common systemctl Commands

```bash
# Kubelet service
sudo systemctl status kubelet
sudo systemctl restart kubelet
sudo systemctl enable kubelet
sudo journalctl -u kubelet -n 100
sudo journalctl -u kubelet -f

# etcd service (if on same machine)
sudo systemctl status etcd
sudo systemctl restart etcd
```

## Notes

- **Static Pods**: Control plane components run as static pods. When you edit manifests in `/etc/kubernetes/manifests/`, kubelet automatically restarts them.
- **Kubelet Restart**: Restarting kubelet will restart all static pods, so you don't need to manually restart API server, controller manager, or scheduler.
- **Certificate Regeneration**: Regenerating certificates may require updating other components that use those certificates.
- **External etcd**: If using external etcd, ensure etcd server is accessible and certificates are correct.
- **IP Changes**: After migration, all IP references need to be updated consistently across all configuration files.
- **Backup**: Always backup configuration files and certificates before making changes.

## Expected Outcomes

After successful troubleshooting:

✅ Node status shows `Ready`  
✅ All control plane pods are `Running`  
✅ All pods in all namespaces are `Running` or `Completed`  
✅ API server is accessible and healthy  
✅ etcd connectivity is working (if external etcd)  
✅ kubelet service is running without errors  
✅ `kubectl` commands work correctly  
✅ Cluster is fully functional  

## Additional Resources

- [Kubeadm Documentation](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/)
- [Kubeadm Cluster Creation](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/)
- [Kubeadm Certificate Management](https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-certs/)
- [Static Pods](https://kubernetes.io/docs/tasks/configure-pod-container/static-pod/)
- [Kubelet Configuration](https://kubernetes.io/docs/reference/config-api/kubelet-config.v1beta1/)

