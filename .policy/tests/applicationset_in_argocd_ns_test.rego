package tests.applicationset_in_argocd_ns

import rego.v1

import data.main

good_appset := {
	"kind": "ApplicationSet",
	"metadata": {"name": "onboarding", "namespace": "argocd"},
}

bad_appset_wrong_ns := {
	"kind": "ApplicationSet",
	"metadata": {"name": "onboarding", "namespace": "gitops"},
}

bad_appset_no_ns := {
	"kind": "ApplicationSet",
	"metadata": {"name": "onboarding"},
}

test_applicationset_in_argocd_ns_pass if {
	result := main.deny with input as good_appset
	count(result) == 0
}

test_applicationset_in_argocd_ns_fail_wrong_ns if {
	result := main.deny with input as bad_appset_wrong_ns
	some msg in result
	contains(msg, "ApplicationSet/onboarding")
}

test_applicationset_in_argocd_ns_fail_no_ns if {
	result := main.deny with input as bad_appset_no_ns
	some msg in result
	contains(msg, "default")
}
