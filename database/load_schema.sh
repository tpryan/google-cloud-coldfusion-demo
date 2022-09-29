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