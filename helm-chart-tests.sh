#!/bin/bash

#
# Test Helm charts
# Usage:
# helm-chart-tests.sh /path/to/charts-dir /path/to/values-dir
#

failed=0

#Loop Helm charts
for chart in $(find $1 -maxdepth 1 -type d | tail -n +2)
do
    echo "CHART: ${chart}"

    helm lint $chart 1>/dev/null
    if [ $? -eq 0 ]; then
        echo "  PASS: Lint"
    else
        echo "  FAILED: Lint"
        failed=1
    fi

    helm template $chart 1>/dev/null
    if [ $? -eq 0 ]; then
        echo "  PASS: Template default values"
    else
        echo "  FAILED: Template default values"
        failed=1
    fi

    for values in $(ls $2/*.yaml)
    do
        helm template $chart -f $values 1>/dev/null
        if [ $? -eq 0 ]; then
            echo "  PASS: Template values $values"
        else
            echo "  FAILED: Template values $values"
            failed=1
        fi
    done
done 

exit ${failed}