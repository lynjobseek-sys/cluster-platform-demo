package main

import rego.v1

# Workloads in 'default' have no team owner, no NetworkPolicy boundary, and
# no quota. They're invisible to per-namespace RBAC and monitoring conventions.
# Force every workload into an explicit, owned namespace.

deny contains msg if {
	is_workload
	resource_namespace(input) == "default"
	msg := sprintf(
		"%s/%s is in the 'default' namespace: deploy into a team-owned namespace instead",
		[input.kind, resource_name(input)],
	)
}
