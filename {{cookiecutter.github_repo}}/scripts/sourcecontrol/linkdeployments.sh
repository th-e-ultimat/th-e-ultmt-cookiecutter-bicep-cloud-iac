#!/bin/bash

# Get latest deployment
deployment=$(az deployment sub show -n main)

deployment_result=$(echo $deployment | jq .properties.provisioningState)

# Check if latest deployment succeeded
if [ "$deployment_result" != "\"Succeeded\"" ]; then
    echo "Recent deployment $deployment_result at $(echo $deployment | jq .properties.timestamp)"
    exit 1
fi

# Loop through all resources that need to be linked
for git_link in $(echo $deployment | jq -c '.properties.outputs.gitLinks.value[]'); do
    repo_url=$(echo $git_link | jq .repoUrl)
    resource_id=$(echo $git_link | jq .resourceId)
    single_env=$(echo $git_link | jq .isSingleEnvironment)

    # Get Azure Resource nme
    resource_name="${resource_id##*/}"
    resource_name="${resource_name%\"}"

    # Get Repository path in [Owner/Repo] format
    repo_path=${repo_url//'https://github.com/'/} # N.B. will only work for github hosted repo
    repo_path="${repo_path%\"}"
    repo_path="${repo_path#\"}"

    echo "Connecting source control for $resource_name to $repo_path..."

    # Get publishing profile
    echo "[1] Getting publishing profile for $resource_name"
    publishing_profile=$(bash -c "az webapp deployment list-publishing-profiles --ids "$resource_id" --xml") # assigned to variable doesn't work without bash -c

    # Save publish profile as secret
    environment_prefix=${DEPLOYMENT_ENVIRONMENT^^}
    secret_name="AZURE_PUBLISH_PROFILE_$environment_prefix"
    workflow_name="cd_$DEPLOYMENT_ENVIRONMENT.yml"

    if [[ $single_env = true ]]
    then
        secret_name="AZURE_PUBLISH_PROFILE"
        workflow_name="cd.yml"
    fi

    echo "[2] Saving publishing profile as github secret \"$secret_name\""
    gh secret --repo $repo_path set $secret_name -b"${publishing_profile}"
    if [ $? -ne 0 ]; then
        echo "Failed to save publishing profile as github secret"
        exit 1
    fi

    # Run deployment
    echo "[3] Run deployment pipeline \"$workflow_name\" on $repo_path"
    gh workflow --repo $repo_path run $workflow_name
    if [ $? -ne 0 ]; then
        echo "Failed to run deployment pipeline"
        exit 1
    fi

    echo "Done connecting source control for $resource_name to $repo_path"
done

exit 0
