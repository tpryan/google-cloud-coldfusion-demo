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