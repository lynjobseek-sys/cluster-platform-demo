package main

import rego.v1

# Block :latest (or no tag, which resolves to :latest) on workload images.
# Without a pinned tag, rollbacks are non-deterministic and image cache can serve
# stale bits across nodes.

deny contains msg if {
	some c in workload_containers
	uses_latest(c.image)
	msg := sprintf(
		"%s/%s container %q uses image %q: pin an explicit tag or digest, not :latest",
		[input.kind, resource_name(input), c.name, c.image],
	)
}

uses_latest(image) if endswith(image, ":latest")

uses_latest(image) if {
	# image like "registry:port/name" without a tag. Strip registry, then check.
	parts := split(image, "/")
	last := parts[count(parts) - 1]
	not contains(last, ":")
}
