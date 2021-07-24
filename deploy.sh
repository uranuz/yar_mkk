#!/bin/bash

# Обновляем систему
sudo apt -y update
sudo apt -y upgrade

# Устанавливаем программы работы с репозиториями
sudo apt -y install git

# Создаем каталог исходников
mkdir -p ~/projects/yar_mkk
cd ~/projects/yar_mkk

# Выкачиваем все наши репозитории
git clone https://github.com/uranuz/yar_mkk.git
git clone https://github.com/uranuz/webtank.git
git clone https://github.com/uranuz/trifle.git
git clone https://github.com/uranuz/ivy.git
git clone https://github.com/uranuz/fir.git

# Переводим все репозитории на нужную ветку
cd ~/projects/yar_mkk/yar_mkk
git checkout master
git pull

cd ~/projects/yar_mkk/webtank
git checkout master
git pull

cd ~/projects/yar_mkk/trifle
git checkout master
git pull

cd ~/projects/yar_mkk/ivy
git checkout master
git pull

cd ~/projects/yar_mkk/fir
git checkout master
git pull

# Создаем папку для скачивания пакетов
mkdir -p ~/packages
cd ~/packages

# Скачиваем компилятор языка D
wget http://downloads.dlang.org/releases/2.x/2.091.0/dmd_2.091.0-0_amd64.deb
sudo dpkg -i dmd_2.091.0-0_amd64.deb
# Чиним зависимости после установки пакета
sudo apt -fy install

# Запускаем разворот
# Заходим в репозиторий сайта
cd ~/projects/yar_mkk/yar_mkk

# Установка системных зависимостей
dub run :deploy_sys_req

# Разворот сайта
dub run :deploy_site -- --user=yar_mkk --site=localhost

# Конвертация базы данных
dub run :deploy_db
