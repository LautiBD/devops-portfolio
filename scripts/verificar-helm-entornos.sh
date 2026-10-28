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
    STATUS=$(helm list -n "$NS" -q | grep -E "^${NAME}$" >/dev/null && echo "deployed" || echo "NOT_FOUND")
    if [ "$STATUS" = "deployed" ]; then
        ok "Release '$NAME' en namespace '$NS' -> $STATUS"
    else
        fail "Release '$NAME' en namespace '$NS' -> $STATUS"
    fi
done

info "2. Verificación de Ingress Activos"
for ns in staging production; do
    eval_check
    ING_COUNT=$(kubectl get ingress -n "$ns" --no-headers 2>/dev/null | wc -l || echo "0")
    if [ "$ING_COUNT" -gt 0 ]; then
        ok "Ingress detectado en namespace '$ns'"
    else
        fail "No se encontró Ingress en namespace '$ns'"
    fi
done

info "3. Resumen Final de Auditoría"
echo "  Pruebas pasadas: $PASSED / $TOTAL"
if [ "$PASSED" -eq "$TOTAL" ]; then
    echo -e "\n\033[1;32m¡FELICITACIONES! TP10 COMPLETADO CON ÉXITO.\033[0m\n"
else
    echo -e "\n\033[1;31mSe encontraron fallos en la verificación.\033[0m\n"
    exit 1
fi
