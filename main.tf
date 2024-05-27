provider "google" {
 project                = local.project
 region                 = local.region
}


locals {
  # yaml file for the config
  config_file = yamldecode(file("${path.cwd}/config/config_example.yaml"))

  project = local.config_file.project_id
  region  = local.config_file.region

  taxonomies = flatten(local.config_file.taxonomy)

  # get policy tags
  policy_tags = flatten([for tax in local.config_file.taxonomy :
    ([for tag in lookup(tax, "policy_tags", {}) :
      {
        taxonomy    = tax.id
        id          = tag.id
        description = tag.description
    }])


  ])
  
  child_one = flatten([for tax in local.config_file.taxonomy :
    ([for tag in lookup(tax, "policy_tags", {}) :
      [for level_one in lookup(tag, "level_one", {}) :
        {
          taxonomy          = tax.id
          id                = level_one.id
          parent_policy_tag = tag.id
          description       = level_one.description
      }]

    ])


  ])
  
  child_two = flatten([for tax in local.config_file.taxonomy :
    ([for tag in lookup(tax, "policy_tags", {}) :
      [for level_one in lookup(tag, "level_one", {}) :
        [for level_two in lookup(level_one, "level_two", {}) :
          {
            taxonomy          = tax.id
            id                = level_two.id
            parent_policy_tag = level_one.id
            description       = level_two.description
          }
        ]

  ]])])

  child_three = flatten([for tax in local.config_file.taxonomy :
    ([for tag in lookup(tax, "policy_tags", {}) :
      [for level_one in lookup(tag, "level_one", {}) :
        [for level_two in lookup(level_one, "level_two", {}) :
          [for level_three in lookup(level_two, "level_three", {}) :
            {
              taxonomy          = tax.id
              id                = level_three.id
              parent_policy_tag = level_two.id
              description       = level_three.description
            }
          ]
        ]

  ]])])

  child_four = flatten([for tax in local.config_file.taxonomy :
    ([for tag in lookup(tax, "policy_tags", {}) :
      [for level_one in lookup(tag, "level_one", {}) :
        [for level_two in lookup(level_one, "level_two", {}) :
          [for level_three in lookup(level_two, "level_three", {}) :
            [for level_four in lookup(level_three, "level_four", {}) :
              {
                taxonomy          = tax.id
                id                = level_four.id
                parent_policy_tag = level_three.id
                description       = level_four.description
              }
            ]
          ]
        ]

  ]])])

  masked_readers = flatten([for role in local.config_file.iam_roles.masked_reader_policy :
    {
      policy_name = role.policy_name
      role        = "roles/bigquerydatapolicy.maskedReader"
      members     = role.members
    }
  ])

  finegrained_readers_access = flatten([for role in local.config_file.iam_roles.finegrained_reader_access :
    {
      policy_name = role.policy_name
      role        = "roles/datacatalog.categoryFineGrainedReader"
      members     = role.members
    }
  ])

  # Security - column level and masking
  security_column_lists = flatten([for policy in local.config_file.security.column_level_sec :
    {
      data_policy_id = policy.data_policy_id
      policy_tag     = policy.policy_tag
    }
  ])

  security_maskings = flatten([for policy in local.config_file.security.masking :
    {
      data_policy_id = policy.data_policy_id
      policy_tag     = policy.policy_tag
      masking_rule   = policy.masking_rule
    }
  ])

}

resource "google_data_catalog_taxonomy" "taxonomy" {
  for_each = { for k, v in local.taxonomies : k => v }

  project                = local.project
  region                 = local.region
  display_name           = each.value.id
  description            = each.value.description
  activated_policy_types = each.value.activated_policy_types
}

resource "google_data_catalog_policy_tag" "taxonomy_policy_tags" {
  for_each = { for k, v in local.policy_tags : k => v }

  display_name = each.value.id
  description  = each.value.description
  taxonomy     = [for k, v in values(google_data_catalog_taxonomy.taxonomy) : v.id if v.display_name == each.value.taxonomy][0]
  depends_on   = [google_data_catalog_taxonomy.taxonomy]

}

resource "google_data_catalog_policy_tag" "level_one" {
  for_each = { for k, v in local.child_one : k => v }

  display_name      = each.value.id
  description       = each.value.description
  taxonomy          = [for k, v in values(google_data_catalog_taxonomy.taxonomy) : v.id if v.display_name == each.value.taxonomy][0]
  parent_policy_tag = [for k, v in values(google_data_catalog_policy_tag.taxonomy_policy_tags) : v.id if v.display_name == each.value.parent_policy_tag][0]
  depends_on        = [google_data_catalog_policy_tag.taxonomy_policy_tags, google_data_catalog_taxonomy.taxonomy]

}

