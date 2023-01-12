## 1. Плагин Calico

Порверяем текущий плагин. Для этого рациональнее всего поглядеть в инвентори кубспрея, а что же он нам поставил?

![изображение](https://user-images.githubusercontent.com/98019531/212032428-e4621124-5e2f-4fa1-a51c-86c2b7e74a69.png)

Отлично. Дальше работаем с установленным Calico.

Пилим Network Policy для установленного в прошлый раз nginx:

```
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: ingresspolicy
  namespace: default
spec:
  podSelector:
    matchLabels:
      app: nginx
  policyTypes:
    - Ingress
  ingress:
    - ports:
        - port: 80
        - port: 443
```

## 2. Экзерсисы с calicoctl

Тащим бинарь с гита, закидываем к бинарникам и чекаем версию:

![изображение](https://user-images.githubusercontent.com/98019531/212037410-604e4bdb-0bc1-44ee-9528-3db5804a8ba4.png)

Забираем через calicoctl ноды, пулы и профайлы:

![изображение](https://user-images.githubusercontent.com/98019531/212038596-1400e767-a189-4981-bea2-6e8cf16f471d.png)
