# helm-drupal

Reusable Helm chart for running a Drupal application on Kubernetes. Packages the
PHP-FPM + Nginx pair plus optional cron, Xdebug and Blackfire, so consuming
projects only supply their own values.

Published to `https://favish.github.io/helm-drupal` and consumed as a chart
dependency by favish Drupal projects (`kitco-cms-drupal`, `zerohedge-d8`, …).
Shared chart: **changes must stay backwards compatible** — new behaviour ships
behind default-off values.

## Contents

- [Components](#components)
- [Layout](#layout)
- [Usage](#usage)
- [Key values](#key-values)
- [cron-worker](#cron-worker)
- [Releasing](#releasing)
- [Local checks](#local-checks)
- [Conventions (agents & contributors)](#conventions-agents--contributors)
- [Pending improvements](#pending-improvements)

## Components

| Component | Template | Purpose |
|-----------|----------|---------|
| php-fpm Deployment (+HPA) | `drupal/templates/php/` | Runs Drupal via PHP-FPM; autoscales on CPU/memory. |
| nginx Deployment (+HPA) | `drupal/templates/nginx/` | Serves static assets, proxies FastCGI to php-fpm. |
| cron-worker Deployment | `drupal/templates/cron-worker/` | Optional (default-off). Runs `drush cron` on its own pod, no HPA. |
| Ingress + TLS | `drupal/templates/ingress.yaml`, `tls-secret.yaml` | External routing + certificate. |
| Xdebug StatefulSet | `drupal/templates/xdebug/` | Optional step-debugger. |
| Shared env / init container | `_drupal-env.tpl`, `_drupal-initContainer.tpl` | DB/S3/Blackfire env + the init container that loads app code into the pod. |

php and cron-worker share the same image and init container, so `drush` runs
against the real codebase and database.

## Layout

```
drupal/                          # the chart
├── Chart.yaml                   # metadata (version injected at release time)
├── values.yaml                  # defaults, documented inline
└── templates/
    ├── php/ nginx/              # deployment, service, hpa, configmap
    ├── cron-worker/             # optional drush-cron deployment
    ├── xdebug/                  # optional debugger
    ├── ingress.yaml tls-secret.yaml
    ├── _drupal-env.tpl          # shared env (DB, S3, Blackfire)
    └── _drupal-initContainer.tpl
.github/workflows/release.yml    # tag -> publish chart
CHANGELOG.md
```

## Usage

Declare the dependency in the consuming umbrella chart:

```yaml
dependencies:
  - name: drupal
    repository: https://favish.github.io/helm-drupal
    version: 4.3.0
```

```bash
helm dependency update ./your-umbrella-chart
```

Minimal values:

```yaml
drupal:
  db: { database: my_db, host: 10.0.0.1, user: my_user, pass: "secret" }
  fqdn: cms.example.com
  php:
    image: favish/php-fpm:4.0.0
    autoscaling: { enabled: true, minReplicas: 3, targetCPUUtilizationPercentage: 80 }
  initContainer:
    image: us.gcr.io/your-project/your-app   # tag usually set to the git SHA at deploy time
```

## Key values

| Value | Default | Meaning |
|-------|---------|---------|
| `php.image` | `favish/php-fpm:3.0.5` | PHP-FPM image (override per project). |
| `php.autoscaling.enabled` | `false` | php HPA on/off. |
| `php.autoscaling.targetCPUUtilizationPercentage` | `80` | HPA CPU target. |
| `php.livenessProbe` / `php.readinessProbe` | `{}` (off) | Optional php-fpm probes. |
| `php.cronWorker.enabled` | `false` | Dedicated cron pod (see below). |
| `initContainer.image` / `.tag` | — | Image that loads Drupal code into the pod. |
| `db.*` | — | MySQL connection. |
| `ingress.hosts` / `ingress.tls.enabled` | — | Routing + TLS. |

Full commented reference: `drupal/values.yaml`.

## cron-worker

URL-triggered Drupal cron (`/cron/<token>`) lands on the serving php pods; a
heavy run (search indexing, feed imports, purges) spikes their CPU and churns the
autoscaler. `php.cronWorker.enabled=true` instead runs `drush cron` on a separate
no-HPA Deployment, keeping cron load off the serving fleet.

```yaml
php:
  cronWorker:
    enabled: true
    period: 60                       # seconds between runs
    uri: "https://cms.example.com"   # optional --uri for URL-building cron tasks
    resources:
      requests: { cpu: 250m, memory: 512Mi }
      limits:   { cpu: "2",  memory: 1500Mi }
```

Reuses the init container + `php.image`; no extra image required. Default-off.

## Releasing

GitHub Actions (`.github/workflows/release.yml`). Merge to `master`, update
`CHANGELOG.md`, then tag:

```bash
git tag 4.4.0 && git push origin 4.4.0
```

The workflow packages the chart (stamping the tag as the chart version) and
publishes it to the `gh-pages` Helm repo. `workflow_dispatch` runs a dry-run
(package + index, no push).

Migrated from CircleCI (its checkout key lost repo access — `Permission denied
(publickey)`); `actions/checkout` uses the built-in `GITHUB_TOKEN`, no deploy key.

## Local checks

```bash
helm lint ./drupal

# Chart.yaml has no version until release; stamp a temp one to render
cp drupal/Chart.yaml /tmp/c.bak
printf '\nversion: 0.0.0-test\n' >> drupal/Chart.yaml
helm template t ./drupal --set initContainer.image=example --set php.cronWorker.enabled=true
cp /tmp/c.bak drupal/Chart.yaml
```

## Conventions (agents & contributors)

- Backwards compatibility is mandatory; new behaviour goes behind a default-off /
  empty value. Verify with `helm template` before and after.
- Chart `version` is injected from the git tag at release; it is not in
  `Chart.yaml`. Local renders need a temporary version stamp (above).
- Helm replaces lists wholesale (no merge). Consumers overriding `resources` /
  `env` fully replace defaults — account for this when changing defaults.
- Release = push a git tag. No manual gh-pages step.

## Pending improvements

Identified in audit, left unchanged to protect consumers; tracked for a
coordinated update:

- `imagePullPolicy` unset on app containers; `blackfire/blackfire` sidecar
  untagged (defaults `latest`). Pin + set explicitly.
- HPA renders an empty `metrics:` block if autoscaling is enabled with all
  targets nulled. Guard it or default a metric.
- `ingress.yaml` uses the deprecated `kubernetes.io/ingress.class` annotation →
  `spec.ingressClassName`.
- `tls-secret.yaml` expects pre-base64'd input → consider `stringData:`.
- Pod annotations use dotted `prometheus.io.scrape` keys → conventional
  `prometheus.io/scrape`.
- DB password + Blackfire/S3 tokens passed as plain env → move to `Secret` +
  `secretKeyRef`.
