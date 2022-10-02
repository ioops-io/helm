# Collection of HELM Charts

## List of Helm Charts

| Template name | Description | Values.yml tips |
|---|---|---|
| ioops-template | Main template | [Configure](Configure.md) |

## Test templates

```bash
./helm-chart-tests.sh chart test/values
```

## Helm Tips

1) Installing Helm:

[Check latest instructions to install Helm](https://helm.sh/docs/intro/install/)

1) Testing a template:

```bash
cd chart
helm lint chart-name
```

Output shold contains:

```bash
1 chart(s) linted, 0 chart(s) failed
```

1) Customizing and deploy:

TIP: --app-version equals to the container image version inside container registry. --version refers to this Chart version and they may not be equal each other.

```bash
helm package --app-version=1.0.0 --version=1.0.0 . -d /tmp
helm upgrade -i --wait release-name /tmp/chart-name-1.0.0.tgz \
    --set nameOverride=other-release-name
```

You can call it passing your custom values.yalm file.

```bash
helm package --app-version=1.0.0 --version=1.0.0 . -d /tmp
helm upgrade -i --wait release-name /tmp/chart-name-1.0.0.tgz -f /path/to/values.yaml
```

1) Verifying deployment

```bash
helm list
```
