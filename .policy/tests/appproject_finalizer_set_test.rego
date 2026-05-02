package tests.appproject_finalizer_set

import rego.v1

import data.main

good_appproject := {
	"kind": "AppProject",
	"metadata": {
		"name": "frontend",
		"namespace": "argocd",
		"finalizers": ["resources-finalizer.argocd.argoproj.io"],
	},
}

bad_no_finalizer := {
	"kind": "AppProject",
	"metadata": {"name": "frontend", "namespace": "argocd"},
}

bad_wrong_finalizer := {
	"kind": "AppProject",
	"metadata": {
		"name": "frontend",
		"namespace": "argocd",
		"finalizers": ["other.example.com/finalizer"],
	},
}

test_appproject_finalizer_set_pass if {
	result := main.deny with input as good_appproject
	count(result) == 0
}

test_appproject_finalizer_set_fail_missing if {
	result := main.deny with input as bad_no_finalizer
	some msg in result
	contains(msg, "missing finalizer")
}

test_appproject_finalizer_set_fail_wrong if {
	result := main.deny with input as bad_wrong_finalizer
	some msg in result
	contains(msg, "missing finalizer")
}
