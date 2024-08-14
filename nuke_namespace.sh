#!/bin/bash
IFS=$'\n'
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
set  -o xtrace  -o errexit  -o nounset  -o pipefail  +o history

if [ -z "${1+x}" ] || [ -z "${1}" ]; then
  echo -e "\nUsage:  ${0}  <NAMESPACE>\n"
  exit 1
fi
DEL_NAMESPACE="${1}"

for RELEASE_NAME in $( helm  list  -n "${DEL_NAMESPACE}"  -q ); do
  echo "== Helm uninstall '${RELEASE_NAME}' =="
  helm  uninstall  -n "${DEL_NAMESPACE}"  "${RELEASE_NAME}"  --no-hooks  || true
  "${SCRIPT_DIR}/nuke_helmrelease.sh"  "${RELEASE_NAME}"
done

for RESOURCE in $( kubectl api-resources --verbs=list --namespaced -o name | xargs -n 1 kubectl get --show-kind --ignore-not-found -n "${DEL_NAMESPACE}" -o name); do
  echo "== Delete api-resource '${RESOURCE}' =="
  kubectl patch -n "${DEL_NAMESPACE}"  -p '{"metadata":{"finalizers":null}}' --type=merge  "${RESOURCE}" || true
  kubectl delete -n "${DEL_NAMESPACE}"  "${RESOURCE}"  --force || true
done

#for RESOURCE in $( kubectl  get  -n "${DEL_NAMESPACE}"  all,ingress,mutatingwebhookconfigurations,validatingwebhookconfigurations,configmaps  -o name); do
#  echo "== Delete resource '${RESOURCE}' =="
#  echo kubectl patch -n "${DEL_NAMESPACE}"  -p '{"metadata":{"finalizers":null}}' --type=merge  "${RESOURCE}" || true
#  echo kubectl delete -n "${DEL_NAMESPACE}"  "${RESOURCE}"  --force || true
#done

kubectl patch -p '{"metadata":{"finalizers":null}}' --type=merge  "namespace/${DEL_NAMESPACE}" || true
kubectl  delete --timeout=10s  namespace  "${DEL_NAMESPACE}"  --force || true

echo "== Done. =="