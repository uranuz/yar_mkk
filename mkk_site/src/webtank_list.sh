#!/bin/bash
#Определяем входные параметры скрипта
root_dir="../../" #Путь к корню всей группы проектов относительно текущей
import_dir_rel='webtank/src/' #Путь к проекту отностительно корня
in_list_file_rel=$import_dir_rel'sources.list' #Путь к входному файлу-списку относительно корня
out_list_file_rel='webtank.list' #Путь к выходному файлу-списку относительно текущей директории

#Создаём список файлов для сборки библиотеки
import_dir=$root_dir$import_dir_rel
in_list_file=$root_dir$in_list_file_rel #
out_list_file='webtank.list'
echo -n>$out_list_file #Стираем файл
while IFS="\n" read LINE #Построчное чтение из файла in_list_file
do
	echo $import_dir${LINE:2}>>$out_list_file;
done < "$in_list_file"
