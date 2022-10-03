# Copyright 2022 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

FROM adobecoldfusion/coldfusion:latest

# Install Maven and git, for retrieving third party content
RUN apt-get update -y && apt-get install maven git -y 

# Grab the mysql driver jar
RUN mvn dependency:get -Dartifact=mysql:mysql-connector-java:8.0.30
RUN cp /root/.m2/repository/mysql/mysql-connector-java/8.0.30/mysql-connector-java-8.0.30.jar /opt/coldfusion/cfusion/lib/ && rm -rf /root/.m2

# Grab Secret Manager jar
RUN mvn dependency:get -Dartifact=com.google.cloud:google-cloud-secretmanager:2.3.7
RUN mkdir -p /app/jarfiles && cp -r /root/.m2 /app/jarfiles && rm -rf /root/.m2

# Grab javaloader
RUN git clone https://github.com/markmandel/JavaLoader /tmp/jl
RUN cp -r /tmp/jl/javaloader /opt/coldfusion/cfusion/wwwroot

# Run CF config settings
RUN /opt/coldfusion/config/cfsetup/cfsetup.sh alias instance /opt/coldfusion/cfusion/
RUN /opt/coldfusion/config/cfsetup/cfsetup.sh add mapping virtual=/javaloader physical=/opt/coldfusion/cfusion/wwwroot/javaloader/ instance
RUN /opt/coldfusion/config/cfsetup/cfsetup.sh set debug enabled=true instance
RUN /opt/coldfusion/config/cfsetup/cfsetup.sh set debug robust_enabled=true instance
RUN /opt/coldfusion/config/cfsetup/cfsetup.sh set debug iplist=172.17.0.1 instance
RUN /opt/coldfusion/config/cfsetup/cfsetup.sh set caching redisCacheStoragePort=6379 instance
RUN /opt/coldfusion/config/cfsetup/cfsetup.sh set caching redisCacheStorageHost=host.docker.internal instance
RUN /opt/coldfusion/config/cfsetup/cfsetup.sh set runtime sessionStorage=REDIS instance
RUN /opt/coldfusion/config/cfsetup/cfsetup.sh set runtime sessionStorageHost=host.docker.internal instance
RUN /opt/coldfusion/config/cfsetup/cfsetup.sh set runtime sessionStoragePort=6379 instance
RUN /opt/coldfusion/config/cfsetup/cfsetup.sh set runtime reuseRedisCachingForSessionStorage=true instance
RUN /opt/coldfusion/config/cfsetup/cfsetup.sh set runtime sslSessionStorage=false instance
RUN /opt/coldfusion/cfusion/bin/cfpm.sh install orm,debugger,mysql,redissessionstorage,zip
RUN /opt/coldfusion/cfusion/bin/coldfusion restart

# Got a weird error that the neo-runtime.bak could be written, this fixes that. 
RUN chmod 777 /opt/coldfusion/cfusion/lib/neo-runtime.bak

# Copy code
COPY code/todo /app/todo
COPY code/index.cfm /app/index.cfm
ENV PORT 8500