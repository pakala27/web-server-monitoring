#!/usr/bin/env bash
clusters=($(curl -sg 'http://localhost:9090/prometheus/api/v1/targets' | jq -r '.data?[][] | select(.labels.cluster != null) | .labels.cluster' | uniq))

for cluster in ${clusters[*]}; do
    echo "{\"timestamp\":\"$(date +%Y-%m-%dT%H:%M:%S:%3N)\",\"cluster\":\"${cluster}\"}"
    machineCount=($(curl -sg 'http://localhost:9090/prometheus/api/v1/targets' | jq -r -c --arg cluster "${cluster}" '.data?[][] | select(.labels.cluster == $cluster) | select(.labels.job != $cluster + "_nodes")' | wc -l))
    jsonResult=($(curl -sg "http://localhost:9090/prometheus/api/v1/query?query=jvm_info{cluster=\"${cluster}\"}" | jq -c --arg timestamp "$(date +%Y-%m-%dT%H:%M:%S:%3N)" '.data.result[].metric | {timestamp: $timestamp, hostname: .hostname, cluster:  .cluster }'))
    if [[ ${#jsonResult[@]} != "${machineCount}" ]]; then
        echo "{\"timestamp\":\"$(date +%Y-%m-%dT%H:%M:%S:%3N)\",\"cluster\":\"${cluster}\",\"message\":\"Some targets unavailable\"}"
        echo ${jsonResult[*]} | jq -c .
    fi
done