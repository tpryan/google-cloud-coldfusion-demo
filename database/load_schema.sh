PROJECT=$1
SQLNAME=$2
PASSWORD=$3

SQLSERVICEACCOUNT=$(gcloud sql instances describe $SQLNAME --project $PROJECT --format="value(serviceAccountEmailAddress)" | xargs)

cp schema.sql schema.tmp
sed -i"" -e "s/todo_pass/$PASSWORD/" schema.tmp
gsutil mb gs://$PROJECT-temp
gsutil cp schema.tmp gs://$PROJECT-temp/schema.sql
gsutil iam ch serviceAccount:$SQLSERVICEACCOUNT:objectViewer gs://$PROJECT-temp/
gcloud sql import sql $SQLNAME gs://$PROJECT-temp/schema.sql -q --project=${PROJECT}
gsutil rm gs://$PROJECT-temp/schema.sql
gsutil rb gs://$PROJECT-temp
rm schema.tmp
rm schema.tmp-e