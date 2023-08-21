#!/bin/bash

##############
# переменные #
##############
# директория бэкапов
backup_dir="/root/backup"
# маска имени полного бэкапа
name_full_backup="full_backup"
# пользователь mariadb
mariadb_user="root"
# пароль mariadb
mariadb_password="MySQLP1"
# имя папок содержащих точки с которых будет идти бэкап
inc_xtrabackup_checkpoints="inc_backup_$(date +%d.%m.%Y-%H:%M)"
# имя архива бэкапов
gzip_name="inc_backup_$(date +%d.%m.%Y-%H:%M).gz"

######################
## функции-процедуры #
######################
# функция проверки запущенного сервиса mariadb
function check_service {
  if [[ $(systemctl show --property=ActiveState mariadb) == 'ActiveState=inactive' ]]; then
    echo 'please start service mariadb!!!'
    exit
  fi
}

# функция выбора последнего полного бэкапа
function choose_last_full_backup {
  cd $backup_dir
  # получить список полных бэкап директорий и добавить их в массив
  for d in $(ls -1d */ | grep $name_full_backup | sed 's:/$::'); do
    args+=($d)
  done
  # найти директорию последнего полного бэкапа
  for (( i=0; i<"${#args[@]}"; i++ )); do
    for (( j=0; j<"${#args[@]}"; j++ )) do
      # уловие по секундам со времени создания
      if [ $(date -r ${args[i]} +"%s") -ge $(date -r ${args[j]} +"%s") ]; then
        full_xtrabackup_checkpoints=${args[i]}
      fi
    done
  done
}

# функция проверки на наличие директорий полного бэкапа
function check_dirs_exists {
  cd $backup_dir
  # есть ли директории бэкапа
  if [ ! $(ls -1d */ 2>&1 | grep $name_full_backup | sed 's:/$::') ]; then
    echo 'directories full backup doesn`t exists'
    exit
  fi
}

# фуннкция бэкапа
function backup {
  cd $backup_dir
  mariabackup --backup --stream=mbstream \
              --user=$mariadb_user --password=$mariadb_password \
              --incremental-basedir=$full_xtrabackup_checkpoints \
              --extra-lsndir=$inc_xtrabackup_checkpoints | gzip > $gzip_name
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
check_dirs_exists
choose_last_full_backup
backup
