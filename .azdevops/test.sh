
docker network create tripinsights
docker run -d \
--network tripinsights \
-e 'ACCEPT_EULA=Y' \
-e 'MSSQL_SA_PASSWORD=localtestpw123@' \
--name 'sqltestdb' \
-p 1433:1433 \
mcr.microsoft.com/mssql/server:2017-latest

sleep 20
docker ps
docker logs sqltestdb

docker exec sqltestdb /opt/mssql-tools/bin/sqlcmd \
-S localhost -U SA -P 'localtestpw123@' \
-Q "CREATE DATABASE mydrivingDB"

docker run -d \
--network tripinsights \
--name dataload \
-e "SQLFQDN=sqltestdb" \
-e "SQLUSER=sa" \
-e "SQLPASS=localtestpw123@" \
-e "SQLDB=mydrivingDB" \
vyta/data-load:v1

# give some time for data to load
sleep 20
docker logs dataload

- script: | 
docker run -d \
--network tripinsights \
-p 8080:80 \
--name poi \
-e "SQL_PASSWORD=localtestpw123@" \
-e "SQL_SERVER=sqltestdb" \
-e "SQL_USER=sa" \
-e "ASPNETCORE_ENVIRONMENT=Development" \
tripinsights/poi:1.0

docker run -d \
--network tripinsights \
-p 8081:80 \
--name trips \
-e "SQL_PASSWORD=localtestpw123@" \
-e "SQL_SERVER=sqltestdb" \
-e "SQL_USER=sa" \
-e "DOCS_URI=http://temp" \
tripinsights/trips:1.0

docker run -d \
--network tripinsights \
-p 8082:80 \
--name user-java \
-e "SQL_PASSWORD=localtestpw123@" \
-e "SQL_SERVER=sqltestdb" \
-e "SQL_USER=sa" \
tripinsights/user-java:1.0 

docker run -d \
--network tripinsights \
-p 8083:80 \
--name userprofile \
-e "SQL_PASSWORD=localtestpw123@" \
-e "SQL_SERVER=sqltestdb" \
-e "SQL_USER=sa" \
tripinsights/userprofile:1.0

docker ps

curl -X GET 'http://localhost:8080/api/poi/healthcheck'
# printf "call trips\n"
# curl -X GET 'http://localhost:8081/api/trips'
# printf "call user profile\n"
# curl -X GET 'http://localhost:8083/api/user'
# printf "update user profile\n"
# curl -X GET 'http://localhost:8082/api/user-java/healthcheck'
# sleep 20 # give enough time for profile java app to be up and running
# curl -X PATCH --header 'Content-Type: application/json' --header 'Accept: application/json' -d '{ "fuelConsumption":20, "hardStops":200 }' 'http://localhost:8082/api/user-java/aa1d876a-3e37-4a7a-8c9b-769ee6217ec1'  