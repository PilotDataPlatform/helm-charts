# helm-charts
Helm Charts Repository for the Pilot Data Platform

![Helm v3](https://img.shields.io/badge/Helm-v3-green?style=for-the-badge)
[![License: AGPL v3](https://img.shields.io/badge/License-AGPL_v3-blue.svg?style=for-the-badge)](https://www.gnu.org/licenses/agpl-3.0)

## Usage

### Creating a new chart
```bash
helm create mychart
```

```bash
helm package mychart # will use version defined in chart
mv mychart-x.y.z.tgz docs # move it to the github pages folder
helm repo index docs --url https://pilotdataplatform.github.io/helm-charts/ # build index file for helm repository
```

### Using a chart from the git repo repo
```bash
helm install deployment-name ./mychart
```

### Using a chart from the helm repository
```bash
helm repo add pilot https://pilotdataplatform.github.io/helm-charts/
helm install deployment-name pilot/mychart
```antonio is testing
