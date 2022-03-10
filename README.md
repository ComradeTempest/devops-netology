4.1. Командная оболочка Bash: Практические навыки

1. c=a+b, так как мы задали этому значению стринг a+b
   d=1+2, так как тут у нас стринг из значений переменных a и b
   e=3, так как тут у нас арифметическое выражение на основе переменных
  
2. 
  #!/usr/bin/env bash
  while ((1==1))
  do
          curl http://localhost:9100
          if (($? != 0))
          then
          date >> curl.log
          else
          break
          fi
  done
  
3.
#!/usr/bin/env bash
addr=(192.168.0.1 173.194.222.113 87.250.250.242)
for i in "${addr[@]}"
do
x=0
while ((x!=5))
do
           curl --head http://$i:80
           if (($? !=0))
           then
           ((x+=1)) || true
           echo "'$i' X" >> addr_check.log
           else
           ((x+=1)) || true
           echo "'$i' V" >> addr_check.log
           fi
done
done

4.
#!/usr/bin/env bash
addr=(192.168.0.1 173.194.222.113 87.250.250.242)
while ((1==1))
do
for i in "${addr[@]}"
do
          curl --head http://$i:80
          if (($? !=0))
          then
          echo  "$i" >> error
          break 2
          fi
done
done
  
