#!/bin/bash
# End-to-end kubeadm cluster setup using Multipass
# This script automates the entire cluster creation process

set -e

# Configuration
CONTROL_PLANE_VM="kubeadm-cp"
WORKER_VM_PREFIX="kubeadm-worker"
NUM_WORKERS=1
K8S_VERSION="v1.28"
CNI_PLUGIN="flannel"  # Options: flannel, calico

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=========================================="
echo "Q14: End-to-End Kubeadm Cluster Setup"
echo "Using Multipass"
echo "==========================================${NC}"
echo ""

# Check if multipass is installed
if ! command -v multipass &> /dev/null; then
    echo -e "${RED}❌ Multipass is not installed.${NC}"
    echo ""
    echo "Install it with:"
    echo "  brew install multipass"
    exit 1
fi

echo -e "${GREEN}✅ Multipass is installed${NC}"
echo ""

# Check if VMs already exist
if multipass list | grep -q "$CONTROL_PLANE_VM"; then
    echo -e "${YELLOW}⚠️  Control plane VM '$CONTROL_PLANE_VM' already exists.${NC}"
    read -p "Delete and recreate? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "🗑️  Deleting existing VMs..."
        multipass delete "$CONTROL_PLANE_VM" || true
        for i in $(seq 1 $NUM_WORKERS); do
            multipass delete "${WORKER_VM_PREFIX}-${i}" || true
        done
        multipass purge
        echo "✅ VMs deleted"
    else
        echo "Cancelled."
        exit 0
    fi
fi

# Create control plane VM
echo -e "${BLUE}🚀 Creating control plane VM...${NC}"
multipass launch --name "$CONTROL_PLANE_VM" --cpus 2 --mem 4G --disk 20G 22.04
echo -e "${GREEN}✅ Control plane VM created${NC}"
echo ""

# Create worker VMs
if [ "$NUM_WORKERS" -gt 0 ]; then
    echo -e "${BLUE}🚀 Creating $NUM_WORKERS worker VM(s)...${NC}"
    for i in $(seq 1 $NUM_WORKERS); do
        multipass launch --name "${WORKER_VM_PREFIX}-${i}" --cpus 2 --mem 4G --disk 20G 22.04
        echo -e "${GREEN}✅ Worker VM ${i} created${NC}"
    done
    echo ""
fi

# Wait for VMs to be ready
echo -e "${YELLOW}⏳ Waiting for VMs to be ready...${NC}"
sleep 10

# Wait for control plane VM to be ready (running with IP)
echo -e "${YELLOW}⏳ Waiting for control plane VM to be ready...${NC}"
MAX_RETRIES=30
RETRY_COUNT=0
VM_READY=0
while [ $RETRY_COUNT -lt $MAX_RETRIES ] && [ $VM_READY -eq 0 ]; do
    # Check if VM is running and has an IP address
    VM_STATUS=$(multipass info "$CONTROL_PLANE_VM" 2>/dev/null | grep "State:" | awk '{print $2}' || echo "")
    VM_IP=$(multipass info "$CONTROL_PLANE_VM" 2>/dev/null | grep "IPv4:" | awk '{print $2}' || echo "")
    
    if [ "$VM_STATUS" = "Running" ] && [ -n "$VM_IP" ]; then
        VM_READY=1
        break
    fi
    
    RETRY_COUNT=$((RETRY_COUNT + 1))
    if [ $((RETRY_COUNT % 5)) -eq 0 ]; then
        echo -n " [${RETRY_COUNT}s]"
    else
        echo -n "."
    fi
    sleep 2
done
echo ""
if [ $VM_READY -eq 0 ]; then
    echo -e "${RED}❌ Control plane VM not ready after $MAX_RETRIES retries${NC}"
    echo -e "${YELLOW}   VM status:${NC}"
    multipass info "$CONTROL_PLANE_VM" || true
    exit 1
