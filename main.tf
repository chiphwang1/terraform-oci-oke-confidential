# =============================================================================
# Data Sources
# =============================================================================

data "oci_identity_availability_domains" "ads" {
  compartment_id = var.tenancy_ocid
}

data "oci_containerengine_cluster" "oke" {
  cluster_id = var.cluster_id
}

# =============================================================================
# Self-Managed Confidential Worker Nodes
# =============================================================================
#
# CONFIDENTIAL COMPUTING: These instances use AMD SEV (Secure Encrypted
# Virtualization) via the platform_config block. This encrypts VM memory
# with a per-VM key that is not accessible to the hypervisor, other VMs,
# or OCI operators. Requires AMD-based shapes (E3/E4/E5 Flex).
#
# Why self-managed instead of managed node pool?
# oci_containerengine_node_pool does NOT support platform_config, so
# confidential computing is only possible with self-managed instances.
# =============================================================================

resource "oci_core_instance" "confidential_worker" {
  count = var.node_count

  compartment_id      = var.compartment_ocid
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[count.index % length(data.oci_identity_availability_domains.ads.availability_domains)].name
  display_name        = "${var.cluster_name}-confidential-worker-${count.index}"
  shape               = var.node_shape

  shape_config {
    ocpus         = var.node_ocpus
    memory_in_gbs = var.node_memory_gb
  }

  source_details {
    source_type             = "image"
    source_id               = var.node_image_id
    boot_volume_size_in_gbs = var.node_boot_volume_gb
  }

  create_vnic_details {
    subnet_id        = var.worker_subnet_id
    assign_public_ip = true
    display_name     = "${var.cluster_name}-worker-vnic-${count.index}"
  }

  # ---------------------------------------------------------------------------
  # CONFIDENTIAL COMPUTING — AMD SEV platform configuration
  # ---------------------------------------------------------------------------
  # type: AMD_VM for E3/E4/E5 Flex shapes
  # is_memory_encryption_enabled: enables AMD SEV memory encryption (the core
  #   confidential computing feature — encrypts VM memory at the hardware level)
  # is_secure_boot_enabled: ensures only signed boot software runs
  # is_measured_boot_enabled: records boot measurements for attestation
  # is_trusted_platform_module_enabled: enables virtual TPM for key storage
  #
  # All settings are ForceNew — changing any value destroys and recreates the node.
  # ---------------------------------------------------------------------------
  platform_config {
    type                               = "AMD_VM"
    is_memory_encryption_enabled       = var.enable_confidential_compute  # <-- CONFIDENTIAL COMPUTING
    is_secure_boot_enabled             = var.is_secure_boot_enabled
    is_measured_boot_enabled           = var.is_measured_boot_enabled
    is_trusted_platform_module_enabled = var.is_trusted_platform_module_enabled
  }

  metadata = merge(
    {
      ssh_authorized_keys = var.ssh_public_key
      user_data = base64encode(templatefile("${path.module}/cloud-init.tftpl", {
        cluster_endpoint = split(":", data.oci_containerengine_cluster.oke.endpoints[0].private_endpoint)[0]
        cluster_ca_cert  = var.cluster_ca_cert
      }))
    },
    # VCN-Native Pod Networking metadata
    var.cni_type == "npn" ? {
      oke-native-pod-networking = "true"
      oke-max-pods              = tostring(var.max_pods_per_node)
      pod-subnets               = var.pod_subnet_id
    } : {}
  )
}
