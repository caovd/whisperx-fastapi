{{/*
Expand the name of the chart.
*/}}
{{- define "whisperx-fastapi.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "whisperx-fastapi.fullname" -}}
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
{{- define "whisperx-fastapi.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "whisperx-fastapi.labels" -}}
helm.sh/chart: {{ include "whisperx-fastapi.chart" . }}
{{ include "whisperx-fastapi.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
hpe-ezua/type: vendor-service
hpe-ezua/app: {{ .Chart.Name }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "whisperx-fastapi.selectorLabels" -}}
app.kubernetes.io/name: {{ include "whisperx-fastapi.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
