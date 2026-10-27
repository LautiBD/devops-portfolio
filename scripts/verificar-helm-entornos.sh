#!/bin/bash
set -euo pipefail
TOTAL=0
PASSED=0
ok()   { echo -e "  \033[0;32m[PASS]\033[0m $1"; PASSED=$((PASSED+1)); }
fail() { echo -e "  \033[0;31m[FAIL]\033[0m $1"; }
info() { echo -e "\n\033[1;34m=== $1 ===\033[0m"; }
eval_check() { TOTAL=$((TOTAL+1)); }
echo -e "\033[1;36m"
echo "  =============================================================="
echo "    AUDITORÍA MULTI-ENTORNO CON HELM & INGRESS (TP10C)"
echo "  =============================================================="
echo -e "\033[0m"
info "1. Verificación de Releases de Helm Activos"
for rel in "notes-staging:staging" "notes-prod:production"; do
    NAME=$(echo "$rel" | cut -d':' -f1)
    NS=$(echo "$rel" | cut -d':' -f2)
    eval_check
    STATUS=$(helm status "$NAME" -n "$NS" 2>/dev/null | grep STATUS | awk '{print $2}' || echo "NOT_FOUND")
    if [ "$STATUS" = "deployed" ]; then
        ok "Release '$NAME' en namespace '$NS' -> $STATUS"
    else
        fail "Release '$NAME' en namespace '$NS' -> $STATUS"
    fi
done
