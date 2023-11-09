#!/bin/bash

# дата последнего редактирования 17.01.2023 09:11
# tested: centOS7, debian11

##########################
# общее описание скрипта #
##########################
# скрипт устанавливает pve(python virtual enviroment), набор модулей питона для работы других сервисов
# 2 варианта установки:
# - набор модулей minimal
# - набор модулей full

############################################
# критические переменные для быстрой смены #
############################################
# расположение скрипта
actual_path=$(readlink -f "${BASH_SOURCE[0]}")
script_dir=$(dirname "$actual_path")
# имя скрипта нужно для запуска на удаленном хосте и для запаковки архива в скрипт, автоматически
# обновляется при изменении имени
script_name="pve-1.031-universal.sh"
# имя сервиса
service_name=""
# каталог установки сервиса
service_install_dir="/opt/pve"
# папка куда установится pve для сервиса
service_pve_install_dir="/opt/pve"
# каталог куда распакуется внутренний архив
int_arch_dir="$script_dir/archive"
# имя внутреннего архива, обновляется при перепаковке
int_arch_name="pve_offline.tgz"
# каталог системных пакетов созданных через --build
int_arch_pack_dir="$int_arch_dir/packages"
# каталог исходников
int_arch_src_dir="$int_arch_dir/src"
# версия питона для установки
# CentOS
python_ver_centos="3.9.16"
# RedOS
python_ver_redos="3.9.16"
# Debian
python_ver_debian="3.9.16"
# Ubuntu
python_ver_ubuntu="3.9.16"
# Astra
python_ver_astra="3.9.16"
# AltLinux
python_ver_altlinux="3.9.16"
##############
# переменные #
##############
# переменные внутреннего архива
PAYLOAD_LINE=$(awk '/^__PAYLOAD_BEGINS__/ { print NR + 1; exit 0; }' $0)
# файл логов
log_file="$script_dir/script.log"
# временная папка
temp_dir="$script_dir/temp"
# внешний файл списка модулей pip3
list_pip3_modules_ext="$script_dir/freeze.txt"

# CentOS
# список пакетов для скачивания
# минимально необходимый набор системных пакетов
packages_system_centos=("yum-utils" "cmake" "gcc" "gcc-c++" "curl" "git" "patch" "mc" "wget")
# остальные пакеты
packages_main_centos=("python3-pip" "python3-devel" "libsndfile" "python3-wheel" "python3-virtualenv" \
                      "rustc" "cargo" "openssl" "openssl-devel" "libffi" \
                      "libffi-devel" "zlib" "zlib-devel" "bzip2" "bzip2-devel" "libxml2" "libxml2-devel" \
                      "xmlsec1" "xmlsec1-openssl" "readline" "readline-devel" "sqlite" "sqlite-devel" \
                      "xz" "xz-devel" "ffmpeg" "ffmpeg-devel" "sox" "jq")
# RedOS
# минимально необходимый набор системных пакетов
packages_system_redos=("yum-utils" "cmake" "gcc" "gcc-c++" "curl" "git" "patch" "mc" "wget")
# остальные пакеты
packages_main_redos=("python3-pip" "python3-devel" "libsndfile" "python3-wheel" "python3-virtualenv" \
                      "rustc" "cargo" "openssl" "openssl-devel" "libffi" \
                      "libffi-devel" "zlib" "zlib-devel" "bzip2" "bzip2-devel" "libxml2" "libxml2-devel" \
                      "xmlsec1" "xmlsec1-openssl" "readline" "readline-devel" "sqlite" "sqlite-devel" \
                      "xz" "xz-devel" "ffmpeg" "ffmpeg-devel" "sox" "jq")
# Debian
# минимально необходимый набор системных пакетов
packages_system_debian=("gcc" "g++" "gcc-c++" "cpp" "curl" "git" "patch" "cmake" "build-essential" \
                        "apt-transport-https" "gnupg2" "mc" "net-tools")
# остальные пакеты
packages_main_debian=("python3-pip" "python3-dev" "libsndfile1" "python3-wheel" "python3-venv" \
                      "rustc" "cargo" "openssl" "libssl-dev" \
                      "libffi-dev" "zlib1g" "zlib1g-dev" "bzip2" "libbz2-dev" "libxml2" "libxml2-dev" \
                      "xmlsec1" "libxmlsec1-dev" "readline-common" "libreadline-dev" "sqlite3" \
                      "libsqlite3-dev" "xz-utils" "lzma" "liblzma-dev" \
                      "ffmpeg" "jq")
# Ubuntu
# минимально необходимый набор системных пакетов
packages_system_ubuntu=("gcc" "g++" "gcc-c++" "cpp" "curl" "git" "patch" "cmake" "build-essential" \
                        "apt-transport-https" "gnupg2" "mc" "net-tools")
# остальные пакеты
packages_main_ubuntu=("python3-pip" "python3-dev" "libsndfile1" "python3-wheel" "python3-venv" \
                      "rustc" "cargo" "openssl" "libssl-dev" \
                      "libffi-dev" "zlib1g" "zlib1g-dev" "bzip2" "libbz2-dev" "libxml2" "libxml2-dev" \
                      "xmlsec1" "libxmlsec1-dev" "readline-common" "libreadline-dev" "sqlite3" \
                      "libsqlite3-dev" "xz-utils" "lzma" "liblzma-dev" \
                      "ffmpeg" "jq")
