### Как сдавать задания

Вы уже изучили блок «Системы управления версиями», и начиная с этого занятия все ваши работы будут приниматься ссылками на .md-файлы, размещённые в вашем публичном репозитории.

Скопируйте в свой .md-файл содержимое этого файла; исходники можно посмотреть [здесь](https://raw.githubusercontent.com/netology-code/sysadm-homeworks/devsys10/04-script-03-yaml/README.md). Заполните недостающие части документа решением задач (заменяйте `???`, ОСТАЛЬНОЕ В ШАБЛОНЕ НЕ ТРОГАЙТЕ чтобы не сломать форматирование текста, подсветку синтаксиса и прочее, иначе можно отправиться на доработку) и отправляйте на проверку. Вместо логов можно вставить скриншоты по желани.

# Домашнее задание к занятию "4.3. Языки разметки JSON и YAML"


## Обязательная задача 1
Мы выгрузили JSON, который получили через API запрос к нашему сервису:
```
    { "info" : "Sample JSON output from our service\t",
        "elements" :[
            { "name" : "first",
            "type" : "server",
            "ip" : 7175 
            }
            { "name" : "second",
            "type" : "proxy",
            "ip : 71.78.22.43
            }
        ]
    }
```
  Нужно найти и исправить все ошибки, которые допускает наш сервис
  
```
    { "info" : "Sample JSON output from our service\t",
        "elements" :[
            { "name" : "first",
            "type" : "server",
            "ip" : 7175 
            },
            { "name" : "second",
            "type" : "proxy",
            "ip" : "71.78.22.43"
            }
        ]
    }
```

## Обязательная задача 2
В прошлый рабочий день мы создавали скрипт, позволяющий опрашивать веб-сервисы и получать их IP. К уже реализованному функционалу нам нужно добавить возможность записи JSON и YAML файлов, описывающих наши сервисы. Формат записи JSON по одному сервису: `{ "имя сервиса" : "его IP"}`. Формат записи YAML по одному сервису: `- имя сервиса: его IP`. Если в момент исполнения скрипта меняется IP у сервиса - он должен так же поменяться в yml и json файле.

### Ваш скрипт:
```python
import socket
from time import sleep
import json
import yaml

counter = 1

objectlist = {'drive.google.com': '', 'mail.google.com': '', 'google.com': ''}


def get_objectlist(addr):
    for host in addr:
        ip = socket.gethostbyname(host)
        addr[host] = ip
    return addr

def makefiles(addr):
    with open('obj.json', 'w') as json:
        json.write(str(json.dumps(addr)))
    with open('obj.yaml', 'w') as yaml:
        yaml.write(yaml.dump(addr))
    return

while counter != 0:
    hostinfo = get_objectlist(objectlist)
    sleep(10)
    for host in hostinfo:
        ip = socket.gethostbyname(host)
        if ip != hostinfo[host]:
            print(' [ERROR] ' + str(host) + ' IP mismatch: address ' + hostinfo[host] + ' changed to ' + ip, sep='')
            hostinfo[host] = ip
            makefiles(hostinfo)
            counter = 0
        else:
            print(str(host) + ' ' + ip + ' Healthy ')
```

### Вывод скрипта при запуске при тестировании:
```
C:/Users/admin/AppData/Local/Microsoft/WindowsApps/python3.9.exe c:/Users/admin/Desktop/4.3.py
drive.google.com 64.233.165.194 Healthy 
mail.google.com 108.177.14.17 Healthy 
google.com 64.233.165.138 Healthy
drive.google.com 64.233.165.194 Healthy 
mail.google.com 108.177.14.17 Healthy 
google.com 64.233.165.138 Healthy
drive.google.com 64.233.165.194 Healthy
mail.google.com 108.177.14.17 Healthy
google.com 64.233.165.138 Healthy
drive.google.com 64.233.165.194 Healthy
mail.google.com 108.177.14.17 Healthy
google.com 64.233.165.138 Healthy
drive.google.com 64.233.165.194 Healthy
mail.google.com 108.177.14.17 Healthy
google.com 64.233.165.138 Healthy
drive.google.com 64.233.165.194 Healthy
mail.google.com 108.177.14.17 Healthy
google.com 64.233.165.138 Healthy
drive.google.com 64.233.165.194 Healthy
mail.google.com 108.177.14.17 Healthy
google.com 64.233.165.138 Healthy
drive.google.com 64.233.165.194 Healthy
mail.google.com 108.177.14.17 Healthy
google.com 64.233.165.138 Healthy
drive.google.com 64.233.165.194 Healthy
 [ERROR] mail.google.com IP mismatch: address 108.177.14.17 changed to 173.194.73.83
google.com 64.233.165.138 Healthy

```

### json-файл(ы), который(е) записал ваш скрипт:
```json
{"drive.google.com": "64.233.165.194", "mail.google.com": "108.177.14.17", "google.com": "64.233.165.138"}
```

### yml-файл(ы), который(е) записал ваш скрипт:
```yaml
drive.google.com: 64.233.165.194
google.com: 64.233.165.138
mail.google.com: 108.177.14.17
```

## Дополнительное задание (со звездочкой*) - необязательно к выполнению

Так как команды в нашей компании никак не могут прийти к единому мнению о том, какой формат разметки данных использовать: JSON или YAML, нам нужно реализовать парсер из одного формата в другой. Он должен уметь:
   * Принимать на вход имя файла
   * Проверять формат исходного файла. Если файл не json или yml - скрипт должен остановить свою работу
   * Распознавать какой формат данных в файле. Считается, что файлы *.json и *.yml могут быть перепутаны
   * Перекодировать данные из исходного формата во второй доступный (из JSON в YAML, из YAML в JSON)
   * При обнаружении ошибки в исходном файле - указать в стандартном выводе строку с ошибкой синтаксиса и её номер
   * Полученный файл должен иметь имя исходного файла, разница в наименовании обеспечивается разницей расширения файлов

### Ваш скрипт:
```python
???
```

### Пример работы скрипта:
???
