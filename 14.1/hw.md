## 1. Команды и их вывод.

![изображение](https://user-images.githubusercontent.com/98019531/217749800-9df44532-ef9e-4972-8e58-08f08366017c.png)

![изображение](https://user-images.githubusercontent.com/98019531/217749909-47d15912-ee78-479a-8c4c-2da949374514.png)

![изображение](https://user-images.githubusercontent.com/98019531/217750023-55be5c35-10e4-4f4a-b7c7-04762ebacd9b.png)

![изображение](https://user-images.githubusercontent.com/98019531/217752862-982501b3-4997-4953-ab76-6c133ef540ce.png)

![изображение](https://user-images.githubusercontent.com/98019531/217752939-0d5e1831-19fa-4b08-8dbd-a5d141c9d852.png)

![изображение](https://user-images.githubusercontent.com/98019531/217755571-27051a08-42e2-4048-948f-930bba4d669a.png)

## 2. Работаем с секретами.

Сделаем хитрый секрет в yaml-формате и сразу применим его.

![изображение](https://user-images.githubusercontent.com/98019531/217757757-1dfde543-412c-4017-836c-4fb591af074e.png)

Пишем маленький конфиг пода — созданный секрет у нас пойдёт через env, а тот, который получился в первой части, мы маунтим.

```
---
apiVersion: v1
kind: Pod
metadata:
  labels:
    app: test
  name: test
  namespace: default

spec:
  containers:
    - image: nginx:latest
      name: testnginx
      env:
        - name: USER
          valueFrom:
            secretKeyRef:
              name: testsecret
              key: user
        - name: PASSWORD
          valueFrom:
            secretKeyRef:
              name: testsecret
              key: password
      volumeMounts:
        - mountPath: "/etc/nginx/ssl"
          name: "sslsecret"
          readOnly: true

  volumes:
    - name: "sslsecret"
      secret:
        secretName: domain-cert
```

Проверим, что у нас прошло через переменные:

![изображение](https://user-images.githubusercontent.com/98019531/217761100-7132be77-24aa-4289-9b2e-cd39d231b9ef.png)

Отлично. Теперь проверим, что примаунтилось в /etc/nginx/ssl:

![изображение](https://user-images.githubusercontent.com/98019531/217761594-522d012a-64f4-4250-9339-1d9da9a32dda.png)

Вполне пристойно.
