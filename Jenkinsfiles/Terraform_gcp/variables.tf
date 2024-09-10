variable "region" {
  description = "Google project ID to be used"
  type        = string
}

variable "project_id" {
  description = "Google project ID to be used"
  type        = string
}

variable "topic_name" {
  description = "Name of the Pub/Sub topic"
  type        = string
}

variable "subscriber_name" {
  description = "Name of the Pub/Sub subscription"
  type        = string
}

variable "service_account" {
  description = "Service account email to be used"
  type        = string
}

variable "message_retention_duration" {
  description = "Retention duration for Pub/Sub messages"
  type        = string
}

variable "dead_letter_topic" {
  description = "Dead letter topic for failed messages"
  type        = string
}

variable "max_delivery_attempts" {
  description = "Max delivery attempts before sending to dead letter topic"
  type        = number
}

variable "allowed_storage_regions" {
  description = "Comma-separated list of allowed storage regions for messages"
  type        = list(string)
}

variable "ack_deadline_seconds" {
  description = "Time limit for message acknowledgment in seconds"
  type        = number

}
