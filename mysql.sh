#!/bin/bash
 #chkconfig: 35 80 15
 #description: mysql daemon
#Source function library.
. /etc/rc.d/init.d/functions
my_port={{getv "port"}}
base_dir={{getv "basedir"}}
conf_file={{getv "conf_file"}}
my_user={{getv "my_user"}}
my_sock={{getv "my_sock"}}
create_user={{getv "create_user"}}
create_password={{getv "create_password"}}
start() {
    status
    REVAL=$?
    if [ $REVAL == 1 ];then
        nohup ${base_dir}/bin/mysqld_safe --defaults-file=${conf_file} >/dev/null  2>&1 &
        sleep 3
        while(true)
        do
            status
            REVAL=$?
            if [ $REVAL == 0 ];then
                break
            else
                echo "wait mysql start"
                sleep 3
            fi       
        done
    else
        echo "mysql already running"
    fi
}
stop() {
    status
    REVAL=$?
    if [ $REVAL == 0 ];then
        ${base_dir}/bin/mysqladmin -u ${my_user} -S ${my_sock} shutdown
        sleep 3
        while(true)
        do
            status
            REVAL=$?
            if [ $REVAL == 1 ];then
                break
            else
                echo "wait mysql stop"
                sleep 3
            fi
        done
    else
        echo "mysql already stop"
    fi
}
status() {
    netstat -nltp | grep ${my_port}
    REVAL=$?
    if [ $REVAL == 0 ];then
        echo "mysql is running"
        return 0
    else
        echo "mysql is not running"
        return 1
    fi
}
init() {
    status
    REVAL=$?
    if [ $REVAL == 1 ];then
        if [ ! -d "${base_dir}/data" ]; then
            if [ ! -d "${base_dir}/tmp" ]; then
                mkdir ${base_dir}/tmp
                cd ${base_dir}
                echo "mysql begin to init"
                ${base_dir}/bin/mysqld --defaults-file=${conf_file} --initialize-insecure --user=mysql
                sleep 3
                while(true)
                do
                    if [[ -d "${base_dir}/data" && -d "${base_dir}/tmp" ]]; then
                        chown -R mysql ${base_dir}/.
                        echo "mysql has been init"
                        break
                    else
                        echo "wait mysql init"
                        sleep 3
                    fi
                done
            else
                echo "tmpdir already exists"
            fi
        else
            echo "datadir already exists"
        fi
    else
        echo "mysql already running"
    fi
}
clean() {
    status
    REVAL=$?
    if [ $REVAL == 1 ];then
        if [ ! -d "${base_dir}/data" ]; then
            echo "datadir is not exists"
        else
            if [ ! -d "${base_dir}/tmp" ]; then
                echo "tmpdir is not exists"
            else
                if [ ! -d "/data/trash" ]; then
                    mkdir /data/trash
                fi
                date=`date +"%s"`
                mv ${base_dir}/data ${base_dir}/data${date}
                mv ${base_dir}/tmp ${base_dir}/tmp${date}
                mv ${base_dir}/data${date} /data/trash/
                mv ${base_dir}/tmp${date} /data/trash/
                if [[ ! -d "${base_dir}/data" && ! -d "${base_dir}/tmp" ]]; then
                    echo "data&tmp has been moved to /data/trash , remember to clean the trash"
                fi
            fi
        fi
    else
        echo "mysql is running , can't be cleaned"
    fi
}
grant() {
    mysql -u ${my_user} -S ${my_sock} -e "create user '${create_user}'@'%' identified by '${create_password}';grant all privileges on *.* to '${create_user}'@'%' identified by '${create_password}';flush privileges;select 'grant success';"
}
case "$1" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    restart)
        stop
        start
        ;;
    status)
        status
        ;;
    init)
        init
        ;;
    clean)
        clean
        ;;
    recovery)
        stop
        clean
        init
        start
        ;;
    grant)
        grant
        ;;
    *)
        echo $"Usage: $0 {start|stop|restart|status|init|clean|recovery|grant}"
        RETVAL=2
esac
exit $RETVAL
