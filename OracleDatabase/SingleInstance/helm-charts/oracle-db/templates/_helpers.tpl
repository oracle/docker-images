#
# Copyright (c) 2020, Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#

{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{/* Expand Variables using a template */}}
{{- define "oracle-db-env" }}
env:
  - name: SVC_HOST
    value: "{{ template "fullname" . }}"
  - name: SVC_PORT
    value: "1521"
  - name: ORACLE_SID
    value: {{ default "ORCLCDB" .Values.oracle_sid | quote }}
  - name: ORACLE_PDB
    value: {{ default "ORCLPDB1" .Values.oracle_pdb | quote }}
  - name: ORACLE_PWD
    valueFrom:
      secretKeyRef:
        name: {{ template "fullname" . }}
        key: oracle_pwd
  - name: ORACLE_CHARACTERSET
    value: {{ default "ORCLPDB1" .Values.oracle_characterset | quote }}
  - name: ORACLE_EDITION
    value: {{ default "enterprise" .Values.oracle_edition | quote }}
  - name: ENABLE_ARCHIVELOG
    value: {{ default false .Values.enable_archivelog | quote}}
{{- end }}
{{/* oracle db labels */}}
{{- define "oracle-db-labels" }}
labels:
  app: {{ template "fullname" . }}
  chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
  release: {{ .Release.Name }}
  heritage: {{ .Release.Service }}
{{- end }}

