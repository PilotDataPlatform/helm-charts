{{/*
Expand the name of the chart.
*/}}
{{- define "pilotx.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "pilotx.fullname" -}}
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
{{- define "pilotx.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "pilotx.labels" -}}
helm.sh/chart: {{ include "pilotx.chart" . }}
{{ include "pilotx.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "pilotx.selectorLabels" -}}
app.kubernetes.io/name: {{ include "pilotx.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "pilotx.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "pilotx.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create the R2DBC database URL
*/}}
{{- define "pilotx.r2dbcUrl" -}}
r2dbc:postgresql://{{ .Values.appConfig.database.host }}:{{ .Values.appConfig.database.port }}/{{ .Values.appConfig.database.name }}
{{- end }}

{{/*
Create the JDBC database URL (for Flyway/Datasource)
*/}}
{{- define "pilotx.jdbcUrl" -}}
jdbc:postgresql://{{ .Values.appConfig.database.host }}:{{ .Values.appConfig.database.port }}/{{ .Values.appConfig.database.name }}
{{- end }}
