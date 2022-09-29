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
RUN apt-get update -y && apt-get install maven git -y 
RUN mvn dependency:get -Dartifact=mysql:mysql-connector-java:8.0.30
RUN cp /root/.m2/repository/mysql/mysql-connector-java/8.0.30/mysql-connector-java-8.0.30.jar /opt/coldfusion/cfusion/lib/ && rm -rf /root/.m2
RUN mvn dependency:get -Dartifact=com.google.cloud:google-cloud-secretmanager:2.3.7
RUN mkdir -p /app/jarfiles && cp -r /root/.m2 /app/jarfiles && rm -rf /root/.m2
RUN git clone https://github.com/markmandel/JavaLoader /tmp/jl
RUN cp -r /tmp/jl/javaloader /opt/coldfusion/cfusion/wwwroot
COPY code/todo /app/todo
COPY code/index.cfm /app/index.cfm
ENV PORT 8500