{{- define "wellpass.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: wellpass
{{- end }}

