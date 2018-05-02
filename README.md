# aspace_deploy
Ansible playbooks for deploying Archivesspace instances for new clients &amp; upgrading existing clients.

These scripts are a reworking of stuff from appstrap (https://github.com/ucldc/appstrap) and our focused only on new client instances and updating exisiting client instances.

They are designed for Archivesspace 1.3.0 and on.

These will be much simplified from the existing ansible playbooks, since it will be in single client per instance mode. Currently, the install uses a multi-tenant mode which is very cumbersome.

The front end proxy machine & VPC networks already exist. See appstrap for details.

The rds instance must have the DB Paramter Group modified to set log_bin_trust_function_creators == 1 (on).

## Upgrade procedure

The aspace upgrades are proving to be a bit more troublesome than I'd like,
especially for instances that have been migrated from Archivist's Toolkit. In
order to mitigate any problems, using the flexibility of AWS has given a
foolproof method for upgrading, with easy rollbacks if needed.
This involves creating a parallel environment with a new RDS instance and new
Ec2 instances for the new version.

0. Create the modified version of the Archivesspace that our AT migrated
   instances require. Put the built zip file on the aspace front server in the
   same directory with the setup_new_client_instance.yml.
1. Take a db snapshot of the existing RDS server.
2. Create a new RDS MySQL instance. NOTE: need to make ansible playbook for
   this. Parameters are as follows:
  * MySQL community edition
  * Multi-AZ Deployment & Provisioned IOPS storage
  * Current instance size: db.t2.small (2015-10-23)
  * Current storage: 16GB (2015-10-23)
  * Admin user is rds_aspace_admin
  * Create in the aspace-vpc
  * security group is "default"
  * DB parameter group is "aspace" (for the binary logging issue)
  * Set Backup retention to 7 days, maintenance window for early sunday morning.
  * Allow minor version upgrades with window early monday morning.
3. Shutoff access to the aspace instances by running
   /home/ec2-user/bin/maintenance.sh on the aspace front machine.
4. Dump all DBs in existing RDS instance to file:
   `mysqldump -h <current RDS endpoint> -u rds_aspace_admin --all-databases -p >
   all-dbs.sql`
5. Create new databases in new instance:
   `mysql -h <new RDS endpoint> -u rds_aspace_admin -p < all-dbs.sql`
6.  Modify the group_vars/all to update the Archivesspace version and sha256sum.
7. Create new instances for each client:
   `ansible-playbook -i hosts create_aspace_instance.yml --extra-vars="client_name=<client_name>"`
8. Run the setup_new_client_instance.yml for each client:
   `ansible-playbook -i hosts setup_new_client_instance.yml --vault-password-file=~/.vault_password --limit=<vX.X.X>`
9. Verify that the aspace app is running correctly. Monit should eventually
   report that it is running & you can check the logs on the machine. The logs
   will be at /home/&lt;client_name&gt;/archivesspace/logs/archivesspace.out.
10. Modify the entries in the nginx.conf on the apsace front to point at the IPs
    for the new client instances.

## Modifying Archivesspace Releases to work with our AT migrated instances
There is a problem with the DB migrations for a couple of our aspace instances
that were migrated from Archivist's Toolkit.
The solution for the UCSF DB came from Mark Cooper and involves explicitly setting the ids for a particular migration. [See this google group posting](https://groups.google.com/forum/#!topic/archivesspace/olsmrF2smNg).
Basically you need to add `:id => row[:id],` below the `self[:job].insert(:repo_id => row[:repo_id],` line in the common/db/migrations/037_generalized_job_table.rb

Once the changes for the current build are made, run `./scripts/build_release <version number in form vX.X.X>` to produce the zip file to place in the ansible playbook directory.

For the UCMPPDC data that was imported from AT, needed to do the following to
the sql db before migrating 1.2 -> 1.3.

    select * from group_permission where permission_id>=27;
    +-----+---------------+----------+
    | id  | permission_id | group_id |
    +-----+---------------+----------+
    | 121 |            27 |        1 |
    | 122 |            28 |        1 |
    | 123 |            29 |        1 |
    | 124 |            30 |        1 |
    | 125 |            31 |        1 |
    +-----+---------------+----------+
    5 rows in set (0.00 sec)
    
    mysql> select * from group_permission where id>=121;
    +-----+---------------+----------+
    | id  | permission_id | group_id |
    +-----+---------------+----------+
    | 121 |            27 |        1 |
    | 122 |            28 |        1 |
    | 123 |            29 |        1 |
    | 124 |            30 |        1 |
    | 125 |            31 |        1 |
    +-----+---------------+----------+
    5 rows in set (0.01 sec)
    
    mysql> delete * from group_permission where id>=121;
