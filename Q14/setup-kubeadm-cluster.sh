#!/bin/bash
# Setup script for creating a kubeadm cluster for Q14 lab
# This script provides instructions and automation for setting up a kubeadm cluster

set -e

echo "=========================================="
echo "Q14: Kubeadm Cluster Setup"
echo "=========================================="
echo ""

# Detect OS first (before root check, so we can show instructions for macOS/Windows)
OS="unknown"
OS_TYPE="unknown"

# Check for macOS
if [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
    OS_TYPE="macos"
    echo "📋 Detected OS: macOS"
    echo ""
    echo "⚠️  kubeadm requires Linux. macOS is not supported directly."
    echo ""
    echo "💡 Options to run kubeadm on macOS:"
    echo ""
    echo "Option 1: Use a Linux VM (Recommended)"
    echo "   - Install VirtualBox, VMware, or Parallels"
    echo "   - Create an Ubuntu/Debian VM"
    echo "   - Run this script inside the VM"
    echo ""
    echo "Option 2: Use Docker Desktop with a Linux container"
    echo "   - Use a Linux container with systemd support"
    echo "   - Example: docker run -it --privileged ubuntu:22.04"
    echo ""
    echo "Option 3: Use Multipass (Ubuntu VMs)"
    echo "   - Install: brew install multipass"
    echo "   - Create VM: multipass launch --name kubeadm-vm"
    echo "   - Access: multipass shell kubeadm-vm"
    echo "   - Run this script inside the VM"
    echo ""
    echo "Option 4: Use UTM (Free VM for macOS)"
    echo "   - Install: brew install --cask utm"
    echo "   - Create an Ubuntu VM"
    echo "   - Run this script inside the VM"
    echo ""
    read -p "Would you like to see instructions for setting up a VM? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo ""
        echo "📖 Quick VM Setup Instructions:"
        echo ""
        echo "1. Install Multipass:"
        echo "   brew install multipass"
        echo ""
        echo "2. Create a VM:"
        echo "   multipass launch --name kubeadm-vm --cpus 2 --mem 4G --disk 20G"
        echo ""
        echo "3. Access the VM:"
        echo "   multipass shell kubeadm-vm"
        echo ""
        echo "4. Copy this script to the VM:"
        echo "   multipass transfer setup-kubeadm-cluster.sh kubeadm-vm:/home/ubuntu/"
        echo ""
        echo "5. Run the script in the VM:"
        echo "   sudo bash setup-kubeadm-cluster.sh"
        echo ""
    fi
    exit 0
fi

# Check for Windows (Git Bash, WSL, or Cygwin)
if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]] || [[ -n "$WSL_DISTRO_NAME" ]]; then
    OS="windows"
    OS_TYPE="windows"
    echo "📋 Detected OS: Windows"
    echo ""
    echo "⚠️  kubeadm requires Linux. Windows is not supported directly."
    echo ""
    echo "💡 Options to run kubeadm on Windows:"
    echo ""
    echo "Option 1: Use WSL2 (Windows Subsystem for Linux) - Recommended"
    echo "   - Install WSL2: wsl --install"
    echo "   - Install Ubuntu from Microsoft Store"
    echo "   - Open Ubuntu terminal"
    echo "   - Run this script inside WSL2"
    echo ""
    echo "Option 2: Use a Linux VM"
    echo "   - Install VirtualBox or VMware"
    echo "   - Create an Ubuntu/Debian VM"
    echo "   - Run this script inside the VM"
    echo ""
    echo "Option 3: Use Docker Desktop with WSL2 backend"
    echo "   - Enable WSL2 integration in Docker Desktop"
    echo "   - Use a Linux container"
    echo ""
    read -p "Would you like to see WSL2 setup instructions? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo ""
        echo "📖 WSL2 Setup Instructions:"
        echo ""
        echo "1. Install WSL2:"
        echo "   wsl --install"
        echo ""
        echo "2. Restart your computer"
        echo ""
        echo "3. Open Ubuntu terminal (from Start Menu)"
        echo ""
        echo "4. Copy this script to WSL2:"
        echo "   # From Windows, copy to WSL2:"
        echo "   # The script should be in your Windows user directory"
        echo ""
        echo "5. Run the script in WSL2:"
        echo "   sudo bash setup-kubeadm-cluster.sh"
        echo ""
    fi
    exit 0
fi

# Check for Linux
# Now check if running as root (only needed for Linux)
if [ "$OSTYPE" != "darwin"* ] && [ "$OSTYPE" != "msys" ] && [ "$OSTYPE" != "cygwin" ] && [ -z "$WSL_DISTRO_NAME" ]; then
    if [ "$EUID" -ne 0 ]; then 
        echo "⚠️  This script requires root/sudo privileges"
        echo "   Please run with: sudo $0"
        exit 1
    fi
fi

# Check for Linux
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    OS_TYPE="linux"
    echo "📋 Detected OS: $OS (Linux)"
    echo ""
elif [ -f /etc/redhat-release ]; then
    OS="rhel"
    OS_TYPE="linux"
    echo "📋 Detected OS: RHEL/CentOS (Linux)"
    echo ""
