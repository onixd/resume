#!/bin/bash

# дата последнего редактирования 13.06.2023 14:03
# tested: alt8sp, debian11, centos7

############################
## общее описание скрипта ##
############################
# скрипт устанавливает пакеты

##############################################
## критические переменные для быстрой смены ##
##############################################
# имя скрипта нужно для запуска на удаленном хосте и для запаковки архива в скрипт, автоматически
# обновляется при изменении имени, ПЕРЕМЕННУЮ НЕ ТРОГАТЬ!!!
script_name="install_packages-0.002.sh"
# имя внутреннего архива, обновляется при перепаковке
int_arch_name="packages-0.001.tar.gz"
# каталог куда распакуется внутренний архив
int_arch_dir="archive"
# каталог системных пакетов созданных через --build
int_arch_pack_dir="$int_arch_dir/packages"
################
## переменные ##
################
# переменные внутреннего архива
PAYLOAD_LINE=$(awk '/^__PAYLOAD_BEGINS__/ { print NR + 1; exit 0; }' $0)
# файл логов
log_file="script.log"
# расположение скрипта
actual_path=$(readlink -f "${BASH_SOURCE[0]}")
script_dir=$(dirname "$actual_path")

# CentOS
# список пакетов для скачивания
# минимально необходимый набор системных пакетов
packages_system_centos=("yum-utils" "cmake" "gcc" "gcc-c++" "curl" "git" "patch" "mc" "logrotate" "htop")
# остальные пакеты
packages_main_centos=(
                     )
# Debian
# минимально необходимый набор системных пакетов
packages_system_debian=("gcc" "g++" "cpp" "curl" "git" "patch" "cmake" "dpkg-dev" "build-essential" "make" \
                        "logrotate" "apt-transport-https" "gnupg2" "mc" "net-tools" "htop")
# остальные пакеты
packages_main_debian=(
                     )
#Altlinux
# минимально необходимый набор системных пакетов
packages_system_altlinux=("python3" "openssl" "gcc" "gcc-c++" "cpp" "curl" "git" "patch" "cmake" "logrotate" \
                          "apt-https" "gnupg2" "mc" "net-tools" "libreadline7" "jq" "htop")
# остальные пакеты
packages_main_altlinux=(
                       )

#######################
## функции-процедуры ##
#######################
# определение операционной системы
function detect_os {
    # проверка на Центос
    if [ `cat /etc/os-release | grep '^ID=' | sed s/'ID='//g | awk '{print tolower($0)}' | sed 's/"//g'` == "centos" ]; then
      os="centos"
      version=`cat /etc/redhat-release | grep '^CentOS' | awk '{print $4}'`
      codename=""
    # проверка на Альт
    elif [ `cat /etc/os-release | grep '^ID=' | sed s/'ID='//g | awk '{print tolower($0)}' | sed 's/"//g'` == "altlinux" ];then
      os="altlinux"
      version=`cat /etc/os-release  | grep VERSION_ID | sed 's/VERSION_ID=//g'`
    # проверка на дебиан
    elif [ `cat /etc/os-release | grep '^ID=' | sed s/'ID='//g | awk '{print tolower($0)}' | sed 's/"//g'` == "debian" ]; then
      os="debian"
      version=`cat /etc/debian_version | awk '{print $1}'`
      codename=`cat /etc/os-release | grep '^VERSION_CODENAME' | sed s/'VERSION_CODENAME='//g`
    fi
  # имя ос
  if [ "$1" == "os" ]; then echo "$os"; fi
  # обрезка версии до первой точки
  if [ "$1" == "version" ]; then echo "$version" | sed 's/\..*//'; fi
  # кодовое имя дистрибутива
  if [ "$1" == "codename" ]; then echo "$codename"; fi
}

# функция настройки Selinux
function configure_selinux {
  # проверяем наличие конфиг файла селинукс
  if [ -f /etc/selinux/config ]; then
    # меняем значение, если переданный параметр существует
    if [ $(cat /etc/selinux/config | grep -c $1) -ne 0 ];then
      echo "Значение до изменения:"
      cat /etc/selinux/config | grep $1
      sed -i "s/$1=.*/$1=$2/" /etc/selinux/config
      echo "Значение после изменения:"
      cat /etc/selinux/config | grep $1
   else
     echo "Параметр не найден изменение невозможно"
    fi
  else
  # если не найден файл конфигурации селинукс - выдаем ошибку
    echo "Файл конфигурации Selinux не найден."
  fi
}

# установка репозиториев
function install_repo {
  case $(detect_os os) in
    centos)
      yum install -y epel-release
    ;;
    debian)
    ;;
    altlinux)
    ;;
  esac
}

