pipeid=$(curl -u 'admin:yabba dabba doo' -k -XGET  "https://localhost/api/system/pipelines/pipeline" | jq -r '.[] | select(.title=="Routing") | .id')
if [ -z "$pipeid" ];then 
    fail-message "Oops, it looks like you still need create your pipeline!";  
fi

ruleid=$(curl -u 'admin:yabba dabba doo' -k -XGET  "https://localhost/api/system/pipelines/rule" | jq -r '.[] | select(.title=="Route - My First Stream Logs") | .id')
if [ -z "$ruleid" ];then 
    fail-message "Oops, it looks like you still need create your routing rule!";  
fi

pljson=$(curl -u 'admin:yabba dabba doo' -k -XGET  "https://localhost/api/system/pipelines/pipeline/$pipeid")
plrules=$(echo $pljson | jq -r '.stages | .[].rules')
if [[ $plrules != *"Route - My First Stream Logs"* ]]; then
    fail-message "Oops, it looks like you still need to add your routing rule to your pipeline"
fi