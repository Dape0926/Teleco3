Esta es una guía de implementación de un clúster Galera de bases de datos MariaDB con balanceo de carga usando Nginx.

Esta guia esta diseñada tanto para poder implementarla solo leyendo este readme, o usando los archivos de configuracion ya modificados 
que estan en el repositorio, sientete libre de implementarlo como te parezca mas sencillo.

si tienes alguna duda de como quedan los diferentes archivos modificados, todos estos estan el el repósitorio del proyecto.

GUIA:

1. Se crea una carpeta donde irán las máquinas del proyecto. Luego, mediante el cmd, se accede a esa carpeta con el comando "cd" y 
se utiliza el comando "vagrant init". Este creará un documento donde se configuran las diferentes máquinas a utilizar. En este caso, se crearán 6 máquinas con distribución Ubuntu: 1 que tendrá el papel de balanceador (balanceadorm), un cliente (clientesql) y 4 servidores (nodo1 - nodo4). A continuación, se provee el Vagrantfile que se utilizó.

Vagrant.configure("2") do |config|
if Vagrant.has_plugin? "vagrant-vbguest"
config.vbguest.no_install = true
config.vbguest.auto_update = false
config.vbguest.no_remote = true
end
config.vm.define :nodo1 do |nodo1|
nodo1.vm.box = "bento/ubuntu-20.04"
nodo1.vm.network :private_network, ip: "192.168.70.10"
nodo1.vm.hostname = "nodo1"
end
config.vm.define :nodo2 do |nodo2|
nodo2.vm.box = "bento/ubuntu-20.04"
nodo2.vm.network :private_network, ip: "192.168.70.11"
nodo2.vm.hostname = "nodo2"
end
config.vm.define :nodo3 do |nodo3|
nodo3.vm.box = "bento/ubuntu-20.04"
nodo3.vm.network :private_network, ip: "192.168.70.12"
nodo3.vm.hostname = "nodo3"
end
config.vm.define :nodo4 do |nodo4|
nodo4.vm.box = "bento/ubuntu-20.04"
nodo4.vm.network :private_network, ip: "192.168.70.13"
nodo4.vm.hostname = "nodo4"
end
config.vm.define :balanceadorm do |balanceadorm|
balanceadorm.vm.box = "bento/ubuntu-20.04"
balanceadorm.vm.network :private_network, ip: "192.168.70.8"
balanceadorm.vm.hostname = "balanceadorm"
end
config.vm.define :clientesql do |clientesql|
clientesql.vm.box = "bento/ubuntu-20.04"
clientesql.vm.network :private_network, ip: "192.168.70.9"
clientesql.vm.hostname = "clientesql"
end
end

2. En los 4 servidores que serán el clúster se tiene que descargar MariaDB. En este caso, se hace con la herramienta Galera-3 y se lleva a cabo con los siguientes comandos:

- sudo -i // se accede como super usuario para realizar las configuraciones
- apt-get update -y // con este comando se actualiza el sistema con los ultimos paquetes disponibles
- apt-get upgrade -y // con este comando se actualizaran los paquetes ya instalados del sistema
- apt-get install mariadb-server galera-3 -y // aca se procede a la instalacion del mariadb

Hacer este proceso en los demas nodos (servidores)  

3. Por defecto el usuario root en MariaDB no tiene una contraseña, entonces se necesita asignarle una (hacer este proceso en cada uno de los nodos).

- mysql_secure_installation 

Responder a todas las preguntas como se muestra a continuación

Enter current password for root (enter for none): Provide your root user password
Switch to unix_socket authentication [Y/n] n
Change the root password? [Y/n] Y
New password: // poner nueva contraseña
Re-enter new password: 
Remove anonymous users? [Y/n] Y
Disallow root login remotely? [Y/n] Y
Remove test database and access to it? [Y/n] Y
Reload privilege tables now? [Y/n] Y

No olvidar repetir este proceso en cada uno de los nodos.

4. Verificamos que el firewall este desactivado en cada nodo, en caso de que no se procede a desactivarlo.

