1.
В чём отличие режимов работы сервисов в Docker Swarm кластере: replication и global?
  Replication размещает определённое администратором количество реплик на воркерах, global раскидывает реплики на всех нодах, включая управляющие.

Какой алгоритм выбора лидера используется в Docker Swarm кластере?
  Используется алгоритм Raft Consensus, вот тут есть отличненькая пояснительная анимация, что это такое: http://thesecretlivesofdata.com/raft/

Что такое Overlay Network?
  Оверлейная сеть используется для связи контейнеров на всех хостах, составляющих Swarm.
  
  
  2.
  ![изображение](https://user-images.githubusercontent.com/98019531/166688343-11593d1f-72ed-43a7-b6c0-67e79a60a684.png)
  
  3. 
  ![изображение](https://user-images.githubusercontent.com/98019531/166688494-fe81335a-0aed-42fe-bc3a-310263c796e1.png)

  4. Это включит автолок сварма — шифрование ключей расшифровки логов рафта (тот самый алгоритм, про который мы упоминали в вопросе 2).
  Всё это хозяйство нужно для повышения стойкости кластера в плане кражи ключей расшифровки логов, которые передаются на управляющие ноды при рестарте.