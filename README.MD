## Provisioning servers with Terraform
## clone the git repo on DevOps system
ssh -i web-vpc-keypair.pem ec2-user@<public_ip_of_devops_system>;
git clone <github-repo>;
cd <repo-dir>/terraform;
export AWS_ACCESS_KEY_ID="secret";
export AWS_SECRET_ACCESS_KEY="secret";
terraform init;
terraform plan;
terraform apply;

## Setup password less authentication from DevOps to web and monitoring systems
## Create ansible user on all systems (devops, web & monitoring)
## login to all systems and create user 'ansible'
useradd ansible;
## Generate SSH private/public keys with RSA and no passphrase
sudo su - ansible;
ssh-keygen;
## Copy devops public key to other systems authorizes_keys file (to be created in .ssh dir in ansible  home dir). We can also use ssh-copy-id CLI as well.
## Check SSH connectivity from DevOps system to other systems

## Install Ansible on DevOps system
# I followed below web link for installing ansible using python-pip. But can use another ways to install 
# Ansible and configure.
https://www.tecmint.com/install-ansible-on-centos-rhel-8/

## Install and configure Prometheus and Grafana on Monitoring system
cd <repo-dir>/ansible;
ansible-playbook -i hosts-monitoring.yml playbook-monitoring.yml -u ansible;

## Above playbook does following tasks
#    - Download and configure Prometheus Node Exporter on Web and Monitoring systems
#    - Download and configure Apache Exporter on web system
#    - Download and configure Prometheus on Monitoring system
#    - Install and configure Grafana on Monitoring system
#    - Create Datasource and Dashboards automatically


### Further improvements
## Extend the infra provisioning with Terraform to acheive below.
#    - Handling terraform state (use s3 or terraform cloud to keep the state files to make it secure)
#    - Create ALB and target groups to hide web application under ALB for security and load bancing
#    - May be another better way to make SSH connections from DevOps to other systems for running Ansible #      Playbooks. ex. Integrations with IAM etc.