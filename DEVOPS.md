# CloudiCraft Studio - Enterprise DevOps Operations Guide & Runbook

This document details the complete DevOps architecture, containerization strategy, multi-environment orchestration, GitOps CI/CD pipelines, Kubernetes manifests, Helm packaging, Terraform Infrastructure-as-Code, and Prometheus/Grafana observability stack for **CloudiCraft Studio**.

---

## 1. System Architecture

```
                                  +------------------------------------+
                                  |           Internet Traffic         |
                                  +-----------------+------------------+
                                                    |
                                                    v
                                  +------------------------------------+
                                  |      Nginx Edge Reverse Proxy      |
                                  |     (Port 80 / 443, Rate Limited)  |
                                  +--------+------------------+--------+
                                           |                  |
                       Path: /             |                  |  Path: /api/*, /metrics
                                           v                  v
                    +---------------------------+    +---------------------------+
                    |    Frontend Container     |    |     Backend Container     |
                    |  React 18 + Vite (SPA)    |    |   Express REST API :5001  |
                    |  Nginx Alpine Runtime     |    |   Node 20 Alpine + Init   |
                    +---------------------------+    +-------------+-------------+
                                                                   |
                                                                   v
                                                     +---------------------------+
                                                     |      Redis Cache :6379    |
                                                     |  In-Memory Sessions & PVC |
                                                     +---------------------------+
```

### Key Engineering Features:
- **Zero-Downtime Deployments**: Kubernetes `RollingUpdate` with `maxSurge: 1`, `maxUnavailable: 0` and PodDisruptionBudgets (`PDB`).
- **Security Hardening**:
  - Non-root user execution (`UID 1000` / `node`, `nginx`).
  - Read-only root filesystems where applicable with dropped Linux capabilities (`ALL`).
  - Zero-trust Kubernetes NetworkPolicies restricting inter-service communication.
  - Multi-stage Docker builds stripping dev dependencies and minimizing attack surface.
  - Rate limiting on API paths (`limit_req_zone` 20 req/s with burst allowance).
- **Signal Handling**: Express backend leverages `dumb-init` as PID 1 to gracefully trap `SIGTERM`/`SIGINT` for instant, non-blocking zero-downtime container termination.
- **Full Observability**: Prometheus scraping Node.js event loop, memory, CPU, and custom HTTP request duration histograms; pre-built Grafana executive dashboards.

---

## 2. Directory Structure

```
├── .github/
│   └── workflows/
│       ├── ci.yml                 # Matrix testing, linting, and build verification
│       ├── security-scan.yml      # Trivy CVE & GitLeaks secret scanner
│       ├── docker-build-push.yml  # Multi-arch Buildx push to GHCR
│       └── cd-deploy.yml          # Automated Kubernetes GitOps CD rollout
├── client/
│   ├── Dockerfile                 # Multi-stage React Vite build -> Nginx Alpine
│   ├── nginx.conf                 # SPA routing & caching headers
│   └── .dockerignore
├── server/
│   ├── Dockerfile                 # Multi-stage Node 20 Alpine + dumb-init
│   ├── test/                      # Node.js native integration & health tests
│   └── .dockerignore
├── nginx/
│   ├── Dockerfile                 # Edge reverse proxy container
│   └── nginx.conf                 # Upstreams, rate limits, and security headers
├── k8s/
│   ├── namespace.yaml             # cloudicraft-studio namespace
│   ├── resource-quota.yaml        # CPU/Memory resource quotas & limits
│   ├── configmap.yaml             # Environment configuration
│   ├── secret.yaml.example        # Secrets template
│   ├── backend-deployment.yaml    # 2-replica Express backend with probes
│   ├── backend-service.yaml       # ClusterIP service
│   ├── backend-hpa.yaml           # Autoscaling 2 to 10 pods
│   ├── backend-pdb.yaml           # PodDisruptionBudget
│   ├── frontend-deployment.yaml   # React SPA deployment
│   ├── frontend-service.yaml      # ClusterIP service
│   ├── frontend-hpa.yaml          # Autoscaling 2 to 8 pods
│   ├── redis-deployment.yaml      # Stateful Redis with PersistentVolumeClaim
│   ├── ingress.yaml               # TLS Cert-Manager Ingress
│   └── network-policy.yaml        # Zero-trust network segmentation
├── helm/
│   └── cloudicraft/               # Production Helm 3 chart package
│       ├── Chart.yaml
│       ├── values.yaml
│       └── templates/
├── terraform/
│   ├── main.tf                    # AWS root composition
│   ├── variables.tf
│   ├── outputs.tf
│   ├── terraform.tfvars.example
│   └── modules/
│       ├── vpc/                   # Multi-AZ VPC, subnets, NAT Gateway
│       ├── eks/                   # AWS EKS cluster, managed node groups
│       └── ecr/                   # Container registries with vulnerability scanning
├── monitoring/
│   ├── prometheus/
│   │   ├── prometheus.yml         # Scrape targets (App, Node, cAdvisor)
│   │   └── alerts.yml             # Prometheus alert rules (Down, 5xx, Latency)
│   └── grafana/
│       ├── provisioning/          # Datasource & Dashboard providers
│       └── dashboards/
│           └── cloudicraft-overview.json  # Pre-configured Grafana dashboard
├── scripts/
│   └── devops/
│       ├── health-check.sh        # Deployment health probing script
│       ├── validate-k8s.sh        # Kubernetes manifest syntax validator
│       └── generate-certs.sh      # Local SSL generator
├── docker-compose.yml             # Production compose stack
├── docker-compose.dev.yml         # Live hot-reloading development compose
├── docker-compose.monitoring.yml  # Observability compose stack
├── Makefile                       # Single-command operator shortcuts
└── DEVOPS.md                      # DevOps documentation and runbook
```

