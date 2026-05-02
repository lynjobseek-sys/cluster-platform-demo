package main

import rego.v1

# Application ServiceAccounts must not be granted cluster-admin.
# System SAs (kube-system, kubernetes-dashboard, etc.) are allowed because
# control-plane components legitimately need it. App workloads should not.

deny contains msg if {
	is_role_binding
	binds_cluster_admin
	some s in input.subjects
	is_app_service_account(s)
	msg := sprintf(
		"%s/%s binds cluster-admin to ServiceAccount %s/%s: app SAs must use a scoped Role",
		[input.kind, resource_name(input), s.namespace, s.name],
	)
}

is_role_binding if input.kind == "ClusterRoleBinding"

is_role_binding if input.kind == "RoleBinding"

binds_cluster_admin if {
	input.roleRef.kind == "ClusterRole"
	input.roleRef.name == "cluster-admin"
}

is_app_service_account(s) if {
	s.kind == "ServiceAccount"
	not system_namespace(s.namespace)
}

system_namespace(ns) if ns == "kube-system"

system_namespace(ns) if ns == "kube-public"

system_namespace(ns) if ns == "kube-node-lease"
