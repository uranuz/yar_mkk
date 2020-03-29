#!/bin/bash

# Обновляем систему
sudo apt -y update
sudo apt -y upgrade

# Устанавливаем программы работы с репозиториями
sudo apt -y install git mercurial

# Создаем каталог исходников
mkdir -p ~/sources
cd ~/sources

# Выкачиваем все наши репозитории
hg clone https://bitbucket.org/uranuz/yar_mkk
hg clone https://bitbucket.org/uranuz/webtank
git clone https://github.com/uranuz/trifle.git
git clone https://github.com/uranuz/ivy.git
git clone https://github.com/uranuz/fir.git

# Переводим все репозитории на нужную ветку
# Это репозитории Mercurial (hg)
cd ~/sources/yar_mkk
hg checkout default
hg pull -u

cd ~/sources/webtank
hg checkout default
hg pull -u

# Это репозитории git
cd ~/sources/trifle
git checkout master
git pull

cd ~/sources/ivy
git checkout master
git pull

cd ~/sources/fir
git checkout master
git pull

# Создаем папку для скачивания пакетов
mkdir -p ~/packages
cd ~/packages

# Скачиваем компилятор языка D
wget http://downloads.dlang.org/releases/2.x/2.091.0/dmd_2.091.0-0_amd64.deb
sudo dpkg -i -y dmd_2.091.0-0_amd64.deb
# Чиним зависимости после установки пакета
sudo apt -fy install

# Запускаем разворот
# Заходим в репозиторий сайта
cd ~/sources/yar_mkk

# Установка системных зависимостей
dub run :deploy_sys_req

# Разворот сайта
dub run :deploy_site -- --user=yar_mkk --site=localhost

# Конвертация базы данных
dub run :deploy_db
