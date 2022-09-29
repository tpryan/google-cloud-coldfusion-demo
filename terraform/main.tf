

resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}


locals {
  sacompute = "${data.google_project.project.number}-compute@developer.gserviceaccount.com"
  sabuild = "${data.google_project.project.number}@cloudbuild.gserviceaccount.com"
  DB_USER = "todo_user"
  DB_PASS = random_password.password.result
  DB_NAME = "todo"
  DB_PORT = "3306"
}



# Handle Permissions
variable "build_roles_list" {
  description = "The list of roles that build needs for"
  type        = list(string)
  default = [
    "roles/compute.instanceAdmin",
  ]
}


resource "google_project_iam_member" "allbuild" {
  for_each   = toset(var.build_roles_list)
  project    = data.google_project.project.number
  role       = each.key
  member     = "serviceAccount:${local.sabuild}"
  depends_on = [google_project_service.all]
}




data "google_project" "project" {
  project_id = var.project_id
}

variable "gcp_service_list" {
  description = "The list of apis necessary for the project"
  type        = list(string)
  default = [
    "cloudapis.googleapis.com",
    "sql-component.googleapis.com",
    "sqladmin.googleapis.com",
    "secretmanager.googleapis.com",
    "compute.googleapis.com",
    "servicenetworking.googleapis.com",
    "cloudbuild.googleapis.com",
  ]
}

resource "google_project_service" "all" {
  for_each           = toset(var.gcp_service_list)
  project            = data.google_project.project.number
  service            = each.key
  disable_on_destroy = false
}

resource "google_project_iam_member" "allrun" {
  project    = data.google_project.project.number
  role       = "roles/secretmanager.secretAccessor"
  member     = "serviceAccount:${local.sacompute}"
  depends_on = [google_project_service.all]
}

resource "google_compute_network" "main" {
  provider                = google-beta
  name                    = "${var.basename}-private-network"
  auto_create_subnetworks = true
  project                 = var.project_id
  depends_on = [google_project_service.all]
}

resource "google_compute_global_address" "main" {
  name          = "${var.basename}-vpc-address"
  provider      = google-beta
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.main.id
  project       = var.project_id
  depends_on    = [google_project_service.all]
}

resource "google_service_networking_connection" "main" {
  network                 = google_compute_network.main.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.main.name]
  depends_on              = [google_project_service.all]
}

resource "random_id" "id" {
  byte_length = 2
}

# Handle Database
resource "google_sql_database_instance" "main" {
  name             = "${var.basename}-db-${random_id.id.hex}"
  database_version = "MYSQL_5_7"
  region           = var.region
  project          = var.project_id
  settings {
    tier                  = "db-g1-small"
    disk_autoresize       = true
    disk_autoresize_limit = 0
    disk_size             = 10
    disk_type             = "PD_SSD"
    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.main.id
    }
    location_preference {
      zone = var.zone
    }
  }
  deletion_protection = false
  depends_on = [
    google_project_service.all,
    google_compute_global_address.main,
    google_service_networking_connection.main
  ]

  provisioner "local-exec" {
    working_dir = "../${path.module}/database"
    command     = "./load_schema.sh ${var.project_id} ${google_sql_database_instance.main.name} ${local.DB_PASS}"
  }
}




resource "google_secret_manager_secret" "DB_USER" {
  project = data.google_project.project.number
  replication {
    automatic = true
  }
  secret_id  = "DB_USER"
  depends_on = [google_project_service.all]
}

resource "google_secret_manager_secret_version" "DB_USER" {
  enabled     = true
  secret      = "projects/${data.google_project.project.number}/secrets/DB_USER"
  secret_data = local.DB_USER
  depends_on  = [google_project_service.all, google_secret_manager_secret.DB_USER]
}

resource "google_secret_manager_secret" "DB_PASS" {
  project = data.google_project.project.number
  replication {
    automatic = true
  }
  secret_id  = "DB_PASS"
  depends_on = [google_project_service.all]
}

resource "google_secret_manager_secret_version" "DB_PASS" {
  enabled     = true
  secret      = "projects/${data.google_project.project.number}/secrets/DB_PASS"
  secret_data = local.DB_PASS
  depends_on  = [google_project_service.all, google_secret_manager_secret.DB_PASS]
}

resource "google_secret_manager_secret" "DB_NAME" {
  project = data.google_project.project.number
  replication {
    automatic = true
  }
  secret_id  = "DB_NAME"
  depends_on = [google_project_service.all]
}

resource "google_secret_manager_secret_version" "DB_NAME" {
  enabled     = true
  secret      = "projects/${data.google_project.project.number}/secrets/DB_NAME"
  secret_data = local.DB_NAME
  depends_on  = [google_project_service.all, google_secret_manager_secret.DB_NAME]
}

resource "google_secret_manager_secret" "DB_PORT" {
  project = data.google_project.project.number
  replication {
    automatic = true
  }
  secret_id  = "DB_PORT"
  depends_on = [google_project_service.all]
}

resource "google_secret_manager_secret_version" "DB_PORT" {
  enabled     = true
  secret      = "projects/${data.google_project.project.number}/secrets/DB_PORT"
  secret_data = local.DB_PORT
  depends_on  = [google_project_service.all, google_secret_manager_secret.DB_PORT]
}

resource "google_secret_manager_secret" "DB_HOST" {
  project = data.google_project.project.number
  replication {
    automatic = true
  }
  secret_id  = "DB_HOST"
  depends_on = [google_project_service.all]
}

resource "google_secret_manager_secret_version" "DB_HOST" {
  enabled     = true
  secret      = "projects/${data.google_project.project.number}/secrets/DB_HOST"
  secret_data = google_sql_database_instance.main.private_ip_address
  depends_on  = [google_project_service.all, google_secret_manager_secret.DB_HOST]
}


resource "google_compute_firewall" "allow-coldfusion" {
  project       = var.project_id
  name          = "allow-coldfusion"
  network       = google_compute_network.main.name
  source_ranges = ["0.0.0.0/0"]
  target_tags = ["cfusion"]

  allow {
    protocol = "tcp"
    ports    = ["8500"]
  }
}

resource "google_compute_firewall" "allow-ssh-private" {
  project       = var.project_id
  name          = "allow-ssh-private"
  network       = google_compute_network.main.name
  source_ranges = ["0.0.0.0/0"]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}


resource "google_compute_instance" "main" {
  name         = var.basename
  machine_type = "e2-standard-2"
  zone         = var.zone
  project      = var.project_id
  tags         = ["http-server", "cfusion"]


  boot_disk {
    auto_delete = true
    device_name = var.basename
    initialize_params {
      image = "projects/ubuntu-os-cloud/global/images/ubuntu-2004-focal-v20220905"
      size  = "200"
      type  = "pd-balanced"
    }
  }

  network_interface {
    network = google_compute_network.main.id
    access_config {
      // Ephemeral public IP
    }
  }

  service_account {
    email  = local.sacompute
    scopes = ["cloud-platform"]
  }

  provisioner "local-exec" {
    working_dir = "../${path.module}/scripts"
    command     = "./install.sh ${var.project_id} ${google_compute_instance.main.name}"
  }

  depends_on = [google_project_service.all]
}
