#!/bin/bash
set -euo pipefail

source /etc/profile || true

# 修正 Apache/PHP-FPM 用户组为 www-data，确保权限
sed -i 's/export APACHE_RUN_USER=.*/export APACHE_RUN_USER=www-data/' /etc/apache2/envvars
sed -i 's/export APACHE_RUN_GROUP=.*/export APACHE_RUN_GROUP=www-data/' /etc/apache2/envvars
sed -i 's/^user\s*=.*/user = www-data/' /etc/php/7.4/fpm/pool.d/www.conf 2>/dev/null || true
sed -i 's/^group\s*=.*/group = www-data/' /etc/php/7.4/fpm/pool.d/www.conf 2>/dev/null || true
chown -R www-data:www-data /home/svnadmin || true
chmod -R 777 /home/svnadmin || true

# 初始化 /home/svnadmin（当为挂载卷且为空时）
if [ ! -d "/home/svnadmin/rep" ] || [ ! -f "/home/svnadmin/svnserve.conf" ]; then
	echo "[init] seeding /home/svnadmin from /opt/svnadmin-seed" >&2
	mkdir -p /home/svnadmin
	cp -rT /opt/svnadmin-seed /home/svnadmin || true
fi

# 确保必要的目录与权限
mkdir -p /home/svnadmin/{rep,logs,sasl/ldap,crond,backup,temp,templete/initStruct/01/{branches,tags,trunk}}
touch /home/svnadmin/svnadmin.db || true
chown -R www-data:www-data /home/svnadmin || true

# 启动 PHP-FPM（Debian: php-fpm 服务名基于已安装版本的通用入口）
service php7.4-fpm start || service php-fpm start || true

# 启动 SVN 服务
/usr/bin/svnserve --daemon --pid-file=/home/svnadmin/svnserve.pid -r '/home/svnadmin/rep/' --config-file '/home/svnadmin/svnserve.conf' --log-file '/home/svnadmin/logs/svnserve.log' --listen-port 3690 --listen-host 0.0.0.0 || true

# 启动 saslauthd（LDAP 模式）
spid=$(uuidgen)
/usr/sbin/saslauthd -a 'ldap' -O "$spid" -O '/home/svnadmin/sasl/ldap/saslauthd.conf' || true
ps aux | grep -v grep | grep "$spid" | awk 'NR==1{print $2}' > '/home/svnadmin/sasl/saslauthd.pid' || true
chmod 777 /home/svnadmin/sasl/saslauthd.pid || true

# 启动 cron 与 atd
service cron start || true
service atd start || true

# 启动后台守护进程
/usr/bin/php /var/www/html/server/svnadmind.php start &

# Apache 运行（Debian使用apache2ctl/apache2）
mkdir -p /run/apache2
# 兼容预期的 httpd pid 路径
mkdir -p /run/httpd
ln -sf /run/apache2/apache2.pid /run/httpd/httpd.pid
apache2ctl -D FOREGROUND
