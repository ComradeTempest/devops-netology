1.
```
version: '2.1'

services:
  db:
    container_name: db
    image: postgres:12-alpine
    restart: always
    environment:
      POSTGRES_PASSWORD: test
      POSTGRES_USER: root
    expose:
      - 5432
    ports:
      - "5432:5432"
    restart: unless-stopped
    volumes:
	    - /data/backup:/backup
      - /data/db:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "psql -h 'localhost' -U 'root' -c '\\l'"]
      interval: 1s
      timeout: 3s
      retries: 30
(Хелсчек опционален)
```
2.
![изображение](https://user-images.githubusercontent.com/98019531/169092373-f50d231e-f021-413b-9b79-d987a64c6b79.png)
![изображение](https://user-images.githubusercontent.com/98019531/169092630-caeefc3d-65e0-4b3b-8bf0-7050e57b4025.png)
![изображение](https://user-images.githubusercontent.com/98019531/169093076-846f68d0-4e85-44f2-9893-983a11115d54.png)
![изображение](https://user-images.githubusercontent.com/98019531/169095616-4262ad6e-468f-4450-9db3-441b14600a0a.png)


3.
![изображение](https://user-images.githubusercontent.com/98019531/169100978-746aac91-0a28-452c-a4a8-43c9ecf8689f.png)


4.
![изображение](https://user-images.githubusercontent.com/98019531/169129843-4c6553c9-3d02-449a-b786-8f2dcab3af94.png)

(Order интегерный, ибо планировался числовой номер заказа)

![изображение](https://user-images.githubusercontent.com/98019531/169136007-752d1e85-b48f-41ce-b487-9d12c45beffd.png)


5.
![изображение](https://user-images.githubusercontent.com/98019531/169146059-6ef11d25-e8fd-47f1-9d53-c79ad9029385.png)

Сие означает, что было выполнено последовательное сканирование таблички clients, первая строка получена за 0,00, последняя за 18.10,
сканирование приблизительно вернуло нам 810 строк (ишь разогнался) средним размером в 72 байта. В итоге осуществилась фильтрация и было отрезано два ряда.

6.
Поскольку барахла у нас тут не очень много, но оно довольно плотно переплетено, делаем так:
pg_dumpall -U root > /backup/dumpall
Сообразно команде, полный дамп сервера падает в директорию /backup на локальную машину. После чего мы можем не просто заглушить контейнер, мы можем спокойно
стопнуть стек компоуза. Потом мы пересоздаём чистую среду с сервером постгрес тем же компоуз-манифестом. Заливаем установку через
psql -U root -h localhost -p 5432 < /backup/dumpall или psql -f /backup/dumpall root — Готово, великий успех!
