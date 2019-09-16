dub build :main_service
dub run :dispatcher -- --workerPath=./bin/mkk_main_service --port=8083
