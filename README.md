# linx

## Requisitos

Para testar os playbooks é preciso os seguintes requisitos:

1. Ubuntu 18.04 LTS
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
 * Criação do diretório "linxapp" e copia dos arquivos linxapp.js, package.json,parserlog.py,watchdog.bash,benchmark.bash.
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

2. Modificar os parâmetros de conexão dentro do arquivo linxinventory.cfg
```
[linx]
12.12.12.3
[linx:vars]
ansible_ip=12.12.12.3
ansible_user=osboxes
ansible_ssh_pass=osboxes.org
ansible_sudo_pass=osboxes.org
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
```

