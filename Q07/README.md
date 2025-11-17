# Q7: Deployment Port Configuration & NodePort Service Lab

This lab demonstrates how to reconfigure a Deployment to expose container ports and create a NodePort Service to expose pods externally.

## Overview

Complete the following tasks:
1. **Reconfigure** the existing Deployment `front-end` in namespace `sp-culator` to expose port `80/tcp` of the existing container `nginx`
2. **Create** a new Service named `front-end-svc` exposing the container port `80/tcp`
3. **Configure** the Service to expose the individual pods via NodePort

## What You'll Learn

- **Container Ports**: How to expose ports in Kubernetes Deployments
- **Services**: Understanding Kubernetes Service types (NodePort)
- **kubectl patch**: Modifying existing resources without full YAML
- **kubectl expose**: Creating Services from Deployments
- **NodePort**: Exposing services on each node's IP at a static port

## Prerequisites

- `kubectl` configured to access a Kubernetes cluster
- `make` installed
- Cluster with at least one node
- Basic understanding of Kubernetes Deployments and Services

## Quick Start

### 1. Set up the lab environment

```bash
make all
```

This will:
- Create the `sp-culator` namespace
- Create the `front-end` Deployment with nginx container (port not exposed initially)

### 2. Apply the solution

**Option 1: Manual solution (step by step)**
```bash
# Step 1: Reconfigure deployment to expose port 80/tcp
kubectl patch deployment front-end -n sp-culator --type='json' \
  -p='[{"op": "add", "path": "/spec/template/spec/containers/0/ports", "value": [{"containerPort": 80, "protocol": "TCP"}]}]'

# Step 2: Create NodePort service
kubectl expose deployment front-end -n sp-culator \
  --name=front-end-svc \
  --port=80 \
  --target-port=80 \
  --type=NodePort
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
- `make patch-deployment` - Patch deployment to expose port 80/tcp
- `make create-service` - Create NodePort service
- `make status` - Show environment summary
- `make verify` - Verify solution implementation
- `make test` - Test the NodePort service
- `make clean` - Clean up all resources

## Detailed Solution Steps

### Step 1: Reconfigure Deployment to Expose Port 80/tcp

The initial deployment has an nginx container but doesn't explicitly expose port 80. We need to add the port configuration to the container spec.

**Using kubectl patch:**
```bash
kubectl patch deployment front-end -n sp-culator --type='json' \
  -p='[{"op": "add", "path": "/spec/template/spec/containers/0/ports", "value": [{"containerPort": 80, "protocol": "TCP"}]}]'
```

**What this does:**
- `--type='json'`: Uses JSON patch format
- `"op": "add"`: Adds a new field
- `"path": "/spec/template/spec/containers/0/ports"`: Path to the ports array in the first container
- `"value": [{"containerPort": 80, "protocol": "TCP"}]`: The port configuration to add

**Verify the patch:**
```bash
kubectl get deployment front-end -n sp-culator -o yaml | grep -A 5 ports
```

**Expected output:**
```yaml
ports:
- containerPort: 80
  protocol: TCP
```

**Alternative: Edit the deployment directly**
```bash
kubectl edit deployment front-end -n sp-culator
# Add the ports section to the container spec
```

### Step 2: Create NodePort Service

Create a Service that exposes the deployment on a NodePort.

**Using kubectl expose:**
```bash
kubectl expose deployment front-end -n sp-culator \
  --name=front-end-svc \
  --port=80 \
  --target-port=80 \
  --type=NodePort
```

**What this does:**
- `expose deployment front-end`: Creates a service from the deployment
- `--name=front-end-svc`: Service name
- `--port=80`: Service port (port exposed by the service)
- `--target-port=80`: Container port (port on the pods)
- `--type=NodePort`: Service type (exposes on each node's IP)

**Verify the service:**
```bash
kubectl get svc front-end-svc -n sp-culator
```

**Expected output:**
```
NAME            TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
front-end-svc   NodePort   10.96.xxx.xxx   <none>        80:3xxxx/TCP   1m
```

The `PORT(S)` column shows `80:3xxxx/TCP` where:
- `80` is the service port
- `3xxxx` is the NodePort (randomly assigned, range 30000-32767)

**Alternative: Create from YAML**
```bash
kubectl apply -f solution.yaml
```

## Understanding the Components

### Container Ports

**Why expose ports in Deployment?**
- Documents which ports the container listens on
- Helps with service discovery
- Required for some Kubernetes features (health checks, service mesh)
- Best practice for clarity

**Port configuration:**
```yaml
containers:
- name: nginx
  image: nginx:1.25
  ports:
  - containerPort: 80
    protocol: TCP
```

### NodePort Service

**What is NodePort?**
- Exposes the service on each node's IP at a static port
- Port range: 30000-32767 (default)
- Accessible from outside the cluster using `<NodeIP>:<NodePort>`
- Traffic is routed to the service's cluster IP

**Service configuration:**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: front-end-svc
  namespace: sp-culator
spec:
  type: NodePort
  selector:
    app: front-end
  ports:
  - port: 80          # Service port
    targetPort: 80    # Container port
    protocol: TCP
    nodePort: 30080   # Optional: specific NodePort
```

**Service Types Comparison:**
- **ClusterIP** (default): Only accessible within the cluster
- **NodePort**: Exposes on each node's IP at a static port
- **LoadBalancer**: Exposes externally using cloud provider's load balancer
- **ExternalName**: Maps to an external DNS name

## Verification Checklist

After applying the solution, verify:

