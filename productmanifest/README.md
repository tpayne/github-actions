# Product Manifest

This GitHub action is intended to be used with ArgoCD and Helm charts to help faciliate an easier GitOps experience.

This GitHub action does require some additional work, so watch this space.

## Inputs
### `gitops-repo-url` (argument) (mandatory)
The URL of the GitOps repo to clone and update

### `manifest-file` (argument) (mandatory)
The relative location of the Helm Values chart to update

### `github-username` (argument) (mandatory)
Name of the destination username/organization

### `github-email` (argument) (mandatory)
Name of the destination username/organization email

### `image-list` (argument) (mandatory)
Image list to process. This is a CSV and takes the form of a string like...
   <helmChartName>:<dockerImage>

For example...
   wscs-deployment:tpayne666/nodejs:master,wsnodejs-b-deployment:tpayne666/nodejs:1.0   

### `commit-message` (argument) (optional)
Commit message for Git

### `git-token` (argument) (mandatory)
Value of the Git Token to use for the commit - usually a GITHUB PAT 

### `registry-server` (argument) (mandatory)
Docker registry server where images are held
  
### `docker-username` (argument) (mandatory)
Docker username to login as

### `docker-passwd` (argument) (mandatory)
Docker password to use for the login

## Example usage
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
