{{/* This contains items shared between Drupal, Cloud Command, and Xdebug */}}
{{- define "drupal.env" }}
- name: "MYSQL_DB"
  value: "{{ .Values.db.database }}"
- name: "MYSQL_HOST"
  value: "{{ .Values.db.host }}"
- name: "MYSQL_PASS"
  value: "{{ .Values.db.pass }}"
- name: "MYSQL_USER"
  value: "{{ .Values.db.user }}"
- name: "BASE_URL"
  value: "{{ .Values.fqdn }}"
- name: "VARNISH_STATEFULSET_DOMAIN"
  value: "varnish-internal.{{ .Release.Namespace }}.svc.cluster.local"
- name: "DRUPAL_ENV"
  value: {{ .Values.env }}
{{- if .Values.s3Filesystem.enabled }}
{{- with .Values.s3Filesystem }}
- name: "S3_ACCESS_KEY"
  value: {{ .accessKey }}
- name: "S3_SECRET_KEY"
  value: {{ .secretKey }}
- name: "S3_BUCKET"
  value: {{ .bucket }}
- name: "S3_REGION"
  value: {{ .region }}
- name: "S3_HOSTNAME"
  value: {{ .hostname }}
{{- end }}
{{- end }}
{{- end }}
