terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "3.51.0"
      }
   }
}

# Setting Hashicorp provider for GCP and the service account

provider "google" {
  credentials = file("JSON_CREDS_FILE")
  project = "PROJECT_NAME"
  region =  "REGION_TO_DEPLOY"
  zone = "ZONE_TO_DEPLOY"
}

resource "random_string" "text" {
  length = 9
  special =  false
  upper = false
}

# Storage bucket withj lifecycle of 2 days

resource "google_storage_bucket" "my_bucket" {
  name = "my_bucket_${random_string.text.result}"
  location = "REGION_TO_DEPLOY"
  force_destroy = true

  lifecycle_rule {
    condition {
      age = 2
    }
    action {
      type = "Delete"
    }
  }
}

resource "google_compute_address" "vm_static_ip" {
  name = "terra-static-ip"
}

# Creating VPC network

resource "google_compute_network" "vpc_network" {
  name = "terra-network"
  mtu = 1500
  routing_mode = "GLOBAL"
  description = "Network created using Terraform"
  auto_create_subnetworks = "false"
}

#Creating VPC subnetwork

resource "google_compute_subnetwork" "vpc_subnet" {
  name = "terra-subnet"
  ip_cidr_range = "10.0.0.0/16"
  region = "REGION_TO_DEPLOY"
  network = google_compute_network.vpc_network.id
}

# Assigning custom IP for the VM

resource "google_compute_address" "internal_with_subnet_and_address" {
  name = "vm-address"
  subnetwork = google_compute_subnetwork.vpc_subnet.id
  address_type = "INTERNAL"
  address = "10.0.41.41"
  region = "REGION_TO_DEPLOY"
}

# Firewall is only allowing HTTP for Apache traffic

resource "google_compute_firewall" "http-server" {
  name    = "terra-firewall"
  network = google_compute_network.vpc_network.name
  priority = 1500

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }
  # Targets for the VM
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["http-server"]
}

# Deploying VM

resource "google_compute_instance" "vm_instance" {
 name = "terra-vm"
 machine_type = "f1-micro"
 tags = ["http-server"]

 metadata_startup_script = "sudo apt-get -y update; sudo apt install -y apache2"
 
 boot_disk {
   initialize_params {
     image = "projects/ubuntu-os-cloud/global/images/ubuntu-1604-xenial-v20201210"
   }
 }

 network_interface {
   subnetwork = google_compute_subnetwork.vpc_subnet.id
   access_config {
       nat_ip = google_compute_address.vm_static_ip.address
  }
 }
}

# Spanshot saving the boot disk in US

resource "google_compute_snapshot" "snapshot" {
  name        = "terra-snapshot"
  source_disk = google_compute_instance.vm_instance.name
  zone        = "VM_ZONE"
  labels = {
    my_label = "value"
  }
  storage_locations = ["BACKUP_REGION"]
}

