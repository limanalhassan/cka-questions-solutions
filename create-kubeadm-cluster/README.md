# Kubeadm Cluster Creation Utility

This folder contains utility scripts for creating and managing kubeadm clusters. These scripts are **standalone utilities** that can be used to set up kubeadm clusters for any purpose.

## Purpose

This is **NOT** a lab or question folder. It's a utility folder that provides:
- Automated kubeadm cluster creation using Multipass
- Scripts for adding worker nodes
- Scripts for breaking/fixing clusters (for troubleshooting practice)

## Usage

```bash
# Create a complete cluster
make cluster

# Check cluster status
make status

# Access control plane VM
make shell

# Get kubeconfig
make kubeconfig

# Break cluster (for troubleshooting practice)
make break

# Fix cluster
make fix

# Clean up
make clean
```

## Scripts

- `setup-multipass-cluster.sh` - End-to-end automated cluster setup using Multipass
- `setup-kubeadm-cluster.sh` - Manual control plane setup script
- `add-worker-node.sh` - Script to add worker nodes
- `break-cluster.sh` - Script to simulate cluster migration issues
- `fix-cluster.sh` - Script to fix broken clusters (if available)

## Relationship to Q14

The Q14 lab (Kubeadm Cluster Migration Troubleshooting) uses similar scripts but has its own copies for the lab-specific workflow. This folder is a standalone utility that can be used independently.

## Requirements

- Multipass installed (for macOS/Windows)
- Or a Linux machine with kubeadm support
- sudo/root access
- Internet connection


