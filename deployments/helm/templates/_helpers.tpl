{{/* Define namespace of chart, useful for multi-namespace deployments */}}
{{- define "proxy-3proxy.namespace" -}}
  {{- if .Values.namespaceOverride }}
    {{- .Values.namespaceOverride }}
  {{- else }}
    {{- .Release.Namespace }}
  {{- end }}
{{- end }}

{{/* Expand the name of the chart */}}
{{- define "proxy-3proxy.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "proxy-3proxy.fullname" -}}
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

{{/* Create chart name and version as used by the chart label */}}
{{- define "proxy-3proxy.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/* Common labels */}}
{{- define "proxy-3proxy.commonLabels" -}}
helm.sh/chart: {{ include "proxy-3proxy.chart" . }}
{{ include "proxy-3proxy.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/* Selector labels */}}
{{- define "proxy-3proxy.selectorLabels" -}}
app.kubernetes.io/name: {{ include "proxy-3proxy.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
