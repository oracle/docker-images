#
# Copyright (c) 2021, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
#

{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "essbase.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "essbase.fullname" -}}
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
{{- define "essbase.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "essbase.labels" -}}
helm.sh/chart: {{ include "essbase.chart" . }}
{{ include "essbase.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "essbase.selectorLabels" -}}
app.kubernetes.io/name: {{ include "essbase.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "essbase.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "essbase.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Common environment variables for the essbase containers
*/}}
{{- define "essbase.commonEnv" -}}
- name: ESSBASE_CLUSTER_SIZE
  value: {{ .Values.essbaseCluster.serverCount | quote }}
- name: DATABASE_TYPE
  value: {{ .Values.database.type | quote }}
- name: DATABASE_CONNECT_STRING
  value: {{ required "database.connectString required" .Values.database.connectString | quote }}
- name: DATABASE_SCHEMA_PREFIX
  value: {{ .Values.database.schemaPrefix | quote }}
{{- with .Values.database.schemaTablespace }}
- name: DATABASE_SCHEMA_TABLESPACE
  value: {{ . | quote }}
{{- end }}
{{- with .Values.database.schemaTempTablespace }}
- name: DATABASE_SCHEMA_TEMP_TABLESPACE
  value: {{ . | quote }}
{{- end }}
{{- if .Values.easServer.enabled }}
- name: ENABLE_EAS
  value: "TRUE"
{{- end }}
{{- end }}

