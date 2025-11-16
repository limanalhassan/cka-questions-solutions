# Q13: NetworkPolicy Configuration Lab

This lab demonstrates how to configure Kubernetes NetworkPolicies to allow communication between frontend and backend deployments while maintaining the most restrictive (least permissive) security posture.

## Overview

**Scenario:** We have frontend and backend Deployments in separate namespaces (`frontend` and `backend`). They need to communicate.

**Task:**
1. **Analyze**: Inspect the frontend and backend Deployments to understand their communication requirements
2. **Apply**: From the NetworkPolicy YAML files in the `~/netpol` folder, choose one to apply

**Requirements for the chosen NetworkPolicy:**
- **Allow** communication between frontend and backend
- Be as restrictive as possible (least permissive)
- **Do NOT delete or change** the existing "deny-all" NetworkPolicies

**Warning:** Failure to follow these rules may result in a score reduction or zero.

## What You'll Learn

- **NetworkPolicy**: Understanding Kubernetes network policies and how they control pod-to-pod communication
- **Namespace Isolation**: How NetworkPolicies work across namespaces
- **Least Permissive**: Creating the most restrictive policy that still allows required communication
- **Policy Types**: Understanding Ingress and Egress policies
- **Pod Selectors**: Using labels to select pods for policies
- **Namespace Selectors**: Allowing traffic from specific namespaces

## Prerequisites

- `kubectl` configured to access a Kubernetes cluster
- `make` installed
- Cluster with a CNI plugin that supports NetworkPolicy (e.g., Calico, Cilium)
- Basic understanding of Kubernetes networking and labels

**Note:** NetworkPolicies require a CNI plugin that supports them. Kind clusters with default CNI may not support NetworkPolicies. Consider using Calico or Cilium.

## Quick Start

### 1. Set up the lab environment

```bash
make all
```

This will:
- Create `frontend` and `backend` namespaces
- Create frontend and backend deployments
- Create backend service
- Create deny-all NetworkPolicies in both namespaces (DO NOT DELETE)
- Create sample NetworkPolicy files in `~/netpol/` folder

### 2. Analyze the deployments

```bash
make inspect
# OR manually:
kubectl get deploy frontend -n frontend -o yaml
kubectl get deploy backend -n backend -o yaml
kubectl get svc backend -n backend
```

### 3. Review NetworkPolicy files

```bash
make list-netpol
# OR manually:
ls -la ~/netpol/
cat ~/netpol/*.yaml
```

### 4. Apply the solution

**Option 1: Manual solution**
```bash
# Choose the most restrictive NetworkPolicy (netpol-1.yaml)
kubectl apply -f ~/netpol/netpol-1.yaml
```

**Option 2: Automated solution**
```bash
make solution
```

### 5. Verify the solution

```bash
make verify
make test-communication
```

## Available Make Targets

- `make all` - Full lab setup (clean, setup)
- `make setup` - Create namespaces, deployments, services, and NetworkPolicy files
- `make solution` - Complete automated solution (applies netpol-1.yaml)
- `make apply-netpol FILE=netpol-1.yaml` - Apply a specific NetworkPolicy file
- `make status` - Show environment summary
- `make verify` - Verify solution implementation
- `make inspect` - Inspect deployments and services
- `make list-netpol` - List and display NetworkPolicy files
- `make test-communication` - Test frontend to backend communication
- `make clean` - Clean up all resources (preserves deny-all policies during cleanup)

## Detailed Solution Steps

### Step 1: Analyze Deployments

**Inspect frontend deployment:**
```bash
kubectl get deploy frontend -n frontend -o yaml
kubectl get pods -n frontend -l app=frontend --show-labels
```

**Key information:**
- Labels: `app: frontend`
- Namespace: `frontend`
- Needs to connect to: `backend.backend.svc.cluster.local:8080`

**Inspect backend deployment:**
```bash
kubectl get deploy backend -n backend -o yaml
kubectl get pods -n backend -l app=backend --show-labels
```

**Key information:**
- Labels: `app: backend`
- Namespace: `backend`
- Service: `backend` on port `8080`
- Needs to receive traffic from frontend

**Inspect backend service:**
```bash
kubectl get svc backend -n backend -o yaml
```

### Step 2: Review NetworkPolicy Files

**List available files:**
```bash
ls -la ~/netpol/
```

**Review each file:**
```bash
cat ~/netpol/netpol-1.yaml  # Most restrictive
cat ~/netpol/netpol-2.yaml  # Least restrictive (allows all)
cat ~/netpol/netpol-3.yaml  # Moderate (allows from any namespace)
```

