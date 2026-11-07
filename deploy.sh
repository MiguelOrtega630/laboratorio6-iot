#!/usr/bin/env bash
# Despliega WordPress y PrestaShop (cada uno con su BD) en el cluster actual de kubectl.
set -euo pipefail
cd "$(dirname "$0")"

echo ">> Cluster actual: $(kubectl config current-context)"
kubectl apply -f k8s/00-namespaces.yaml

# Los Secrets se crean aqui con claves aleatorias; nunca quedan en un archivo del repo.
# Si ya existen no se tocan (cambiarlos dejaria la BD ya inicializada con otra clave).
mk_secret() {
  local ns="$1" name="$2"
  if kubectl -n "$ns" get secret "$name" >/dev/null 2>&1; then
    echo ">> Secret $ns/$name ya existe, se conserva"
  else
    kubectl -n "$ns" create secret generic "$name" \
      --from-literal=root-password="$(openssl rand -hex 16)" \
      --from-literal=password="$(openssl rand -hex 16)"
  fi
}
mk_secret wordpress  wordpress-db-secret
mk_secret prestashop prestashop-db-secret

echo ">> Bases de datos"
kubectl apply -f k8s/wordpress/db.yaml -f k8s/prestashop/db.yaml
kubectl -n wordpress  rollout status deploy/wordpress-db  --timeout=300s
kubectl -n prestashop rollout status deploy/prestashop-db --timeout=300s

echo ">> Portales"
kubectl apply -f k8s/wordpress/app.yaml -f k8s/prestashop/app.yaml
kubectl -n wordpress  rollout status deploy/wordpress  --timeout=300s
kubectl -n prestashop rollout status deploy/prestashop --timeout=420s

echo; echo ">> Estado"
kubectl get pods,pvc,svc -n wordpress
kubectl get pods,pvc,svc -n prestashop
echo; echo ">> Si EXTERNAL-IP dice <pending>, espera 1-2 min y ejecuta:"
echo "   kubectl get svc -n wordpress wordpress; kubectl get svc -n prestashop prestashop"
