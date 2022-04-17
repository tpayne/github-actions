Product Manifest
----------------
This GitHub action is intended to be used with ArgoCD and Helm charts to help faciliate an easier GitOps experience.

This GitHub action does require some additional work as I start to use it in anger, so watch this space.

NOTE THIS DOES NOT CURRENTLY WORK - I HAVE SOME ISSUES WITH THE DIGEST THAT NEEDS RESOLVING AS REST API DOES NOT WORK
AS SOME DOCUMENTS SAY

Build Status
------------
[![GitHub CR Build and Push](https://github.com/tpayne/github-actions/actions/workflows/docker-image.yml/badge.svg?branch=main&event=push)](https://github.com/tpayne/github-actions/actions/workflows/docker-image.yml)

Documented Parameters
---------------------
The following are the documented parameters for this action...


>| Argument | Description | Mandatory |
>| -------- | ----------- | --------- | 
>| `gitops-repo-url` | The URL of the GitOps repo to clone and update | True |
>| `manifest-file` | The relative location of the Helm Values chart to update | True |
>| `github-username` | Name of the destination username/organization | True |
>| `github-email` | Name of the destination username/organization email | True |
>| `image-list` | Image list to process. This is a CSV and takes the form of a string like (helmChartName):(dockerImage) | True |
>| `git-token` | Value of the Git Token to use for the commit - usually a GITHUB PAT | True |
>| `registry-server` | Docker registry server where images are held | True |
>| `docker-username` | Docker username to login as | True |
>| `docker-passwd` | Docker password to use for the login | True |

Example usage
-------------
The following are some samples of usage.
   
```yaml
   - name: GitOps Helm Update
     uses: tpayne/github-actions/productmanifest
     env:
      API_TOKEN_GITHUB: ${{ secrets.API_TOKEN_GITHUB }}
     with:
      gitops-repo-url: https://github.com/tpayne/kubernetes-examples
      manifest-file: YAML/Argocd/helm/dev/values.yaml
      github-username: ${{ secrets.GIT_USER }}
      github-email: ${{ secrets.GIT_EMAIL }}
      image-list: wscs-deployment:tpayne666/nodejs:master,wsnodejs-b-deployment:tpayne666/nodejs:1.0 
      git-token: ${{ secrets.API_TOKEN_GITHUB }}
      registry-server: docker.io
      docker-username: ${{ secrets.DOCKER_USER }}
      docker-passwd: ${{ secrets.DOCKER_PWD }}
```

```yaml
   - name: GitOps Helm Chart Update(s)
     uses: tpayne/github-actions/productmanifest@main
     env:
      API_TOKEN_GITHUB: ${{ secrets.XGITHUB_PAT }}
     with:
      gitops-repo-url: https://github.com/tpayne/codefresh-csdp-samples
      manifest-file: helm/dev/values.yaml
      github-username: ${{ secrets.XGITHUB_USER }}
      github-email: ${{ secrets.XGITHUB_EMAIL }}
      image-list: jenkinscd-framework-deployment:tpayne666/jenkinsdsl:latest
      git-token: ${{ secrets.XGITHUB_PAT }}
      registry-server: docker.io
      docker-username: ${{ secrets.DOCKERHUB_USERNAME }}
      docker-passwd: ${{ secrets.DOCKERHUB_PASSWORD }}
```

Notes
-----
- This GitHub action has only been tested against `docker.io` using public repos. Additional support may need to be added for other repo types. This can be done best by using their REST API as `docker` is flakey 
- Currently, this action uses Docker REST APIs rather than docker itself for the work. This is because it is generally quicker, but not so portable. If portability becomes an issue, I will make this addon work as a `dnd` system

References
----------
- https://hub.docker.com/_/docker/?tab=tags (DnD)
- https://docs.github.com/en/rest/reference/packages
- https://docs.docker.com/registry/spec/api/#listing-repositories
- https://github.community/t/ghcr-io-docker-http-api/130121
