## Install

1. Install the Guacamole custom resource definition as defined in the [operator](https://github.com/PilotDataPlatform/operator) repo.
2. Run Helm install with the `values.yaml` as defined in the [azure-infra](https://github.com/PilotDataPlatform/azure-infra) repo:

    ```
    helm install guacamole-operator guacamole-operator/ --values guacamole-operator/values.yaml --namespace guacamole-system
    ```