resource "google_data_catalog_policy_tag" "level_two" {
  for_each = { for k, v in local.child_two : k => v }

  display_name      = each.value.id
  description       = each.value.description
  taxonomy          = [for k, v in values(google_data_catalog_taxonomy.taxonomy) : v.id if v.display_name == each.value.taxonomy][0]
  parent_policy_tag = [for k, v in values(google_data_catalog_policy_tag.level_one) : v.id if v.display_name == each.value.parent_policy_tag][0]
  depends_on        = [google_data_catalog_taxonomy.taxonomy, google_data_catalog_policy_tag.level_one, google_data_catalog_policy_tag.taxonomy_policy_tags]

}

resource "google_data_catalog_policy_tag" "level_three" {
  for_each = { for k, v in local.child_three : k => v }

  display_name      = each.value.id
  description       = each.value.description
  taxonomy          = [for k, v in values(google_data_catalog_taxonomy.taxonomy) : v.id if v.display_name == each.value.taxonomy][0]
  parent_policy_tag = [for k, v in values(google_data_catalog_policy_tag.level_two) : v.id if v.display_name == each.value.parent_policy_tag][0]
  depends_on        = [google_data_catalog_policy_tag.level_two, google_data_catalog_taxonomy.taxonomy, google_data_catalog_policy_tag.level_one, google_data_catalog_policy_tag.taxonomy_policy_tags]

}

resource "google_data_catalog_policy_tag" "level_four" {
  for_each = { for k, v in local.child_four : k => v }

  display_name      = each.value.id
  description       = each.value.description
  taxonomy          = [for k, v in values(google_data_catalog_taxonomy.taxonomy) : v.id if v.display_name == each.value.taxonomy][0]
  parent_policy_tag = [for k, v in values(google_data_catalog_policy_tag.level_three) : v.id if v.display_name == each.value.parent_policy_tag][0]
  depends_on        = [google_data_catalog_policy_tag.level_three, google_data_catalog_policy_tag.level_two, google_data_catalog_taxonomy.taxonomy, google_data_catalog_policy_tag.level_one, google_data_catalog_policy_tag.taxonomy_policy_tags]

}

resource "google_bigquery_datapolicy_data_policy" "column_level_sec_policy" {
  for_each = { for i, n in local.security_column_lists : i => n }

  location         = local.config_file.region
  data_policy_id   = each.value.data_policy_id
  policy_tag       = contains(values(google_data_catalog_policy_tag.taxonomy_policy_tags)[*].display_name, each.value.policy_tag) ? [for k, v in values(google_data_catalog_policy_tag.taxonomy_policy_tags) : v.name if v.display_name == each.value.policy_tag][0] : (contains(values(google_data_catalog_policy_tag.level_one)[*].display_name, each.value.policy_tag) ? [for k, v in values(google_data_catalog_policy_tag.level_one) : v.name if v.display_name == each.value.policy_tag][0] : (contains(values(google_data_catalog_policy_tag.level_two)[*].display_name, each.value.policy_tag) ? [for k, v in values(google_data_catalog_policy_tag.level_two) : v.name if v.display_name == each.value.policy_tag][0] : (contains(values(google_data_catalog_policy_tag.level_three)[*].display_name, each.value.policy_tag) ? [for k, v in values(google_data_catalog_policy_tag.level_three) : v.name if v.display_name == each.value.policy_tag][0] : (contains(values(google_data_catalog_policy_tag.level_four)[*].display_name, each.value.policy_tag) ? [for k, v in values(google_data_catalog_policy_tag.level_four) : v.name if v.display_name == each.value.policy_tag][0] : null))))
  data_policy_type = "COLUMN_LEVEL_SECURITY_POLICY"
  depends_on       = [google_data_catalog_policy_tag.taxonomy_policy_tags, google_data_catalog_policy_tag.level_one, google_data_catalog_policy_tag.level_two, google_data_catalog_policy_tag.level_three, google_data_catalog_policy_tag.level_four]
}

