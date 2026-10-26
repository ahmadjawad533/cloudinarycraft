#!/usr/bin/env bash
set -e

HOST="${1:-http://localhost}"
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}Probing CloudiCraft Studio services at ${HOST}...${NC}\n"

probe() {
  local name="$1"
  local url="$2"
  local expected_status="${3:-200}"

  printf "Testing %-35s " "$name..."
  local status
  status=$(curl -s -o /dev/null -w "%{http_code}" "$url" || echo "000")

  if [ "$status" -eq "$expected_status" ]; then
    echo -e "[${GREEN}PASS${NC}] (HTTP $status)"
  else
    echo -e "[${RED}FAIL${NC}] (Expected $expected_status, got $status)"
    return 1
  fi
}

FAILED=0

probe "Nginx Edge Gateway Health" "$HOST/gateway-health" 200 || FAILED=1
probe "Backend Liveness Probe"     "$HOST/api/healthz"     200 || FAILED=1
probe "Prometheus Metrics Exporter" "$HOST/metrics"        200 || FAILED=1
probe "Frontend React Application" "$HOST/"                200 || FAILED=1

echo ""
if [ "$FAILED" -eq 0 ]; then
  echo -e "${GREEN}✓ All services are healthy and operational!${NC}"
  exit 0
else
  echo -e "${RED}✗ One or more health checks failed.${NC}"
  exit 1
fi
