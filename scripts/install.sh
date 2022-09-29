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

PROJECT=$1
SERVERNAME=$2

sleep 60

gcloud compute scp --project=${PROJECT} silent.properties ${SERVERNAME}:~ 
gcloud compute ssh ${SERVERNAME} --project=${PROJECT} --command="curl -o installer https://download.macromedia.com/pub/coldfusion/updates/14/gui_installers/ColdFusion_2021_GUI_WWEJ_linux64.bin"
gcloud compute ssh ${SERVERNAME} --project=${PROJECT} --command="chmod +x installer"
gcloud compute ssh ${SERVERNAME} --project=${PROJECT} --command="sudo ./installer -f silent.properties "

gcloud compute ssh ${SERVERNAME} --project=${PROJECT} --command="sudo apt-get update -y"
gcloud compute ssh ${SERVERNAME} --project=${PROJECT} --command="sudo apt-get install maven git -y"
gcloud compute ssh ${SERVERNAME} --project=${PROJECT} --command="mvn dependency:get -Dartifact=mysql:mysql-connector-java:8.0.30"


gcloud compute ssh ${SERVERNAME} --project=${PROJECT} --command="sudo cp ~/.m2/repository/mysql/mysql-connector-java/8.0.30/mysql-connector-java-8.0.30.jar /opt/ColdFusion2021/cfusion/lib/"
gcloud compute ssh ${SERVERNAME} --project=${PROJECT} --command="sudo rm -rf .m2"
gcloud compute ssh ${SERVERNAME} --project=${PROJECT} --command="sudo /opt/ColdFusion2021/cfusion/bin/cfpm.sh install orm,debugger,mysql,zip"


gcloud compute ssh ${SERVERNAME} --project=${PROJECT} --command="sudo git clone https://github.com/markmandel/JavaLoader /tmp/jl"
gcloud compute ssh ${SERVERNAME} --project=${PROJECT} --command="sudo cp -r /tmp/jl/javaloader /opt/ColdFusion2021/cfusion/wwwroot"


gcloud compute ssh ${SERVERNAME} --project=${PROJECT} --command="mvn dependency:get -Dartifact=com.google.cloud:google-cloud-secretmanager:2.3.7"
gcloud compute ssh ${SERVERNAME} --project=${PROJECT} --command="sudo cp -r ~/.m2 /opt/ColdFusion2021/cfusion/wwwroot/jarfiles"
gcloud compute ssh ${SERVERNAME} --project=${PROJECT} --command="sudo /opt/ColdFusion2021/config/cfsetup/cfsetup.sh alias instance /opt/ColdFusion2021/cfusion"
gcloud compute ssh ${SERVERNAME} --project=${PROJECT} --command="sudo /opt/ColdFusion2021/config/cfsetup/cfsetup.sh set runtime disablecfcomponentaccess=false instance"
gcloud compute ssh ${SERVERNAME} --project=${PROJECT} --command="sudo /opt/ColdFusion2021/config/cfsetup/cfsetup.sh add mapping virtual=/javaloader physical=/opt/ColdFusion2021/cfusion/wwwroot/javaloader/ instance"
gcloud compute ssh ${SERVERNAME} --project=${PROJECT} --command="sudo /opt/ColdFusion2021/cfusion/bin/cfpm.sh update all"
gcloud compute ssh ${SERVERNAME} --project=${PROJECT} --command="sudo /opt/ColdFusion2021/cfusion/bin/coldfusion restart"
