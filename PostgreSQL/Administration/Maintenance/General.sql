
--------------------------------------------------------------------------------------------------------------
-- https://www.abatic.es/tareas-de-mantenimiento-en-postgresql/
--------------------------------------------------------------------------------------------------------------

-- Es posible ejecutar el comando ANALYZE junto al comando VACUUM, de hecho es una buena práctica. De esta 
-- forma limpiamos cada una de las tablas de manera que aquellas filas muertas producidas por los UPDATES y 
-- DELETES, sean reutilizadas para nuevos INSERT y además, se actualiza la información obtenida de las 
-- tablas.

-- Para las tablas que no se realizan nuevas escrituras, es conveniente ejecutar el comando VACUUM FULL. 
-- De esta forma se recupera el espacio en el disco duro a nivel físico ocupado por aquellas filas muertas.

-- Lo siguiente a realizar es el comando REINDEX para reconstruir aquellos índices que están hinchados 
-- (bloated), es decir, contiene muchas páginas vacías con filas muertas. También hay que ejecutar este 
-- comando si actualizas a la versión 13 de PostgreSQL, pues se mejora los índices B-tree.

-- Consideraciones a tener en cuenta al realizar las tareas de mantenimiento en PostgreSQL
-- Antes que nada, es muy recomendable aumentar el valor del parámetro maintenace_work_men para reducir el 
-- tiempo de ejecución de tales tareas. Podemos hacer uso del comando SET para modificar el parámetro en la 
-- sesión. Recordad que una vez se terminen de ejecutar todos los comandos hay que volver a poner el valor 
-- predeterminado del parámetro.

-- El comando VACUUM ANALYZE es relativamente rápido y no bloquea las tablas que está limpiando. Por lo 
-- contrario el comando VACUUM FULL, es mucho más lento y además, bloquea la tabla que está reconstruyendo 
-- para recuperar el espacio ocupado.

-- Para recuperar el espacio ocupado por las tablas se requiere de espacio extra en el disco duro, pues 
-- realmente clona en un nuevo fichero aquellas páginas que están llenas y elimina el fichero antiguo que 
-- contiene las páginas vacías. En la versión 13 de PostgreSQL se puede mejorar el comando VACUUM 
-- ejecutándose en varios procesos de forma paralela.

-- Conclusión
-- Para realizar las tareas de mantenimiento, podemos crear un script dónde en la primera línea se aumente el 
-- valor del parámetro maintenace_work_men y en la última línea se le asigne el valor por defecto.
-- En las líneas intermedias, ejecutar el comando VACUUM ANALYZE por cada una de las tablas existentes en la 
-- base de datos y ejecutar el comando VACUUM FULL sólo en aquellas tablas dónde no se realizan INSERT. 
-- Por último ejecutar el comando REINDEX por cada tabla que contenga índices.

1. Cual es el valor por defecto de MAINTENACE_WORK_MEN

	Modificarlo y cuando terminamos ponerlo nuevamente en su valor por defecto

2. Ejecutar VACUUM ANALYZE

3. Ejecutar REINDEX

