# Q10: WordPress Resource Requests Adjustment Lab

This lab demonstrates how to adjust resource requests for a WordPress application to evenly distribute node resources across pods while maintaining node stability.

## Overview

**Task:** Adjust resource requests for a WordPress application.

**Requirements:**
- **Application:** WordPress
- **Replicas:** 3
- **Namespace:** `relative-fawn`
- **Node Resources:** CPU: 1 (1000m), Memory: 2015360ki (~1.92 GiB)
- **Distribution:** Divide resources evenly across all 3 pods
- **Overhead:** Add enough overhead to keep the node stable
- **Consistency:** Use the same resource requests for main containers and init containers
- **Scope:** Only adjust `requests`, not `limits`

**Helper Tip:** Temporarily scale the deployment to 0 replicas while updating resource requests.

## What You'll Learn

- **Resource Requests**: Understanding CPU and memory requests in Kubernetes
- **Resource Calculation**: Calculating per-pod resources with overhead considerations
- **Init Containers**: Applying resource requests to init containers
- **Deployment Updates**: Updating resource specifications in running deployments
- **Scaling Strategy**: Using scaling to facilitate resource updates

## Prerequisites

- `kubectl` configured to access a Kubernetes cluster
- `make` installed
- Basic understanding of Kubernetes resource management
- Understanding of CPU and memory units (m, Mi, ki)

## Quick Start

### 1. Set up the lab environment

```bash
make all
```

This will:
- Create the `relative-fawn` namespace
- Create the WordPress deployment with 3 replicas
- Deploy init containers and main container (without resource requests initially)

### 2. Apply the solution

**Option 1: Manual solution (step by step)**
```bash
# Step 1: Scale to 0 replicas (helper tip)
kubectl scale deployment wordpress -n relative-fawn --replicas=0

# Step 2: Add resource requests
kubectl patch deployment wordpress -n relative-fawn --type='json' \
  -p='[
    {"op": "add", "path": "/spec/template/spec/initContainers/0/resources", "value": {"requests": {"cpu": "300m", "memory": "589Mi"}}},
    {"op": "add", "path": "/spec/template/spec/initContainers/1/resources", "value": {"requests": {"cpu": "300m", "memory": "589Mi"}}},
    {"op": "add", "path": "/spec/template/spec/containers/0/resources/requests", "value": {"cpu": "300m", "memory": "589Mi"}}
  ]'

# Step 3: Scale back to 3 replicas
kubectl scale deployment wordpress -n relative-fawn --replicas=3
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
- `make setup` - Create namespace and deployment
- `make solution` - Complete automated solution
- `make scale-down` - Scale deployment to 0 replicas
- `make add-requests` - Add resource requests to all containers
- `make scale-up` - Scale deployment to 3 replicas
- `make status` - Show environment summary
- `make verify` - Verify solution implementation
- `make show-resources` - Show resource requests from deployment spec
- `make pod-resources` - Show resource requests from running pods
- `make clean` - Clean up all resources

## Resource Calculation

### Node Resources
- **CPU:** 1 core = 1000m (millicores)
- **Memory:** 2015360ki (kibibytes) ≈ 1968 MiB

### Overhead Calculation
To keep the node stable, we need to reserve resources for:
- System processes (kubelet, kube-proxy, etc.)
- OS overhead
- Buffer for unexpected usage

**Assumed Overhead:**
- **CPU:** 100m (10% of total)
- **Memory:** 200 MiB (~10% of total)

### Available Resources for Pods
- **CPU:** 1000m - 100m = **900m**
- **Memory:** 1968 MiB - 200 MiB = **1768 MiB**

### Per-Pod Resources (3 replicas)
- **CPU:** 900m ÷ 3 = **300m per pod**
- **Memory:** 1768 MiB ÷ 3 ≈ **589 MiB per pod** (or 603136ki)

### Final Resource Requests
All containers (init containers and main container) should have:
```yaml
resources:
  requests:
    cpu: "300m"
    memory: "589Mi"
```

## Detailed Solution Steps

### Step 1: Scale Deployment to 0 Replicas

Scaling down first makes it easier to update the deployment without affecting running pods:

```bash
kubectl scale deployment wordpress -n relative-fawn --replicas=0
```

**Why scale down?**
- Prevents scheduling issues during update
- Allows clean rollout with new resource requests
- Reduces resource contention during update

### Step 2: Add Resource Requests

Add resource requests to all containers using `kubectl patch`:

```bash
kubectl patch deployment wordpress -n relative-fawn --type='json' \
  -p='[
    {"op": "add", "path": "/spec/template/spec/initContainers/0/resources", "value": {"requests": {"cpu": "300m", "memory": "589Mi"}}},
    {"op": "add", "path": "/spec/template/spec/initContainers/1/resources", "value": {"requests": {"cpu": "300m", "memory": "589Mi"}}},
    {"op": "add", "path": "/spec/template/spec/containers/0/resources/requests", "value": {"cpu": "300m", "memory": "589Mi"}}
  ]'
