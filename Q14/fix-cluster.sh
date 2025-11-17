#!/bin/bash
# Script to fix a broken kubeadm cluster after migration
# This script reverses the changes made by break-cluster.sh

set -e

echo "=========================================="
echo "Q14: Fixing Broken Kubeadm Cluster"
echo "=========================================="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "⚠️  This script requires root/sudo privileges"
    echo "   Please run with: sudo $0"
    exit 1
fi

# Get current node IP
CURRENT_IP=$(hostname -I | awk '{print $1}')
echo "📌 Current node IP: $CURRENT_IP"

# For single-node cluster, etcd is typically on the same node
# If using external etcd, you would set this to the etcd server IP
ETCD_IP="${CURRENT_IP}"

echo "🔧 Fixing cluster configurations..."
echo "   Control Plane IP: $CURRENT_IP"
echo "   etcd IP: $ETCD_IP"
echo ""

# Fix API server manifest
if [ -f /etc/kubernetes/manifests/kube-apiserver.yaml ]; then
    echo "🔧 Fixing kube-apiserver.yaml..."
    
    # Fix etcd endpoints
    sed -i "s|--etcd-servers=https://.*:2379|--etcd-servers=https://${ETCD_IP}:2379|g" \
        /etc/kubernetes/manifests/kube-apiserver.yaml
    
    # Fix advertise address
    sed -i "s|--advertise-address=.*|--advertise-address=${CURRENT_IP}|g" \
        /etc/kubernetes/manifests/kube-apiserver.yaml
    
    echo "   ✅ Fixed etcd endpoints and advertise address"
else
    echo "   ⚠️  kube-apiserver.yaml not found"
fi

# Fix kubelet config
if [ -f /etc/kubernetes/kubelet.conf ]; then
    echo "🔧 Fixing kubelet.conf..."
    
    # Fix server address
    sed -i "s|server: https://.*:6443|server: https://${CURRENT_IP}:6443|g" \
        /etc/kubernetes/kubelet.conf
    
    echo "   ✅ Fixed kubelet server address"
else
    echo "   ⚠️  kubelet.conf not found"
fi

# Fix admin config
if [ -f /etc/kubernetes/admin.conf ]; then
    echo "🔧 Fixing admin.conf..."
    
    # Fix server address
    sed -i "s|server: https://.*:6443|server: https://${CURRENT_IP}:6443|g" \
        /etc/kubernetes/admin.conf
    
    echo "   ✅ Fixed admin kubeconfig server address"
else
    echo "   ⚠️  admin.conf not found"
fi

# Fix user kubeconfig (root)
if [ -f ~/.kube/config ]; then
    echo "🔧 Fixing ~/.kube/config (root)..."
    
    # Fix server address
    sed -i "s|server: https://.*:6443|server: https://${CURRENT_IP}:6443|g" \
        ~/.kube/config
    
    echo "   ✅ Fixed ~/.kube/config (root) server address"
else
    echo "   ⚠️  ~/.kube/config (root) not found"
fi

# Fix ubuntu user kubeconfig
if [ -f /home/ubuntu/.kube/config ]; then
    echo "🔧 Fixing /home/ubuntu/.kube/config..."
    
    # Fix server address
    sed -i "s|server: https://.*:6443|server: https://${CURRENT_IP}:6443|g" \
        /home/ubuntu/.kube/config
    
    # Fix ownership in case it was modified
    chown ubuntu:ubuntu /home/ubuntu/.kube/config 2>/dev/null || true
    
    echo "   ✅ Fixed /home/ubuntu/.kube/config server address"
else
    echo "   ⚠️  /home/ubuntu/.kube/config not found"
fi

# Restart kubelet to apply changes
echo ""
echo "🔄 Restarting kubelet to apply fixes..."
systemctl restart kubelet

echo ""
echo "⏳ Waiting for cluster components to restart..."
sleep 10

# Wait for API server to be ready
echo "⏳ Waiting for API server to be ready..."
for i in {1..30}; do
    if kubectl get nodes &>/dev/null; then
        echo "   ✅ API server is responding"
        break
    fi
    echo "   Waiting... ($i/30)"
    sleep 2
done

echo ""
echo "✅ Cluster fixes applied!"
echo ""
echo "📋 Verifying cluster status..."
echo ""

# Check node status
echo "Nodes:"
kubectl get nodes || echo "   ⚠️  kubectl not working yet, may need more time"

echo ""
echo "Control plane pods:"
kubectl get pods -n kube-system 2>/dev/null || echo "   ⚠️  kubectl not working yet, may need more time"

echo ""
echo "📖 If nodes are still NotReady, wait a bit longer and check:"
echo "   kubectl get nodes"
echo "   kubectl get pods -n kube-system"
echo "   sudo journalctl -u kubelet -n 50"
echo ""

