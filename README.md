# aspace_deploy
Ansible playbooks for deploying Archivesspace instances for new clients &amp; upgrading existing clients.

These scripts are a reworking of stuff from appstrap (https://github.com/ucldc/appstrap) and are focused only on new client instances and updating exisiting client instances.

They are designed for Archivesspace 1.3.0 and on.

These will be much simplified from the existing ansible playbooks, since it will be in single client per instance mode. Currently, the install uses a multi-tenant mode which is very cumbersome.

The front end proxy machine & VPC networks already exist. See appstrap for details.

The rds instance must have the DB Parameter Group modified to set log_bin_trust_function_creators == 1 (on).

## Upgrade procedure

The aspace upgrades are proving to be a bit more troublesome than I'd like,
especially for instances that have been migrated from Archivist's Toolkit. In
order to mitigate any problems, using the flexibility of AWS has given a
foolproof method for upgrading, with easy rollbacks if needed.
This involves creating a parallel environment with a new RDS instance and new
Ec2 instances for the new version.

0. Put the built zip file for the new version of ASpace on the aspace front server in the
   same directory with the setup_new_client_instance.yml.
   
1. Take a db snapshot of the existing RDS server. [Note: not quite sure what purpose this serves, other than being extra precautious?]

2. Create a new RDS MySQL instance. Refer to setup of existing RDS MySQL instance for parameters to use. NOTE: need to make ansible playbook for this. 

3. Shutoff access to the aspace instances by running

   `/home/ec2-user/bin/maintenance.sh on` on the aspace front machine.
   
4. Dump all DBs in existing RDS instance to file, e.g.:

   `mysqldump --databases ucsf ucmppdc ucbeda ucsc ucrcmp uclaclark ucm ucla uclacsrc uci -h <existing RDS endpoint> -u rds_aspace_admin -p > sqldump-x-x-x.sql`
   
5. Create new databases in new instance:

   `mysql -h <new RDS endpoint> -u rds_aspace_admin -p < sqldump-x-x-x.sql`
   
   Tag the RDS instance with Program = dsc, Service = aspace, Environment = prd
   
6.  Modify the `group_vars/all` file to update the `aspace_version` and `db_server`. Note: be sure to use the RDS cluster endpoint for the `db_server`.

7. Create new instances for each client:

   ` cat client-list.csv |xargs -i@ ansible-playbook create_aspace_instance.yml --extra-vars="client_name=@"`
   
8. Run the setup_new_client_instance.yml for each client (This involves a 15 minute wait at the end. Can take a while for everything to come up properly.):

   `ansible-playbook -i hosts setup_new_client_instance.yml --vault-password-file=~/.vault_password --limit=<vX.X.X>`
   
9. Verify that the aspace app is running correctly: `ansible -i ~/code/aspace_deploy/hosts -a "sudo monit summary" vX.X.X`

   Monit should eventually report that it is running & you can check the logs on the machine. 
   
   The (very verbose) aspace logs will be at `/home/<client_name>/archivesspace/logs/archivesspace.out`
   
10. Modify the entries in `nginx.conf/nginx.conf` on the apsace front to point at the IPs for the new client instances:

    `ansible-playbook -i hosts update_nginx_conf.yml --limit=<old-version> --extra-vars="previous_version=<new-version>"`

11. Make sure the config file is good:
    
    `sudo /etc/init.d/nginx configtest`
    
    Restart nginx:
    
    `sudo /etc/init.d/nginx restart`