```

**What this does:**
- Adds `resources.requests` to first init container (`init-db`)
- Adds `resources.requests` to second init container (`init-config`)
- Adds `resources.requests` to main container (`wordpress`)
- All use the same values: 300m CPU, 589Mi memory

**Alternative: Using kubectl edit**
```bash
kubectl edit deployment wordpress -n relative-fawn
# Manually add resources.requests to each container
```

### Step 3: Scale Back to 3 Replicas

```bash
kubectl scale deployment wordpress -n relative-fawn --replicas=3
```

### Step 4: Verify

```bash
# Check deployment
kubectl get deployment wordpress -n relative-fawn

# Check pods
kubectl get pods -n relative-fawn -l app=wordpress

# Check resource requests
kubectl describe pod <pod-name> -n relative-fawn | grep -A 5 "Requests:"
```

## Understanding Resource Requests

### Resource Requests vs Limits

**Requests:**
- Minimum resources guaranteed to the container
- Used by scheduler to place pods on nodes
- Used for resource allocation
- **This lab only adjusts requests**

**Limits:**
- Maximum resources a container can use
- Enforced by cgroups
- Container will be throttled/killed if exceeded
- **Not modified in this lab**

### CPU Units

- **1 core** = 1000m (millicores)
- **100m** = 0.1 core = 10% of a CPU
- **300m** = 0.3 core = 30% of a CPU

### Memory Units

- **1 MiB** (mebibyte) = 1024 × 1024 bytes = 1048576 bytes
- **1 ki** (kibibyte) = 1024 bytes
- **2015360ki** = 2015360 × 1024 bytes ≈ 1968 MiB
- **589 MiB** ≈ 603136ki

### Why Same Requests for All Containers?

- **Consistency:** Ensures predictable resource allocation
- **Simplicity:** Easier to calculate and verify
- **Fairness:** All containers get equal share
- **Requirements:** Task explicitly requires same requests for init and main containers

## Verification

### Check Deployment Configuration

```bash
# View deployment YAML
kubectl get deployment wordpress -n relative-fawn -o yaml

# Check resource requests
kubectl get deployment wordpress -n relative-fawn -o jsonpath='{.spec.template.spec.initContainers[*].resources.requests}'
kubectl get deployment wordpress -n relative-fawn -o jsonpath='{.spec.template.spec.containers[0].resources.requests}'
```

### Check Pod Status

```bash
# List pods
kubectl get pods -n relative-fawn -l app=wordpress

# Check pod resources
kubectl describe pod <pod-name> -n relative-fawn

# View resource requests in pod spec
kubectl get pod <pod-name> -n relative-fawn -o jsonpath='{.spec.initContainers[*].resources.requests}'
kubectl get pod <pod-name> -n relative-fawn -o jsonpath='{.spec.containers[0].resources.requests}'
```

### Verify All Requirements

- [ ] Deployment has 3 replicas
- [ ] All pods are running and ready
- [ ] Init container 1 has requests: CPU=300m, Memory=589Mi
- [ ] Init container 2 has requests: CPU=300m, Memory=589Mi
- [ ] Main container has requests: CPU=300m, Memory=589Mi
- [ ] All containers have the same resource requests
- [ ] Resource limits are unchanged (if they existed)

## Verification Checklist

After applying the solution, verify:

- [ ] Deployment `wordpress` has 3 replicas
- [ ] All 3 pods are running and ready
- [ ] Init container `init-db` has resource requests set
- [ ] Init container `init-config` has resource requests set
- [ ] Main container `wordpress` has resource requests set
- [ ] All containers have CPU request: 300m
- [ ] All containers have memory request: 589Mi
- [ ] Resource requests are consistent across all containers
- [ ] Resource limits are not modified (if they existed)

## Troubleshooting

### Pods not starting

**Symptom:** Pods stuck in `Pending` state

**Possible causes:**
- Insufficient node resources
- Resource requests too high
- Node doesn't have enough capacity

**Solution:**
```bash
# Check pod events
kubectl describe pod <pod-name> -n relative-fawn