# Astra
# минимально необходимый набор системных пакетов
packages_system_astra=("gcc" "g++" "cpp" "curl" "git" "patch" "cmake" "build-essential" \
                      "apt-transport-https" "gnupg2" "mc" "net-tools")
# остальные пакеты
packages_main_astra=("python3-pip" "python3-dev" "libsndfile1" "python3-wheel" "python3-venv" \
                     "rustc" "cargo" "openssl" "libssl-dev" \
                     "libffi-dev" "zlib1g" "zlib1g-dev" "bzip2" "libbz2-dev" "libxml2" "libxml2-dev" \
                     "xmlsec1" "libxmlsec1-dev" "readline-common" "libreadline-dev" "sqlite3" \
                     "libsqlite3-dev" "xz-utils" "lzma" "liblzma-dev" \
                     "ffmpeg" "jq")
#Altlinux
# минимально необходимый набор системных пакетов
packages_system_altlinux=("python3" "openssl" "gcc" "gcc-c++" "cpp" "curl" "git" "patch" "cmake" \
                          "build-essential" "apt-https" "gnupg2" "mc" "net-tools" "libreadline7" "jq")
# остальные пакеты
packages_main_altlinux=("python3-module-pip" "python3-dev" "libsndfile1" "python3-wheel" "python3-venv" \
                        "rustc" "cargo" "openssl" "libssl-devel" \
                        "libffi-devel" "zlib1g" "zlib1g-devel" "zlib-devel" "bzip2" "libbz2-dev" "libxml2" "libxml2-dev" \
                        "xmlsec1" "libxmlsec1-devel" "readline-common" "libreadline-devel" "libreadline-devel-static " "sqlite3" \
                        "libsqlite3-devel" "xz-utils" "lzma" "liblzma-devel" "libstdc++-devel-static" \
                        "bzip2-devel" \
                        "ffmpeg")
# список модулей pip3
# модули для сервисов
modules_pip3_full=("torchvision" "nemo-toolkit==1.18.1" "torchaudio==2.0.2" "Flask==2.1.0" \
                   "flask-restplus==0.13.0" "Werkzeug==2.0.2" "librosa==0.10.0" "pydub==0.25.1" \
                   "hydra-core==1.2.0" "pytorch-lightning==1.9.4" "braceexpand==0.1.7" "webdataset==0.1.62" \
                   "transformers==4.33.3" "packaging==21.0" "pandas==2.0.1" "sentencepiece==0.1.99" \
                   "inflect==6.0.4" "pyannote.core==5.0.0" "pyannote.database==5.0.1" \
                   "pyannote.metrics==3.2.1" "editdistance==0.6.2" "jiwer==3.0.1" "ipython==8.13.2" \
                   "onnxruntime-gpu" "seaborn" "gunicorn" "cython" "youtokentome==1.0.3" "einops" \
                   "wandb" "gevent" "pymorphy2" "PyJWT" "progressbar2" "webrtcvad" "pydantic==1.10.2" \
                   "torchmetrics==0.11.1")
# модули для сервисов на прод
modules_pip3_minimal=("pip" "setuptools" "Cython" "gunicorn"  "pyinstaller" "wheel" \
                      "Flask==2.1.0" "flask-restplus==0.13.0" "onnxruntime-gpu" "Werkzeug==2.0.2" "requests" "gevent" "pymorphy2" "PyJWT" "progressbar2" "webrtcvad" "pydantic==1.10.2" "torchmetrics==0.11.1")

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
    elif [ `cat /etc/os-release | grep '^ID=' | sed s/'ID='//g | awk '{print tolower($0)}' | sed 's/"//g'` == "ubuntu" ]; then
      os="ubuntu"
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

# системные твики
function configure_system {
  case $(detect_os os) in
    centos)
    ;;
    redos)
    ;;
    debian)
      # по версии дебиана
      case $(detect_os version) in
        11)
          # apt удаляет из кэша скачанные пакеты, отключить
          echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/01keep-debs
        ;;
        12)
          # apt удаляет из кэша скачанные пакеты, отключить
          echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/01keep-debs
        ;;
      esac
    ;;
    ubuntu)
      # apt удаляет из кэша скачанные пакеты, отключить
      echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/01keep-debs
      # запрос на рестарт сервисов = автоматически
      sed -i "s|\x23\x24nrconf\x7Brestart\x7D = 'i';|\x24nrconf\x7Brestart\x7D = 'a';|g" /etc/needrestart/needrestart.conf
    ;;
    altlinux)
    ;;
    astra)
      # apt удаляет из кэша скачанные пакеты, отключить
      echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/01keep-debs
    ;;
  esac 
}

