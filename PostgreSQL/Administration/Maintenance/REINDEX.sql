
-- Comando REINDEX
-- Este comando es similar al anterior, con la diferencia que actúa sobre los índices. Reconstruye los 
-- índices eliminando aquellas páginas que no contienen filas. De esta forma se disminuye el tamaño.

-- Any of these can be forced by adding the keyword FORCE after the command

-- Recreate a single index, myindex:

    REINDEX INDEX myindex

-- Recreate all indices in a table, mytable:
    REINDEX TABLE mytable

-- Recreate all indices in schema public:
    REINDEX SCHEMA public

-- Recreate all indices in database postgres:
    REINDEX DATABASE postgres

-- Recreate all indices on system catalogs in database postgres:
    REINDEX SYSTEM postgres
