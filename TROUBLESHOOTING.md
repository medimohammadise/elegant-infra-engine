# Troubleshooting

## kind Public Endpoints Stop Working After Host Reboot

This repository runs Kubernetes on a remote Docker-backed `kind` cluster. After a reboot of the Docker host, public `NodePort`-backed services such as Headlamp, Keycloak, Grafana, and Prometheus may stop responding even when their pods are still `Running`.

Typical symptoms:

- `http://myserver:8443/` for Headlamp is unreachable
- `http://myserver:8080/` for Keycloak is unreachable
- `http://myserver:3000/` for Grafana is unreachable
- `kubectl get pods -A` shows the application pods as `Running`
- `kubectl -n kube-system get pods` shows `kube-proxy` in `CrashLoopBackOff`

Typical `kube-proxy` error:

```text
failed complete: too many open files
```

### Root Cause

On this setup, `kind` node containers inherit host kernel `inotify` limits. If the Docker host comes back with low defaults after reboot, `kube-proxy` can fail with `too many open files`. When that happens, the `NodePort` iptables rules are not restored and public service exposure breaks.

### Permanent Host Fix

Run these commands on the Docker host, for example `myserver`:

```bash
sudo tee /etc/sysctl.d/99-kind-inotify.conf >/dev/null <<'EOF'
fs.inotify.max_user_watches = 524288
fs.inotify.max_user_instances = 512
EOF
```

```bash
sudo sysctl --system
```

Verify:

```bash
sysctl fs.inotify.max_user_watches fs.inotify.max_user_instances
```

Expected output:

```text
fs.inotify.max_user_watches = 524288
fs.inotify.max_user_instances = 512
```

The fix is persistent across reboots because it is stored in `/etc/sysctl.d/99-kind-inotify.conf`.

### Recovery Steps After Applying the Host Fix

From this repository, using the generated kubeconfig:

```bash
KUBECONFIG=/Users/mehdi/MyProject/elegant-infra-engine/components/all/blitzinfra-kubeconfig \
kubectl -n kube-system delete pod -l k8s-app=kube-proxy
```

```bash
KUBECONFIG=/Users/mehdi/MyProject/elegant-infra-engine/components/all/blitzinfra-kubeconfig \
kubectl -n kube-system rollout status ds/kube-proxy --timeout=120s
```

Then verify system recovery:

```bash
KUBECONFIG=/Users/mehdi/MyProject/elegant-infra-engine/components/all/blitzinfra-kubeconfig \
kubectl -n kube-system get pods -o wide
```

Check the public ports directly on the Docker host:

```bash
ssh myserver 'curl -I --max-time 5 http://127.0.0.1:8443/'
ssh myserver 'curl -I --max-time 5 http://127.0.0.1:8080/'
ssh myserver 'curl -I --max-time 5 http://127.0.0.1:3000/login'
```

Expected results:

- Headlamp returns `200 OK`
- Keycloak returns `302 Found`
- Grafana returns `200 OK`

### Notes

- This issue affects the host-backed `NodePort` exposure path, not necessarily the application pods themselves.
- If the host ports are healthy but the URLs are still unreachable from your workstation, check external firewall rules or network reachability to `myserver`.
- If `kube-proxy` does not recover after the host sysctl fix, the next recovery option is to recreate the `kind` cluster from `components/kind-cluster` or `components/all`.
