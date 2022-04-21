Product Manifest
----------------
This GitHub action is intended to be used with ArgoCD and Helm charts to help faciliate an easier GitOps experience.

Build Status
------------
[![GitHub CR Build and Push](https://github.com/tpayne/github-actions/actions/workflows/main-build.yml/badge.svg?branch=main&event=push)](https://github.com/tpayne/github-actions/actions/workflows/main-build.yml)

Documented Parameters
---------------------
The following are the documented parameters for this action...


>| Argument | Description | Mandatory |
>| -------- | ----------- | --------- | 
>| `gitops-repo-url` | The URL of the GitOps repo to clone and update | True |
>| `manifest-file` | The relative location of the Helm Values chart to update | True |
>| `github-username` | Name of the destination username/organization | True |
>| `github-email` | Name of the destination username/organization email | True |
>| `image-list` | Image list to process. This is a CSV and takes the form of a string like (helmChartName):(dockerImage):(tag) | False |
>| `image-list-file` | Image list to process. This is a CSV and takes the form of a string like (helmChartName):(dockerImage):(tag). This will override `image-list` | False |
>| `git-token` | Value of the Git Token to use for the commit - usually a GITHUB PAT | True |
>| `registry-server` | Docker registry server where images are held. Currently, only `docker.io` and `ghcr.io` are supported | True |
>| `docker-username` | Docker username to login as | True |
>| `docker-passwd` | Docker password to use for the login | True |

You must specify either `image-list` or `image-list-file`.

Example usage
-------------
The following are some samples of usage...

Standard usage.

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

Image list file sample.

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
      image-list-file: helm/imagelist.txt
      git-token: ${{ secrets.XGITHUB_PAT }}
      registry-server: ghcr.io
      docker-username: ${{ secrets.DOCKERHUB_USERNAME }}
      docker-passwd: ${{ secrets.XGITHUB_PAT }}
```

Some environment substitution sample using `ghcr.io`

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
        image-list: jenkinscd-framework-deployment:${{ env.REGISTRY }}/${{ github.actor }}/jenkinsdsl:master
        git-token: ${{ secrets.XGITHUB_PAT }}
        registry-server: ${{ env.REGISTRY }}
        docker-username: ${{ github.actor }}
        docker-passwd: ${{ secrets.XGITHUB_PAT }}
```

Notes
-----
- Make sure you have NO spaces in the dockerlist you submit. If you do, then it will not be parsed correctly - use `chartname:image:tag,chartname:image:tag,chartname:image:tag`, NOT `chartname:image:tag, chartname:image:tag, chartname:image:tag`
- This GitHub action has only been tested against `docker.io` and `ghcr.io`. Additional support may need to be added for other repo types. This can be done best by using their REST API as `docker` is flakey 
- Currently, this action uses Docker REST APIs rather than docker itself for the work. This is because it is generally quicker, but not so portable.
- If using `docker.io` you will need to specify your DockerHub user password as the `docker-passwd` value.
- If using `ghcr.io` you will need to use your GitHub PAT token as the `docker-passwd` value.

References
----------
- https://hub.docker.com/_/docker/?tab=tags (DnD)
- https://docs.github.com/en/rest/reference/packages
- https://docs.docker.com/registry/spec/api/#listing-repositories
- https://github.community/t/ghcr-io-docker-http-api/130121
- https://docs.docker.com/registry/spec/api/#:~:text=The%20Docker-Content-Digest%20header%20returns%20the%20canonical%20digest%20of,verify%20the%20value%20against%20the%20uploaded%20blob%20data.
- https://www.deployhub.com/docker-image-digest-using-v2-registry-api/
- https://docs.docker.com/engine/api/v1.41/#section/Versioning