- sudo ufw status // se verifica el estado del firewall
- sudo ufw disable // se desactiva el firewall

5. Configurar cada servidor del cluster.

En este punto hemos instalado el servidor MariaDB con el cluster Galera en cada servidor.
Lo siguiente que se debe hacer es configurar este cluster para lograr la comunicación entre servidores. Para hacer esto se necesita crear un archivo de configuración común en cada servidor.

6. Configurar primer servidor.

Iniciar sesion en el primer nodo y crea el archivo de configuracion de Galera con el siguiente comando.
- vim /etc/mysql/conf.d/galera.cnf
Agregar las siguientes lineas al archivo (asegurate de corroborar las IP dependiendo de tus necesidades).

/////////////////////////////////////////////////////////////////////////////////////////////////////////
[mysqld]
binlog_format=ROW
default-storage-engine=innodb
innodb_autoinc_lock_mode=2
bind-address=0.0.0.0

# Galera Provider Configuration
wsrep_on=ON
wsrep_provider=/usr/lib/galera/libgalera_smm.so

# Galera Cluster Configuration
wsrep_cluster_name="galera_cluster"
wsrep_cluster_address="gcomm://192.168.70.10,192.168.70.11,192.168.70.12,192.168.70.13" //corroborar las IP

# Galera Synchronization Configuration
wsrep_sst_method=rsync

# Galera Node Configuration
wsrep_node_address="192.168.70.10"
wsrep_node_name="nodo1"
/////////////////////////////////////////////////////////////////////////////////////////////////////////

Guarda el archivo cuando termines y procede al segundo nodo y se repite el mismo proceso.

- vim /etc/mysql/conf.d/galera.cnf
Agregar las siguientes lineas al archivo (asegurate de corroborar las IP dependiendo de tus necesidades).

/////////////////////////////////////////////////////////////////////////////////////////////////////////
[mysqld]
binlog_format=ROW
default-storage-engine=innodb
innodb_autoinc_lock_mode=2
bind-address=0.0.0.0

# Galera Provider Configuration
wsrep_on=ON
wsrep_provider=/usr/lib/galera/libgalera_smm.so

# Galera Cluster Configuration
wsrep_cluster_name="galera_cluster"
wsrep_cluster_address="gcomm://192.168.70.10,192.168.70.11,192.168.70.12,192.168.70.13" //corroborar las IP

# Galera Synchronization Configuration
wsrep_sst_method=rsync

# Galera Node Configuration
wsrep_node_address="192.168.70.11"
wsrep_node_name="nodo2"
/////////////////////////////////////////////////////////////////////////////////////////////////////////

Guarda el archivo cuando termines y procede al tercer nodo y se repite el mismo proceso.

- vim /etc/mysql/conf.d/galera.cnf
Agregar las siguientes lineas al archivo (asegurate de corroborar las IP dependiendo de tus necesidades).

/////////////////////////////////////////////////////////////////////////////////////////////////////////
[mysqld]
binlog_format=ROW
default-storage-engine=innodb
innodb_autoinc_lock_mode=2
bind-address=0.0.0.0

# Galera Provider Configuration
wsrep_on=ON
wsrep_provider=/usr/lib/galera/libgalera_smm.so

# Galera Cluster Configuration
wsrep_cluster_name="galera_cluster"
wsrep_cluster_address="gcomm://192.168.70.10,192.168.70.11,192.168.70.12,192.168.70.13" //corroborar las IP

# Galera Synchronization Configuration
wsrep_sst_method=rsync

# Galera Node Configuration
wsrep_node_address="192.168.70.12"
wsrep_node_name="nodo3"
/////////////////////////////////////////////////////////////////////////////////////////////////////////

Guarda el archivo cuando termines y procede al cuarto nodo y se repite el mismo proceso.

- vim /etc/mysql/conf.d/galera.cnf
Agregar las siguientes lineas al archivo (asegurate de corroborar las IP dependiendo de tus necesidades).

