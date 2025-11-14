# Q6: Argo CD Helm Installation Lab

This lab demonstrates installing Argo CD (Argo Continuous Delivery) in a Kubernetes cluster using Helm.

## Overview

Install Argo CD using Helm with the following requirements:
1. Add the official Argo CD Helm repository with name `argo`
2. Argo CD CRDs are pre-installed (don't install them via Helm)
3. Generate a Helm template for Argo CD version `7.7.3` and save to `/argo-helm.yaml`
   - Configure to not install CRDs
   - Namespace: `argocd`
4. Install Argo CD using Helm with release name `argocd`
   - Version: `7.7.3`
   - Namespace: `argocd`
   - Configure to not install CRDs
5. No need to configure access to the Argo CD server UI

## What is Argo CD?

Argo CD is a declarative, GitOps continuous delivery tool for Kubernetes:
- **GitOps**: Uses Git repositories as the source of truth
- **Declarative**: Desired state is defined in Git
- **Continuous Sync**: Automatically syncs applications to desired state
- **Multi-cluster**: Can manage multiple Kubernetes clusters
- **Web UI**: Provides a web interface for visualization

## Prerequisites

- `kubectl` configured to access a Kubernetes cluster
- `helm` installed (version 3.x)
- `make` installed
- Cluster admin permissions (for installing Argo CD)
- Root/sudo access (for writing to `/argo-helm.yaml` in exam environment)

**Check Helm installation:**
```bash
helm version
```

**Install Helm (if needed):**
```bash
# macOS
brew install helm

# Or download from: https://helm.sh/docs/intro/install/
```

## Quick Start

### 1. Set up the lab environment

```bash
make all
```

This will:
- Create the `argocd` namespace
- Pre-install Argo CD CRDs (as per requirements)

### 2. Install Argo CD (Solution)

**Option 1: Manual installation (step by step)**
```bash
# Step 1: Add Helm repository
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

# Step 2: Generate template
helm template argocd argo/argo-cd --version 7.7.3 \
  --namespace argocd \
  --create-namespace \
  --skip-crds > /argo-helm.yaml

# Step 3: Install Argo CD
helm install argocd argo/argo-cd --version 7.7.3 \
  --namespace argocd \
  --create-namespace \
  --skip-crds
```

**Option 2: Automated solution**
```bash
make solution
```

### 3. Verify the installation

```bash
make verify
```

Or check manually:
```bash
helm list -n argocd
kubectl -n argocd get pods
```

## Available Make Targets

- `make all` - Full lab setup (clean, setup)
- `make setup` - Create namespace and pre-install CRDs
- `make repo-add` - Add Argo CD Helm repository
- `make template` - Generate Helm template (saves to ./argo-helm.yaml)
- `make install` - Install Argo CD via Helm
- `make solution` - Complete solution (repo-add, template, install)
- `make status` - Show environment summary
- `make verify` - Verify Argo CD installation
- `make clean` - Clean up all resources

## Detailed Installation Steps

### Step 1: Add Helm Repository

```bash
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
```

**Verify:**
```bash
helm repo list
```

Expected output should include:
```
NAME    URL
argo    https://argoproj.github.io/argo-helm
```

### Step 2: Generate Helm Template

Generate the template with CRDs disabled and save to `/argo-helm.yaml`:

```bash
helm template argocd argo/argo-cd --version 7.7.3 \
  --namespace argocd \
  --create-namespace \
  --skip-crds > /argo-helm.yaml
```

**Key flags:**
- `argocd`: Release name
- `argo/argo-cd`: Repository/chart name
- `--version 7.7.3`: Chart version
- `--namespace argocd`: Target namespace
- `--create-namespace`: Create namespace if it doesn't exist
- `--skip-crds`: Don't include CRDs in template (they're pre-installed)

**Note:** Writing to `/argo-helm.yaml` requires root access. In exam environments, you may need `sudo`.

**For local testing:**
```bash
helm template argocd argo/argo-cd --version 7.7.3 \
  --namespace argocd \
  --create-namespace \
  --skip-crds > ./argo-helm.yaml
```

### Step 3: Install Argo CD

Install using the same configuration:

```bash
helm install argocd argo/argo-cd --version 7.7.3 \
  --namespace argocd \
  --create-namespace \
  --skip-crds
```

**Verify installation:**
```bash
helm list -n argocd
kubectl -n argocd get pods
```

