#!/usr/bin/python3
import json
import urllib.parse
import os

from http.client import HTTPSConnection
from urllib.parse import urlencode

headers = {'Authorization': 'AQAAAAAA2w5-AACypr_jUDYpFkZgrU4UYOeANSA'}

class ConnWrapper:
	def __init__(self, conn):
		self._conn = conn

	def __enter__(self):
		return self._conn

	def __exit__(self, exc_type, exc_val, exc_tb):
		self._conn.close()
		self._conn = None


def get_api_conn(netloc='cloud-api.yandex.net'):
	"""Устанавливает подключение к API Яндекс.Диска"""
	return ConnWrapper(HTTPSConnection(netloc))


def assure_http_code(resp, msg='Ошибка HTTP-запроса', codes=(200,)):
	"""Проверить ответ сервера на ошибку"""
	if resp.status != codes and resp.status not in codes:
		raise Exception(
			'{}. \nHTTP-код: {}. Причина: {}. \nОтвет: {}'.format(
				msg, resp.status, resp.status, resp.read().decode('utf-8')))


FOLDER_CREATED = 201 # Папка была создана
FOLDER_EXISTS = 409 # Папка ужо существует
def create_remote_path(dest_path):
	"""Создает путь на Яндекс.Диске, если нет его"""
	path_spl = dest_path.split(os.path.sep)
	# 1-ый элемент - пустая строка из за корневой папки "/"
	for i in range(2, len(path_spl)+1):
		parent = os.path.sep.join(path_spl[:i])
		print(parent)
		request_uri = '/v1/disk/resources?' + urlencode({
			'path': parent
		})
		with get_api_conn() as conn:
			conn.request("PUT", request_uri, headers=headers)
			assure_http_code(conn.getresponse(), 'Не удалось создать папку на Яндекс.Диске', codes=(FOLDER_CREATED, FOLDER_EXISTS))


def get_upload_link(dest_file_name, overwrite):
	"""Получить ссылку для загрузки файла на Яндекс.Диск"""
	dest_path = os.path.dirname(dest_file_name)
	create_remote_path(dest_path)

	request_uri = '/v1/disk/resources/upload?' + urlencode({
		'path': dest_file_name,
		'overwrite': 'true' if overwrite else 'false'
	})
	resp_str = None
	with get_api_conn() as conn:
		conn.request("GET", request_uri, headers=headers)
		resp = conn.getresponse()
		assure_http_code(resp, 'Не удалось получить ссылку для загрузки файла на Яндекс.Диск')
		resp_str = resp.read().decode('utf-8')

	if not resp_str:
		raise Exception('Ожидался объект со ссылкой для загрузки файла, но получена дырка от бублика!')

	resp_data = json.loads(resp_str)
	print(resp_data)
	href_spl = urllib.parse.urlsplit( resp_data['href'] )
	if href_spl.scheme != 'https':
		raise Exception('Ожидалась схема "https" для зогруски файло на севрер!')
	netloc = href_spl.netloc
	relref = resp_data['href'].split(netloc, 1)[1] # Отделяем останки ссылки

	return netloc, relref


FILE_UPLOADED = 201
FILE_ACCEPTED = 202
def upload_file(source_file_name, dest_file_name, overwrite):
	"""Загрузить файл на Яндекс.Диск"""
	upload_netloc, upload_href = get_upload_link(dest_file_name, overwrite)

	file_content = None
	with open(source_file_name, 'rb') as source_file:
		file_content = source_file.read()

	with get_api_conn(upload_netloc) as conn:
		conn.request("PUT", upload_href, body=file_content)
		assure_http_code(conn.getresponse(), 'Не удалось загрузить файл на Яндекс.Диск', codes=(FILE_UPLOADED, FILE_ACCEPTED))

