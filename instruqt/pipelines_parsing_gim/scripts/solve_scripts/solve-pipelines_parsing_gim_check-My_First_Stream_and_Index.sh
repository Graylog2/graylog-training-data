#Create Index
request=$(curl -u 'admin:yabba dabba doo' -k -XPOST "https://localhost/api/system/indices/index_sets"  -H 'Content-Type: application/json' -H 'X-Requested-By: skipper' -d '{"title":"My First Index","description":"My First Index Description","index_prefix":"mfi","writable":true,"can_be_default":true,"shards":1,"replicas":0,"rotation_strategy_class":"org.graylog2.indexer.rotation.strategies.TimeBasedSizeOptimizingStrategy","rotation_strategy":{"type":"org.graylog2.indexer.rotation.strategies.TimeBasedSizeOptimizingStrategyConfig","index_lifetime_min":"P30D","index_lifetime_max":"P40D"},"retention_strategy_class":"org.graylog2.indexer.retention.strategies.DeletionRetentionStrategy","retention_strategy":{"type":"org.graylog2.indexer.retention.strategies.DeletionRetentionStrategyConfig","max_number_of_indices":20},"index_analyzer":"standard","index_optimization_max_num_segments":1,"index_optimization_disabled":false,"field_type_refresh_interval":5000,"creation_date":"2024-03-06T19:46:51.632+00:00"}')
id=$(echo $request | jq -r '.id')

#Create Stream
curl -u 'admin:yabba dabba doo' -k -XPOST "https://localhost/api/streams"  -H 'Content-Type: application/json' -H 'X-Requested-By: skipper' -d "{\"index_set_id\":\"$id\",\"description\":\"My First Stream Description\",\"title\":\"My First Stream\",\"remove_matches_from_default_stream\":true}"

#Start Stream
#Get Stream ID
id=$(curl -u 'admin:yabba dabba doo' -k -XGET  "https://localhost/api/streams" | jq -r '.streams | .[] | select(.title=="My First Stream") | .id')
curl -u 'admin:yabba dabba doo' -k -XPOST "https://localhost/api/streams/$id/resume" -H 'X-Requested-By: Skipper'