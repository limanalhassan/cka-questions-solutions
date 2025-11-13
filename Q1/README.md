# Q1: NGINX TLSv1.3 Configuration Lab

This lab demonstrates configuring NGINX to only allow TLSv1.3 connections by updating the ConfigMap.

## Overview

Update the `nginx-config` ConfigMap to allow **only TLSv1.3** connections:
- Current configuration allows both TLSv1.2 and TLSv1.3
- After the fix, TLSv1.2 connections should fail
- TLSv1.3 connections should continue to work

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
- Create namespace and ConfigMap
- Generate TLS certificates
- Deploy NGINX with TLS configuration
- Set up port-forwarding
- Test TLS 1.2 connection (should succeed)

### 2. Test before fixing

1. Restart the deployment:
   ```bash
   make restart
   ```

2. Start port-forward in one terminal:
   ```bash
   make forward
   ```

3. In another terminal, test both TLS versions:
   ```bash
   # TLS 1.3 should work
   curl -k --tls-max 1.3 https://localhost:8443
   
   # TLS 1.2 should also work (before fix)
   curl -k --tls-max 1.2 https://localhost:8443
   ```

### 3. Apply the fix

Update the `nginx-config` ConfigMap to only allow TLSv1.3:

```bash
kubectl -n nginx-static edit configmap nginx-config
```

Change the `ssl_protocols` line from:
```
ssl_protocols TLSv1.2 TLSv1.3;
```

To:
```
ssl_protocols TLSv1.3;
```

### 4. Restart and verify

1. Restart the deployment to apply changes:
   ```bash
   make restart
   ```

2. Start port-forward:
   ```bash
   make forward
   ```

3. Test again:
   ```bash
   # TLS 1.3 should still work
   curl -k --tls-max 1.3 https://localhost:8443
   
   # TLS 1.2 should now fail
   curl -k --tls-max 1.2 https://localhost:8443
   ```

## Available Make Targets

- `make all` - Full lab setup (setup, cert, deploy, forward, test)
- `make setup` - Create namespace and ConfigMap
- `make cert` - Generate TLS certificates
- `make deploy` - Deploy NGINX
- `make forward` - Port-forward to localhost:8443
- `make test` - Test TLS 1.2 connection
- `make restart` - Restart deployment
- `make clean` - Clean up all resources

## Manual Testing

### Test TLS 1.3 (should work)
```bash
curl -k --tls-max 1.3 https://localhost:8443
```

### Test TLS 1.2 (should fail after fix)
```bash
curl -k --tls-max 1.2 https://localhost:8443
```

**Expected output after fix:**
```
curl: (35) error:1409442E:SSL routines:ssl3_read_bytes:tlsv1 alert protocol version
```

## Files

- `q1.yaml` - NGINX deployment with ConfigMap (allows TLS 1.2 and 1.3)
- `Makefile` - Automation for lab setup and testing

## Notes

- The lab uses hostname `web.k8s.local`
- TLS certificates are auto-generated
- Port-forward runs on port 8443
- After updating the ConfigMap, you must restart the deployment for changes to take effect

