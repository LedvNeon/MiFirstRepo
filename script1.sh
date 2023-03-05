#!/bin/bash
# cut -d' ' -f1 — разбиваем строку на подстроки разделителем "пробел". Разделитель указывается флагом -d. 
#Флагом -f указываем по# рядковый номер поля, которое будет отображаться в выводе. 
#В данном случае «1» - первое поле, это и есть ip-адресс.
# Если в  логе IP идет вторым, то -f2
# sort - сортировка строк по порядку -r (обратный порядок)
# uniq— выведет только уникальные строки
# -c - вывод кол-ва
# less /var/log/nginx/access.log | cut -d' ' -f1 | sort | uniq -c
# awk '{print$1}' - вывод первого столбца
# head -1 - после awk выведет 1 строку (т.е. результат 1 строка 1 столбец)

# Проверим наличие файла /home/vagrant/scripts/result/max.txt и переименуем его (а файл за прошлый час удалим),      
# что бы в письмо с результатом приложить 2 файлы - текущий и с прошлого часа для сравнения
# АНАЛОГИЧНО БУДЕТ ДЛЯ ВСЕХ ФАЙЛОВ

max_last_hour=/home/vagrant/scripts/result/max_last_hour.txt
if [[ -f "$max_last_hour" ]]; then
       rm /home/vagrant/scripts/result/max_last_hour.txt
fi


max=/home/vagrant/scripts/result/max.txt
if [[ -f "$max" ]]; then
        mv /home/vagrant/scripts/result/max.txt  /home/vagrant/scripts/result/max_last_hour.txt
fi

echo "Выведем максимальное число запросов к nginx в файл /home/vagrant/scripts/result/max.txt"
cat /var/log/nginx/access.log |cut -d' ' -f1 | sort -r | uniq -c | awk '{print$1}' | head -1 > /home/vagrant/scripts/result/max.txt

# Добавим временной интервал
cat /var/log/nginx/access.log | awk '{print $4}' | head -n 1 &&  date | awk '{print $2,$3,$4,$6}' >> /home/vagrant/scripts/result/max.txt

# Проверим наличие файла /home/vagrant/scripts/result/urls.txt и переименуем его

urls_last_hour=/home/vagrant/scripts/result/urls_last_hour.txt
if [[ -f "$urls_last_hour" ]]; then
       rm /home/vagrant/scripts/result/urls_last_hour.txt
fi

urls=/home/vagrant/scripts/result/urls.txt
if [[ -f "$urls" ]]; then
       mv /home/vagrant/scripts/result/urls.txt /home/vagrant/scripts/result/urls_last_hour.txt
fi

echo "Выведем максимальное число запросов к nginx вместе со списком url, которые запрашивались, IP источника и число 
запросов"
cat /var/log/nginx/access.log  | sort -r | uniq -c | awk '{print $2,$8}' | uniq -c | awk '{print $1,$2,$3}' | head -1> /home/vagrant/scripts/result/urls.txt

# Добавим временной интервал
cat /var/log/nginx/access.log | awk '{print $4}' | head -n 1 &&  date | awk '{print $2,$3,$4,$6}' >> /home/vagrant/scripts/result/urls.txt



# Проверим наличие файла с ошибками и, если он есть, переименуем
errors_last_hour=/home/vagrant/scripts/result/errors_last_hour.txt
if [[ -f "$errors_last_hour" ]]; then
      rm /home/vagrant/scripts/result/errors_last_hour.txt
fi

errors=/home/vagrant/scripts/result/errors.txt
if [[ -f "$errors" ]]; then
       mv /home/vagrant/scripts/result/errors.txt  /home/vagrant/scripts/result/errors_last_hour.txt
fi

echo "Посмотрим ошибки nginx и выведем результат в /home/vagrant/scripts/result/errors.txt"
cat /var/log/nginx/error.log > /home/vagrant/scripts/result/errors.txt

# Добавим временной интервал
cat /var/log/nginx/access.log | awk '{print $4}' | head -n 1 &&  date | awk '{print $2,$3,$4,$6}' >> /home/vagrant/scripts/result/errors.txt



# Проверим наличие файла с кодами ответа и, если он есть, переименуем
answers_last_hour=/home/vagrant/scripts/result/answers.txt
if [[ -f "$answers_last_hour" ]]; then
      rm /home/vagrant/scripts/result/answers_last_hour.txt
fi

answers=/home/vagrant/scripts/result/answers.txt
if [[ -f "$answers" ]]; then
       mv /home/vagrant/scripts/result/answers.txt /home/vagrant/scripts/result/answers_last_hour.txt
fi

echo "Выведем все коды ответа nginx с указанием их кол-ва и выведем результат в /home/vagrant/scripts/result/answers.txt"
cat /var/log/nginx/access.log | sort -r | awk '{print $1,$9}' | uniq -c > /home/vagrant/scripts/result/answers.txt   

# Добавим временной интервал
cat /var/log/nginx/access.log | awk '{print $4}' | head -n 1 &&  date | awk '{print $2,$3,$4,$6}' >> /home/vagrant/scripts/result/unswers.txt


# Отправим файлы с информацией на почту dima@domain.local

echo "nginx-info" | mail -s "В файлах во вложении информация по nginx" dima@domain.local  -a /home/vagrant/scripts/result/max.txt -a /home/vagrant/scripts/result/answers.txt -a /home/vagrant/scripts/result/errors.txt -a /home/vagrant/scripts/result/urls.txt -a /home/vagrant/scripts/result/max_last_hour.txt -a /home/vagrant/scripts/result/answers_last_hour.txt -a /home/vagrant/scripts/result/errors_last_hour.txt -a /home/vagrant/scripts/result/urls_last_hour.txt 