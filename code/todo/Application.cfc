component {
    this.name = "todo";
     this.ormenabled = true;
     
    this.applicationTimeout= CreateTimeSpan(0,0,0,10);
    this.datasource    = "todo_datasource";
    this.ormsettings={datasource="todo_datasource", logsql="true"}
    this.mappings["/javaloader"]="#server.coldfusion.rootdir#/wwwroot/javaloader";


    if (!StructKeyExists(server.system.environment, "DB_NAME") || IsDefined("url.force_secret")){
        gcpProject = getProjectID();
        keys = ["DB_USER", "DB_PASS", "DB_HOST", "DB_NAME", "DB_PORT"];
        secrets = getGoogleCloudSecrets(keys, gcpProject);

        for (key in keys){
            server.system.environment[key] = secrets[key];
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

        application.project = "coldfusion-demo";

        var keys = ["DB_USER", "DB_PASS", "DB_HOST", "DB_NAME", "DB_PORT"];
        var secrets = getEnvironmentSecrets(keys);

        if (structCount(secrets) eq 0){
            secrets = getGoogleCloudSecrets(keys,  application.project)
        }


        application.driver      = "MySQL5";
        application.database    = secrets.DB_NAME;
        application.host        = secrets.DB_HOST;
        application.port        = secrets.DB_PORT;
        application.username    = secrets.DB_USER;
        application.password    = secrets.DB_PASS;
   

        RestInitApplication(expandPath('./cfc/services'), "api")
        return true; 
    }

    function onRequestStart(){
       if (IsDefined("url.reinit")){
         OnApplicationStart()
       }  
       return true
    }


    private function getGoogleCloudSecrets(array secrets, string project) any{
        var results = structNew();

        var paths = DirectoryList(ExpandPath("../jarfiles"), true);


        var loader = createObject("component", "javaloader.JavaLoader").init(paths);

        var secretName = loader.create("com.google.cloud.secretmanager.v1.SecretVersionName");
        var secretManagerServiceClient = loader.create("com.google.cloud.secretmanager.v1.SecretManagerServiceClient").create();
        
        for (secret in secrets){
            var secrethPath = secretName.of(project, secret, "latest").toString();
            var secretValue = secretManagerServiceClient.accessSecretVersion(secrethPath);
            results[secret] = secretValue.getPayload().getData().toString("UTF-8"); 
        }
        return results
    }

    private function getEnvironmentSecrets(array secrets) any{
        var results = structNew();
        for (secret in secrets){
            results[secret] =server.system.environment[secret];	
        }	

        return results
    }

    private function getProjectID()any{
        httpService = new http();
        httpService.setMethod("GET");
        httpService.addParam(type="header",name="Metadata-Flavor",value="Google");
        httpService.setUrl("http://metadata.google.internal/computeMetadata/v1/project/project-id");
        result = httpService.send().getPrefix().Filecontent.toString();
        return result;
    }


}