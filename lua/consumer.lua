local template = require "resty.template"
local cjson = require "cjson"
local http = require "resty.http"
local httpc = http.new()

local uri = ngx.var.uri
ngx.log(ngx.INFO,"uri = ",uri )

-- get  kong ip
--[[local socket = require "socket"]]
--function GetAdd(hostname)
    --local ip, resolved = socket.dns.toip(hostname)
    --local ListTab = {}
    --for k, v in ipairs(resolved.ip) do
        --table.insert(ListTab, v)
    --end
    --return ListTab
--end

--[[local kong = unpack(GetAdd('kong'))]]
--print(unpack(GetAdd(socket.dns.gethostname())))

local kong =  "127.0.0.1"




local function handleListConsumers()
    
    local res,err = httpc:request_uri("http://" .. kong .. ":8001/consumers/",{
        method = "GET"
    })

    local fData = {};
    if not res then 
        ngx.log(ngx.ERR,"request for get all consumers http://localhost:8001/consumers fail because of no res")
        return false,nil,res,err
    elseif res.status ~= 200 then
        ngx.log(ngx.ERR,"request for get all consumers  http://localhost:8001/consumers fail because of res.status != 200")
        return false,nil,res,err
    else
        fData = cjson.decode(res.body)
        return true,fData.data,nil,nil
    end
end




local function handleDeleteConsumer()

    local param = ngx.req.get_uri_args();
    local id = param.id;
    
    local res,err = httpc:request_uri("http://" .. kong .. ":8001/consumers/"..id,{
        method = "DELETE"
    })
    
    if not res then
        ngx.log(ngx.ERR,"request for delete http://localhost:8001/consumers fail because of no res")
        return false,res,err
    elseif res.status ~= 204 then
        ngx.log(ngx.ERR,"request for delete  http://localhost:8001/consumers fail because of res.status != 200")
        return false,res,err
    else
        return true,nil,nil
    end
end





local function handleUpdateConsumer()
    
    local param = ngx.req.get_uri_args();

    local id = param.id
    local username = param.username
    local custom_id = param.custom_id

    return id,username,custom_id
end





local function handleDoAddConsumer()
    ngx.req.read_body()
    local param = ngx.req.get_post_args();
    
    local id = param.id
    local username = param.username
    local custom_id = param.custom_id

    local res
    local err
    if id == nil then 
        res,err = httpc:request_uri("http://" .. kong .. ":8001/consumers", {
            method = "POST",
            body = "username=" .. username .. "&custom_id=" .. custom_id,
        headers = {
                ["Content-Type"] = "application/x-www-form-urlencoded"
            }
        })
    else
        res,err = httpc:request_uri("http://" .. kong .. ":8001/consumers/"..id,{
            method = "PATCH",
            body = "username="..username.."&custom_id="..custom_id,
            headers = {
                ["Content-Type"] = "application/x-www-form-urlencoded"
            }
        })
    end

    if not res then
        ngx.log(ngx.ERR,"request for save/update a new customer http://localhost:8001/customers fail because of no res,error = ",err)
        return false,res,err
    elseif res.status ~= 200 then
        if res.status ~= 201 then
            ngx.log(ngx.ERR,"request for save/update a new customer http://localhost:8001/customers fail because of res.status != 200")
            return false,res,err
        else
            return true,nil,nil
        end
    else
        return true,nil,nil;
    end
end






if uri == "/consumer/list-consumers" then
    local isSucceed,data,res,err = handleListConsumers()
    if isSucceed == true then
        template.render("consumer/consumer_index.html",{items = data})
    else 
        template.render("error/error.html",{
             res = res,
             err = err
        })
    end

elseif uri == '/consumer/delete' then
    local isSucceed,res,err = handleDeleteConsumer()
    if isSucceed  == true then 
        ngx.redirect("/consumer/list-consumers")
    else 
        template.render('error/error.html',{
             res = res,
             err = err
        })
    end

elseif uri == '/consumer/add-consumer' then
    template.render('consumer/consumer_add.html')

elseif uri == '/consumer/update'  then
    local id,username,custom_id = handleUpdateConsumer() 
    template.render('consumer/consumer_add.html',{
        id = id,
        username = username,
        custom_id = custom_id
    })

elseif uri == '/consumer/do-add-consumer' then
    local isSucceed,res,err = handleDoAddConsumer()

    if isSucceed == true then 
        ngx.redirect("/consumer/list-consumers")
    else 
        template.render('error/error.html',{
            res = res,
            err = err
        })
    end
end