**Understanding the options:**

1. **netpol-1.yaml** (Most Restrictive - RECOMMENDED):
   - Frontend: Allows egress only to backend namespace with label `name: backend`
   - Backend: Allows ingress only from frontend namespace with label `name: frontend`
   - Port: Only port 8080
   - **This is the most restrictive option**

2. **netpol-2.yaml** (Least Restrictive):
   - Frontend: Allows all egress
   - Backend: Allows all ingress
   - **Too permissive - not recommended**

3. **netpol-3.yaml** (Moderate):
   - Frontend: Allows egress to backend pods in any namespace
   - Backend: Allows ingress from frontend pods in any namespace
   - **Less restrictive than netpol-1**

### Step 3: Apply the Chosen NetworkPolicy

**Apply the most restrictive option:**
```bash
kubectl apply -f ~/netpol/netpol-1.yaml
```

**Verify it was applied:**
```bash
kubectl get netpol -n frontend
kubectl get netpol -n backend
```

### Step 4: Verify Communication

**Test from frontend pod:**
```bash
# Get a frontend pod
FRONTEND_POD=$(kubectl -n frontend get pods -l app=frontend -o jsonpath='{.items[0].metadata.name}')

# Test connection
kubectl -n frontend exec $FRONTEND_POD -- curl -v http://backend.backend.svc.cluster.local:8080
```

## Understanding NetworkPolicies

### NetworkPolicy Basics

**What is a NetworkPolicy?**
- Controls traffic flow between pods
- Acts as a firewall for pods
- Uses labels to select pods
- Can control both ingress (incoming) and egress (outgoing) traffic

**Default Behavior:**
- If no NetworkPolicy selects a pod, all traffic is allowed
- If a NetworkPolicy selects a pod, only explicitly allowed traffic is permitted
- Multiple NetworkPolicies are additive (union of rules)

### Policy Structure

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend-backend
  namespace: frontend
spec:
  podSelector:          # Selects pods this policy applies to
    matchLabels:
      app: frontend
  policyTypes:          # Types of traffic to control
  - Ingress             # Incoming traffic
  - Egress              # Outgoing traffic
  ingress:              # Ingress rules (if policyTypes includes Ingress)
  - from:               # Sources allowed
    - podSelector:      # Pods in same namespace
    - namespaceSelector: # Pods in other namespaces
  egress:               # Egress rules (if policyTypes includes Egress)
  - to:                 # Destinations allowed
    - podSelector:
    - namespaceSelector:
    ports:              # Ports allowed
    - protocol: TCP
      port: 8080
```

### Most Restrictive Policy

**Key principles:**
1. **Specific namespace selection**: Use namespaceSelector with specific labels
2. **Specific pod selection**: Use podSelector with specific labels
3. **Specific ports**: Only allow required ports
4. **One direction**: Frontend needs egress, backend needs ingress

**Example (Most Restrictive):**
```yaml
# Frontend namespace - allows egress to backend
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend-backend
  namespace: frontend
spec:
  podSelector:
    matchLabels:
      app: frontend
  policyTypes:
  - Egress
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          name: backend      # Specific namespace
      podSelector:
        matchLabels:
          app: backend       # Specific pods
    ports:
    - protocol: TCP
      port: 8080             # Specific port only
```

## Verification

### Check NetworkPolicies

```bash
# List all NetworkPolicies
kubectl get netpol -n frontend
kubectl get netpol -n backend

# View details
kubectl get netpol deny-all -n frontend -o yaml
kubectl get netpol allow-frontend-backend -n frontend -o yaml
```

### Verify deny-all Policies Exist

```bash
# Must exist in both namespaces
kubectl get netpol deny-all -n frontend
kubectl get netpol deny-all -n backend
```

### Test Communication

```bash
# Get frontend pod
FRONTEND_POD=$(kubectl -n frontend get pods -l app=frontend -o jsonpath='{.items[0].metadata.name}')

# Test connection
kubectl -n frontend exec $FRONTEND_POD -- curl -v http://backend.backend.svc.cluster.local:8080

