Поставил Go 1.18.3, но решил всё хозяйство делать в Go Playground, ибо легковесно и корректирует моё нелепое форматирование.

3. Для первой задачи пункта три был взят и скорректирован под условия код из примера, уж больно он лаконичен.
```
package main

import "fmt"

func main() {
	fmt.Print("Enter length in meters to convert it in feet: ")
	var input float64
	fmt.Scanf("%f", &input)

	output := input / 0.3048

	fmt.Println(output)
}
```
Во втором решение будет через цикл перебора, это подходит для текущих условий, но для по-настоящему больших рядов лучше, на мой взгляд, getmin.

```
package main

import "fmt"

func main() {
	x := []int{48, 96, 86, 68, 57, 82, 63, 70, 37, 34, 83, 27, 19, 97, 9, 17}
	var min = x[0]
	for i := range x {
		if x[i] < min {
			min = x[i]
		}
	}
	fmt.Println("The smallest number in the row: ", min)
}
```

В третьей задаче было искушение обойтись аналогичным циклом перебора, но было решено сделать красивый читабельный вывод. Для этого дописали функцию, которая вместо диковатого вывода столбиком соберёт и выведет массив с результатами.
```
package main

import "fmt"

func count() (list []int) {
	for i := 1; i <= 100; i++ {
		if i%3 == 0 {
			list = append(list, i)
		}
	}
	return
}
func main() {
	out := count()
	fmt.Printf("Completely divisible by 3: %v\n", out)
}
```
