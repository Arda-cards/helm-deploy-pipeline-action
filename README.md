# helm-deploy-pipeline-action

[![ci](https://github.com/Arda-cards/helm-deploy-pipeline-action/actions/workflows/ci.yaml/badge.svg?branch=main)](https://github.com/Arda-cards/helm-deploy-pipeline-action/actions/workflows/ci.yaml?query=branch%3Amain)
[CHANGELOG.md](CHANGELOG.md)

Given a set of pre- / post-CloudFormation, a helm chart and a cluster, install/update the cluster

This action handles the complete deployment pipeline for a gradle project.

This action expects the project to have been checked out already in the `github.workspace` and will look for:

| file                                           | required | description                                                    |
|------------------------------------------------|----------|----------------------------------------------------------------|
| `src/main/cloudformation/pre-install.cfn.yml`  | no       | If present, applied before the helm deployment                 |
| `src/main/cloudformation/post-install.cfn.yml` | no       | If present, applied after the helm deployment                  |
| `src/main/helm/`                               | yes      | `values.yaml` and `values-`*purpose*`.yaml` configure the chart. |

The action will add a tag for `Environment` (see below) to every CloudFormation element created.

## Parametrizing CloudFormation

The action sets the following parameters for both the pre and the post install stacks.

| name        | description                             |
|-------------|-----------------------------------------|
| Environment | The name of the AWS account.            |
| Namespace   | The name of the namespace to deploy to. |
| component      | The name of the component being deployed.  |

Values from the `pre_install_parameter` and `post_install_parameter` file are added to the set.
The files are json array:

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
[ "${{ runner.debug }}" == 1 ] && set -xv
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

The action sets the following variables.

| name               | description                 |
|--------------------|-----------------------------|
| global.CLUSTER_IAM | arn:aws:iam::${cluster_iam} |
| global.AWS_REGION  | aws_region                  |
| global.purpose       | purpose                       |

If defined, the `helm_value` file is passed to Helm *after* the purpose specific value.yaml from the project.

### Example

Assuming a Helm chart that needs `.Values.global.databaseURI` to contain the value available as the CloudFormation export `AuroraClusterUri`,
this shell script, inlined in the GitHub job, reads the CloudFormation export and saves it as the global variable `databaseURI`.

```shell
[ "${{ runner.debug }}" == 1 ] && set -xv
set -u

function appendExport {
  echo "${1}: $(aws cloudformation list-exports --query "Exports[?Name=='${2}'].Value" --output text)"
}

file_name=read-cloudFormation-values.yaml
echo "file_name=${file_name}" >>${GITHUB_OUTPUT}

{
echo "---"
echo "global:"
appendExport "  databaseURI" "AuroraClusterUri"
} >${file_name}
```

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
        environment: [ dev ]
    environment: "${{ matrix.environment }}"
    steps:
      - uses: actions/checkout@v4
      - uses: Arda-carda/helm-deploy-pipeline-action@dna/1
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
          namespace: "${{ matrix.environment }}-${{ needs.build.outputs.component_name }}"
          purpose: "${{ matrix.environment }}"
          verbose: true
```

## Permission Required

```yaml
permissions:
  contents: read
  id-token: write
  packages: read
```
