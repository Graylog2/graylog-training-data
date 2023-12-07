#Delete Existing Public DNS Record for this VM
printf "Running Track Cleanup"

printf "Deleting public DNS Record"
authemail=${cloudflare_auth_email}
apitoken=${cloudflare_auth_token}
id=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/08be24924fc30f320e7329020986bad2/dns_records" -H "X-Auth-Email: $authemail" -H "Authorization: Bearer $apitoken" -H "Content-Type: application/json" | jq -r ".result[] | select(.name | contains (\"$dns\")) | .id")
DeleteRecord=$(curl -s -X DELETE "https://api.cloudflare.com/client/v4/zones/08be24924fc30f320e7329020986bad2/dns_records/$id" -H "X-Auth-Email: $authemail" -H "Authorization: Bearer $apitoken" -H "Content-Type: application/json")
echo $DeleteRecord

printf "Completed Cleanup"