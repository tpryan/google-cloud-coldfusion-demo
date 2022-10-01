//  Copyright 2022 Google LLC

//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at

//       http://www.apache.org/licenses/LICENSE-2.0

//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.


component {
    this.name = "todo";
    this.ormenabled = true;
    this.applicationTimeout = CreateTimeSpan(0,0,60,0);
    this.sessionmanagement="Yes" 
    this.sessiontimeout = CreateTimeSpan(0,0,45,0);
    this.datasource = "todo_datasource";
    this.ormsettings ={
            datasource="todo_datasource", 
            logsql="true" 
    }
    this.mappings["/javaloader"]="#server.coldfusion.rootdir#/wwwroot/javaloader";


    if (!StructKeyExists(server.system.environment, "DB_NAME") || IsDefined("url.force_secret")){
        this.gcpProject = getProjectID();
        keys = ["DB_USER", "DB_PASS", "DB_HOST", "DB_NAME", "DB_PORT"];
        this.secrets = getGoogleCloudSecrets(keys, this.gcpProject);

        for (key in keys){
            server.system.environment[key] = this.secrets[key];
        }
    }

    this.datasources = {
        todo_datasource    = {
            driver      = "MySQL5",
            database    = server.system.environment.DB_NAME ,
            host        = server.system.environment.DB_HOST,
            port        = server.system.environment.DB_PORT,
            username    = server.system.environment.DB_USER,
            password    = server.system.environment.DB_PASS
        }
    }

    

    function onApplicationStart() { 
        RestInitApplication(expandPath('./cfc/services'), "api")
        return true; 
    }

    function onSessionStart() { 
        session.started = Now();
        return true; 
    }

    function onRequestStart(){
       if (IsDefined("url.reinit")){
         OnApplicationStart()
       }  
       return true
    }


    private function getGoogleCloudSecrets(array secrets, string project) any{
        local.results = structNew();
        local.paths = DirectoryList(ExpandPath("../jarfiles"), true);
        local.loader = createObject("component", "javaloader.JavaLoader").init(paths);
        local.client = loader.create("com.google.cloud.secretmanager.v1.SecretManagerServiceClient").create();
        
        for (secret in secrets){
            local.secrethPath = "projects/#project#/secrets/#secret#/versions/latest";
            local.secretValue = local.client.accessSecretVersion(secrethPath);
            local.results[secret] = local.secretValue.getPayload().getData().toString("UTF-8"); 
        }
        return local.results
    }

    private function getEnvironmentSecrets(array secrets) any{
        local.results = structNew();
        for (secret in secrets){
            local.results[secret] =server.system.environment[secret];	
        }	

        return local.results
    }

    private function getProjectID()any{
        local.httpService = new http();
        local.httpService.setMethod("GET");
        local.httpService.addParam(type="header",name="Metadata-Flavor",value="Google");
        local.httpService.setUrl("http://metadata.google.internal/computeMetadata/v1/project/project-id");
        local.result = local.httpService.send().getPrefix().Filecontent.toString();
        return local.result;
    }

}