# linx

## Requisitos

Para testar os playbooks é preciso os seguintes requisitos:

1. VM Ubuntu 18.04 LTS
2. python,python3
3. Acesso SSH ao cliente.
4. Servidor de Gerenciamento de Configuração Ansible
5. Conta de e-mail "gmail", com a opção de "lesssecureapps" habilitada

## Descrição dos Arquivos

1. **linxapp.js** : Aplicação enviada pela Linx, ela abre a porta 3000 e apresenta a mensagem "Hello World!"
2. **package.json**: Metadados da aplicação, aqui se inserem as dependencias.
3. **load-balancer.conf**: Arquivo de configuração de proxy reverso para o nginx com load balance configurado.
4. **parserlog.py**: Script de parseamento dos logs de acesso do nginx, e encarregado de enviar e-mail
5. **linxdeploy.yml**: Playbook de deploy, encarregado de fazer backup do diretório node_modules, package.json da aplicação node e instalar as novas dependencias, a aplicação é restartada utilizando PM2 reload, garantindo zero downtime.
6. **linxrollback.yml**: Playbook de rollback, encarregado de voltar à versão anterior do diretório node_modules e package.json,a aplicação é restartada utilizando PM2 reload, garantindo zero downtime.
7. **linxbenchmark.yml**: Playbook encarregado de iniciar o script de benchmark na VM. O resultado é printado na tela.
8. **linxparserlog.yml**: Playbook que executa o script de parseamento dos logs do nginx. O resultado é printado na tela.
9. **watchdog.j2**: Arquivo Jinja que irá se transformar no script de monitoramento das aplicações nginx, e node. 
10. **linxinventory.cfg**: Arquivo de inventário do Ansible, aqui será setada os parâmetros para conexão.
11. **benchmark.j2**: Template Jinja dos testes de carga da aplicação utilizando o utilitario "ab".
12. **linxmain.yml**: Playbook principal, ele irá fazer as seguintes tarefas:
 * Instalação dos pacotes git,openssl,apache2-utils,node,PM2,nginx.
 * Criação do diretório "linxapp" e "node",  assim como a copia dos arquivos linxapp.js, package.json,parserlog.py,watchdog.bash,benchmark.bash.
 * Criação dos symbolic link, para ter os binários node, npm, npx, pm2 disponivéis em todo o sistema.
 * Instalação da dependencia "express".
 * Iniciar a aplicação linxapp.js utilizando PM2 em modo cluster mode, um processo per CPU core.
 * Criação de um Self-Signed certificado digital para que funcione o https.
 * Configuração do NGINX, utilizando load-balance.
 * Configuração da crontab de root, de forma a que o script de monitoração watchdog.bash rode a cada 5 minutos.
 * Configuração da crontab de root, de forma a que o script de parseamento parserlog.py rode a meianoite.


## Procedimento de Teste.

1. Clonar o repositorio git no servidor Ansible.
  * git clone https://github.com/JoseBalbuena/linx.git
  

2. Entrar no diretório "linx" criado no servidor ansible, e modificar os parâmetros de conexão dentro do arquivo linxinventory.cfg
```
[linx]
12.12.12.3
[linx:vars]
ansible_ip=12.12.12.3
ansible_user=osboxes
ansible_ssh_pass=osboxes.org
ansible_sudo_pass=osboxes.org
ansible_python_interpreter=python3
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
```

3. Para o envio de e-mail funcionar, criar uma conta de gmail, e habilitar o parâmetro "lesssecureapp"
  * https://www.google.com/settings/security/lesssecureapps

4. No script parser.py inserir os dados de e-mail, senha da conta criada
```
port = 587  # For starttls
smtp_server = "smtp.gmail.com"
sender_email = "jbalbuen22@gmail.com"
receiver_email = "jbalbuen22@gmail.com"
password = "XXXXXXXX" 
message = msg 
```

5. Executar o playbook principal linxmain.yml
```
ansible-playbook -i linxinventory.cfg linxmain.yml 
```

Finalizado o playbook, você deverá ter um ambiente totalmente funcional, testando:
```
[jose@rejane linx]$ curl http://12.12.12.3/
Hello World!
[jose@rejane linx]$ 
[jose@rejane linx]$ curl -k https://12.12.12.3/
Hello World!
[jose@rejane linx]$ 
```

