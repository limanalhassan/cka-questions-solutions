# Q12: MariaDB PersistentVolume Recovery Lab

This lab demonstrates how to recover a deleted MariaDB Deployment while preserving data by reusing an existing PersistentVolume through a PersistentVolumeClaim.

## Overview

**Scenario:** A user accidentally deleted the MariaDB Deployment in the `mariadb` namespace, which was configured with persistent storage.

**Task:** Re-establish the Deployment while ensuring data is preserved by reusing the available PersistentVolume.

**Requirements:**
1. A PersistentVolume already exists and is retained for reuse (only one PV exists)
2. Create a PersistentVolumeClaim (PVC) named `mariadb` in the `mariadb` namespace
   - Access mode: `ReadWriteOnce`
   - Storage: `250Mi`
3. Edit the MariaDB Deployment file at `~/mariadb-deploy.yaml` to use the PVC
4. Apply the updated Deployment file to the cluster
5. Ensure the MariaDB Deployment is running and stable

## What You'll Learn

- **PersistentVolume (PV)**: Understanding cluster-level storage resources
- **PersistentVolumeClaim (PVC)**: Understanding namespace-level storage requests
- **Data Recovery**: Recovering deployments while preserving data
- **Volume Binding**: How PVCs bind to PVs
- **Deployment Configuration**: Configuring volumes in Deployments
- **File Editing**: Editing YAML files and applying changes

## Prerequisites

- `kubectl` configured to access a Kubernetes cluster
- `make` installed
- Basic understanding of Kubernetes storage concepts
- Understanding of PersistentVolumes and PersistentVolumeClaims

## Quick Start

### 1. Set up the lab environment

```bash
make all
```

This will:
- Create the `mariadb` namespace
- Create a PersistentVolume (retained for reuse)
- Create the MariaDB deployment file at `~/mariadb-deploy.yaml` (without PVC reference)

### 2. Apply the solution

**Option 1: Manual solution (step by step)**
```bash
# Task 1: Create PersistentVolumeClaim
kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mariadb
  namespace: mariadb
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 250Mi
EOF

# Task 2: Edit ~/mariadb-deploy.yaml to add PVC reference
# Add to volumes section:
# volumes:
# - name: mariadb-data
#   persistentVolumeClaim:
#     claimName: mariadb

# Task 3: Apply the deployment
kubectl apply -f ~/mariadb-deploy.yaml

# Task 4: Verify deployment is running and stable
kubectl rollout status deployment/mariadb -n mariadb
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
- `make setup` - Create namespace, PV, and deployment file
- `make solution` - Complete automated solution
- `make create-pvc` - Create PersistentVolumeClaim only
- `make update-deployment` - Update deployment file to use PVC
- `make apply-deployment` - Apply the deployment file
- `make status` - Show environment summary
- `make verify` - Verify solution implementation
- `make show-pvc` - Show PVC details
- `make show-deployment-file` - Display deployment file contents
- `make clean` - Clean up resources (PV is retained)

## Detailed Solution Steps

### Understanding PersistentVolumes and PersistentVolumeClaims

**PersistentVolume (PV):**
- Cluster-level resource
- Represents actual storage in the cluster
- Created by cluster administrators
- Has a lifecycle independent of pods
- Can be statically or dynamically provisioned

**PersistentVolumeClaim (PVC):**
- Namespace-level resource
- Request for storage from a PV
- Users create PVCs to request storage
- Kubernetes binds PVCs to matching PVs
- Pods reference PVCs in their volume specifications

**Binding Process:**
1. User creates a PVC with specific requirements (size, access mode)
2. Kubernetes finds a matching PV
3. PV and PVC are bound together
4. Pods can use the PVC to access the storage

### Task 1: Create PersistentVolumeClaim

Create a PVC that will bind to the existing PersistentVolume:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mariadb
  namespace: mariadb
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 250Mi
```

**Key specifications:**
- **name**: `mariadb` (as required)
- **namespace**: `mariadb`
- **accessModes**: `ReadWriteOnce` (matches PV)
- **storage**: `250Mi` (must be ≤ PV capacity)

**Apply the PVC:**
```bash
kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mariadb
  namespace: mariadb
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 250Mi
EOF
```

**Verify PVC is bound:**
```bash
kubectl get pvc mariadb -n mariadb
```

Expected output should show `STATUS: Bound` and the `VOLUME` column should show the PV name.

### Task 2: Edit Deployment File

