#!/bin/bash

##############
# переменные #
##############
# директория бэкапов
backup_dir="/storage/backup/mariadb"
# маска имени папок\файлов полного бэкапа
full_backup_mask="full_backup_*"
# маска файла полного бэкапа для ls
full_backup_name="full_backup_*.gz"
# маска имени папок\файлов инкрементального бэкапа
inc_backup_mask="inc_backup_*"
# время хранения в днях
days_stor_backups="7"

######################
## функции-процедуры #
######################
# функция получения даты самого старого полного бэкапа
function choose_first_full_backup {
  cd $backup_dir
  # получить список полных бэкап файлов, добавить их в массив
  for f in $(ls | grep $full_backup_name); do
    if [ -f $f ]; then
      args+=($f)
    fi
  done
  # найти файл самого старого полного бэкапа
  for (( i=0; i<"${#args[@]}"; i++ )); do
    for (( j=0; j<"${#args[@]}"; j++ )) do
      # уловие по секундам со времени создания
      if [ $(date -r ${args[i]} +"%s") -le $(date -r ${args[j]} +"%s") ]; then
        first_full_backup_file=${args[i]}
      fi
    done
  done
}

# функция удаления старых бэкапов
function clean_old {
  cd $backup_dir
  # удалить полные бэкапы старше $days_stor_backups
  find . -mtime +$days_stor_backups -daystart -name "$full_backup_mask" -exec rm -rv {} \;
  # удалить все инкрементальные бэкапы старше самого старого полного бэкапа
  find . -daystart -name "$inc_backup_mask" ! -newer $first_full_backup_file -exec rm -rv {} \;
}

########
# main #
########
choose_first_full_backup
clean_old