# установка системных пакетов
function install_pac {
  cd $script_dir
  # онлайн режим установки
  if [ $1 == "online" ]; then
    case $(detect_os os) in
      centos)
        # основной пакет всех утилит yum, если будет дохлый не пройдет установка всех остальных пакетов
        yum install -y yum-utils
        # проверка на "битые" и прерванные установки
        yum-complete-transaction --cleanup-only
        # установка основных системных пакетов
        if [ "$2" == "system" ]; then
          for (( i=0; i<"${#packages_system_centos[@]}"; i++ )); do
            yum install -y ${packages_system_centos[i]}
          done
         # установка остальных пакетов
         elif [ "$2" == "main" ]; then
          for (( i=0; i<"${#packages_main_centos[@]}"; i++ )); do
            yum install -y ${packages_main_centos[i]}
          done
        fi
      ;;
      debian)
        apt update
        # установка основных системных пакетов
        if [ "$2" == "system" ]; then
          for (( i=0; i<"${#packages_system_debian[@]}"; i++ )); do
            apt install -y ${packages_system_debian[i]}
          done
         # установка остальных пакетов
         elif [ "$2" == "main" ]; then
          for (( i=0; i<"${#packages_main_debian[@]}"; i++ )); do
            apt install -y ${packages_main_debian[i]}
          done
        fi
      ;;
      altlinux)
        apt-get update
        # установка основных системных пакетов
        if [ "$2" == "system" ]; then
          for (( i=0; i<"${#packages_system_altlinux[@]}"; i++ )); do
            apt-get install -y ${packages_system_altlinux[i]}
          done
         # установка остальных пакетов
         elif [ "$2" == "main" ]; then
          for (( i=0; i<"${#packages_main_altlinux[@]}"; i++ )); do
            apt-get install -y ${packages_main_altlinux[i]}
          done
        fi
      ;;
    esac
   # оффлайн режим установки
   elif [ $1 == "offline" ]; then
     case $(detect_os os) in
      centos)
        rpm -ivh --replacepkgs --force $2/*
      ;;
      debian)
        dpkg -i $2/*
      ;;
      altlinux)
        apt-get install -y $2/*
      ;;
    esac
  fi
}

# создание временных директорий
function create_temp_dirs {
  cd $script_dir
  # папка внутреннего архива, сюда распакуется внутренний архив
  if [ ! -d $int_arch_dir ]; then mkdir $int_arch_dir; fi
  # папка куда скачаются все пакеты для оффлайн установки
  if [ ! -d $int_arch_dir/packages ]; then mkdir $int_arch_dir/packages; fi
}

# скачать пакеты rpm
function download_pac {
  cd $script_dir
  cd $int_arch_pack_dir
  case $(detect_os os) in
    centos)
      yum --enablerepo=base clean metadata
      # системные пакеты
      for (( i=0; i<"${#packages_system_centos[@]}"; i++ )); do
        repotrack -a x86_64 "${packages_system_centos[i]}"
      done
      # все основные пакеты
      for (( i=0; i<"${#packages_main_centos[@]}"; i++ )); do
        repotrack -a x86_64 "${packages_main_centos[i]}"
      done
    ;;
    debian)
      # системные пакеты
      apt update
      for (( i=0; i<"${#packages_system_debian[@]}"; i++ )); do
        apt install -y -d --reinstall ${packages_system_debian[i]}
      done
      for (( i=0; i<"${#packages_main_debian[@]}"; i++ )); do
        apt install -y -d --reinstall ${packages_main_debian[i]}
      done
        cp /var/cache/apt/archives/*.deb $PWD/
# этот вариант не скачивает все зависимости зависимостей
#      for (( i=0; i<"${#packages_system_debian[@]}"; i++ )); do
#        "pkgdownload.sh" "${packages_system_debian[i]}"
#      done
#      # все основные пакеты
#      for (( i=0; i<"${#packages_main_debian[@]}"; i++ )); do
#        "pkgdownload.sh" "${packages_main_debian[i]}"
#      done
# после последнего обновления этот вариант не работает
#        apt-offline set offline.sig --install-packages ${packages_system_debian[@]} ${packages_main_debian[@]}
#        apt-offline get offline.sig --no-checksum -d ''
    ;;
    altlinux)
      # системные пакеты
      apt-get update
      for (( i=0; i<"${#packages_system_altlinux[@]}"; i++ )); do
        apt-get install -y -d ${packages_system_altlinux[i]}
      done
      for (( i=0; i<"${#packages_main_altlinux[@]}"; i++ )); do
        apt-get install -y -d ${packages_main_altlinux[i]}
      done
        cp /var/cache/apt/archives/*.rpm $PWD/
    ;;
  esac
}

# создание архива для включения в скрипт оффлайн установки
function create_arсhive {
  cd $script_dir
  tar -zcvf $int_arch_name -C $1 $(ls -A $1) --remove-files
  rm -rf $1
}

# распаковка внутреннего архива
function extract_archive {
  # распаковать в каталог
  if [ $1 == "dir" ]; then
    echo "распаковка внутреннего архива в $2">> $log_file
    mkdir -p $2
    tail -n +${PAYLOAD_LINE} $0 | base64 -d | tar -xzf - --directory="$2"
   # скопировать внутренний архив рядом со скриптом
   elif [ $1 == "asis" ]; then
    echo "копирование внутреннего архива в каталог со скриптом">> $log_file
    tail -n +${PAYLOAD_LINE} $0 | base64 -d > $int_arch_name
  fi
  if [ "$?" != "0" ]; then
    echo "ошибка установки, архив внутренних ресурсов поврежден" >> $log_file
    clear_temp
    exit
  fi
}

# врезать в скрипт внешний архив
function pack_archive {
# удалить всё что после payload
  sed -i '/^__PAYLOAD_BEGINS__$/q' $script_name
  echo -n "Packing archive \"$1\" into script \"${script_name}\" "
  if [ x${script_name} != x$1 ]; then
    # вставить архив в скрипт
    base64 $1 >> $script_name
    # обновить информацию об имени архива в переменную
    sed -i 's/^int_arch_name=.*$/int_arch_name="'$1'"/g' $script_name
  fi
}

# удалить из скрипта архив
function null_archive {
  # удалить всё что после payload
  sed -i '/^__PAYLOAD_BEGINS__$/q' $script_name
}

# удаление временных каталогов
function clear_temp {
  cd $script_dir
  rm -rf $int_arch_dir &> /dev/null
  rm -rf $int_arch_name &> /dev/null
}

# удаление пробелов из строки
function string_no_space {
  no_space=`echo -e $@ | sed -e 's/ //g'`
  # вывод функции
  echo $no_space
}

# все возможные варианты элементов массива
function mix_array {
  # блок инициации массива переданного в функцию, по другому дурацкий баш не передает
  # длина массива
  newvar="${1}"
  shift
  # все элементы массива
  newarray=("${@}")
  # задание пустого массива куда складируются все варианты
  list=()
  for (( i=0; i<$newvar; i++ )); do
    list+=(${newarray[i]})
    for (( j=0; j<$newvar; j++ )); do
      if [ $i -ne $j ]; then
        list+=(${newarray[j]})
      fi
    done
  done
  # вывод функции
  echo ${list[*]}
}

# описание послеустановочных действий
function description_postinstall {
  echo "-----------------------------------------------------
-----------------------------------------------------------"
}

# описание режимов работы скрипта, выводит при "пустом" запуске
function show_description {
  echo "ключи -e(--extract) -p(--pack) -b(--build) -n(--null)
              -i(--install) -off(--offline) -on(--online)

----совместный блок-------
"-i/--install"               - установить пакеты в online/offline режиме
вместе
"-off/--offline"             - установка оффлайн (необходимо собрать скрипт с ключем -b/--build)
или
"-on/--online"               - установка онлайн (собирать с ключем -b/--build не надо)
""
--------------------------

"-e/--extract"               - скопировать внутренний архив рядом со скриптом;
"-p/--pack имя_архива"       - запаковать архив в скрипт - архив создавать без абсолютных каталогов:
                               tar -czvf urs-install.tgz -C archive \$(ls -A archive);
"-d/--dir путь/имя_каталога" - совместно с -p/--pack или -e/--extract, сжать\распаковать каталог в\из архива;
"-b/--build"                 - скачать все пакеты, и модули, и упаковать в скрипт для оффлайн установки;
"-n/--null"                  - удалить внутренний архив из скрипта;

# Установить пакеты онлайн
Пример использования: $0 -i -on
# Установить пакеты оффлайн
Пример использования: $0 -i -off
# Скопировать внутренний архив рядом со скриптом не распаковывая в папку
Пример использования: $0 --extract
# Запаковать архив в скрипт
Пример использования: $0 --pack <service>-offline.tgz
# Сжать каталог и запаковать архив в скрипт
Пример использования: $0 --pack -d <имя каталога>
# Распаковать внутренний архив рядом со скриптом в каталог
Пример использования: $0 -e -d archive
# Собрать все пакеты для установки оффлайн сервиса
Пример использования: $0 --build
# Удалить внутренний архив из скрипта
Пример использования: $0 --null
"
}

########
# main #
########

# временный костыль, без перезапуска не обновляет переменную
if [ `echo $0 | sed 's/\\.\\///g'` != $script_name ]; then
  # обновление имени скрипта в переменной script_name вверху скрипта
  sed -i "s|^script_name=.*$|script_name=\"$0\"|g ; s/\"\\.\\//\"/g" $0
  echo "скрипт был переименован, запустите ещё раз"
  exit
fi

# пустой запуск
if [ "$1" == "" ]; then show_description; exit; fi

# перебор ключей запуска
while (($#)); do
 arg=$1
  shift
   case $arg in
     # для двойных ключей с --
     --*) case ${arg:2} in
           # установка
           install)   key_install="install";;
           # онлайн установка
           online)    key_online="online";;
           # оффлайн установка
           offline)   key_offline="offline";;
           # сборка внутреннего архива для оффлайн установки
           build)     key_build="build";;
           # удалить внутренний архив (слишком большой для редактирования скрипта)
           null)      key_null="null";;
           # скопировать архив рядом со скриптом не распаковывая его
           extract)   key_extract="extract";;
           # запаковать внешний архив в скрипт
           pack)      key_pack="pack"; key_p_arg=$1;;
           # сделать архив и запаковать в скрипт из директории
           dir)       key_dir="dir"; key_d_arg=$1;;
           # тестирование одиночных функций
           test)      key_test="test";;
           # все остальные ключи неправильные
           *)         echo "неправильный двойной ключ запуска";;
          esac;;

     # для одинарных ключей с -
     -*) case ${arg:1} in
          # установка
          i)    key_i="i";;
          # онлайн установка
          on)   key_on="on";;
          # оффлайн установка
          off)  key_off="off";;
          # сборка внутреннего архива для оффлайн установки
          b)    key_b="b";;
          # удалить внутренний архив (слишком большой для редактирования скрипта)
          n)    key_n="n";;
          # скопировать архив рядом со скриптом не распаковывая его
          e)    key_e="e";;
          # запаковать внешний архив в скрипт
          p)    key_p="p"; key_p_arg=$1;;
          # сделать архив и запаковать в скрипт из директории
          d)    key_d="d"; key_d_arg=$1;;
          # для тестирования отдельных функций
          t)    key_t="t";;
          # все остальные ключи неправильные
          *)    echo "неправильный одинарный ключ запуска";;
         esac;;
    esac
done

# массив ключей установки, все варианты ключей, при добалении нового ключа - дописать его СЮДА!
key_all=($key_i $key_install \
         $key_on $key_online \
         $key_off $key_offline \
         $key_b $key_build \
         $key_n $key_null \
         $key_e $key_extract \
         $key_p $key_pack \
         $key_d $key_dir \
         $key_t $key_test)
# все варианты, в перемешку, поступивших ключей
key_all_mix=$(mix_array ${#key_all[@]} ${key_all[@]})
# все ключи в кучу без пробелов
key_all_no_space=$(string_no_space ${key_all_mix[@]})

# выборка вариантов совместных ключей
case $key_all_no_space in
  # онлайн установка
  i*on*       ) # установить системные пакеты
                install_pac online system;
                # установить репозитории
                install_repo;
                # установить основную кучу пакетов
                install_pac online main;
                # удалить временные каталоги, показать инструкции после установки
                clear_temp; description_postinstall;;
  # оффлайн установка
  i*off*      ) # распаковать внутренний архив
                extract_archive dir $int_arch_dir;
                # установить пакеты оффлайн
                install_pac offline $int_arch_pack_dir;
                # удалить временные каталоги, показать инструкции после установки
                clear_temp; description_postinstall;;
  # сборка внутреннего архива для оффлайн установки
  *b*         ) # создать временные каталоги
                create_temp_dirs;
                # установить системные пакеты
                install_pac online system;
                # установить репозитории
                install_repo;
                # установить основную кучу пакетов
                install_pac online main;
                # скачать установщики пакетов
                download_pac;
                # создать внутренний архив
                create_arсhive $int_arch_dir;
                # запаковать внутренний архив в скрипт
                pack_archive $int_arch_name;
                # удалить временные каталоги
                clear_temp;;
  # удалить внутренний архив (слишком большой для редактирования скрипта)
  n*          ) null_archive;;
  # скопировать архив рядом со скриптом не распаковывая его
  e|extract   ) extract_archive asis;;
  # распаковать архив в папку
  e*d*        ) extract_archive dir $key_d_arg;;
  # запаковать архив в скрипт
  p|pack      ) pack_archive $key_p_arg;;
  # запаковать папку в архив и включить в скрипт
  p*d*        ) create_arсhive $key_d_arg; pack_archive $int_arch_name; clear_temp;;
  # test function (раздел для тестирования одиночных функций)
  t*          ) ;;
  # пустая строка
  ""          ) show_description;;
  *           ) echo "неправильное сочетание ключей";;
esac

exit 0
__PAYLOAD_BEGINS__
