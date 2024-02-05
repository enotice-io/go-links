resource "google_artifact_registry_repository" "this" {
  location      = var.region
  repository_id = var.app-name
  description   = "Repository for ${var.app-name} application"
  format        = "DOCKER"
}

resource "null_resource" "image" {
  depends_on = [google_artifact_registry_repository.this]
  provisioner "local-exec" {
    command = "cd ${path.module}/.. && ./docker_scripts/image.sh ${var.deploy} ${var.region} ${var.project} ${var.app-name} ${var.package_version}"
  }
  triggers = {
    always_run = timestamp()
  }
}