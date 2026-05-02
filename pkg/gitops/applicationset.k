# simpleOnboarding is the heart of the platform: one ApplicationSet per
# logical project (argocd, monitoring, vault, ...) using a git directory
# generator. The generator walks appsops/*/<project>/*/* and produces one
# ArgoCD Application per directory.
#
# Convention: appsops/<team>/<project>/<app>/<env>/
#   path.segments[1] = team   (matches AppProject name)
#   path.segments[2] = project
#   path.segments[3] = app
#   path.segments[4] = env    (drives the destination cluster)
#
# Teams never write ArgoCD YAML. They drop a directory under
# appsops/<their-team>/<project>/<app>/<env>/ containing whatever the
# Application needs (Helm chart files, Kustomize, raw manifests). The
# directory existing IS the onboarding signal.
#
# IMPORTANT: this ApplicationSet must live in the argocd namespace,
# otherwise the cross-namespace AppProject reference cannot resolve.
simpleOnboarding = lambda project: str, repoURL: str, appPath: str -> {str:any} {
    _envToCluster = "{{ get (dict \"local\" \"in-cluster\" \"staging\" \"dev\" \"prod\" \"prod\") (index .path.segments 4) }}"
    {
        "apiVersion": "argoproj.io/v1alpha1"
        "kind": "ApplicationSet"
        "metadata": {
            "name": project + "-onboarding"
            "namespace": "argocd"
        }
        "spec": {
            "goTemplate": True
            "goTemplateOptions": ["missingkey=error"]
            "generators": [
                {
                    "git": {
                        "repoURL": repoURL
                        "revision": "HEAD"
                        "directories": [
                            {"path": appPath + "/*/" + project + "/*/*"}
                        ]
                    }
                }
            ]
            "template": {
                "metadata": {
                    "name": "{{ index .path.segments 1 }}-{{ index .path.segments 3 }}-{{ index .path.segments 4 }}"
                    "finalizers": ["resources-finalizer.argocd.argoproj.io"]
                }
                "spec": {
                    "project": "{{ index .path.segments 1 }}"
                    "source": {
                        "repoURL": repoURL
                        "targetRevision": "HEAD"
                        "path": "{{ .path.path }}"
                    }
                    "destination": {
                        "name": _envToCluster
                        "namespace": "{{ index .path.segments 1 }}-{{ index .path.segments 4 }}"
                    }
                    "syncPolicy": {
                        "automated": {"prune": True, "selfHeal": True}
                        "syncOptions": ["CreateNamespace=true", "ServerSideApply=true"]
                    }
                }
            }
        }
    }
}
