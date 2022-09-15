1. Ставим окружение для дженкинса.

![изображение](https://user-images.githubusercontent.com/98019531/190084585-fa765b7f-9f87-4e6e-a6f0-ca6b1864bf2d.png)

Допиливаем дженкинс.

![изображение](https://user-images.githubusercontent.com/98019531/190084705-c2ee1a98-1455-4f96-8370-31b108ce6b71.png)

2. Настраиваем проект, добавляем репу, добавляем ключи с мастер-дженкинса в сам дженкинс и в гитхаб.

Пишем жобу:

![изображение](https://user-images.githubusercontent.com/98019531/190091956-56c7a1bd-2ad1-4534-b54d-57a580fdc0e3.png)

Жоба работает и находит ошибки.

![изображение](https://user-images.githubusercontent.com/98019531/190148883-4c7800b1-b467-4a75-81d4-c727c659e1fa.png)

Пишем декларативный скриптовый пайплайн.

```
pipeline {
    agent any
    stages {
        stage('checkout') {
            steps {
                git credentialsId: '20eabf2e-aef7-4367-b7ea-4d6222f93fe5', 
                url: 'git@github.com:ComradeTempest/vector.git',
                branch: 'main'
            }
        }
        stage('test') {
            steps {
                sh 'molecule test'
            }
        }
    }
}
```

Пайплайн работает.

![изображение](https://user-images.githubusercontent.com/98019531/190149392-2ad89750-d2be-499a-9b3a-799169168a76.png)

Делаем мультибранч, он автоматом сканирует всё, что должно — успешно.

![изображение](https://user-images.githubusercontent.com/98019531/190153775-736a9690-3963-4423-bc9d-a086bdade004.png)

![изображение](https://user-images.githubusercontent.com/98019531/190154002-b8ca3948-8f58-407a-b53d-af0679269f14.png)

Собрали scripted pipeline, всё ок, с аргументом и без.

![изображение](https://user-images.githubusercontent.com/98019531/190204886-334e0daf-69f5-4b68-a701-de5cc610351b.png)


Линк на репу с ролью и дженкинсфайлами: https://github.com/ComradeTempest/vector

АПДЕЙТ

![изображение](https://user-images.githubusercontent.com/98019531/190393317-111202d3-8046-41ad-a8eb-72edfd7726f9.png)

Проверка молекулой завершилась успешно, дело было в хостах.