/////////////////////////////////////////////////////////////////////////////////////////////////////////
[mysqld]
binlog_format=ROW
default-storage-engine=innodb
innodb_autoinc_lock_mode=2
bind-address=0.0.0.0

# Galera Provider Configuration
wsrep_on=ON
wsrep_provider=/usr/lib/galera/libgalera_smm.so

# Galera Cluster Configuration
wsrep_cluster_name="galera_cluster"
wsrep_cluster_address="gcomm://192.168.70.10,192.168.70.11,192.168.70.12,192.168.70.13" //corroborar las IP

# Galera Synchronization Configuration
wsrep_sst_method=rsync

# Galera Node Configuration
wsrep_node_address="192.168.70.13"
wsrep_node_name="nodo4"
/////////////////////////////////////////////////////////////////////////////////////////////////////////

Guarda y cierra el archivo una vez terminado.
En este punto ya configuramos los 4 nodos para que se puedan comunicar entre ellos.


7- PASO IMPORTANTE: luego de configurar en cada nodo el galera.cnf hay que modificar en cada nodo el siguiente archivo:

- cd /etc/mysql/mariadb.conf.d

Dentro de este directorio hay que modificar el archivo llamado 50-server.cnf

-vim 50-server.cnf

En este archivo se encuentran las configuraciones por defecto de cada servidor, solo tenemos que cambiar 1 parametro:

- bind address = 0.0.0.0  //por defecto viene con 127.0.0.1 

guardamos y salimos del directorio, recordar hacer el mismo cambio en cada nodo del cluster.


8. Inicializar el cluster Galera.

Asegurate de apagar el servicio de MariaDB en todos los nodos antes de iniciar el cluster con el siguiente comando.

- sudo systemctl stop mariadb

Luego inicializar el cluster en el nodo1 con el siguiente comando.

- galera_new_cluster

Puedes corroborarlo con el siguiente comando.

- mysql -u root -p -e "SHOW STATUS LIKE 'wsrep_cluster_size'"

Te pedira la contraseña de root que se configuro anteriormente.

Te debe aparecer algo parecido a esto.

+--------------------+-------+
| Variable_name      | Value |
+--------------------+-------+
| wsrep_cluster_size | 1     |
+--------------------+-------+

En caso de que no te salga asi repite el paso 7.

Ahora dirigete al segundo nodo y inicia el servicio de MariaDB. 

- sudo systemctl start mariadb

Verifica nuevamente el tamaño del cluster en el segundo nodo.

- mysql -u root -p -e "SHOW STATUS LIKE 'wsrep_cluster_size'"

Digita nuevamente la contraseña, te deberia salir algo como esto.

+--------------------+-------+
| Variable_name      | Value |
+--------------------+-------+
| wsrep_cluster_size | 2     |
+--------------------+-------+

Repite el mismo proceso en el tercer y cuarto servidor y verifica que el wsrep_cluster_size aumente de numero cuando enciendes el servicio de MariaDB.

9. Verifica que esta funcionando la replicación del cluster Galera.

Despues de esto tu cluster Galera esta corriendo correctamente, para verficarlo crearemos una base de datos en el primero nodo y esta tendra que aparecer en los demas nodos.

En el nodo 1 inicia sesion en MariaDB de la siguiente manera.

- mysql -u root -p

Provee tu contraseña y estaras dentro de la consola de comandos de la base de datos

Procedemos a crear la base de datos de prueba

- create database prueba;

Salir de la consola de comandos

- exit;

En el nodo 2 inicia sesion en la base de datos

- mysql -u root -p

Provee tu contraseña y verifica que la existencia de la base de datos creada en el nodo 1 este en el nodo 2

- show databases;

Deberia salir algo como esto

+--------------------+
| Database           |
+--------------------+
| information_schema |
| mysql              |
| performance_schema |
| prueba             |
+--------------------+

Repite este paso en los demas nodos para verificar que la replicación esta funcionando

FELICIDADES!! Has creado y configurado tu cluster de bases de datos de manera satisfactoria, ahora hay que agregarle el balanceo de carga con la herramienta Nginx

