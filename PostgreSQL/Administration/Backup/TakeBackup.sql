
Archivo crear_backup_postgresql.txt
	No ejecuta nada. Es un archivo de notas

script_backup_DB_postgresql
	Este si hace el backup
	
	Linea 1
	Arma un archivo con nombre concursar_dump_LA FECHA.sql Este archivo va ser de la db concursar y lo crea con el usuario postgres. 
	Y va a correr a las 5:30
	30 5 * * * docker exec -t postgres-test_postgres_1 pg_dump -U postgres concursar > /home/operador/postgres_dump/concursar_dump_$(date +\%Y-\%m-\%d__\%H_\%M_\%S).sql

	Linea 2
	Arma un archivo concursar_dump_sin_owner_ni_roles_LA FECHA.sql El user es postgres, lo arma sin roles (-O) y sin privilegios (-x)
	33 5 * * * docker exec -t postgres-test_postgres_1 pg_dump -U postgres -O -x concursar > /home/operador/postgres_dump/concursar_dump_sin_owner_ni_roles$(date +\%Y-\%m-\%d__\%H_\%M_\%S).sql

	Linea 3
	Arma un archivo concursar_dump_borra_base_y_crea_base_con_datos.sql El user es postgres, lo arma incluyendo los comandos DROP (-c) and CREATE DATABASE (-C)
	40 5 * * * docker exec -t postgres-test_postgres_1 pg_dump -U postgres -c -C concursar > /home/operador/postgres_dump/concursar_dump_borra_base_y_crea_base_con_datos$(date +\%Y-\%m-\%d__\%H_\%M_\%S).sql
	
	Linea 4
	Arma un archivo para todas las DBs .sql El user es postgres, lo arma incluyendo el comando DROP
	25 5 * * * docker exec -t postgres-test_postgres_1 pg_dumpall -U postgres -c > /home/operador/postgres_dump/dump_all_completa_borra_todo_y_crea_desde_cero_$(date +\%Y-\%m-\%d__\%H_\%M_\%S).sql

backup_crontab
	Tiene los comandos anteriores
	
script eliminar archivos dump postgres
	Este elimina todos los archivos que fueron modificados hace mas de 15 dias


I could't reach that server doing a PING from my VM


