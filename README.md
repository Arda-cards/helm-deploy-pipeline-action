# helm-deploy-pipeline-action

[![ci](https://github.com/Arda-cards/helm-deploy-pipeline-action/actions/workflows/ci.yaml/badge.svg?branch=main)](https://github.com/Arda-cards/helm-deploy-pipeline-action/actions/workflows/ci.yaml?query=branch%3Amain)
[CHANGELOG.md](CHANGELOG.md)

Given a set of pre/post cloudformations, a helm chart and a cluster, install/update the cluster

This action handles the complete deployment pipeline for a gradle project.

This action expects the project to have been checked out already in the `github.workspace` and will look for:

| file                                           | required | description                                                    |
|------------------------------------------------|----------|----------------------------------------------------------------|
| `src/main/cloudformation/pre-install.cfn.yml`  | no       | If present, applied before the helm deployment                 |
| `src/main/cloudformation/post-install.cfn.yml` | no       | If present, applied after the helm deployment                  |
| `src/main/helm/`                               | yes      | `values.yaml` and `values-`*phase*`.yaml` configure the chart. | 

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
          image_pull_secret: "${{ secrets.GPR_OCI_READ_SECRET }}"
          module_name: "${{ needs.build.outputs.module_name }}"
          namespace: "${{ matrix.environment }}-${{ needs.build.outputs.module_name }}"
          phase: "${{ matrix.environment }}"
          verbose: true
```

## Permission Required

```yaml
permissions:
  contents: read
  id-token: write
  packages: read
```