FILE_ENTRIES_LIMIT = 200
def get_nested_files_list(dir_name):
	"""Получает список файлов в папке, сортированный по убываннию даты изменения"""
	request_uri = '/v1/disk/resources?' + urlencode({
		'path': dir_name,
		'limit': FILE_ENTRIES_LIMIT,
		'sort': '-modified'
	})
	resp_str = None
	with get_api_conn() as conn:
		conn.request("GET", request_uri, headers=headers)

		resp = conn.getresponse()
		assure_http_code(resp, 'Не удалось получить список файлов в папке с Яндекс.Диска')
		resp_str = resp.read().decode('utf-8')

	resp_data = json.loads(resp_str)

	embedded = resp_data["_embedded"]
	file_objects = embedded["items"]

	file_paths = [ o['path'] for o in file_objects ]
	print(file_paths)
	return file_paths


def delete_file(file_path):
	"""Удалить файл с Яндекс.Диска"""
	request_uri = '/v1/disk/resources?' + urlencode({
		'path': file_path,
		'permanently': False
	})
	with get_api_conn() as conn:
		conn.request("DELETE", request_uri, headers=headers)
		assure_http_code(conn.getresponse(), 'Не вышло удалить файлы с Яндекс.Диска')


def remove_remote_extra_files(dir_name, num_of_files):
	"""Удалить лишние файлы в папке с Яндекс.Диска и оставить только num_of_files самых свежих"""
	file_paths = get_nested_files_list(dir_name)
	extra_file_paths = file_paths[num_of_files:]

	for curr_path in extra_file_paths:
		delete_file(curr_path)

import os.path

def remove_local_extra_files(dir_name, num_of_files):
	"""Удалить лишние файлы в локальной папке и оставить только num_of_files самых свежих"""
	if not os.path.exists(dir_name):
		return
	file_names = [ os.path.join(dir_name, name) for name in os.listdir(dir_name)  ]
	file_names = [ name for name in file_names if os.path.isfile(name) ]

	file_names.sort(key = lambda fname: os.path.getmtime(fname), reverse = True )

	extra_file_paths = file_names[num_of_files:]

	for curr_path in extra_file_paths:
		os.remove(curr_path)


import subprocess
pg_dump_path = 'pg_dump'

def make_pg_dump(dbname, file_name, host='127.0.0.1', username='postgres'):
	"""Сотворить дамп базы данных"""
	subprocess.call([pg_dump_path, '--host', host, '--user', username, '--clean', '--format', 't', '--file', file_name, dbname])

import datetime

base_local_dumps_dir = os.path.expanduser('~/test_dumps/') # Куда *ложить* дампы локально
base_remote_dumps_dir = '/yar_mkk_dumps/' # Куды пихать фаелы в Тындекс.Дискете

if __name__ == "__main__":
	dumps_per_base = 20
	current_datetime = datetime.datetime.now(datetime.timezone.utc)
	# Хотим чтобы оставались дампы раз в 3 месяца
	quarter = current_datetime.month // 4 + 1
	path_suffix = '{}/q{}'.format(current_datetime.year, quarter)
	local_dumps_dir = os.path.join(base_local_dumps_dir, path_suffix)
	remote_dumps_dir = os.path.join(base_remote_dumps_dir, path_suffix)

	os.makedirs(local_dumps_dir, exist_ok=True) # Создай папку, если нет

	db_names = ['baza_MKK', 'MKK_site_base', 'mkk_history']

	files_to_leave = dumps_per_base * len(db_names)

	current_datetime_str = current_datetime.strftime('%Y.%m.%dT%H-%M-%S%z')

	for db_name in db_names:
		dump_filename = '{}_{}.backup'.format(current_datetime_str, db_name)
		dump_local_filename = os.path.join(local_dumps_dir, dump_filename)
		dump_remote_filename = os.path.join(remote_dumps_dir, dump_filename)

		make_pg_dump(db_name, dump_local_filename)
		upload_file(dump_local_filename, dump_remote_filename, overwrite=True)

	# Удаляем старые дампы с Яндекс.Дискеты
	remove_remote_extra_files(remote_dumps_dir, files_to_leave)
	# И с локального жесткого диска
	remove_local_extra_files(local_dumps_dir, files_to_leave)
