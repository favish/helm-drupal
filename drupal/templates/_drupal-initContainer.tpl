{{- define "drupal.initContainer" }}
{{- if .Values.initContainer.enabled }}
- name: "install"
  image: {{ .Values.initContainer.image }}:{{ default "latest" .Values.initContainer.tag }}
  imagePullPolicy: IfNotPresent
  volumeMounts:
    - name: "drupal-source"
      mountPath: "/srv"
{{- end }}
{{- end }}
