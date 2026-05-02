# ManagedProjects controls which logical project tracks render through the
# entry point. Each entry produces one simpleOnboarding ApplicationSet that
# scans appsops/*/<project>/*/* and generates Applications for every
# directory it finds.
ManagedProjects: [str] = ["argocd", "monitoring", "vault"]
