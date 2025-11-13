# Q2: Ingress → Gateway API Migration Lab

This lab demonstrates migrating a web application from Kubernetes Ingress to Gateway API while maintaining HTTPS access.

## Overview

Migrate an existing web application from Ingress to Gateway API:
- Maintain HTTPS access
- Create Gateway and HTTPRoute resources
- Test the Gateway API configuration
- Delete the old Ingress resource

## Prerequisites

- `kubectl` configured to access a Kubernetes cluster
- `make` installed
- `openssl` installed (for certificate generation)
- `curl` installed (for testing)

## Quick Start

### 1. Set up the lab environment

```bash
make all
```

This will:
- Install Gateway API CRDs
- Install NGINX Gateway Fabric controller
- Create namespace, deployment, service, and Ingress
- Generate TLS certificates
- Test the Ingress setup

### 2. Apply the Gateway API solution (Solution to the question)

```bash
make solution
```

This creates:
- `web-gateway` - Gateway resource with TLS termination
- `web-route` - HTTPRoute with routing rules

### 3. Test the Gateway API

```bash
make test-gateway
```

### 4. Complete the migration (delete the ingress)

```bash
make delete-ingress
```

## Available Make Targets

- `make all` - Full lab setup (Ingress-based environment)
- `make clean` - Clean up all resources
- `make solution` - Apply Gateway + HTTPRoute solution
- `make test` - Test Ingress setup (automatic)
- `make forward` - Port-forward Ingress service for manual testing
- `make test-gateway` - Test Gateway API setup (automatic)
- `make forward-gateway` - Port-forward Gateway service for manual testing
- `make validate` - Check Gateway/HTTPRoute status
- `make status` - Show environment summary
- `make delete-ingress` - Delete Ingress resource (step 4)

## Manual Testing

### Test via port-forward

1. Start port-forward:
   ```bash
   make forward
   ```

2. In another terminal, test:
   ```bash
   curl http://localhost:8080
   ```

### Test Gateway API (after applying solution)

**Option 1: Automatic test**
```bash
make test-gateway
```
This will port-forward the Gateway service and test it automatically.

**Option 2: Manual port-forward**
1. Start port-forward:
   ```bash
   make forward-gateway
   ```
   Or manually:
   ```bash
   kubectl -n web-ns port-forward svc/web-gateway-nginx 8443:443
   ```

2. In another terminal, test:
   ```bash
   curl -k --resolve gateway.web.k8s.local:8443:127.0.0.1 https://gateway.web.k8s.local:8443
   ```
   
   **Note:** The `--resolve` option is needed to properly send the SNI (Server Name Indication) in the TLS handshake.

**Option 3: Check Gateway Status**
```bash
kubectl -n web-ns get gateway web-gateway
kubectl -n web-ns get svc web-gateway-nginx
make validate
```

## Files

- `q2.yaml` - Base setup with Ingress
- `solution.yaml` - Gateway API solution (Gateway + HTTPRoute)
- `Makefile` - Automation for lab setup and testing

## Notes

- The lab uses hostname `gateway.web.k8s.local`
- TLS certificates are auto-generated
- GatewayClass `nginx` must be installed (handled by `make all`)

