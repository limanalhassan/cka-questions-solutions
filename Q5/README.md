# Q5: PriorityClass and Pod Eviction Lab

This lab demonstrates creating a PriorityClass and using it to control pod scheduling and eviction behavior in Kubernetes.

## Overview

Complete the following tasks:
1. **Create a PriorityClass** named `high-priority` for user-workloads
   - Value must be **one less than the highest existing user-defined priority class value**
2. **Patch the `busybox-logger` deployment** in the `priority` namespace to use the new PriorityClass
3. **Ensure successful rollout** of the deployment
4. **Verify pod eviction** - Lower priority pods should be evicted to make room for high-priority pods

## What is PriorityClass?

PriorityClass is a Kubernetes resource that defines the relative priority of pods:
- **Higher priority pods** are scheduled first and can evict lower priority pods
- **Priority values** range from -2147483648 to 1000000000 (higher = more important)
- **System PriorityClasses** (prefixed with `system-`) are reserved for system components
- **User-defined PriorityClasses** are for application workloads

### How Pod Eviction Works

When a node runs out of resources (CPU, memory):
1. Kubernetes identifies pods that can be evicted
2. Lower priority pods are evicted first
3. Higher priority pods are protected from eviction
4. Evicted pods are rescheduled if resources become available

## Prerequisites

- `kubectl` configured to access a Kubernetes cluster
- `make` installed
- Cluster with sufficient resources to demonstrate eviction (or resource constraints configured)

## Quick Start

### 1. Set up the lab environment

```bash
make all
```

This will:
- Create the `priority` namespace
- Create example PriorityClasses (low-priority, medium-priority, default-priority)
- Deploy `busybox-logger` deployment (without priority class)
- Deploy other deployments with lower priority classes
- Wait for all deployments to be ready

### 2. Find the highest PriorityClass value

```bash
kubectl get priorityclass -o custom-columns=NAME:.metadata.name,VALUE:.value,DESCRIPTION:.description
```

Look for the highest **user-defined** PriorityClass value (exclude system-* classes).

### 3. Create the high-priority PriorityClass

The value must be **one less than the highest existing user-defined priority class**.

For example, if the highest is `1000`, create with value `999`:

```yaml
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: high-priority
value: 999
description: "High priority class for user-workloads"
globalDefault: false
```

### 4. Patch the busybox-logger deployment

```bash
kubectl patch deployment busybox-logger -n priority \
  -p '{"spec":{"template":{"spec":{"priorityClassName":"high-priority"}}}}'
```

### 5. Verify the solution

```bash
make verify
```

Or check manually:
```bash
kubectl get priorityclass high-priority
kubectl -n priority get deployment busybox-logger -o jsonpath='{.spec.template.spec.priorityClassName}'
kubectl -n priority get pods -o custom-columns=NAME:.metadata.name,PRIORITY:.spec.priorityClassName,STATUS:.status.phase
```

## Available Make Targets

- `make all` - Full lab setup (clean, setup, deploy)
- `make setup` - Create namespace, PriorityClasses, and deployments
- `make deploy` - Wait for deployments to be ready
- `make solution` - Apply PriorityClass solution (automated)
- `make status` - Show environment summary
- `make verify` - Verify solution implementation
- `make clean` - Clean up all resources

## Detailed Steps

### Step 1: Examine Existing PriorityClasses

```bash
kubectl get priorityclass
```

**Expected output:**
```
NAME                VALUE        GLOBAL-DEFAULT   AGE
default-priority    1000         false            1m
low-priority        100          false            1m
medium-priority     500          false            1m
```

**Note:** System PriorityClasses (like `system-cluster-critical`) may also exist but should be ignored.

### Step 2: Determine the Highest Value

From the example above:
- `default-priority`: 1000 (highest user-defined)
- `medium-priority`: 500
- `low-priority`: 100

**Highest user-defined value: 1000**  
**New PriorityClass value: 1000 - 1 = 999**

### Step 3: Create the high-priority PriorityClass

```bash
kubectl apply -f - <<EOF
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: high-priority
value: 999
description: "High priority class for user-workloads"
globalDefault: false
EOF
```

**Key fields:**
- `value`: 999 (one less than highest existing)
- `description`: Describes the purpose
- `globalDefault`: false (not the default for all pods)

### Step 4: Patch the Deployment

