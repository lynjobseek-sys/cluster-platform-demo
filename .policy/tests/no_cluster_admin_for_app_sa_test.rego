package tests.no_cluster_admin_for_app_sa

import rego.v1

import data.main

good_binding := {
	"kind": "ClusterRoleBinding",
	"metadata": {"name": "frontend-app-reader"},
	"roleRef": {"apiGroup": "rbac.authorization.k8s.io", "kind": "ClusterRole", "name": "view"},
	"subjects": [{"kind": "ServiceAccount", "name": "frontend-app", "namespace": "frontend-prod"}],
}

bad_app_sa_admin := {
	"kind": "ClusterRoleBinding",
	"metadata": {"name": "frontend-app-admin"},
	"roleRef": {"apiGroup": "rbac.authorization.k8s.io", "kind": "ClusterRole", "name": "cluster-admin"},
	"subjects": [{"kind": "ServiceAccount", "name": "frontend-app", "namespace": "frontend-prod"}],
}

system_sa_admin_allowed := {
	"kind": "ClusterRoleBinding",
	"metadata": {"name": "kube-system-admin"},
	"roleRef": {"apiGroup": "rbac.authorization.k8s.io", "kind": "ClusterRole", "name": "cluster-admin"},
	"subjects": [{"kind": "ServiceAccount", "name": "controller", "namespace": "kube-system"}],
}

test_no_cluster_admin_pass_scoped_role if {
	result := main.deny with input as good_binding
	count(result) == 0
}

test_no_cluster_admin_fail_app_sa if {
	result := main.deny with input as bad_app_sa_admin
	some msg in result
	contains(msg, "binds cluster-admin")
}

test_no_cluster_admin_pass_system_sa if {
	result := main.deny with input as system_sa_admin_allowed
	count(result) == 0
}
