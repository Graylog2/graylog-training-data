id=$(curl -u 'admin:yabba dabba doo' -k -XGET  "https://localhost/api/streams" | jq -r '.streams | .[] | select(.title=="My First Stream") | .id')
if [ -z "$id" ];then 
    fail-message "Oops, it looks like you still need create your first stream";  
fi