### Step 4: Wait for Argo CD to be Ready

```bash
kubectl -n argocd wait --for=condition=available --timeout=300s deployment/argocd-server
kubectl -n argocd get pods
```

## Understanding the Installation

### Helm Repository

- **Repository name**: `argo` (as specified)
- **Repository URL**: `https://argoproj.github.io/argo-helm`
- Contains the official Argo CD Helm charts

### Helm Chart Configuration

- **Chart**: `argo-cd`
- **Version**: `7.7.3` (must match in both template and install)
- **Release name**: `argocd`
- **Namespace**: `argocd`
- **CRDs**: Skipped (pre-installed)

### Why Skip CRDs?

- CRDs are pre-installed in the cluster (as per requirements)
- Installing them via Helm would cause conflicts
- Using `--skip-crds` prevents Helm from managing CRDs

### Template File Location

- **Exam requirement**: `/argo-helm.yaml` (root filesystem)
- **Local testing**: `./argo-helm.yaml` (current directory)
- The template is a reference/manifest of what will be installed

## Verification Checklist

After installation, verify:

- [ ] Helm repository `argo` is added
- [ ] Helm template generated and saved (to `/argo-helm.yaml` or `./argo-helm.yaml`)
- [ ] Helm release `argocd` is installed
- [ ] Argo CD pods are running in `argocd` namespace
- [ ] Argo CD services are created
- [ ] CRDs are not installed by Helm (they're pre-installed)

## Troubleshooting

### Helm repository not found

**Symptom:** `Error: could not find chart argo/argo-cd`

**Solution:**
```bash
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
```

### Cannot write to /argo-helm.yaml

**Symptom:** Permission denied when writing to `/argo-helm.yaml`

**Solution:**
```bash
# Use sudo (exam environment)
sudo helm template argocd argo/argo-cd --version 7.7.3 \
  --namespace argocd \
  --create-namespace \
  --skip-crds > /argo-helm.yaml

# Or save to current directory for testing
helm template argocd argo/argo-cd --version 7.7.3 \
  --namespace argocd \
  --create-namespace \
  --skip-crds > ./argo-helm.yaml
```

### CRD conflicts

**Symptom:** Error about CRDs already existing

**Solution:**
- Ensure `--skip-crds` flag is used in both template and install commands
- Verify CRDs are pre-installed: `kubectl get crd | grep argoproj.io`

### Argo CD pods not starting

**Symptom:** Pods stuck in `Pending` or `ContainerCreating`

**Possible causes:**
- Insufficient cluster resources
- Image pull issues
- Resource quotas

**Solution:**
```bash
# Check pod status
kubectl -n argocd describe pods

# Check events
kubectl -n argocd get events

# Check resource usage
kubectl top nodes
```

### Wrong Helm chart version

**Symptom:** Version mismatch or chart not found

**Solution:**
- Verify version exists: `helm search repo argo/argo-cd --versions | head -10`
- Use exact version: `7.7.3`
- Ensure repository is updated: `helm repo update`

## Files

- `q6.yaml` - Base setup (namespace and pre-installed CRDs)
- `solution.yaml` - Solution reference with commands
- `Makefile` - Automation for lab setup and installation
- `argo-helm.yaml` - Generated Helm template (created during solution)

## Notes

- **CRDs are pre-installed**: Don't install them via Helm
- **Version consistency**: Use `7.7.3` for both template and install
- **Template file**: Must be saved to `/argo-helm.yaml` (root filesystem) in exam
- **Namespace**: Always use `argocd` namespace
- **Release name**: Must be `argocd`
- **Repository name**: Must be `argo`
- **No UI configuration**: As per requirements, UI access setup is not needed

## Expected Outcomes

After successful installation:

✅ Helm repository `argo` added  
✅ Helm template generated and saved to `/argo-helm.yaml`  
✅ Helm release `argocd` installed in `argocd` namespace  
✅ Argo CD pods running (argocd-server, argocd-repo-server, argocd-application-controller, etc.)  
✅ Argo CD services created  
✅ CRDs not installed by Helm (pre-installed)  
✅ Installation uses version `7.7.3`  

## Additional Resources

- [Argo CD Documentation](https://argo-cd.readthedocs.io/)
- [Argo CD Helm Chart](https://github.com/argoproj/argo-helm/tree/main/charts/argo-cd)
- [Helm Documentation](https://helm.sh/docs/)

