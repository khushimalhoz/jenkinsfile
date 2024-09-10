provider "google" {
  project     = var.project_id
  region      = var.region
  credentials = file("/home/khushimalhoz/cars24/Terraform/quantum-ally-428107-d9-de45cbaba432.json")

}

# Create the main Pub/Sub topic
resource "google_pubsub_topic" "my_topic" {
  name    = var.topic_name
  project = var.project_id

  message_retention_duration = var.message_retention_duration

  message_storage_policy {
    allowed_persistence_regions = var.allowed_storage_regions
  }
}

# Create the dead-letter Pub/Sub topic
resource "google_pubsub_topic" "dead_letter_topic" {
  name    = var.dead_letter_topic
  project = var.project_id

  message_retention_duration = var.message_retention_duration

  message_storage_policy {
    allowed_persistence_regions = var.allowed_storage_regions
  }
}

# Create a Pub/Sub subscription
resource "google_pubsub_subscription" "my_subscription" {
  name  = var.subscriber_name
  topic = google_pubsub_topic.my_topic.name

  ack_deadline_seconds = var.ack_deadline_seconds

  # Optional Dead Letter Policy
  dead_letter_policy {
    dead_letter_topic     = "projects/${var.project_id}/topics/${google_pubsub_topic.dead_letter_topic.id}"
    max_delivery_attempts = var.max_delivery_attempts
  }
}