fi
echo -e "${GREEN}✅ Control plane VM is ready${NC}"
echo ""

# Get control plane IP
echo -e "${BLUE}📡 Getting control plane IP...${NC}"
CP_IP=$(multipass info "$CONTROL_PLANE_VM" | grep IPv4 | awk '{print $2}')
if [ -z "$CP_IP" ]; then
    echo -e "${YELLOW}⚠️  IP not available yet, waiting...${NC}"
    sleep 5
    CP_IP=$(multipass info "$CONTROL_PLANE_VM" | grep IPv4 | awk '{print $2}')
fi
echo -e "${GREEN}✅ Control plane IP: $CP_IP${NC}"
echo ""

# Transfer scripts to control plane with retry
echo -e "${BLUE}📤 Transferring scripts to control plane VM...${NC}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RETRY_COUNT=0
MAX_TRANSFER_RETRIES=5
while [ $RETRY_COUNT -lt $MAX_TRANSFER_RETRIES ]; do
    if multipass transfer "${SCRIPT_DIR}/setup-kubeadm-cluster.sh" "${CONTROL_PLANE_VM}:/home/ubuntu/" 2>/dev/null && \
       multipass transfer "${SCRIPT_DIR}/break-cluster.sh" "${CONTROL_PLANE_VM}:/home/ubuntu/" 2>/dev/null && \
       multipass transfer "${SCRIPT_DIR}/fix-cluster.sh" "${CONTROL_PLANE_VM}:/home/ubuntu/" 2>/dev/null; then
        echo -e "${GREEN}✅ Scripts transferred${NC}"
        break
    fi
    RETRY_COUNT=$((RETRY_COUNT + 1))
    if [ $RETRY_COUNT -lt $MAX_TRANSFER_RETRIES ]; then
        echo -e "${YELLOW}⚠️  Transfer failed, retrying ($RETRY_COUNT/$MAX_TRANSFER_RETRIES)...${NC}"
        sleep 3
    else
        echo -e "${RED}❌ Failed to transfer scripts after $MAX_TRANSFER_RETRIES retries${NC}"
        exit 1
    fi
done
echo ""

# Transfer scripts to worker VMs with retry
if [ "$NUM_WORKERS" -gt 0 ]; then
    echo -e "${BLUE}📤 Transferring scripts to worker VMs...${NC}"
    for i in $(seq 1 $NUM_WORKERS); do
        RETRY_COUNT=0
        MAX_TRANSFER_RETRIES=5
        while [ $RETRY_COUNT -lt $MAX_TRANSFER_RETRIES ]; do
            if multipass transfer "${SCRIPT_DIR}/add-worker-node.sh" "${WORKER_VM_PREFIX}-${i}:/home/ubuntu/" 2>/dev/null; then
                echo -e "${GREEN}✅ Scripts transferred to worker ${i}${NC}"
                break
            fi
            RETRY_COUNT=$((RETRY_COUNT + 1))
            if [ $RETRY_COUNT -lt $MAX_TRANSFER_RETRIES ]; then
                echo -e "${YELLOW}⚠️  Transfer to worker ${i} failed, retrying ($RETRY_COUNT/$MAX_TRANSFER_RETRIES)...${NC}"
                sleep 3
            else
                echo -e "${RED}❌ Failed to transfer scripts to worker ${i} after $MAX_TRANSFER_RETRIES retries${NC}"
                exit 1
            fi
        done
    done
    echo ""
fi

# Setup control plane
echo -e "${BLUE}🔧 Setting up control plane node...${NC}"
echo "This may take a few minutes..."
multipass exec "$CONTROL_PLANE_VM" -- sudo bash /home/ubuntu/setup-kubeadm-cluster.sh

# Wait a bit for cluster to stabilize
echo ""
echo -e "${YELLOW}⏳ Waiting for cluster to stabilize...${NC}"
sleep 10

