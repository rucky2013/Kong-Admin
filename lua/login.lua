local template = require "resty.http"
local template = require "resty.template"

local uri = ngx.var.uri
ngx.log(ngx.INFO,"uri = ",uri )

ngx.req.read_body()
local param = ngx.req.get_post_args();
local username = param.username
local password = param.password

ngx.log(ngx.DEBUG,"username = ",username," password = ",password)

local correct_username = ""
local correct_password = ""

if username == correct_username then 
    if password == correct_password then
        ngx.redirect("/index/")
    else
        ngx.log(ngx.INFO,"password is wrong !")
        template.render('error/login_error.html',{error_msg = "username or password is wrong !"})
    end
else 
    ngx.log(ngx.INFO,"username or password is wrong !")
    template.render('error/login_error.html',{error_msg = "username or password is wrong !"})
end
