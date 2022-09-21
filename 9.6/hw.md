Развернули кластер, создали инстанс, подняли репу, наполнили частично файлом.

![изображение](https://user-images.githubusercontent.com/98019531/191514776-69c2ef5a-33cc-4d63-bd7c-75e632e6f7eb.png)

Пилим requirements и докерфайл:

```
FROM centos:7

RUN yum install python3 curl -y

COPY requirements.txt requirements.txt

RUN pip3 install -r requirements.txt

COPY python-api.py /api/python-api.py

EXPOSE 5290

CMD ["python3", "/api/python-api.py"]
```

Залили скрипты для CI. Пайплайн тут же побежал соборать/заливать. Успех!

![изображение](https://user-images.githubusercontent.com/98019531/191523805-a9dfa288-f7ce-43b4-a27e-f1789e1725f6.png)

Раскатали докер-образ:

![изображение](https://user-images.githubusercontent.com/98019531/191529223-be486af0-be9d-4ebf-bfbc-fe0173d504b9.png)

Не нравится — сделали таску текст поправить

![изображение](https://user-images.githubusercontent.com/98019531/191530322-7e46b84b-fe0a-4931-9118-3d4fc7fd4e0c.png)

Отбранчевались, поправили

![изображение](https://user-images.githubusercontent.com/98019531/191530726-323f54bb-dbea-476b-8748-fea4ab429596.png)

Собрали, залили в регистр, тестер скачал, развернул контейнер

![изображение](https://user-images.githubusercontent.com/98019531/191532619-f52197a9-3d84-44cb-911c-b08b83080cb3.png)

![изображение](https://user-images.githubusercontent.com/98019531/191532689-16b0c5b6-4f89-4a2e-9377-9b77f767a62b.png)

Успешно, молодцы

Откомментились

![изображение](https://user-images.githubusercontent.com/98019531/191532970-9c13be29-2556-4ce0-9f6b-de333de1fa87.png)


Ссылка на гитлаб

https://netology96.gitlab.yandexcloud.net/admin96/test96/-/tree/main