# установка репозиториев
function install_repo {
  case $(detect_os os) in
    centos)
     yum install -y epel-release
     # пакет основных утилит ставится заранее перед скачиванием пакетов через repotrack
     yum install -y yum-utils
     # ffmpeg репозиторий, содержащий ffmpeg 3,2 версии.
     yum localinstall -y --nogpgcheck https://download1.rpmfusion.org/free/el/rpmfusion-free-release-7.noarch.rpm
     # обновление списка пакетов после добавления репы
     yum update -y
    ;;
    redos)
    ;;
    debian)
    ;;
    ubuntu)
    ;;
    astra)
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
        # обновление openssl
        # если openssl в системе меньше 1.1.1
        if [ `openssl version | grep -Eo '[0-9]\.[0-9]+\.[0-9]+'` != "1.1.1" ]; then
          # скачать последние исходники
          wget https://www.openssl.org/source/openssl-1.1.1u.tar.gz
          # распаковать
          tar -xvf openssl-*.tar.gz && rm -f openssl-*.tar.gz
          # перейти в распакованный каталог
          cd openssl-*
          # сконфигурировать
          ./config --prefix=/usr --openssldir=/usr
          # скомпилить
          make
          # установить
          make install
          # удалить папку
          cd ..
          rm -rf openssl-*
        fi        
      ;;
      redos)
        # основной пакет всех утилит yum, если будет дохлый не пройдет установка всех остальных пакетов
        yum install -y yum-utils
        # установка основных системных пакетов
        if [ "$2" == "system" ]; then
          for (( i=0; i<"${#packages_system_redos[@]}"; i++ )); do
            yum install -y ${packages_system_redos[i]}
          done
        # установка остальных пакетов
         elif [ "$2" == "main" ]; then
          for (( i=0; i<"${#packages_main_redos[@]}"; i++ )); do
            yum install -y ${packages_main_redos[i]}
          done
        fi
        # обновление openssl
        # если openssl в системе меньше 1.1.1
        if [ `openssl version | grep -Eo '[0-9]\.[0-9]+\.[0-9]+'` != "1.1.1" ]; then
          # скачать последние исходники
          wget https://www.openssl.org/source/openssl-1.1.1u.tar.gz
          # распаковать
          tar -xvf openssl-*.tar.gz && rm -f openssl-*.tar.gz
          # перейти в распакованный каталог
          cd openssl-*
          # сконфигурировать
          ./config --prefix=/usr --openssldir=/usr
          # скомпилить
          make
          # установить
          make install
          # удалить папку
          cd ..
          rm -rf openssl-*
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
      ubuntu)
        apt update
        # установка основных системных пакетов
        if [ "$2" == "system" ]; then
          for (( i=0; i<"${#packages_system_ubuntu[@]}"; i++ )); do
            apt install -y ${packages_system_ubuntu[i]}
          done
         # установка остальных пакетов
         elif [ "$2" == "main" ]; then
          for (( i=0; i<"${#packages_main_ubuntu[@]}"; i++ )); do
            apt install -y ${packages_main_ubuntu[i]}
          done
        fi
      ;;
      astra)
        apt update
        # установка основных системных пакетов
        if [ "$2" == "system" ]; then
          for (( i=0; i<"${#packages_system_astra[@]}"; i++ )); do
            apt install -y ${packages_system_astra[i]}
          done
         # установка остальных пакетов
         elif [ "$2" == "main" ]; then
          for (( i=0; i<"${#packages_main_astra[@]}"; i++ )); do
            apt install -y ${packages_main_astra[i]}
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
        # установка openssl
        cd $int_arch_src_dir
        tar -xvf openssl-*.tar.gz && rm -f openssl-*.tar.gz
        cd openssl-*
        ./config --prefix=/usr --openssldir=/usr
        make
        make install
      ;;
      redos)
        rpm -ivh --replacepkgs --force $2/*
        # установка openssl
        cd $int_arch_src_dir
        tar -xvf openssl-*.tar.gz && rm -f openssl-*.tar.gz
        cd openssl-*
        ./config --prefix=/usr --openssldir=/usr
        make
        make install
      ;;
      debian)
        dpkg -i $2/*
      ;;
      ubuntu)
        dpkg -i $2/*
      ;;
      astra)
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
  if [ ! -d $int_arch_dir ]; then mkdir $int_arch_dir; fi
  # создание каталога packages
  if [ ! -d $int_arch_pack_dir ]; then mkdir $int_arch_pack_dir; fi
  # создание каталога src
  if [ ! -d $int_arch_src_dir ]; then mkdir $int_arch_src_dir; fi  
}

# загрузка ffmpeg 5.1 для установки поверх 3.2. Актуально только для центос7
function download_ffmpeg {
  if [ $1 == "online" ]; then
    # в онлайн режиме загружаем архив просто рядом со скриптом
    cd $script_dir
    case $(detect_os os) in
      centos)
        wget https://github.com/q3aql/ffmpeg-builds/releases/download/v5.1.2/ffmpeg-5.1.2-linux-gnu-64bit-build.tar.bz2
      ;;
      redos)
      ;;
      debian)
      ;;
      ubuntu)
      ;;
      astra)
      ;;
      altlinux)
      ;;
    esac
  elif [ $1 == "offline" ]; then
    # для сборки оффлайн инсталлера загружаем архив в папку archive
    cd $script_dir
    cd archive
    case $(detect_os os) in
      centos)
        wget https://github.com/q3aql/ffmpeg-builds/releases/download/v5.1.2/ffmpeg-5.1.2-linux-gnu-64bit-build.tar.bz2
      ;;
      redos)
      ;;
      debian)
      ;;
      ubuntu)
      ;;
      astra)
      ;;
      altlinux)
      ;;
    esac
  fi
}

# установка ffmpeg 5.1
function install_ffmpeg {
  if [ $1 == "online" ]; then
    # в онлайн режиме устанавливает из директории скрипта
    cd $script_dir
    case $(detect_os os) in
      centos)
      # установка происходит просто рахорхивированием архива в корень
        tar jxvf ffmpeg-5.1.2-linux-gnu-64bit-build.tar.bz2 -C /
      ;;
      redos)
      ;;
      debian)
      ;;
      ubuntu)
      ;;
      astra)
      ;;
      altlinux)
      ;;
    esac
  elif [ $1 == "offline" ]; then
    # в оффлайн ставим из папки archive
    cd $script_dir
    cd archive
    case $(detect_os os) in
      centos)
        if [ x${HOME} = x ]; then HOME='/root'; fi
        # установка происходит просто разорхивированием архива в корень
        tar jxvf $int_arch_dir/ffmpeg-5.1.2-linux-gnu-64bit-build.tar.bz2 -C /
      ;;
      redos)
      ;;
      debian)
      ;;
      ubuntu)
      ;;
      astra)
      ;;
      altlinux)
      ;;
    esac
  fi
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
      # обновление openssl
      cd $int_arch_src_dir
      wget https://www.openssl.org/source/openssl-1.1.1u.tar.gz      
    ;;
    redos)
      yum --enablerepo=base clean metadata
      # системные пакеты
      for (( i=0; i<"${#packages_system_redos[@]}"; i++ )); do
        repotrack "${packages_system_redos[i]}"
      done
      # все основные пакеты
      for (( i=0; i<"${#packages_main_redos[@]}"; i++ )); do
        repotrack "${packages_main_redos[i]}"
      done
      # обновление openssl
      cd $int_arch_src_dir
      wget https://www.openssl.org/source/openssl-1.1.1u.tar.gz     
    ;;
    debian)
      apt update
      # системные пакеты
      for (( i=0; i<"${#packages_system_debian[@]}"; i++ )); do
        apt install -y -d --reinstall ${packages_system_debian[i]}
      done
      # все основные пакеты
      for (( i=0; i<"${#packages_main_debian[@]}"; i++ )); do
        apt install -y -d --reinstall ${packages_main_debian[i]}
      done
      # скопировать все скачанные пакеты в папку инсталлятора $int_arch_pack_dir
      cp /var/cache/apt/archives/*.deb $PWD/
    ;;
    ubuntu)
      apt update
      # системные пакеты
      for (( i=0; i<"${#packages_system_ubuntu[@]}"; i++ )); do
        apt install -y -d --reinstall ${packages_system_ubuntu[i]}
      done
      # все основные пакеты
      for (( i=0; i<"${#packages_main_ubuntu[@]}"; i++ )); do
        apt install -y -d --reinstall ${packages_main_ubuntu[i]}
      done
      # скопировать все скачанные пакеты в папку инсталлятора $int_arch_pack_dir
      cp /var/cache/apt/archives/*.deb $PWD/
    ;;
    astra)
      apt update
      # системные пакеты
      for (( i=0; i<"${#packages_system_astra[@]}"; i++ )); do
        apt install -y -d ${packages_system_astra[i]}
      done
      for (( i=0; i<"${#packages_main_astra[@]}"; i++ )); do
        apt install -y -d ${packages_main_astra[i]}
      done
      # скопировать все скачанные пакеты в папку инсталлятора $int_arch_pack_dir
      cp /var/cache/apt/archives/*.deb $PWD/
    ;;
    altlinux)
      # системные пакеты
      apt-get update
      # пакеты обновления системы
      apt-get dist-upgrade -y
      # пакеты с системного массива
      for (( i=0; i<"${#packages_system_altlinux[@]}"; i++ )); do
        apt-get install -y -d ${packages_system_altlinux[i]}
      done
      # пакеты с основного массива
      for (( i=0; i<"${#packages_main_altlinux[@]}"; i++ )); do
       apt-get install -y -d ${packages_main_altlinux[i]}
      done
      # скопировать все скачанные пакеты в папку инсталлятора $int_arch_pack_dir
      cp /var/cache/apt/archives/*.rpm $PWD/
    ;;
  esac
}

# формирование списка requirements.txt
function list_pip3_modules {
  cd $script_dir
  # проверка наличия внешнего файла списка модулей pip3
  if [ -f $list_pip3_modules_ext ]; then
    echo "существует внешний файл список модулей pip3" >> $log_file
    cp $list_pip3_modules_ext $temp_dir/modules/requirements.txt
   else
    echo "внешнего файла списка модулей pip3 не существует, загрузка внутреннего списка" >> $log_file
    # полный список для варки
    if [ $1 == "full" ]; then
      for (( i=0; i<"${#modules_pip3_full[@]}"; i++ )); do
        echo ${modules_pip3_full[i]} >> $temp_dir/modules/requirements.txt
      done
    fi
    # минимальный список для прода
    if [ $1 == "minimal" ]; then
      for (( i=0; i<"${#modules_pip3_minimal[@]}"; i++ )); do
        echo ${modules_pip3_minimal[i]} >> $temp_dir/modules/requirements.txt
      done
    fi
  fi
}

# перенос pyenv из root директории
function download_pyenv {
 cd $script_dir
 # удаление всех версий питона из папки pyenv
 rm -rf $HOME/.pyenv/versions/*
 # перенос системного pyenv в папку формируемого архива
 mv $HOME/.pyenv archive/
 # создание папки кэш куда будет скачан архив для оффлайн установки версии питона
 mkdir archive/.pyenv/cache
 # перенос архива установки питона в папку кэш(установщик там ищет архив)
 case $(detect_os os) in
   centos)
     mv archive/.pyenv/sources/$python_ver_centos/Python-$python_ver_centos.tar.xz archive/.pyenv/cache
   ;;
   redos)
     mv archive/.pyenv/sources/$python_ver_centos/Python-$python_ver_centos.tar.xz archive/.pyenv/cache
   ;;
   debian)
     mv archive/.pyenv/sources/$python_ver_debian/Python-$python_ver_debian.tar.xz archive/.pyenv/cache
   ;;
   ubuntu)
     mv archive/.pyenv/sources/$python_ver_ubuntu/Python-$python_ver_ubuntu.tar.xz archive/.pyenv/cache
   ;;
   astra)
     mv archive/.pyenv/sources/$python_ver_astra/Python-$python_ver_astra.tar.xz archive/.pyenv/cache
   ;;
   altlinux)
     cp archive/.pyenv/sources/$python_ver_altlinux/Python-$python_ver_altlinux.tar.xz archive/.pyenv/cache
   ;;
 esac
}

# скачивание модулей python
function download_modules {
  cd $script_dir
  # переход локально на $python_ver_дистрибутив
  case $(detect_os os) in
    centos)
      pyenv local $python_ver_centos
    ;;
    redos)
      pyenv local $python_ver_redos
    ;;
    debian)
      pyenv local $python_ver_debian
    ;;
    ubuntu)
      pyenv local $python_ver_ubuntu
    ;;
    astra)
      pyenv local $python_ver_astra
    ;;
    altlinux)
      pyenv local $python_ver_altlinux
    ;;
  esac
  # временные папки
  mkdir $temp_dir
  mkdir $temp_dir/modules
  # создание окружения на базе питона
  python3 -m venv $temp_dir
  # установка всех модулей
   source $temp_dir/bin/activate
    # обновление pip3
    pip3 install --upgrade pip
    pip3 install wheel
    pip3 install scikit-build
    pip3 install setuptools_rust
    pip3 install setuptools
    pip3 install --upgrade cython
    list_pip3_modules $1
    cd $temp_dir/modules
    pip3 download pytest_runner
    pip3 download --no-cache-dir -r requirements.txt
  deactivate
  # переход локально на системную версию чтобы не сломать то что уже работает на системной
  pyenv local system
  rm -rf .python-version
  cd $script_dir
  # перемещение с временной папки в основную папку архива
  mv temp/modules archive/
  # удаление временной папки
  rm -rf $temp_dir
}

function export_pyenv_enviroment {
  export PYENV_ROOT="$HOME/.pyenv" &&  export PATH="$PYENV_ROOT/bin:$PATH"
  eval "$(pyenv init -)"
}

function install_pyenv {
  cd $script_dir
  # удаление папки .pyenv если не установлена ни одна из версий питона
  if [ `ls $HOME/.pyenv/versions | wc -l` -eq 0 ]; then
    rm -rf $HOME/.pyenv
  fi
  # удаление всего кэша (надо посмотреть не вредно ли?)
  rm -rf $HOME/.cache/*
  # онлайн установка
  if [ $1 == "online" ]; then
    curl https://pyenv.run | bash
    export_pyenv_enviroment
    # установка питона с сохранением исходников ключ -k
    case $(detect_os os) in
      centos)
        # проверка наличия нужной версии питона в репозитории pyenv
        if [ "`pyenv install --list | sed 's/^ *//g' | grep ^$python_ver_centos`" == "$python_ver_centos" ]; then
          pyenv install -s -k $python_ver_centos
         else
          echo "такой версии питона не существует, проверить версии: pyenv install --list"
          clear_temp
          exit
        fi
      ;;
      redos)
        # проверка наличия нужной версии питона в репозитории pyenv
        if [ "`pyenv install --list | sed 's/^ *//g' | grep ^$python_ver_redos`" == "$python_ver_redos" ]; then
          pyenv install -s -k $python_ver_redos
         else
          echo "такой версии питона не существует, проверить версии: pyenv install --list"
          clear_temp
          exit
        fi
      ;;
      debian)
        if [ "`pyenv install --list | sed 's/^ *//g' | grep ^$python_ver_debian`" == "$python_ver_debian" ]; then
          pyenv install -s -k $python_ver_debian
         else
          echo "такой версии питона не существует, проверить версии: pyenv install --list"
          clear_temp
          exit
        fi
      ;;
      ubuntu)
        if [ "`pyenv install --list | sed 's/^ *//g' | grep ^$python_ver_ubuntu`" == "$python_ver_ubuntu" ]; then
          pyenv install -s -k $python_ver_ubuntu
         else
          echo "такой версии питона не существует, проверить версии: pyenv install --list"
          clear_temp
          exit
        fi
      ;;
      astra)
        if [ "`pyenv install --list | sed 's/^ *//g' | grep ^$python_ver_astra`" == "$python_ver_astra" ]; then
          pyenv install -s -k $python_ver_astra
         else
          echo "такой версии питона не существует, проверить версии: pyenv install --list"
          clear_temp
          exit
        fi
      ;;
      altlinux)
        if [ "`pyenv install --list | sed 's/^ *//g' | grep ^$python_ver_altlinux`" == "$python_ver_altlinux" ]; then
          pyenv install -s -k $python_ver_altlinux
         else
          echo "такой версии питона не существует, проверить версии: pyenv install --list"
          clear_temp
          exit
        fi
      ;;
    esac
   # оффлайн установка
   elif [ $1 == "offline" ]; then
    # перенести установленную версию pyenv в хом рута
    mv $int_arch_dir/.pyenv /root
    # прописывание pyenv окружения (действует до первой перезагрузки)
    export_pyenv_enviroment
    # установка питона
    case $(detect_os os) in
      centos)
        pyenv install -s $python_ver_centos
      ;;
      redos)
        pyenv install -s $python_ver_redos
      ;;
      debian)
        pyenv install -s $python_ver_debian
      ;;
      ubuntu)
        pyenv install -s $python_ver_ubuntu
      ;;
      astra)
        pyenv install -s $python_ver_astra
      ;;
      altlinux)
        pyenv install -s $python_ver_altlinux
      ;;
    esac
  fi
}

