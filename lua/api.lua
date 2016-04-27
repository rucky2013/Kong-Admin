local template = require "resty.template"
local cjson = require "cjson"
local http = require "resty.http"
local httpc = http.new()

local uri = ngx.var.uri
ngx.log(ngx.INFO,"uri = ",uri )

-- get  kong ip
local socket = require "socket"
function GetAdd(hostname)
    local ip, resolved = socket.dns.toip(hostname)
    local ListTab = {}
    for k, v in ipairs(resolved.ip) do
        table.insert(ListTab, v)
    end
    return ListTab
end

local kong = unpack(GetAdd('kong'))
--print(unpack(GetAdd(socket.dns.gethostname())))



local function handleListApis()
    
    local res,err = httpc:request_uri("http://" .. kong .. ":8001/apis/",{
        method = "GET"
    })

    local fData = {};
    if not res then 
        ngx.log(ngx.ERR,"request for get all apis http://localhost:8001/apis fail because of no res")
        return false,nil,res,err
    elseif res.status ~= 200 then
        ngx.log(ngx.ERR,"request for get all apis  http://localhost:8001/apis fail because of res.status != 200")
        return false,nil,res,err
    else
        fData = cjson.decode(res.body)
        return true,fData.data,nil,nil
    end
end




local function handleDeleteApi()

    local param = ngx.req.get_uri_args();
    local id = param.id;
    
    local res,err = httpc:request_uri("http://" .. kong .. ":8001/apis/"..id,{
        method = "DELETE"
    })
    
    if not res then
        ngx.log(ngx.ERR,"request for delete http://localhost:8001/apis fail because of no res")
        return false,res,err
    elseif res.status ~= 204 then
        ngx.log(ngx.ERR,"request for delete  http://localhost:8001/apis fail because of res.status != 200")
        return false,res,err
    else
        return true,nil,nil
    end
end





local function handleUpdateApi()
    
    local param = ngx.req.get_uri_args();

    local id = param.id
    local upstream_url = param.upstream_url
    local request_path = param.request_path

    return id,upstream_url,request_path
end





local function handleDoAddApi()
    ngx.req.read_body()
    local param = ngx.req.get_post_args();
    
    local id = param.id
    local upstream_url = param.upstream_url
    local request_path = param.request_path

    local res
    local err
    if id == nil then 
        res,err = httpc:request_uri("http://" .. kong .. ":8001/apis", {
            method = "POST",
            body = "upstream_url=" .. upstream_url .. "&request_path=" .. request_path,
	    headers = {
                ["Content-Type"] = "application/x-www-form-urlencoded"
            }
        })
    else
        res,err = httpc:request_uri("http://" .. kong .. ":8001/apis/"..id,{
            method = "PATCH",
            body = "upstream_url="..upstream_url.."&request_path="..request_path,
            headers = {
                ["Content-Type"] = "application/x-www-form-urlencoded"
            }
        })
    end

    if not res then
        ngx.log(ngx.ERR,"request for save/update a new api http://localhost:8001/apis fail because of no res,error = ",err)
        return false,res,err
    elseif res.status ~= 200 then
        if res.status ~= 201 then
            ngx.log(ngx.ERR,"request for save/update a new api http://localhost:8001/apis fail because of res.status != 200")
            return false,res,err
        else
            return true,nil,nil
        end
    else
        return true,nil,nil;
    end
end






if uri == "/api/list-apis" then
    local isSucceed,data,res,err = handleListApis()
    if isSucceed == true then
        template.render("api/api_index.html",{items = data})
    else 
        template.render("error/error.html",{
             res = res,
             err = err
        })
    end

elseif uri == '/api/delete' then
    local isSucceed,res,err = handleDeleteApi()
    if isSucceed  == true then 
        ngx.redirect("/api/list-apis")
    else 
        template.render('error/error.html',{
             res = res,
             err = err
        })
    end

elseif uri == '/api/add-api' then
    template.render('api/api_add.html')

elseif uri == '/api/update'  then
    local id,upstream_url,request_path = handleUpdateApi() 
    template.render('api/api_add.html',{
        id = id,
        upstream_url = upstream_url,
        request_path = request_path
    })

elseif uri == '/api/do-add-api' then
    local isSucceed,res,err = handleDoAddApi()

    if isSucceed == true then 
        ngx.redirect("/api/list-apis")
    else 
        template.render('error/error.html',{
            res = res,
            err = err
        })
    end
end

