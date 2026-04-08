# -----------------------------------------------------------------------------
# Identity / Authentication
# -----------------------------------------------------------------------------

variable "tenancy_ocid" {
  type        = string
  description = "OCID of the OCI tenancy."
}

variable "compartment_ocid" {
  type        = string
  description = "OCID of the compartment where resources will be created."
}

variable "region" {
  type        = string
  description = "OCI region (e.g. us-ashburn-1)."
}

# -----------------------------------------------------------------------------
# Existing Cluster
# -----------------------------------------------------------------------------

variable "cluster_id" {
  type        = string
  description = "OCID of the existing OKE cluster to add self-managed nodes to."
}

variable "cluster_ca_cert" {
  type        = string
  description = "Base64-encoded CA certificate of the OKE cluster (from kubeconfig certificate-authority-data)."
}

variable "cluster_name" {
  type        = string
  description = "Display name prefix for the self-managed worker nodes."
  default     = "gva2"
}

variable "kubernetes_version" {
  type        = string
  description = "Kubernetes version matching the existing cluster."
  default     = "v1.34.1"
}

variable "cni_type" {
  type        = string
  description = "CNI plugin: npn (VCN-Native Pod Networking) or flannel."
  default     = "npn"

  validation {
    condition     = contains(["npn", "flannel"], var.cni_type)
    error_message = "cni_type must be 'npn' or 'flannel'."
  }
}

# -----------------------------------------------------------------------------
# Existing Network (subnets in the gva2 VCN)
# -----------------------------------------------------------------------------

variable "worker_subnet_id" {
  type        = string
  description = "OCID of the existing subnet for worker node VNICs."
}

variable "pod_subnet_id" {
  type        = string
  description = "OCID of the existing subnet for pod IPs (VCN-Native CNI)."
}

# -----------------------------------------------------------------------------
# Self-Managed Worker Nodes
# -----------------------------------------------------------------------------

variable "node_count" {
  type        = number
  description = "Number of self-managed worker nodes to create."
  default     = 2
}

variable "node_shape" {
  type        = string
  description = "Compute shape for worker nodes. Must be AMD-based for confidential compute."
  default     = "VM.Standard.E4.Flex"
}

variable "node_ocpus" {
  type        = number
  description = "Number of OCPUs per worker node (Flex shapes)."
  default     = 4
}

variable "node_memory_gb" {
  type        = number
  description = "Memory in GB per worker node (Flex shapes)."
  default     = 64
}

variable "node_boot_volume_gb" {
  type        = number
  description = "Boot volume size in GB for each worker node."
  default     = 100
}

variable "node_image_id" {
  type        = string
  description = "OCID of the OKE-optimized node image."
}

variable "ssh_public_key" {
  type        = string
  description = "SSH public key for worker node access. Optional — omit to disable SSH."
  default     = ""
}

variable "max_pods_per_node" {
  type        = number
  description = "Maximum number of pods per node when using VCN-Native CNI."
  default     = 31
}

# -----------------------------------------------------------------------------
# Confidential Computing (AMD SEV)
# -- These settings enable AMD Secure Encrypted Virtualization on worker nodes.
# -- Requires an AMD-based shape (VM.Standard.E3/E4/E5.Flex).
# -- All settings are ForceNew: changing them destroys and recreates nodes.
# -----------------------------------------------------------------------------

variable "enable_confidential_compute" {
  type        = bool
  description = "[CONFIDENTIAL] Enable AMD SEV memory encryption on worker nodes."
  default     = true
}

variable "is_secure_boot_enabled" {
  type        = bool
  description = "[CONFIDENTIAL] Enable UEFI Secure Boot on worker nodes."
  default     = true
}

variable "is_measured_boot_enabled" {
  type        = bool
  description = "[CONFIDENTIAL] Enable Measured Boot on worker nodes."
  default     = true
}

variable "is_trusted_platform_module_enabled" {
  type        = bool
  description = "[CONFIDENTIAL] Enable vTPM (Trusted Platform Module) on worker nodes."
  default     = true
}
