package main

import rego.v1

is_workload if input.kind == "Deployment"

is_workload if input.kind == "StatefulSet"

workload_containers contains c if {
	is_workload
	some c in input.spec.template.spec.containers
}

workload_containers contains c if {
	is_workload
	some c in input.spec.template.spec.initContainers
}

resource_name(obj) := obj.metadata.name if {
	obj.metadata.name
}

resource_name(obj) := "<unnamed>" if {
	not obj.metadata.name
}

resource_namespace(obj) := obj.metadata.namespace if {
	obj.metadata.namespace
}

resource_namespace(obj) := "default" if {
	not obj.metadata.namespace
}