# Check if connection succeeds
# Should return HTTP 200, 403, or 404 (not connection refused)
```

## Verification Checklist

After applying the solution, verify:

- [ ] deny-all NetworkPolicy exists in frontend namespace (NOT deleted)
- [ ] deny-all NetworkPolicy exists in backend namespace (NOT deleted)
- [ ] Additional NetworkPolicy applied to allow communication
- [ ] Frontend pods can egress to backend pods
- [ ] Backend pods can ingress from frontend pods
- [ ] Only port 8080 is allowed
- [ ] Only specific namespaces are allowed (most restrictive)
- [ ] Communication test succeeds

## Troubleshooting

### NetworkPolicies not working

**Symptom:** Policies applied but traffic still blocked/allowed incorrectly

**Possible causes:**
- CNI plugin doesn't support NetworkPolicy
- Policies not correctly applied
- Label selectors don't match

**Solution:**
```bash
# Check if CNI supports NetworkPolicy
kubectl get networkpolicies.networking.k8s.io --all-namespaces

# Verify policies are applied
kubectl get netpol --all-namespaces

# Check pod labels
kubectl get pods --show-labels -n frontend
kubectl get pods --show-labels -n backend

# Check namespace labels
kubectl get ns frontend backend --show-labels
```

### deny-all policy deleted

**Symptom:** deny-all NetworkPolicy missing

**Solution:**
```bash
# Recreate deny-all policy
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all
  namespace: frontend
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
EOF
```

### Communication not working

**Symptom:** Frontend cannot reach backend

**Possible causes:**
- NetworkPolicy too restrictive
- Wrong namespace labels
- Wrong pod labels
- Wrong port

**Solution:**
```bash
# Check NetworkPolicy rules
kubectl get netpol -n frontend -o yaml
kubectl get netpol -n backend -o yaml

# Verify namespace labels
kubectl get ns frontend backend --show-labels

# Test without policies (temporarily)
kubectl delete netpol allow-frontend-backend -n frontend
kubectl delete netpol allow-frontend-backend -n backend
# Test connection
# Then reapply correct policy
```

### Wrong NetworkPolicy applied

**Symptom:** Applied a too-permissive policy

**Solution:**
```bash
# Delete the wrong policy
kubectl delete netpol <policy-name> -n frontend
kubectl delete netpol <policy-name> -n backend

# Apply the correct (most restrictive) one
kubectl apply -f ~/netpol/netpol-1.yaml
```

## Common kubectl Commands

### NetworkPolicy

```bash
# List NetworkPolicies
kubectl get netpol -n <namespace>
kubectl get netpol --all-namespaces

# Describe NetworkPolicy
kubectl describe netpol <name> -n <namespace>

# View NetworkPolicy YAML
kubectl get netpol <name> -n <namespace> -o yaml

# Apply NetworkPolicy
kubectl apply -f <file>.yaml

# Delete NetworkPolicy
kubectl delete netpol <name> -n <namespace>
```

### Testing Communication

```bash
# Get pod name
kubectl get pods -n frontend -l app=frontend

# Test connection
kubectl exec -n frontend <pod-name> -- curl http://backend.backend.svc.cluster.local:8080

# Test with verbose output
kubectl exec -n frontend <pod-name> -- curl -v http://backend.backend.svc.cluster.local:8080
```

## Files

- `q13.yaml` - Base setup (namespaces, deployments, services, deny-all policies)
- `solution.yaml` - Solution reference with example NetworkPolicy
- `Makefile` - Automation for lab setup and solution
- `README.md` - This documentation
- `~/netpol/*.yaml` - NetworkPolicy files (created during setup)

## Notes

- **deny-all policies**: Must NOT be deleted or modified
- **Most restrictive**: Choose the policy that allows only the minimum required traffic
- **Namespace labels**: Ensure namespaces have correct labels for namespaceSelector
- **Pod labels**: Ensure pods have correct labels for podSelector
- **Port specificity**: Only allow the exact port needed (8080)
- **Direction**: Frontend needs egress, backend needs ingress
- **CNI requirement**: Cluster must have a CNI plugin that supports NetworkPolicy

## Expected Outcomes

After successful solution:

✅ deny-all NetworkPolicies exist in both namespaces (not deleted)  
✅ Additional NetworkPolicy applied to allow frontend-backend communication  
✅ Frontend pods can egress to backend pods on port 8080  
✅ Backend pods can ingress from frontend pods on port 8080  
✅ Policy is most restrictive (specific namespaces, pods, and ports only)  
✅ Communication test succeeds  
✅ No other unnecessary traffic is allowed  

## Additional Resources

- [Kubernetes NetworkPolicies](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
- [NetworkPolicy Specification](https://kubernetes.io/docs/reference/kubernetes-api/policy-resources/network-policy-v1/)
- [NetworkPolicy Examples](https://kubernetes.io/docs/tasks/administer-cluster/declare-network-policy/)

