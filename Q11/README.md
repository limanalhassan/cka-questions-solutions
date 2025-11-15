# Q11: cert-manager CRD Documentation Lab

This lab demonstrates how to extract and document Kubernetes Custom Resource Definitions (CRDs) using `kubectl` commands, specifically focusing on cert-manager CRDs.

## Overview

**Task:** Verify the `cert-manager` application deployed in the cluster.

**Sub-tasks:**

1. **Create a list of cert-manager CRDs:**
   - Save the list to `~/resources.yaml`
   - **CRITICAL:** Use kubectl's **default** output format
   - **DO NOT** set an output format (no `-o` or `--output` flags)
   - **Warning:** Failure to use default format will result in reduced score

2. **Extract documentation for `subject` field:**
   - Extract documentation for the `subject` specification field of the `Certificate` Custom Resource
   - Save to `~/subject.yaml`
   - **Flexibility:** You may use any output format that kubectl supports

## What You'll Learn

- **CRD Discovery**: Finding and listing Custom Resource Definitions
- **kubectl get crd**: Listing CRDs in the cluster
- **kubectl explain**: Extracting field documentation from CRDs
- **Output Formats**: Understanding when to use default vs. specified output formats
- **cert-manager**: Understanding cert-manager CRDs and their structure

## Prerequisites

- `kubectl` configured to access a Kubernetes cluster
- `make` installed
- **cert-manager installed** in the cluster
- Basic understanding of Custom Resource Definitions (CRDs)

**Install cert-manager (if not already installed):**
```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml
```

## Quick Start

### 1. Set up the lab environment

```bash
make all
```

This will:
- Create the `cert-manager` namespace (for reference)
- Check if cert-manager CRDs are installed

### 2. Apply the solution

**Option 1: Manual solution (step by step)**
```bash
# Task 1: List cert-manager CRDs (DEFAULT OUTPUT FORMAT - NO -o FLAG)
kubectl get crd | grep cert-manager > ~/resources.yaml

# Task 2: Extract subject field documentation (any output format)
kubectl explain certificate.spec.subject > ~/subject.yaml
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
- `make setup` - Create namespace and check cert-manager installation
- `make solution` - Complete automated solution
- `make task1` - Complete Task 1 only (list CRDs)
- `make task2` - Complete Task 2 only (extract subject docs)
- `make status` - Show environment summary
- `make verify` - Verify solution implementation
- `make show-resources` - Display contents of ~/resources.yaml
- `make show-subject` - Display contents of ~/subject.yaml
- `make check-cert-manager` - Check cert-manager installation
- `make clean` - Clean up resources (does not remove cert-manager)

## Detailed Solution Steps

### Task 1: Create List of cert-manager CRDs

**CRITICAL REQUIREMENT:** Use kubectl's **default output format**. Do NOT use `-o` or `--output` flags.

**Method 1: Using kubectl get crd (Recommended)**
```bash
kubectl get crd | grep cert-manager > ~/resources.yaml
```

**What this does:**
- `kubectl get crd`: Lists all CRDs in the cluster (default table format)
- `grep cert-manager`: Filters for cert-manager CRDs
- `> ~/resources.yaml`: Saves output to file

**Expected output format (default table):**
```
NAME                                    CREATED AT
certificates.cert-manager.io            2024-01-01T00:00:00Z
certificaterequests.cert-manager.io     2024-01-01T00:00:00Z
challenges.acme.cert-manager.io         2024-01-01T00:00:00Z
...
```

**Method 2: Using kubectl api-resources (Alternative)**
```bash
kubectl api-resources --api-group=cert-manager.io -o name > ~/resources.yaml
```

**⚠️ WARNING:** This method uses `-o name`, which may not be considered "default format". Use Method 1 to be safe.

**Verify the file:**
```bash
cat ~/resources.yaml
```

### Task 2: Extract Documentation for `subject` Field

**Flexibility:** You may use any output format for this task.

**Method 1: Default format (plain text)**
```bash
kubectl explain certificate.spec.subject > ~/subject.yaml
```

**Method 2: With recursive details**
```bash
kubectl explain certificate.spec.subject --recursive > ~/subject.yaml
```

**Method 3: YAML format**
```bash
kubectl explain certificate.spec.subject -o yaml > ~/subject.yaml
```

**What this does:**
- `kubectl explain`: Shows documentation for a specific field
- `certificate.spec.subject`: Path to the `subject` field in Certificate CRD
- `> ~/subject.yaml`: Saves output to file

**Expected output:**
```
KIND:     Certificate
VERSION:  cert-manager.io/v1

RESOURCE: subject <Object>

     Subject to be used on the Certificate.

     <Object>
       Subject Distinguished Name fields.
```

**Verify the file:**
```bash
cat ~/subject.yaml
```

## Understanding kubectl Commands

### kubectl get crd

**Purpose:** Lists all Custom Resource Definitions in the cluster

**Default output format:** Table format with columns:
- NAME: CRD name
- CREATED AT: Creation timestamp

**Example:**
```bash
kubectl get crd
```

**Output:**
```
NAME                                    CREATED AT
certificates.cert-manager.io            2024-01-01T00:00:00Z
certificaterequests.cert-manager.io     2024-01-01T00:00:00Z
...
```

### kubectl explain

**Purpose:** Documents fields in Kubernetes resources

**Syntax:**
```bash
kubectl explain <resource>.<field-path>
```

**Options:**
- `--recursive`: Show all nested fields
- `-o <format>`: Output format (yaml, json, etc.)

**Example:**
```bash
kubectl explain certificate.spec.subject
kubectl explain certificate.spec.subject --recursive
kubectl explain certificate.spec.subject -o yaml
```

### kubectl api-resources

**Purpose:** Lists API resources available in the cluster

**Useful for:**
- Finding resources in a specific API group
- Discovering resource names and short names

**Example:**
```bash
kubectl api-resources --api-group=cert-manager.io
```

## Verification

### Check Generated Files

```bash
# Check Task 1 file
cat ~/resources.yaml