Número de processo nodes, um por core CPU, executando comando pm2 status na VM:
```
osboxes@osboxes:~$ nproc
2
osboxes@osboxes:~$ pm2 status
┌──────────┬────┬─────────┬─────────┬──────┬────────┬─────────┬────────┬──────┬───────────┬─────────┬──────────┐
│ App name │ id │ version │ mode    │ pid  │ status │ restart │ uptime │ cpu  │ mem       │ user    │ watching │
├──────────┼────┼─────────┼─────────┼──────┼────────┼─────────┼────────┼──────┼───────────┼─────────┼──────────┤
│ linxapp  │ 0  │ 1.0.0   │ cluster │ 8769 │ online │ 0       │ 3m     │ 0.1% │ 41.7 MB   │ osboxes │ disabled │
│ linxapp  │ 1  │ 1.0.0   │ cluster │ 8776 │ online │ 0       │ 3m     │ 0.1% │ 42.0 MB   │ osboxes │ disabled │
└──────────┴────┴─────────┴─────────┴──────┴────────┴─────────┴────────┴──────┴───────────┴─────────┴──────────┘
 Use `pm2 show <id|name>` to get more details about an app
osboxes@osboxes:~$ 
```

Verificando a instalação da dependencia "express" da aplicação node:
```
osboxes@osboxes:~/linxapp$ npm list
linxapp@1.0.0 /home/osboxes/linxapp
└─┬ express@4.16.4
  ├─┬ accepts@1.3.5
```

Verificando crontab de root, com o script de monitoramento a ser executado a cada 5 min:
```
osboxes@osboxes:~$ sudo su -
[sudo] password for osboxes: 
root@osboxes:~# crontab -l
#Ansible: check nginx linxapp processes
*/5 * * * * /home/osboxes/linxapp/watchdog.bash > /dev/null
#Ansible: parser log script
0 0 * * * /home/osboxes/linxapp/parserlog.py > /dev/null
root@osboxes:~# 
```

6. Dentro do diretório "linx" no servidor ansible modificar o arquivo package.json, adicionando uma nova dependencia 
```
"underscore"
  "dependencies": {
          "underscore": "latest",
      	  "express": "latest"
  },
```
7. Executar o playbook de deploy:
```
[jose@rejane linx]$ ansible-playbook -i linxinventory.cfg linxdeploy.yml 
```
Verificando se o backup do node_modules foi executado:
```
osboxes@osboxes:~/linxapp$ ls -ltrah | grep -i modules
drwxrwxr-x 51 osboxes osboxes 4.0K Apr 10 17:13 node_modules.bkp
drwxrwxr-x 52 osboxes osboxes 4.0K Apr 10 17:13 node_modules
osboxes@osboxes:~/linxapp$ 
```

Verificando se a dependencia nova foi instalada:
```
osboxes@osboxes:~/linxapp$ npm list
...
...
└── underscore@1.9.1

osboxes@osboxes:~/linxapp$ 
```

8. Executando playbook de rollback:
```
[jose@rejane linx]$ ansible-playbook -i linxinventory.cfg linxrollback.yml 
```
Verificando se a dependencia foi removida:
```
osboxes@osboxes:~/linxapp$ npm list
...
...
├─┬ type-is@1.6.16
  │ ├── media-typer@0.3.0
  │ └── mime-types@2.1.22 deduped
  ├── utils-merge@1.0.1
  └── vary@1.1.2

osboxes@osboxes:~/linxapp$ 
osboxes@osboxes:~/linxapp$ 
```


