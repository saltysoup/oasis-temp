# Copyright 2025 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import os
import ray
import time
import cupy as cp
import logging
import sys
import argparse
from ray.util.collective.types import Backend
import ray.util.collective as collective
from ray.util.placement_group import placement_group

# --- Constants ---
GROUP = "dense_allreduce_benchmark_group"

def setup_logger(job_id: str):
    """Configures a logger to write to stdout and a file in /bucket."""
    log_file_path = f"/bucket/{job_id}.log"
    logger = logging.getLogger()
    logger.setLevel(logging.INFO)

    if logger.hasHandlers():
        logger.handlers.clear()

    formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(message)s', datefmt='%Y-%m-%d %H:%M:%S')

    stream_handler = logging.StreamHandler(sys.stdout)
    stream_handler.setFormatter(formatter)
    logger.addHandler(stream_handler)

    try:
        file_handler = logging.FileHandler(log_file_path)
        file_handler.setFormatter(formatter)
        logger.addHandler(file_handler)
        logging.info(f"Logging to stdout and {log_file_path}")
    except Exception as e:
        logging.error(f"CRITICAL: Failed to configure file logging at {log_file_path}. Error: {e}")

@ray.remote(num_gpus=1)
class BenchmarkWorker:
    """A Ray actor that participates in the NCCL benchmark."""
    def __init__(self, tensor_gb: int):
        self.tensor_size_bytes = int(tensor_gb * 1024 * 1024 * 1024)
        self.rank = -1
        self.world_size = -1

    # THIS IS THE COMBINED AND CORRECTED METHOD
    def setup_collective_group_and_log_env(self, world_size: int, rank: int, group_name: str):
        """
        Sets up the NCCL environment, logs variables for debugging, and initializes the collective group.
        """
        self.rank = rank
        self.world_size = world_size

        # --- Logging Logic Moved Here ---
        # This will now execute right before the NCCL call that might be failing.
        os.environ["NCCL_DEBUG"] = "INFO"
        logging.info(f"--- Environment Variables for Rank {self.rank} on Node {ray.get_runtime_context().get_node_id()} ---")
        for key, value in os.environ.items():
            if key.startswith("NCCL") or key == "LD_LIBRARY_PATH":
                logging.info(f"  {key}={value}")
        logging.info("-------------------------------------------------")
        
        # --- NCCL Initialization ---
        collective.init_collective_group(
            world_size=self.world_size,
            rank=self.rank,
            backend=Backend.NCCL,
            group_name=group_name
        )
        
        logging.info(f"[Rank {self.rank}/{self.world_size}] NCCL group initialized successfully.")
        return True
        
    def run_allreduce_benchmark(self, num_iterations=10):
        """Runs a timed All-Reduce benchmark."""
        tensor = cp.ones(self.tensor_size_bytes, dtype=cp.uint8)

        for _ in range(5):
            collective.allreduce(tensor, group_name=GROUP)
        cp.cuda.Stream.null.synchronize()

        start_time = time.time()
        for _ in range(num_iterations):
            collective.allreduce(tensor, group_name=GROUP)
        cp.cuda.Stream.null.synchronize()
        duration = time.time() - start_time

        if self.rank == 0:
            avg_time = duration / num_iterations
            effective_data_size_bytes = self.tensor_size_bytes * 2
            bandwidth_gbps = (effective_data_size_bytes * 8) / (avg_time * 1e9)
            bandwidth_gbs = effective_data_size_bytes / (avg_time * 1e9)
            return (bandwidth_gbps, bandwidth_gbs)

        return None

    def shutdown(self):
        """Cleans up the collective group."""
        logging.info(f"[Rank {self.rank}/{self.world_size}] Shutting down.")
        collective.destroy_collective_group(group_name=GROUP)
        return True

def parse_args():
    """Parses command-line arguments."""
    parser = argparse.ArgumentParser(description="Dense NCCL All-Reduce Benchmark with Autoscaling")
    parser.add_argument("--num-nodes", type=int, default=2, help="Number of nodes to autoscale and use.")
    parser.add_argument("--gpus-per-node", type=int, default=8, help="Number of GPUs to use on each node.")
    parser.add_argument("--tensor-gb", type=int, default=8, help="Size of the tensor for each worker in gigabytes.")
    parser.add_argument("--iterations", type=int, default=10, help="Number of timed benchmark iterations.")
    parser.add_argument("--timeout-seconds", type=int, default=1800, help="Timeout in seconds to wait for nodes to be provisioned.")
    return parser.parse_args()

def main():
    args = parse_args()

    if args.num_nodes <= 0 or args.gpus_per_node <= 0:
        print("Error: --num-nodes and --gpus-per-node must be greater than 0.", file=sys.stderr)
        sys.exit(1)

    ray.init(address="auto")

    job_id = ray.get_runtime_context().get_job_id()
    setup_logger(job_id)

    world_size = args.num_nodes * args.gpus_per_node
    logging.info(f"Starting benchmark with {args.num_nodes} nodes and {args.gpus_per_node} GPUs/node for a total of {world_size} workers.")

    resources_per_node = {"GPU": args.gpus_per_node, "CPU": args.gpus_per_node}
    bundles = [resources_per_node] * args.num_nodes
    pg = placement_group(bundles, strategy="STRICT_SPREAD")

    logging.info(f"Waiting for resources to be ready... Timeout: {args.timeout_seconds}s")
    ready, _ = ray.wait([pg.ready()], timeout=args.timeout_seconds)
    if not ready:
        logging.error("Resource request timed out. Cluster did not scale up in time.")
        raise RuntimeError(f"Failed to acquire resources for {args.gpus_per_node} GPUs on {args.num_nodes} nodes within {args.timeout_seconds}s.")

    logging.info("✅ Placement Group is ready. Creating benchmark workers...")

    workers = []
    for node_index in range(args.num_nodes):
        for _ in range(args.gpus_per_node):
            worker = BenchmarkWorker.options(
                num_gpus=1,
                placement_group=pg,
                placement_group_bundle_index=node_index
            ).remote(tensor_gb=args.tensor_gb)
            workers.append(worker)

    # Call the single, combined setup method for all workers.
    # The logging will now happen reliably before the NCCL init call.
    logging.info("Initializing collective group and logging environment...")
    ray.get([
        worker.setup_collective_group_and_log_env.remote(world_size=world_size, rank=rank, group_name=GROUP)
        for rank, worker in enumerate(workers)
    ])
    
    logging.info("All workers initialized. Starting benchmark...")

    all_results = ray.get([w.run_allreduce_benchmark.remote(args.iterations) for w in workers])
    final_bandwidth = next(res for res in all_results if res is not None)

    results_string = (
        f"\n{'='*60}"
        f"\n Dense NCCL All-Reduce Benchmark Completed"
        f"\n{'='*60}"
        f"\n  Total Nodes: {args.num_nodes}"
        f"\n  GPUs per Node: {args.gpus_per_node}"
        f"\n  Total Workers (GPUs): {world_size}"
        f"\n  Message Size per Worker: {args.tensor_gb} GB"
        f"\n  Iterations: {args.iterations}"
        f"\n" + "-" * 60 +
        f"\n  Aggregate Algorithm Bandwidth: {final_bandwidth[0]:.2f} Gbps ({final_bandwidth[1]:.2f} GB/s)"
        f"\n{'='*60}\n"
    )
    logging.info(results_string)

    ray.get([w.shutdown.remote() for w in workers])
    ray.util.remove_placement_group(pg)
    ray.shutdown()
    logging.info("Benchmark finished, Placement Group removed, and Ray session shut down.")

if __name__ == "__main__":
    main()
