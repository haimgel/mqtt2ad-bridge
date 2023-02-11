# MQTT to Active Directory Bridge

> "'If it is stupid, but it works, it isn't stupid."

This container creates MQTT switches that control Active Directory 
group membership. If the switch is on, a particular user or subgroup
is added to a group, when it's off, it's removed. It's thin wrapper around 
the [mqtt2cmd](https://github.com/haimgel/mqtt2cmd)
MQTT to command-line applications gateway that I wrote.

## Why?

In my house, Wi-Fi access is configured with WPA-enterprise, and
Samba Active Directory domain controllers act as authentication and
authorization sources. Membership in "Network Access" group is what controls
whether one of my kids or any of their devices have Internet privileges or not.

Using this container, I can configure Home Assistant with automations to enable and
disable Internet access on a schedule, give my wife an easy way to control this from 
her phone manually.

## Configuration

Create a "mqtt2ad-bridge" user account in AD, give it read/write access to "Network Access" group.
I run this container on my Kubernetes cluster, like this:

Store the switch config map and AD credentials:
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  labels:
    app.kubernetes.io/instance: mqtt2ad-bridge
    app.kubernetes.io/name: mqtt2ad-bridge
  name: mqtt2ad-bridge
  namespace: home-automation
data:
  mqtt2cmd.yaml: |
    app-id: 'mqtt2ad-bridge-test'
    mqtt:
      broker: "tcp://mqtt.mydomain.com:1883"
    switches:
      - name: "network-access-arie"
        refresh: "30m"
        turn_on: '/app/ad-command.sh add "Network Access" "Devices-Arie"'
        turn_off: '/app/ad-command.sh remove "Network Access" "Devices-Arie"'
        get_state: '/app/ad-command.sh check "Network Access" "Devices-Arie"'
      - name: "network-access-benjie"
        refresh: "30m"
        turn_on: '/app/ad-command.sh add "Network Access" "Devices-Benjie"'
        turn_off: '/app/ad-command.sh remove "Network Access" "Devices-Benjie"'
        get_state: '/app/ad-command.sh check "Network Access" "Devices-Benjie"'
      - name: "network-access-daniel"
        refresh: "30m"
        turn_on: '/app/ad-command.sh add "Network Access" "Devices-Daniel"'
        turn_off: '/app/ad-command.sh remove "Network Access" "Devices-Daniel"'
        get_state: '/app/ad-command.sh check "Network Access" "Devices-Daniel"'
```

```yaml
apiVersion: v1
kind: Secret
metadata:
  labels:
    app.kubernetes.io/instance: mqtt2ad-bridge
    app.kubernetes.io/name: mqtt2ad-bridge
  name: mqtt2ad-bridge
  namespace: home-automation
type: Opaque
data:
  domain: your-ad-domain-base64
  password: mqtt2ad-bridge-ad-password-base64
  username: mqtt2ad-bridge-base64
```

And then create a simple deployment to run it:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app.kubernetes.io/instance: mqtt2ad-bridge
    app.kubernetes.io/name: mqtt2ad-bridge
  name: mqtt2ad-bridge
  namespace: home-automation
spec:
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/instance: mqtt2ad-bridge
      app.kubernetes.io/name: mqtt2ad-bridge
  template:
    metadata:
      labels:
        app.kubernetes.io/instance: mqtt2ad-bridge
        app.kubernetes.io/name: mqtt2ad-bridge
    spec:
      containers:
      - command:
        - mqtt2cmd
        - -c
        - /config/mqtt2cmd.yaml
        - -l
        - /dev/null
        env:
        - name: AD_DOMAIN
          valueFrom:
            secretKeyRef:
              key: domain
              name: mqtt2ad-bridge
        - name: AD_USERNAME
          valueFrom:
            secretKeyRef:
              key: username
              name: mqtt2ad-bridge
        - name: PASSWD_FILE
          value: /config/ad_password
        image: ghcr.io/haimgel/mqtt2ad-bridge:1.0
        imagePullPolicy: IfNotPresent
        name: mqtt2ad-bridge
        resources:
          limits:
            cpu: "1"
            memory: 100Mi
          requests:
            cpu: 10m
            memory: 20Mi
        securityContext:
          runAsGroup: 65534
          runAsUser: 65534
        volumeMounts:
        - mountPath: /config/mqtt2cmd.yaml
          name: config
          subPath: mqtt2cmd.yaml
        - mountPath: /config/ad_password
          name: credentials
          subPath: password
      enableServiceLinks: false
      volumes:
      - name: config
        configMap:
          defaultMode: 420
          name: mqtt2ad-bridge
      - name: credentials
        secret:
          defaultMode: 420
          secretName: mqtt2ad-bridge
```
