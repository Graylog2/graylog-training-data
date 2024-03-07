index=$(curl -u 'admin:yabba dabba doo' -k -XGET "https://localhost/api/system/indexer/indices" | jq '.all.indices[] | select(.index_name=="mfi_0") | .index_name')
if [ -z "$id" ];then 
    fail-message "Oops, it looks like you still need create your first index";  
fi

id=$(curl -u 'admin:yabba dabba doo' -k -XGET  "https://localhost/api/streams" | jq -r '.streams | .[] | select(.title=="My First Stream") | .id')
if [ -z "$id" ];then 
    fail-message "Oops, it looks like you still need create your first stream";  
fi