# Check node resources
kubectl describe node <node-name>

# Verify resource requests are correct
kubectl get deployment wordpress -n relative-fawn -o yaml | grep -A 5 resources
```

### Resource requests not applied

**Symptom:** Pods don't have resource requests

**Solution:**
```bash
# Check deployment spec
kubectl get deployment wordpress -n relative-fawn -o yaml | grep -A 10 resources

# Re-apply patch
kubectl patch deployment wordpress -n relative-fawn --type='json' \
  -p='[{"op": "add", "path": "/spec/template/spec/initContainers/0/resources", "value": {"requests": {"cpu": "300m", "memory": "589Mi"}}}]'

# Restart rollout
kubectl rollout restart deployment wordpress -n relative-fawn
```

### Inconsistent resource requests

**Symptom:** Different containers have different requests

**Solution:**
```bash
# Check all containers
kubectl get deployment wordpress -n relative-fawn -o jsonpath='{.spec.template.spec.initContainers[*].resources.requests}'
kubectl get deployment wordpress -n relative-fawn -o jsonpath='{.spec.template.spec.containers[0].resources.requests}'

# Re-apply patch with all containers
# (use the complete patch command from solution)
```

### Deployment not updating

**Symptom:** Changes not reflected in pods

**Solution:**
```bash
# Check rollout status
kubectl rollout status deployment/wordpress -n relative-fawn

# Force rollout restart
kubectl rollout restart deployment wordpress -n relative-fawn

# Check pod template hash
kubectl get pods -n relative-fawn -l app=wordpress --show-labels
```

### Wrong resource values

**Symptom:** Resource requests don't match calculated values

**Solution:**
- Verify calculation: (Node resources - Overhead) ÷ Replicas
- Check units: CPU in millicores (m), Memory in MiB
- Re-apply patch with correct values

## Common kubectl Commands

### View Resources

```bash
# Deployment spec
kubectl get deployment wordpress -n relative-fawn -o yaml

# Pod spec
kubectl get pod <pod-name> -n relative-fawn -o yaml

# Resource requests only
kubectl get deployment wordpress -n relative-fawn -o jsonpath='{.spec.template.spec.containers[0].resources.requests}'
```

### Patch Resources

```bash
# Add requests to container
kubectl patch deployment wordpress -n relative-fawn --type='json' \
  -p='[{"op": "add", "path": "/spec/template/spec/containers/0/resources/requests", "value": {"cpu": "300m", "memory": "589Mi"}}]'

# Replace requests
kubectl patch deployment wordpress -n relative-fawn --type='json' \
  -p='[{"op": "replace", "path": "/spec/template/spec/containers/0/resources/requests/cpu", "value": "300m"}]'
```

### Scale Deployment

```bash
# Scale to specific replicas
kubectl scale deployment wordpress -n relative-fawn --replicas=3

# Scale to 0
kubectl scale deployment wordpress -n relative-fawn --replicas=0
```

## Files

- `q10.yaml` - Base setup (deployment without resource requests)
- `solution.yaml` - Solution reference with complete deployment YAML
- `Makefile` - Automation for lab setup and solution
- `README.md` - This documentation

## Notes

- **Namespace:** All resources in `relative-fawn` namespace
- **Replicas:** Must maintain 3 replicas
- **Resource requests:** Only adjust `requests`, not `limits`
- **Consistency:** All containers (init and main) must have same requests
- **Overhead:** Reserve resources for node stability (100m CPU, 200Mi memory)
- **Scaling:** Helper tip suggests scaling to 0 during update
- **Calculation:** (Node resources - Overhead) ÷ Replicas = Per-pod resources

## Expected Outcomes

After successful solution:

✅ Deployment has 3 replicas  
✅ All pods are running and ready  
✅ Init container 1 has requests: CPU=300m, Memory=589Mi  
✅ Init container 2 has requests: CPU=300m, Memory=589Mi  
✅ Main container has requests: CPU=300m, Memory=589Mi  
✅ All containers have consistent resource requests  
✅ Resource limits unchanged (if they existed)  
✅ Total pod requests: 900m CPU, 1768 MiB memory (leaving 100m CPU, 200Mi for overhead)  

## Additional Resources

- [Kubernetes Resource Management](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/)
- [Resource Requests and Limits](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/#resource-requests-and-limits-of-pod-and-container)
- [Init Containers](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/)
- [kubectl patch Documentation](https://kubernetes.io/docs/tasks/manage-kubernetes-objects/update-api-object-kubectl-patch/)

