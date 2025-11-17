# =========================
# CKA LABS - ROOT MAKEFILE
# =========================
# This Makefile orchestrates all CKA lab environments

# Find all Q* directories
Q_DIRS := $(shell find . -maxdepth 1 -type d -name 'Q*' | sort)

# Extract question numbers (Q01, Q02, etc.)
QUESTIONS := $(shell echo $(Q_DIRS) | sed 's|./||g' | tr ' ' '\n' | sort -V)

.PHONY: help all setup clean solution status

# =========================
# Help
# =========================
help:
	@echo "CKA Labs - Root Makefile"
	@echo "========================"
	@echo ""
	@echo "Available targets:"
	@echo "  make setup          - Set up all Q* lab environments (Q14 skipped - needs cluster)"
	@echo "  make setup-Q<num>   - Set up a specific lab (e.g., make setup-Q1)"
	@echo "  make clean          - Clean up all Q* lab environments"
	@echo "  make clean-Q<num>   - Clean up a specific lab (e.g., make clean-Q1)"
	@echo "  make solution-Q<num> - Apply solution to a specific lab"
	@echo "  make status         - Show status of all labs"
	@echo "  make all            - Set up all labs (same as 'make setup')"
	@echo ""
	@echo "Special notes:"
	@echo "  - Q14 requires a kubeadm cluster. Use 'cd Q14 && make setup-cluster'"
	@echo ""
	@echo "Available labs:"
	@for q in $(QUESTIONS); do \
		echo "  - $$q"; \
	done
	@echo ""

# =========================
# Default target
# =========================
all: setup

# =========================
# Set up all labs
# =========================
setup:
	@echo "🚀 Setting up all CKA lab environments..."
	@echo "=========================================="
	@echo ""
	@for q in $(QUESTIONS); do \
		if [ -f "$$q/Makefile" ]; then \
			if [ "$$q" = "Q14" ]; then \
				echo "📦 Setting up $$q (skipping - requires kubeadm cluster)..."; \
				echo "   ℹ️  Q14 requires a kubeadm cluster. Use 'make setup-cluster' in Q14/"; \
			else \
				echo "📦 Setting up $$q..."; \
				$(MAKE) -C $$q setup || echo "   ⚠️  Failed to set up $$q"; \
			fi; \
			echo ""; \
		fi; \
	done
	@echo "✅ All lab environments set up!"
	@echo ""
	@echo "ℹ️  Note: Q14 requires a kubeadm cluster. Use 'make setup-cluster' in Q14/"

# =========================
# Clean all labs
# =========================
clean:
	@echo "🧹 Cleaning up all CKA lab environments..."
	@echo "=========================================="
	@echo ""
	@for q in $(QUESTIONS); do \
		if [ -f "$$q/Makefile" ]; then \
			echo "🗑️  Cleaning up $$q..."; \
			$(MAKE) -C $$q clean || echo "   ⚠️  Failed to clean $$q"; \
			echo ""; \
		fi; \
	done
	@echo "✅ All lab environments cleaned!"

# =========================
# Status of all labs
# =========================
status:
	@echo "📊 Status of all CKA lab environments..."
	@echo "========================================="
	@echo ""
	@for q in $(QUESTIONS); do \
		if [ -f "$$q/Makefile" ]; then \
			echo "📦 $$q:"; \
			if kubectl get ns 2>/dev/null | grep -q "$$(grep '^NAMESPACE' $$q/Makefile | head -1 | cut -d' ' -f3 || echo '')"; then \
				echo "   ✅ Environment exists"; \
			else \
				echo "   ⚪ Not set up"; \
			fi; \
		fi; \
	done
	@echo ""

# =========================
# Dynamic targets for individual labs
# =========================
# Generate setup targets for each Q* directory
define SETUP_TARGET
setup-$(1):
	@echo "🚀 Setting up $(1)..."
	@if [ -f "$(1)/Makefile" ]; then \
		$(MAKE) -C $(1) setup; \
	else \
		echo "   ❌ $(1)/Makefile not found"; \
		exit 1; \
	fi
endef

# Generate clean targets for each Q* directory
define CLEAN_TARGET
clean-$(1):
	@echo "🧹 Cleaning up $(1)..."
	@if [ -f "$(1)/Makefile" ]; then \
		$(MAKE) -C $(1) clean; \
	else \
		echo "   ❌ $(1)/Makefile not found"; \
		exit 1; \
	fi
endef

# Generate solution targets for each Q* directory
define SOLUTION_TARGET
solution-$(1):
	@echo "🔧 Applying solution for $(1)..."
	@if [ -f "$(1)/Makefile" ]; then \
		$(MAKE) -C $(1) solution || echo "   ⚠️  No solution target in $(1)"; \
	else \
		echo "   ❌ $(1)/Makefile not found"; \
		exit 1; \
	fi
endef

# Generate all targets for each Q* directory
$(foreach q,$(QUESTIONS),$(eval $(call SETUP_TARGET,$(q))))
$(foreach q,$(QUESTIONS),$(eval $(call CLEAN_TARGET,$(q))))
$(foreach q,$(QUESTIONS),$(eval $(call SOLUTION_TARGET,$(q))))