# установка pve окружения
function install_pve {
  cd $script_dir
  # оффлайн установка
  if [ $1 == "offline" ]; then
    # вывести в лог в каком режиме установка
    echo "Установка в оффлайн режиме" >> $log_file
    # переход локально
    case $(detect_os os) in
      centos)
        pyenv local $python_ver_centos
      ;;
      redos)
        pyenv local $python_ver_redos
      ;;
      debian)
        pyenv local $python_ver_debian
      ;;
      ubuntu)
        pyenv local $python_ver_ubuntu
      ;;
      astra)
        pyenv local $python_ver_astra
      ;;
      altlinux)
        pyenv local $python_ver_altlinux
      ;;
        esac
    # создание окружения на базе питона
    python3 -m venv $service_pve_install_dir
    # установка модулей
    source $service_pve_install_dir/bin/activate
      cd $int_arch_dir/modules
      # получить имя установочного пакета pip3
      filename_pip3=`ls -A | grep pip-*.whl`
      # получить имя установочного пакета setuptools
      filename_setuptools=`ls -A | grep setuptools-*.whl`
      # получить имя установочного пакета Cython
      filename_cython=`ls -A | grep Cython-*.whl`
      # получить имя установочного пакета pytest_runner
      filename_runner=`ls -A | grep pytest_runner-*.whl`
      # установить отдельно пакет pip3 (не ставится из общей массы)
      pip3 install $filename_pip3 --no-index --find-links '.'
      # установить отдельно пакет setuptools (не ставится из общей массы)
      pip3 install $filename_setuptools --no-index --find-links '.'
      # установить отдельно пакет Cython (не ставится из общей массы)
      pip3 install $filename_cython --no-index --find-links '.'
      # установить отдельно пакет pytest_runner (не ставится из общей массы)
      pip3 install $filename_runner --no-index --find-links '.'
      # установить всю общую массу модулей
      pip3 install -r requirements.txt --no-index --find-links '.'
    deactivate
    # переход локально на системную версию чтобы не сломать то что уже работает на системной
    pyenv local system
   # онлайн установка
   elif [ $1 == "online" ]; then
    # вывести в лог в каком режиме установка
    echo "Установка в онлайн режиме" >> $log_file
    # переход локально на версию питона установленную через pyenv
    # указывает системе работать с версией питона установленного в pyenv
    case $(detect_os os) in
      centos)
        pyenv local $python_ver_centos
      ;;
      redos)
        pyenv local $python_ver_redos
      ;;
      debian)
        pyenv local $python_ver_debian
      ;;
      ubuntu)
        pyenv local $python_ver_ubuntu
      ;;
      astra)
        pyenv local $python_ver_astra
      ;;
      altlinux)
        pyenv local $python_ver_altlinux
      ;;
    esac
    # создание виртуального питон окружения в папке
    python3 -m venv $service_pve_install_dir
    # установка модулей
    source $service_pve_install_dir/bin/activate
      curl -sS https://bootstrap.pypa.io/pip/get-pip.py | python3
      python3 -m pip install --upgrade pip
      # pip3 freeze не добаляет в список setuptools
      pip3 install --upgrade setuptools
      # установка модулей питона из списка в массиве или из внешнего файла модулей
        if [ -f $list_pip3_modules_ext ]; then
          echo "существует внешний файл список модулей pip3" >> $log_file
          mapfile -t modules_pip3 < $list_pip3_modules_ext
          for (( i=0; i<"${#modules_pip3[@]}"; i++ )); do
            pip3 install --upgrade ${modules_pip3[i]}
          done
        else
          echo "внешнего файла списка модулей pip3 не существует, загрузка внутреннего списка" >> $log_file
          # полный список для варки
          if [ $2 == "full" ]; then
            for (( i=0; i<"${#modules_pip3_full[@]}"; i++ )); do
              pip3 install --upgrade ${modules_pip3_full[i]}
            done
          fi
          # минимальный список для прода
          if [ $2 == "minimal" ]; then
            for (( i=0; i<"${#modules_pip3_minimal[@]}"; i++ )); do
              pip3 install --upgrade ${modules_pip3_minimal[i]}
            done
          fi
        fi
    deactivate
    # переход локально на системную версию чтобы не сломать то что уже работает на системной
    pyenv local system
  fi
}

