SERVERNAME=todo
PROJECT=coldfusion-demo-2


gcloud compute scp --project=${PROJECT} --recurse ../code/todo ${SERVERNAME}:~
gcloud compute scp --project=${PROJECT} --recurse ../code/index.cfm ${SERVERNAME}:~
gcloud compute ssh ${SERVERNAME} --project=${PROJECT} --command="sudo cp -r ~/todo /opt/ColdFusion2021/cfusion/wwwroot" 
gcloud compute ssh ${SERVERNAME} --project=${PROJECT} --command="sudo cp -r index.cfm /opt/ColdFusion2021/cfusion/wwwroot/"