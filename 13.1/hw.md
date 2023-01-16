## 1. Stage.

Переключаемся на нужный контекст:

![изображение](https://user-images.githubusercontent.com/98019531/212692193-4169c9bb-5516-407f-94be-00f86be5c5a9.png)

Пишем деплоймент на 2 контейнера. Вместо фронта берём nginx, alpine сойдёт за бэк.

```
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
      - name: backend
        image: alpine:latest
        command: ["sleep", "3600"]

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

Также пишем коротенький statefulset для постгреса:

```
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: teststagedb
spec:
  serviceName: teststagedb-svc
  selector:
    matchLabels:
      app: teststagedb
  replicas: 1
  template:
    metadata:
      labels:
        app: teststagedb
    spec:
      containers:
        - name: teststagedb
          image: postgres:latest
          volumeMounts:
            - name: teststagedbvolume
              mountPath: /data/13_1/db
          env:
            - name: POSTGRES_PASSWORD
              value: testpassword
            - name: PGDATA
              value: /data/13_1/db

---
apiVersion: v1
kind: Service
metadata:
  name: teststagelb
spec:
  selector:
    app: teststagedb
  type: LoadBalancer
  ports:
    - port: 5432
      targetPort: 5432
```

Скрины из kubectl:

![изображение](https://user-images.githubusercontent.com/98019531/212703796-4a1527a8-656d-476c-8b90-370b41434e90.png)

Чтобы убедиться, что в поде два контейнера, вот скрин описания пода (хвост с эвентами не влез):

![изображение](https://user-images.githubusercontent.com/98019531/212704173-8f3652e5-6445-4cb5-b384-4e6a51143a72.png)


## 2. Prod

Переключаемся на прод через set-context.

Нам придётся разбить деплой для приложений на два — prodfront и prodback — и немножко его допилить, чтобы фронт видел бэк, а бэк видел БД.

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: prodfront
  labels:
    app: prodfrontapp
spec:
  replicas: 1
  minReadySeconds: 15
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
      maxSurge: 1
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
```
В prodback поместили env, указывающие на БД.

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: prodback
  labels:
    app: prodbackapp
spec:
  replicas: 1
  minReadySeconds: 15
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
      maxSurge: 1
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
        command: ["sleep", "3600"]
        ports:
        - containerPort: 81
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
```

И подновлённый statefulset для БД

```
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: proddb
spec:
  serviceName: proddbsvc
  selector:
    matchLabels:
      app: proddb
  replicas: 1
  template:
    metadata:
      labels:
        app: proddb
    spec:
      containers:
        - name: proddb
          image: postgres:latest
          volumeMounts:
            - name: proddbvolume
              mountPath: /data/13_1/prod/db
          env:
            - name: POSTGRES_PASSWORD
              value: testpassword
            - name: PGDATA
              value: /data/13_1/prod/db
---
apiVersion: v1
kind: Service
metadata:
  name: prodlb
spec:
  selector:
    app: proddb
  type: LoadBalancer
  ports:
    - port: 5432
      targetPort: 5432
```

Отчётный скрин из kubectl:

![изображение](https://user-images.githubusercontent.com/98019531/212709713-e9a77acf-bbdb-407d-970f-54161bf11c8f.png)

