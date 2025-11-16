# =========================
# CKA LAB - QUESTION 12 (MariaDB PersistentVolume Recovery)
# =========================
QUESTION := Q12
NAMESPACE := mariadb
PVC_NAME := mariadb
DEPLOYMENT_NAME := mariadb
DEPLOYMENT_FILE := ~/mariadb-deploy.yaml
PV_NAME := mariadb-pv
STORAGE_SIZE := 250Mi
ACCESS_MODE := ReadWriteOnce
YAML := q12.yaml
SOLUTION := solution.yaml

# =========================
# Default workflow
# =========================
.PHONY: all
all: clean setup
	@echo "\n✅ $(QUESTION) environment ready."
	@echo "   Complete the tasks manually or run 'make solution'.\n"

# =========================
# Environment Setup
# =========================
.PHONY: setup
setup:
	@echo "\n🔧 Setting up $(QUESTION) environment..."
	@echo "→ Ensuring PV is available (clearing claimRef if needed)..."
	-kubectl patch pv $(PV_NAME) --type=merge -p='{"spec":{"claimRef":null}}' --ignore-not-found 2>/dev/null || true
	-sleep 2
	kubectl apply -f $(YAML)
	@echo "\n📝 Creating MariaDB deployment file at $(DEPLOYMENT_FILE)..."
	@mkdir -p $$(dirname $(DEPLOYMENT_FILE))
	@printf '%s\n' \
		'apiVersion: apps/v1' \
		'kind: Deployment' \
		'metadata:' \
		'  name: mariadb' \
		'  namespace: mariadb' \
		'  labels:' \
		'    app: mariadb' \
		'spec:' \
		'  replicas: 1' \
		'  selector:' \
		'    matchLabels:' \
		'      app: mariadb' \
		'  template:' \
		'    metadata:' \
		'      labels:' \
		'        app: mariadb' \
		'    spec:' \
		'      containers:' \
		'      - name: mariadb' \
		'        image: mariadb:10.11' \
		'        env:' \
		'        - name: MYSQL_ROOT_PASSWORD' \
		'          value: "rootpassword"' \
		'        - name: MYSQL_DATABASE' \
		'          value: "mydb"' \
		'        ports:' \
		'        - containerPort: 3306' \
		'        volumeMounts:' \
		'        - name: mariadb-data' \
		'          mountPath: /var/lib/mysql' \
		'      volumes:' \
		'      - name: mariadb-data' \
		'        # PVC will be added as part of the solution' \
		'        # persistentVolumeClaim:' \
		'        #   claimName: mariadb' \
		> $(DEPLOYMENT_FILE)
	@echo "   ✅ Deployment file created at $(DEPLOYMENT_FILE)"
	@echo "\n⏳ Waiting for PersistentVolume to be available..."
	sleep 2
	@echo "✅ Environment setup complete.\n"

