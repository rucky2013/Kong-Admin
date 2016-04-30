local template = require "resty.template"
local cjson = require "cjson"
local http = require "resty.http"
local httpc = http.new()

local uri = ngx.var.uri
ngx.log(ngx.INFO,"uri = ",uri )

--get  kong ip
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
print(unpack(GetAdd(socket.dns.gethostname())))

--local kong =  "127.0.0.1"




local function handleListOAuths()
    
    local res,err = httpc:request_uri("http://" .. kong .. ":8001/plugins/",{
        method = "GET"
    })

    local fData = {};
    if not res then 
        ngx.log(ngx.ERR,"request for get all plugins http://localhost:8001/plugins fail because of no res")
        return false,nil,res,err
    elseif res.status ~= 200 then
        ngx.log(ngx.ERR,"request for get all plugins  http://localhost:8001/plugins fail because of res.status != 200")
        return false,nil,res,err
    else
        fData = cjson.decode(res.body)
    end

    -- select oauth plugin
    local _fData = fData.data
    local i = 1
    while i <= table.getn(_fData) do
        if _fData[i].name ~= "oauth" then
            table.remove(_fData[i])
        i = i + 1
        end
    end
    
    return true,_fData,nil,nil
end




local function handleDeleteOAuth()

    local param = ngx.req.get_uri_args();
    local id = param.id;
    
    local res,err = httpc:request_uri("http://" .. kong .. ":8001/plugins/"..id,{
        method = "DELETE"
    })
    
    if not res then
        ngx.log(ngx.ERR,"request for delete oauth http://localhost:8001/plugins fail because of no res")
        return false,res,err
    elseif res.status ~= 204 then
        ngx.log(ngx.ERR,"request for delete oauth http://localhost:8001/plugins fail because of res.status != 204")
        return false,res,err
    else
        return true,nil,nil
    end
end





--[[local function handleUpdateApi()]]
    
    --local param = ngx.req.get_uri_args();

    --local id = param.id
    --local upstream_url = param.upstream_url
    --local request_path = param.request_path

    --return id,upstream_url,request_path
--[[end]]





local function handleDoAddOAuth()
    ngx.req.read_body()
    local param = ngx.req.get_post_args();
    
    local api_id = param.id
    local name = "oauth2"
    local scopes = param.scopes
    local mandatory_scope = "true"
    local enable_authorization_code = param.authorization_code
    local enable_implicit_grant = param.implicit_grant
    local enable_password_grant = param.password_grant
    local enable_client_credentials = param.client_credentials
    local token_expiration = param.token_expiration

    local res,err = httpc:request_uri("http://" .. kong .. ":8001/apis/"..api_id.."/plugins", {
        method = "POST",
        body = "name="..name..
                "&config.scopes="..scopes..
                "&config.mandatory_scope="..mandatory_scope..
                "&config.enable_authorization_code="..enable_authorization_code..
                "&config.enable_client_credentials="..enable_client_credentials..
                "&config.enable_implicit_grant="..enable_implicit_grant..
                "&config.enable_password_grant="..enable_password_grant..
                "&config.token_expiration="..token_expiration,
        headers = {
                ["Content-Type"] = "application/x-www-form-urlencoded"
            }
    })

    if not res then
        ngx.log(ngx.ERR,"request for save a new oauth api http://localhost:8001/apis/../plugins fail because of no res,error = ",err)
        return false,res,err
    elseif res.status ~= 200 then
        if res.status ~= 201 then
            ngx.log(ngx.ERR,"request for save a new oauth api http://localhost:8001/apis/..plugins fail because of res.status != 200")
            return false,res,err
        else
            return true,nil,nil
        end
    else
        return true,nil,nil;
    end
end

local function handleGetApiDetailByOAuth(oauthItems)

    table.foreach(oauthItems,
        
        function(i,item)
            local res,err = httpc:request_uri("http://" .. kong .. ":8001/apis/" .. item.api_id,{
                method = "GET"
            })
            
            if not res then 
                ngx.log(ngx.ERR,"request for get api detail http://localhost:8001/apis/id fail because of no res")
                return false,apiItems,res,err
            elseif res.status ~= 200 then
                ngx.log(ngx.ERR,"request for get api detail http://localhost:8001/apis/id fail because of res.status != 200")
                return false,apiItems,res,err
            else
                local data = cjson.decode(res.body)
                item.upstream_url = data.upstream_url
                item.request_path = data.request_path
            end
        end
    )

    return true,oauthItems,res,err
end





local function handleGetAllApis()
    
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




local function handleGetUnOAuthApis(oauthItems)
    
    local isSucceed,apis,res,err = handleGetAllApis()

    if isSucceed == true then
        local i = 1
        while i <= table.getn(apis) do
            local api = apis[i]
            for j,oauthItem in pairs(oauthItems) do
                if oauthItem.enabled == true and oauthItem.api_id == api.id then
                    table.remove(apis,i)
                    i = i - 1
                    break
                end
            end
            i = i + 1
        end

        return isSucceed,apis,res,err
    else
        return false,apis,res,err
    end
end




local function handlelGetAllConsumers()
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
    end

    return true,fData.data,res,err
end