resource "google_bigquery_datapolicy_data_policy" "data_masking_policy" {
  for_each = { for key, val in local.security_maskings : key => val }

  location         = local.config_file.region
  data_policy_id   = each.value.data_policy_id
  policy_tag       = contains(values(google_data_catalog_policy_tag.taxonomy_policy_tags)[*].display_name, each.value.policy_tag) ? [for k, v in values(google_data_catalog_policy_tag.taxonomy_policy_tags) : v.name if v.display_name == each.value.policy_tag][0] : (contains(values(google_data_catalog_policy_tag.level_one)[*].display_name, each.value.policy_tag) ? [for k, v in values(google_data_catalog_policy_tag.level_one) : v.name if v.display_name == each.value.policy_tag][0] : (contains(values(google_data_catalog_policy_tag.level_two)[*].display_name, each.value.policy_tag) ? [for k, v in values(google_data_catalog_policy_tag.level_two) : v.name if v.display_name == each.value.policy_tag][0] : (contains(values(google_data_catalog_policy_tag.level_three)[*].display_name, each.value.policy_tag) ? [for k, v in values(google_data_catalog_policy_tag.level_three) : v.name if v.display_name == each.value.policy_tag][0] : (contains(values(google_data_catalog_policy_tag.level_four)[*].display_name, each.value.policy_tag) ? [for k, v in values(google_data_catalog_policy_tag.level_four) : v.name if v.display_name == each.value.policy_tag][0] : null))))
  data_policy_type = "DATA_MASKING_POLICY"
  data_masking_policy {
    predefined_expression = each.value.masking_rule
  }
  depends_on = [google_data_catalog_policy_tag.taxonomy_policy_tags, google_data_catalog_policy_tag.level_one, google_data_catalog_policy_tag.level_two, google_data_catalog_policy_tag.level_three, google_data_catalog_policy_tag.level_four]
}

resource "google_data_catalog_policy_tag_iam_binding" "finegrained_reader_access_binding" {
  for_each   = { for k, v in local.finegrained_readers_access : k => v }
  
  policy_tag = contains(values(google_data_catalog_policy_tag.taxonomy_policy_tags)[*].display_name, each.value.policy_name) ? [for k, v in values(google_data_catalog_policy_tag.taxonomy_policy_tags) : v.name if v.display_name == each.value.policy_name][0] : (contains(values(google_data_catalog_policy_tag.level_one)[*].display_name, each.value.policy_name) ? [for k, v in values(google_data_catalog_policy_tag.level_one) : v.name if v.display_name == each.value.policy_name][0] : (contains(values(google_data_catalog_policy_tag.level_two)[*].display_name, each.value.policy_name) ? [for k, v in values(google_data_catalog_policy_tag.level_two) : v.name if v.display_name == each.value.policy_name][0] : (contains(values(google_data_catalog_policy_tag.level_three)[*].display_name, each.value.policy_name) ? [for k, v in values(google_data_catalog_policy_tag.level_three) : v.name if v.display_name == each.value.policy_name][0] : (contains(values(google_data_catalog_policy_tag.level_four)[*].display_name, each.value.policy_name) ? [for k, v in values(google_data_catalog_policy_tag.level_four) : v.name if v.display_name == each.value.policy_name][0] : null))))
  role       = each.value.role
  members    = each.value.members
  depends_on = [google_bigquery_datapolicy_data_policy.column_level_sec_policy]
}

resource "google_bigquery_datapolicy_data_policy_iam_binding" "masked_reader_access_binding" {
  for_each       = { for k, v in local.masked_readers : k => v }
  
  location       = local.config_file.region
  data_policy_id = [for k, v in values(google_bigquery_datapolicy_data_policy.data_masking_policy) : v.data_policy_id if regex("\\d+$", v.policy_tag) == regex("\\d+$", contains(values(google_data_catalog_policy_tag.taxonomy_policy_tags)[*].display_name, each.value.policy_name) ? [for k, v in values(google_data_catalog_policy_tag.taxonomy_policy_tags) : v.name if v.display_name == each.value.policy_name][0] : (contains(values(google_data_catalog_policy_tag.level_one)[*].display_name, each.value.policy_name) ? [for k, v in values(google_data_catalog_policy_tag.level_one) : v.name if v.display_name == each.value.policy_name][0] : (contains(values(google_data_catalog_policy_tag.level_two)[*].display_name, each.value.policy_name) ? [for k, v in values(google_data_catalog_policy_tag.level_two) : v.name if v.display_name == each.value.policy_name][0] : (contains(values(google_data_catalog_policy_tag.level_three)[*].display_name, each.value.policy_name) ? [for k, v in values(google_data_catalog_policy_tag.level_three) : v.name if v.display_name == each.value.policy_name][0] : (contains(values(google_data_catalog_policy_tag.level_four)[*].display_name, each.value.policy_name) ? [for k, v in values(google_data_catalog_policy_tag.level_four) : v.name if v.display_name == each.value.policy_name][0] : null)))))][0]
  role           = each.value.role
  members        = each.value.members
}