# =========================
# Solution Application
# =========================
.PHONY: solution
solution:
	@echo "\n🚀 Applying solution:"
	@echo "\n   Step 0: Ensuring namespace exists..."
	-kubectl create ns $(NAMESPACE) --dry-run=client -o yaml | kubectl apply -f -
	@echo "\n   Step 1: Cleaning up any existing PVC and ensuring PV is available..."
	-kubectl delete pvc $(PVC_NAME) -n $(NAMESPACE) --ignore-not-found 2>/dev/null || true
	@echo "   Waiting for PVC deletion to complete..."
	-sleep 3
	@echo "   Clearing PV claimRef..."
	-kubectl patch pv $(PV_NAME) --type=merge -p='{"spec":{"claimRef":null}}' --ignore-not-found 2>/dev/null || true
	@echo "   Waiting for PV to become Available..."
	@for i in 1 2 3 4 5 6 7 8 9 10; do \
		PV_STATUS=$$(kubectl get pv $(PV_NAME) -o jsonpath='{.status.phase}' 2>/dev/null || echo "Unknown"); \
		if [ "$$PV_STATUS" = "Available" ]; then \
			echo "   ✅ PV is Available"; \
			break; \
		fi; \
		if [ $$i -eq 5 ]; then \
			echo "   Retrying patch (attempt 2)..."; \
			kubectl patch pv $(PV_NAME) --type=merge -p='{"spec":{"claimRef":null}}' 2>/dev/null || true; \
		fi; \
		if [ $$i -eq 10 ]; then \
			echo "   ⚠️  PV still not Available after 20 seconds, trying alternative method..."; \
			kubectl get pv $(PV_NAME) -o json 2>/dev/null | sed 's/"claimRef":{[^}]*},//' | kubectl replace -f - 2>/dev/null || \
			kubectl patch pv $(PV_NAME) --type=merge -p='{"spec":{"claimRef":null}}' 2>/dev/null || true; \
			sleep 3; \
			PV_STATUS=$$(kubectl get pv $(PV_NAME) -o jsonpath='{.status.phase}' 2>/dev/null || echo "Unknown"); \
			if [ "$$PV_STATUS" = "Available" ]; then \
				echo "   ✅ PV is now Available"; \
				break; \
			else \
				echo "   ⚠️  PV status is still '$$PV_STATUS', proceeding anyway..."; \
			fi; \
		fi; \
		if [ $$i -lt 10 ]; then \
			echo "   Waiting for PV to become Available (current: $$PV_STATUS, attempt $$i/10)..."; \
			sleep 2; \
		fi; \
	done
	@echo "\n   Task 1: Creating PersistentVolumeClaim '$(PVC_NAME)'..."
	@echo "apiVersion: v1" > /tmp/pvc-$(PVC_NAME).yaml && \
	echo "kind: PersistentVolumeClaim" >> /tmp/pvc-$(PVC_NAME).yaml && \
	echo "metadata:" >> /tmp/pvc-$(PVC_NAME).yaml && \
	echo "  name: mariadb" >> /tmp/pvc-$(PVC_NAME).yaml && \
	echo "  namespace: mariadb" >> /tmp/pvc-$(PVC_NAME).yaml && \
	echo "spec:" >> /tmp/pvc-$(PVC_NAME).yaml && \
	echo "  accessModes:" >> /tmp/pvc-$(PVC_NAME).yaml && \
	echo "    - ReadWriteOnce" >> /tmp/pvc-$(PVC_NAME).yaml && \
	echo "  storageClassName: manual" >> /tmp/pvc-$(PVC_NAME).yaml && \
	echo "  resources:" >> /tmp/pvc-$(PVC_NAME).yaml && \
	echo "    requests:" >> /tmp/pvc-$(PVC_NAME).yaml && \
	echo "      storage: 250Mi" >> /tmp/pvc-$(PVC_NAME).yaml && \
	kubectl apply -f /tmp/pvc-$(PVC_NAME).yaml && \
	rm -f /tmp/pvc-$(PVC_NAME).yaml
	@echo "\n   Task 2: Updating deployment file to use PVC..."
	@if [ -f $(DEPLOYMENT_FILE) ]; then \
		sed -i.bak '/# PVC will be added/,/#   claimName: mariadb/d' $(DEPLOYMENT_FILE) && \
		awk '/^      volumeMounts:/ { in_volumemounts=1; print; next } \
		     /^      volumes:/ { in_volumemounts=0; in_volumes=1; print; next } \
		     in_volumes && /- name: mariadb-data$$/ && !added_pvc { print; print "        persistentVolumeClaim:"; print "          claimName: mariadb"; added_pvc=1; in_volumes=0; next } \
		     /^      [a-z]/ && !/^      volumes:/ && !/^      volumeMounts:/ { in_volumes=0; in_volumemounts=0 } \
		     { print }' $(DEPLOYMENT_FILE) > $(DEPLOYMENT_FILE).tmp && \
		mv $(DEPLOYMENT_FILE).tmp $(DEPLOYMENT_FILE) && \
		rm -f $(DEPLOYMENT_FILE).bak && \
		echo "   ✅ Deployment file updated"; \
	else \
		echo "   ⚠️  Deployment file not found, creating it..."; \
		$(MAKE) setup; \
		sed -i.bak '/# PVC will be added/,/#   claimName: mariadb/d' $(DEPLOYMENT_FILE) && \
		awk '/^      volumeMounts:/ { in_volumemounts=1; print; next } \
		     /^      volumes:/ { in_volumemounts=0; in_volumes=1; print; next } \
		     in_volumes && /- name: mariadb-data$$/ && !added_pvc { print; print "        persistentVolumeClaim:"; print "          claimName: mariadb"; added_pvc=1; in_volumes=0; next } \
		     /^      [a-z]/ && !/^      volumes:/ && !/^      volumeMounts:/ { in_volumes=0; in_volumemounts=0 } \
		     { print }' $(DEPLOYMENT_FILE) > $(DEPLOYMENT_FILE).tmp && \
		mv $(DEPLOYMENT_FILE).tmp $(DEPLOYMENT_FILE) && \
		rm -f $(DEPLOYMENT_FILE).bak; \
	fi
	@echo "\n   Task 3: Applying updated deployment..."
	kubectl apply -f $(DEPLOYMENT_FILE)
	@echo "\n   Task 4: Waiting for deployment to be running and stable..."
	kubectl -n $(NAMESPACE) rollout status deploy/$(DEPLOYMENT_NAME) --timeout=120s
	@echo "\n✅ Solution applied. Run 'make verify' to confirm.\n"

