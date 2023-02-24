resource "google_container_cluster" "my-gk-clu" {
  name = "my-gk-clu"
  location = "asia-east1-a"
  initial_node_count = 1
  remove_default_node_pool = true
  network = google_compute_network.vpc-google-network.name
  subnetwork = google_compute_subnetwork.restricted-subnetwork.name
  node_config {
      preemptible = true
      # tags = [ "private-rules" ]
      
      machine_type = "e2-standard-4"
      service_account = google_service_account.gke-service-acc.email
      oauth_scopes = [ 
        "https://www.googleapis.com/auth/cloud-platform"
       ]
    }
  private_cluster_config {
    enable_private_endpoint = true
    enable_private_nodes = true
    master_ipv4_cidr_block = "172.16.0.0/28"
   
  }

 


  ip_allocation_policy {
  }





  master_authorized_networks_config {
    cidr_blocks {
      display_name = "manged-subnet"
      cidr_block = "10.0.0.0/24"
    }
    cidr_blocks {
      display_name = "restricted-subnetwork"
      cidr_block = "10.0.1.0/24"
    }
  }

  

}

resource "google_container_node_pool" "gk-worker-nodes" {
    name = "gk-worker-nodes"
    cluster = google_container_cluster.my-gk-clu.name
    location = "asia-east1-a"
    node_count = 1

    node_config {
      preemptible = true
      # tags = [ "private-rules" ]
      
      machine_type = "e2-standard-4"
      service_account = google_service_account.gke-service-acc.email
      oauth_scopes = [ 
        "https://www.googleapis.com/auth/cloud-platform"
       ]
    }
}