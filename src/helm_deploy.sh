#!/usr/bin/env bash
set -uo pipefail

# shellcheck disable=SC1091
. lib/retry.sh

function install() {

  echo "Deploying $HELM_RELEASE in $HELM_NAMESPACE ..."
  echo
  if helm upgrade --install --force --wait --timeout 300 "${HELM_RELEASE}" \
    --namespace "${HELM_NAMESPACE}" \
    --values secrets.yaml \
    --version "${CHART_VERSION}" \
    --set dbDatabase="${WP_DB_NAME}" \
    --set dbPrefix="${WP_DB_PREFIX}" \
    --set environment="${APP_ENVIRONMENT}" \
    --set exim.image.tag="${PARENT_VERSION}" \
    --set hostname="${APP_HOSTNAME}" \
    --set hostpath="${APP_HOSTPATH}" \
    --set newrelic.appname="${NEWRELIC_APPNAME}" \
    --set openresty.image.repository="${OPENRESTY_IMAGE}" \
    --set openresty.image.tag="${BUILD_TAG}" \
    --set pagespeed.enabled="${PAGESPEED_ENABLED}" \
    --set php.image.repository="${PHP_IMAGE}" \
    --set php.image.tag="${BUILD_TAG}" \
    --set openresty.minReplicaCount="${OPENRESTY_MIN_REPLICA_COUNT}" \
    --set openresty.maxReplicaCount="${OPENRESTY_MAX_REPLICA_COUNT}" \
    --set wp.siteUrl="${APP_HOSTNAME}/${APP_HOSTPATH}" \
    --set wp.stateless.bucket="${WP_STATELESS_BUCKET}" \
  raywalker/wordpress 2>&1 | tee -a helm_output.txt
  then
    echo "SUCCESS: Deployed release $HELM_RELEASE"
    return 0
  fi
  echo "FAILURE: Could not deploy release $HELM_RELEASE"
  return 1
}

TIMEOUT=10 retry install && exit 0

>&2 echo "ERROR: Helm release ${HELM_RELEASE} failed to deploy"

TYPE="Helm Deployment" \
EXTRA_TEXT="\`\`\`
History:
$(helm history "${HELM_RELEASE}" --max=5)

Build:
$(cat helm_output.txt)
\`\`\`" \
notify-job-failure.sh

./helm_rollback.sh

exit 1
