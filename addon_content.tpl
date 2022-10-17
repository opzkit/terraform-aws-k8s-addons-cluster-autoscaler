apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  creationTimestamp: null
  labels:
    app.kubernetes.io/name: cluster-autoscaler
    k8s-app: cluster-autoscaler
  name: cluster-autoscaler
  namespace: kube-system
spec:
  maxUnavailable: 1
  selector:
    matchLabels:
      k8s-app: cluster-autoscaler

---

apiVersion: v1
automountServiceAccountToken: true
kind: ServiceAccount
metadata:
  creationTimestamp: null
  labels:
    app.kubernetes.io/name: cluster-autoscaler
    k8s-app: cluster-autoscaler
  name: cluster-autoscaler
  namespace: kube-system

---

apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  creationTimestamp: null
  labels:
    app.kubernetes.io/name: cluster-autoscaler
    k8s-app: cluster-autoscaler
  name: cluster-autoscaler
rules:
- apiGroups:
  - ""
  resources:
  - events
  - endpoints
  verbs:
  - create
  - patch
- apiGroups:
  - ""
  resources:
  - pods/eviction
  verbs:
  - create
- apiGroups:
  - ""
  resources:
  - pods/status
  verbs:
  - update
- apiGroups:
  - ""
  resourceNames:
  - cluster-autoscaler
  resources:
  - endpoints
  verbs:
  - get
  - update
- apiGroups:
  - ""
  resources:
  - nodes
  verbs:
  - watch
  - list
  - get
  - update
- apiGroups:
  - ""
  resources:
  - namespaces
  - pods
  - services
  - replicationcontrollers
  - persistentvolumeclaims
  - persistentvolumes
  verbs:
  - watch
  - list
  - get
- apiGroups:
  - batch
  resources:
  - jobs
  - cronjobs
  verbs:
  - watch
  - list
  - get
- apiGroups:
  - batch
  - extensions
  resources:
  - jobs
  verbs:
  - get
  - list
  - patch
  - watch
- apiGroups:
  - extensions
  resources:
  - replicasets
  - daemonsets
  verbs:
  - watch
  - list
  - get
- apiGroups:
  - policy
  resources:
  - poddisruptionbudgets
  verbs:
  - watch
  - list
- apiGroups:
  - apps
  resources:
  - daemonsets
  - replicasets
  - statefulsets
  verbs:
  - watch
  - list
  - get
- apiGroups:
  - storage.k8s.io
  resources:
  - storageclasses
  - csinodes
  - csidrivers
  - csistoragecapacities
  verbs:
  - watch
  - list
  - get
- apiGroups:
  - ""
  resources:
  - configmaps
  verbs:
  - list
  - watch
- apiGroups:
  - coordination.k8s.io
  resources:
  - leases
  verbs:
  - create
- apiGroups:
  - coordination.k8s.io
  resourceNames:
  - cluster-autoscaler
  resources:
  - leases
  verbs:
  - get
  - update

---

apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  creationTimestamp: null
  labels:
    app.kubernetes.io/name: cluster-autoscaler
    k8s-app: cluster-autoscaler
  name: cluster-autoscaler
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-autoscaler
subjects:
- kind: ServiceAccount
  name: cluster-autoscaler
  namespace: kube-system

---

apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  creationTimestamp: null
  labels:
    app.kubernetes.io/name: cluster-autoscaler
    k8s-app: cluster-autoscaler
  name: cluster-autoscaler
  namespace: kube-system
rules:
- apiGroups:
  - ""
  resources:
  - configmaps
  verbs:
  - create
- apiGroups:
  - ""
  resourceNames:
  - cluster-autoscaler-status
  resources:
  - configmaps
  verbs:
  - delete
  - get
  - update

---

apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  creationTimestamp: null
  labels:
    app.kubernetes.io/name: cluster-autoscaler
    k8s-app: cluster-autoscaler
  name: cluster-autoscaler
  namespace: kube-system
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: cluster-autoscaler
subjects:
- kind: ServiceAccount
  name: cluster-autoscaler
  namespace: kube-system

---

apiVersion: v1
kind: Service
metadata:
  creationTimestamp: null
  labels:
    app.kubernetes.io/name: cluster-autoscaler
    k8s-app: cluster-autoscaler
  name: cluster-autoscaler
  namespace: kube-system
spec:
  ports:
  - name: http
    port: 8085
    protocol: TCP
    targetPort: 8085
  selector:
    app.kubernetes.io/name: cluster-autoscaler
  type: ClusterIP

---

apiVersion: apps/v1
kind: Deployment
metadata:
  creationTimestamp: null
  labels:
    app.kubernetes.io/name: cluster-autoscaler
    k8s-app: cluster-autoscaler
  name: cluster-autoscaler
  namespace: kube-system
spec:
  replicas: ${replicas}
  selector:
    matchLabels:
      app: cluster-autoscaler
  template:
    metadata:
      annotations:
        prometheus.io/port: "8085"
        prometheus.io/scrape: "true"
      creationTimestamp: null
      labels:
        app: cluster-autoscaler
        app.kubernetes.io/name: cluster-autoscaler
        k8s-app: cluster-autoscaler
    spec:
      containers:
      - command:
        - ./cluster-autoscaler
        - --balance-similar-node-groups=false
        - --cloud-provider=aws
        - --aws-use-static-instance-list=false
        - --expander=random
        - --scale-down-utilization-threshold=0.5
        - --skip-nodes-with-local-storage=false
        - --skip-nodes-with-system-pods=false
        - --scale-down-delay-after-add=10m0s
        - --new-pod-scale-up-delay=0s
        - --max-node-provision-time=15m0s
        - --logtostderr=true
        - --stderrthreshold=info
        - --v=4
        - --node-group-auto-discovery=asg:tag=k8s.io/cluster-autoscaler/enabled,k8s.io/cluster-autoscaler/${cluster_name}
        image: registry.k8s.io/autoscaling/cluster-autoscaler:v${image_tag}
        imagePullPolicy: IfNotPresent
        livenessProbe:
          failureThreshold: 3
          httpGet:
            path: /health-check
            port: http
            scheme: HTTP
          periodSeconds: 10
          successThreshold: 1
          timeoutSeconds: 1
        name: cluster-autoscaler
        ports:
        - containerPort: 8085
          name: http
          protocol: TCP
        resources:
          requests:
            cpu: 100m
            memory: 300Mi
      dnsPolicy: ClusterFirst
      priorityClassName: system-cluster-critical
      securityContext:
        fsGroup: 10001
      serviceAccountName: cluster-autoscaler
      topologySpreadConstraints:
      - labelSelector:
          matchLabels:
            app: cluster-autoscaler
        maxSkew: 1
        topologyKey: topology.kubernetes.io/zone
        whenUnsatisfiable: ScheduleAnyway
      - labelSelector:
          matchLabels:
            app: cluster-autoscaler
        maxSkew: 1
        topologyKey: kubernetes.io/hostname
        whenUnsatisfiable: DoNotSchedule
