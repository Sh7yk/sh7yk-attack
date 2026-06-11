#!/bin/bash
#Находим живые хосты
mapcidr -cidr scope.txt -silent | naabu -sn -silent -wn -verify | tee alive_hosts.txt
#Сканируем на открытые порты
nmap -p- -Pn --open -sV -iL alive_hosts.txt -oA Scan_nmap
#Формирование файла со списком открытых портов, через заптую(для httpx)
grep -oE '[0-9]+/open/tcp' Scan_nmap.gnmap | cut -d/ -f1 | sort -nu | paste -sd, > open_ports.txt
#Поиск всех возможных веб сервисов, создание скриншотов
httpx -l alive_hosts.txt -ss -system-chrome -fc 404 -fwc 0 -sid 3 -p `cat open_ports.txt` -silent | tee web_scope.txt; chmod -R a+rX output
#Фазинг директорий
dirsearch -l web_scope.txt --no-color --format=plain --auth-type=basic --auth="admin:admin" -r -w /usr/share/wordlists/seclists/Discovery/Web-Content/common.txt -o dirsearch_result -q -F --random-agent -x 404,500 --deep-recursive --crawl
#Очистка результатов dirsearch для katana 
awk '{print $3}' dirsearch_result > dirsearch_urls.txt
#Краулинг конечных точек
katana -silent -sc -fsu -kf all -jsl -jc -list dirsearch_urls.txt -o katana_result.txt
#Сбор скриншотов с конечных точек
mkdir katana_screenshots; cd katana_screenshots; httpx -silent -l ../katana_result.txt -ss -fc 404 -fwc 0 -sid 3 -sc -td -title -ws; chmod -R a+rX output;cd .. 
#Проверка nuclei
nuclei -l katana_result.txt -headless -sc -fr -je nuclei_result.json -pe nuclei_json.pdf
