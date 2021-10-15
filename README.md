# vault-okta-demo

## Prerequisites 

1. Define variables from the example `example.auto.tfvars` file
1. Okta account
1. Okta API token - from https://dev-123456-admin.okta.com/admin/access/api/tokens
1. Vault running (dev mode is fine)
  1. Vault's address in the vault_addr TF variable. This is needed even if the 
    environment variable VAULT_ADDR is set, as we need to use it for the URLs
  1. Vault token in env var VAULT_TOKEN (recommended) or in variable+providers.tf
1. For testing, users in Okta, and assigned to the groups once created
  1. In Okta, Directory -> Groups -> `vault_admins` and `vault_devs`


## 

1. Test by running `$ vault login -method=oidc -path=okta_oidc role=okta_admin`
  This will open your browser to login with the Okta user assigned to your new vault-admins/vault-devs group, 
  and return a token in the CLI. 
1. To test in the UI, select the `okta_oidc` tab on the login page, and enter `okta_admin` or `okta_devs`


## Troubleshooting

```
Error exchanging oidc code: "Provider.Exchange: id_token failed verification: Provider.VerifyIDToken: invalid id_token audiences: verifyAudiences: invalid id_token audiences: invalid audience".
```

This means the `bound_audiences` for the `vault_jwt_auth_backend_role` that Vault is trying are missing/invalid. 
Ensure the terraform created app client_id (not the client_id variable set) and `api://vault` are in the role, ie:

```
        "bound_audiences": [
          "0oa4rr3i4dydl3pMf4x7",
          "api://vault"
        ],
```

```
Vault login failed.
No code or id_token received.
```

This usually means the user trying to authenticate is not part of the vault-admins or vault-devs groups in Okta. 

```
error validating claims: claim "groups" is missing

```

Check for a mismatch in the Okta group name and the API -> Claims filter.


```
error validating claims: claim "groups" does not match any associated bound claim values

```

Check the var.roles group names matches the okta_group.vault-* groups setup. 