# создание архива для включения в скрипт оффлайн установки
function create_arсhive {
  cd $script_dir
  tar -zcvf $int_arch_name -C $1 $(ls -A $1) --remove-files >> $log_file
  rm -rf $1
}

# распаковка внутреннего архива
function extract_archive {
  # распаковать в каталог
  if [ $1 == "dir" ]; then
    echo "распаковка внутреннего архива в $2">> $log_file
    echo "распаковка внутреннего архива"
    mkdir -p $2
    tail -n +${PAYLOAD_LINE} $0 | base64 -d | tar -xzf - --directory="$2" --checkpoint=.100
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
  # удалить архив который уже есть в скрипте, всё что после payload
  sed -i '/^__PAYLOAD_BEGINS__$/q' $script_name
  # если случайно скопировали имя архива = имя скрипта
  if [ ${script_name} != $1 ]; then
    # вставить архив в скрипт
    base64 $1 >> $script_name
    # обновить информацию об имени архива в переменную
    sed -i 's/^int_arch_name=.*$/int_arch_name="'$1'"/g' $script_name
    echo "архив $1 запакован в $script_name" >> $log_file
   else
    echo "осторожно с именем архива!"
  fi
}

function null_archive {
  # удалить всё что после payload
  sed -i '/^__PAYLOAD_BEGINS__$/q' $script_name
}