```bash
kubectl patch deployment busybox-logger -n priority \
  -p '{"spec":{"template":{"spec":{"priorityClassName":"high-priority"}}}}'
```

This updates the pod template to use the new PriorityClass.

### Step 5: Verify Rollout

```bash
kubectl -n priority rollout status deploy/busybox-logger
```

Wait for the deployment to successfully roll out with the new priority.

### Step 6: Observe Pod Eviction (if resources are constrained)

If the cluster has resource constraints, lower priority pods may be evicted:

```bash
kubectl -n priority get pods -w
```

Watch for:
- `busybox-logger` pods starting with `high-priority`
- Lower priority pods being evicted or terminated

## Understanding PriorityClass Values

### Value Ranges

- **System PriorityClasses**: Typically 2000000000 and above
- **User-defined PriorityClasses**: Typically 1 to 1000000000
- **Default priority**: 0 (if no PriorityClass specified)

### Best Practices

1. **Use meaningful values**: Leave gaps between priority levels (e.g., 100, 500, 1000)
2. **Document purpose**: Always include a description
3. **Avoid globalDefault**: Only set `globalDefault: true` for one PriorityClass
4. **Plan for eviction**: Higher priority pods can evict lower priority ones

## Verification Checklist

After completing the lab, verify:

- [ ] `high-priority` PriorityClass exists
- [ ] PriorityClass value is correct (one less than highest existing)
- [ ] `busybox-logger` deployment uses `high-priority`
- [ ] Deployment successfully rolled out
- [ ] Pods are running with the new priority
- [ ] Lower priority pods may be evicted (if resources constrained)

## Testing Pod Eviction

To observe pod eviction in action, you can:

1. **Constrain node resources** (if using kind/minikube):
   ```bash
   # This requires cluster configuration
   ```

2. **Check pod status**:
   ```bash
   kubectl -n priority get pods -o wide
   kubectl -n priority describe pods
   ```

3. **Watch for eviction events**:
   ```bash
   kubectl -n priority get events --sort-by=.metadata.creationTimestamp
   ```

## Troubleshooting

### PriorityClass not found

**Symptom:** Error when patching deployment: `PriorityClass "high-priority" not found`

**Solution:**
1. Verify PriorityClass exists: `kubectl get priorityclass high-priority`
2. Check spelling: Ensure exact match `high-priority`
3. Create the PriorityClass first before patching

### Deployment not rolling out

**Symptom:** Deployment stuck in rollout or pods not starting

**Solution:**
1. Check deployment status: `kubectl -n priority describe deployment busybox-logger`
2. Check pod events: `kubectl -n priority get events`
3. Verify PriorityClass value is valid (not too high)
4. Check resource constraints: `kubectl describe nodes`

### Incorrect PriorityClass value

**Symptom:** Value is not one less than highest existing

**Solution:**
1. Find highest value: `kubectl get priorityclass -o jsonpath='{range .items[*]}{.value}{"\n"}{end}' | sort -n | tail -1`
2. Calculate: `highest - 1`
3. Delete and recreate PriorityClass with correct value

### Pods not being evicted

**Symptom:** Lower priority pods remain running

**Possible reasons:**
- Cluster has sufficient resources (no eviction needed)
- Pods have resource limits that prevent eviction
- Node has enough capacity for all pods

**Note:** Eviction only occurs when nodes are resource-constrained. In a well-resourced cluster, all pods may run simultaneously.

## Files

- `q5.yaml` - Base setup (namespace, PriorityClasses, deployments)
- `solution.yaml` - PriorityClass solution (reference)
- `Makefile` - Automation for lab setup and verification

## Notes

- PriorityClass values must be unique
- Once a PriorityClass is created, its value cannot be changed
- Pod priority is set at creation time and cannot be changed
- System PriorityClasses (system-*) should be ignored when finding highest value
- Pod eviction depends on resource availability - may not occur in well-resourced clusters
- The `busybox-logger` deployment should have 3 replicas after successful rollout

## Expected Outcomes

After successful completion:

✅ `high-priority` PriorityClass created with correct value  
✅ `busybox-logger` deployment uses `high-priority` PriorityClass  
✅ Deployment successfully rolled out  
✅ All `busybox-logger` pods are running  
✅ Pod priority is correctly set  
✅ Lower priority pods may be evicted (if resources constrained)  

## Additional Resources

- [Kubernetes PriorityClass Documentation](https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/)
- [Pod Priority and Preemption](https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/)

