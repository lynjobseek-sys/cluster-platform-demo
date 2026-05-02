package tests.must_have_resources

import rego.v1

import data.main

good_deployment := {
	"kind": "Deployment",
	"metadata": {"name": "api", "namespace": "backend-dev"},
	"spec": {"template": {"spec": {"containers": [{
		"name": "api",
		"image": "ghcr.io/example/api:2.0.0",
		"resources": {"requests": {"cpu": "250m", "memory": "256Mi"}},
	}]}}},
}

bad_no_requests := {
	"kind": "Deployment",
	"metadata": {"name": "api", "namespace": "backend-dev"},
	"spec": {"template": {"spec": {"containers": [{
		"name": "api",
		"image": "ghcr.io/example/api:2.0.0",
	}]}}},
}

bad_partial_requests := {
	"kind": "Deployment",
	"metadata": {"name": "api", "namespace": "backend-dev"},
	"spec": {"template": {"spec": {"containers": [{
		"name": "api",
		"image": "ghcr.io/example/api:2.0.0",
		"resources": {"requests": {"cpu": "250m"}},
	}]}}},
}

test_must_have_resources_pass if {
	result := main.deny with input as good_deployment
	count(result) == 0
}

test_must_have_resources_fail_missing_both if {
	result := main.deny with input as bad_no_requests
	count([m | some m in result; contains(m, "missing resources.requests")]) == 2
}

test_must_have_resources_fail_missing_memory_only if {
	result := main.deny with input as bad_partial_requests
	count([m | some m in result; contains(m, "missing resources.requests.memory")]) == 1
	count([m | some m in result; contains(m, "missing resources.requests.cpu")]) == 0
}
