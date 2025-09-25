# Side notes

These are working notes that supplement the primary documentation.

## Kubectl Ray plugin

Instead of installing `ray` via Conda, you can install it as a `kubectl` plugin.

Install the `ray` plugin for `kubectl` - see
[Use kubectl plugin](https://docs.ray.io/en/latest/cluster/kubernetes/user-guides/kubectl-plugin.html)

Check the Ray cluster resources:

```sh
kubectl ray get cluster
```

Start an interactive session (this sets up the required port forwarding to see
the dashboard):

```sh
kubectl ray session ray-cluster-ccc
```

```
kubectl ray job submit \
  --name convnext-train \
  --runtime-env train/runtime-env.yaml \
  --working-dir train \
  -- python convnext_train.py
```