# Setup kubeconfig on control plane VM
echo -e "${BLUE}📋 Setting up kubeconfig on control plane VM...${NC}"
multipass exec "$CONTROL_PLANE_VM" -- bash <<'KUBECONFIG_SETUP'
    mkdir -p $HOME/.kube
    if [ -f /etc/kubernetes/admin.conf ]; then
        sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config
        sudo chown $(id -u):$(id -g) $HOME/.kube/config
        echo "✅ Kubeconfig created at $HOME/.kube/config"
    else
        echo "❌ Error: /etc/kubernetes/admin.conf not found"
        exit 1
    fi
KUBECONFIG_SETUP

# Verify kubeconfig exists before copying
if ! multipass exec "$CONTROL_PLANE_VM" -- test -f /home/ubuntu/.kube/config; then
    echo -e "${RED}❌ Error: Kubeconfig not found on control plane VM${NC}"
    echo "   Trying to create it again..."
    multipass exec "$CONTROL_PLANE_VM" -- bash -c "mkdir -p /home/ubuntu/.kube && sudo cp /etc/kubernetes/admin.conf /home/ubuntu/.kube/config && sudo chown ubuntu:ubuntu /home/ubuntu/.kube/config"
fi

echo -e "${GREEN}✅ Kubeconfig configured on control plane VM${NC}"
echo ""

# Get kubeconfig
echo -e "${BLUE}📋 Getting kubeconfig...${NC}"
multipass exec "$CONTROL_PLANE_VM" -- cat /home/ubuntu/.kube/config > /tmp/kubeconfig-multipass.yaml

# Verify we got the kubeconfig
if [ ! -f /tmp/kubeconfig-multipass.yaml ] || [ ! -s /tmp/kubeconfig-multipass.yaml ]; then
    echo -e "${RED}❌ Error: Failed to copy kubeconfig${NC}"
    exit 1
fi

export KUBECONFIG=/tmp/kubeconfig-multipass.yaml
echo -e "${GREEN}✅ Kubeconfig copied to local machine${NC}"

# Update kubeconfig with control plane IP
echo -e "${BLUE}🔧 Updating kubeconfig with control plane IP...${NC}"
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS sed requires backup extension
    sed -i.bak "s/127.0.0.1/$CP_IP/g" /tmp/kubeconfig-multipass.yaml
    sed -i.bak "s/localhost/$CP_IP/g" /tmp/kubeconfig-multipass.yaml
    rm -f /tmp/kubeconfig-multipass.yaml.bak
else
    # Linux sed
    sed -i "s/127.0.0.1/$CP_IP/g" /tmp/kubeconfig-multipass.yaml
    sed -i "s/localhost/$CP_IP/g" /tmp/kubeconfig-multipass.yaml
fi
echo -e "${GREEN}✅ Kubeconfig updated${NC}"
echo ""

# Install CNI plugin
echo -e "${BLUE}🌐 Installing CNI plugin ($CNI_PLUGIN)...${NC}"
if [ "$CNI_PLUGIN" = "flannel" ]; then
    kubectl --kubeconfig=/tmp/kubeconfig-multipass.yaml apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
elif [ "$CNI_PLUGIN" = "calico" ]; then
    kubectl --kubeconfig=/tmp/kubeconfig-multipass.yaml apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/calico.yaml
else
    echo -e "${RED}❌ Unknown CNI plugin: $CNI_PLUGIN${NC}"
    exit 1
fi
echo -e "${GREEN}✅ CNI plugin installed${NC}"
echo ""

# Wait for CNI to be ready
echo -e "${YELLOW}⏳ Waiting for CNI to be ready...${NC}"
sleep 30

# Check control plane node status
echo -e "${BLUE}📊 Checking cluster status...${NC}"
kubectl --kubeconfig=/tmp/kubeconfig-multipass.yaml get nodes
echo ""

