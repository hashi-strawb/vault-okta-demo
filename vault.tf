
# Vault config
resource "vault_jwt_auth_backend" "okta_oidc" {
  description        = "Okta OIDC"
  path               = var.okta_mount_path
  type               = "oidc"
  oidc_discovery_url = okta_auth_server.vault.issuer
  bound_issuer       = okta_auth_server.vault.issuer
  oidc_client_id     = okta_app_oauth.vault.client_id
  oidc_client_secret = okta_app_oauth.vault.client_secret
  default_role       = "okta_default"
  tune {
    listing_visibility = "unauth"
    default_lease_ttl  = var.okta_default_lease_ttl
    max_lease_ttl      = var.okta_max_lease_ttl
    token_type         = var.okta_token_type
  }
}

resource "vault_jwt_auth_backend_role" "okta_role" {
  for_each       = var.roles
  backend        = vault_jwt_auth_backend.okta_oidc.path
  role_name      = each.key
  token_policies = each.value.token_policies

  allowed_redirect_uris = [
    "${var.vault_addr}/ui/vault/auth/${vault_jwt_auth_backend.okta_oidc.path}/oidc/callback",
    # This is for logging in with the CLI if you want.
    "http://localhost:${var.cli_port}/oidc/callback",
  ]

  user_claim = "email"
  #user_claim      = "sub"
  role_type       = "oidc"
  bound_audiences = [var.okta_auth_audience, okta_app_oauth.vault.client_id]
  # bound_audiences = [okta_auth_server.vault.audiences]
  oidc_scopes = [
    "openid",
    "profile",
    "email",
  ]
  groups_claim = "groups"

  claim_mappings = {
    "name"               = "name",
    "family_name"        = "family_name",
    "given_name"         = "given_name",
    "nickname"           = "nickname",
    "preferred_username" = "preferred_username",
    "email"              = "email",
  }

  verbose_oidc_logging = true
}


locals {
  # TODO: Paramterise these
  groups_policies = {
    # Dummy nonexistent policies for now, to proove the concept
    "vault-admins" : ["okta-group-vault-admins"],
    "vault-devs" : ["okta-group-vault-devs"],
  }


  # TODO: add vault-admins (for example) to a parent group
  groups_parents = {
  }
}

resource "vault_identity_group" "group" {
  for_each = local.groups_policies
  name     = "Okta: ${each.key}"
  type     = "external"
  policies = each.value

  lifecycle {
    ignore_changes = [
      member_entity_ids
    ]
  }
}

resource "vault_identity_group_alias" "group-alias" {
  for_each = local.groups_policies

  name           = each.key
  mount_accessor = vault_jwt_auth_backend.okta_oidc.accessor
  canonical_id   = vault_identity_group.group[each.key].id
}