10. descargar Nginx en el balanceador

Repetir el proceso de actualizar el sistema con estos comandos

- sudo -i // se accede como super usuario para realizar las configuraciones
- apt-get update -y // con este comando se actualiza el sistema con los ultimos paquetes disponibles
- apt-get upgrade -y // con este comando se actualizaran los paquetes ya instalados del sistema
- sudo ufw status // se verifica el estado del firewall
- sudo ufw disable // se desactiva el firewall

Descargar Nginx

- apt-get install nginx -y

11. Ya con nginx instalado procedemos a configurarlo como balanceador de carga

Para esto nos dirigimos a la siguiente ubicación

- cd /etc/nginx

En esta ubicación si utilizamos el comando ls nos saldran varios archivos, el que nos interesa es nginx.conf, procedemos a modificarlo con vim nginx.conf

Dentro de este archivo tendremos las configuraciones por defecto de nginx, estas no las vamos a modificar, lo unico que vamos a hacer es:

Agregar en la ultima linea del archivo por fuera de los corchetes que vienen por defecto lo siguiente

stream {
include stream.conf;
}

Guardamos y cerramos el archivo, agregar esto nos permitira crear un archivo exclusivo de configuración de balanceo que llamaremos stream.conf

Procedemos a crear este archivo en la ubicación etc/nginx

- vim stream.conf

Luego de esto procedemos a agregar lo siguiente

//////////////////////////////////////
upstream galera_cluster {
    least_conn;
    server  192.168.70.10:3306; #node1
    server  192.168.70.11:3306; #node2
    server  192.168.70.12:3306; #node3
    server  192.168.70.13:3306; #node4
}

server {
    listen 3306; # MySQL default
    proxy_pass galera_cluster;
}
//////////////////////////////////////

Guardamos y cerramos el archivo, gracias a esto ahora nginx funciona como proxy inverso y se encargara de repartir las peticiones al cluster para no saturar los servidores

12. Reiniciar el servicio de Nginx

- sudo service nginx restart

13. Ya con esto podremos hacer las solicitudes directamente al balanceador. Procedemos a hacer una prueba con nuestra maquina clientesql.

Instalar un cliente de MariaDB para hacer las solicitudes

- sudo apt update
- sudo apt-get install mariadb-client

Hay que tener en cuenta que primero hay que crear un usuario al que se le permita hacer solicitudes desde cualquier host

Nos dirigimos al nodo 1 y entramos a la consola de MariaDB con 

- mysql -u root -p

En la consola usamos el siguiente comando para la creación de dicho usuario

- GRANT ALL PRIVILEGES ON . TO 'usuario1'@'%' IDENTIFIED BY 'usuario1'; // Puede cambiar 'usuario1' por el nombre que le quiera dar

Para actualizar los permisos se usa el siguiente comando

- flush privileges;

Luego de esto podemos salir de la consola del nodo 1 y volver a nuestro cliente sql

14. Entramos a nuestro cluster de base de datos realizando la solicitud al balanceador directamente

- mysql -h 192.168.70.8 -u usuario1 -p //PARA ENTRAR A LA BASE DE DATOS DESDE EL BALANCEADOR

Te pedira la contraseña del usuario y estaras dentro de la consola de comandos de la base de datos, puedes hacer una prueba intentando crear una base de datos como se hizo en pasos anteriores y despues de esto corroborar directamente en todos los nodos que se creo la base de datos.

Con todos estos pasos ya tienes configurado tu cluster de 4 nodos con balanceador de carga. Gracias por seguir esta guia.
Las personas encargadas de hacer posible este proyecto fueron:

Daniel Alejandro Pedroza - daniel_ale.pedroza@uao.edu.co

Eduardo Jose Rodriguez - eduardo_j.rodriguez@uao.edu.co

Juan Camilo Ospina - juan_c.ospina_o@uao.edu.co

Seyner Andres Trujillo - seyner.trujillo@uao.edu.co

Cualquier duda no dudes en contactarnos via correo electronico, estamos para colaborar ;).