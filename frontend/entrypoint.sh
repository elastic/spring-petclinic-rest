#!/bin/bash -e
echo "Loading source maps"
chmod 0666 /source_maps/*.map

#wait for apm-server to come alive
until  $(curl -s -o /tmp/apm_health_check.out --head --fail "${ELASTIC_APM_SERVER_URL}/"); do
    echo "Waiting for APM Server..."
  sleep 1
done
#wait for es to be available as source maps will go there from the apm-server
shopt -s nocasematch
if [[ "${INSECURE_SSL}" == "true" ]]; then
    until curl -u "${ELASTICSEARCH_USERNAME}:${ELASTICSEARCH_PASSWORD}" -s "${ELASTICSEARCH_URL}/_cat/health" "--insecure" -o /dev/null; do
        echo "Waiting for Elasticsearch..."
        sleep 1
    done
else
    until curl -u "${ELASTICSEARCH_USERNAME}:${ELASTICSEARCH_PASSWORD}" -s "${ELASTICSEARCH_URL}/_cat/health" -o /dev/null; do
        echo "Waiting for Elasticsearch..."
        sleep 1
    done
fi
shopt -u nocasematch

# Wait for Elasticsearch to start up before doing anything.


echo "Ready to load sourcemaps"
for source_map in /source_maps/*.map; do

    filename=$(basename $source_map)
    filename="${filename%.*}"

    #in case we have local copy
    echo "Loading source map $source_map $PETCLINIC_INTERNAL_URL"
    response_code=$(curl -s -o /tmp/source_map.out -X POST "${ELASTIC_APM_SERVER_URL}/assets/v1/sourcemaps" -w "%{response_code}" -F service_name="${ELASTIC_APM_SERVICE_NAME}-react" -F service_version="${ELASTIC_APM_SERVICE_VERSION}" -F bundle_filepath="${PETCLINIC_INTERNAL_URL}/static/js/${filename}" -F sourcemap=@$source_map)
    if [[ $response_code -ne 202 ]]; then
      echo "FAILED Loading source map. Expected 202, got..."
      cat /tmp/source_map.out
      exit 1
    else
      echo "OK!"
    fi

    #in case we have remote copy
    echo "Loading source map $source_map $PETCLINIC_EXTERNAL_URL"
    response_code=$(curl -s -o /tmp/source_map.out -X POST "${ELASTIC_APM_SERVER_URL}/assets/v1/sourcemaps" -w "%{response_code}" -F service_name="${ELASTIC_APM_SERVICE_NAME}-react" -F service_version="${ELASTIC_APM_SERVICE_VERSION}" -F bundle_filepath="${PETCLINIC_EXTERNAL_URL}/static/js/${filename}" -F sourcemap=@$source_map)
    if [[ $response_code -ne 202 ]]; then
      echo "FAILED Loading source map. Expected 202, got..."
      cat /tmp/source_map.out
      exit 1
    else
      echo "OK!"
    fi
done
exec "$@"

