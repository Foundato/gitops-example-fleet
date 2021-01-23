# Example Fleet Repo

This repository serves as an example for a GitOps fleet repository. It can be seen as the central inventory 
for all clusters the infrastructure team serves to it's users.

> We leverage Flux V2 to run our GitOps process. The method and the repo can be used for various GitOps workflows,
> but our scripts and demos will only work with Flux v2.

The main purpose for this repo is:

* Maintain an inventory specific for each cluster
* Deploy infrastructure services to each cluster
* Provide the tenants (allow other teams to deploy to the clusters with limited permissions)

## Getting started

### Initial Setup

For the example setup, we need a local test cluster at first. For this we are using k3d, which is a fast way to provision a 
k3s based cluster. In case you want to use another cluster just skip this step.

```sh
./scripts/00-init-cluster-local.sh
```

After this went successful you should be able to list all pods in the new cluster.

```sh
k get pods --all-namespaces       

NAMESPACE     NAME                                      READY   STATUS    RESTARTS   AGE
kube-system   coredns-854c77959c-lbrj9                  1/1     Running   0          84s
kube-system   local-path-provisioner-7c458769fb-j5z54   1/1     Running   0          84s
kube-system   metrics-server-86cbb8457f-s72gg           1/1     Running   0          84s
```

When the cluster is running you can initiate the GitOps flow.

If you are interested in how the initial manifests where created, take a look into the bootstrap scripts.
Basically what this scripts do is create resources for the flux setup.

* GitRepository pointing to this fleet repo on Github
* Kustomization to ensure flux knows which folder to sync for this cluster
* Flux manifests that deploy the whole GitOps toolkit stack

> In case you want to use other cluster names, just delete the clusters folder and adjust the scripts. Then rerun the scripts.

After the cluster is created, apply the gitops system manifests with:

```sh
./scripts/40-apply-flux.sh
```

After the apply is finished, the gitops controller should start its work:

```sh
k get pods -n gitops-system

NAME                                           READY   STATUS    RESTARTS   AGE
helm-controller-6765c95b47-f7nnc               1/1     Running   0          2m20s
image-automation-controller-6778cd5466-mhtfn   1/1     Running   0          2m19s
image-reflector-controller-56dc6695c6-f7898    1/1     Running   0          2m19s
kustomize-controller-7f5455cd78-nqrwk          1/1     Running   0          2m18s
notification-controller-694856fd64-jkq9q       1/1     Running   0          2m17s
source-controller-5bdb7bdfc9-2gnz4             1/1     Running   0          2m17s
```

the logs of the source controller should also show you, that the fleet repo is now synced:

```sh
k logs -f source-controller-5bdb7bdfc9-2gnz4
{"level":"info","ts":"2021-01-23T13:59:51.207Z","logger":"controller-runtime.metrics","msg":"metrics server is starting to listen","addr":":8080"}
{"level":"info","ts":"2021-01-23T13:59:51.218Z","logger":"setup","msg":"starting manager"}
I0123 13:59:51.237773       6 leaderelection.go:243] attempting to acquire leader lease  gitops-system/305740c0.fluxcd.io...
{"level":"info","ts":"2021-01-23T13:59:51.243Z","logger":"controller-runtime.manager","msg":"starting metrics server","path":"/metrics"}
I0123 13:59:53.710570       6 leaderelection.go:253] successfully acquired lease gitops-system/305740c0.fluxcd.io

...

{"level":"info","ts":"2021-01-23T13:59:53.842Z","logger":"controller","msg":"Starting Controller","reconcilerGroup":"source.toolkit.fluxcd.io","reconcilerKind":"HelmChart","controller":"helmchart"}
{"level":"info","ts":"2021-01-23T13:59:53.842Z","logger":"controller","msg":"Starting workers","reconcilerGroup":"source.toolkit.fluxcd.io","reconcilerKind":"HelmChart","controller":"helmchart","worker count":2}
{"level":"info","ts":"2021-01-23T13:59:53.843Z","logger":"controller","msg":"Starting workers","reconcilerGroup":"source.toolkit.fluxcd.io","reconcilerKind":"HelmRepository","controller":"helmrepository","worker count":2}
{"level":"info","ts":"2021-01-23T13:59:56.503Z","logger":"controllers.GitRepository","msg":"Reconciliation finished in 2.6661923s, next run in 1m0s","controller":"gitrepository","request":"gitops-system/base-fleet-repo"}
{"level":"info","ts":"2021-01-23T14:00:57.346Z","logger":"controllers.GitRepository","msg":"Reconciliation finished in 913.0738ms, next run in 1m0s","controller":"gitrepository","request":"gitops-system/base-fleet-repo"}
{"level":"info","ts":"2021-01-23T14:01:58.136Z","logger":"controllers.GitRepository","msg":"Reconciliation finished in 858.1136ms, next run in 1m0s","controller":"gitrepository","request":"gitops-system/base-fleet-repo"}
```

### Initiate Infra Tenant

Now that the basic sync is established, we need to first add the infra repository sync to this cluster.

```sh
./scripts/30-generate-team-tenant.sh
```

After the tenant is generated, commit and push it. The sync process should automatically apply it to the cluster.

## Known Issues

Sometimes the api server takes a while to recognize the CRDs, so while running the apply-flux script, there can be errors like this:

```log
...
deployment.apps/image-reflector-controller created
deployment.apps/kustomize-controller created
deployment.apps/notification-controller created
deployment.apps/source-controller created
networkpolicy.networking.k8s.io/allow-scraping created
networkpolicy.networking.k8s.io/allow-webhooks created
networkpolicy.networking.k8s.io/deny-ingress created
unable to recognize "clusters/k3s-gitops-euw-int-001/system/gitops-system": no matches for kind "Kustomization" in version "kustomize.toolkit.fluxcd.io/v1beta1"
unable to recognize "clusters/k3s-gitops-euw-int-001/system/gitops-system": no matches for kind "GitRepository" in version "source.toolkit.fluxcd.io/v1beta1"
```

In this case, just rerun the script.