---

## 3. Quick Start & Local Execution

### Prerequisites:
- Docker Engine & Docker Compose (v2+)
- Node.js 18+ (for local testing)

### 1-Command Operations with `Makefile`:

```bash
# View available commands
make help

# Run test suites locally
make test

# Build all container images
make build

# Start the full stack
make up

# Verify all services are healthy
make health

# Tail real-time logs
make logs

# Start Observability Stack (Prometheus :9090, Grafana :3001)
make monitor-up

# Stop all containers
make down
```

---

## 4. Observability & Monitoring

The monitoring stack provides real-time telemetry across infrastructure and application layers:

| Component | Port | Description | Credentials |
|---|---|---|---|
| **CloudiCraft Studio** | `http://localhost:80` | Frontend SPA + API Reverse Proxy | N/A |
| **Backend API** | `http://localhost:5001` | Direct API Server | N/A |
| **Prometheus** | `http://localhost:9090` | Time-series metrics engine & alerts | N/A |
| **Grafana** | `http://localhost:3001` | SRE Dashboards | `admin` / `admin` |
| **cAdvisor** | `http://localhost:8080` | Container resource telemetry | N/A |
| **Node Exporter** | `http://localhost:9100` | Host hardware & OS metrics | N/A |

### Pre-Configured Alerting Rules (`monitoring/prometheus/alerts.yml`):
- `BackendServiceDown`: Alerts if backend container is unreachable for > 1m.
- `HighHttp5xxErrorRate`: Triggers if 5xx errors exceed 5% of total requests over 5 minutes.
- `HighRequestLatency`: Triggers if P95 response latency exceeds 1.5 seconds.
- `HighMemoryUsage`: Alerts if Node.js process RSS exceeds 400MB.

---

## 5. Kubernetes & Helm Deployment

### Native Kubernetes Manifests:
```bash
# Validate manifests
make k8s-validate

# Deploy namespace and configurations
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/resource-quota.yaml
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/secret.yaml.example

# Deploy Redis, Backend, Frontend, and Ingress
kubectl apply -f k8s/redis-deployment.yaml
kubectl apply -f k8s/backend-deployment.yaml
kubectl apply -f k8s/backend-service.yaml
kubectl apply -f k8s/backend-hpa.yaml
kubectl apply -f k8s/backend-pdb.yaml
kubectl apply -f k8s/frontend-deployment.yaml
kubectl apply -f k8s/frontend-service.yaml
kubectl apply -f k8s/frontend-hpa.yaml
kubectl apply -f k8s/ingress.yaml
kubectl apply -f k8s/network-policy.yaml
```

### Helm 3 Deployment:
```bash
# Dry run template validation
helm template cloudicraft ./helm/cloudicraft

# Install or upgrade release
helm upgrade --install cloudicraft ./helm/cloudicraft \
  --namespace cloudicraft-studio \
  --create-namespace \
  --values ./helm/cloudicraft/values.yaml
```

---

## 6. Infrastructure as Code (Terraform AWS)

```bash
cd terraform

# Initialize providers and modules
terraform init

# Plan infrastructure changes
terraform plan -var-file="terraform.tfvars.example"

# Apply changes to provision VPC, EKS, and ECR
terraform apply -var-file="terraform.tfvars.example"
```

---

## 7. Site Reliability Engineering (SRE) Incident Playbook

### High Latency or 5xx Errors
1. Check Prometheus alert status: `http://localhost:9090/alerts`.
2. Inspect container logs:
   ```bash
   docker compose logs --tail=100 -f backend
   # In Kubernetes:
   kubectl logs -n cloudicraft-studio -l app=cloudicraft-backend --tail=100 -f
   ```
3. Check CPU/Memory saturation:
   ```bash
   kubectl top pods -n cloudicraft-studio
   ```
4. If traffic surge is causing queuing, scale up backend pods:
   ```bash
   kubectl scale deployment backend-deployment -n cloudicraft-studio --replicas=5
   ```

### Rolling Back a Faulty Deployment
If a bad release is deployed in Kubernetes:
```bash
kubectl rollout undo deployment/backend-deployment -n cloudicraft-studio
kubectl rollout status deployment/backend-deployment -n cloudicraft-studio
```
Or via Helm:
```bash
helm rollback cloudicraft <previous-revision-number> -n cloudicraft-studio
```