9. Parando os processos nginx e pm2.
```
osboxes@osboxes:~/linxapp$ sudo systemctl stop nginx
[sudo] password for osboxes: 
osboxes@osboxes:~/linxapp$ pm2 stop linxapp
[PM2] Applying action stopProcessId on app [linxapp](ids: 0,1)
[PM2] [linxapp](0) ✓
[PM2] [linxapp](1) ✓
┌──────────┬────┬─────────┬─────────┬─────┬─────────┬─────────┬────────┬─────┬────────┬─────────┬──────────┐
│ App name │ id │ version │ mode    │ pid │ status  │ restart │ uptime │ cpu │ mem    │ user    │ watching │
├──────────┼────┼─────────┼─────────┼─────┼─────────┼─────────┼────────┼─────┼────────┼─────────┼──────────┤
│ linxapp  │ 0  │ 1.0.0   │ cluster │ 0   │ stopped │ 2       │ 0      │ 0%  │ 0 B    │ osboxes │ disabled │
│ linxapp  │ 1  │ 1.0.0   │ cluster │ 0   │ stopped │ 2       │ 0      │ 0%  │ 0 B    │ osboxes │ disabled │
└──────────┴────┴─────────┴─────────┴─────┴─────────┴─────────┴────────┴─────┴────────┴─────────┴──────────┘
 Use `pm2 show <id|name>` to get more details about an app
osboxes@osboxes:~/linxapp$ ps -ef | grep -i nginx
osboxes  10713 10065  0 17:19 pts/0    00:00:00 grep --color=auto -i nginx
osboxes@osboxes:~/linxapp$ 
```

Esperar uns 5 minutos, os processos deveriam ter sido levantados sozinhos pelo script whatchdog.bash na cron de root.

```
osboxes@osboxes:~/linxapp$ sudo su -
root@osboxes:~# crontab -l
#Ansible: check nginx linxapp processes
*/5 * * * * /home/osboxes/linxapp/watchdog.bash > /dev/null
#Ansible: parser log script
0 0 * * * /home/osboxes/linxapp/parserlog.py > /dev/null
root@osboxes:~# exit
osboxes@osboxes:~/linxapp$ ps -ef | grep -i nginx
root     10734     1  0 17:20 ?        00:00:00 nginx: master process /usr/sbin/nginx -g daemon on; master_process on;
www-data 10736 10734  0 17:20 ?        00:00:00 nginx: worker process
www-data 10737 10734  0 17:20 ?        00:00:00 nginx: worker process
osboxes  10781 10065  0 17:20 pts/0    00:00:00 grep --color=auto -i nginx
osboxes@osboxes:~/linxapp$ pm2 status
┌──────────┬────┬─────────┬─────────┬───────┬────────┬─────────┬────────┬──────┬───────────┬─────────┬──────────┐
│ App name │ id │ version │ mode    │ pid   │ status │ restart │ uptime │ cpu  │ mem       │ user    │ watching │
├──────────┼────┼─────────┼─────────┼───────┼────────┼─────────┼────────┼──────┼───────────┼─────────┼──────────┤
│ linxapp  │ 0  │ 1.0.0   │ cluster │ 10758 │ online │ 2       │ 15s    │ 0.1% │ 42.0 MB   │ osboxes │ disabled │
│ linxapp  │ 1  │ 1.0.0   │ cluster │ 10765 │ online │ 2       │ 15s    │ 0.2% │ 41.3 MB   │ osboxes │ disabled │
└──────────┴────┴─────────┴─────────┴───────┴────────┴─────────┴────────┴──────┴───────────┴─────────┴──────────┘
 Use `pm2 show <id|name>` to get more details about an app
osboxes@osboxes:~/linxapp$ 
```

10. Fazendo testes de troughput bechmark, para isso existe o script benchmark.bash que foi copiado na VM, caso eu queira testar utilizar o playbook linxbenchmark.yml

```
[jose@rejane linx]$ ansible-playbook -i linxinventory.cfg linxbenchmark.yml 
```

O resultado dos testes será printando na tela.

11. Fazendo teste de parseamento de log, para isso foi criado o script em python parser.py, e um playbook para testar:

O resultado será mostrado na tela e enviado via email para a conta de gmail previamente configurada. Lembrando que não temos página configurada então o resultado irá mostrar sempre "/" que é o que aparece no log do nginx.

```
[jose@rejane linx]$ ansible-playbook -i linxinventory.cfg linxparserlog.yml 

PLAY [all] ********************************************************************************************************************

TASK [Gathering Facts] ********************************************************************************************************
ok: [12.12.12.3]

TASK [Run parser script] ******************************************************************************************************
changed: [12.12.12.3]

TASK [debug] ******************************************************************************************************************
ok: [12.12.12.3] => {
    "msg": [
        "300002|/|200"
    ]
}

PLAY RECAP ********************************************************************************************************************
12.12.12.3                 : ok=3    changed=1    unreachable=0    failed=0   

[jose@rejane linx]$ 
```








