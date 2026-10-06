#!/bin/bash
set -euo pipefail

# Check for required commands
for cmd in docker curl grep; do
  if ! command -v "$cmd" > /dev/null 2>&1; then
    echo "❌ Required command '$cmd' not found. Please install it before running this script."
    exit 1
  fi
done

TOTAL_POINTS=6
PASS_COUNT=0
FAIL_COUNT=0
LOGFILE=$(mktemp)

# Cleanup temp file on exit
trap 'rm -f "$LOGFILE"' EXIT

check_pass() {
  local msg="$1"
  echo -e "\033[1;32m✅ PASS:\033[0m $msg"
  echo "- ✅ **PASS:** $msg" >> "$LOGFILE"
  PASS_COUNT=$((PASS_COUNT+1))
}

check_fail() {
  local msg="$1"
  echo -e "\033[1;31m❌ FAIL:\033[0m $msg"
  echo "- ❌ **FAIL:** $msg" >> "$LOGFILE"
  FAIL_COUNT=$((FAIL_COUNT+1))
}

# -----------------------------
# 0. Get GitHub username (if in Codespaces)
# -----------------------------

if [ -n "${GITHUB_USER:-}" ]; then
  : # Codespaces already sets GITHUB_USER natively
elif [ -n "${CODESPACE_NAME:-}" ] && command -v gh > /dev/null 2>&1; then
  GITHUB_USER="$(gh api user --jq .login 2>/dev/null || echo "unknown")"
elif [ -n "${CODESPACE_NAME:-}" ]; then
  GITHUB_USER="$(echo "$CODESPACE_NAME" | cut -d'-' -f1)"
elif [ -n "${USER:-}" ]; then
  GITHUB_USER="$USER"
else
  GITHUB_USER="unknown"
fi

echo "🔍 Running Lab Checks..."
echo "----------------------------------"

# -----------------------------
# Task 1: Docker is running
# -----------------------------

if docker ps > /dev/null 2>&1; then
  check_pass "Task 1: Docker is running"
else
  check_fail "Task 1: Docker is NOT running"
fi

# -----------------------------
# Task 2: Custom bridge network 'csf-net' exists
# -----------------------------

if docker network ls --format '{{.Name}}' | grep -qx "csf-net"; then
  check_pass "Task 2: Custom bridge network 'csf-net' exists"
else
  check_fail "Task 2: Custom bridge network 'csf-net' missing"
fi

# -----------------------------
# Task 3: Both containers exist, are running, and attached to csf-net
# -----------------------------

RUNNING=$(docker ps --format '{{.Names}}' | grep -cE "^(csf-ubuntu1|csf-ubuntu2)$" || true)
ON_NET1=$(docker inspect -f '{{range $k,$v := .NetworkSettings.Networks}}{{if eq $k "csf-net"}}yes{{end}}{{end}}' csf-ubuntu1 2>/dev/null || true)
ON_NET2=$(docker inspect -f '{{range $k,$v := .NetworkSettings.Networks}}{{if eq $k "csf-net"}}yes{{end}}{{end}}' csf-ubuntu2 2>/dev/null || true)
if [ "$RUNNING" -ge 2 ] && [ "$ON_NET1" = "yes" ] && [ "$ON_NET2" = "yes" ]; then
  check_pass "Task 3: csf-ubuntu1 and csf-ubuntu2 are running and attached to 'csf-net'"
else
  check_fail "Task 3: Containers are not both running and attached to 'csf-net'"
fi

# -----------------------------
# Task 4: Container-to-container connectivity (ping)
# -----------------------------

IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' csf-ubuntu1 2>/dev/null || true)
if [ -n "$IP" ] && docker exec csf-ubuntu2 ping -c 1 "$IP" > /dev/null 2>&1; then
  check_pass "Task 4: Container-to-container ping works"
else
  check_fail "Task 4: Ping between containers failed"
fi

# -----------------------------
# Task 5: Nginx container is running
# -----------------------------

if docker ps --format '{{.Names}}' | grep -qx "csf-nginx"; then
  check_pass "Task 5: Nginx container is running"
else
  check_fail "Task 5: Nginx container not running"
fi

# -----------------------------
# Task 6: Nginx web server accessible on port 8080
# -----------------------------

if curl -s http://localhost:8080 | grep -q "Welcome to nginx"; then
  check_pass "Task 6: Nginx web server accessible on port 8080"
else
  check_fail "Task 6: Cannot access nginx on port 8080"
fi

# -----------------------------
# Summary
# -----------------------------

echo "----------------------------------"
echo -e "\033[1m🎯 RESULTS:\033[0m"
echo -e "\033[1;32mPassed: $PASS_COUNT / $TOTAL_POINTS\033[0m"
echo -e "\033[1;31mFailed: $FAIL_COUNT / $TOTAL_POINTS\033[0m"

if [ "$PASS_COUNT" -eq "$TOTAL_POINTS" ]; then
  echo -e "\033[1;32m🏆 All checks passed! Lab complete.\033[0m"
else
  echo -e "\033[1;33m⚠️ Some checks failed. Review your steps.\033[0m"
fi

# Write marksheet from actual runtime results
MARKSHEET=marksheet.md
{
  echo "# Lab Marksheet"
  echo ""
  echo "- **GitHub Username:** $GITHUB_USER"
  echo "- **Score:** $PASS_COUNT / $TOTAL_POINTS"
  echo ""
  echo "## Check Results"
  cat "$LOGFILE"
} > "$MARKSHEET"
echo "Marksheet written to $MARKSHEET"