Deploying GCP infrastructure using Terraform
===========
Terraform code to deploy an Apache server instance linked to one subnetwork under firewall rules 

**Author: Javier Suárez Sanz**


## What does it do?
   - Automated deployment of a Ubuntu 16.04 with an Apache already installed. This Terraform code deploys one instance with one network and subnetwork linked with a personalized INTERNAL IP and controlled by firewall rules avoiding SSH connections to this VM. One Metadata Startup Script is deploying an Apache server to check that using the EXTERNAL IP Apache server is running altought you can't access to this VM using SSH. The VM disk is backup to US.

     * Use Hashicorp 3.51.0 version which is the latest one.
     * Use GCP service account to use with Terraform (find "terraform-creds.json" in this repository).
     * Deploy one storage bucket using "google_storage_bucket" with random name.
       - Configured with 2 days as lifecycle with Delete action. Force destroy will delete this bucket after 2 days altought there is data inside.
     * This VM will use two network interfaces, INTERNAL and EXTERNAL.
       - Deploy one VM static IP using "google_compute_address" as EXTERNAL ephimeral IP.
       - Deploy one vpc_network that could be accesed in a GLOBAL mode using the parameter routing_mode to provide access out of the REGION using "google_compute_network".
       - Deploy one vpc_subnet in the personalized CIDR of "10.0.0.0/16" in the same region as the instance itself -in this case "europe-west3"- using "google_compute_subnetwork".
       - Deploy one VM INTERNAL IP using "google_compute_address" again but in this case setting address_type as INTERNAL with the IP "10.0.41.41".
       - Deploy one FIREWALL to control the management traffic by SSH connections using "google_compute_firewall".
         This firewall is allowing HTTP traffic and it's blocking SSH connections to this VM (screenshots in the repository with Apache running and SSH blocked)
       - Deploy one VM itself with the parameters below using "google_compute_instance" with the little VM size f1-micro as test purposes.
         Using boot_disk to deploy Ubuntu 16.04 Xenial.
         Using "metadata_startup_script" to deploy one Apache server inside this VM to test.
     * **Baseline BACKUP**: One snapshot of the VM disk is stored in a different region, in this case US Central location as base DR natural disaster purposes using "google_compute_snapshot".

## How to deploy it

* Change default values following your project and resources ones. 

  ````credentials = file("JSON_CREDS_FILE")````

  ````project = "PROJECT_NAME"````

  ````region =  "REGION_TO_DEPLOY"````

  ````zone = "ZONE_TO_DEPLOY"````


* Test it with: ````terraform validate````
* Plan and delopy the infrastructure: ````terraform plan```` (Higher version than Terraform 0.11.0)

