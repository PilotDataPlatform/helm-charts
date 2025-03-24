# Task: Create a Base Helm Chart for Multiple Services

## Overview
We need to develop a base Helm chart that contains common Kubernetes resources—namely, a Deployment, Service, ServiceAccount, and Ingress. This chart will serve as a foundation for multiple services (e.g., bff and dataset), enabling consistency and reducing duplication.

## Requirements
1. **Base Chart Structure**
   - Create a new Helm chart (suggested name: `base-chart-hdc`) with the standard Helm directory layout.
2. **Templates**
   - **Deployment Template:**  
     - Configure replica count, image repository/tag, container ports, and environment variables.
     - Support additional configurations such as initContainers, extra environment variables, and volume mounts.
   - **Service Template:**  
     - Allow configuration of service type (ClusterIP, LoadBalancer, etc.) and ports.
   - **ServiceAccount Template:**  
     - Create and configure a service account, including annotations and imagePullSecrets if needed.
   - **Ingress Template:**  
     - Provide options to enable/disable ingress with configurable annotations, host rules, and paths.
3. **Helpers and Naming**
   - Implement a `_helpers.tpl` file to centralize common naming conventions, labels, and selectors. Use patterns from your existing charts (e.g., `bff` vs. `dataset-service`) as a guide.
4. **Values**
   - In `values.yaml`, define defaults for all configurable settings (image details, ports, environment settings, etc.).
   - Consolidate any environment or configuration parameters as shown in your diff (e.g., `appConfig` values).
5. **Integration**
   - Ensure that both the bff and dataset services can reference this base chart, overriding settings as needed.
6. **Documentation**
   - Include a README.md that explains:
     - How to deploy the chart.
     - How to extend/override values.
     - The differences and commonalities with the current bff and dataset charts.

## Actionable Steps
1. **Initialize the Helm Chart:**
   - Create a new directory (e.g., `base-chart-hdc`) and run:
     ```bash
     helm create base-chart-hdc
     ```
2. **Refactor and Consolidate Templates:**
   - Merge common parts from the current `bff` and `dataset-service` templates.
   - In the Deployment template, replace service-specific naming with parameterized references (using `.Values` and helper functions).
   - Repeat for Service, ServiceAccount, and Ingress templates.
3. **Implement Helpers:**
   - In `_helpers.tpl`, define functions for naming (e.g., `base-chart.name`, `base-chart.fullname`, `base-chart.labels`, etc.) ensuring consistency.
4. **Configure Values:**
   - Update `values.yaml` with defaults (e.g., `replicaCount`, `image.repository`, `image.tag`, `service.port`, etc.).
   - Integrate environment-specific values as seen in the diff (e.g., `appConfig` settings).
5. **Test and Validate:**
   - Deploy the chart in a development environment.
   - Validate that overriding values (for both bff and dataset) works correctly.
6. **Document and Finalize:**
   - Write a detailed `README.md` with usage examples.
   - Summarize the adjustments made based on the diff provided.

