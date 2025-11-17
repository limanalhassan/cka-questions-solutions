#!/bin/bash
# Script to simulate cluster migration issues
# This script "breaks" the cluster by changing IPs to simulate migration

set -e

echo "=========================================="
echo "Q14: Simulating Cluster Migration Issues"
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

# Generate a fake "old" IP (using a different subnet)
OLD_IP="192.168.100.100"
OLD_ETCD_IP="192.168.100.200"

echo "🔧 Simulating migration from old IPs:"
echo "   Old Control Plane IP: $OLD_IP"
echo "   Old etcd IP: $OLD_ETCD_IP"
echo ""

# Backup original files
BACKUP_DIR="/etc/kubernetes/backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo "💾 Creating backup in $BACKUP_DIR..."

# Backup API server manifest
if [ -f /etc/kubernetes/manifests/kube-apiserver.yaml ]; then
    cp /etc/kubernetes/manifests/kube-apiserver.yaml "$BACKUP_DIR/"
    echo "   ✅ Backed up kube-apiserver.yaml"
    
    # Break: Change etcd endpoints to old IP
    sed -i "s|--etcd-servers=https://.*:2379|--etcd-servers=https://${OLD_ETCD_IP}:2379|g" \
        /etc/kubernetes/manifests/kube-apiserver.yaml
    
    # Break: Change advertise address to old IP
    sed -i "s|--advertise-address=.*|--advertise-address=${OLD_IP}|g" \
        /etc/kubernetes/manifests/kube-apiserver.yaml
    
    echo "   ⚠️  Modified kube-apiserver.yaml with old IPs"
else
    echo "   ⚠️  kube-apiserver.yaml not found"
fi

# Backup and break kubelet config
if [ -f /etc/kubernetes/kubelet.conf ]; then
    cp /etc/kubernetes/kubelet.conf "$BACKUP_DIR/"
    echo "   ✅ Backed up kubelet.conf"
    
    # Break: Change server address to old IP
    sed -i "s|server: https://.*:6443|server: https://${OLD_IP}:6443|g" \
        /etc/kubernetes/kubelet.conf
    
    echo "   ⚠️  Modified kubelet.conf with old IP"
else
    echo "   ⚠️  kubelet.conf not found"
fi

# Backup and break admin config
if [ -f /etc/kubernetes/admin.conf ]; then
    cp /etc/kubernetes/admin.conf "$BACKUP_DIR/"
    echo "   ✅ Backed up admin.conf"
    
    # Break: Change server address to old IP
    sed -i "s|server: https://.*:6443|server: https://${OLD_IP}:6443|g" \
        /etc/kubernetes/admin.conf
    
    echo "   ⚠️  Modified admin.conf with old IP"
else
    echo "   ⚠️  admin.conf not found"
fi

# Backup and break user kubeconfig
if [ -f ~/.kube/config ]; then
    cp ~/.kube/config "$BACKUP_DIR/kubeconfig-user"
    echo "   ✅ Backed up ~/.kube/config"
    
    # Break: Change server address to old IP
    sed -i "s|server: https://.*:6443|server: https://${OLD_IP}:6443|g" \
        ~/.kube/config
    
    echo "   ⚠️  Modified ~/.kube/config with old IP"
else
    echo "   ⚠️  ~/.kube/config not found"
fi

# Restart kubelet to apply changes
echo ""
echo "🔄 Restarting kubelet to apply changes..."
systemctl restart kubelet

echo ""
echo "✅ Cluster has been 'broken' to simulate migration issues!"
echo ""
echo "📋 Summary of changes:"
echo "   - etcd endpoints changed to: $OLD_ETCD_IP"
echo "   - API server advertise address changed to: $OLD_IP"
echo "   - kubelet server address changed to: $OLD_IP"
echo "   - kubeconfig server addresses changed to: $OLD_IP"
echo ""
echo "💾 Backup location: $BACKUP_DIR"
echo ""
echo "🔧 To fix the cluster, you need to:"
echo "   1. Update all IPs back to: $CURRENT_IP"
echo "   2. Update etcd IP to the correct value"
echo "   3. Restart kubelet"
echo ""
echo "📖 See solution.yaml and README.md for detailed fix steps"

