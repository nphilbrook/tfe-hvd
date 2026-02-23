#!/usr/bin/env bash
# Install cert-manager and Reloader into the EKS cluster.
#
# Prerequisites:
#   - kubectl context pointed at the target cluster
#   - Terraform has already been applied (creates the EKS Pod Identity association)
#   - Helm 3 installed
#
# Cert-manager uses EKS Pod Identity for Route53 access — no static credentials
# or service account annotations are needed here; the Pod Identity association
# created by Terraform handles the IAM binding automatically.
set -euo pipefail

CERT_MANAGER_VERSION="v1.19.3"
RELOADER_VERSION="2.2.8"

# --- Helm repos ---
helm repo add jetstack https://charts.jetstack.io
helm repo add stakater https://stakater.github.io/stakater-charts
helm repo update

# --- Namespaces ---
kubectl create namespace cert-manager --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace reloader     --dry-run=client -o yaml | kubectl apply -f -

# --- cert-manager ---
# Note: no serviceAccount.annotations needed — EKS Pod Identity does not require
# the eks.amazonaws.com/role-arn annotation that IRSA uses.
helm upgrade --install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --version "${CERT_MANAGER_VERSION}" \
  --set crds.enabled=true \
  --wait

# --- Reloader (triggers rolling restarts when the TLS secret is renewed) ---
helm upgrade --install reloader stakater/reloader \
  --namespace reloader \
  --version "${RELOADER_VERSION}" \
  --wait

# --- cert-manager CRDs ---
echo "Waiting for cert-manager webhook to be ready..."
kubectl rollout status deployment/cert-manager-webhook -n cert-manager --timeout=120s

kubectl apply -f "$(dirname "$0")/clusterissuer.yaml"
kubectl apply -f "$(dirname "$0")/certificate.yaml"

echo "Done. Check certificate status with:"
echo "  kubectl get certificate -n tfe"
echo "  kubectl describe certificaterequest -n tfe"
