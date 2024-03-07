rule=$(curl -X GET "localhost:9200/_search?size=1" -H 'Content-Type: application/json' -d '{"query":{"exists":{"field":"rule_demo"}}}' | jq '.hits.hits[]._index')
if [ -z "$rule" ]; then
    fail-message "Oops, it looks like no logs have the rule_demo field added! Go check your pipeline / resend logs"
    exit 0
fi