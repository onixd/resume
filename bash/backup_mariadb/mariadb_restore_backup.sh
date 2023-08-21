#!/bin/bash

##############
# переменные #
##############
# директория бэкапов
backup_dir="/root/backup"
# маска имени полного бэкапа
name_full_backup="full_backup"
# файл бэкапа
backup_file="$2"
# временный каталог распаковки полного бэкапа
extract_dir_full="extract_full"
# временный каталог распаковки инкрементального бэкапа
extract_dir_inc="extract_inc"
# имя временного файла распаковки
extract_name="${backup_file}_extract"
# каталог баз mysql
mysql_db_dir=`cat /etc/my.cnf | grep datadir | sed 's/datadir = //g'`
# каталог бэкапов каталогов совместимости
# в Альт8СП в каталоге с базами находятся доп. каталоги с билиотеками
# при init всех баз каталоги дохнут и mariadb не стартует
extra_dirs="extra_dirs"

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

# функция проверки сервиса mariadb
function check_service {
  if [[ $(systemctl show --property=ActiveState mariadb) == 'ActiveState=active' ]]; then
    echo 'остановите сервис mariadb!'
    exit
  fi
}

# функция подготовки системы для восстановления бэкапа
function clean_db {
  if [ "$1" == "full" ]; then
    # при восстановлении полного бэкапа очистить каталог баз
    rm -rf $mysql_db_dir/*
    echo "очистка папки $mysql_db_dir"
   elif [ "$1" == "incremental" ]; then
    # при восстановлении полного бэкапа очистить каталог баз
    rm -rf $mysql_db_dir/*
    echo "очистка папки $mysql_db_dir"
  fi
}

# функция создания временных каталогов разорхивации
function create_dirs {
  if [ "$1" == "full" ]; then
    # создать временный каталог куда разорхивируется полный бэкап
    mkdir -p $backup_dir/$extract_dir_full
    echo "создание временного каталога $backup_dir/$extract_dir_full"
   elif [ "$1" == "incremental" ]; then
     # создать временный каталог куда разорхивируется полный бэкап
     mkdir -p $backup_dir/$extract_dir_full
     # создать временный каталог куда разорхивируется инкрементальный бэкап
     mkdir -p $backup_dir/$extract_dir_inc
     echo "создание временного каталога $backup_dir/$extract_dir_inc"
  fi
}

# функция распаковки бэкапа
function extract_backup {
  cd $backup_dir
  # полный бэкап
  if [ "$1" == "full" ]; then
    # разархивировать полный бэкап
    gunzip -c $backup_file > $extract_dir_full/$extract_name
    cat $extract_dir_full/$extract_name | mbstream -x --directory=$extract_dir_full
    # удалить лишнее после распаковки
    rm -rf $extract_dir_full/$extract_name
    echo "разархивирование полного бэкапа в $extract_dir_full"
   # инкрементальный бэкап
   elif [ "$1" == "incremental" ]; then
    # разархивировать инкрементальный бэкап
    gunzip -c $backup_file > $extract_dir_inc/$extract_name
    cat $extract_dir_inc/$extract_name | mbstream -x --directory=$extract_dir_inc
    # удалить лишнее после распаковки
    rm -rf $extract_dir_inc/$extract_name
    echo "разархивирование инкрементального бэкапа $backup_file в $extract_dir_inc"

    # выбрать полный бэкап для данного инкрементального
    choose_last_full_backup

    # разархивировать полный для данного инкрементального
    gunzip -c ${backup_dir_full}.gz > $extract_dir_full/$extract_name
    cat $extract_dir_full/$extract_name | mbstream -x --directory=$extract_dir_full
    # удалить лишнее после распаковки
    rm -rf $extract_dir_full/$extract_name
    echo "разархивирование полного бэкапа ${backup_dir_full}.gz в $extract_dir_full"
  fi
}

# функция выбора последнего полного бэкапа для восстанавливаемого инкрементального
function choose_last_full_backup {
  cd $backup_dir
  # получить список полных бэкап директорий, отсортировать по времени и добавить их в массив
  for d in $(ls -1d */ | grep $name_full_backup | sed 's:/$::' | sort -n); do
    args+=($d)
  done
  # найти директорию последнего полного бэкапа для данного инкрементального
  for (( i=0; i<"${#args[@]}"; i++ )); do
    # уловие по секундам со времени создания
    # если дата полного меньше или равно даты инкрементального
    if [ $(date -r ${args[i]} +"%s") -le $(date -r $backup_file +"%s") ]; then
      backup_dir_full=${args[i]}
    fi
  done
}

# функция подготовки бэкапа, с мурзилки:
# The data files that Mariabackup creates in the target directory are not point-in-time consistent,
# given that the data files are copied at different times during the backup operation. If you try to
# restore from these files, InnoDB notices the inconsistencies and crashes to protect you from corruption
function prepare_backup {
  cd $backup_dir
  if [ "$1" == "full" ]; then
    # подготовка полного бэкапа
    mariabackup --prepare \
                --target-dir=$extract_dir_full
   elif [ "$1" == "incremental" ]; then
    # подготовка полного бэкапа
    mariabackup --prepare \
                --target-dir=$extract_dir_full
    # подготовка икрементального бэкапа
    mariabackup --prepare \
                --target-dir=$extract_dir_full \
                --incremental-dir=$extract_dir_inc
  fi
}

# функция восстановления из бэкапа
function restore_backup {
  cd $backup_dir
  if [ "$1" == "full" ]; then
    mariabackup --copy-back --force-non-empty-directories \
                --target-dir=$extract_dir_full
   elif [ "$1" == "incremental" ]; then
    mariabackup --copy-back --force-non-empty-directories \
                --target-dir=$extract_dir_full
  fi
}

# функция прав
function assign_rights {
  chown -R mysql:mysql $mysql_db_dir
}

# фукция восстановления дополнительных каталогов
function restore_extra_dirs {
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
          cp -r $backup_dir/$extra_dirs/$(detect_os os)/$(detect_os version)/* $mysql_db_dir
        ;;
      esac
    ;;
  esac

}

# функция очистки временных каталогов
function clear_temp {
  cd $backup_dir
  # удалить временные каталоги распаковки
  rm -rf $extract_dir_full
  rm -rf $extract_dir_inc
}

# описание режимов работы скрипта, выводит при "пустом" запуске
function show_description {
  echo "$0 full\incremental <имя_бэкапа_полного\инкрементального.gz>
БАЗА С ПАПКИ $mysql_db_dir БУДЕТ ПОЛНОСТЬЮ УДАЛЕНА!!!
Пример использования: $0 full full_backup_27.07.2023-11:31.gz
Пример использования: $0 incremental inc_backup_27.07.2023-11:31.gz"
}

########
# main #
########

# проверки ключей запуска
# пустой запуск
if [ "$1" == "" ]; then show_description; exit; fi
# проверка на ключи full\incremental
if [ "$1" != "full" ] && [ "$1" != "incremental" ]; then echo 'укажите тип бэкапа full\incremental'; exit; fi
# проверка указания файла
if [ "$2" == "" ]; then echo 'укажите файл бэкапа'; exit; fi
# проверка наличия файла бэкапа
if [ ! -f $2 ]; then echo 'нет такого файла бэкапа'; exit; fi

check_service
clean_db $1
create_dirs $1
extract_backup $1
prepare_backup $1
restore_backup $1
restore_extra_dirs
assign_rights
clear_temp