Edit `~/mariadb-deploy.yaml` to add the PVC reference in the volumes section:

**Original volumes section (without PVC):**
```yaml
volumes:
- name: mariadb-data
  # PVC will be added as part of the solution
  # persistentVolumeClaim:
  #   claimName: mariadb
```

**Updated volumes section (with PVC):**
```yaml
volumes:
- name: mariadb-data
  persistentVolumeClaim:
    claimName: mariadb
```

**Using a text editor:**
```bash
# Using vi/vim
vi ~/mariadb-deploy.yaml

# Using nano
nano ~/mariadb-deploy.yaml

# Using sed (automated)
sed -i 's/# persistentVolumeClaim:/persistentVolumeClaim:/' ~/mariadb-deploy.yaml
sed -i 's/#   claimName: mariadb/    claimName: mariadb/' ~/mariadb-deploy.yaml
```

**Verify the edit:**
```bash
cat ~/mariadb-deploy.yaml | grep -A 3 "volumes:"
```

### Task 3: Apply the Deployment

Apply the updated deployment file:

```bash
kubectl apply -f ~/mariadb-deploy.yaml
```

**Verify deployment is created:**
```bash
kubectl get deployment mariadb -n mariadb
```

### Task 4: Ensure Deployment is Running and Stable

**Check deployment status:**
```bash
kubectl get deployment mariadb -n mariadb
kubectl get pods -n mariadb
```

**Wait for rollout to complete:**
```bash
kubectl rollout status deployment/mariadb -n mariadb
```

**Check pod is running:**
```bash
kubectl get pods -n mariadb -l app=mariadb
```

**Verify pod is using the PVC:**
```bash
kubectl describe pod <pod-name> -n mariadb | grep -A 5 "Volumes:"
```

## Verification

### Check PersistentVolumeClaim

```bash
# View PVC
kubectl get pvc mariadb -n mariadb

# Detailed view
kubectl describe pvc mariadb -n mariadb

# Verify it's bound
kubectl get pvc mariadb -n mariadb -o jsonpath='{.status.phase}'
# Should output: Bound
```

### Check Deployment

```bash
# View deployment
kubectl get deployment mariadb -n mariadb

# Check replicas
kubectl get deployment mariadb -n mariadb -o jsonpath='{.status.readyReplicas}/{.spec.replicas}'
# Should output: 1/1

# View deployment YAML
kubectl get deployment mariadb -n mariadb -o yaml
```

### Check Pods

```bash
# List pods
kubectl get pods -n mariadb -l app=mariadb

# Check pod status
kubectl get pods -n mariadb -l app=mariadb -o jsonpath='{.items[0].status.phase}'
# Should output: Running

# Describe pod
kubectl describe pod <pod-name> -n mariadb
```

### Check Volume Mount

```bash
# Verify volume mount in pod
kubectl get pod <pod-name> -n mariadb -o jsonpath='{.spec.volumes[0].persistentVolumeClaim.claimName}'
# Should output: mariadb

# Check volume mount path
kubectl get pod <pod-name> -n mariadb -o jsonpath='{.spec.containers[0].volumeMounts[0].mountPath}'
# Should output: /var/lib/mysql
```

### Verify Data Persistence

```bash
# Connect to MariaDB pod
kubectl exec -it <pod-name> -n mariadb -- mysql -uroot -prootpassword

# In MySQL prompt, check databases
SHOW DATABASES;

# Exit
exit
```

## Verification Checklist

After completing all tasks, verify:

- [ ] PersistentVolume exists and is available
- [ ] PersistentVolumeClaim `mariadb` exists in `mariadb` namespace
- [ ] PVC access mode is `ReadWriteOnce`
- [ ] PVC storage size is `250Mi`
- [ ] PVC is bound to the PersistentVolume
- [ ] Deployment file `~/mariadb-deploy.yaml` exists
- [ ] Deployment file references PVC `mariadb`
- [ ] Deployment `mariadb` exists in `mariadb` namespace
- [ ] Deployment has 1 replica
- [ ] Deployment is running (1/1 replicas ready)
- [ ] Pod is in `Running` state
- [ ] Deployment is stable (no ongoing rollout)

## Troubleshooting

### PVC not binding to PV

**Symptom:** PVC status is `Pending`

**Possible causes:**
- Access mode mismatch
- Storage size too large
- No matching PV available
- PV is already bound

