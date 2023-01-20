## 1. Общая папка для тестового конфига.

Для начала мы допилим кусочек спеки из деплоя для предыдущего задания.

```
---
apiVersion: v1
kind: Namespace
metadata:
  name: stage

---
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: teststage
  name: teststage
  namespace: stage
spec:
  replicas: 1
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
      maxSurge: 1
  selector:
    matchLabels:
      app: teststage
  template:
    metadata:
      labels:
        app: teststage
    spec:
      containers:
      - name: frontend
        image: nginx:latest
        ports:
        - containerPort: 80
        volumeMounts:
          - mountPath: "/testnginx"
            name: testvolume
      - name: backend
        image: alpine:latest
        volumeMounts:
          - mountPath: "/testalpine"
            name: testvolume
        command: ["sleep", "3600"]
      volumes:
        - name: testvolume
          emptyDir: {}

---
apiVersion: v1
kind: Service
metadata:
  name: teststagesvc
  labels:
    app: teststage
spec:
  type: NodePort
  ports:
  - port: 80
    nodePort: 32280
  selector:
    app: teststage

```

Скрин с проверкой взаимодействия.

![изображение](https://user-images.githubusercontent.com/98019531/213658481-04a338b7-2111-4be2-9bf2-f7f861bb956e.png)

## 2. Цепляем HFS-шару на проде.

Поставили хелм, раскатали nfs-server.

![изображение](https://user-images.githubusercontent.com/98019531/213674202-7b5221e4-2db7-4d05-9a14-def902dc13a1.png)

Допилим старые деплои и сделаем из них один толстенький, который будет цеплять фронт, бэк и PVC.

```
test@minikube:/data/13_2$ cat grandprod.yml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: prodfront
  labels:
    app: prodfrontapp
spec:
  replicas: 1
  minReadySeconds: 15
  selector:
    matchLabels:
      app: prodfrontapp
  template:
    metadata:
      labels:
        app: prodfrontapp
    spec:
      containers:
        - name: frontend
          image: nginx:latest
          ports:
            - containerPort: 88
          env:
            - name: PRODUCT_BACK_SERVER_URL
              value: prodbackapp
          volumeMounts:
            - mountPath: /testshare
              name: share
      volumes:
        - name: share
          persistentVolumeClaim:
            claimName: pvc

---
apiVersion: v1
kind: Service
metadata:
  name: prodfrontsvc
  labels:
    app: prodfrontapp
spec:
  type: NodePort
  ports:
    - port: 88
      nodePort: 32288
  selector:
    app: prodfrontapp

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: prodback
  labels:
    app: prodbackapp
spec:
  replicas: 1
  minReadySeconds: 15
  selector:
    matchLabels:
      app: prodbackapp
  template:
    metadata:
      labels:
        app: prodbackapp
    spec:
      containers:
        - env:
            - name: DATABASE_HOST
              value: proddb
            - name: DATABASE_PORT
              value: "5432"
          name: backend
          image: alpine:latest
          command:
            - sleep
            - "3600"
          ports:
            - containerPort: 81
          volumeMounts:
            - mountPath: /testshare
              name: share
      volumes:
        - name: share
          persistentVolumeClaim:
            claimName: pvc

---
apiVersion: v1
kind: Service
metadata:
  name: prodbacksvc
  labels:
    app: prodbackapp
spec:
  type: NodePort
  ports:
    - port: 81
      nodePort: 32281
  selector:
    app: prodbackapp

---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc
spec:
  storageClassName: nfs
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
```

![изображение](https://user-images.githubusercontent.com/98019531/213685638-6181b199-6ec0-47b0-8b76-0552acc6fda5.png)


Проверяем — создаём бэком файлик и наполнение, чекаем из фронта:

![изображение](https://user-images.githubusercontent.com/98019531/213685528-6a386559-f4e2-4f4f-8fc4-3e2178ad6e30.png)

