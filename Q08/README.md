# Q8: Sidecar Container for Logging Lab

This lab demonstrates how to integrate a legacy application's logging into Kubernetes' built-in logging system by adding a sidecar container to an existing Deployment.

## Overview

**Problem:** A legacy application writes logs to a file (`/var/log/synergy-deployment.log`) instead of stdout/stderr, making them inaccessible via `kubectl logs`.

**Solution:** Add a sidecar container that streams the log file, making it accessible through Kubernetes' standard logging interface.

**Tasks:**
1. Update the existing Deployment `synergy-deployment` in namespace `synergy`
2. Add a co-located container (sidecar) named `sidecar`
3. Use `busybox:stable` image for the sidecar
4. Execute command: `/bin/sh -c "tail -n+l -f /var/log/synergy-deployment.log"`
5. Use a shared volume mounted at `/var/log` in both containers
6. Do not modify the existing container specification except for adding the volume mount

## What You'll Learn

- **Sidecar Pattern**: Using co-located containers for cross-cutting concerns
- **Shared Volumes**: Using `emptyDir` volumes to share data between containers
- **Logging Integration**: Making file-based logs accessible via `kubectl logs`
- **kubectl patch**: Modifying Deployments with JSON patch operations
- **Multi-container Pods**: Understanding how containers in the same pod share resources

## Prerequisites

- `kubectl` configured to access a Kubernetes cluster
- `make` installed
- Basic understanding of Kubernetes Deployments, Pods, and Volumes

## Quick Start

### 1. Set up the lab environment

```bash
make all
```

This will:
- Create the `synergy` namespace
- Create the `synergy-deployment` with a legacy app that writes logs to a file

### 2. Apply the solution

**Option 1: Manual solution (step by step)**
```bash
# Patch the deployment to add volume, volume mount, and sidecar
kubectl patch deployment synergy-deployment -n synergy --type='json' \
  -p='[
    {"op": "add", "path": "/spec/template/spec/volumes", "value": [{"name": "log-volume", "emptyDir": {}}]},
    {"op": "add", "path": "/spec/template/spec/containers/0/volumeMounts", "value": [{"name": "log-volume", "mountPath": "/var/log"}]},
    {"op": "add", "path": "/spec/template/spec/containers/-", "value": {
      "name": "sidecar",
      "image": "busybox:stable",
      "command": ["/bin/sh", "-c"],
      "args": ["tail -n+l -f /var/log/synergy-deployment.log"],
      "volumeMounts": [{"name": "log-volume", "mountPath": "/var/log"}]
    }}
  ]'
```

**Option 2: Automated solution**
```bash
make solution
```

### 3. Verify and test

```bash
make verify
make test
```

## Available Make Targets

- `make all` - Full lab setup (clean, setup)
- `make setup` - Create namespace and deployment
- `make solution` - Complete automated solution
- `make add-volume` - Add shared volume to deployment
- `make mount-volume-app` - Mount volume in app container
- `make add-sidecar` - Add sidecar container
- `make status` - Show environment summary
- `make verify` - Verify solution implementation
- `make logs` - View logs from sidecar container
- `make test` - Test sidecar logging functionality
- `make clean` - Clean up all resources

## Detailed Solution Steps

### Understanding the Sidecar Pattern

**What is a Sidecar?**
- A sidecar is a co-located container that runs alongside the main application container in the same pod
- Shares the same network namespace, storage, and lifecycle
- Used for cross-cutting concerns like logging, monitoring, proxying

**Why Use a Sidecar for Logging?**
- Legacy applications may write logs to files instead of stdout/stderr
- Kubernetes' `kubectl logs` only works with stdout/stderr
- Sidecar can stream file logs to stdout, making them accessible via `kubectl logs`

### Step 1: Add Shared Volume

Create an `emptyDir` volume that will be shared between containers:

```yaml
volumes:
- name: log-volume
  emptyDir: {}
```

**emptyDir Volume:**
- Created when a pod is assigned to a node
- Exists as long as the pod is running
- Shared between all containers in the pod
- Data is lost when the pod is removed

### Step 2: Mount Volume in App Container

Mount the volume in the existing application container:

```yaml
volumeMounts:
- name: log-volume
  mountPath: /var/log
```

This allows the app to write logs to `/var/log/synergy-deployment.log`, which will be stored in the shared volume.

### Step 3: Add Sidecar Container

Add the sidecar container that streams the log file:

```yaml
containers:
- name: sidecar
  image: busybox:stable
  command: ["/bin/sh", "-c"]
  args: ["tail -n+l -f /var/log/synergy-deployment.log"]
  volumeMounts:
  - name: log-volume
    mountPath: /var/log
```

