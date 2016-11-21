#!/bin/sh
set -e

[ -z "$API_TOKEN" ] && { echo "API_TOKEN must be set"; exit 1; }
[ -z "$SERVICE_MANAGER" ] && { echo "SERVICE_MANAGER must be set"; exit 1; }
[ -z "$APP_NAME" ] && { echo "APP_NAME must be set"; exit 1; }

KEY=rolling/${APP_NAME}/stable/id
ID_TO_REPLACE=$(curl -s -XGET -H "Authorization: Bearer ${API_TOKEN}" ${SERVICE_MANAGER}/api/kv/${KEY}?raw=true)

KEY=rolling/${APP_NAME}/candidate/id
ID_TO_PROMOTE=$(curl -s -XGET -H "Authorization: Bearer ${API_TOKEN}" ${SERVICE_MANAGER}/api/kv/${KEY}?raw=true)

echo "Replacing stable: ${ID_TO_REPLACE}"
echo "Promoting candidate: ${ID_TO_PROMOTE}"

KEY=rolling/${APP_NAME}/stable/id
VALUE=$ID_TO_PROMOTE
curl -s -XPUT -o /dev/null -H "Authorization: Bearer ${API_TOKEN}" -d "${VALUE}" ${SERVICE_MANAGER}/api/kv/${KEY}

KEY=rolling/${APP_NAME}/blendpercent
VALUE=0
curl -s -XPUT -o /dev/null -H "Authorization: Bearer ${API_TOKEN}" -d "${VALUE}" ${SERVICE_MANAGER}/api/kv/${KEY}

KEY=rolling/${APP_NAME}/candidate/id
VALUE=rolling/null
curl -s -XPUT -o /dev/null -H "Authorization: Bearer ${API_TOKEN}" -d "${VALUE}" ${SERVICE_MANAGER}/api/kv/${KEY}
