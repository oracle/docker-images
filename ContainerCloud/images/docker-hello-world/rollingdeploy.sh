#!/bin/bash
set -ex

INSECURE_CURL="-k"

# ------------------------------------
# Step 1: Trigger deploy via API
# ------------------------------------
ORIGINAL_CANDIDATE=$(curl ${INSECURE_CURL} -s -XGET -H "Authorization: Bearer ${API_TOKEN}" ${SERVICE_MANAGER}/api/kv/rolling/${APP_NAME}/candidate/id?raw=true)
TIMESTAMP=$(date +%Y%m%d-%H%m%S)
[ -z "$SCALE_AMOUNT" ] && { SCALE_AMOUNT=1; }

POSTDATA=$(cat <<ENDOFTEMPLATE
{
  "deployment_id": "${APP_NAME}-${TIMESTAMP}",
  "deployment_name": "${APP_FRIENDLY_NAME} ${TRAVIS_BUILD_NUMBER}",
  "desired_state": 1,
  "placement": {
    "pool_id": "default"
  },
  "quantities": {
    "app": ${SCALE_AMOUNT}
  },
  "stack": {
    "content": "version: 2\nservices:\n  app:\n    image: \"${DOCKER_REGISTRY}/${IMAGE_NAME}:${TRAVIS_BUILD_NUMBER}\"\n    ports:\n      - ${EXPOSED_PORT}/tcp\n    environment:\n      - \"occs:availability=per-pool\"\n      - \"occs:scheduler=random\"\n",
    "service_id": "app",
    "service_name": "${APP_FRIENDLY_NAME} ${TRAVIS_BUILD_NUMBER}",
    "subtype": "service"
  }
}
ENDOFTEMPLATE
)

curl ${INSECURE_CURL} -XPOST -H "Authorization: Bearer ${API_TOKEN}" -d "${POSTDATA}" ${SERVICE_MANAGER}/api/v2/deployments/

# ------------------------------------
# Step 2: Wait for the deployment to be ready
# ------------------------------------
TRY=0
MAX_TRIES=12
WAIT_SECONDS=5
HEALTHY=0
while [ $TRY -lt $MAX_TRIES ]; do
 TRY=$(( $TRY + 1 ))
 RESPONSE=$(curl ${INSECURE_CURL} -s -XGET -H "Authorization: Bearer ${API_TOKEN}" ${SERVICE_MANAGER}/api/v2/deployments/${APP_NAME}-${TIMESTAMP} | jq ".deployment | .current_state == .desired_state")

 if [ "$RESPONSE" == "true" ]; then
  HEALTHY=1
  break
 fi
 echo "Current and desired state of deployment do not match. ${TRY} of ${MAX_TRIES} tries."
 sleep $WAIT_SECONDS
done

if [ $HEALTHY -gt 0 ]; then
  echo "Current and desired state of deployment match. Continuing."
else
  echo "Tried ${MAX_TRIES} times but deployment is not healthy."
  exit 1
fi

# ------------------------------------
# Step 3: Store service discovery key for candidate version
# ------------------------------------

# Reset the blend to 0 so no initial traffic is sent to the candidate
curl ${INSECURE_CURL} -s -XPUT -H "Authorization: Bearer ${API_TOKEN}" -d "0" ${SERVICE_MANAGER}/api/kv/rolling/${APP_NAME}/blendpercent

curl ${INSECURE_CURL} -s -XPUT -H "Authorization: Bearer ${API_TOKEN}" -d "apps/app-${APP_NAME}-${TIMESTAMP}-${EXPOSED_PORT}/containers" ${SERVICE_MANAGER}/api/kv/rolling/${APP_NAME}/candidate/id

# ------------------------------------
# Step 4: Remove original candidate deployment
# ------------------------------------
ORIGINAL_DEPLOY_ID=$(echo $ORIGINAL_CANDIDATE | sed -r 's/apps\/app-(.+)-([0-9]+)\/containers/\1/')

HTTP_CODE=$(curl ${INSECURE_CURL} -s -XGET -o /dev/null -w "%{http_code}" -H "Authorization: Bearer ${API_TOKEN}" ${SERVICE_MANAGER}/api/v2/deployments/${ORIGINAL_DEPLOY_ID})
if [ $HTTP_CODE -eq 404 ]; then
  echo "Tried to remove inactive deployment ${ORIGINAL_DEPLOY_ID} but it doesn't exist."
  exit 0
fi

# First, the deployment must be stopped
curl ${INSECURE_CURL} -s -XPOST -H "Authorization: Bearer ${API_TOKEN}" ${SERVICE_MANAGER}/api/v2/deployments/${ORIGINAL_DEPLOY_ID}/stop

# Make sure it has stopped
TRY=0
MAX_TRIES=30
WAIT_SECONDS=10
STOPPED=0
while [ $TRY -lt $MAX_TRIES ]; do
 TRY=$(( $TRY + 1 ))
 RESPONSE=$(curl ${INSECURE_CURL} -s -XGET -H "Authorization: Bearer ${API_TOKEN}" ${SERVICE_MANAGER}/api/v2/deployments/${ORIGINAL_DEPLOY_ID} | jq ".deployment | .current_state == .desired_state")

 if [ "$RESPONSE" == "true" ]; then
  STOPPED=1
  break
 fi
 echo "Current and desired state of deployment do not match. ${TRY} of ${MAX_TRIES} tries."
 sleep $WAIT_SECONDS
done

if [ $STOPPED -gt 0 ]; then
  # Finally, remove the deployment, and reset the ID
  echo "Original deployment has stopped. Removing the deployment for ${ORIGINAL_DEPLOY_ID}."

  TRY=0
  MAX_TRIES=30
  WAIT_SECONDS=10
  REMOVED=0
  while [ $TRY -lt $MAX_TRIES ]; do
   TRY=$(( $TRY + 1 ))
   RESPONSE=$(curl ${INSECURE_CURL} -k -s -XDELETE -H "Authorization: Bearer ${API_TOKEN}" ${SERVICE_MANAGER}/api/v2/deployments/${ORIGINAL_DEPLOY_ID})
   ERROR_COUNT=$(echo ${RESPONSE} | jq -r ".errors | length")

   if [ $ERROR_COUNT -gt 0 ]; then
    ERRORS=$(echo ${RESPONSE} | jq ".errors[].message")
    echo "${TRY} of ${MAX_TRIES} removal tries. ${ERRORS}"
   else
    REMOVED=1
    break
   fi
   sleep $WAIT_SECONDS
  done

  if [ $REMOVED -gt 0 ]; then
    echo "Deployment ${ORIGINAL_DEPLOY_ID} has been removed."
  else
    echo "Checked ${MAX_TRIES} times but ${ORIGINAL_DEPLOY_ID} is not removed. You may need to remove it manually."
  fi

else
  echo "Checked ${MAX_TRIES} times but deployment is not stopped. You may need to stop it manually."
fi
