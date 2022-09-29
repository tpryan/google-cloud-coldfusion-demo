component rest="true" restpass="api/health"{
    remote string function get() httpmethod = "GET"  {
        return "ok";
    }
}    