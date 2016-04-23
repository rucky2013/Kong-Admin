FROM daocloud.io/library/centos
RUN yum -y update

# install openResty
ADD openresty-1.9.7.4 /opt/openresty-1.9.7.4/ 
RUN yum -y install pcre-devel && yum -y install openssl-devel && yum -y install perl && yum -y install gcc && yum -y install make  
RUN mkdir /opt/openResty/ && cd /opt/openresty-1.9.7.4 && ./configure --prefix=/opt/openResty/ && make && make install

# exec kong-admin
ADD ./ /opt/Kong-Admin/
CMD cd /opt/openResty/nginx/sbin && ./nginx -p /opt/Kong-Admin -c /opt/Kong-Admin/conf/nginx.conf && tail -f /opt/Kong-Admin/logs/error.log