# назначить права на файлы сервиса
function assign_rights {
  chown -R $USER:$USER $service_install_dir
}

# удаление старой версии
function uninstall_service {
  systemctl stop $service_name &> /dev/null
  systemctl disable $service_name &> /dev/null
  if [ -d $service_install_dir ]; then rm -fR $service_install_dir &> /dev/null; fi
  if [ -f $service_name ]; then rm -f /etc/systemd/system/$service_name.service &> /dev/null; fi
  echo "удаление старой версии $service_name" >> $log_file
}

# удаление временных каталогов
function clear_temp {
  cd $script_dir
  rm -rf $int_arch_dir &> /dev/null
  rm -rf .python-version &> /dev/null
  rm -rf $int_arch_name &> /dev/null
  rm -rf $HOME/.cache/pip &> /dev/null
  rm -rf $int_arch_pack_dir/offline.sig &> /dev/null
}

# удаление пробелов из строки
function string_no_space {
  no_space=`echo -e $@ | sed -e 's/ //g'`
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

# функция обновления списка pip модулей из внешнего файла
function renew_list {
    [ ! -f "$2" ] && echo "Не указан или неверно указан внешний список модулей. Выходим" && exit 1
    mode=$1
    new_list=$2
    # перебор ключей для выбора какой список обновлять
    if [ $mode == "full" ]; then
       varname=modules_pip3_${mode}
    elif [ $mode == "minimal" ]; then
       varname=modules_pip3_${mode}
     else
       echo "Неверный ключ. Пример вызова -r full/minimal имя_файла"
       exit 1
    fi;
    # номер строки с объявлением переменной
    begin_line_number=`awk "/^${varname}/ {print NR}" $script_name `
    # количество строк от объявления переменной до конца массива
    endline_number=`cat $script_name |tail -n +$begin_line_number | awk '/)$/ {print NR}' |head -n1`
    # считаем вторую границу диапазона, -1 для корректировки
    final_number=$(( $begin_line_number+$endline_number-1 ))
    # ограничитель на количество модулей в строке итогового файла. Нужно для лучшей читаемости
    count=0
    # начинаем формировать временный файл
    echo -n "${varname}=(" > tmp.txt
    # пишем модули из входног файла во временный, заворачивая в "" для соответствия баш формату
    for module in $(cat $new_list); do
        echo -n "\"$module\" ">> tmp.txt
        count=$(($count+1))
        # 5 модулей в строке,после этого ставим \ и переходим на новую строку
        [ $count -eq 5 ] && echo "\\">> tmp.txt && count=0
    done
    echo ")">> tmp.txt
    # вырезаем из скрипта строки, содержащие объявленный массив модулей
    sed -i "${begin_line_number},${final_number}d" $script_name
    # вставляем новый массив в скрипт из временного файла в нужную строку с коректировкой -1
    sed -i "$(($begin_line_number-1))r tmp.txt" $script_name
    # удаляем временный файл
    rm -f tmp.txt
}

# описание режимов работы скрипта, выводит при "пустом" запуске
function show_description {
  echo "ключи -e(--extract) -p(--pack) -b(--build) -n(--null)
              -i(--install) -off(--offline) -on(--online) -m(--minimal) -f(--full) -r(--renew)

----совместный блок-------
"-i/--install"               - установить сервис в online/offline режиме
вместе
"-off/--offline"             - установка оффлайн (необходимо собрать скрипт с ключем -b/--build)
или
"-on/--online"               - установка онлайн (собирать с ключем -b/--build не надо)
"-m/--minimal"               - установка миниального набора модулей pip3
или
"-f/--full"                  - установка полного набора модулей pip3
""
--------------------------

"-e/--extract"               - скопировать внутренний архив рядом со скриптом;
"-p/--pack имя_архива"       - запаковать архив в скрипт - архив создавать без абсолютных каталогов:
                               tar -czvf urs-install.tgz -C archive \$(ls -A archive);
"-d/--dir путь/имя_каталога" - совместно с -p/--pack или -e/--extract, сжать\распаковать каталог в\из архива;
"-b/--build"                 - скачать все пакеты, и модули, и упаковать в скрипт для оффлайн установки;
"-n/--null"                  - удалить внутренний архив из скрипта;
"-r/--renew \
full/minimal имя_файла"      - вписать в скрипт новый full/minimal список pip модулей из внешнего файла


# Установить сервис с полным набором модулей pip3
Пример использования: $0 -i -f -on
# Установить сервис с минимальным набором модулей pip3
Пример использования: $0 -i -m -on
# Установить сервис из заранее собранного инсталлера
Пример использования: $0 -i -off
# Скопировать внутренний архив рядом со скриптом не распаковывая в папку
Пример использования: $0 --extract
# Запаковать архив в скрипт
Пример использования: $0 --pack <service>-offline.tgz
# Сжать каталог и запаковать архив в скрипт
Пример использования: $0 --pack -d <имя каталога>
# Распаковать внутренний архив рядом со скриптом в каталог
Пример использования: $0 -e -d archive
# Собрать все пакеты для установки оффлайн сервиса с полным набором модулей pip3
Пример использования: $0 --build -f
# Собрать все пакеты для установки оффлайн сервиса с минимальным набором модулей pip3
Пример использования: $0 --build -m
# Удалить внутренний архив из скрипта
Пример использования: $0 --null
# Изменить список pip модулей в скрипте
Пример использования: $0 -r full freeze.txt
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
           install)  key_install="install";;
           # онлайн установка
           online)   key_online="online";;
           # оффлайн установка
           offline)  key_offline="offline";;
           # минимальный набор модулей pip3
           minimal)  key_minimal="minimal";;
           # полный набор модулей pip3
           full)     key_full="full";;
           # сборка внутреннего архива для оффлайн установки
           build)    key_build="build";;
           # удалить внутренний архив (слишком большой для редактирования скрипта)
           null)     key_null="null";;
           # скопировать архив рядом со скриптом не распаковывая его
           extract)  key_extract="extract";;
           # запаковать внешний архив в скрипт
           pack)     key_pack="pack"; key_p_arg=$1;;
           # сделать архив и запаковать в скрипт из директории
           dir)      key_dir="dir"; key_d_arg=$1;;
           # тестирование одиночных функций
           test)     key_test="test";;
           # обновление списка pip модулей
           renew)    key_renew="renew"; key_r_arg1=$1; key_r_arg2=$2;;
           # все остальные ключи неправильные
           *)        echo "неправильный двойной ключ запуска";;
          esac;;

     # для одинарных ключей с -
     -*) case ${arg:1} in
          # установка
          i)    key_i="i";;
          # онлайн установка
          on)   key_on="on";;
          # оффлайн установка
          off)  key_off="off";;
          # минимальный набор модулей pip3
          m)    key_m="m";;
          # полный набор модулей pip3
          f)    key_f="f";;
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
          # обновление списка pip модулей
          r)    key_r="r"; key_r_arg1=$1; key_r_arg2=$2;;
          # все остальные ключи неправильные
          *)    echo "неправильный одинарный ключ запуска";;
         esac;;
    esac
