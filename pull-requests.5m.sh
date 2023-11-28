#!/usr/bin/env bash
#
# <bitbar.title>Pull requests plugin</bitbar.title>
# <bitbar.version>v1.0</bitbar.version>
# <bitbar.author>phlpl</bitbar.author>
# <bitbar.author.github>phlpl</bitbar.author.github>
# <bitbar.desc>Monitor pull requests for repositories</bitbar.desc>
# <bitbar.dependencies>brew install jq</bitbar.dependencies>
# <bitbar.abouturl>https://github.com/phlpl</bitbar.abouturl>
#
# References:
# https://github.com/matryer/xbar-plugins/blob/main/Dev/GitHub/pull-requests.5m.js
# https://docs.github.com/en/rest/overview/authenticating-to-the-rest-api?apiVersion=2022-11-28
# https://docs.github.com/en/rest/pulls/pulls?apiVersion=2022-11-28#list-pull-requests
# https://jqlang.github.io/jq/
#
# Dependencies:
# brew install jq
#

declare -a repos=('OWNER/REPO' 'OWNER/REPO' 'OWNER/REPO')
token='FINE-GRAINED-TOKEN'
new_status_window_hours=1

total_count=0
pr_output=''
title_indicator=''

for repo in "${repos[@]}"
do
    results=$(curl -s -L \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer $token" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    https://api.github.com/repos/$repo/pulls)

    repo_count=$(echo $results | jq length)
    total_count=$(( total_count + repo_count ))

    pr_output+="$repo: $repo_count \n"

    for (( i=0; i<$repo_count; i++ ))
    do
        number=$(echo $results | jq -r --argjson i $i '.[$i].number')
        title=$(echo $results | jq -r --argjson i $i '.[$i].title')
        user_login=$(echo $results | jq -r --argjson i $i '.[$i].user.login')
        html_url=$(echo $results | jq -r --argjson i $i '.[$i].html_url')
        updated_at=$(echo $results | jq -r --argjson i $i '.[$i].updated_at')

        updated_at_seconds=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$updated_at" +%s)
        current_time=$(date -u +%s)
        difference_hrs=$(( (current_time - updated_at_seconds) / 3600 ))

        if [ $difference_hrs -le $new_status_window_hours ]; then
            title_indicator='color=blue'
        fi

        connector='├'

        if [ $i == $(( $repo_count - 1 )) ]; then
            connector='└'
        fi

        pr_output+="${connector} #$number $title ($user_login) ${difference_hrs}hrs ago | href=$html_url \n"
    done
done

echo "$total_count | sfimage=arrow.triangle.pull $title_indicator"
echo "---"

echo -e $pr_output