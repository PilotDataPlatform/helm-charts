#!/bin/bash

set -e

HELM_REPOSITORY="pilotdataplatform.github.io"

show_help() {
    echo "Usage: $(basename $0) [OPTIONS] <chart-name> [chart-version]"
    echo
    echo "This script will pull a the helm chart into a .tgz file, add it to the docs/ folder and run the helm repo index command."
    echo
    echo "Options:"
    echo "  -h, --help      Show this help message and exit"
    echo "  --release       Releases new version of a Pilot helm chart"
    echo
    echo "Arguments:"
    echo "  <chart-name>    Full chart name including repository prefix (e.g., myrepo/mychart). Run 'helm search repo myrepo' if you're unsure about the name."
    echo "  [chart-version] Specific version of the chart to pull (optional)"
    echo
    echo "Example:"
    echo "  $(basename $0) myrepo/mychart 1.2.3"
    echo "  $(basename $0) --release download-service"
}

check_arguments() {
    if [[ $1 == "-h" || $1 == "--help" ]]; then
        show_help
        exit 0
    fi

    if [[ -z $1 ]]; then
        echo "Error: No chart name provided."
        exit 1
    fi
}

extract_chart_name() {
    if [[ $1 == "--release" ]]; then
        echo $2
    else
        if [[ $1 == oci://* ]]; then
            # For OCI URLs, take the last segment
            echo $1 | rev | cut -d "/" -f 1 | rev
        else
            # For regular helm repo charts
            echo $1 | cut -d "/" -f 2
        fi
    fi
}

pull_chart() {
    helm repo update
    if [[ -z $2 ]]; then
        # pull latest version
        helm pull $1 --untar
    else
        # pull specific version
        helm pull $1 --version $2 --untar
    fi
}

extract_version() {
    grep '^version:' $1/Chart.yaml | awk '{print $2}'
}

compress_chart() {
    tar -czvf "$1-$2.tgz" $1/
}

move_chart() {
    mv $1-$2.tgz docs/
}

update_repo_index() {
    helm repo index docs --url https://$1/helm-charts/
}

main() {
    local pull_chart=false
    check_arguments $1
    if [[ $1 == "--release" ]]; then
        FULL_CHART_NAME=$2
        CHART_VERSION=$3
    else
        FULL_CHART_NAME=$1
        CHART_VERSION=$2
        pull_chart=true
    fi
    CHART_NAME=$(extract_chart_name $1 $FULL_CHART_NAME)
    if $pull_chart; then
        rm -rf $CHART_NAME
        pull_chart $FULL_CHART_NAME $CHART_VERSION
    fi
    VERSION=$(extract_version $CHART_NAME)
    compress_chart $CHART_NAME $VERSION
    move_chart $CHART_NAME $VERSION
    update_repo_index $HELM_REPOSITORY
}

main $@
