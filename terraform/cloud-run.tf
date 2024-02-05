resource "random_string" "random" {
  length  = 32
  special = false
}

resource "google_cloud_run_v2_service" "this" {
  provider     = google-beta
  depends_on   = [null_resource.image]
  name         = var.app-name
  location     = var.region
  launch_stage = "BETA"

  client_version = var.package_version



  template {
    containers {
      image = "${var.region}-docker.pkg.dev/${var.project}/${var.app-name}/${var.app-name}:${var.package_version}"
      env {
        name  = "DATABASE_URL"
        value = "postgresql://${google_sql_user.db_user.name}:${random_password.password.result}@${google_sql_database_instance.this.private_ip_address}:5432/${google_sql_database.this.name}"
      }
      env {
        name  = "FLASK_SECRET"
        value = random_string.random.result
      }
      env {
        name  = "GOOGLE_OAUTH_CLIENT_JSON"
        value = data.google_secret_manager_secret_version_access.basic.secret_data
      }
    }
    scaling {
      min_instance_count = var.min_instances
      max_instance_count = 100 // this is the default
    }
    timeout = "15s"
    vpc_access {
      network_interfaces {
        network = google_compute_network.private_network.name
      }
    }
  }
}

## Allow public invocations
resource "google_cloud_run_service_iam_binding" "default" {
  location = google_cloud_run_v2_service.this.location
  service  = google_cloud_run_v2_service.this.name
  role     = "roles/run.invoker"
  members = [
    "allUsers"
  ]
}