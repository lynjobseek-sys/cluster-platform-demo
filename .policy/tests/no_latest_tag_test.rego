package tests.no_latest_tag

import rego.v1

import data.main

good_deployment := {
	"kind": "Deployment",
	"metadata": {"name": "web", "namespace": "frontend-prod"},
	"spec": {"template": {"spec": {"containers": [{
		"name": "web",
		"image": "ghcr.io/example/web:1.4.2",
		"resources": {"requests": {"cpu": "100m", "memory": "128Mi"}},
	}]}}},
}

bad_latest := {
	"kind": "Deployment",
	"metadata": {"name": "web", "namespace": "frontend-prod"},
	"spec": {"template": {"spec": {"containers": [{
		"name": "web",
		"image": "ghcr.io/example/web:latest",
		"resources": {"requests": {"cpu": "100m", "memory": "128Mi"}},
	}]}}},
}

bad_no_tag := {
	"kind": "Deployment",
	"metadata": {"name": "web", "namespace": "frontend-prod"},
	"spec": {"template": {"spec": {"containers": [{
		"name": "web",
		"image": "ghcr.io/example/web",
		"resources": {"requests": {"cpu": "100m", "memory": "128Mi"}},
	}]}}},
}

test_no_latest_tag_pass if {
	result := main.deny with input as good_deployment
	count(result) == 0
}

test_no_latest_tag_fail_explicit_latest if {
	result := main.deny with input as bad_latest
	some msg in result
	contains(msg, "uses image")
}

test_no_latest_tag_fail_no_tag if {
	result := main.deny with input as bad_no_tag
	some msg in result
	contains(msg, "uses image")
}
