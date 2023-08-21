#!/bin/bash

##############
# переменные #
##############
# директория бэкапов
backup_dir="/root/backup"
# пользователь mariadb
mariadb_user="root"
# пароль mariadb
mariadb_password="MySQL1"
# имя папок содержащих точки с которых будет идти бэкап
full_xtrabackup_checkpoints="full_backup_$(date +%d.%m.%Y-%H:%M)"
# имя архива бэкапов
gzip_name="full_backup_$(date +%d.%m.%Y-%H:%M).gz"
# каталог бэкапов каталогов совместимости
extra_dirs="extra_dirs"
# каталог баз mysql
mysql_db_dir="/var/lib/mysql"

# список каталогов совместимости
#Altlinux
extra_dirs_list_altlinux=("db" "dev" "etc" "lib64" "run" "tmp" "usr" "var")

######################
## функции-процедуры #
######################
# определение операционной системы
function detect_os {
    # проверка на Центос
    if [ `cat /etc/os-release | grep '^ID=' | sed s/'ID='//g | awk '{print tolower($0)}' | sed 's/"//g'` == "centos" ]; then
      os="centos"
      version=`cat /etc/redhat-release | grep '^CentOS' | awk '{print $4}'`
      codename=""
    # проверка на Редос
    elif [ `cat /etc/os-release | grep '^ID=' | sed s/'ID='//g | awk '{print tolower($0)}' | sed 's/"//g'` == "redos" ]; then
      os="redos"
      version=`cat /etc/os-release  | grep VERSION_ID | sed 's/VERSION_ID=//g' | sed 's/["]//g'`
      codename=""
    # проверка на Альт
    elif [ `cat /etc/os-release | grep '^ID=' | sed s/'ID='//g | awk '{print tolower($0)}' | sed 's/"//g'` == "altlinux" ];then
      os="altlinux"
      version=`cat /etc/os-release  |grep VERSION_ID |sed 's/VERSION_ID=//g'`
    # проверка на дебиан
    elif [ `cat /etc/os-release | grep '^ID=' | sed s/'ID='//g | awk '{print tolower($0)}' | sed 's/"//g'` == "debian" ]; then
      os="debian"
      version=`cat /etc/debian_version | awk '{print $1}'`
      codename=`cat /etc/os-release | grep '^VERSION_CODENAME' | sed s/'VERSION_CODENAME='//g`
    elif [ `cat /etc/os-release | grep '^ID=' | sed s/'ID='//g | awk '{print tolower($0)}' | sed 's/"//g'` == "astra" ]; then
       os="astra"
       version=`cat /etc/debian_version | awk '{print $1}'`
       codename=`cat /etc/os-release | grep '^VERSION_CODENAME' | sed s/'VERSION_CODENAME='//g`
    fi
  # имя ос
  if [ "$1" == "os" ]; then echo "$os"; fi
  # обрезка до мажорной версии
  if [ "$1" == "version" ]; then echo "$version" | sed 's/\..*//'; fi
  # обрезка до минорной версии
#  if [ "$1" == "version" ]; then echo "$version" | grep -Eo '[0-9]\.[0-9]+'; fi
  # кодовое имя дистрибутива
  if [ "$1" == "codename" ]; then echo "$codename"; fi
}

# функция проверки запущенного сервиса mariadb
function check_service {
  if [[ $(systemctl show --property=ActiveState mariadb) == 'ActiveState=inactive' ]]; then
    echo 'please start service mariadb!!!'
    exit
  fi
}

# бэкап дополнительных каталогов
function backup_extra_dirs {
  case $(detect_os os) in
    centos)
    ;;
    redos)
    ;;
    debian)
    ;;
    astra)
    ;;
    altlinux)
      case $(detect_os version) in
        8)
          if [ ! -d $backup_dir/$extra_dirs/$(detect_os os)/$(detect_os version) ]; then mkdir -p $backup_dir/$extra_dirs/$(detect_os os)/$(detect_os version); fi
          for (( i=0; i<"${#extra_dirs_list_altlinux[@]}"; i++ )); do
            # скопировать каталоги с папки БД mysql в папку бэкапов, если каталоги есть копировать не будет!!!
            # на случай если удалят случайно на рабочей базе эти каталоги
            if [ ! -d $backup_dir/$extra_dirs/$(detect_os os)/$(detect_os version)/${extra_dirs_list_altlinux[i]} ]; then
              cp -r $mysql_db_dir/${extra_dirs_list_altlinux[i]} $backup_dir/$extra_dirs/$(detect_os os)/$(detect_os version)
            fi
          done
        ;;
      esac
    ;;
  esac
}

# фуннкция бэкапа
function backup {
  cd $backup_dir
  mariabackup --backup --stream=mbstream --user=$mariadb_user --password=$mariadb_password \
              --extra-lsndir=$full_xtrabackup_checkpoints | gzip > $gzip_name
}

# функция проверки устаноленного пакета mariadb-backup
function check_pac_mariadb_backup {
  if [ ! $(mariabackup -v 2>&1 | grep -Eo '[0-9][0-9]\.[0-9]\.[0-9]+') ]; then
    echo 'please install package mariadb-backup'
  fi
}

########
# main #
########
check_service
check_pac_mariadb_backup
backup_extra_dirs
backup
