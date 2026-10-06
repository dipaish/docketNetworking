#!/bin/bash
set -euo pipefail

# Check for required commands
for cmd in docker curl grep; do
  if ! command -v "$cmd" > /dev/null 2>&1; then
    echo "❌ Required command '$cmd' not found. Please install it before running this script."
    exit 1
  fi
done

echo "🔍 Running Lab Checks..."
echo "----------------------------------"

PASS_COUNT=0
FAIL_COUNT=0
LOGFILE=$(mktemp)

# Cleanup temp file on exit
trap 'rm -f "$LOGFILE"' EXIT

check_pass() {
  local msg="PASS: $1"
  echo -e "\033[1;32m✅ ${msg}\033[0m"
  echo "    ${msg}" >> "$LOGFILE"
  PASS_COUNT=$((PASS_COUNT+1))
}

check_fail() {
  local msg="FAIL: $1"
  echo -e "\033[1;31m❌ ${msg}\033[0m"
  echo "    ${msg}" >> "$LOGFILE"
  FAIL_COUNT=$((FAIL_COUNT+1))
}

# -----------------------------
# 0. Get GitHub username
# -----------------------------

if [ -n "${GITHUB_USER:-}" ]; then
  # Codespaces sets GITHUB_USER natively
  :
elif [ -n "${CODESPACE_NAME:-}" ] && command -v gh > /dev/null 2>&1; then
  GITHUB_USER="$(gh api user --jq .login 2>/dev/null || echo "unknown")"
elif [ -n "${USER:-}" ]; then
  GITHUB_USER="$USER"
else
  GITHUB_USER="unknown"
fi

# -----------------------------
# 1. Check Docker is running
# -----------------------------

if docker ps > /dev/null 2>&1; then
  check_pass "Docker is running"
else
  check_fail "Docker is NOT running"
  echo "Docker is not running, cannot continue checks."
  exit 1
fi

# -----------------------------
# 2. Check ubuntu image pulled
# -----------------------------

if docker images | grep -q "ubuntu.*focal"; then
  check_pass "Ubuntu image (focal) exists"
else
  check_fail "Ubuntu image not found"
fi

# -----------------------------
# 3. Check first container exists
# -----------------------------

if docker ps -a | grep -q "csf-ubuntu1"; then
  check_pass "Container csf-ubuntu1 exists"
else
  check_fail "csf-ubuntu1 missing"
fi

# -----------------------------
# 4. Check second container exists
# -----------------------------

if docker ps -a | grep -q "csf-ubuntu2"; then
  check_pass "Container csf-ubuntu2 exists"
else
  check_fail "csf-ubuntu2 missing"
fi

# -----------------------------
# 5. Check containers running
# -----------------------------

RUNNING=$(docker ps --format '{{.Names}}' | grep -cE "csf-ubuntu1|csf-ubuntu2" || true)
if [ "$RUNNING" -ge 2 ]; then
  check_pass "Both containers are running"
else
  check_fail "Containers are not running properly"
fi

# -----------------------------
# 6. Check custom bridge network exists
# -----------------------------

if docker network ls | grep -q "csf-net"; then
  check_pass "Custom bridge network 'csf-net' exists"
else
  check_fail "Custom bridge network 'csf-net' missing"
fi

# -----------------------------
# 7. Check containers are on csf-net
# -----------------------------

ON_NET1=$(docker inspect -f '{{range $k,$v := .NetworkSettings.Networks}}{{if eq $k "csf-net"}}yes{{end}}{{end}}' csf-ubuntu1 2>/dev/null || true)
ON_NET2=$(docker inspect -f '{{range $k,$v := .NetworkSettings.Networks}}{{if eq $k "csf-net"}}yes{{end}}{{end}}' csf-ubuntu2 2>/dev/null || true)
if [ "$ON_NET1" = "yes" ] && [ "$ON_NET2" = "yes" ]; then
  check_pass "Both containers are attached to 'csf-net'"
else
  check_fail "Containers are not both on 'csf-net'"
fi

# -----------------------------
# 8. Check networking (ping)
# -----------------------------

IP=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' csf-ubuntu1 2>/dev/null || true)
if [ -z "$IP" ]; then
  check_fail "Could not retrieve IP of csf-ubuntu1"
else
  if docker exec csf-ubuntu2 ping -c 1 "$IP" > /dev/null 2>&1; then
    check_pass "Container-to-container ping works"
  else
    check_fail "Ping between containers failed"
  fi
fi

# -----------------------------
# 9. Check nginx container
# -----------------------------

if docker ps | grep -q "csf-nginx"; then
  check_pass "Nginx container is running"
else
  check_fail "Nginx container not running"
fi

# -----------------------------
# 10. Check port 8080
# -----------------------------

if curl -s http://localhost:8080 | grep -q "Welcome to nginx"; then
  check_pass "Nginx web server accessible on port 8080"
else
  check_fail "Cannot access nginx on port 8080"
fi

# -----------------------------
# Summary
# -----------------------------

echo "----------------------------------"
echo -e "\033[1m🎯 RESULTS:\033[0m"
echo -e "\033[1;32mPassed: $PASS_COUNT\033[0m"
echo -e "\033[1;31mFailed: $FAIL_COUNT\033[0m"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo -e "\033[1;32m🏆 All checks passed! Lab complete.\033[0m"
else
  echo -e "\033[1;33m⚠️ Some checks failed. Review your steps.\033[0m"
fi

# Write marksheet from actual runtime results
MARKSHEET=marksheet.md
{
  echo "# Lab Marksheet"
  echo "- **GitHub Username:** $GITHUB_USER"
  echo "- **Passed:** $PASS_COUNT"
  echo "- **Failed:** $FAIL_COUNT"
  echo ""
  echo "## Check Results"
  cat "$LOGFILE"
} > "$MARKSHEET"
echo "Marksheet written to $MARKSHEET"