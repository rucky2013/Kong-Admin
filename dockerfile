FROM daocloud.io/library/centos
RUN yum -y update

# install openResty
ADD openresty-1.9.7.4 /opt/openresty-1.9.7.4/ 
RUN yum -y install pcre-devel && yum -y install openssl-devel && yum -y install perl && yum -y install gcc && yum -y install make  
RUN mkdir /opt/openResty/ && cd /opt/openresty-1.9.7.4 && ./configure --prefix=/opt/openResty/ && make && make install

# install luajit - for socket 
RUN yum -y install git && yum -y install cmake && yum -y install wget && yum -y install gcc-c++ && yum -y install unzip 
RUN mkdir /home/whc/ 
RUN cd /home/whc && git clone https://github.com/torch/luajit-rocks.git 
RUN cd /home/whc/luajit-rocks && mkdir build && mkdir /opt/luajitrocks
RUN cd /home/whc/luajit-rocks/build && cmake ..   
RUN cd /home/whc/luajit-rocks/build && make install
RUN luarocks install luasocket

# exec kong-admin
RUN yum -y install git
RUN cd /opt/ && git clone https://github.com/pzxwhc/Kong-Admin.git
RUN cd /opt/Kong-Admin && git checkout -b aliyun origin/aliyun
RUN cp /opt/Kong-Admin/import/* /opt/openResty/lualib/resty
CMD cd /opt/openResty/nginx/sbin && ./nginx -p /opt/Kong-Admin -c /opt/Kong-Admin/conf/nginx.conf && tail -f /opt/Kong-Admin/logs/error.log



