docker run -d -e POSTGRES_DB=cis -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=postgres -P --name db izotoff/postgres

docker run -it --name eee tcs /tmp/restore.sh
docker run -it -P --volumes-from eee tcs

