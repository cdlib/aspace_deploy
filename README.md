# aspace_deploy
Ansible playbooks for deploying Archivesspace instances for new clients &amp; upgrading existing clients.

These scripts are a reworking of stuff from appstrap (https://github.com/ucldc/appstrap) and our focused only on new client instances and updating exisiting client instances.

They are designed for Archivesspace 1.3.0 and on.

These will be much simplified from the existing ansible playbooks, since it will be in single client per instance mode. Currently, the install uses a multi-tenant mode which is very cumbersome.

The front end proxy machine & VPC networks already exist. See appstrap for details.
