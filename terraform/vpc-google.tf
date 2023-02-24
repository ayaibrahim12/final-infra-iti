resource "google_project_service" "compute" {
  service = "compute.googleapis.com"
}
resource "google_project_service" "container" {
  service = "container.googleapis.com"
}

resource "google_compute_network" "vpc-google-network" {
  name                    = "network"
  auto_create_subnetworks = false
 project = "aya-ibrahim79632"
}
resource "google_compute_subnetwork" "manged-subnet" {
  name = "manged-subnet"
  region = "asia-east1"
  ip_cidr_range = "10.0.0.0/24"
  network = google_compute_network.vpc-google-network.self_link
} 

resource "google_compute_subnetwork" "restricted-subnetwork" {
  name          = "restricted-subnetwork"
  ip_cidr_range = "10.0.1.0/24"
  network       = google_compute_network.vpc-google-network.self_link
  region        = "asia-east1"
  private_ip_google_access = true

  secondary_ip_range {
    range_name    = "secondary-ip-range"
    ip_cidr_range = "10.0.4.0/24"
  }
}
resource "google_compute_firewall" "http-web" {
  name    = "http-web"
  network = google_compute_network.vpc-google-network.name
  allow {
    protocol = "tcp"
    ports    = ["80","443"]
  }
  source_ranges = ["0.0.0.0/0"]
}
resource "google_compute_router" "router-name" {
  name = "router-name"
  network = google_compute_network.vpc-google-network.self_link
region = google_compute_subnetwork.manged-subnet.region
}

resource "google_compute_router_nat" "my-nat" {
  name                  = "my-nat"
  router                = google_compute_router.router-name.name
  region = google_compute_router.router-name.region
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  nat_ip_allocate_option = "AUTO_ONLY"
 
  
}
resource "google_service_account" "instance-vm" {
  account_id = "instance-vm"
  display_name = "instance-vm"
}
resource "google_service_account" "gke-service-acc" {
  account_id   = "gke-service-acc"
  display_name = "gke-service-acc"
}
resource "google_project_iam_member" "instance" {
  project = "aya-ibrahim79632"
  role = "roles/container.admin"
  member = "serviceAccount:${google_service_account.instance-vm.email}"
}
resource "google_project_iam_member" "gke_sa" {
  role    = "roles/storage.admin"
  member  = "serviceAccount:${google_service_account.gke-service-acc.email}"
  project = "aya-ibrahim79632"
}
resource "google_project_iam_member" "gke_sa-container" {
  role    = "roles/container.admin"
  member  = "serviceAccount:${google_service_account.gke-service-acc.email}"
  project = "aya-ibrahim79632"
}
resource "google_project_iam_member" "gke_sa-storage" {
  role    = "roles/storage.objectAdmin"
  member  = "serviceAccount:${google_service_account.gke-service-acc.email}"
  project = "aya-ibrahim79632"
}
resource "google_compute_instance" "instance-private" {
  name = "instance-private"
  machine_type = "f1-micro"
  zone         = "asia-east1-a"


  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-1804-lts"
    }
  }
  tags = ["ssh"]
  service_account {
    email = google_service_account.instance-vm.email
    scopes = [ "https://www.googleapis.com/auth/cloud-platform" ]
  }
    network_interface {
      subnetwork = google_compute_subnetwork.manged-subnet.self_link
    }

  metadata_startup_script = file("scop-script.sh")

}
resource "google_compute_firewall" "ssh" {
  project = "aya-ibrahim79632"
  name = "ssh"
  network = google_compute_network.vpc-google-network.name
  priority = 100
  direction = "INGRESS"
  allow {
    protocol = "tcp"
    ports = ["22","80"]
  }


  target_tags = ["ssh"]
  source_ranges = ["35.235.240.0/20","41.199.23.235"]

}