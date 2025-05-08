
-- Ref
https://dev.to/shree_j/how-to-install-and-run-psql-using-docker-41j2

-- via psql
docker run --name postgresql-container -p 5432:5432 -e POSTGRES_PASSWORD=somePassword -d postgres

-- Verify a new container created and running at 0.0.0.0:5432 with the below command.
docker ps -a

-- Download the pgAdmin-4 browser version from docker-hub using the following command.

docker run --rm -p 5050:5050 thajeztah/pgadmin4

http://localhost:5050 
