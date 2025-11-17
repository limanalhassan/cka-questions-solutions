# CKA (Certified Kubernetes Administrator) Practice Labs

A comprehensive collection of hands-on labs designed to help you prepare for the Certified Kubernetes Administrator (CKA) exam. Each lab focuses on specific Kubernetes concepts and real-world scenarios you'll encounter in the exam.

## 📋 Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Repository Structure](#repository-structure)
- [Available Labs](#available-labs)
- [Root Makefile Usage](#root-makefile-usage)
- [Individual Lab Usage](#individual-lab-usage)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)

## 🎯 Overview

This repository contains **14 practice labs** covering essential CKA exam topics:

- **Configuration & Management**: ConfigMaps, Secrets, Deployments, Services
- **Storage**: PersistentVolumes, PersistentVolumeClaims, StorageClasses
- **Networking**: Services, NetworkPolicies, Ingress
- **Security**: RBAC, SecurityContext, NetworkPolicies
- **Troubleshooting**: Cluster debugging, pod issues, network problems
- **Cluster Administration**: kubeadm, cluster upgrades, node management

Each lab includes:
- ✅ Environment setup scripts
- ✅ Problem scenarios
- ✅ Step-by-step solutions
- ✅ Automated verification
- ✅ Comprehensive documentation

## 🔧 Prerequisites

### Required Tools

- **kubectl** - Kubernetes command-line tool
  ```bash
  # Verify installation
  kubectl version --client
  ```

- **make** - Build automation tool
  ```bash
  # macOS
  xcode-select --install
  
  # Linux (Ubuntu/Debian)
  sudo apt-get install make
  ```

- **Access to a Kubernetes cluster** - Any of the following:
  - Local cluster (minikube, kind, k3d)
  - Cloud provider cluster (EKS, GKE, AKS)
  - Self-hosted cluster
  - **Note**: Q14 requires a kubeadm cluster (scripts provided)

### Optional Tools

- **curl** - For testing HTTP endpoints
- **openssl** - For certificate generation (Q01)
- **Multipass** - For Q14 kubeadm cluster setup (macOS/Windows)
- **jq** - For JSON parsing (some labs)

## 🚀 Quick Start

### 1. Clone or Navigate to the Repository

```bash
cd /path/to/CKA
```

### 2. Verify Prerequisites

```bash
# Check kubectl
kubectl cluster-info

# Check make
make --version
```

### 3. Set Up All Labs (Recommended for First Time)

```bash
# Set up all lab environments at once
make setup
```

This will:
- Create all necessary namespaces
- Deploy all required resources
- Set up test environments
- **Note**: Q14 is skipped (requires special kubeadm cluster setup)

### 4. Work on a Specific Lab

```bash
# Navigate to a lab directory
cd Q01

# Set up the lab environment
make setup

# Work on the problem, then verify
make verify

# Apply the solution
make solution

# Clean up when done
make clean
```

## 📁 Repository Structure

```
CKA/
├── README.md                    # This file
├── Makefile                     # Root Makefile for managing all labs
│
├── Q01/                          # NGINX TLSv1.3 Configuration
│   ├── README.md
│   ├── Makefile
│   ├── q1.yaml
│   ├── solution.yaml
│   └── Q01.jpg
│
├── Q02/                          # Lab 2
│   └── ...
│
├── Q12/                         # MariaDB PersistentVolume Recovery
│   ├── README.md
│   ├── Makefile
│   ├── q12.yaml
│   └── solution.yaml
│
├── Q13/                         # NetworkPolicy Configuration
│   ├── README.md
│   ├── Makefile
│   ├── q13.yaml
│   ├── solution.yaml
│   └── create-netpol-files.sh
│
├── Q14/                         # Kubeadm Cluster Troubleshooting
│   ├── README.md
│   ├── Makefile
│   ├── q14.yaml
│   ├── solution.yaml
│   ├── setup-kubeadm-cluster.sh
│   ├── break-cluster.sh
│   └── fix-cluster.sh
│
└── create-kubeadm-cluster/      # Utility for creating kubeadm clusters
    ├── README.md
    ├── Makefile
    ├── setup-kubeadm-cluster.sh
    ├── setup-multipass-cluster.sh
    └── add-worker-node.sh
```

## 📚 Available Labs

### Q01: NGINX TLSv1.3 Configuration
**Topic**: ConfigMaps, TLS Configuration  
**Difficulty**: ⭐⭐  
**Time**: 10-15 minutes  
**Focus**: Update NGINX ConfigMap to allow only TLSv1.3 connections

### Q02-Q11: [Various Topics]
*Check individual lab READMEs for details*

### Q12: MariaDB PersistentVolume Recovery
**Topic**: PersistentVolumes, PersistentVolumeClaims, Data Recovery  
**Difficulty**: ⭐⭐⭐  
**Time**: 15-20 minutes  
**Focus**: Recover a deleted Deployment while preserving data using existing PVs

### Q13: NetworkPolicy Configuration
**Topic**: NetworkPolicies, Network Security  
**Difficulty**: ⭐⭐⭐⭐  
**Time**: 20-25 minutes  
**Focus**: Configure NetworkPolicies to allow frontend-backend communication with least permissive rules

### Q14: Kubeadm Cluster Migration Troubleshooting
**Topic**: Cluster Administration, Troubleshooting, kubeadm  
**Difficulty**: ⭐⭐⭐⭐⭐  
**Time**: 30-45 minutes  
**Focus**: Fix a broken kubeadm cluster after machine migration  
**Special**: Requires a real kubeadm cluster (setup scripts provided)

## 🛠️ Root Makefile Usage

The root `Makefile` provides convenient commands to manage all labs from a single location.

### Available Commands

```bash
# Show help and available labs
make help

# Set up all lab environments (Q14 skipped)
make setup

# Set up a specific lab
make setup-Q01
make setup-Q12
make setup-Q13

# Clean up all labs
make clean

# Clean up a specific lab
make clean-Q01

# Apply solution to a specific lab
make solution-Q01

# Check status of all labs
make status
```

### Examples

```bash
# Set up labs Q01, Q12, and Q13
make setup-Q01 setup-Q12 setup-Q13

# Clean up everything and start fresh
make clean
make setup

# Work on Q12: set up, solve, verify, clean
make setup-Q12
# ... work on the problem ...
make solution-Q12
make clean-Q12
```

## 📖 Individual Lab Usage

Each lab directory contains its own `Makefile` with lab-specific targets.

### Common Targets (Available in Most Labs)

```bash
# Set up the lab environment
make setup

# Apply the solution
make solution

# Verify your work (if available)
make verify

# Clean up all resources
make clean

# Show help
make help
```

### Lab-Specific Targets

Some labs have additional targets:

- **Q01**: `make cert`, `make deploy`, `make forward`, `make test`
- **Q12**: `make verify`, `make check-pv`
- **Q13**: `make verify`, `make test-communication`
- **Q14**: `make setup-cluster`, `make break`, `make fix`, `make cluster`

**Always check the lab's README.md for specific instructions!**

## 🔍 Troubleshooting

### Common Issues

#### 1. "kubectl: command not found"
```bash
# Install kubectl
# macOS
brew install kubectl

# Linux
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
```

#### 2. "make: command not found"
```bash
# macOS
xcode-select --install

# Linux (Ubuntu/Debian)
sudo apt-get install make
```

#### 3. "Error from server (Forbidden)"
- Check your kubeconfig: `kubectl config view`
- Verify cluster access: `kubectl cluster-info`
- Ensure you have proper RBAC permissions

#### 4. "Error: namespace already exists"
- Clean up the lab: `make clean` (in the lab directory)
- Or delete manually: `kubectl delete ns <namespace>`

#### 5. Q14: "Failed to connect: No route to host"
- Wait a few seconds for VMs to fully boot
- Check VM status: `multipass list`
- Retry the command

#### 6. PersistentVolume Issues (Q12)
- Check PV status: `kubectl get pv`
- Clear claimRef if needed: `kubectl patch pv <pv-name> -p '{"spec":{"claimRef":null}}'`
- Ensure PV is in `Available` state before creating PVC

### Getting Help

1. **Check the lab's README.md** - Each lab has detailed documentation
2. **Review solution.yaml** - Compare your approach with the solution
3. **Check kubectl output** - Use `kubectl describe` and `kubectl logs` for debugging
4. **Verify prerequisites** - Ensure all required tools are installed

## 🎓 Study Tips

1. **Read the README First** - Each lab's README explains the concepts and requirements
2. **Try Before Looking at Solutions** - Attempt the problem before checking `solution.yaml`
3. **Understand, Don't Memorize** - Focus on understanding why solutions work
4. **Practice Time Management** - CKA exam is time-constrained; practice working efficiently
5. **Use kubectl Help** - Learn `kubectl explain` and `kubectl --help`
6. **Practice Imperative Commands** - Exam allows both imperative and declarative approaches

## 📝 Notes

- **Q14 Special Requirements**: Q14 requires a real kubeadm cluster. Use the provided scripts in `create-kubeadm-cluster/` or `Q14/` to set up a test cluster.
- **Resource Cleanup**: Always clean up labs when done to avoid resource conflicts
- **Cluster Requirements**: Most labs work with any Kubernetes cluster (minikube, kind, cloud, etc.)
- **Solution Files**: Each lab includes a `solution.yaml` file for reference, but try solving problems yourself first!

## 🤝 Contributing

Found an issue or have a suggestion? 

1. Check if the issue is already documented
2. Review the lab's README for clarification
3. Verify your environment meets prerequisites
4. Check kubectl and cluster logs for errors

## 📄 License

This repository is for educational purposes to help prepare for the CKA exam.

## 🔗 Useful Resources

- [Kubernetes Official Documentation](https://kubernetes.io/docs/)
- [CKA Exam Curriculum](https://www.cncf.io/certification/cka/)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [Kubernetes API Reference](https://kubernetes.io/docs/reference/kubernetes-api/)

---

**Good luck with your CKA exam preparation! 🚀**
