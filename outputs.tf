output "taxonomy_list" {
  value       = [for taxonomy in google_data_catalog_taxonomy.taxonomy : taxonomy.name]
  description = "The list of taxonomies"
}

output "policy_tag_list" {
  value       = [for tag in merge(google_data_catalog_policy_tag.taxonomy_policy_tags, google_data_catalog_policy_tag.level_one, google_data_catalog_policy_tag.level_two) : tag.name]
  description = "List of all policy tags list"
}

output "policy_tag_parent_list" {
  value       = [for tag in google_data_catalog_policy_tag.taxonomy_policy_tags : tag.name]
  description = "List of parent policy tags list"
}

output "policy_tag_level_one_list" {
  value       = [for tag in google_data_catalog_policy_tag.level_one : tag.name]
  description = "List of level one policy tags  list"
}

output "policy_tag_level_two_list" {
  value       = [for tag in google_data_catalog_policy_tag.level_two : tag.name]
  description = "List of level two policy tags list"
}

output "policy_tag_level_three_list" {
  value       = [for tag in google_data_catalog_policy_tag.level_three : tag.name]
  description = "List of level three policy tags list"
}

output "policy_tag_level_four_list" {
  value       = [for tag in google_data_catalog_policy_tag.level_four : tag.name]
  description = "List of level four policy tags list"
}

output "data_masking_policy_list" {
  value       = [for policy in google_bigquery_datapolicy_data_policy.data_masking_policy : policy.name]
  description = "List data masking policies list"
}

output "column_level_security_policy_list" {
  value       = [for policy in google_bigquery_datapolicy_data_policy.column_level_sec_policy : policy.name]
  description = "List column level policy list"
}