- [ ] Deployment has port 80/tcp configured in container spec
- [ ] Service `front-end-svc` exists
- [ ] Service type is `NodePort`
- [ ] Service port is `80`
- [ ] Service target port is `80`
- [ ] Service selector matches deployment labels (`app: front-end`)
- [ ] NodePort is assigned (30000-32767 range)
- [ ] Pods are running and ready

## Testing the Service

### Test from within the cluster

```bash
# Get the service cluster IP
kubectl get svc front-end-svc -n sp-culator

# Test from a pod
kubectl -n sp-culator run test-curl --image=curlimages/curl:latest --rm -i --restart=Never -- \
  curl -s http://front-end-svc.sp-culator.svc.cluster.local:80
```

### Test via NodePort

```bash
# Get NodePort
NODE_PORT=$(kubectl -n sp-culator get svc front-end-svc -o jsonpath='{.spec.ports[0].nodePort}')

# Get node IP (for kind/minikube, use localhost)
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')

# Test
curl http://${NODE_IP}:${NODE_PORT}
# Or for kind/minikube:
curl http://localhost:${NODE_PORT}
```

### Using make test

```bash
make test
```

## Troubleshooting

### Deployment port not showing

**Symptom:** Port not visible after patching

**Solution:**
```bash
# Check if patch was applied
kubectl get deployment front-end -n sp-culator -o yaml | grep -A 5 ports

# If not, try patching again or edit directly
kubectl edit deployment front-end -n sp-culator
```

### Service not created

**Symptom:** `kubectl expose` fails

**Possible causes:**
- Deployment doesn't exist
- Service name already exists
- Wrong namespace

**Solution:**
```bash
# Check deployment exists
kubectl get deployment front-end -n sp-culator

# Check if service exists
kubectl get svc front-end-svc -n sp-culator

# Create from YAML if expose fails
kubectl apply -f solution.yaml
```

### Service not accessible

**Symptom:** Cannot connect to NodePort

**Possible causes:**
- Pods not ready
- Wrong port
- Firewall blocking
- Service selector doesn't match pod labels

**Solution:**
```bash
# Check pods
kubectl -n sp-culator get pods -l app=front-end

# Check service endpoints
kubectl -n sp-culator get endpoints front-end-svc

# Check service selector
kubectl -n sp-culator get svc front-end-svc -o yaml | grep selector -A 2

# Check pod labels
kubectl -n sp-culator get pods -l app=front-end --show-labels
```

### Port already in use

**Symptom:** NodePort conflict

**Solution:**
- Kubernetes will assign a random port if not specified
- To specify a port, use YAML with `nodePort` field
- Ensure the port is in range 30000-32767

### Pods not starting

**Symptom:** Pods in `Pending` or `ContainerCreating`

**Solution:**
```bash
# Check pod status
kubectl -n sp-culator describe pods -l app=front-end

# Check events
kubectl -n sp-culator get events

# Check image pull
kubectl -n sp-culator get pods -l app=front-end -o yaml | grep image
```

## Common kubectl Commands

### Patch Deployment

```bash
# Add port to container
kubectl patch deployment <name> -n <namespace> --type='json' \
  -p='[{"op": "add", "path": "/spec/template/spec/containers/0/ports", "value": [{"containerPort": 80, "protocol": "TCP"}]}]'

# Replace port
kubectl patch deployment <name> -n <namespace> --type='json' \
  -p='[{"op": "replace", "path": "/spec/template/spec/containers/0/ports/0/containerPort", "value": 8080}]'

# Remove port
kubectl patch deployment <name> -n <namespace> --type='json' \
  -p='[{"op": "remove", "path": "/spec/template/spec/containers/0/ports"}]'
```

### Expose Service

```bash
# NodePort
kubectl expose deployment <name> -n <namespace> \
  --name=<service-name> \
  --port=<port> \
  --target-port=<target-port> \
  --type=NodePort

# ClusterIP (default)
kubectl expose deployment <name> -n <namespace> \
  --name=<service-name> \
  --port=<port>

# LoadBalancer
kubectl expose deployment <name> -n <namespace> \
  --name=<service-name> \
  --port=<port> \
  --type=LoadBalancer
```

## Files

- `q7.yaml` - Base setup (namespace and deployment without port exposed)
- `solution.yaml` - Solution reference with Service YAML
- `Makefile` - Automation for lab setup and solution
- `README.md` - This documentation

## Notes

- **Port exposure**: While nginx listens on port 80 by default, explicitly declaring it in the Deployment is a best practice
- **NodePort range**: Default range is 30000-32767, but can be configured in kube-apiserver
- **Service selector**: Must match pod labels for the service to route traffic
- **Namespace**: All resources must be in the `sp-culator` namespace
- **Container name**: The container is named `nginx` (not `front-end`)
- **Service name**: Must be exactly `front-end-svc`

## Expected Outcomes

After successful solution:

✅ Deployment `front-end` has port 80/tcp configured  
✅ Service `front-end-svc` created  
✅ Service type is `NodePort`  
✅ Service exposes port 80  
✅ Service targets container port 80  
✅ NodePort assigned (30000-32767)  
✅ Service accessible via `<NodeIP>:<NodePort>`  
✅ Pods are running and receiving traffic  

## Additional Resources

- [Kubernetes Services Documentation](https://kubernetes.io/docs/concepts/services-networking/service/)
- [kubectl patch Documentation](https://kubernetes.io/docs/tasks/manage-kubernetes-objects/update-api-object-kubectl-patch/)
- [kubectl expose Documentation](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#expose)
- [NodePort Service Type](https://kubernetes.io/docs/concepts/services-networking/service/#type-nodeport)

