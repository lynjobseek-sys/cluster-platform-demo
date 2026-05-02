# A per-team AppProject sets the RBAC blast radius. Source repos are
# constrained to the platform repo; destinations to <team>-* namespaces on
# any cluster the platform has registered.
appProject = lambda team: str, repoURL: str -> {str:any} {
    {
        "apiVersion": "argoproj.io/v1alpha1"
        "kind": "AppProject"
        "metadata": {
            "name": team
            "namespace": "argocd"
            "finalizers": ["resources-finalizer.argocd.argoproj.io"]
        }
        "spec": {
            "description": "AppProject for team " + team
            "sourceRepos": [repoURL]
            "destinations": [
                {"server": "*", "namespace": team + "-*"}
            ]
            "clusterResourceWhitelist": [
                {"group": "", "kind": "Namespace"}
            ]
            "namespaceResourceWhitelist": [
                {"group": "*", "kind": "*"}
            ]
        }
    }
}