**Sidecar Configuration:**
- **Name**: `sidecar` (as required)
- **Image**: `busybox:stable`
- **Command**: `tail -n+l -f /var/log/synergy-deployment.log`
  - `tail -n+l`: Start from line 1 (or use `-n+1`)
  - `-f`: Follow the file (stream continuously)
- **Volume Mount**: Same volume mounted at `/var/log`

### Complete Solution Using kubectl patch

```bash
kubectl patch deployment synergy-deployment -n synergy --type='json' \
  -p='[
    {"op": "add", "path": "/spec/template/spec/volumes", "value": [{"name": "log-volume", "emptyDir": {}}]},
    {"op": "add", "path": "/spec/template/spec/containers/0/volumeMounts", "value": [{"name": "log-volume", "mountPath": "/var/log"}]},
    {"op": "add", "path": "/spec/template/spec/containers/-", "value": {
      "name": "sidecar",
      "image": "busybox:stable",
      "command": ["/bin/sh", "-c"],
      "args": ["tail -n+l -f /var/log/synergy-deployment.log"],
      "volumeMounts": [{"name": "log-volume", "mountPath": "/var/log"}]
    }}
  ]'
```

**Breaking down the patch:**
1. **Add volumes**: Creates the `log-volume` emptyDir volume
2. **Add volumeMounts to container 0**: Mounts the volume in the app container
3. **Add container**: Appends the sidecar container to the containers array

### Alternative: Using kubectl edit

```bash
kubectl edit deployment synergy-deployment -n synergy
```

Then manually add:
- `volumes` section under `spec.template.spec`
- `volumeMounts` to the existing container
- Sidecar container to the `containers` array

## Verification

### Check Deployment Configuration

```bash
# View deployment YAML
kubectl get deployment synergy-deployment -n synergy -o yaml

# Check for volume
kubectl get deployment synergy-deployment -n synergy -o jsonpath='{.spec.template.spec.volumes}'

# Check containers
kubectl get deployment synergy-deployment -n synergy -o jsonpath='{.spec.template.spec.containers[*].name}'
```

### Check Pod Configuration

```bash
# List pods
kubectl get pods -n synergy

# View pod details
kubectl get pod <pod-name> -n synergy -o yaml

# Check containers in pod
kubectl get pod <pod-name> -n synergy -o jsonpath='{.spec.containers[*].name}'
```

### Test Logging

```bash
# View logs from sidecar container
kubectl logs <pod-name> -n synergy -c sidecar

# Follow logs
kubectl logs <pod-name> -n synergy -c sidecar -f

# View logs from app container
kubectl logs <pod-name> -n synergy -c app
```

## Verification Checklist

After applying the solution, verify:

- [ ] Shared volume `log-volume` (emptyDir) exists in deployment
- [ ] App container has volume mounted at `/var/log`
- [ ] Sidecar container `sidecar` exists
- [ ] Sidecar uses image `busybox:stable`
- [ ] Sidecar command is `/bin/sh -c "tail -n+l -f /var/log/synergy-deployment.log"`
- [ ] Sidecar has volume mounted at `/var/log`
- [ ] Pods have both containers running
- [ ] Logs are accessible via `kubectl logs <pod> -c sidecar`
- [ ] Existing container specification unchanged (except volume mount)

## Troubleshooting

### Sidecar container not appearing

**Symptom:** Pod only has one container

**Solution:**
```bash
# Check deployment spec
kubectl get deployment synergy-deployment -n synergy -o yaml | grep -A 20 containers

# Verify patch was applied
kubectl get deployment synergy-deployment -n synergy -o jsonpath='{.spec.template.spec.containers[*].name}'
```

### Volume not shared

**Symptom:** Sidecar can't read log file

**Possible causes:**
- Volume not created
- Volume not mounted in both containers
- Mount paths don't match

**Solution:**
```bash
# Check volumes
kubectl get deployment synergy-deployment -n synergy -o jsonpath='{.spec.template.spec.volumes}'

# Check volume mounts in app container
kubectl get deployment synergy-deployment -n synergy -o jsonpath='{.spec.template.spec.containers[0].volumeMounts}'

# Check volume mounts in sidecar
kubectl get deployment synergy-deployment -n synergy -o jsonpath='{.spec.template.spec.containers[?(@.name=="sidecar")].volumeMounts}'
```

### Sidecar logs empty

**Symptom:** `kubectl logs` shows no output

**Possible causes:**
- Log file doesn't exist yet
- Wrong file path
- App not writing logs

**Solution:**
```bash
# Check if log file exists in app container
kubectl exec <pod-name> -n synergy -c app -- ls -la /var/log/

# Check if log file exists in sidecar
kubectl exec <pod-name> -n synergy -c sidecar -- ls -la /var/log/

# Check app container logs
kubectl logs <pod-name> -n synergy -c app

# Wait a bit and check again (app writes logs every 5 seconds)
sleep 10
kubectl logs <pod-name> -n synergy -c sidecar
```

