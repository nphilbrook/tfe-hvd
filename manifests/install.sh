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
#
# The two extraArgs below fix DNS-01 propagation checks in split-horizon DNS setups.
# Without them, cert-manager discovers authoritative nameservers by following the
# delegation chain from inside the cluster. In this VPC the resolver returns the
# *private* zone nameservers for nick-philbrook.sbx.hashidemos.io, which don't
# have the _acme-challenge TXT record and return REFUSED.
# --dns01-recursive-nameservers forces cert-manager to query public resolvers instead.
# --dns01-recursive-nameservers-only disables the authoritative NS lookup entirely.
helm upgrade --install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --version "${CERT_MANAGER_VERSION}" \
  --set crds.enabled=true \
  --set 'extraArgs[0]=--dns01-recursive-nameservers=8.8.8.8:53\,1.1.1.1:53' \
  --set 'extraArgs[1]=--dns01-recursive-nameservers-only' \
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
