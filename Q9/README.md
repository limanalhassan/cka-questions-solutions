# Q9: StorageClass Configuration Lab

This lab demonstrates how to create and configure a StorageClass in Kubernetes, including setting it as the default StorageClass.

## Overview

**Tasks:**
1. **Create** a new StorageClass named `low-latency`
2. **Configure** it to use provisioner `rancher.io/local-path`
3. **Set** `VolumeBindingMode` to `WaitForFirstConsumer` (MANDATORY)
4. **Make** it the default StorageClass for the cluster
5. **Do NOT modify** any existing Deployments or PersistentVolumeClaims

## What You'll Learn

- **StorageClass**: Understanding Kubernetes storage classes and their configuration
- **Provisioners**: How storage provisioners work
- **VolumeBindingMode**: Understanding `Immediate` vs `WaitForFirstConsumer`
- **Default StorageClass**: Setting and managing default storage classes
- **Resource Management**: Working with storage resources without modifying existing ones

## Prerequisites

- `kubectl` configured to access a Kubernetes cluster
- `make` installed
- Cluster with a storage provisioner (e.g., local-path-provisioner for kind)
- Basic understanding of Kubernetes storage concepts

**Note:** This lab uses `rancher.io/local-path` provisioner, which is commonly available in kind clusters. For other clusters, you may need to install the local-path-provisioner or use a different provisioner.

## Quick Start

### 1. Set up the lab environment

```bash
make all
```

This will:
- Create the `storage-lab` namespace
- Create an existing Deployment and PVC (these should NOT be modified)

### 2. Apply the solution

**Option 1: Manual solution (step by step)**
```bash
# Step 1: Remove default from existing StorageClass (if any)
kubectl patch storageclass standard -p '{"metadata": {"annotations": {"storageclass.kubernetes.io/is-default-class": "false"}}}'

# Step 2: Create the new StorageClass
kubectl apply -f solution.yaml
```

**Option 2: Automated solution**
```bash
make solution
```

### 3. Verify the solution

```bash
make verify
```

## Available Make Targets

- `make all` - Full lab setup (clean, setup)
- `make setup` - Create namespace, deployment, and PVC
- `make solution` - Complete automated solution
- `make create-storageclass` - Create the StorageClass only
- `make set-default` - Set StorageClass as default
- `make status` - Show environment summary
- `make verify` - Verify solution implementation
- `make show-storageclass` - Show StorageClass YAML
- `make list-storageclasses` - List all StorageClasses
- `make clean` - Clean up all resources

## Detailed Solution Steps

### Understanding StorageClass

**What is a StorageClass?**
- Defines different classes of storage available in a cluster
- Allows administrators to describe different types of storage
- Users can request storage with specific characteristics
- Each StorageClass has a provisioner that creates the actual storage

**Key Components:**
- **Name**: Unique identifier for the StorageClass
- **Provisioner**: Determines which volume plugin is used
- **Parameters**: Provisioner-specific configuration
- **VolumeBindingMode**: When volumes are bound and provisioned
- **ReclaimPolicy**: What happens to volumes when PVC is deleted

### Step 1: Create the StorageClass

Create a StorageClass with the required configuration:

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: low-latency
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
provisioner: rancher.io/local-path
volumeBindingMode: WaitForFirstConsumer
```

**Key fields:**
- **name**: `low-latency` (as required)
- **provisioner**: `rancher.io/local-path` (as required)
- **volumeBindingMode**: `WaitForFirstConsumer` (MANDATORY)
- **annotations**: `storageclass.kubernetes.io/is-default-class: "true"` (makes it default)

**Apply the StorageClass:**
```bash
kubectl apply -f solution.yaml
```

### Step 2: Set as Default StorageClass

**Method 1: Using annotation in YAML (recommended)**
```yaml
metadata:
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
```

**Method 2: Using kubectl patch**
```bash
kubectl patch storageclass low-latency -p '{"metadata": {"annotations": {"storageclass.kubernetes.io/is-default-class": "true"}}}'
```

**Important:** Only one StorageClass can be default at a time. If another StorageClass is already default, remove its default annotation first:

```bash
# Find existing default
kubectl get storageclass -o jsonpath='{.items[?(@.metadata.annotations.storageclass\.kubernetes\.io/is-default-class=="true")].metadata.name}'