.PHONY: create-pvc
create-pvc:
	@echo "\n🔧 Creating PersistentVolumeClaim..."
	@echo "apiVersion: v1" > /tmp/pvc-$(PVC_NAME).yaml && \
	echo "kind: PersistentVolumeClaim" >> /tmp/pvc-$(PVC_NAME).yaml && \
	echo "metadata:" >> /tmp/pvc-$(PVC_NAME).yaml && \
	echo "  name: mariadb" >> /tmp/pvc-$(PVC_NAME).yaml && \
	echo "  namespace: mariadb" >> /tmp/pvc-$(PVC_NAME).yaml && \
	echo "spec:" >> /tmp/pvc-$(PVC_NAME).yaml && \
	echo "  accessModes:" >> /tmp/pvc-$(PVC_NAME).yaml && \
	echo "    - ReadWriteOnce" >> /tmp/pvc-$(PVC_NAME).yaml && \
	echo "  storageClassName: manual" >> /tmp/pvc-$(PVC_NAME).yaml && \
	echo "  resources:" >> /tmp/pvc-$(PVC_NAME).yaml && \
	echo "    requests:" >> /tmp/pvc-$(PVC_NAME).yaml && \
	echo "      storage: 250Mi" >> /tmp/pvc-$(PVC_NAME).yaml && \
	kubectl apply -f /tmp/pvc-$(PVC_NAME).yaml && \
	rm -f /tmp/pvc-$(PVC_NAME).yaml
	@echo "✅ PVC created.\n"

.PHONY: update-deployment
update-deployment:
	@echo "\n🔧 Updating deployment file to use PVC..."
	@if [ -f $(DEPLOYMENT_FILE) ]; then \
		sed -i.bak '/# PVC will be added/,/#   claimName: mariadb/d' $(DEPLOYMENT_FILE) && \
		awk '/^      volumeMounts:/ { in_volumemounts=1; print; next } \
		     /^      volumes:/ { in_volumemounts=0; in_volumes=1; print; next } \
		     in_volumes && /- name: mariadb-data$$/ && !added_pvc { print; print "        persistentVolumeClaim:"; print "          claimName: mariadb"; added_pvc=1; in_volumes=0; next } \
		     /^      [a-z]/ && !/^      volumes:/ && !/^      volumeMounts:/ { in_volumes=0; in_volumemounts=0 } \
		     { print }' $(DEPLOYMENT_FILE) > $(DEPLOYMENT_FILE).tmp && \
		mv $(DEPLOYMENT_FILE).tmp $(DEPLOYMENT_FILE) && \
		rm -f $(DEPLOYMENT_FILE).bak && \
		echo "✅ Deployment file updated"; \
	else \
		echo "❌ Deployment file not found at $(DEPLOYMENT_FILE)"; \
		exit 1; \
	fi

