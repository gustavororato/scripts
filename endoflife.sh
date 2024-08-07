#!/bin/bash

# Author: Gustavo Henrique Rorato
# Date: 07/08/2024
# Objective: Check the last 3 versions of each stack used and display the results in a single table by executing a single command.

# Define your stack
mystack=("perl" "react" "nodejs" "nuxt" "go")

# Iterate over each stack item
for stack in "${mystack[@]}"; do 

    # Fetch JSON data from the API
    json=$(curl --silent --request GET --url "https://endoflife.date/api/$stack.json" --header 'Accept: application/json')

    # Check if curl returned nothing
    if [ -z "$json" ]; then
        echo "No data received for $stack. Skipping..."
        continue
    fi

    # Check if the JSON is an array and contains entries
    if [ "$(echo "$json" | jq -r 'type')" != "array" ] || [ "$(echo "$json" | jq length)" -lt 1 ]; then
        echo "Less than 1 entries in JSON for $stack. Skipping..."
        continue
    fi

    # Limit to the first 3 results
    json=$(echo "$json" | jq '.[0:3]')

    echo "End of Life for: $stack"

    # Get the latest version details
    latest_version=$(echo "$json" | jq -r 'max_by(.releaseDate)')

    # Get the latestReleaseDate from the latest version
    latest_release_date=$(echo "$latest_version" | jq -r '.releaseDate')

    # Parse the JSON data and format it into a tab-separated format, adding '>' to the latest version
    parsed_data=$(echo "$json" | jq -r --arg releaseDate "$latest_release_date" '
        .[] | [
            if .releaseDate == $releaseDate then
                ">" + .cycle
            else
                .cycle
            end,
            .releaseDate,
            .eol,
            .latest,
            .latestReleaseDate,
            .lts,
            .support,
            .extendedSupport
        ] | @tsv'
    )

    # Print headers
    printf "%-15s %-15s %-15s %-15s %-20s %-15s %-15s %-17s\n" "Cycle" "Release Date" "EOL" "Latest" "Latest Release Date" "LTS" "Support" "Extended Support"

    # Print parsed data
    echo "$parsed_data" | awk -F'\t' '{ printf "%-15s %-15s %-15s %-15s %-20s %-15s %-15s %-17s\n", $1, $2, $3, $4, $5, $6, $7, $8 }'

    echo # This adds a blank line for better readability
done