# Remove default from existing StorageClass
kubectl patch storageclass <existing-default> -p '{"metadata": {"annotations": {"storageclass.kubernetes.io/is-default-class": "false"}}}'
```

### Step 3: Verify VolumeBindingMode (MANDATORY)

The `VolumeBindingMode` must be set to `WaitForFirstConsumer`. This is mandatory and will result in a reduced score if not set correctly.

**Check VolumeBindingMode:**
```bash
kubectl get storageclass low-latency -o jsonpath='{.volumeBindingMode}'
```

**Expected output:** `WaitForFirstConsumer`

### Understanding VolumeBindingMode

**Immediate:**
- Volume is bound and provisioned immediately when PVC is created
- Binding happens before pod scheduling
- Suitable for storage that can be accessed from any node

**WaitForFirstConsumer:**
- Volume binding is delayed until a pod using the PVC is scheduled
- Binding happens after pod scheduling
- Suitable for topology-constrained storage (e.g., local storage)
- Allows scheduler to consider pod's node requirements

**Why WaitForFirstConsumer for local-path?**
- Local-path provisioner creates storage on the node where the pod runs
- The scheduler needs to know which node the pod will run on
- Binding must wait until the pod is scheduled

## Verification

### Check StorageClass Configuration

```bash
# View StorageClass
kubectl get storageclass low-latency

# View detailed YAML
kubectl get storageclass low-latency -o yaml

# Check if it's default (should show *)
kubectl get storageclass
```

**Expected output:**
```
NAME            PROVISIONER             RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
low-latency     rancher.io/local-path   Delete          WaitForFirstConsumer   false                  1m
standard        kubernetes.io/no-provisioner   Delete   Immediate              false                  5m
```

The default StorageClass is marked with `(default)` in newer kubectl versions or with `*` in the output.

### Verify All Requirements

```bash
# 1. StorageClass exists
kubectl get storageclass low-latency

# 2. Provisioner is correct
kubectl get storageclass low-latency -o jsonpath='{.provisioner}'
# Expected: rancher.io/local-path

# 3. VolumeBindingMode is WaitForFirstConsumer (MANDATORY)
kubectl get storageclass low-latency -o jsonpath='{.volumeBindingMode}'
# Expected: WaitForFirstConsumer

# 4. Is default
kubectl get storageclass low-latency -o jsonpath='{.metadata.annotations.storageclass\.kubernetes\.io/is-default-class}'
# Expected: true

# 5. Existing resources not modified
kubectl get deploy app-deployment -n storage-lab
kubectl get pvc existing-pvc -n storage-lab
```

## Verification Checklist

After applying the solution, verify:

- [ ] StorageClass `low-latency` exists
- [ ] Provisioner is `rancher.io/local-path`
- [ ] VolumeBindingMode is `WaitForFirstConsumer` (MANDATORY)
- [ ] StorageClass is marked as default
- [ ] No other StorageClasses are marked as default
- [ ] Existing Deployment `app-deployment` was NOT modified
- [ ] Existing PVC `existing-pvc` was NOT modified

## Troubleshooting

### StorageClass not created

**Symptom:** `kubectl get storageclass low-latency` returns not found

**Solution:**
```bash
# Check if YAML is correct
cat solution.yaml

# Apply again
kubectl apply -f solution.yaml

# Check for errors
kubectl get events --sort-by='.lastTimestamp' | tail -20
```

### Wrong provisioner

**Symptom:** Provisioner doesn't match `rancher.io/local-path`

**Solution:**
```bash
# Check current provisioner
kubectl get storageclass low-latency -o jsonpath='{.provisioner}'

# Update provisioner
kubectl patch storageclass low-latency -p '{"provisioner": "rancher.io/local-path"}'
```

### VolumeBindingMode not set correctly

**Symptom:** VolumeBindingMode is not `WaitForFirstConsumer`

**Solution:**
```bash
# Check current value
kubectl get storageclass low-latency -o jsonpath='{.volumeBindingMode}'

# Update VolumeBindingMode (MANDATORY)
kubectl patch storageclass low-latency -p '{"volumeBindingMode": "WaitForFirstConsumer"}'
```

**Note:** This is MANDATORY. Failing to set this correctly will result in a reduced score.

### StorageClass not default

**Symptom:** Another StorageClass is still default

**Solution:**
```bash
# Find existing default
kubectl get storageclass -o jsonpath='{.items[?(@.metadata.annotations.storageclass\.kubernetes\.io/is-default-class=="true")].metadata.name}'

# Remove default from existing
kubectl patch storageclass <existing-name> -p '{"metadata": {"annotations": {"storageclass.kubernetes.io/is-default-class": "false"}}}'

# Set new default
kubectl patch storageclass low-latency -p '{"metadata": {"annotations": {"storageclass.kubernetes.io/is-default-class": "true"}}}'
```

### Multiple default StorageClasses

**Symptom:** Multiple StorageClasses marked as default

**Solution:**
```bash
# List all defaults
kubectl get storageclass -o jsonpath='{.items[?(@.metadata.annotations.storageclass\.kubernetes\.io/is-default-class=="true")].metadata.name}'

# Remove default from all except low-latency
for sc in $(kubectl get storageclass -o jsonpath='{.items[?(@.metadata.annotations.storageclass\.kubernetes\.io/is-default-class=="true")].metadata.name}'); do
  if [ "$sc" != "low-latency" ]; then
    kubectl patch storageclass $sc -p '{"metadata": {"annotations": {"storageclass.kubernetes.io/is-default-class": "false"}}}'
  fi
