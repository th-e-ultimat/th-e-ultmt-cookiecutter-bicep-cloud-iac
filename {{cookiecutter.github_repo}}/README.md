# {{cookiecutter.github_repo}}

{{cookiecutter.company_full_name}} Cloud Infrastructure as Code

## IaC Service Principal

### IaC Role Definition

Custom subscription role definition for infrastructure as code.
```json
{
    "Name": "Custom Infrastructure as Code Role",
    "Description": "Can manage infrastructure.",
    "actions": [
        "*"
    ],
    "notActions": [
        "Microsoft.Authorization/*/Delete"
    ],
    "AssignableScopes": [
        "/subscriptions/{subscriptionId1}"
    ]
}
```

Save the json file e.g. as `'iacrole.json'` then create the role definition as follows:
```bash
az role definition create --role-definition iacrole.json
```
The cli will reply with a payload that includes a name which is a guid.

### IaC Service Pricipal Creation

```bash
az ad sp create-for-rbac \
  --name "github-az-bicep-spn" \
  --role  "contributor" \
  --scopes "subscriptions/<subscription-id>"
```

## Importing from ARM

### Decompiling ARM template JSON to Bicep

```
az bicep decompile --file your-arm-file.json
```

## Deployment

### What if deployment

```
az deployment sub what-if -l <location> --template-file .\bicep\main.bicep --subscription <subscription>- --parameters location=<location>
```