**Solution:**
```bash
# Check PVC status
kubectl describe pvc mariadb -n mariadb

# Check available PVs
kubectl get pv

# Verify PV is available
kubectl get pv mariadb-pv -o jsonpath='{.status.phase}'
# Should be: Available

# Check PV access modes and capacity
kubectl get pv mariadb-pv -o yaml | grep -A 5 "accessModes\|capacity"
```

### Deployment not starting

**Symptom:** Pod stuck in `Pending` or `ContainerCreating`

**Possible causes:**
- PVC not bound
- Image pull issues
- Resource constraints

**Solution:**
```bash
# Check pod events
kubectl describe pod <pod-name> -n mariadb

# Check PVC binding
kubectl get pvc mariadb -n mariadb

# Check deployment
kubectl describe deployment mariadb -n mariadb
```

### Deployment file not found

**Symptom:** `~/mariadb-deploy.yaml` doesn't exist

**Solution:**
```bash
# Check if file exists
ls -la ~/mariadb-deploy.yaml

# Recreate using make
make setup

# Or create manually from solution.yaml template
```

### Deployment file doesn't reference PVC

**Symptom:** Deployment created but pod has no volume

**Solution:**
```bash
# Check deployment file
cat ~/mariadb-deploy.yaml | grep -A 5 "volumes:"

# Edit file to add PVC reference
vi ~/mariadb-deploy.yaml

# Reapply
kubectl apply -f ~/mariadb-deploy.yaml
```

### Deployment not stable

**Symptom:** Deployment keeps restarting or rolling out

**Solution:**
```bash
# Check deployment status
kubectl rollout status deployment/mariadb -n mariadb

# Check pod logs
kubectl logs <pod-name> -n mariadb

# Check pod events
kubectl describe pod <pod-name> -n mariadb

# Check replica set
kubectl get rs -n mariadb
```

## Common kubectl Commands

### PersistentVolume

```bash
# List PVs
kubectl get pv

# Describe PV
kubectl describe pv mariadb-pv

# View PV YAML
kubectl get pv mariadb-pv -o yaml
```

### PersistentVolumeClaim

```bash
# List PVCs
kubectl get pvc -n mariadb

# Create PVC
kubectl apply -f pvc.yaml

# Describe PVC
kubectl describe pvc mariadb -n mariadb

# Delete PVC
kubectl delete pvc mariadb -n mariadb
```

### Deployment

```bash
# Apply deployment
kubectl apply -f ~/mariadb-deploy.yaml

# Get deployment
kubectl get deployment mariadb -n mariadb

# Describe deployment
kubectl describe deployment mariadb -n mariadb

# Rollout status
kubectl rollout status deployment/mariadb -n mariadb

# View deployment YAML
kubectl get deployment mariadb -n mariadb -o yaml
```

## Files

- `q12.yaml` - Base setup (namespace and PersistentVolume)
- `solution.yaml` - Solution reference with PVC and complete deployment
- `Makefile` - Automation for lab setup and solution
- `README.md` - This documentation
- `~/mariadb-deploy.yaml` - MariaDB deployment file (created during setup)

## Notes

- **PersistentVolume**: Already exists and is retained (not deleted during cleanup)
- **PVC name**: Must be exactly `mariadb`
- **Namespace**: All resources in `mariadb` namespace
- **Access mode**: Must be `ReadWriteOnce` (matches PV)
- **Storage size**: Must be `250Mi` (≤ PV capacity of 500Mi)
- **Deployment file**: Must be at `~/mariadb-deploy.yaml`
- **Data preservation**: Reusing the PV ensures data is preserved
- **Stable deployment**: Deployment should have 1/1 replicas ready and no ongoing rollouts

## Expected Outcomes

After successful completion:

✅ PersistentVolume exists and is available  
✅ PersistentVolumeClaim `mariadb` created  
✅ PVC access mode is `ReadWriteOnce`  
✅ PVC storage size is `250Mi`  
✅ PVC is bound to the PersistentVolume  
✅ Deployment file `~/mariadb-deploy.yaml` exists  
✅ Deployment file references PVC `mariadb`  
✅ Deployment `mariadb` applied successfully  
✅ Deployment is running (1/1 replicas ready)  
✅ Pod is in `Running` state  
✅ Deployment is stable  
✅ Data is preserved (reusing existing PV)  

## Additional Resources

- [Kubernetes PersistentVolumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)
- [PersistentVolumeClaims](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistentvolumeclaims)
- [Volumes in Pods](https://kubernetes.io/docs/concepts/storage/volumes/)
- [Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)