done
```

### Provisioner not available

**Symptom:** PVCs using the StorageClass are stuck in Pending

**Possible causes:**
- Local-path-provisioner not installed
- Wrong provisioner name

**Solution:**
```bash
# Check if local-path-provisioner is installed (for kind)
kubectl get pods -n local-path-storage

# Install local-path-provisioner (for kind)
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.24/deploy/local-path-storage.yaml

# For other clusters, check available provisioners
kubectl get storageclass
```

### Existing resources modified

**Symptom:** Deployment or PVC was accidentally modified

**Solution:**
- **DO NOT** modify existing resources
- If modified, restore from original YAML
- Check what was changed:
  ```bash
  kubectl get deploy app-deployment -n storage-lab -o yaml
  kubectl get pvc existing-pvc -n storage-lab -o yaml
  ```

## Common kubectl Commands

### Create StorageClass

```bash
# From YAML
kubectl apply -f solution.yaml

# Using kubectl create
kubectl create storageclass low-latency \
  --provisioner=rancher.io/local-path \
  --volume-binding-mode=WaitForFirstConsumer
```

### View StorageClass

```bash
# List all
kubectl get storageclass

# Get details
kubectl get storageclass low-latency -o yaml

# Get specific field
kubectl get storageclass low-latency -o jsonpath='{.provisioner}'
kubectl get storageclass low-latency -o jsonpath='{.volumeBindingMode}'
```

### Update StorageClass

```bash
# Patch annotation
kubectl patch storageclass low-latency -p '{"metadata": {"annotations": {"storageclass.kubernetes.io/is-default-class": "true"}}}'

# Patch VolumeBindingMode
kubectl patch storageclass low-latency -p '{"volumeBindingMode": "WaitForFirstConsumer"}'

# Edit interactively
kubectl edit storageclass low-latency
```

### Set Default StorageClass

```bash
# Remove default from existing
kubectl patch storageclass <old-default> -p '{"metadata": {"annotations": {"storageclass.kubernetes.io/is-default-class": "false"}}}'

# Set new default
kubectl patch storageclass low-latency -p '{"metadata": {"annotations": {"storageclass.kubernetes.io/is-default-class": "true"}}}'
```

## Files

- `q9.yaml` - Base setup (namespace, deployment, PVC - DO NOT MODIFY)
- `solution.yaml` - StorageClass definition
- `Makefile` - Automation for lab setup and solution
- `README.md` - This documentation

## Notes

- **StorageClass name**: Must be exactly `low-latency`
- **Provisioner**: Must be exactly `rancher.io/local-path`
- **VolumeBindingMode**: Must be `WaitForFirstConsumer` (MANDATORY - reduced score if incorrect)
- **Default annotation**: `storageclass.kubernetes.io/is-default-class: "true"`
- **Do NOT modify**: Existing Deployment `app-deployment` and PVC `existing-pvc`
- **Only one default**: Only one StorageClass can be default at a time
- **Provisioner availability**: Ensure local-path-provisioner is installed (common in kind clusters)

## Expected Outcomes

After successful solution:

✅ StorageClass `low-latency` created  
✅ Provisioner is `rancher.io/local-path`  
✅ VolumeBindingMode is `WaitForFirstConsumer` (MANDATORY)  
✅ StorageClass is marked as default  
✅ No other StorageClasses are default  
✅ Existing Deployment `app-deployment` unchanged  
✅ Existing PVC `existing-pvc` unchanged  
✅ New PVCs without storageClassName will use `low-latency`  

## Testing the StorageClass

### Create a test PVC

```bash
# Create PVC without storageClassName (will use default)
kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-pvc
  namespace: storage-lab
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 100Mi
EOF
```

### Verify PVC uses default StorageClass

```bash
# Check PVC
kubectl get pvc test-pvc -n storage-lab

# Check StorageClass used
kubectl get pvc test-pvc -n storage-lab -o jsonpath='{.spec.storageClassName}'
# Should show: low-latency

# Check VolumeBindingMode behavior
# With WaitForFirstConsumer, PV won't be created until pod is scheduled
kubectl get pv
```

### Clean up test resources

```bash
kubectl delete pvc test-pvc -n storage-lab
```

## Additional Resources

- [Kubernetes StorageClass Documentation](https://kubernetes.io/docs/concepts/storage/storage-classes/)
- [Volume Binding Modes](https://kubernetes.io/docs/concepts/storage/storage-classes/#volume-binding-mode)
- [Default StorageClass](https://kubernetes.io/docs/tasks/administer-cluster/change-default-storage-class/)
- [Local Path Provisioner](https://github.com/rancher/local-path-provisioner)

