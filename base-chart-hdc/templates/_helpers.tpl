{{/*
Expand the name of the chart.
*/}}
{{- define "base-chart-hdc.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "base-chart-hdc.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "base-chart-hdc.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "base-chart-hdc.labels" -}}
helm.sh/chart: {{ include "base-chart-hdc.chart" . }}
{{ include "base-chart-hdc.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "base-chart-hdc.selectorLabels" -}}
app.kubernetes.io/name: {{ .Values.labels.app | default (include "base-chart-hdc.name" .) }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- if .Values.labels.component }}
app.kubernetes.io/component: {{ .Values.labels.component }}
{{- end }}
{{- if .Values.labels.partOf }}
app.kubernetes.io/part-of: {{ .Values.labels.partOf }}
{{- end }}
{{- with .Values.labels.custom }}
{{- toYaml . | nindent 0 }}
{{- end }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "base-chart-hdc.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "base-chart-hdc.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}
