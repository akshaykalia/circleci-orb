#!/bin/bash
# Get the Shipyard environment URL and bypass token for this project

URL=""
ORG="${CIRCLE_PROJECT_USERNAME}"
REPO="${CIRCLE_PROJECT_REPONAME}"
BRANCH="${CIRCLE_BRANCH}"

# Hit the Shipyard API
URL="https://shipyard.build/api/v1/project?org_name=${ORG}&repo_name=${REPO}&branch=${BRANCH}"
JSON=$(curl -s "${URL}" -H "x-api-token: ${SHIPYARD_API_TOKEN}")

# Ensure we got a response
if [ -z "${JSON}" ]
then
  echo "ERROR: no response from ${URL}"
  exit 1
fi

SHIPYARD_BYPASS_TOKEN=$(echo "${JSON}" | jq -r '.data[0].attributes.bypass_token')
SHIPYARD_ENVIRONMENT_URL=$(echo "${JSON}" | jq -r '.data[0].attributes.url')
SHIPYARD_ENVIRONMENT_READY=$(echo "${JSON}" | jq -r '.data[0].attributes.ready')

# Validate the response data
if [ -z "${SHIPYARD_BYPASS_TOKEN}" ]; then
  echo "${JSON}"
  echo "ERROR: no bypass token found!"
  exit 1
fi

if [ -z "${SHIPYARD_ENVIRONMENT_URL}" ]; then
  echo "${JSON}"
  echo "ERROR: no access url found!"
  exit 1
fi

if [ -z "${SHIPYARD_ENVIRONMENT_READY}" ]; then
  echo "${JSON}"
  echo "ERROR: no value for 'ready'!"
  exit 1
fi

# Wait for the environment to be ready
while [[ "${SHIPYARD_ENVIRONMENT_READY}" != true ]]; do
  echo "Waiting for your Shipyard environment..."
  sleep 3

  # Re-fetch the data
  JSON=$(curl -s "${URL}" -H "x-api-token: ${SHIPYARD_API_TOKEN}")
  SHIPYARD_BYPASS_TOKEN=$(echo "${JSON}" | jq -r '.data[0].attributes.bypass_token')
  SHIPYARD_ENVIRONMENT_URL=$(echo "${JSON}" | jq -r '.data[0].attributes.url')
  SHIPYARD_ENVIRONMENT_READY=$(echo "${JSON}" | jq -r '.data[0].attributes.ready')
done

{ echo "export SHIPYARD_BYPASS_TOKEN=${SHIPYARD_BYPASS_TOKEN}"; echo "export SHIPYARD_ENVIRONMENT_URL=${SHIPYARD_ENVIRONMENT_URL}"; echo "export SHIPYARD_ENVIRONMENT_READY=${SHIPYARD_ENVIRONMENT_READY}"; } >> "${BASH_ENV}"