else
    echo "⚠️  Cannot detect OS type."
    echo "   Detected: $OSTYPE"
    echo ""
    echo "💡 This script is designed for:"
    echo "   - Linux (Ubuntu, Debian, CentOS, RHEL)"
    echo "   - macOS (will show VM options)"
    echo "   - Windows (will show WSL2 options)"
    echo ""
    echo "If you're on Linux, please ensure /etc/os-release exists."
    exit 1
fi

# Function to install kubeadm on Ubuntu/Debian
install_kubeadm_ubuntu() {
    echo "🔧 Installing kubeadm, kubelet, kubectl on Ubuntu/Debian..."
    
    echo "alias k=kubectl" >> ~/.bashrc
    echo "alias cl=clear" >> ~/.bashrc
    source ~/.bashrc

    apt-get update
    apt-get install -y apt-transport-https ca-certificates curl gpg
    
    # Add Kubernetes repository
    curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
    echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list
    
    apt-get update
    apt-get install -y kubelet kubeadm kubectl
    apt-mark hold kubelet kubeadm kubectl
    
    echo "✅ Kubernetes tools installed"
}

# Function to install kubeadm on CentOS/RHEL
install_kubeadm_centos() {
    echo "🔧 Installing kubeadm, kubelet, kubectl on CentOS/RHEL..."
    
    # Add Kubernetes repository
    cat <<EOF | tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.28/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.28/rpm/repodata/repomd.xml.key
EOF
    
    yum install -y kubelet kubeadm kubectl
    systemctl enable --now kubelet
    
    echo "✅ Kubernetes tools installed"
}

# Install containerd if not present
install_containerd() {
    if command -v containerd &> /dev/null; then
        echo "✅ containerd already installed"
        return
    fi
    
    echo "🔧 Installing containerd..."
    
    if [ "$OS" = "ubuntu" ] || [ "$OS" = "debian" ]; then
        apt-get update
        apt-get install -y containerd
    elif [ "$OS" = "centos" ] || [ "$OS" = "rhel" ]; then
        yum install -y containerd
    fi
    
    # Configure containerd
    mkdir -p /etc/containerd
    containerd config default | tee /etc/containerd/config.toml
    sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
    systemctl restart containerd
    systemctl enable containerd
    
    echo "✅ containerd installed and configured"
}

# Configure system prerequisites
configure_system() {
    echo "🔧 Configuring system prerequisites..."
    
    # Disable swap
    swapoff -a
    sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
    
    # Load kernel modules
    modprobe overlay
    modprobe br_netfilter
    
    # Configure sysctl
    cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
    sysctl --system
    
    echo "✅ System configured"
}

# Initialize kubeadm cluster
init_cluster() {
    echo "🚀 Initializing kubeadm cluster..."
    
    # Get node IP
    NODE_IP=$(hostname -I | awk '{print $1}')
    echo "📌 Using node IP: $NODE_IP"
    
    # Initialize cluster
    kubeadm init \
        --apiserver-advertise-address=$NODE_IP \
        --pod-network-cidr=10.244.0.0/16 \
        --ignore-preflight-errors=Swap
    
    # Configure kubectl
    mkdir -p $HOME/.kube
    cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    chown $(id -u):$(id -g) $HOME/.kube/config
    
    echo "✅ Cluster initialized"
    echo ""
    echo "📝 Next steps:"
    echo "   1. Install a CNI plugin (e.g., Flannel):"
    echo "      kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml"
    echo "   2. Wait for nodes to be Ready:"
    echo "      kubectl get nodes"
    echo ""
}

# Main execution
main() {
    echo "Starting kubeadm cluster setup..."
    echo ""
    
# Install Kubernetes tools (only for Linux)
if [ "$OS_TYPE" != "linux" ]; then
    echo "❌ This script can only run on Linux."
    echo "   Please use a VM or WSL2 as suggested above."
    exit 1
fi

if [ "$OS" = "ubuntu" ] || [ "$OS" = "debian" ]; then
    install_kubeadm_ubuntu
elif [ "$OS" = "centos" ] || [ "$OS" = "rhel" ] || [ "$OS" = "rocky" ] || [ "$OS" = "almalinux" ]; then
    install_kubeadm_centos
else
    echo "⚠️  Unsupported Linux distribution: $OS"
    echo ""
    echo "Supported distributions:"
    echo "  - Ubuntu"
    echo "  - Debian"
    echo "  - CentOS"
    echo "  - RHEL"
    echo "  - Rocky Linux"
    echo "  - AlmaLinux"
    echo ""
    echo "You can try to install kubeadm manually:"
    echo "  https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/"
    exit 1
fi
    
    # Install containerd
    install_containerd
    
    # Configure system
    configure_system
    
    # Initialize cluster
    init_cluster
    
    echo "✅ Setup complete!"
    echo ""
    echo "⚠️  Note: For the Q14 lab, you'll need to:"
    echo "   1. Install a CNI plugin"
    echo "   2. Run the break-cluster.sh script to simulate migration issues"
    echo "   3. Then fix the issues as per the lab instructions"
}

# Run main function
main