### Wrong sidecar command

**Symptom:** Sidecar exits or doesn't stream logs

**Solution:**
- Verify command: `tail -n+l -f /var/log/synergy-deployment.log`
- Note: `-n+l` means start from line 1 (alternative: `-n+1`)
- The `-f` flag is essential for following the file

### Deployment not updating

**Symptom:** Changes not reflected in pods

**Solution:**
```bash
# Check rollout status
kubectl rollout status deployment/synergy-deployment -n synergy

# Check pod status
kubectl get pods -n synergy

# Force rollout restart if needed
kubectl rollout restart deployment/synergy-deployment -n synergy
```

## Understanding the Components

### emptyDir Volume

**Characteristics:**
- Created when pod is assigned to a node
- Initially empty
- Shared between all containers in the pod
- Persists for pod lifetime
- Data lost when pod is removed
- Can optionally use memory (tmpfs) for better performance

**When to use:**
- Sharing data between containers in the same pod
- Temporary storage
- Cache or scratch space

### Sidecar Container

**Benefits:**
- Extends functionality without modifying main application
- Shares network and storage with main container
- Same lifecycle (starts/stops with pod)
- Can be used for logging, monitoring, proxying, etc.

**Considerations:**
- Shares pod resources (CPU, memory)
- All containers must be ready for pod to be ready
- If sidecar fails, pod may be marked unhealthy

### Multi-container Pods

**Shared Resources:**
- Network namespace (same IP, can use localhost)
- Storage volumes
- IPC namespace
- Lifecycle (all containers start/stop together)

**Isolated Resources:**
- Process namespace (different PIDs)
- File system (unless shared via volumes)
- Environment variables
- Resource limits (per container)

## Common kubectl Commands

### View Pod Containers

```bash
# List containers in a pod
kubectl get pod <pod-name> -n <namespace> -o jsonpath='{.spec.containers[*].name}'

# Get container status
kubectl get pod <pod-name> -n <namespace> -o jsonpath='{.status.containerStatuses[*].name}'
```

### View Logs

```bash
# All containers
kubectl logs <pod-name> -n <namespace>

# Specific container
kubectl logs <pod-name> -n <namespace> -c <container-name>

# Follow logs
kubectl logs <pod-name> -n <namespace> -c <container-name> -f

# Previous container instance (if crashed)
kubectl logs <pod-name> -n <namespace> -c <container-name> --previous
```

### Execute Commands

```bash
# In specific container
kubectl exec <pod-name> -n <namespace> -c <container-name> -- <command>

# Interactive shell
kubectl exec -it <pod-name> -n <namespace> -c <container-name> -- /bin/sh
```

## Files

- `q8.yaml` - Base setup (deployment without sidecar)
- `solution.yaml` - Solution reference with complete deployment YAML
- `Makefile` - Automation for lab setup and solution
- `README.md` - This documentation

## Notes

- **Container name**: Must be exactly `sidecar`
- **Image**: Must be `busybox:stable`
- **Command**: Must be `/bin/sh -c "tail -n+l -f /var/log/synergy-deployment.log"`
- **Volume mount**: Both containers must mount at `/var/log`
- **Volume type**: Use `emptyDir` for shared storage
- **Don't modify app container**: Only add volume mount, don't change image, command, or resources
- **Namespace**: All resources in `synergy` namespace

## Expected Outcomes

After successful solution:

✅ Shared `emptyDir` volume `log-volume` created  
✅ App container has volume mounted at `/var/log`  
✅ Sidecar container `sidecar` added  
✅ Sidecar uses `busybox:stable` image  
✅ Sidecar runs `tail -n+l -f /var/log/synergy-deployment.log`  
✅ Sidecar has volume mounted at `/var/log`  
✅ Pods have both containers running  
✅ Logs accessible via `kubectl logs <pod> -c sidecar`  
✅ App container specification unchanged (except volume mount)  

## Additional Resources

- [Kubernetes Volumes Documentation](https://kubernetes.io/docs/concepts/storage/volumes/)
- [emptyDir Volume](https://kubernetes.io/docs/concepts/storage/volumes/#emptydir)
- [Multi-container Pods](https://kubernetes.io/docs/concepts/workloads/pods/#how-pods-manage-multiple-containers)
- [Sidecar Pattern](https://kubernetes.io/docs/concepts/workloads/pods/#how-pods-manage-multiple-containers)
- [kubectl patch Documentation](https://kubernetes.io/docs/tasks/manage-kubernetes-objects/update-api-object-kubectl-patch/)

