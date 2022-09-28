# Домашнее задание к занятию "10.02. Системы мониторинга"

## Обязательные задания

1. Опишите основные плюсы и минусы pull и push систем мониторинга.

Пулл:

    + Централизованный. Настраивается из одной точки.
    + Использует TCP, а данные ходят по HTTP — надёжнее.
    + Работает в режиме on-demand.
    
    - Всё централизовано, при поломке будет больше траблов.
    - Для discovery нужны дополнительные приблуды.
    - Сложней обеспечить безопасность канала агент-сервер
    
    
Пуш:

    + Хорошо скалируется горизонтально.
    + В общем, жрёт меньше ресурсов.
    + Более самостоятельные агенты.
    
    - Жрёт с экспортеров всё подряд, нужно дополнительно фильтровать.
    - Агенты настраиваются нецентрализованно, на местах.
    - Сложно детально диагностировать проблему через мониторинг.

2. Какие из ниже перечисленных систем относятся к push модели, а какие к pull? А может есть гибридные?

    - Prometheus Пулл
    - TICK Пуш
    - Zabbix Гибрид
    - VictoriaMetrics Гибрид
    - Nagios Пулл

3. Склонируйте себе [репозиторий](https://github.com/influxdata/sandbox/tree/master) и запустите TICK-стэк, 
используя технологии docker и docker-compose.

В виде решения на это упражнение приведите выводы команд с вашего компьютера (виртуальной машины):

    - curl http://localhost:8086/ping
    - curl http://localhost:8888
    - curl http://localhost:9092/kapacitor/v1/ping

А также скриншот веб-интерфейса ПО chronograf (`http://localhost:8888`). 

![изображение](https://user-images.githubusercontent.com/98019531/192807476-e535902a-58ba-454c-8efc-11e0e3e3563c.png)

![изображение](https://user-images.githubusercontent.com/98019531/192807558-c70543aa-42bf-4612-b8e5-b40d3b828312.png)

![изображение](https://user-images.githubusercontent.com/98019531/192808126-5ecdc527-91e5-4476-b50b-872307faf915.png)



4. Перейдите в веб-интерфейс Chronograf (`http://localhost:8888`) и откройте вкладку `Data explorer`.

    - Нажмите на кнопку `Add a query`
    - Изучите вывод интерфейса и выберите БД `telegraf.autogen`
    - В `measurments` выберите mem->host->telegraf_container_id , а в `fields` выберите used_percent. 
    Внизу появится график утилизации оперативной памяти в контейнере telegraf.
    - Вверху вы можете увидеть запрос, аналогичный SQL-синтаксису. 
    Поэкспериментируйте с запросом, попробуйте изменить группировку и интервал наблюдений.

Для выполнения задания приведите скриншот с отображением метрик утилизации места на диске 
(disk->host->telegraf_container_id) из веб-интерфейса.


![изображение](https://user-images.githubusercontent.com/98019531/192813830-702a5762-9e4e-4178-9a9b-a35e61dc8e7c.png)


5. Изучите список [telegraf inputs](https://github.com/influxdata/telegraf/tree/master/plugins/inputs). 
Добавьте в конфигурацию telegraf следующий плагин - [docker](https://github.com/influxdata/telegraf/tree/master/plugins/inputs/docker):
```
[[inputs.docker]]
  endpoint = "unix:///var/run/docker.sock"
```

Дополнительно вам может потребоваться донастройка контейнера telegraf в `docker-compose.yml` дополнительного volume и 
режима privileged:
```
  telegraf:
    image: telegraf:1.4.0
    privileged: true
    volumes:
      - ./etc/telegraf.conf:/etc/telegraf/telegraf.conf:Z
      - /var/run/docker.sock:/var/run/docker.sock:Z
    links:
      - influxdb
    ports:
      - "8092:8092/udp"
      - "8094:8094"
      - "8125:8125/udp"
```

После настройки перезапустите telegraf, обновите веб интерфейс и приведите скриншотом список `measurments` в 
веб-интерфейсе базы telegraf.autogen . Там должны появиться метрики, связанные с docker.

![изображение](https://user-images.githubusercontent.com/98019531/192817673-033ceaba-8add-484d-8a97-833af1a70fc6.png)


---