done

# массив ключей установки, все варианты ключей, при добалении нового ключа - дописать его СЮДА!
key_all=($key_i $key_install \
         $key_on $key_online \
         $key_off $key_offline \
         $key_m $key_minimal \
         $key_f $key_full \
         $key_b $key_build \
         $key_n $key_null \
         $key_e $key_extract \
         $key_p $key_pack \
         $key_d $key_dir \
         $key_t $key_test \
         $key_r $key_renew)
# все варианты, в перемешку, поступивших ключей
key_all_mix=$(mix_array ${#key_all[@]} ${key_all[@]})
# все ключи в кучу без пробелов
key_all_no_space=$(string_no_space ${key_all_mix[@]})

# выборка вариантов совместных ключей
case $key_all_no_space in
  # онлайн установка с полным набором pip3 модулей
  i*on*f*     ) uninstall_service;
                install_pac online system; install_repo; install_pac online main;
                download_ffmpeg online; install_ffmpeg online;
                install_pyenv online; install_pve online full;
                assign_rights;
                clear_temp;;
  # онлайн установка с минимальным набором pip3 модулей
  i*on*m*     ) uninstall_service;
                install_pac online system; install_repo; install_pac online main;
                download_ffmpeg online; install_ffmpeg online;
                install_pyenv online; install_pve online minimal;
                assign_rights;
                clear_temp;;
  # оффлайн установка
  i*off*      ) uninstall_service;
                extract_archive dir $int_arch_dir;
                install_pac offline $int_arch_pack_dir;
                install_ffmpeg offline; install_pyenv offline; install_pve offline;
                clear_temp;;
  # сборка внутреннего архива для оффлайн установки с полным набором модулей pip3
  *b*f*       ) create_temp_dirs;
                configure_system;
                install_pac online system; install_repo; install_pac online main;
                download_pac; download_ffmpeg offline;
                install_pyenv online; download_modules full; download_pyenv;
                create_arсhive $int_arch_dir; pack_archive $int_arch_name;
                clear_temp;;
  # сборка внутреннего архива для оффлайн установки с минимальным набором модулей pip3
  *b*m*       ) create_temp_dirs;
                configure_system;
                install_pac online system; install_repo; install_pac online main;
                download_pac; download_ffmpeg offline;
                install_pyenv online; download_modules minimal; download_pyenv;
                create_arсhive $int_arch_dir; pack_archive $int_arch_name;
                clear_temp;;
  # удалить внутренний архив (слишком большой для редактирования скрипта)
  n|null      ) null_archive;;
  # скопировать архив рядом со скриптом не распаковывая его
  e|extract   ) extract_archive asis;;
  # распаковать архив в папку рядом со скриптом
  e*d*        ) extract_archive dir $key_d_arg;;
  # запаковать архив в скрипт
  p|pack      ) pack_archive $key_p_arg;;
  # запаковать папку в архив и включить в скрипт
  p*d*        ) create_arсhive $key_d_arg; pack_archive $int_arch_name; clear_temp;;
  # обновить список pip модулей из внешнего файла
  r|renew     ) renew_list $key_r_arg1 $key_r_arg2;;
  # test function (раздел для тестирования одиночных функций)
  t           ) create_temp_dirs; download_pac; install_pac online system; install_repo;
                install_pac online main; install_pyenv online; download_modules minimal; download_pyenv;;
  # пустая строка
  ""          ) show_description;;
  *           ) echo "неправильное сочетание ключей";;
esac

exit 0
__PAYLOAD_BEGINS__
