package main

import rego.v1

# AppProject without resources-finalizer.argocd.argoproj.io will, on deletion,
# orphan every Application underneath it - the apps stay registered but their
# project is gone, and ArgoCD refuses to reconcile them. Recovery is manual
# and tedious. Require the finalizer up front.

required_finalizer := "resources-finalizer.argocd.argoproj.io"

deny contains msg if {
	input.kind == "AppProject"
	not has_finalizer
	msg := sprintf(
		"AppProject/%s is missing finalizer %q: deletion would orphan child Applications",
		[resource_name(input), required_finalizer],
	)
}

has_finalizer if {
	some f in input.metadata.finalizers
	f == required_finalizer
}
