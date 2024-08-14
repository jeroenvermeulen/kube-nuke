#!/bin/bash
IFS=$'\n'
set  -o xtrace  -o errexit  -o nounset  -o pipefail  +o history

if [ -z "${1+x}" ] || [ -z "${1}" ]; then
  echo -e "\nUsage:  ${0}  <HELM-RELEASE>\n"
  exit 1
fi
RELEASE_NAME="${1}"

# echo "== Helm uninstall '${RELEASE_NAME}' =="
# helm  uninstall  -n "${DEL_NAMESPACE}"  "${RELEASE_NAME}"  --no-hooks  || true

for RESOURCE in $( kubectl get all,apiservice,mutatingwebhookconfigurations,validatingwebhookconfigurations,clusterroles,clusterrolebindings -A -o jsonpath="{range .items[?(@.metadata.annotations.meta\.helm\.sh/release-name=='${RELEASE_NAME}')]}{.kind}{'/'}{.metadata.name}{'\n'}{end}" ); do
  kubectl patch -p '{"metadata":{"finalizers":null}}' --type=merge  "${RESOURCE}" || true
  kubectl delete  "${RESOURCE}"  --force || true  
done

echo "== Done. =="