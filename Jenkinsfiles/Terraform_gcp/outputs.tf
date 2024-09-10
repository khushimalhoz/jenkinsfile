output "pubsub_topic_name" {
  description = "The name of the Pub/Sub topic created"
  value       = google_pubsub_topic.my_topic.name
}

output "pubsub_subscription_name" {
  description = "The name of the Pub/Sub subscription created"
  value       = google_pubsub_subscription.my_subscription.name
}