local function handleGetAllOAuthApplications()

    -- get all applications by consumers
    local isSucceed,consumers,res,err = handlelGetAllConsumers()

    if isSucceed == false then
        return false,nil,res,err
    end

    table.foreach(consumers,
        function(i,consumer)
            local res,err = httpc:request_uri("http://" .. kong .. ":8001/consumers/" .. consumer.id .. "/oauth2",{
                method = "GET"
            })
            
            if not res then 
                ngx.log(ngx.ERR,"request for get oauthApplication detail http://localhost:8001/consumers/consumer_id/oauth2 fail because of no res")
                return false,apiItems,res,err
            elseif res.status ~= 200 then
                ngx.log(ngx.ERR,"request for get oauthApplication detail http://localhost:8001/consumers/consumer_id/oauth2 fail because of res.status != 200")
                return false,apiItems,res,err
            else
                local fData = cjson.decode(res.body)
                local data = fData.data

                if table.getn(data) ~= 0 then
                    consumer.client_id = data[1].client_id
                    consumer.client_secret = data[1].client_secret
                    consumer.redirect_uri = data[1].redirect_uri
                    consumer.name = data[1].name
                    consumer.application_id = data[1].id
                end
            end
        end
    )

    return true,consumers,nil,nil
end




local function handlelDoAddOAuthApplication()

    ngx.req.read_body()
    local param = ngx.req.get_post_args();
    
    local consumer_id= param.consumer_id
    local name = param.name
    local client_id = param.client_id
    local client_secret = param.client_secret
    local redirect_uri = param.redirect_uri

    ngx.log(ngx.DEBUG,"consumer_id = ",consumer_id)
    ngx.log(ngx.DEBUG,"name =",name)
    ngx.log(ngx.DEBUG,"client_id = ",client_secret)
    ngx.log(ngx.DEBUG,"client_secret = ",client_secret)
    ngx.log(ngx.DEBUG,"redirect_uri = ",redirect_uri)

    local res,err = httpc:request_uri("http://" .. kong .. ":8001/consumers/"..consumer_id.."/oauth2", {
        method = "POST",
        body = "name="..name..
                "&client_id="..client_id..
                "&client_secret="..client_secret..
                "&redirect_uri="..redirect_uri,
        headers = {
                ["Content-Type"] = "application/x-www-form-urlencoded"
            }
    })
    
    if not res then
        ngx.log(ngx.ERR,"request for add a new OAuth application http://localhost:8001/consumers/../oauth2 fail "..
                    "because of no res,error = ",err)
        return false,res,err
    elseif res.status ~= 200 then
        if res.status ~= 201 then
            ngx.log(ngx.ERR,"request for add a new OAuth application http://localhost:8001/consumers/../oauth2 fail"..
                " because of res.status != 200")
            return false,res,err
        else
            return true,nil,nil
        end
    else
        return true,nil,nil;
    end
end




if uri == "/oauth/list-oauths" then
    local oauthSucceed,oauthItems,oauthRes,oauthErr = handleListOAuths()
    if oauthSucceed == true then
        local apiSucceed,oauthItems,apiRes,apiErr = handleGetApiDetailByOAuth(oauthItems)
        if apiSucceed == true then

            local unApiSucceed,unOAuthApis,unRes,unErr = handleGetUnOAuthApis(oauthItems)
            
            if unApiSucceed == true then
                
                template.render("oauth/oauth_index.html",{
                    oauthItems = oauthItems,
                    unOAuthApis = unOAuthApis
                })
            else 
                template.render("error/error.html",{
                    res = unRes,
                    err = unErr
                })
            end
        else 
            template.render("error/error.html",{
                res = apiRes,
                err = apiErr
            })
        end
    else 
        template.render("error/error.html",{
             res = oauthRes,
             err = oauthErr
        })
    end

elseif uri == '/oauth/delete' then
    local isSucceed,res,err = handleDeleteOAuth()
    if isSucceed  == true then 
        ngx.redirect("/oauth/list-oauths")
    else 
        template.render('error/error.html',{
             res = res,
             err = err
        })
    end

elseif uri == '/oauth/add-oauth' then
    
    local param = ngx.req.get_uri_args();
    local id = param.id;
    local request_path = param.request_path;

    template.render('oauth/oauth_add_api.html',{
         id = id,
         request_path = request_path
    })

elseif uri == '/oauth/list-oauthApplications' then
    local isSucceed,consumersAndApplications,res,err = handleGetAllOAuthApplications()

    if isSucceed == true then 
        template.render('oauth/oauth_applications.html',{
            consumersAndApplications = consumersAndApplications 
        })
    else 
        template.render('error/error.html',{
            res = res,
            err = err
        })
    end

elseif uri == '/oauth/add-oauthApplication' then
    local isSucceed,consumers,res,err = handlelGetAllConsumers()
    if isSucceed == true then 
        template.render('oauth/oauth_add_application.html',{
            consumers = consumers 
        })
    else 
        template.render('error/error.html',{
            res = res,
            err = err
        })
    end

elseif uri == '/oauth/do-add-oauth-application' then
    local isSucceed,consumers,res,err = handlelDoAddOAuthApplication()
    if isSucceed == true then 
        ngx.redirect('/oauth/list-oauthApplications')
    else 
        template.render('error/error.html',{
            res = res,
            err = err
        })
    end

elseif uri == '/api/update'  then
    local id,upstream_url,request_path = handleUpdateApi() 
    template.render('api/api_add.html',{
        id = id,
        upstream_url = upstream_url,
        request_path = request_path
    })

elseif uri == '/oauth/do-add-oauth' then
    local isSucceed,res,err = handleDoAddOAuth()

    if isSucceed == true then 
        ngx.redirect("/oauth/list-oauths")
    else 
        template.render('error/error.html',{
            res = res,
            err = err
        })
    end
end

