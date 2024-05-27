variable "project_id" {
  description = "The ID of the GCP project where resources will be deployed"
  type        = string
}

variable "region" {
  description = "The default GCP region to deploy resources to"
  type        = string
  default     = "europe-west2"
}

variable "taxonomies" {
  type = tuple([
    object({
      activated_policy_types : tuple([
        string,
      ]),
      description : string,
      id : string,
      policy_tags : tuple([
        object({
          description : string,
          id : string,
          level_one : optional(tuple([
            object({
              description : string,
              id : string,
              level_two : optional(tuple([
                object({
                  description : string,
                  id : string,
                  level_three : optional(tuple([
                    object({
                      description : string,
                      id : string,
                      level_four : optional(tuple([
                        object({
                          description : string,
                          id : string
                        })
                      ]))
                    })
                  ]))
                }),
              ]), ),
            }),
          ]), ),
        }),
      ]),
    }),
  ])
  default = [{
    "activated_policy_types" : ["POLICY_TYPE_UNSPECIFIED"],
    "description" : "taxonomy description",
    "id" : "default taxonomy",
    "policy_tags" : [{
      "description" : "policy tag description",
      "id" : "default policy tag"
    }]
  }]

  validation {
    condition = alltrue([
      for taxonomy in var.taxonomies :
      alltrue([for activate_policy_type in taxonomy.activated_policy_types :
        contains(["POLICY_TYPE_UNSPECIFIED", "FINE_GRAINED_ACCESS_CONTROL"], activate_policy_type)
      ])
    ])
    error_message = "Supported policy types are 'FINE_GRAINED_ACCESS_CONTROL' or 'POLICY_TYPE_UNSPECIFIED'."
  }

  validation {
    condition = alltrue([
      for taxonomy in var.taxonomies :
      length(textencodebase64(taxonomy.id, "UTF-8")) <= 200
    ])
    error_message = "Policy id be at most 200 bytes long when encoded in UTF-8"
  }

  validation {
    condition = alltrue([
      for taxonomy in var.taxonomies :
      length((textencodebase64(taxonomy.description, "UTF-8"))) <= 2000
    ])
    error_message = "Description be at most 2000 bytes long when encoded in UTF-8"
  }

  validation {
    condition = alltrue([
      for taxonomy in var.taxonomies :
      alltrue([for policy_tag in taxonomy.policy_tags :
        length(textencodebase64(policy_tag.id, "UTF-8")) <= 200
      ])
    ])
    error_message = "Policy id be at most 200 bytes long when encoded in UTF-8"
  }

  validation {
    condition = alltrue([
      for taxonomy in var.taxonomies :
      alltrue([for policy_tag in taxonomy.policy_tags :
        length(textencodebase64(policy_tag.description, "UTF-8")) <= 2000
      ])
    ])
    error_message = "Policy id be at most 2000 bytes long when encoded in UTF-8"
  }
}

variable "security" {
  type = tuple([
    object({
      column_lvl_sec : optional(tuple([
        object({
          data_policy_id : string,
          policy_tag : string
        })
      ])),
      masking : optional(tuple([
        object({
          data_policy_id : string,
          policy_tag : string,
          predefined_expression : string
        })
      ]))
    })
  ])
  default = [{
    "column_lvl_sec" : [{
      "data_policy_id" : "column level sec policy",
      "policy_tag" : "name of policy tag"
    }]
  }]

  validation {
    condition = alltrue([
      for policy in var.security :
      policy.masking == null ? true :
      alltrue([for masking_policy in policy.masking :
      contains(["SHA256", "ALWAYS_NULL", "DEFAULT_MASKING_VALUE", "LAST_FOUR_CHARACTERS", "FIRST_FOUR_CHARACTERS", "EMAIL_MASK", "DATE_YEAR_MASK"], masking_policy.predefined_expression)])
    ])
    error_message = "Predefined expression or masking rule must be one of SHA256, ALWAYS_NULL, DEFAULT_MASKING_VALUE, LAST_FOUR_CHARACTERS, FIRST_FOUR_CHARACTERS, EMAIL_MASK, DATE_YEAR_MASK"
  }
}

variable "iam_roles" {
  type = tuple([
    object({
      masked_reader_policy : optional(tuple([
        object({
          name_of_the_policy : string,
          members : tuple([
            object({
              user : string
            })
          ])
        })
      ])),
      finegrained_reader_access : optional(tuple([
        object({
          name_of_the_policy : string,
          members : tuple([
            object({
              user : string
            })
          ])
        })
      ]))
    })
  ])

  default = [{}]
}
