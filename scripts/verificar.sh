#!/bin/bash
set -uo pipefail
NS="devops-portfolio"
ERRORS=0
ok()   { echo -e "  \033[0;32m[OK]\033[0m   $1"; }
fail() { echo -e "  \033[0;31m[FAIL]\033[0m $1"; ERRORS=$((ERRORS+1)); }

echo "================================================="
echo "  VERIFICACIÓN HELM & INGRESS (TP10 / TP10B)"
echo "================================================="
echo ""
echo "--- 1. Validación de Renderizado (Render First) ---"
if helm template test-release ./devops-portfolio -f devops-portfolio/values-prod.yaml > /tmp/test-rendered.yaml 2>/dev/null; then
  ok "Renderizado de plantillas Go completado exitosamente"
  if python3 -c "import yaml; list(yaml.safe_load_all(open('/tmp/test-rendered.yaml')))" 2>/dev/null; then
    ok "Sintaxis YAML del manifiesto renderizado correcta"
  else
    fail "Error de sintaxis en el YAML renderizado"
  fi
else
  fail "Error al ejecutar helm template"
fi

echo ""
echo "--- 2. Estado del Release de Helm ---"
if helm list -n "$NS" -q | grep -E "^mi-app$" >/dev/null; then
  ok "Release 'mi-app' -> deployed"
else
  fail "Release 'mi-app' no encontrado o no desplegado en el namespace $NS"
fi

echo ""
echo "--- 3. Pods en Kubernetes ---"
kubectl get pods -n $NS --no-headers 2>/dev/null | while read line; do
  NAME=$(echo $line   | awk '{print $1}')
  STATUS=$(echo $line | awk '{print $3}')
  READY=$(echo $line  | awk '{print $2}')
  if [ "$STATUS" = "Running" ]; then
    ok "$NAME -> $STATUS ($READY)"
  else
    fail "$NAME -> $STATUS ($READY)"
  fi
done

echo ""
echo "--- 4. Ingress y Enrutamiento Capa 7 ---"
kubectl get ingress -n $NS --no-headers 2>/dev/null | while read line; do
  NAME=$(echo $line | awk '{print $1}')
  HOST=$(echo $line | awk '{print $3}')
  ok "Ingress '$NAME' configurado para host: $HOST"
done

echo ""
if [ "$ERRORS" -eq 0 ]; then
  echo "=== TP10 / TP10B OK: Todos los checks pasaron ==="
else
  echo "=== ATENCIÓN: $ERRORS checks fallaron ==="
fi
