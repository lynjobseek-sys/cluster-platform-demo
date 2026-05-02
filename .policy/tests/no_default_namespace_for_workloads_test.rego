package tests.no_default_namespace_for_workloads

import rego.v1

import data.main

good_deployment := {
	"kind": "Deployment",
	"metadata": {"name": "worker", "namespace": "data-prod"},
	"spec": {"template": {"spec": {"containers": [{
		"name": "worker",
		"image": "ghcr.io/example/worker:0.9.1",
		"resources": {"requests": {"cpu": "100m", "memory": "128Mi"}},
	}]}}},
}

bad_default_ns := {
	"kind": "Deployment",
	"metadata": {"name": "worker", "namespace": "default"},
	"spec": {"template": {"spec": {"containers": [{
		"name": "worker",
		"image": "ghcr.io/example/worker:0.9.1",
		"resources": {"requests": {"cpu": "100m", "memory": "128Mi"}},
	}]}}},
}

bad_unset_ns := {
	"kind": "StatefulSet",
	"metadata": {"name": "db"},
	"spec": {"template": {"spec": {"containers": [{
		"name": "db",
		"image": "ghcr.io/example/db:1.0.0",
		"resources": {"requests": {"cpu": "100m", "memory": "128Mi"}},
	}]}}},
}

test_no_default_namespace_pass if {
	result := main.deny with input as good_deployment
	count(result) == 0
}

test_no_default_namespace_fail_explicit_default if {
	result := main.deny with input as bad_default_ns
	some msg in result
	contains(msg, "'default' namespace")
}

test_no_default_namespace_fail_namespace_unset if {
	result := main.deny with input as bad_unset_ns
	some msg in result
	contains(msg, "'default' namespace")
}
