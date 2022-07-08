1. Найдите, где перечислены все доступные resource и data_source, приложите ссылку на эти строки в коде на гитхабе.

Ресурсы у нас на данный момент перечислены со строчки 918

https://github.com/hashicorp/terraform-provider-aws/blob/main/internal/provider/provider.go#L918

А датасорсы с 426

https://github.com/hashicorp/terraform-provider-aws/blob/main/internal/provider/provider.go#L426

2. Для создания очереди сообщений SQS используется ресурс aws_sqs_queue у которого есть параметр name.

  С каким другим параметром конфликтует name? Приложите строчку кода, в которой это указано.
    
    Конфликт идёт с параметром name_prefix, 87 строчка кода.
    
   https://github.com/hashicorp/terraform-provider-aws/blob/main/internal/service/sqs/queue.go#L87
    
  Какая максимальная длина имени?
    
    Ответ ждёт нас с 424 строчки кода. 
    
   https://github.com/hashicorp/terraform-provider-aws/blob/main/internal/service/sqs/queue.go#L424
    
    Рассмотрим поподробнее:
   ```
    		if fifoQueue {
			re = regexp.MustCompile(`^[a-zA-Z0-9_-]{1,75}\.fifo$`)
		} else {
			re = regexp.MustCompile(`^[a-zA-Z0-9_-]{1,80}$`)
		}
   ```
    В случае с FIFO не может превышать 75 символов, определённых в параметрах, мандаторно наличие расширения .fifo. 
    В иных случаях максимальная длина 80 символов, также определённых в параметрах.
    
  Какому регулярному выражению должно подчиняться имя?
  
    В случае с fifo это (`^[a-zA-Z0-9_-]{1,75}\.fifo$`) — латинский алфавит, цифры, дефис и подчёркивание. И расширение .fifo как требование.
    В прочих случаях (`^[a-zA-Z0-9_-]{1,80}$`) — то же самое, но без мандаторного расширения.
    
