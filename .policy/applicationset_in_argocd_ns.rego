package main

import rego.v1

# ArgoCD's ApplicationSet controller only watches the namespace it runs in
# (argocd) unless explicitly configured for multi-namespace. An ApplicationSet
# created elsewhere is silently ignored - no events, no errors, just nothing
# happens. Catch this at lint time.

deny contains msg if {
	input.kind == "ApplicationSet"
	resource_namespace(input) != "argocd"
	msg := sprintf(
		"ApplicationSet/%s is in namespace %q: must be in 'argocd' or the controller will not reconcile it",
		[resource_name(input), resource_namespace(input)],
	)
}
