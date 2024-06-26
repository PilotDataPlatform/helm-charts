#!/bin/bash
set -e

HELM_REPOSITORY="pilotdataplatform.github.io"

# Get chart name from the argument
FULL_CHART_NAME=$1
CHART_VERSION=$2

# Function to display help
show_help() {
    echo "Usage: $(basename $0) [OPTIONS] <chart-name> [chart-version]"
    echo
    echo "This script will pull a the helm chart into a .tgz file, add it to the docs/ folder and run the helm repo index command."
    echo
    echo "Options:"
    echo "  -h, --help      Show this help message and exit"
    echo
    echo "Arguments:"
    echo "  <chart-name>    Full chart name including repository prefix (e.g., myrepo/mychart). Run 'helm search repo myrepo' if you're unsure about the name."
    echo "  [chart-version] Specific version of the chart to pull (optional)"
    echo
    echo "Example:"
    echo "  $(basename $0) myrepo/mychart 1.2.3"
}

# Check for help option
if [[ $1 == "-h" || $1 == "--help" ]]; then
    show_help
    exit 0
fi

# Ensure chart name is provided
if [[ -z $FULL_CHART_NAME ]]; then
    echo "Error: No chart name provided."
    exit 1
fi

# Extract the chart name without the repo prefix
CHART_NAME=$(echo $FULL_CHART_NAME | cut -d "/" -f 2)

# delete folder if exists
rm -rf $CHART_NAME

# Step 1: Download the chart
helm repo update
# Conditionally pull the chart with or without a specific version
if [[ -z $CHART_VERSION ]]; then
    helm pull $FULL_CHART_NAME --untar
else
    helm pull $FULL_CHART_NAME --version $CHART_VERSION --untar
fi

# Extract version from the chart metadata
VERSION=$(grep '^version:' $CHART_NAME/Chart.yaml | awk '{print $2}')

# Step 2: Compress the chart into a .tgz file
tar -czvf "$CHART_NAME-$VERSION.tgz" $CHART_NAME/

# Step 3: Move the .tgz file with version to the docs/ directory
mv $CHART_NAME-$VERSION.tgz docs/

# Step 4: Update the Helm repo index
helm repo index docs --url https://$HELM_REPOSITORY/helm-charts/
