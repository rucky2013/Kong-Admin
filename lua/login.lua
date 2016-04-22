local template = require "resty.http"
local template = require "resty.template"

local uri = ngx.var.uri
ngx.log(ngx.INFO,"uri = ",uri )


------------------------------------------
-----------connect to redis---------------
------------------------------------------

local redis = require "resty.redis"

local red = redis.new();

local ok,err = red:connect("127.0.0.1",6379)
red:set_timeout(5000)

if not ok then
    ngx.log(ngx.ERR,"redis connects fail!")
    res.body = "redis connects fail!"
    template.render('error/error.html',{res = res})
end


--------------------------------------------
--------valid username and password---------
--------------------------------------------
function doValid(res,password)
    if res[1] == password then 
        return true
    else
        return false
    end
end

ngx.req.read_body()
local param = ngx.req.get_post_args();
local username = param.username
local password = param.password

ngx.log(ngx.DEBUG,"username = ",username," password = ",password)

local res,err = red:hmget(username,"password")

if not res then 
    ngx.log(ngx.ERR,"redis is connected,but couldn't get the data!")
    res.body = "redis is connected,but couldn't get the data!"
    template.render('error/error.html',{res = res})

elseif res == ngx.null then
    ngx.log(ngx.INFO,"username or password is wrong !")
    template.render('error/login_error.html',{error_msg = "username or password is wrong !"})

else 
    
    local ok = doValid(res,password)

    if ok then
        ngx.redirect("/index/")
    else 
        ngx.log(ngx.INFO,"username or password is wrong !")
        template.render('error/login_error.html',{error_msg = "username or password is wrong !"})
    end
end







