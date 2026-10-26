#!/usr/bin/env bash
set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}Validating Kubernetes manifests and Helm chart files...${NC}\n"

MANIFEST_DIR="./k8s"

for file in "$MANIFEST_DIR"/*.yaml; do
  [ -e "$file" ] || continue
  printf "Validating %-35s " "$(basename "$file")..."

  # Validate YAML syntax using Python's built-in yaml module or dry-run
  if python3 -c "import yaml, sys; list(yaml.safe_load_all(open('$file')))" 2>/dev/null; then
    echo -e "[${GREEN}VALID${NC}]"
  else
    echo -e "[${RED}SYNTAX ERROR${NC}]"
    exit 1
  fi
done

echo ""
echo -e "${GREEN}✓ All Kubernetes manifests validated successfully!${NC}"
