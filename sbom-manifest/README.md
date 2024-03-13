Product Manifest
----------------
This GitHub action is intended to be used with SBOM formats to help faciliate an easier GitOps experience.

Build Status
------------
[![GitHub CR Build and Push](https://github.com/tpayne/github-actions/actions/workflows/main-build.yml/badge.svg?branch=main&event=push)](https://github.com/tpayne/github-actions/actions/workflows/main-build.yml)

Documented Parameters
---------------------
The following are the documented parameters for this action...


>| Argument | Description | Mandatory |
>| -------- | ----------- | --------- | 
>| `gitops-repo-url` | The URL of the GitOps repo to clone and update | True |
>| `sbom-file` | The relative location of the SBOM to update | True |
>| `github-username` | Name of the destination username/organization | True |
>| `github-email` | Name of the destination username/organization email | True |
>| `component` | Component to update | True |
>| `version` | Component version to use | True |
>| `git-token` | Value of the Git Token to use for the commit - usually a GITHUB PAT | True |

Example usage
-------------
The following are some samples of usage...

Standard usage.

```yaml
   - name: GitOps SBOM Update
     uses: tpayne/github-actions/sbom-manifest
     env:
      API_TOKEN_GITHUB: ${{ secrets.API_TOKEN_GITHUB }}
     with:
      gitops-repo-url: https://github.com/tpayne/kubernetes-examples
      manifest-file: YAML/Argocd/helm/dev/values.yaml
      github-username: ${{ secrets.GIT_USER }}
      github-email: ${{ secrets.GIT_EMAIL }}
      git-token: ${{ secrets.API_TOKEN_GITHUB }}
      component: comp1
      version: release/v1.1 
```

Notes
-----
- The GH action will strip any comments out of the YAML file and reformat it

References
----------
- https://hub.docker.com/_/docker/?tab=tags (DnD)
- https://docs.github.com/en/rest/reference/packages
- https://docs.docker.com/registry/spec/api/#listing-repositories
- https://github.community/t/ghcr-io-docker-http-api/130121
- https://docs.docker.com/registry/spec/api/#:~:text=The%20Docker-Content-Digest%20header%20returns%20the%20canonical%20digest%20of,verify%20the%20value%20against%20the%20uploaded%20blob%20data.
- https://www.deployhub.com/docker-image-digest-using-v2-registry-api/
- https://docs.docker.com/engine/api/v1.41/#section/Versioning
