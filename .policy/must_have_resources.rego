package main

import rego.v1

# Every workload container must declare CPU and memory requests.
# Missing requests means scheduler can't reason about capacity and HPA/VPA
# have no baseline. Limits are intentionally not required here (CPU limits
# in particular are often counterproductive).

deny contains msg if {
	some c in workload_containers
	not has_cpu_request(c)
	msg := sprintf(
		"%s/%s container %q is missing resources.requests.cpu",
		[input.kind, resource_name(input), c.name],
	)
}

deny contains msg if {
	some c in workload_containers
	not has_memory_request(c)
	msg := sprintf(
		"%s/%s container %q is missing resources.requests.memory",
		[input.kind, resource_name(input), c.name],
	)
}

has_cpu_request(c) if c.resources.requests.cpu

has_memory_request(c) if c.resources.requests.memory
