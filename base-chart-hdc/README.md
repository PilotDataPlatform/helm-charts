# Base Helm Chart for HDC

This Helm chart serves as a foundation for multiple HDC services, providing consistent Kubernetes resource configurations.

## Overview

The `base-chart-hdc` provides templates for common Kubernetes resources:
- Deployment with init container support
- Service with optional multiple port configurations 
- ServiceAccount
- Ingress

## Installation

To use this chart as a dependency in another chart:

1. Add the chart dependency to your service's `Chart.yaml`:

```yaml
dependencies:
  - name: base-chart-hdc
    version: 0.1.0
    repository: file://../base-chart-hdc
```

2. Update dependencies:

```bash
helm dependency update ./your-service-chart
```

3. Customize values in your service's `values.yaml` file.

## Deployment

To deploy directly (for testing):

```bash
helm install <release-name> ./base-chart-hdc
```

With custom values:

```bash
helm install <release-name> ./base-chart-hdc --values custom-values.yaml
```

## Extending and Overriding Values

### Example Values Configuration

```yaml
# Chart specific settings
nameOverride: "my-service"
replicaCount: 2

# Kubernetes labels customization
labels:
  app: "custom-app-name"      # Override app.kubernetes.io/name
  component: "api"            # Add app.kubernetes.io/component label
  partOf: "platform"          # Add app.kubernetes.io/part-of label
  custom:                     # Add any custom labels
    environment: "production"
    tier: "backend"

# Image configuration
image:
  repository: my-service-image
  tag: 1.0.0
  pullPolicy: Always
  tagPrefix: ""

# Application configuration 
appConfig:
  port: 8080
  env: "dev"
  config_center_enabled: true
  config_center_base_url: "http://config-service:5000/"
  srv_namespace: "my-service"

# Container settings
container:
  name: "my-container"
  # Command and args for the container (optional)
  command: ["node", "app.js"]
  args: ["--config", "/etc/config/app.json"]
  # Define multiple ports using a list
  ports:
    - name: http
      containerPort: 8080
      protocol: TCP
    - name: admin
      containerPort: 8081
    - name: metrics
      containerPort: 9090

# Service settings  
service:
  type: ClusterIP
  # Define multiple ports using a list
  ports:
    - port: 80
      targetPort: my-service-http
      name: http
    - port: 8080 
      targetPort: my-service-admin
      name: admin
    - port: 9090
      targetPort: my-service-metrics
      name: metrics

# Additional environment variables
extraEnv:
  LOG_LEVEL: debug
  ENABLE_METRICS: "true"

# Volume configuration
extraVolumeMounts:
  - name: config-volume
    mountPath: /app/config

extraVolumes:
  - name: config-volume
    configMap:
      name: my-service-config
```

## Common Patterns

### Configuring Multiple Container Ports

You can define any number of container ports using the ports list:

```yaml
container:
  ports:
    - name: http            # The name of the port (used to generate service targetPort)
      containerPort: 8080   # The container port number
      protocol: TCP         # Optional: defaults to TCP
      
    - name: admin
      containerPort: 8081
      
    - name: metrics
      containerPort: 9090
```

When using this approach, the service targetPort should reference the port names:

```yaml
service:
  ports:
    - port: 80
      targetPort: base-chart-hdc-http  # base-chart-hdc- prefix + container port name
      name: http
      
    - port: 8081
      targetPort: base-chart-hdc-admin
      name: admin
```

### Configuring Multiple Service Ports

You can define any number of service ports using the ports list:

```yaml
service:
  type: ClusterIP
  ports:
    - port: 80              # The port exposed by the service
      targetPort: app-http  # The name of the container port (must match container ports name)
      name: http            # The name for this port
      protocol: TCP         # Optional: defaults to TCP
    
    - port: 8080
      targetPort: app-admin
      name: admin
    
    - port: 9090
      targetPort: metrics
      name: metrics
```

For NodePort services, you can specify the nodePort:

```yaml
service:
  type: NodePort
  ports:
    - port: 80
      targetPort: app-http
      name: http
      nodePort: 30080
```

### Multiple Containers in a Pod

You can add additional containers to the deployment using the `additionalContainers` parameter:

```yaml
additionalContainers:
  - name: sidecar
    image: "sidecar:latest"
    ports:
      - name: sidecar-http
        containerPort: 8081
        protocol: TCP
    volumeMounts:
      - name: shared-data
        mountPath: /shared-data

  - name: metrics
    image: "metrics-exporter:1.0.0"
    ports:
      - name: metrics
        containerPort: 9090
```

This is useful for implementing sidecar patterns, proxies, or metric exporters alongside your main application.

### Customizing Kubernetes Labels

You can customize the Kubernetes labels applied to all resources:

```yaml
labels:
  # Override the default app name label
  app: "custom-app-name"      
  
  # Add component label
  component: "backend"        
  
  # Add part-of label for grouping services
  partOf: "data-platform"     
  
  # Add any custom labels
  custom:                     
    environment: "production"
    team: "data-engineering"
```

These labels are added to all resources and can be used for organization, filtering in Kubernetes UIs, and for selecting targets in network policies, RBAC rules, etc.

### Using Init Containers

```yaml
initContainers:
  enabled: true
  command: ["sh", "-c", "echo Initializing..."]
  args: []
```

### Custom Probes

```yaml
livenessProbe:
  httpGet:
    path: /health
    port: http
  initialDelaySeconds: 30
  periodSeconds: 10

readinessProbe:
  httpGet:
    path: /ready
    port: http
  initialDelaySeconds: 15
  periodSeconds: 5
```

### Enabling Ingress

```yaml
ingress:
  enabled: true
  className: "nginx"
  annotations:
    kubernetes.io/ingress.class: nginx
  hosts:
    - host: my-service.example.com
      paths:
        - path: /
          pathType: Prefix
```

## Main Differences and Commonalities with Current Charts

### Commonalities
- Basic resource templates (Deployment, Service, Ingress, ServiceAccount)
- Label conventions and selector patterns
- Common environment variable patterns

### Key Differences from bff Chart
- Support for init containers
- More flexible configuration for tag prefixes
- Volume mount support
- Improved env variable handling

### Key Differences from dataset-service Chart
- Support for dual-port service configurations
- More consistent naming patterns
- Better defaults for modern Kubernetes

## Development

To modify this base chart:

1. Make changes to templates or values
2. Update version in Chart.yaml
3. Test with a sample service configuration
4. Update documentation as needed