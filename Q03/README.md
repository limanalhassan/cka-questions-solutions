# Q3: Horizontal Pod Autoscaler (HPA) Lab

This lab demonstrates creating and configuring a Horizontal Pod Autoscaler (HPA) to automatically scale a deployment based on CPU usage.

## Overview

Create a Horizontal Pod Autoscaler (HPA) named `apache-server` in the `autoscale` namespace that:
- Targets the existing `apache-server` deployment
- Maintains 50% CPU usage per Pod
- Scales between 1 (min) and 4 (max) Pods
- Has a downscale stabilization window of 30 seconds

## Prerequisites

- `kubectl` configured to access a Kubernetes cluster
- `make` installed
- Metrics Server installed in the cluster (required for HPA to work)

**Note:** HPA requires the Metrics Server to be installed. Most managed Kubernetes clusters have it by default. To check:
```bash
kubectl get deployment metrics-server -n kube-system
```

## Quick Start

### 1. Set up the lab environment

```bash
make all
```

This will:
- Create the `autoscale` namespace
- Deploy the `apache-server` deployment
- Create the service
- Wait for the deployment to be ready

### 2. Create the HPA (Solution)

**Option 1: Manual creation**
Create the HPA resource manually using `kubectl` or by editing YAML.

**Option 2: Apply solution**
```bash
make solution
```

This applies the solution YAML which creates the HPA with all required configurations.

### 3. Verify the HPA

```bash
make status
```

Or check manually:
```bash
kubectl -n autoscale get hpa apache-server
kubectl -n autoscale describe hpa apache-server
```

## Available Make Targets

- `make all` - Full lab setup (clean, setup, deploy)
- `make setup` - Create namespace and apply q3.yaml
- `make deploy` - Wait for deployment to be ready
- `make solution` - Apply HPA solution (manual step)
- `make status` - Show environment summary
- `make watch` - Watch HPA and pods in real-time
- `make clean` - Clean up all resources

## Testing the HPA

### Check HPA Status

```bash
kubectl -n autoscale get hpa apache-server
```

Expected output should show:
- TARGETS: 50% (CPU target)
- MINPODS: 1
- MAXPODS: 4
- REPLICAS: Current number of pods

### Watch HPA and Pods

```bash
make watch
```

Or manually:
```bash
# Terminal 1: Watch HPA
kubectl -n autoscale get hpa apache-server -w

# Terminal 2: Watch Pods
kubectl -n autoscale get pods -l app=apache-server -w
```

### Generate CPU Load (Optional)

To test autoscaling, you can generate CPU load:

1. Port-forward to the service:
   ```bash
   kubectl -n autoscale port-forward svc/apache-server 8080:80
   ```

2. In another terminal, generate load:
   ```bash
   # Install Apache Bench if needed: brew install httpd (macOS)
   ab -n 100000 -c 100 http://localhost:8080/
   ```

3. Watch the HPA scale up:
   ```bash
   kubectl -n autoscale get hpa apache-server -w
   ```

## HPA Configuration Details

The solution HPA includes:

- **Scale Target**: `apache-server` deployment
- **CPU Target**: 50% average utilization
- **Min Replicas**: 1
- **Max Replicas**: 4
- **Downscale Stabilization**: 30 seconds

### Key Fields Explained

- `scaleTargetRef`: References the deployment to scale
- `minReplicas`/`maxReplicas`: Scaling boundaries
- `metrics`: Defines the scaling metric (CPU utilization)
- `behavior.scaleDown.stabilizationWindowSeconds`: Prevents rapid downscaling

## Files

- `q3.yaml` - Base setup (namespace, deployment, service)
- `solution.yaml` - HPA solution
- `Makefile` - Automation for lab setup and testing

## Notes

- HPA requires resource requests/limits to be set on containers (included in q3.yaml)
- Metrics Server must be installed for HPA to function
- HPA checks metrics every 15 seconds by default
- Scaling decisions are based on the average CPU usage across all pods
- The downscale stabilization window prevents pods from being scaled down too quickly

## Troubleshooting

### HPA shows "unknown" in TARGETS

This usually means Metrics Server is not installed or not working:
```bash
kubectl get deployment metrics-server -n kube-system
kubectl logs -n kube-system -l k8s-app=metrics-server
```

### HPA not scaling

- Verify resource requests are set: `kubectl -n autoscale describe deploy apache-server`
- Check HPA events: `kubectl -n autoscale describe hpa apache-server`
- Ensure pods are running: `kubectl -n autoscale get pods`

