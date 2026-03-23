# Data Model: Kafka Component and Dashboard

## Kafka Component

**Purpose**: Represents the deployable event-streaming capability managed through Terraform for an existing kind-based cluster.

**Fields**:

- `enabled`: Whether the Kafka capability is included in an aggregate deployment.
- `namespace`: Kubernetes namespace used for Kafka-related workloads.
- `release_name`: Operator-visible name for the Kafka deployment.
- `chart_repository`: Source location for the Kafka chart package.
- `chart_name`: Chart identifier or local chart path used by the module.
- `chart_version`: Requested chart version for the Kafka deployment.
- `expose_dashboard_public`: Whether the dashboard should be reachable from outside the cluster.
- `dashboard_node_port`: Reserved in-cluster service port for optional public dashboard exposure.
- `dashboard_host_port`: Host port reserved through kind when public dashboard exposure is enabled.
- `persistence_enabled`: Whether Kafka data should survive pod rescheduling or component restarts.
- `persistence_size`: Requested storage size for Kafka data when persistence is enabled.
- `recreate_revision`: Replacement token used to force a controlled redeployment when necessary.

**Validation Rules**:

- `namespace` must be a non-empty Kubernetes-compatible namespace string.
- `release_name` must be non-empty and stable across redeployments unless intentional replacement is desired.
- `dashboard_node_port` and `dashboard_host_port` must be valid non-conflicting port numbers when public exposure is enabled.
- `persistence_size` must be provided in a valid storage quantity format when persistence is enabled.

**Relationships**:

- Depends on `Cluster Environment` for deployment target and optional host-port mappings.
- Owns one `Kafka Dashboard` configuration for operator access.
- Produces `Operator Access Details` for clients and operators.

**State Transitions**:

1. `Not Configured` -> `Configured` when the operator provides or accepts Kafka inputs.
2. `Configured` -> `Deploying` when Terraform applies the Kafka component.
3. `Deploying` -> `Ready` when Kafka and dashboard resources are healthy.
4. `Deploying` -> `Failed` when cluster prerequisites or deployment resources are unavailable.
5. `Ready` -> `Reconfiguring` when the operator changes Kafka or dashboard settings.
6. `Reconfiguring` -> `Ready` or `Failed` depending on reconciliation outcome.

## Kafka Dashboard

**Purpose**: Represents the operator-facing interface that visualizes Kafka brokers, topics, partitions, and consumer activity.

**Fields**:

- `enabled`: Whether the dashboard is deployed with Kafka.
- `release_name`: Operator-visible release name for the dashboard deployment.
- `chart_repository`: Source location for the dashboard chart package.
- `chart_name`: Chart identifier or local chart path used by the dashboard deployment.
- `chart_version`: Requested chart version for the dashboard deployment.
- `service_type`: Internal-only or publicly exposed service mode.
- `node_port`: Optional NodePort value when public exposure is enabled.
- `target_cluster_reference`: Connection reference used by the dashboard to reach Kafka.

**Validation Rules**:

- Dashboard deployment requires a valid target Kafka reference.
- `node_port` must be omitted when public exposure is disabled.
- Dashboard release naming must remain unique within the namespace.

**Relationships**:

- Attached to exactly one `Kafka Component`.
- Consumes `Operator Access Details` produced by the Kafka service configuration.

## Cluster Environment

**Purpose**: Represents the existing kind-based cluster dependency that must be available before Kafka and the dashboard can be deployed.

**Fields**:

- `cluster_name`: Kind cluster name used by Terraform and Kubernetes providers.
- `kubeconfig_path`: Path used by providers to reach the cluster.
- `api_server_host`: Host or IP used for optional public service URLs.
- `dashboard_port_mapping`: Optional mapping that binds a dashboard NodePort to a reachable host port.

**Validation Rules**:

- `kubeconfig_path` must resolve to a readable kubeconfig before component deployment.
- `dashboard_port_mapping` must align with dashboard exposure settings when enabled.

**Relationships**:

- Required by `Kafka Component`.
- Shared with `components/all` and `components/kind-cluster`.

## Operator Access Details

**Purpose**: Represents the operator-visible outputs that document how internal workloads connect to Kafka and how operators open the dashboard.

**Fields**:

- `bootstrap_servers`: In-cluster Kafka connection endpoint exposed to workloads.
- `dashboard_url`: Optional public URL for the dashboard when exposure is enabled.
- `namespace`: Namespace where Kafka and dashboard resources were deployed.
- `release_names`: Operator-visible release identifiers for Kafka and the dashboard.

**Validation Rules**:

- `bootstrap_servers` must always be present once Kafka is ready.
- `dashboard_url` may be null only when public exposure is disabled.

**Relationships**:

- Produced by the `Kafka Component`.
- Consumed by operators, internal workloads, and aggregate outputs.