.PHONY: apply-deployment
apply-deployment:
	@echo "\n🔧 Applying deployment..."
	kubectl apply -f $(DEPLOYMENT_FILE)
	@echo "✅ Deployment applied.\n"

# =========================
# Verification
# =========================
.PHONY: status
status:
	@echo "\n📊 $(QUESTION) Environment Summary:"
	@echo "\nNamespace:"
	kubectl get ns $(NAMESPACE)
	@echo "\nPersistentVolume:"
	kubectl get pv $(PV_NAME) 2>/dev/null || echo "   PV not found"
	@echo "\nPersistentVolumeClaim:"
	kubectl -n $(NAMESPACE) get pvc $(PVC_NAME) 2>/dev/null || echo "   PVC not found"
	@echo "\nDeployment:"
	kubectl -n $(NAMESPACE) get deploy $(DEPLOYMENT_NAME) 2>/dev/null || echo "   Deployment not found"
	@echo "\nPods:"
	kubectl -n $(NAMESPACE) get pods -l app=$(DEPLOYMENT_NAME) 2>/dev/null || echo "   No pods found"
	@echo "\nDeployment file:"
	@if [ -f $(DEPLOYMENT_FILE) ]; then \
		echo "   ✅ $(DEPLOYMENT_FILE) exists"; \
	else \
		echo "   ❌ $(DEPLOYMENT_FILE) not found"; \
	fi

.PHONY: verify
verify:
	@echo "\n🔍 Verifying solution..."
	@echo "\n1. Checking PersistentVolume exists:"
	@kubectl get pv $(PV_NAME) >/dev/null 2>&1 && \
		echo "   ✅ PersistentVolume '$(PV_NAME)' exists" || \
		echo "   ❌ PersistentVolume '$(PV_NAME)' not found"
	@echo "\n2. Checking PersistentVolumeClaim exists:"
	@kubectl -n $(NAMESPACE) get pvc $(PVC_NAME) >/dev/null 2>&1 && \
		echo "   ✅ PVC '$(PVC_NAME)' exists" || \
		echo "   ❌ PVC '$(PVC_NAME)' not found"
	@echo "\n3. Checking PVC specifications:"
	@PVC_ACCESS=$$(kubectl -n $(NAMESPACE) get pvc $(PVC_NAME) -o jsonpath='{.spec.accessModes[0]}' 2>/dev/null); \
	if [ "$$PVC_ACCESS" = "$(ACCESS_MODE)" ]; then \
		echo "   ✅ Access mode is $(ACCESS_MODE)"; \
	else \
		echo "   ⚠️  Access mode is '$$PVC_ACCESS' (expected $(ACCESS_MODE))"; \
	fi
	@PVC_SIZE=$$(kubectl -n $(NAMESPACE) get pvc $(PVC_NAME) -o jsonpath='{.spec.resources.requests.storage}' 2>/dev/null); \
	if [ "$$PVC_SIZE" = "$(STORAGE_SIZE)" ]; then \
		echo "   ✅ Storage size is $(STORAGE_SIZE)"; \
	else \
		echo "   ⚠️  Storage size is '$$PVC_SIZE' (expected $(STORAGE_SIZE))"; \
	fi
	@echo "\n4. Checking PVC is bound to PV:"
	@PVC_STATUS=$$(kubectl -n $(NAMESPACE) get pvc $(PVC_NAME) -o jsonpath='{.status.phase}' 2>/dev/null); \
	if [ "$$PVC_STATUS" = "Bound" ]; then \
		echo "   ✅ PVC is bound"; \
		BOUND_PV=$$(kubectl -n $(NAMESPACE) get pvc $(PVC_NAME) -o jsonpath='{.spec.volumeName}' 2>/dev/null); \
		echo "   Bound to PV: $$BOUND_PV"; \
	else \
		echo "   ⚠️  PVC status is '$$PVC_STATUS' (expected Bound)"; \
	fi
	@echo "\n5. Checking deployment file exists:"
	@if [ -f $(DEPLOYMENT_FILE) ]; then \
		echo "   ✅ Deployment file exists at $(DEPLOYMENT_FILE)"; \
	else \
		echo "   ❌ Deployment file not found"; \
	fi
	@echo "\n6. Checking deployment file references PVC:"
	@if [ -f $(DEPLOYMENT_FILE) ]; then \
		if grep -q "claimName: $(PVC_NAME)" $(DEPLOYMENT_FILE); then \
			echo "   ✅ Deployment file references PVC '$(PVC_NAME)'"; \
		else \
			echo "   ❌ Deployment file does not reference PVC"; \
		fi; \
	fi
	@echo "\n7. Checking deployment exists:"
	@kubectl -n $(NAMESPACE) get deploy $(DEPLOYMENT_NAME) >/dev/null 2>&1 && \
		echo "   ✅ Deployment '$(DEPLOYMENT_NAME)' exists" || \
		echo "   ❌ Deployment '$(DEPLOYMENT_NAME)' not found"
	@echo "\n8. Checking deployment is running:"
	@REPLICAS=$$(kubectl -n $(NAMESPACE) get deploy $(DEPLOYMENT_NAME) -o jsonpath='{.status.replicas}' 2>/dev/null); \
	READY=$$(kubectl -n $(NAMESPACE) get deploy $(DEPLOYMENT_NAME) -o jsonpath='{.status.readyReplicas}' 2>/dev/null); \
	if [ "$$READY" = "1" ] && [ "$$REPLICAS" = "1" ]; then \
		echo "   ✅ Deployment is running ($$READY/$$REPLICAS replicas ready)"; \
	else \
		echo "   ⚠️  Deployment status: $$READY/$$REPLICAS replicas ready"; \
	fi
	@echo "\n9. Checking pods are running:"
	@POD_STATUS=$$(kubectl -n $(NAMESPACE) get pods -l app=$(DEPLOYMENT_NAME) -o jsonpath='{.items[0].status.phase}' 2>/dev/null); \
	if [ "$$POD_STATUS" = "Running" ]; then \
		echo "   ✅ Pod is running"; \
	else \
		echo "   ⚠️  Pod status: $$POD_STATUS"; \
	fi
	@echo "\n10. Checking deployment is stable:"
	@kubectl -n $(NAMESPACE) rollout status deploy/$(DEPLOYMENT_NAME) --timeout=5s >/dev/null 2>&1 && \
		echo "   ✅ Deployment is stable" || \
		echo "   ⚠️  Deployment may still be rolling out"
	@echo "\n✅ Verification complete.\n"

