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

    this.StatusOk = 200;
    this.StatusCreated = 201;
    this.StatusNoContent = 204;
    this.StatusNotFound = 404;


    remote array function list() httpmethod="GET" produces = "application/json"{
        local.result = EntityLoad("todo");
        return local.result;
    }

    remote  todo.cfc.bean.todo function get(numeric id restargsource = "path") httpmethod = "GET" produces="application/json" restpath= "{id}" {
        local.todo = entityLoadByPK("todo", id);
        return local.todo;
    }

     remote void function create(required todo.cfc.bean.todo input) httpmethod="POST" {
        local.todo = new todo.cfc.bean.todo();
        local.todo.setTitle(input.title)
        local.todo.setUpdated(Now());
        
        entitySave(local.todo);
        ormflush();
        restSetResponse({status=this.StatusCreated});
        return
    }

    remote void function update(todo.cfc.bean.todo input, numeric id restargsource = "path") httpmethod = "PUT" restpath= "{id}" {
        local.todo = entityLoadByPK("todo", id);
        local.todo.setTitle(input.title);
        local.todo.setUpdated(Now());
        if (!isNull(input.completed)  && isBoolean(input.completed)){
            if (input.completed) {
                todo.setCompleted(Now());
            } else{
                todo.setCompleted(javaCast("null",""));
            }
        } 

        restSetResponse({status=this.StatusOk});
        entitySave(local.todo);
        ormflush();
    }

     remote void function delete(numeric id restargsource = "path") httpmethod="DELETE" restpath= "{id}" {

        local.todo = entityLoadByPK("todo", id);
         if (!isNull(todo)){
            entityDelete(local.todo);
            ormflush();
            restSetResponse({status=this.StatusNoContent});
            return 
        }
        restSetResponse({status=this.StatusNotFound});
        return 
    }
}