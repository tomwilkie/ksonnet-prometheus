local k = import "ksonnet.beta.2/k8s.libsonnet";

local configMap = k.core.v1.configMap,
  container = k.apps.v1beta1.deployment.mixin.spec.template.spec.containersType,
  deployment = k.apps.v1beta1.deployment,
  daemonSet = k.extensions.v1beta1.daemonSet,
  service = k.core.v1.service,
  servicePort = k.core.v1.service.mixin.spec.portsType,
  volume = deployment.mixin.spec.template.spec.volumesType;

local httpPort = 80;
local grcpPort = 9095;

{
  // Put stuff here that should be overridden when the config is specialised.
  _config+:: {
    namespace: error "'namespace' needs to be set",
  },

  _images+:: {
  },

  // By default, generate a namespace object.
  namespace:
    k.core.v1.namespace.new() +
    k.core.v1.namespace.mixin.metadata.name($._config.namespace),

  util:: {
    deployment(name, containers)::
      deployment.new(name, 1, containers, {}) +
      deployment.mixin.metadata.namespace($._config.namespace) +

      // We want to specify a minReadySeconds on every deployment, so we get some
      // very basic canarying, for instance, with bad arguments.
      deployment.mixin.spec.minReadySeconds(10) +

      // We want to add a sensible default for the number of old deployments
      // handing around.
      deployment.mixin.spec.revisionHistoryLimit(10) +

      // We want the deployment name to also be a label 'name' on each pod, for
      // service selectors.
      deployment.mixin.spec.template.metadata.labels({ name: name }),

    daemonSet(name, containers)::
      daemonSet.new() +
      daemonSet.mixin.metadata.namespace($._config.namespace) +
      daemonSet.mixin.metadata.name(name) +
      daemonSet.mixin.spec.template.metadata.labels({ name: name }) +

      // We want to specify a minReadySeconds on every deamonset, so we get some
      // very basic canarying, for instance, with bad arguments.
      daemonSet.mixin.spec.minReadySeconds(10) +
      daemonSet.mixin.spec.updateStrategy.type("RollingUpdate") +

      daemonSet.mixin.spec.template.spec.containers(containers),

    configVolumeMount(volumeName, path)::
      local volumeMount = self.volumeMount;
      {
        local containers = super.spec.template.spec.containers,
        spec+: { template+: { spec+: { containers: [
          c + volumeMount(volumeName, path)
            for c in containers
        ] } } },
      } +
      deployment.mixin.spec.template.spec.volumes([
        volume.name(volumeName) +
        volume.mixin.configMap.name(volumeName),
      ]),

    hostVolumeMount(volumeName, hostPath, containerPath)::
      local volumeMount = self.volumeMount;
      {
        local containers = super.spec.template.spec.containers,
        spec+: { template+: { spec+: { containers: [
          c + volumeMount(volumeName, containerPath)
            for c in containers
        ] } } },
      } +
      deployment.mixin.spec.template.spec.volumes([
        volume.name(volumeName) +
        volume.mixin.hostPath.path(hostPath),
      ]),

    secretVolumeMount(secretName, path)::
      local volumeMount = self.volumeMount;
      {
        local containers = super.spec.template.spec.containers,
        spec+: { template+: { spec+: { containers: [
          c + volumeMount(secretName, path)
            for c in containers
        ] } } },
      } +
      deployment.mixin.spec.template.spec.volumes([
        volume.new() +
        volume.name(secretName) +
        volume.mixin.secret.secretName(secretName),
      ]),

    container(name, image)::
      container.new(name, image) +
      container.imagePullPolicy("IfNotPresent"),

    volumeMount(volume, path)::
      container.volumeMounts([
        container.volumeMountsType.new(volume, path),
      ]),

    defaultPorts()::
      self.containerPort("http", httpPort) +
      self.containerPort("grpc", grcpPort),

    containerPort(name, port)::
      container.ports([
        container.portsType.new(port) +
        container.portsType.name(name),
      ]),

    containerResourcesRequests(memory, cpu)::
      container.mixin.resources.requests({
        memory: memory,
        cpu: cpu,
      }),

    containerResourcesLimits(memory, cpu)::
      container.mixin.resources.limits({
        memory: memory,
        cpu: cpu,
      }),

    service(name)::
      service.new() +
      service.mixin.metadata.namespace($._config.namespace) +
      service.mixin.metadata.name(name),

    // serviceFor create service for a given deployment.
    serviceFor(deployment)::
      local ports = [
        self.servicePort(_container.name + "-" + port.name, port.containerPort)
          for _container in deployment.spec.template.spec.containers
            for port in (_container + container.ports([])).ports
      ];

      service.new(deployment.metadata.name, deployment.spec.template.metadata.labels, ports) +
      service.mixin.metadata.namespace($._config.namespace),

    servicePort(name, port)::
      servicePort.new(port, port) +
      servicePort.name(name),

    configMap(name)::
      configMap.new() +
      configMap.mixin.metadata.namespace($._config.namespace) +
      configMap.mixin.metadata.name(name),
  },
}
