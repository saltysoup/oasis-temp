# Deploy a Ray Cluster with DWS Flex Start H200 GPUs using CCC

This document provides instructions on how to deploy a Ray cluster on GKE using
A3 Ultra VMs and run example jobs.

For running a stand-alone job, check out the [`RayJob` example](job/README.md).

## 1. Requirements

To set up the required Python environment using Conda, run the following
commands:

```sh
# Create and activate the conda environment
conda env create -f environment.yaml
conda activate oasis
```

## 2. Submit a Training Job

When the cluster is `ready`, you can submit a job.

### 2.a. Port-forward the Ray Dashboard

Open a **new terminal** and run the following command to access the Ray head
node services:

```
kubectl port-forward svc/ray-dashboard-service  8265:8265 2>&1 >/dev/null &
```

With the port-forward active, you can view the Ray Dashboard in your browser at:
[http://localhost:8265](http://localhost:8265)

### 2.b. Submit the job

Use the `ray job submit` command to run the training script. The example below
uses `convnext_train.py`.

```sh
ray job submit \
  --address http://localhost:8265 \
  --runtime-env train/runtime-env.yaml \
  --working-dir train \
  -- python convnext_train.py
```

If the submission is successful you will receive a message indicating the Job
ID, for example:

```
-------------------------------------------------------
Job 'raysubmit_8uZHmkebess9DJGk' submitted successfully
-------------------------------------------------------
```

You should see the new job appear in the Ray Dashboard. You can also view the
job(s) via the command line:

```sh
ray job logs <JOB_ID> --address http://localhost:8265
```

#### Example output

The following example output is from a job submission:

```
Job submission server address: http://localhost:8265
2025-07-24 11:59:21,773 INFO dashboard_sdk.py:338 -- Uploading package gcs://_ray_pkg_43edce3c792ab224.zip.
2025-07-24 11:59:21,774 INFO packaging.py:588 -- Creating a file package for local module 'train'.
2025-07-24 11:59:23,084 INFO dashboard_sdk.py:338 -- Uploading package gcs://_ray_pkg_373201038aa26fa2.zip.
2025-07-24 11:59:23,084 INFO packaging.py:588 -- Creating a file package for local module '.'.

-------------------------------------------------------
Job 'raysubmit_2m9mc2MpX8hY2ikg' submitted successfully
-------------------------------------------------------
..
Training started with configuration:
╭───────────────────────────────────────────────╮
│ Training config                               │
├───────────────────────────────────────────────┤
│ train_loop_config/batch_size_per_worker    64 │
│ train_loop_config/epochs                   10 │
│ train_loop_config/lr                      0.1 │
╰───────────────────────────────────────────────╯
(RayTrainWorker pid=3787, ip=10.52.2.7) Setting up process group for: env:// [rank=0, world_size=16]
..
(RayTrainWorker pid=3704, ip=10.52.3.7) ray-cluster-ccc-gpu-group-worker-684r7:3704:4784 [5] NCCL INFO NET/gIB : GPU Direct RDMA Enabled for HCA 0 'mlx5_0'
(RayTrainWorker pid=3704, ip=10.52.3.7) ray-cluster-ccc-gpu-group-worker-684r7:3704:4784 [5] NCCL INFO NET/gIB : GPU Direct RDMA Enabled for HCA 1 'mlx5_1'
(RayTrainWorker pid=3704, ip=10.52.3.7) ray-cluster-ccc-gpu-group-worker-684r7:3704:4784 [5] NCCL INFO NET/gIB : GPU Direct RDMA Enabled for HCA 2 'mlx5_2'
(RayTrainWorker pid=3704, ip=10.52.3.7) ray-cluster-ccc-gpu-group-worker-684r7:3704:4784 [5] NCCL INFO NET/gIB : GPU Direct RDMA Enabled for HCA 3 'mlx5_3'
(RayTrainWorker pid=3704, ip=10.52.3.7) ray-cluster-ccc-gpu-group-worker-684r7:3704:4784 [5] NCCL INFO NET/gIB : GPU Direct RDMA Enabled for HCA 4 'mlx5_4'
(RayTrainWorker pid=3704, ip=10.52.3.7) ray-cluster-ccc-gpu-group-worker-684r7:3704:4784 [5] NCCL INFO NET/gIB : GPU Direct RDMA Enabled for HCA 5 'mlx5_5'
(RayTrainWorker pid=3704, ip=10.52.3.7) ray-cluster-ccc-gpu-group-worker-684r7:3704:4784 [5] NCCL INFO NET/gIB : GPU Direct RDMA Enabled for HCA 6 'mlx5_6'
(RayTrainWorker pid=3704, ip=10.52.3.7) ray-cluster-ccc-gpu-group-worker-684r7:3704:4784 [5] NCCL INFO NET/gIB : GPU Direct RDMA Enabled for HCA 7 'mlx5_7'
(RayTrainWorker pid=3704, ip=10.52.3.7) ray-cluster-ccc-gpu-group-worker-684r7:3704:4784 [5] NCCL INFO NCCL_NET_GDR_LEVEL set by environment to PIX
(RayTrainWorker pid=3704, ip=10.52.3.7) ray-cluster-ccc-gpu-group-worker-684r7:3704:4784 [5] NCCL INFO GPU Direct RDMA Enabled for GPU 8 / HCA 0 (distance 4 <= 4), read 0 mode Default
(RayTrainWorker pid=3704, ip=10.52.3.7) ray-cluster-ccc-gpu-group-worker-684r7:3704:4784 [5] NCCL INFO GPU Direct RDMA Enabled for GPU 9 / HCA 0 (distance 4 <= 4), read 0 mode Default
(RayTrainWorker pid=3704, ip=10.52.3.7) ray-cluster-ccc-gpu-group-worker-684r7:3704:4784 [5] NCCL INFO GPU Direct RDMA Enabled for GPU 10 / HCA 0 (distance 4 <= 4), read 0 mode Default
(RayTrainWorker pid=3704, ip=10.52.3.7) ray-cluster-ccc-gpu-group-worker-684r7:3704:4784 [5] NCCL INFO GPU Direct RDMA Enabled for GPU 11 / HCA 0 (distance 4 <= 4), read 0 mode Default
..
(RayTrainWorker pid=3787, ip=10.52.2.7) Moving model to device: cuda:0
(RayTrainWorker pid=3787, ip=10.52.2.7) Wrapping provided model in DistributedDataParallel.
(RayTrainWorker pid=3706, ip=10.52.3.7)
Train Epoch 0 Rank 9:   0%|          | 0/1250 [00:00<?, ?it/s] [repeated 15x across cluster]
(RayTrainWorker pid=3706, ip=10.52.3.7) /home/ray/anaconda3/lib/python3.9/site-packages/torch/autograd/graph.py:824: UserWarning: Grad strides do not match bucket view strides. This may indicate grad was not created according to the gradient layout contract, or that the param's strides changed since DDP was constructed.  This is not an error, but may impair performance. [repeated 15x across cluster]
(RayTrainWorker pid=3706, ip=10.52.3.7) grad.sizes() = [1024, 1, 7, 7], strides() = [49, 1, 7, 1] [repeated 15x across cluster]
(RayTrainWorker pid=3706, ip=10.52.3.7) bucket_view.sizes() = [1024, 1, 7, 7], strides() = [49, 49, 7, 1] (Triggered internally at /pytorch/torch/csrc/distributed/c10d/reducer.cpp:328.) [repeated 15x across cluster]
(RayTrainWorker pid=3706, ip=10.52.3.7)   return Variable._execution_engine.run_backward(  # Calls into the C++ engine to run the backward pass [repeated 15x across cluster]
(RayTrainWorker pid=3704, ip=10.52.3.7)
Train Epoch 0 Rank 13:   2%|▏         | 20/1250 [00:06<05:39,  3.63it/s] [repeated 304x across cluster]
(RayTrainWorker pid=3792, ip=10.52.2.7)
Train Epoch 0 Rank 2:   3%|▎         | 38/1250 [00:11<05:33,  3.63it/s] [repeated 296x across cluster]
(RayTrainWorker pid=3704, ip=10.52.3.7)
Train Epoch 0 Rank 13:   5%|▍         | 57/1250 [00:17<05:28,  3.64it/s] [repeated 296x across cluster]
(RayTrainWorker pid=3704, ip=10.52.3.7)
Train Epoch 0 Rank 13:   6%|▌         | 76/1250 [00:22<05:23,  3.63it/s] [repeated 304x across cluster]
(RayTrainWorker pid=3704, ip=10.52.3.7)
Train Epoch 0 Rank 13:   8%|▊         | 95/1250 [00:27<05:17,  3.64it/s] [repeated 304x across cluster]
```

## Appendix: Running the NCCL Benchmark

You can test the GPU-to-GPU network performance using the
`test_nccl_rdma_multi.py` script. This script runs an all reduce NCCL test
between nodes using a large tensor to stress and verify the RDMA networking.

It also includes an example of outputting the logs to a bucket via /bucket
directory (mounted via GCS fuse in ray-cluster-ccc.yaml).

### 1. Submit the NCCL Test Job

```
ray job submit \
  --address http://localhost:8265 \
  --working-dir nccl \
  -- python test_nccl_rdma_multi.py --num-nodes 2
```

### 2. GPU nodes scale up

Ray will detect that 2 nodes were requested for the job and will attempt to add
2 nodes to the gpu-group. This will trigger autoscaling to provision 2 GPU
nodes.

Ray uses bundles to allocate X GPUs and Y cores per node, whilst placement_group
ensures the process runs on different nodes.

We then use `ray.wait` to poll until the nodes has been scaled up and is in
`pg.ready()` state before proceeding with the NCCL tests. `timeout_seconds`
value can be modified, with this example using 30 min as max wait time for nodes
to be scaled up.

```
resources_per_node = {"GPU": args.gpus_per_node, "CPU": args.gpus_per_node}
bundles = [resources_per_node] * args.num_nodes
pg = placement_group(bundles, strategy="STRICT_SPREAD")

logging.info(f"Waiting for resources to be ready... Timeout: {args.timeout_seconds}s")
ready, _ = ray.wait([pg.ready()], timeout=args.timeout_seconds)
```

```
Tailing logs until the job exits (disable with --no-wait):
2025-07-24 04:48:04,378 INFO job_manager.py:531 -- Runtime env is setting up.
d2025-07-24 04:48:10,381        INFO worker.py:1520 -- Using address 10.52.5.115:6379 set in the environment variable RAY_ADDRESS
2025-07-24 04:48:10,382 INFO worker.py:1660 -- Connecting to existing Ray cluster at address: 10.52.5.115:6379...
2025-07-24 04:48:10,397 INFO worker.py:1843 -- Connected to Ray cluster. View the dashboard at 10.52.5.115:8265
2025-07-24 04:48:10 - INFO - Logging to stdout and /bucket/02000000.log
2025-07-24 04:48:10 - INFO - Starting benchmark with 2 nodes and 8 GPUs/node for a total of 16 workers.
2025-07-24 04:48:10 - INFO - Waiting for resources to be ready... Timeout: 1800s
(autoscaler +7s) Tip: use `ray status` to view detailed cluster status. To disable these messages, set RAY_SCHEDULER_EVENTS=0.
(autoscaler +7s) Adding 2 node(s) of type gpu-group.
(autoscaler +7s) Resized to 442 CPUs, 16 GPUs.
(autoscaler +7s) No available node types can fulfill resource requests {'bundle_group_ecbd35f16e896b7b3aed2a4196a902000000': 0.001}*1. Add suitable node types to this cluster to resolve this issue.
(autoscaler +7s) No available node types can fulfill resource requests {'bundle_group_ecbd35f16e896b7b3aed2a4196a902000000': 0.001}*1. Add suitable node types to this cluster to resolve this issue.
```

### 3. Example Output of successful job

The job will run a bi-directional point-to-point benchmark and report the
bandwidth.

```
Job 'raysubmit_UCt5UW3vXzr1v5Hy' submitted successfully
-------------------------------------------------------

Next steps
  Query the logs of the job:
    ray job logs raysubmit_UCt5UW3vXzr1v5Hy
  Query the status of the job:
    ray job status raysubmit_UCt5UW3vXzr1v5Hy
  Request the job to be stopped:
    ray job stop raysubmit_UCt5UW3vXzr1v5Hy

Tailing logs until the job exits (disable with --no-wait):
...
All workers initialized. Starting benchmark...
...
(BenchmarkWorker pid=1876, ip=10.52.2.7) ray-cluster-ccc-gpu-group-worker-4wkhd:1876:2960 [0] NCCL INFO NET/gIB : Initializing gIB v1.0.6
..
(BenchmarkWorker pid=2050, ip=10.52.2.7) ray-cluster-ccc-gpu-group-worker-4wkhd:2050:3084 [0] NCCL INFO Channel 03/0 : 2[2] -> 11[3] [send] via NET/gIB/3/GDRDMA
(BenchmarkWorker pid=2050, ip=10.52.2.7) ray-cluster-ccc-gpu-group-worker-4wkhd:2050:3084 [0] NCCL INFO Channel 11/0 : 2[2] -> 11[3] [send] via NET/gIB/3/GDRDMA
..
==================================================
 NCCL Bi-Directional Point-to-Point Benchmark
==================================================
  Message Size: 4 GB
  Iterations: 10
--------------------------------------------------
  Bandwidth (0 -> 1): 2979.26 Gbps (372.41 GB/s)
  Bandwidth (1 -> 0): 2972.62 Gbps (371.58 GB/s)
--------------------------------------------------
  Average Bandwidth: 2975.94 Gbps (371.99 GB/s)
==================================================
...
------------------------------------------
Job 'raysubmit_UCt5UW3vXzr1v5Hy' succeeded
------------------------------------------
```

### Performance Notes

A3 Ultra VMs provide up to 3200 Gbps of bandwidth for GPU-to-GPU networking. For
NCCL All-Reduce/All-Gather operations with 4GiB/8GiB message sizes, you can
expect bandwidth in the range of 350-400 GB/s.
