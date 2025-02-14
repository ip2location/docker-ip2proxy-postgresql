docker-ip2proxy-postgresql
=============================

This is a pre-configured, ready-to-run PostgreSQL server with IP2Proxy Proxy IP database. It simplifies the development team to install and set up the proxy IP database in PostgreSQL server. The setup script supports the [commercial database packages](https://www.ip2location.com/database/ip2proxy) and [free LITE package](https://lite.ip2location.com). Please register for a download account before running this image.

### Usage

1. Run this image as daemon with your username, password, and download code registered from [IP2Location](https://www.ip2location.com).

       docker run --name ip2proxy -d -e TOKEN={DOWNLOAD_TOKEN} -e CODE={DOWNLOAD_CODE} -e IP_TYPE=IPV4 -e POSTGRESQL_PASSWORD={YOUR_POSTGRESQL_PASSWORD} ip2proxy/postgresql

    **ENV VARIABLE**

   TOKEN - Download token form IP2Location account.

   CODE - Database code. Codes available as below:

    **Free Database**

     * PX1-LITE, PX2-LITE, PX3-LITE, PX4-LITE, PX5-LITE, PX6-LITE, PX7-LITE, PX8-LITE, PX9-LITE, PX10-LITE, PX11-LITE, PX12-LITE

   **Commercial Database**

   * PX1, PX2, PX3, PX4, PX5, PX6, PX7, PX8, PX9, PX10, PX11, PX12
     

   IP_TYPE - (Optional) Download IPv4 or IPv6 database. Script will download IPv4 database by default.

   * IPV4 - Download IPv4 database only.
   * IPV6 - Download IPv6 database only.
     

   POSTGRESQL_PASSWORD - (Optional) Password for PostgreSQL admin. A random password will be generated by default.
   
2. The installation may take minutes to hour depending on your internet speed and hardware. You may check the installation status by viewing the container logs. Run the below command to check the container log:

        docker logs YOUR_CONTAINER_ID

    You should see the line of `> Setup completed` if you have successfully complete the installation.

### Connect to it from an application

    docker run --link ip2proxy:ip2proxy-db -t -i application_using_the_ip2proxy_data

### Make the query

    psql -h ip2proxy-db --username=postgres -d ip2proxy_database

Enter YOUR_POSTGRESQL_PASSWORD password when prompted.

Start lookup by following query:

    SELECT * FROM ip2proxy_database WHERE ip2int('8.8.8.8') BETWEEN ip_from AND ip_to LIMIT 1;

Notes: For IPv6 lookup, please convert the IPv6 into BigInt programmatically. There is no build-in function available with PostgreSQL.



### Sample Code Reference

[https://www.ip2location.com/tutorials](https://www.ip2location.com/tutorials)