# Check Task 2 file
cat ~/subject.yaml

# Check file sizes
wc -l ~/resources.yaml ~/subject.yaml
```

### Verify Default Output Format (Task 1)

The file should contain table-formatted output (default kubectl format):
- Column headers (NAME, CREATED AT)
- Tab-separated values
- No JSON or YAML formatting

**Correct format:**
```
NAME                                    CREATED AT
certificates.cert-manager.io            2024-01-01T00:00:00Z
```

**Incorrect format (would reduce score):**
```yaml
# YAML format (incorrect for Task 1)
- name: certificates.cert-manager.io
  created: 2024-01-01T00:00:00Z
```

### Verify Subject Documentation (Task 2)

The file should contain documentation about the `subject` field:
- Field description
- Field type
- Nested fields (if using --recursive)

## Verification Checklist

After completing the tasks, verify:

- [ ] File `~/resources.yaml` exists
- [ ] File contains cert-manager CRD names
- [ ] File uses default kubectl output format (table format)
- [ ] No `-o` or `--output` flags were used for Task 1
- [ ] File `~/subject.yaml` exists
- [ ] File contains documentation for `subject` field
- [ ] Documentation is readable and complete

## Troubleshooting

### cert-manager CRDs not found

**Symptom:** `kubectl get crd | grep cert-manager` returns nothing

**Solution:**
```bash
# Check if cert-manager is installed
kubectl get crd | grep cert-manager

# Install cert-manager if not installed
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml

# Wait for CRDs to be created
kubectl wait --for condition=established --timeout=60s crd/certificates.cert-manager.io
```

### Certificate CRD not found

**Symptom:** `kubectl explain certificate.spec.subject` returns error

**Solution:**
```bash
# Check if Certificate CRD exists
kubectl get crd certificates.cert-manager.io

# Verify cert-manager installation
kubectl get pods -n cert-manager

# Reinstall cert-manager if needed
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml
```

### Wrong output format for Task 1

**Symptom:** File contains JSON or YAML instead of table format

**Solution:**
```bash
# Remove the file
rm ~/resources.yaml

# Recreate with default format (NO -o flag)
kubectl get crd | grep cert-manager > ~/resources.yaml

# Verify it's table format
cat ~/resources.yaml
```

### File not saved to home directory

**Symptom:** Files saved to wrong location

**Solution:**
```bash
# Use ~/ for home directory
kubectl get crd | grep cert-manager > ~/resources.yaml

# Or use $HOME
kubectl get crd | grep cert-manager > $HOME/resources.yaml

# Verify location
ls -la ~/resources.yaml
```

### Permission denied

**Symptom:** Cannot write to ~/resources.yaml

**Solution:**
```bash
# Check permissions
ls -la ~/

# Fix permissions if needed
chmod 755 ~/

# Or use sudo (if necessary, though not recommended)
sudo kubectl get crd | grep cert-manager > ~/resources.yaml
```

## Common kubectl Commands

### List CRDs

```bash
# All CRDs
kubectl get crd

# Filter by name
kubectl get crd | grep cert-manager

# Specific CRD
kubectl get crd certificates.cert-manager.io
```

### Explain Resources

```bash
# Explain a resource
kubectl explain certificate

# Explain a field
kubectl explain certificate.spec

# Explain nested field
kubectl explain certificate.spec.subject

# Recursive explanation
kubectl explain certificate.spec.subject --recursive

# YAML format
kubectl explain certificate.spec.subject -o yaml
```

### API Resources

```bash
# All API resources
kubectl api-resources

# Filter by API group
kubectl api-resources --api-group=cert-manager.io

# Output as names only
kubectl api-resources --api-group=cert-manager.io -o name
```

## Files

- `q11.yaml` - Base setup (namespace creation)
- `solution.yaml` - Solution reference with commands
- `Makefile` - Automation for lab setup and solution
- `README.md` - This documentation
- `~/resources.yaml` - Generated file (Task 1 output)
- `~/subject.yaml` - Generated file (Task 2 output)

## Notes

- **Task 1 CRITICAL:** Must use default kubectl output format (no `-o` or `--output` flags)
- **Task 2 Flexible:** Can use any output format
- **File locations:** Both files must be in home directory (`~/`)
- **cert-manager required:** Ensure cert-manager is installed before starting
- **Default format:** Table format with column headers and tab-separated values
- **Certificate CRD:** Must exist for Task 2 to work

## Expected Outcomes

After successful completion:

✅ File `~/resources.yaml` created  
✅ File contains cert-manager CRD list in default table format  
✅ No output format flags used for Task 1  
✅ File `~/subject.yaml` created  
✅ File contains documentation for `subject` field  
✅ Documentation is readable and complete  
✅ Both files are in home directory  

## Additional Resources

- [kubectl get crd Documentation](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#get)
- [kubectl explain Documentation](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#explain)
- [Custom Resource Definitions](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/)
- [cert-manager Documentation](https://cert-manager.io/docs/)

