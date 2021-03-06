Role Name
=========

A "meta" role to install awslogs for a given service

Requirements
------------

For use with EC2 instances.

Role Variables
--------------

To use from another role to setup awslogs for a set of logs you first must add
this role to meta/main.yml file for the role you want to support awslogs in

```yaml
dependencies:
  - { role: awslogs, become: yes, dir_dep_role_templates: "{{ dir_role_templates }}" }
```

In the dependent role using this meta role, set the following variables:

```yaml
  vars:
    awslogs_basename: <name that the system log messages will be prefixed with> 
    dir_role_templates: "roles/<name of role using this role>/templates"
```

In the dir_role_templates, there should be a "awslogs.conf.j2" that contains the the specific awslogs configuration directives to point to the logs generated by programs in the dependent role. This file will be added to the base awslogs configuration file to capture output from those files. See the sample_dependent_role_awslogs.conf.j2 for an example of a dependent role logs template.

Other issues
------------

For long running services, you should rotate the logs. the awslogs service
requires a restart after the log has been rotated. For logrotate, a typical conf
file might look like:

```
/var/log/mylogs.log {
  daily
  missingok
  notifempty
  size 50M
  create 0600 root root
  delaycompress
  compress
  rotate 4
  postrotate
    /etc/init.d/awslogs restart > /dev/null
  endscript
}
```

from: https://gist.github.com/ipedrazas/fabb17dba5e6f72f6ffd

License
-------

BSD
