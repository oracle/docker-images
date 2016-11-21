#!/bin/bash
set -ex

INSECURE_CURL="-k"

# ------------------------------------
# Step 1: Determine target color
# ------------------------------------
ORIGINAL_COLOR=$(curl ${INSECURE_CURL} -s -XGET -H "Authorization: Bearer ${API_TOKEN}" ${SERVICE_MANAGER}/api/kv/blue-green/${APP_NAME}/current?raw=true)
TARGET_COLOR=$(echo "bluegreen" | sed -e s/${ORIGINAL_COLOR}//)

# ------------------------------------
# Step 2: Trigger deploy via API
# ------------------------------------
POSTDATA=$(cat <<ENDOFTEMPLATE
{
  "deployment_id": "${APP_NAME}-${TARGET_COLOR}",
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
# Step 3: Store service discovery key for target color
# ------------------------------------
curl ${INSECURE_CURL} -s -XPUT -H "Authorization: Bearer ${API_TOKEN}" -d "apps/app-${APP_NAME}-${TARGET_COLOR}-${EXPOSED_PORT}/containers" ${SERVICE_MANAGER}/api/kv/blue-green/${APP_NAME}/${TARGET_COLOR}/id

# ------------------------------------
# Step 4: Wait for the target color to come online
# ------------------------------------
TRY=0
MAX_TRIES=30
WAIT_SECONDS=10
HEALTHY=0
while [ $TRY -lt $MAX_TRIES ]; do
 TRY=$(( $TRY + 1 ))
 RESPONSE=$(curl ${INSECURE_CURL} -s -XGET -H "Authorization: Bearer ${API_TOKEN}" ${SERVICE_MANAGER}/api/v2/deployments/${APP_NAME}-${TARGET_COLOR} | jq ".deployment | .current_state == .desired_state")

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
# Step 5: Point router at new services
# ------------------------------------
curl ${INSECURE_CURL} -s -XPUT -H "Authorization: Bearer ${API_TOKEN}" -d "${TARGET_COLOR}" ${SERVICE_MANAGER}/api/kv/blue-green/${APP_NAME}/current

# ------------------------------------
# Step 6: Remove original deployment
# ------------------------------------

HTTP_CODE=$(curl ${INSECURE_CURL} -s -XGET -o /dev/null -w "%{http_code}" -H "Authorization: Bearer ${API_TOKEN}" ${SERVICE_MANAGER}/api/v2/deployments/${APP_NAME}-${ORIGINAL_COLOR})
if [ $HTTP_CODE -eq 404 ]; then
  echo "Tried to remove inactive deployment ${APP_NAME}-${ORIGINAL_COLOR} but it doesn't exist."
  exit 0
fi

# First, the deployment must be stopped
curl ${INSECURE_CURL} -s -XPOST -H "Authorization: Bearer ${API_TOKEN}" ${SERVICE_MANAGER}/api/v2/deployments/${APP_NAME}-${ORIGINAL_COLOR}/stop

# Make sure it has stopped
TRY=0
MAX_TRIES=30
WAIT_SECONDS=10
STOPPED=0
while [ $TRY -lt $MAX_TRIES ]; do
 TRY=$(( $TRY + 1 ))
 RESPONSE=$(curl ${INSECURE_CURL} -s -XGET -H "Authorization: Bearer ${API_TOKEN}" ${SERVICE_MANAGER}/api/v2/deployments/${APP_NAME}-${TARGET_COLOR} | jq ".deployment | .current_state == .desired_state")

 if [ "$RESPONSE" == "true" ]; then
  STOPPED=1
  break
 fi
 echo "Current and desired state of deployment do not match. ${TRY} of ${MAX_TRIES} tries."
 sleep $WAIT_SECONDS
done

if [ $STOPPED -gt 0 ]; then
  # Finally, remove the deployment, and reset the ID
  echo "Original deployment has stopped. Removing the deployment for ${APP_NAME}-${ORIGINAL_COLOR}."

  TRY=0
  MAX_TRIES=30
  WAIT_SECONDS=10
  REMOVED=0
  while [ $TRY -lt $MAX_TRIES ]; do
   TRY=$(( $TRY + 1 ))
   RESPONSE=$(curl ${INSECURE_CURL} -s -XDELETE -H "Authorization: Bearer ${API_TOKEN}" ${SERVICE_MANAGER}/api/v2/deployments/${APP_NAME}-${ORIGINAL_COLOR})
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
    echo "Deployment ${APP_NAME}-${ORIGINAL_COLOR} has been removed."
    curl ${INSECURE_CURL} -s -XPUT -H "Authorization: Bearer ${API_TOKEN}" -d "blue-green/null" ${SERVICE_MANAGER}/api/kv/blue-green/${APP_NAME}/${ORIGINAL_COLOR}/id
  else
    echo "Checked ${MAX_TRIES} times but ${APP_NAME}-${ORIGINAL_COLOR} is not removed. You may need to remove it manually."
  fi

else
  echo "Checked ${MAX_TRIES} times but deployment is not stopped. You may need to stop it manually."
fi

# ------------------------------------
# We made it to the end. All is well!
# ------------------------------------
exit 0
