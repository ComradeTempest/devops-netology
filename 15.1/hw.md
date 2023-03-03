## 1. Организация сети на примере Яндекс-облака.

Сделали VPC test15, добавили сабнет (вообще, конечно, он добавился сам)

![изображение](https://user-images.githubusercontent.com/98019531/222724826-5029c861-cc6e-4bc1-9ab9-681769199eb4.png)

Делаем NAT и машинку для чека

![изображение](https://user-images.githubusercontent.com/98019531/222734483-2d87e1ce-53eb-4591-a1e3-1f07d68bc91c.png)

Чекаем доступ и выход в инет

![изображение](https://user-images.githubusercontent.com/98019531/222729261-ae924030-539c-44ec-a3bf-4e27d1eaf5df.png)

Докидываем подсеть private

![изображение](https://user-images.githubusercontent.com/98019531/222728261-0e786d7c-6b45-4616-8d25-cfeaff46bbc5.png)

Делаем табличку

![изображение](https://user-images.githubusercontent.com/98019531/222733901-cf85bec9-a175-41d8-b1a0-81d3b854366d.png)

Привязываем подсеть к табличке

![изображение](https://user-images.githubusercontent.com/98019531/222732369-38f3e76e-a952-4bff-a60f-7c03500cfaef.png)

Делаем изолированную вм

![изображение](https://user-images.githubusercontent.com/98019531/222734680-54a1d7b0-e2be-46d1-85dc-31d298593539.png)

Подхватываем коннект к ней с тестовой вм и проверяем доступы в интернет

![изображение](https://user-images.githubusercontent.com/98019531/222734272-de2c3bf7-8825-4329-b4b4-d7c904e3cf76.png)

Всё работает, мы молодцы.

