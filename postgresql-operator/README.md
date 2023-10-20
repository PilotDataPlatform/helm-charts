## Install

1. Install the Postgres custom resource definition as defined in the [operator](https://github.com/PilotDataPlatform/operator) repo.
2. Run Helm install with the `values.yaml` as defined in the [azure-infra](https://github.com/PilotDataPlatform/azure-infra) repo:

    ```
    helm install postgresql-operator postgresql-operator/ --values postgresql-operator/values.yaml --namespace postgresql-system
    ```