.PHONY: show-pvc
show-pvc:
	@echo "\n📋 PersistentVolumeClaim details:"
	kubectl -n $(NAMESPACE) get pvc $(PVC_NAME) -o yaml || echo "   PVC not found"

.PHONY: show-deployment-file
show-deployment-file:
	@echo "\n📋 Deployment file contents:"
	@if [ -f $(DEPLOYMENT_FILE) ]; then \
		cat $(DEPLOYMENT_FILE); \
	else \
		echo "   File not found at $(DEPLOYMENT_FILE)"; \
	fi

# =========================
# Cleanup
# =========================
.PHONY: clean
clean:
	@echo "\n🧹 Cleaning up $(QUESTION) lab resources..."
	@echo "→ Deleting deployment..."
	-kubectl delete deploy $(DEPLOYMENT_NAME) -n $(NAMESPACE) --ignore-not-found
	@echo "→ Deleting PVC..."
	-kubectl delete pvc $(PVC_NAME) -n $(NAMESPACE) --ignore-not-found
	@echo "→ Waiting for PVC deletion to complete..."
	-sleep 3
	@echo "→ Deleting PersistentVolume..."
	-kubectl delete pv $(PV_NAME) --ignore-not-found
	@echo "→ Deleting namespace..."
	-kubectl delete ns $(NAMESPACE) --ignore-not-found
	@echo "→ Removing deployment file..."
	-rm -f $(DEPLOYMENT_FILE)
	@echo "→ Note: PV will be recreated on next 'make setup'"
	@echo "✅ Cleanup completed for $(QUESTION).\n"

