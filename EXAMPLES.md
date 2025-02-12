# Deploy Examples

## Prometheus Relay

- Update examples/prometheus-relay.yml

```bash
git clone https://github.com/ioops-io/helm.git
cd helm
helm install prometheus-relay -n prometheus-relay --create-namespace chart/ioops-template -f examples/prometheus-relay.yml
```