# Get join command from control plane
echo -e "${BLUE}🔑 Getting join command...${NC}"
JOIN_CMD=$(multipass exec "$CONTROL_PLANE_VM" -- sudo kubeadm token create --print-join-command 2>/dev/null | tail -1)
echo -e "${GREEN}✅ Join command obtained${NC}"
echo ""

# Join worker nodes
if [ "$NUM_WORKERS" -gt 0 ] && [ -n "$JOIN_CMD" ]; then
    echo -e "${BLUE}🔗 Joining worker nodes to cluster...${NC}"
    for i in $(seq 1 $NUM_WORKERS); do
        echo -e "${YELLOW}   Setting up worker ${i}...${NC}"
        # First, install prerequisites on worker (without joining)
        multipass exec "${WORKER_VM_PREFIX}-${i}" -- bash <<'WORKER_SETUP'
            # Install kubeadm, kubelet, kubectl
            sudo apt-get update
            sudo apt-get install -y apt-transport-https ca-certificates curl gpg
            curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
            echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
            sudo apt-get update
            sudo apt-get install -y kubelet kubeadm kubectl
            sudo apt-mark hold kubelet kubeadm kubectl
            
            # Install containerd
            sudo apt-get install -y containerd
            sudo mkdir -p /etc/containerd
            containerd config default | sudo tee /etc/containerd/config.toml
            sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
            sudo systemctl restart containerd
            sudo systemctl enable containerd
            
            # Configure system
            sudo swapoff -a
            sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
            sudo modprobe overlay
            sudo modprobe br_netfilter
            echo 'net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1' | sudo tee /etc/sysctl.d/k8s.conf
            sudo sysctl --system
WORKER_SETUP
        
        echo -e "${YELLOW}   Joining worker ${i} to cluster...${NC}"
        # Now join the cluster
        multipass exec "${WORKER_VM_PREFIX}-${i}" -- sudo bash -c "$JOIN_CMD"
        echo -e "${GREEN}   ✅ Worker ${i} joined${NC}"
    done
    echo ""
    
    # Wait for workers to be ready
    echo -e "${YELLOW}⏳ Waiting for worker nodes to be ready...${NC}"
    sleep 20
fi

# Final status check
echo -e "${BLUE}📊 Final cluster status:${NC}"
kubectl --kubeconfig=/tmp/kubeconfig-multipass.yaml get nodes
echo ""

# Show connection info
echo -e "${GREEN}=========================================="
echo "✅ Cluster setup complete!"
echo "==========================================${NC}"
echo ""
echo -e "${BLUE}📋 Connection Information:${NC}"
echo "   Control Plane VM: $CONTROL_PLANE_VM"
echo "   Control Plane IP: $CP_IP"
echo "   Kubeconfig: /tmp/kubeconfig-multipass.yaml"
echo ""
echo -e "${BLUE}🔧 To use the cluster:${NC}"
echo "   export KUBECONFIG=/tmp/kubeconfig-multipass.yaml"
echo "   kubectl get nodes"
echo ""
echo -e "${BLUE}🖥️  To access VMs:${NC}"
echo "   multipass shell $CONTROL_PLANE_VM"
for i in $(seq 1 $NUM_WORKERS); do
    echo "   multipass shell ${WORKER_VM_PREFIX}-${i}"
done
echo ""
echo -e "${BLUE}🗑️  To clean up:${NC}"
echo "   multipass delete $CONTROL_PLANE_VM"
for i in $(seq 1 $NUM_WORKERS); do
    echo "   multipass delete ${WORKER_VM_PREFIX}-${i}"
done
echo "   multipass purge"
echo ""
echo -e "${YELLOW}💡 For the Q14 lab, you can now run 'make break-cluster' on the control plane VM${NC}"
echo "   multipass shell $CONTROL_PLANE_VM"
echo "   cd /home/ubuntu"
echo "   sudo bash break-cluster.sh"
echo ""

