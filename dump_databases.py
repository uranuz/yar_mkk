#!/usr/bin/python3
import json
import urllib.parse
import os

from http.client import HTTPSConnection
from urllib.parse import urlencode

headers = {'Authorization': '6824204b6459489d9429bc03ce60015a'}
resource_url = '/v1/disk/resources'
conn = HTTPSConnection('cloud-api.yandex.net')

def upload_file(source_file_name, dest_file_name, overwrite):
	api_url = '/v1/disk/resources/upload'

	params = { 
		'path': dest_file_name,
		'overwrite': 'true' if overwrite else 'false'
	}
	request_uri = api_url + '?' + urlencode(params)
	conn.request("GET", request_uri, headers=headers)

	response = conn.getresponse()
	content = response.read().decode('utf-8')

	source_file = open(source_file_name, 'rb')
	file_content = source_file.read()

	obj = json.loads( content )

	print(obj)

	upload_netloc = urllib.parse.urlsplit( obj['href'] ).netloc
	upload_href = obj['href']
	upload_conn = HTTPSConnection(upload_netloc)

	upload_conn.request("PUT", upload_href, body=file_content)

	upload_response = upload_conn.getresponse()

def get_nested_files_list(dir_name):
	api_url = '/v1/disk/resources'

	params = {
		'path': dir_name,
		'limit': 0,
		'sort': '-modified'
	}

	request_uri = api_url + '?' + urlencode(params)
	conn.request("GET", request_uri, headers=headers)

	response = conn.getresponse()
	content = response.read().decode('utf-8')
	obj = json.loads(content)

	embedded = obj["_embedded"]
	file_objects = embedded["items"]

	file_paths = [ o['path'] for o in file_objects ]
	return file_paths

def delete_file(file_path):
	api_url = '/v1/disk/resources'

	params = {
		'path': file_path,
		'permanently': False
	}

	request_uri = api_url + '?' + urlencode(params)
	conn.request("DELETE", request_uri, headers=headers)

	response = conn.getresponse()
	content = response.read()

def remove_extra_files(dir_name, num_of_files):
	file_paths = get_nested_files_list(dir_name)
	extra_file_paths = file_paths[num_of_files:]

	for curr_path in extra_file_paths:
		delete_file(curr_path)

import os.path

def remove_local_extra_files(dir_name, num_of_files):
	file_names = [ os.path.join(dir_name, name) for name in os.listdir(dir_name)  ]
	file_names = [ name for name in file_names if os.path.isfile(name) ]

	file_names.sort(key = lambda fname: os.path.getmtime(fname), reverse = True )

	extra_file_paths = file_names[num_of_files+1:]

	for curr_path in extra_file_paths:
		os.remove(curr_path)
		

import subprocess
pg_dump_path = 'pg_dump'

def make_pg_dump(dbname, file_name, host='127.0.0.1', username='postgres'):
	subprocess.call([pg_dump_path, '--host', host, '--user', username, '--clean', '--format', 't', '--file', file_name, dbname])

import datetime

local_dumps_dir = os.path.expanduser('~/test_dumps/')
remote_dumps_dir = '/yar_mkk_dumps/'

if __name__ == "__main__":
	#upload_file('/home/uranuz/popka.txt', '/copy_of_popka2.txt', True)
	dumps_per_base = 20

	db_names = [ 'baza_MKK', 'MKK_site_base' ]

	files_to_leave = dumps_per_base * len(db_names)

	current_datetime = datetime.datetime.now().strftime('%d.%m.%YT%H-%M-%S')

	dump_local_filenames = [ os.path.join(local_dumps_dir, db_name + '_' + current_datetime + '.tar') for db_name in db_names ]
	dump_remote_filenames = [ os.path.join(remote_dumps_dir, db_name + '_' + current_datetime + '.tar') for db_name in db_names ]

	for i, db_name in enumerate(db_names):
		make_pg_dump(db_name, dump_local_filenames[i])
		upload_file(dump_local_filenames[i], dump_remote_filenames[i], overwrite=True)

	# Удаляем старые дампы с сервера
	remove_extra_files(remote_dumps_dir, files_to_leave)
	# И с жесткого диска
	remove_local_extra_files(local_dumps_dir, files_to_leave)
	