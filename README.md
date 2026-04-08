# OKE Self-Managed Confidential Compute Nodes

Terraform stack that deploys self-managed worker nodes with **AMD SEV confidential computing** to an existing OKE cluster on OCI.

## Why Self-Managed?

OKE managed node pools (`oci_containerengine_node_pool`) do not support `platform_config`, so confidential computing (AMD SEV memory encryption) is only possible with self-managed `oci_core_instance` resources.

## Features

- AMD SEV memory encryption via `platform_config.is_memory_encryption_enabled`
- Selectable CNI: VCN-Native Pod Networking (`npn`) or Flannel (`flannel`)
- Configurable node count, shape, OCPUs, and memory
- Optional shielded instance settings (Secure Boot, Measured Boot, vTPM)
- Nodes auto-join an existing OKE cluster via cloud-init bootstrap

## Prerequisites

- An existing OKE Enhanced cluster
- OCI CLI configured (`~/.oci/config`)
- Terraform >= 1.3.0
- An OKE-optimized Oracle Linux image OCID (find via `oci ce node-pool-options get --node-pool-option-id all`)
- An SSH key pair for node access

## Usage

1. Copy the example tfvars and fill in your values:

```bash
cp terraform.tfvars.example terraform.tfvars
```

2. Get your cluster's CA certificate from kubeconfig:

```bash
oci ce cluster create-kubeconfig --cluster-id <cluster-ocid> --region <region> --token-version 2.0.0 --kube-endpoint PUBLIC_ENDPOINT --file /tmp/kubeconfig
grep certificate-authority-data /tmp/kubeconfig | awk '{print $2}'
```

3. Deploy:

```bash
terraform init
terraform plan
terraform apply
```

4. Verify nodes joined the cluster:

```bash
kubectl get nodes
```

## Variables

### Required

| Variable | Description |
|---|---|
| `tenancy_ocid` | OCID of the OCI tenancy |
| `compartment_ocid` | OCID of the compartment |
| `region` | OCI region (e.g. `us-ashburn-1`) |
| `cluster_id` | OCID of the existing OKE cluster |
| `cluster_ca_cert` | Base64-encoded cluster CA certificate |
| `worker_subnet_id` | OCID of the subnet for worker nodes |
| `pod_subnet_id` | OCID of the subnet for pod IPs (VCN-Native CNI) |
| `node_image_id` | OCID of the OKE-optimized node image |

### Optional

| Variable | Default | Description |
|---|---|---|
| `cluster_name` | `gva2` | Display name prefix for worker nodes |
| `kubernetes_version` | `v1.34.1` | Kubernetes version matching the cluster |
| `cni_type` | `npn` | CNI plugin: `npn` (VCN-Native) or `flannel` |
| `node_count` | `2` | Number of worker nodes |
| `node_shape` | `VM.Standard.E4.Flex` | Compute shape (must be AMD for confidential) |
| `node_ocpus` | `4` | OCPUs per node |
| `node_memory_gb` | `64` | Memory (GB) per node |
| `node_boot_volume_gb` | `100` | Boot volume size (GB) |
| `ssh_public_key` | `""` | SSH public key for node access (omit to disable SSH) |
| `max_pods_per_node` | `31` | Max pods per node (VCN-Native CNI) |
| `enable_confidential_compute` | `true` | Enable AMD SEV memory encryption |
| `is_secure_boot_enabled` | `true` | Enable UEFI Secure Boot |
| `is_measured_boot_enabled` | `true` | Enable Measured Boot |
| `is_trusted_platform_module_enabled` | `true` | Enable vTPM |

## Confidential Computing

The `platform_config` block on each instance enables AMD SEV:

```hcl
platform_config {
  type                               = "AMD_VM"
  is_memory_encryption_enabled       = true   # AMD SEV - encrypts VM memory
  is_secure_boot_enabled             = true   # UEFI Secure Boot
  is_measured_boot_enabled           = true   # Boot attestation
  is_trusted_platform_module_enabled = true   # Virtual TPM
}
```

- `is_memory_encryption_enabled` is the core confidential computing feature
- The other three are optional shielded instance hardening settings
- All are `ForceNew` — changing any value destroys and recreates the node
- Requires AMD-based shapes (`VM.Standard.E3/E4/E5.Flex`)

## CNI Selection

Set `cni_type` to choose the networking model:

- **`npn`** (default) — VCN-Native Pod Networking. Pods get real VCN IPs from `pod_subnet_id`. Requires `pod_subnet_id` to be set.
- **`flannel`** — Flannel overlay networking. Pods use cluster-internal IPs. `pod_subnet_id` is ignored.

## Outputs

| Output | Description |
|---|---|
| `cluster_id` | OCID of the OKE cluster |
| `worker_instance_ids` | OCIDs of the worker instances |
| `worker_private_ips` | Private IPs of the worker instances |
| `kubeconfig_cmd` | Command to generate kubeconfig |