## Git diff between bff and dataset helm charts
```
diff -r bff-hdc dataset-service-hdc/

diff --unified --color -r bff-hdc/Chart.yaml dataset-service-hdc/Chart.yaml
--- bff-hdc/Chart.yaml	2025-03-10 16:30:24.696906636 +0100
+++ dataset-service-hdc/Chart.yaml	2025-03-10 16:30:24.706905836 +0100
@@ -1,6 +1,6 @@
 apiVersion: v2
-appVersion: "1471"
+appVersion: "25"
 description: A Helm chart for Kubernetes
-name: bff
+name: dataset-service
 type: application
-version: 0.6.0
+version: 0.5.0
Only in dataset-service-hdc/: dataset-service
diff --unified --color -r bff-hdc/templates/deployment.yaml dataset-service-hdc/templates/deployment.yaml
--- bff-hdc/templates/deployment.yaml	2025-03-10 16:30:24.703572769 +0100
+++ dataset-service-hdc/templates/deployment.yaml	2025-03-10 16:30:24.710238902 +0100
@@ -1,13 +1,13 @@
 apiVersion: apps/v1
 kind: Deployment
 metadata:
-  name: {{ include "bff.fullname" . }}
+  name: {{ include "dataset-service.fullname" . }}
+  labels:
+    {{- include "dataset-service.labels" . | nindent 4 }}
   {{- with .Values.deploymentAnnotations }}
   annotations:
     {{- toYaml . | nindent 4 }}
   {{- end }}
-  labels:
-    {{- include "bff.labels" . | nindent 4 }}
 spec:
   {{- if not .Values.autoscaling.enabled }}
   replicas: {{ .Values.replicaCount }}
@@ -18,7 +18,7 @@
   {{- end }}
   selector:
     matchLabels:
-      {{- include "bff.selectorLabels" . | nindent 6 }}
+      {{- include "dataset-service.selectorLabels" . | nindent 6 }}
   template:
     metadata:
       {{- with .Values.podAnnotations }}
@@ -26,7 +26,7 @@
         {{- toYaml . | nindent 8 }}
       {{- end }}
       labels:
-        {{- include "bff.selectorLabels" . | nindent 8 }}
+        {{- include "dataset-service.selectorLabels" . | nindent 8 }}
     spec:
       {{- with .Values.imagePullSecrets }}
       imagePullSecrets:
@@ -35,12 +35,56 @@
       {{- if .Values.serviceAccount.create }}
       serviceAccountName: {{ .Values.serviceAccount.name }}
       {{- end }}
+      securityContext:
+        {{- toYaml .Values.podSecurityContext | nindent 8 }}
+      initContainers:
+        - name: "init{{ .Values.name }}"
+          image: "{{ .Values.image.repository }}:alembic-{{ .Values.image.tag | default .Chart.AppVersion }}"
+          imagePullPolicy: {{ .Values.image.pullPolicy }}
+          {{- if .Values.initCommand }}
+          {{- with .Values.initCommand }}
+          command: 
+            {{- toYaml . | nindent 12 }}
+          {{- end }}
+          {{- end }}
+          {{- if .Values.initArgs }}
+          {{- with .Values.initArgs }}
+          args: 
+            {{- toYaml . | nindent 12 }}
+          {{- end }}
+          {{- end }}
+          env:
+          - name: CONFIG_CENTER_ENABLED
+            value: {{ .Values.appConfig.config_center_enabled | quote }}
+          - name: CONFIG_CENTER_BASE_URL
+            value: {{ .Values.appConfig.config_center_base_url | quote }}
+          - name: env
+            value: {{ .Values.appConfig.env | quote }}
+          - name: srv_namespace
+            value: {{ .Values.appConfig.srv_namespace | quote }}
+{{- if .Values.extraEnv }}
+  {{- range $key, $value := .Values.extraEnv }}
+          - name: {{ $key }}
+            value: {{ $value | quote }}
+  {{- end }}
+{{- end }}
+{{- if .Values.envSecrets }}
+  {{- range $key, $secret :=  .Values.envSecrets }}
+          - name: {{ $key }}
+            valueFrom:
+              secretKeyRef:
+                name: {{ $secret }}
+                key: {{ $key | quote }}
+  {{- end }}
+{{- end }}
+{{- with .Values.extraEnvYaml }}
+          {{- toYaml . | nindent 10 }}
+{{- end }}
       containers:
         - name: {{ .Chart.Name }}
-          image: "{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}"
-          ports:
-            - containerPort: {{ .Values.container.port }}
-            - containerPort: {{ .Values.container.portalPort }}
+          securityContext:
+            {{- toYaml .Values.securityContext | nindent 12 }}
+          image: "{{ .Values.image.repository }}:dataset-{{ .Values.image.tag | default .Chart.AppVersion }}"
           imagePullPolicy: {{ .Values.image.pullPolicy }}
           {{- if .Values.command }}
           {{- with .Values.command }}
@@ -55,12 +99,16 @@
           {{- end }}
           {{- end }}
           env:
+          - name: port
+            value: {{ .Values.appConfig.port | quote }}
           - name: CONFIG_CENTER_ENABLED
             value: {{ .Values.appConfig.config_center_enabled | quote }}
           - name: CONFIG_CENTER_BASE_URL
             value: {{ .Values.appConfig.config_center_base_url | quote }}
           - name: env
             value: {{ .Values.appConfig.env | quote }}
+          - name: srv_namespace
+            value: {{ .Values.appConfig.srv_namespace | quote }}
 {{- if .Values.extraEnv }}
   {{- range $key, $value := .Values.extraEnv }}
           - name: {{ $key }}
@@ -70,6 +118,9 @@
 {{- with .Values.extraEnvYaml }}
           {{- toYaml . | nindent 10 }}
 {{- end }}
+          ports:
+              - name: http
+                containerPort: {{ .Values.container.port }}
           resources:
             {{- toYaml .Values.resources | nindent 12 }}
           {{- if .Values.readinessProbe }}
@@ -80,6 +131,10 @@
           livenessProbe:
             {{- toYaml .Values.livenessProbe | nindent 12 }}
           {{- end }}
+          {{- if .Values.extraVolumeMounts }}
+          volumeMounts:
+            {{- toYaml .Values.extraVolumeMounts | nindent 12 }}
+          {{- end }}
       {{- with .Values.nodeSelector }}
       nodeSelector:
         {{- toYaml . | nindent 8 }}
@@ -92,3 +147,7 @@
       tolerations:
         {{- toYaml . | nindent 8 }}
       {{- end }}
+      {{- if .Values.extraVolumes }}
+      volumes:
+        {{- toYaml .Values.extraVolumes | nindent 10 }}
+      {{- end }}
diff --unified --color -r bff-hdc/templates/_helpers.tpl dataset-service-hdc/templates/_helpers.tpl
--- bff-hdc/templates/_helpers.tpl	2025-03-10 16:30:24.700239702 +0100
+++ dataset-service-hdc/templates/_helpers.tpl	2025-03-10 16:30:24.706905836 +0100
@@ -1,7 +1,7 @@
 {{/*
 Expand the name of the chart.
 */}}
-{{- define "bff.name" -}}
+{{- define "dataset-service.name" -}}
 {{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
 {{- end }}
 
@@ -10,7 +10,7 @@
 We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
 If release name contains chart name it will be used as a full name.
 */}}
-{{- define "bff.fullname" -}}
+{{- define "dataset-service.fullname" -}}
 {{- if .Values.fullnameOverride }}
 {{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
 {{- else }}
@@ -26,16 +26,16 @@
 {{/*
 Create chart name and version as used by the chart label.
 */}}
-{{- define "bff.chart" -}}
+{{- define "dataset-service.chart" -}}
 {{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
 {{- end }}
 
 {{/*
 Common labels
 */}}
-{{- define "bff.labels" -}}
-helm.sh/chart: {{ include "bff.chart" . }}
-{{ include "bff.selectorLabels" . }}
+{{- define "dataset-service.labels" -}}
+helm.sh/chart: {{ include "dataset-service.chart" . }}
+{{ include "dataset-service.selectorLabels" . }}
 {{- if .Chart.AppVersion }}
 app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
 {{- end }}
@@ -45,17 +45,17 @@
 {{/*
 Selector labels
 */}}
-{{- define "bff.selectorLabels" -}}
-app.kubernetes.io/name: {{ include "bff.name" . }}
+{{- define "dataset-service.selectorLabels" -}}
+app.kubernetes.io/name: {{ include "dataset-service.name" . }}
 app.kubernetes.io/instance: {{ .Release.Name }}
 {{- end }}
 
 {{/*
 Create the name of the service account to use
 */}}
-{{- define "bff.serviceAccountName" -}}
+{{- define "dataset-service.serviceAccountName" -}}
 {{- if .Values.serviceAccount.create }}
-{{- default (include "bff.fullname" .) .Values.serviceAccount.name }}
+{{- default (include "dataset-service.fullname" .) .Values.serviceAccount.name }}
 {{- else }}
 {{- default "default" .Values.serviceAccount.name }}
 {{- end }}
diff --unified --color -r bff-hdc/templates/ingress.yaml dataset-service-hdc/templates/ingress.yaml
--- bff-hdc/templates/ingress.yaml	2025-03-10 16:30:24.703572769 +0100
+++ dataset-service-hdc/templates/ingress.yaml	2025-03-10 16:30:24.710238902 +0100
@@ -1,5 +1,5 @@
 {{- if .Values.ingress.enabled -}}
-{{- $fullName := include "bff.fullname" . -}}
+{{- $fullName := include "dataset-service.fullname" . -}}
 {{- $svcPort := .Values.service.port -}}
 {{- if and .Values.ingress.className (not (semverCompare ">=1.18-0" .Capabilities.KubeVersion.GitVersion)) }}
   {{- if not (hasKey .Values.ingress.annotations "kubernetes.io/ingress.class") }}
@@ -17,7 +17,7 @@
 metadata:
   name: {{ $fullName }}
   labels:
-    {{- include "bff.labels" . | nindent 4 }}
+    {{- include "dataset-service.labels" . | nindent 4 }}
   {{- with .Values.ingress.annotations }}
   annotations:
     {{- toYaml . | nindent 4 }}
diff --unified --color -r bff-hdc/templates/NOTES.txt dataset-service-hdc/templates/NOTES.txt
--- bff-hdc/templates/NOTES.txt	2025-03-10 16:30:24.700239702 +0100
+++ dataset-service-hdc/templates/NOTES.txt	2025-03-10 16:30:24.706905836 +0100
@@ -6,16 +6,16 @@
   {{- end }}
 {{- end }}
 {{- else if contains "NodePort" .Values.service.type }}
-  export NODE_PORT=$(kubectl get --namespace {{ .Release.Namespace }} -o jsonpath="{.spec.ports[0].nodePort}" services {{ include "bff.fullname" . }})
+  export NODE_PORT=$(kubectl get --namespace {{ .Release.Namespace }} -o jsonpath="{.spec.ports[0].nodePort}" services {{ include "dataset-service.fullname" . }})
   export NODE_IP=$(kubectl get nodes --namespace {{ .Release.Namespace }} -o jsonpath="{.items[0].status.addresses[0].address}")
   echo http://$NODE_IP:$NODE_PORT
 {{- else if contains "LoadBalancer" .Values.service.type }}
      NOTE: It may take a few minutes for the LoadBalancer IP to be available.
-           You can watch the status of by running 'kubectl get --namespace {{ .Release.Namespace }} svc -w {{ include "bff.fullname" . }}'
-  export SERVICE_IP=$(kubectl get svc --namespace {{ .Release.Namespace }} {{ include "bff.fullname" . }} --template "{{"{{ range (index .status.loadBalancer.ingress 0) }}{{.}}{{ end }}"}}")
+           You can watch the status of by running 'kubectl get --namespace {{ .Release.Namespace }} svc -w {{ include "dataset-service.fullname" . }}'
+  export SERVICE_IP=$(kubectl get svc --namespace {{ .Release.Namespace }} {{ include "dataset-service.fullname" . }} --template "{{"{{ range (index .status.loadBalancer.ingress 0) }}{{.}}{{ end }}"}}")
   echo http://$SERVICE_IP:{{ .Values.service.port }}
 {{- else if contains "ClusterIP" .Values.service.type }}
-  export POD_NAME=$(kubectl get pods --namespace {{ .Release.Namespace }} -l "app.kubernetes.io/name={{ include "bff.name" . }},app.kubernetes.io/instance={{ .Release.Name }}" -o jsonpath="{.items[0].metadata.name}")
+  export POD_NAME=$(kubectl get pods --namespace {{ .Release.Namespace }} -l "app.kubernetes.io/name={{ include "dataset-service.name" . }},app.kubernetes.io/instance={{ .Release.Name }}" -o jsonpath="{.items[0].metadata.name}")
   export CONTAINER_PORT=$(kubectl get pod --namespace {{ .Release.Namespace }} $POD_NAME -o jsonpath="{.spec.containers[0].ports[0].containerPort}")
   echo "Visit http://127.0.0.1:8080 to use your application"
   kubectl --namespace {{ .Release.Namespace }} port-forward $POD_NAME 8080:$CONTAINER_PORT
diff --unified --color -r bff-hdc/templates/serviceaccount.yaml dataset-service-hdc/templates/serviceaccount.yaml
--- bff-hdc/templates/serviceaccount.yaml	2025-03-10 16:30:24.703572769 +0100
+++ dataset-service-hdc/templates/serviceaccount.yaml	2025-03-10 16:30:24.710238902 +0100
@@ -3,16 +3,16 @@
 {{- if .Values.imagePullSecrets }}
 imagePullSecrets:
 {{- range $key, $secret := .Values.imagePullSecrets }}
-  - name: {{ .name }}
+  - name: {{ $secret.name }}
 {{- end }}
 {{- end }}
 kind: ServiceAccount
 metadata:
-  name: {{ include "bff.serviceAccountName" . }}
+  name: {{ include "dataset-service.serviceAccountName" . }}
   labels:
-    {{- include "bff.labels" . | nindent 4 }}
+    {{- include "dataset-service.labels" . | nindent 4 }}
   {{- with .Values.serviceAccount.annotations }}
   annotations:
     {{- toYaml . | nindent 4 }}
   {{- end }}
-{{- end }}
+{{- end }}
\ No newline at end of file
diff --unified --color -r bff-hdc/templates/service.yaml dataset-service-hdc/templates/service.yaml
--- bff-hdc/templates/service.yaml	2025-03-10 16:30:24.703572769 +0100
+++ dataset-service-hdc/templates/service.yaml	2025-03-10 16:30:24.710238902 +0100
@@ -1,9 +1,9 @@
 apiVersion: v1
 kind: Service
 metadata:
-  name: {{ include "bff.fullname" . }}
+  name: {{ include "dataset-service.fullname" . }}
   labels:
-    {{- include "bff.labels" . | nindent 4 }}
+    {{- include "dataset-service.labels" . | nindent 4 }}
     {{- with .Values.service.labels }}
     {{- toYaml . | nindent 4 }}
     {{- end }}
@@ -13,10 +13,6 @@
     - port: {{ .Values.service.port }}
       targetPort: {{ .Values.service.targetPort }}
       protocol: TCP
-      name: {{ .Values.service.portName | default (include "bff.fullname" .) }}
-    - port: {{ .Values.service.portalPort }}
-      targetPort: {{ .Values.service.portalTargetPort }}
-      protocol: TCP
-      name: {{ .Values.service.portalPortName | default (printf "portal-%s" (include "bff.fullname" .)) }}
+      name: {{ .Values.service.portName }}
   selector:
-    {{- include "bff.selectorLabels" . | nindent 4 }}
+    {{- include "dataset-service.selectorLabels" . | nindent 4 }}
diff --unified --color -r bff-hdc/templates/tests/test-connection.yaml dataset-service-hdc/templates/tests/test-connection.yaml
--- bff-hdc/templates/tests/test-connection.yaml	2025-03-10 16:30:24.706905836 +0100
+++ dataset-service-hdc/templates/tests/test-connection.yaml	2025-03-10 16:30:24.710238902 +0100
@@ -1,9 +1,9 @@
 apiVersion: v1
 kind: Pod
 metadata:
-  name: "{{ include "bff.fullname" . }}-test-connection"
+  name: "{{ include "dataset-service.fullname" . }}-test-connection"
   labels:
-    {{- include "bff.labels" . | nindent 4 }}
+    {{- include "dataset-service.labels" . | nindent 4 }}
   annotations:
     "helm.sh/hook": test
 spec:
@@ -11,5 +11,5 @@
     - name: wget
       image: busybox
       command: ['wget']
-      args: ['{{ include "bff.fullname" . }}:{{ .Values.service.port }}']
+      args: ['{{ include "dataset-service.fullname" . }}:{{ .Values.service.port }}']
   restartPolicy: Never
diff --unified --color -r bff-hdc/values.yaml dataset-service-hdc/values.yaml
--- bff-hdc/values.yaml	2025-03-10 16:30:24.706905836 +0100
+++ dataset-service-hdc/values.yaml	2025-03-10 16:30:24.710238902 +0100
@@ -1,34 +1,43 @@
-# Default values for bff.
+# Default values for dataset-service.
 # This is a YAML-formatted file.
 # Declare variables to be passed into your templates.
 
+nameOverride: ""
+fullnameOverride: ""
+
 replicaCount: 1
 
 image:
-  repository: bff
-  tag: 1471
+  repository: dataset
+  tag: 25
   pullPolicy: Always
-  # Overrides the image tag whose default is the chart appVersion.
 
-imagePullSecrets: []
-nameOverride: ""
-fullnameOverride: ""
+appConfig:
+  port: 5081
+  env: "dev"
+  config_center_enabled: false
+  config_center_base_url: http://common.utility:5062/
+  srv_namespace: service_dataset
 
 serviceAccount:
   # Specifies whether a service account should be created
   create: false
   # The name of the service account to use.
   # If not set and create is true, a name is generated using the fullname template
-  name:
+  name: 
 
 container:
-  port: 5060
-  portal-port: 3000
+  port: 5081
 
-appConfig:
-  env: "dev"
-  CONFIG_CENTER_ENABLED: false
-  CONFIG_CENTER_BASE_URL:
+service:
+  type: ClusterIP
+  port: 80
+  portName: "http"
+  # Additional custom labels can be added to the service
+  # Example:
+  #labels:
+  #  prometheus.io/scrape: "true"
+  #  team: "backend"
 
 podAnnotations: {}
 
@@ -38,17 +47,7 @@
 
 securityContext: {}
 
-service:
-  type: LoadBalancer
-  port: 5060
-  portalPort: 3000
-  portName: ""
-  portalPortName: ""
-  # Additional custom labels can be added to the service
-  # Example:
-  #labels:
-  #  prometheus.io/scrape: "true"
-  #  team: "backend"
+imagePullSecrets: []
 
 ingress:
   enabled: false
@@ -64,10 +63,14 @@
 
 affinity: {}
 
+extraEnv: {}
+
+extraEnvYaml: {}
+
 readinessProbe: {}
 
-updateStrategy: {}
+extraVolumeMounts: []
 
-extraEnv: {}
+extraVolumes: []
 
-extraEnvYaml: {}
+updateStrategy: {}
```
