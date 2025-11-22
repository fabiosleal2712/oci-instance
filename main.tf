terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 5.0"
    }
  }
}

provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
  region           = var.region
}

# Variables
variable "tenancy_ocid" {
  description = "OCID do Tenancy"
  type        = string
}

variable "user_ocid" {
  description = "OCID do User"
  type        = string
}

variable "fingerprint" {
  description = "Fingerprint da API Key"
  type        = string
}

variable "private_key_path" {
  description = "Caminho para a chave privada da API"
  type        = string
}

variable "region" {
  description = "Região da Oracle Cloud"
  type        = string
  default     = "us-ashburn-1"
}

variable "compartment_ocid" {
  description = "OCID do Compartment"
  type        = string
}

variable "ssh_public_key" {
  description = "Chave SSH pública para acesso às VMs"
  type        = string
}

variable "ocpu_count" {
  description = "Número de OCPUs (Always Free: até 4)"
  type        = number
  default     = 4
}

variable "memory_gb" {
  description = "Memória em GB (Always Free: até 24GB)"
  type        = number
  default     = 24
}

variable "boot_volume_gb" {
  description = "Tamanho do disco de boot em GB (Always Free: até 200GB)"
  type        = number
  default     = 200
}

# Data sources
data "oci_identity_availability_domains" "ads" {
  compartment_id = var.tenancy_ocid
}

# Pega a imagem mais recente do Ubuntu para ARM
data "oci_core_images" "ubuntu_arm" {
  compartment_id           = var.compartment_ocid
  operating_system         = "Canonical Ubuntu"
  operating_system_version = "22.04"
  shape                    = "VM.Standard.A1.Flex"
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

# VCN (Virtual Cloud Network)
resource "oci_core_vcn" "vcn" {
  compartment_id = var.compartment_ocid
  cidr_blocks    = ["10.0.0.0/16"]
  display_name   = "vcn-arm-instance"
  dns_label      = "vcnarm"
}

# Internet Gateway
resource "oci_core_internet_gateway" "ig" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "internet-gateway"
  enabled        = true
}

# Route Table
resource "oci_core_route_table" "rt" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "route-table"

  route_rules {
    network_entity_id = oci_core_internet_gateway.ig.id
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
  }
}

# Security List
resource "oci_core_security_list" "sl" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.vcn.id
  display_name   = "security-list"

  # Regras de saída (egress)
  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
  }

  # Regras de entrada (ingress)
  # SSH
  ingress_security_rules {
    protocol = "6" # TCP
    source   = "0.0.0.0/0"
    tcp_options {
      min = 22
      max = 22
    }
  }

  # HTTP
  ingress_security_rules {
    protocol = "6" # TCP
    source   = "0.0.0.0/0"
    tcp_options {
      min = 80
      max = 80
    }
  }

  # HTTPS
  ingress_security_rules {
    protocol = "6" # TCP
    source   = "0.0.0.0/0"
    tcp_options {
      min = 443
      max = 443
    }
  }

  # ICMP (ping)
  ingress_security_rules {
    protocol = "1" # ICMP
    source   = "0.0.0.0/0"
  }
}

# Subnet
resource "oci_core_subnet" "subnet" {
  compartment_id    = var.compartment_ocid
  vcn_id            = oci_core_vcn.vcn.id
  cidr_block        = "10.0.1.0/24"
  display_name      = "subnet-arm"
  dns_label         = "subnetarm"
  route_table_id    = oci_core_route_table.rt.id
  security_list_ids = [oci_core_security_list.sl.id]
}

# Variável para controlar quantos ADs tentar
variable "try_all_ads" {
  description = "Tentar criar em todos os Availability Domains (0-2 para AD-1, AD-2, AD-3)"
  type        = number
  default     = 0  # Por padrão, tenta apenas 1 AD. Use 2 para tentar todos os 3 ADs
}

# Instância ARM - Tenta em múltiplos Availability Domains
resource "oci_core_instance" "arm_instance" {
  count = var.try_all_ads + 1  # Se try_all_ads = 2, cria 3 instâncias (índices 0, 1, 2)
  
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[count.index].name
  compartment_id      = var.compartment_ocid
  shape               = "VM.Standard.A1.Flex"
  display_name        = "arm-instance-ad${count.index + 1}"

  shape_config {
    ocpus         = var.ocpu_count
    memory_in_gbs = var.memory_gb
  }

  source_details {
    source_type             = "image"
    source_id               = data.oci_core_images.ubuntu_arm.images[0].id
    boot_volume_size_in_gbs = var.boot_volume_gb
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.subnet.id
    assign_public_ip = true
    display_name     = "vnic-arm-ad${count.index + 1}"
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
  }

  # Configuração de timeout para lidar com problemas de capacidade
  timeouts {
    create = "60m"
  }
}

# Outputs
output "instance_ids" {
  description = "OCIDs das instâncias criadas"
  value       = oci_core_instance.arm_instance[*].id
}

output "public_ips" {
  description = "IPs públicos das instâncias"
  value       = oci_core_instance.arm_instance[*].public_ip
}

output "private_ips" {
  description = "IPs privados das instâncias"
  value       = oci_core_instance.arm_instance[*].private_ip
}

output "ssh_commands" {
  description = "Comandos SSH para conectar nas instâncias"
  value       = [for instance in oci_core_instance.arm_instance : "ssh ubuntu@${instance.public_ip}"]
}

output "availability_domains" {
  description = "Availability Domains onde as instâncias foram criadas"
  value       = oci_core_instance.arm_instance[*].availability_domain
}
