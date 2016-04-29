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




--[[local function handleDeleteApi()]]

    --local param = ngx.req.get_uri_args();
    --local id = param.id;
    
    --local res,err = httpc:request_uri("http://" .. kong .. ":8001/apis/"..id,{
        --method = "DELETE"
    --})
    
    --if not res then
        --ngx.log(ngx.ERR,"request for delete http://localhost:8001/apis fail because of no res")
        --return false,res,err
    --elseif res.status ~= 204 then
        --ngx.log(ngx.ERR,"request for delete  http://localhost:8001/apis fail because of res.status != 200")
        --return false,res,err
    --else
        --return true,nil,nil
    --end
--[[end]]





--[[local function handleUpdateApi()]]
    
    --local param = ngx.req.get_uri_args();

    --local id = param.id
    --local upstream_url = param.upstream_url
    --local request_path = param.request_path

    --return id,upstream_url,request_path
--[[end]]





--[[local function handleDoAddApi()]]
    --ngx.req.read_body()
    --local param = ngx.req.get_post_args();
    
    --local id = param.id
    --local upstream_url = param.upstream_url
    --local request_path = param.request_path

    --local res
    --local err
    --if id == nil then 
        --res,err = httpc:request_uri("http://" .. kong .. ":8001/apis", {
            --method = "POST",
            --body = "upstream_url=" .. upstream_url .. "&request_path=" .. request_path,
        --headers = {
                --["Content-Type"] = "application/x-www-form-urlencoded"
            --}
        --})
    --else
        --res,err = httpc:request_uri("http://" .. kong .. ":8001/apis/"..id,{
            --method = "PATCH",
            --body = "upstream_url="..upstream_url.."&request_path="..request_path,
            --headers = {
                --["Content-Type"] = "application/x-www-form-urlencoded"
            --}
        --})
    --end

    --if not res then
        --ngx.log(ngx.ERR,"request for save/update a new api http://localhost:8001/apis fail because of no res,error = ",err)
        --return false,res,err
    --elseif res.status ~= 200 then
        --if res.status ~= 201 then
            --ngx.log(ngx.ERR,"request for save/update a new api http://localhost:8001/apis fail because of res.status != 200")
            --return false,res,err
        --else
            --return true,nil,nil
        --end
    --else
        --return true,nil,nil;
    --end
--end

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
        for i,api in pairs(apis) do
            for j,oauthItem in pairs(oauthItems) do
                if oauthItem.api_id == api.id then
                    table.remove(apis, i)
                    break
                end
            end
        end
        return isSucceed,apis,res,err
    else
        return false,apis,res,err
    end
end





if uri == "/oauth/list-oauths" then
    local oauthSucceed,oauthItems,oauthRes,oauthErr = handleListOAuths()
    if oauthSucceed == true then
        local apiSucceed,oauthItems,apiRes,apiErr = handleGetApiDetailByOAuth(oauthItems)

        ngx.log(ngx.DEBUG,oauthItems[1].config.scopes[1])

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

