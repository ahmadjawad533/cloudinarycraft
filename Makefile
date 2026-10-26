.PHONY: help build up down restart logs test monitor-up monitor-down k8s-validate health clean dev

# Colors for terminal styling
YELLOW := \033[1;33m
GREEN  := \033[1;32m
CYAN   := \033[1;36m
RESET  := \033[0m

help: ## Show this help menu
	@echo -e "$(CYAN)=====================================================================$(RESET)"
	@echo -e "$(CYAN)       CloudiCraft Studio - Enterprise DevOps Command Center        $(RESET)"
	@echo -e "$(CYAN)=====================================================================$(RESET)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "$(GREEN)%-18s$(RESET) %s\n", $$1, $$2}'

build: ## Build all Docker container images locally
	@echo -e "$(YELLOW)Building production container images...$(RESET)"
	docker compose build

up: ## Start the full production stack with health checks
	@echo -e "$(YELLOW)Starting CloudiCraft Studio cluster...$(RESET)"
	docker compose up -d
	@echo -e "$(GREEN)Stack running at http://localhost$(RESET)"

down: ## Stop all running stack containers
	@echo -e "$(YELLOW)Stopping cluster containers...$(RESET)"
	docker compose down

restart: down up ## Restart the stack

logs: ## Follow live logs across all containers
	docker compose logs -f

test: ## Run backend unit and integration test suite
	@echo -e "$(YELLOW)Running backend test suite...$(RESET)"
	npm --prefix server test

dev: ## Launch development stack with live hot-reloading
	@echo -e "$(YELLOW)Launching live development environment...$(RESET)"
	docker compose -f docker-compose.yml -f docker-compose.dev.yml up

monitor-up: ## Start Prometheus and Grafana monitoring stack
	@echo -e "$(YELLOW)Starting Observability Stack (Prometheus & Grafana)...$(RESET)"
	docker compose -f docker-compose.monitoring.yml up -d
	@echo -e "$(GREEN)Prometheus running at http://localhost:9090$(RESET)"
	@echo -e "$(GREEN)Grafana running at http://localhost:3001 (admin/admin)$(RESET)"

monitor-down: ## Stop monitoring stack
	docker compose -f docker-compose.monitoring.yml down

health: ## Probe application and reverse proxy health status
	@bash ./scripts/devops/health-check.sh

k8s-validate: ## Validate Kubernetes YAML manifests
	@bash ./scripts/devops/validate-k8s.sh

clean: ## Prune dangling Docker containers, networks, and unused volumes
	@echo -e "$(YELLOW)Cleaning up Docker resources...$(RESET)"
	docker compose down -v --remove-orphans
