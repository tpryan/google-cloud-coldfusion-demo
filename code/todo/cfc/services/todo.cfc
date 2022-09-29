component rest="true" restpass="api/todo"{

    remote array function list() httpmethod="GET" produces = "application/json"{
        result = EntityLoad("todo");
        return result;
    }

    remote  todo.cfc.bean.todo function get(numeric id restargsource = "path") httpmethod = "GET" produces="application/json" restpath= "{id}" {
        var todo = entityLoadByPK("todo", id);
        return todo;
    }

     remote void function create(required todo.cfc.bean.todo input) httpmethod="POST" {
        var todo = new todo.cfc.bean.todo();
        todo.setTitle(input.title)
        todo.setUpdated(Now());
        
        entitySave(todo);
        ormflush();
        restSetResponse({status=201});
        return
    }

    remote void function update(todo.cfc.bean.todo input, numeric id restargsource = "path") httpmethod = "PUT" restpath= "{id}" {
        writeLog("v1: update received")
        var todo = entityLoadByPK("todo", id);
        todo.setTitle(input.title);
        todo.setUpdated(Now());
        if (!isNull(input.completed)  && isBoolean(input.completed)){
            if (input.completed) {
                writeLog("v1: set complete")
                todo.setCompleted(Now());
            } else{
                writeLog("v1: set incomplete")
                todo.setCompleted(javaCast("null",""));
            }
        } else{
            writeLog("v1: don touch complete")
        }

        restSetResponse({status=200});
        entitySave(todo);
        ormflush();
    }

     remote void function delete(numeric id restargsource = "path") httpmethod="DELETE" restpath= "{id}" {

        var todo = entityLoadByPK("todo", id);
         if (!isNull(todo)){
            entityDelete(todo);
            ormflush();
            restSetResponse({status=204});
            return 
        }
        restSetResponse({status=404});
        return 
    }
}