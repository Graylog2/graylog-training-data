#!/bin/bash

# Generate 1000 log entries
for ((i=1; i<=1000; i++))
do
    datetime=$(date +"%Y-%m-%dT%H:%M:%S%:z")

    department=("Engineering" "Medical" "Science" "Operations" "Communications" "Tactical")
    random_department=${department[$((RANDOM % ${#department[@]}))]}

    if [[ $((RANDOM % 100)) -eq 0 ]]; then
        sus="true"
        if [[ $1 == "kl" ]]; then
            source_ip="203.0.113.2"
            source_department="unknown"
        else
            source_ip="0.0.0.1"
            source_department="895446f01ba99b9c0488c220ffe61c17"
        fi
    else
        source_ip="10.0.$((RANDOM%7+1)).$((RANDOM%30+1))"
        source_department="$random_department"
        sus="false"
    fi

    source_port=$((RANDOM%50000+1000))
    destination_ip="192.168.$((RANDOM%7+2)).$((RANDOM%30+1))"
    destination_port=$((RANDOM%50000+1000))

    if [[ $sus == "true" ]]; then
        action=("allowed" "allowed" "blocked")
        random_action=${action[$((RANDOM % ${#action[@]}))]}
    else
        action="allowed"
    fi

    echo "$datetime,$source_department,$source_ip,$source_port,$destination_ip,$destination_port,$action,$sus" | ncat -w 1 localhost 5555
done