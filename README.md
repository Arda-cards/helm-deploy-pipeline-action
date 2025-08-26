# helm-deploy-pipeline-action

[![ci](https://github.com/Arda-cards/helm-deploy-pipeline-action/actions/workflows/ci.yaml/badge.svg?branch=main)](https://github.com/Arda-cards/helm-deploy-pipeline-action/actions/workflows/ci.yaml?query=branch%3Amain)
[CHANGELOG.md](CHANGELOG.md)

Given a set of pre- / post-CloudFormation, a helm chart and a cluster, install/update the cluster.

This action handles the complete deployment pipeline for a gradle project, including [deployment gate](https://github.com/Arda-cards/deployment-gate-action) if [configured for the purpose](https://github.com/Arda-cards/purpose-configuration-action).

This action expects the project to have been checked out already in the `github.workspace` and will look for:

| file                                           | required | description                                                      |
|------------------------------------------------|----------|------------------------------------------------------------------|
| `src/main/cloudformation/pre-install.cfn.yml`  | no       | If present, applied before the helm deployment                   |
| `src/main/cloudformation/post-install.cfn.yml` | no       | If present, applied after the helm deployment                    |
| `src/main/helm/read-cloudFormation-values.cmd` | no       | If present, applied before the helm deployment                   |
| `src/main/helm/`                               | yes      | `values.yaml` and `values-`*purpose*`.yaml` configure the chart. |

The action will add tags for `Infrastructure` (see below) to every CloudFormation element created.

## Locating the cluster

The action needs the triplet of an *aws role*, an *aws region* and a *cluster name* to locate the cluster for deployment.
These can be passed in as three parameters or, better, through a `locator_url` with optional `locator_url_bearer` or `locator_url_token`;
it is an error to pass both the three parameters `aws_region`, `aws_role` and `cluster_name`, and the `locator_url` at the same time.

The `locator_url` is the URL of a simple properties file that contains the required triplet as

```properties
aws_role=arn:aws:iam::account_id:role/role_name
aws_region=us-east-0
cluster_name=...
```

If `locator_url` identifies a GitHub repository, appropriate headers are added to the `GET` request.

If `locator_url_bearer` or `locator_url_token`, the headers `Authorization: Bearer` or `Authorization: Token` are added to the `GET` request.
If both parameters are present, both headers are added and behavior is defined by the server.

## Parametrizing CloudFormation

The action sets the following parameters for both the pre and the post install stacks.

| name           | description                               |
|----------------|-------------------------------------------|
| Infrastructure | The name of the AWS account.              |
| Namespace      | The name of the namespace to deploy to.   |
| Component      | The name of the component being deployed. |

Values from the `pre_install_parameter` and `post_install_parameter` file are added to the set.
The files are JSON array:

```json
[
  {
    "ParameterKey": "MyParam1",
    "ParameterValue": "myValue1"
  }
]
```

### Example

Assuming following `pre-install.cfn.yml`,

```yaml
AWSTemplateFormatVersion: '2010-09-09'
Description: 'Grants AWS privileges to the service'

Parameters:
  GhcrPullKey:
    Type: String
    Description: "Concatenated(User, ':', PAT) that grants read access to GitHub OCI registry"
    MinLength: 1
    ConstraintDescription: "GhcrPullKey cannot be empty"
    NoEcho: true

Resources:
  GhcrPullSecret:
    Type: AWS::SecretsManager::Secret
    DeletionPolicy: Delete
    UpdateReplacePolicy: Delete
    Properties:
      Name: !Sub "GhcrPullSecret"
      Description: "Grants pull access to the GitHub OCI registry"
      SecretString: !Ref GhcrPullKey
```

this shell script, inlined in the GitHub job, reads a GitHub secret and saves it as the parameter `GhcrPullKey`.

```shell
[ "${RUNNER_DEBUG}" == 1 ] && set -xv
set -u

pre_install_parameters() {
  file_name="${RUNNER_TEMP}/pre.json"
  echo "file_name_pre=$file_name" >>"${GITHUB_OUTPUT}"
  echo '[]' |
    jq --arg value "${{ secrets.GITHUB_REGISTRY_READ_SECRET }}"    '. += [{"ParameterKey": "GhcrPullKey", "ParameterValue": $value}]' \
  > "${file_name}"
}
pre_install_parameters
```

## Parametrizing Helm

### Pre-set values

The action sets the following variables.

| name             | description |
|------------------|-------------|
| global.awsRegion | aws_region  |
| global.purpose   | purpose     |

### Helm value commands

If defined, the `helm_value_command` file is executed and the resulting `helm_value` passed to Helm *after* the
purpose-specific `value.yaml` from the project. The `helm_value_command` file is simple list of tuples *action, key, value*.

| action         | description                                                                                 |
|----------------|---------------------------------------------------------------------------------------------|
| copyValue      | sets the *key* to the *value*                                                               |
| readExport     | sets the *key* to the CloudFormation export named *value*                                   |
| readSecretName | sets the *key* to the name of the secret defined by the CloudFormation export named *value* |

The action strips any prefix that matches `.*|::|` from the value read from CloudFormation.

As it reads the command line-by-line, it substitutes these variables

| name           | description                          |
|----------------|--------------------------------------|
| COMPONENT      | The value of `inputs.component_name` |
| INFRASTRUCTURE | The Infrastructure name              |
| NAMESPACE      | The value of `inputs.namespace`      |
| PURPOSE        | The value of `inputs.purpose`        |

#### Example

Assuming a Helm chart that needs `.Values.global.databaseURI` to contain the value available as the CloudFormation
export `API-AuroraClusterUri`, with the purpose as a prefix,`src/main/helm/read-cloudFormation-values.cmd` describes
the CloudFormation exports to read and the Helm variable
`global.databaseURI` to set.

Note that Helm variable name is a path in the YAML file and, therefore, needs to start with a `.`;
refer to [yq](https://mikefarah.gitbook.io/yq) for more details.

```text
readExport .global.databaseURI "${PURPOSE}-API-AuroraClusterUri"
```

Alternatively, this shell script, inlined in the GitHub job, achieve the same goal.

```shell
[ "${RUNNER_DEBUG}" == 1 ] && set -xv
set -u

file_name=read-cloudFormation-values.yaml
echo "file_name=${file_name}" >>${GITHUB_OUTPUT}

{
echo readExport ".global.databaseURI" "${{ matrix.purpose }}-API-AuroraClusterUri"
} >${file_name}
```

Note that Helm variable name is a path in the YAML file and, therefore, needs to start with a `.`;
refer to [yq](https://mikefarah.gitbook.io/yq) for more details.

## Arguments

See [action.yaml](action.yaml).

## Usage

```yaml
jobs:
  deploy-dev:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      id-token: write
      packages: read
    strategy:
      matrix:
        purpose: [ dev ]
    environment: "${{ matrix.purpose }}"
    steps:
      - uses: actions/checkout@v5
      - uses: Arda-carda/helm-deploy-pipeline-action@v2
        with:
          aws_role: "${{ vars.AWS_ROLE }}"
          aws_region: "${{ vars.AWS_REGION }}"
          chart_name: "${{ needs.build.outputs.chart_name }}"
          chart_version: "${{ needs.build.outputs.chart_version }}"
          clean_up: false
          cluster_name: "${{ vars.AWS_CLUSTER_NAME }}"
          github_token: "${{ github.token }}"
          helm_registry: "${{ vars.HELM_REGISTRY }}"
          component_name: "${{ needs.build.outputs.component_name }}"
          namespace: "${{ matrix.purpose }}-${{ needs.build.outputs.component_name }}"
          purpose: "${{ matrix.purpose }}"
          verbose: true
```

## Permission Required

```yaml
permissions:
  contents: read
  id-token: write
  packages: read
```
