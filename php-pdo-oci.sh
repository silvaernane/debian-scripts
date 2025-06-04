# NÃO RODAR ESSE SCRIPT, COMANDOS APENAS PARA COPIAR E COLAR
sudo apt update && sudo apt upgrade -y

sudo apt install apache2 -y

sudo systemctl enable --now apache2

# Adicionar repositório e instalar PHP
sudo apt install software-properties-common -y

sudo add-apt-repository ppa:ondrej/php -y
sudo apt update

sudo apt install \
  php7.4 libapache2-mod-php7.4 php7.4-cli php7.4-dev \
  php7.4-xml php7.4-mbstring php7.4-curl php7.4-zip -y

# Mudar tudo para a versão correta do PHP
sudo update-alternatives --config php
sudo update-alternatives --config phpize
sudo update-alternatives --config php-config

# Baixar os zips do instant client (19 ou 21)
sudo mkdir -p /opt/oracle
# Verificar nome dos arquivos
sudo unzip instantclient-basic-linux.x64-*.zip -d /opt/oracle
sudo unzip instantclient-sdk-linux.x64-*.zip
rm instantclient-sdk-linux.x64-*.zip
# Colocar a versão correta
cd instantclient-sdk-linux.x64-19.27.0.0.0dbru
cd instantclient_19_27
sudo mv sdk /opt/oracle/instantclient_19_27

# Deixar com essa estrutura
# /opt/oracle/instantclient_19_27/
# ├── adrci
# ├── libclntsh.so
# ├── libclntsh.so.19.1
# ├── libnnz19.so
# ├── libociicus.so
# ├── sqlplus          (se tiver instalado o pacote opcional SQL*Plus)
# ├── uidrvci
# ├── ...
# ├── sdk/
# │   └── include/
# │       ├── oci.h
# │       ├── ociapr.h
# │       ├── oci1.h
# │       ├── ...

#Se não tiver libclntsh.so em /opt/oracle/instantclient_19_27 crie um link:
sudo ln -s libclntsh.so.19.1 /opt/oracle/instantclient_19_27/libclntsh.so

# Instalar libio1 e criar link simbólico
sudo apt install libaio1t64 build-essential php7.4-dev php-pear -y
sudo ln -s /usr/lib/x86_64-linux-gnu/libaio.so.1t64 /usr/lib/x86_64-linux-gnu/libaio.so.1

# Colocar a versão do instantclient
echo '/opt/oracle/instantclient_19_27/' | sudo tee /etc/ld.so.conf.d/oracle-instantclient.conf
sudo ldconfig

#Verificar
ldconfig -p | grep libclntsh
#Deve aparecer libclntsh.so.19.1 (libc6,x86-64) => /opt/oracle/instantclient_19_27/libclntsh.so.19.1

# Apenas se for PHP >= 8.1.0
sudo pecl install oci8
# Quando solicitado, informe:
# instantclient,/opt/oracle/instantclient_<versão>
# Se não der certo para a sua versão, compilar diretamente


# Baixar o código fonte (verificar versão php)
wget https://www.php.net/distributions/php-7.4.33.tar.gz
tar -xzf php-7.4.33.tar.gz
cd php-7.4.33/ext/pdo_oci

phpize
# OU /usr/bin/phpize7.4 (acho que só quando tiver apenas uma versão instalada)

# Sempre verificar o caminho e versão exata com: strings /opt/oracle/instantclient_19_27/libclntsh.so.19.1 | grep 'Release'
./configure --with-pdo-oci=instantclient,/opt/oracle/instantclient_19_27,19.27.0.0.0

make && sudo make install

# Habilitar a extensão
echo "extension=pdo_oci.so" | sudo tee /etc/php/7.4/mods-available/pdo_oci.ini
sudo phpenmod pdo_oci

# Ao final de tudo reiniciar o Apache
sudo systemctl restart apache2

# ---------------------------------------------------------------------------------------
# Adicionar ao ~/.zshrc
export LD_LIBRARY_PATH=/opt/oracle/instantclient_19_27:$LD_LIBRARY_PATH

#Para desinstalar
sudo phpdismod pdo_oci
sudo rm /etc/php/7.4/mods-available/pdo_oci.ini
sudo rm $(php-config --extension-dir)/pdo_oci.so
