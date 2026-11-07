# Laboratorio 6 - WordPress + PrestaShop en AKS, con Grafana

Dos portales en el mismo cluster AKS, cada uno en su namespace y con su propia base MariaDB
(Secret + PVC + Deployment + Service ClusterIP). Grafana (Managed Grafana del template azd)
observa el cluster aparte de los sitios.

| Namespace  | Portal (LoadBalancer) | Base de datos (ClusterIP) | PVC |
|------------|-----------------------|---------------------------|-----|
| wordpress  | wordpress:6-apache    | wordpress-db (mariadb:10.11)  | wordpress-data, wordpress-db-data |
| prestashop | prestashop:8-apache   | prestashop-db (mariadb:10.11) | prestashop-data, prestashop-db-data |

## Como desplegar
1. Clonar el template y crear el cluster: `azd init -t https://github.com/sabbour/aks-app-template` y `azd provision`.
2. `az aks get-credentials -g <grupo-de-recursos> -n <cluster>` y comprobar `kubectl get nodes`.
3. `./deploy.sh` crea los namespaces, los Secrets (claves aleatorias, no se guardan) y aplica los manifiestos.
4. `kubectl get svc -A | grep LoadBalancer` para ver las IP publicas y completar cada asistente.
   - PrestaShop: servidor de BD `prestashop-db`, base `prestashop`, usuario `psuser`; la clave sale de
     `kubectl -n prestashop get secret prestashop-db-secret -o jsonpath='{.data.password}' | base64 -d`.
5. Reinicio: `kubectl -n wordpress rollout restart deploy/wordpress` y `kubectl -n prestashop rollout restart deploy/prestashop`.
6. Apagar: `azd down --force --purge`.

Ningun Service de base de datos se expone a Internet (ClusterIP). Los `secret.example.yaml` no tienen valores reales.

## Notas de este despliegue (Azure for Students)
- El template azd no fue viable (politica de regiones y Azure Monitor); el cluster se creo con:
  `az aks create -g rg-lab6-aks -n aks-lab6 -l spaincentral --node-count 2 --node-vm-size Standard_D2s_v4 --tier free --kms-infrastructure-encryption Enabled --generate-ssh-keys`
- La suscripcion permite 3 IPs publicas por region: PrestaShop comparte la IP de WordPress en el puerto 8080 (`loadBalancerIP` en k8s/prestashop/app.yaml; cambia la IP por la de tu WordPress).
- Apagar: `az group delete -n rg-lab6-aks --yes`
