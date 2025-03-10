---
stage: Data Stores
group: Database
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# PostgreSQL **(FREE SELF)**

This page contains information about PostgreSQL the GitLab Support team uses
when troubleshooting. GitLab makes this information public, so that anyone can
make use of the Support team's collected knowledge.

WARNING:
Some procedures documented here may break your GitLab instance. Use at your
own risk.

If you're on a [paid tier](https://about.gitlab.com/pricing/) and aren't sure
how to use these commands, [contact Support](https://about.gitlab.com/support/)
for assistance with any issues you're having.

## Other GitLab PostgreSQL documentation

This section is for links to information elsewhere in the GitLab documentation.

### Procedures

- [Connect to the PostgreSQL console](https://docs.gitlab.com/omnibus/settings/database.html#connecting-to-the-bundled-postgresql-database).

- [Database procedures for Linux package installations](https://docs.gitlab.com/omnibus/settings/database.html) including:
  - SSL: enabling, disabling, and verifying.
  - Enabling Write Ahead Log (WAL) archiving.
  - Using an external (non-Omnibus) PostgreSQL installation; and backing it up.
  - Listening on TCP/IP as well as or instead of sockets.
  - Storing data in another location.
  - Destructively reseeding the GitLab database.
  - Guidance around updating packaged PostgreSQL, including how to stop it
    from happening automatically.

- [Information about external PostgreSQL](../postgresql/external.md).

- [Running Geo with external PostgreSQL](../geo/setup/external_database.md).

- [Upgrades when running PostgreSQL configured for HA](https://docs.gitlab.com/omnibus/settings/database.html#upgrading-a-gitlab-ha-cluster).

- Consuming PostgreSQL from [within CI runners](../../ci/services/postgres.md).

- Managing PostgreSQL versions on Linux package installations [from the development docs](https://docs.gitlab.com/omnibus/development/managing-postgresql-versions.html).

- [PostgreSQL scaling](../postgresql/replication_and_failover.md)
  - Including [troubleshooting](../postgresql/replication_and_failover.md#troubleshooting)
    `gitlab-ctl patroni check-leader` and PgBouncer errors.

- [Developer database documentation](../../development/feature_development.md#database-guides),
  some of which is absolutely not for production use. Including:
  - Understanding EXPLAIN plans.

## Support topics

### Database deadlocks

References:

- [Issue #1 Deadlocks with GitLab 12.1, PostgreSQL 10.7](https://gitlab.com/gitlab-org/gitlab/-/issues/30528).
- [Customer ticket (internal) GitLab 12.1.6](https://gitlab.zendesk.com/agent/tickets/134307)
  and [Google doc (internal)](https://docs.google.com/document/d/19xw2d_D1ChLiU-MO1QzWab-4-QXgsIUcN5e_04WTKy4).
- [Issue #2 deadlocks can occur if an instance is flooded with pushes](https://gitlab.com/gitlab-org/gitlab/-/issues/33650).
  Provided for context about how GitLab code can have this sort of
  unanticipated effect in unusual situations.

```plaintext
ERROR: deadlock detected
```

Three applicable timeouts are identified in the issue [#30528](https://gitlab.com/gitlab-org/gitlab/-/issues/30528); our recommended settings are as follows:

```ini
deadlock_timeout = 5s
statement_timeout = 15s
idle_in_transaction_session_timeout = 60s
```

Quoting from issue [#30528](https://gitlab.com/gitlab-org/gitlab/-/issues/30528):

<!-- vale gitlab.FutureTense = NO -->

> "If a deadlock is hit, and we resolve it through aborting the transaction after a short period, then the retry mechanisms we already have will make the deadlocked piece of work try again, and it's unlikely we'll deadlock multiple times in a row."

<!-- vale gitlab.FutureTense = YES -->

NOTE:
In Support, our general approach to reconfiguring timeouts (applies also to the
HTTP stack) is that it's acceptable to do it temporarily as a workaround. If it
makes GitLab usable for the customer, then it buys time to understand the
problem more completely, implement a hot fix, or make some other change that
addresses the root cause. Generally, the timeouts should be put back to
reasonable defaults after the root cause is resolved.

In this case, the guidance we had from development was to drop `deadlock_timeout`
or `statement_timeout`, but to leave the third setting at 60 seconds. Setting
`idle_in_transaction` protects the database from sessions potentially hanging for
days. There's more discussion in [the issue relating to introducing this timeout on GitLab.com](https://gitlab.com/gitlab-com/gl-infra/production/-/issues/1053).

PostgreSQL defaults:

- `statement_timeout = 0` (never)
- `idle_in_transaction_session_timeout = 0` (never)

Comments in issue [#30528](https://gitlab.com/gitlab-org/gitlab/-/issues/30528)
indicate that these should both be set to at least a number of minutes for all
Linux package installations (so they don't hang indefinitely). However, 15 s
for `statement_timeout` is very short, and is only effective if the
underlying infrastructure is very performant.

See current settings with:

```shell
sudo gitlab-rails runner "c = ApplicationRecord.connection ; puts c.execute('SHOW statement_timeout').to_a ;
puts c.execute('SHOW deadlock_timeout').to_a ;
puts c.execute('SHOW idle_in_transaction_session_timeout').to_a ;"
```

It may take a little while to respond.

```ruby
{"statement_timeout"=>"1min"}
{"deadlock_timeout"=>"0"}
{"idle_in_transaction_session_timeout"=>"1min"}
```

These settings can be updated in `/etc/gitlab/gitlab.rb` with:

```ruby
postgresql['deadlock_timeout'] = '5s'
postgresql['statement_timeout'] = '15s'
postgresql['idle_in_transaction_session_timeout'] = '60s'
```

Once saved, [reconfigure GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) for the changes to take effect.

NOTE:
These are Linux package settings. If an external database, such as a customer's PostgreSQL installation
or Amazon RDS is being used, these values don't get set, and would have to be set externally.

### Temporarily changing the statement timeout

WARNING:
The following advice does not apply in case
[PgBouncer](../postgresql/pgbouncer.md) is enabled,
because the changed timeout might affect more transactions than intended.

In some situations, it may be desirable to set a different statement timeout
without having to [reconfigure GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation),
which in this case would restart Puma and Sidekiq.

For example, a backup may fail with the following errors in the output of the
[backup command](../../administration/backup_restore/index.md#back-up-gitlab)
because the statement timeout was too short:

```plaintext
pg_dump: error: Error message from server: server closed the connection unexpectedly
```

You may also see errors in the [PostgreSQL logs](../logs/index.md#postgresql-logs):

```plaintext
canceling statement due to statement timeout
```

To temporarily change the statement timeout:

1. Open `/var/opt/gitlab/gitlab-rails/etc/database.yml` in an editor
1. Set the value of `statement_timeout` to `0`, which sets an unlimited statement timeout.
1. [Confirm in a new Rails console session](../operations/rails_console.md#using-the-rails-runner)
   that this value is used:

   ```shell
   sudo gitlab-rails runner "ActiveRecord::Base.connection_config[:variables]"
   ```

1. Perform the action for which you need a different timeout
   (for example the backup or the Rails command).
1. Revert the edit in `/var/opt/gitlab/gitlab-rails/etc/database.yml`.

## Troubleshooting

### Database is not accepting commands to avoid wraparound data loss

This error likely means that `autovacuum` is failing to complete its run:

```plaintext
ERROR:  database is not accepting commands to avoid wraparound data loss in database "gitlabhq_production"
```

Or

```plaintext
 ERROR:  failed to re-find parent key in index "XXX" for deletion target page XXX
```

To resolve the error, run `VACUUM` manually:

1. Stop GitLab with the command `gitlab-ctl stop`.
1. Place the database in single-user mode with the command:

   ```shell
   /opt/gitlab/embedded/bin/postgres --single -D /var/opt/gitlab/postgresql/data gitlabhq_production
   ```

1. In the `backend>` prompt, run `VACUUM;`. This command can take several minutes to complete.
1. Wait for the command to complete, then press <kbd>Control</kbd> + <kbd>D</kbd> to exit.
1. Start GitLab with the command `gitlab-ctl start`.

### GitLab database requirements

The [database requirements](../../install/requirements.md#database) for GitLab include:

- Support for MySQL was removed in [GitLab 12.1](../../update/index.md#1210).
- Review and install the [required extension list](../../install/postgresql_extensions.md).

### Serialization errors in the `production/sidekiq` log

If you receive errors like this example in your `production/sidekiq` log, read
about [setting `default_transaction_isolation` into read committed](https://docs.gitlab.com/omnibus/settings/database.html#set-default_transaction_isolation-into-read-committed) to fix the problem:

```plaintext
ActiveRecord::StatementInvalid PG::TRSerializationFailure: ERROR:  could not serialize access due to concurrent update
```

### PostgreSQL replication slot errors

If you receive errors like this example, read about how to resolve PostgreSQL HA
[replication slot errors](https://docs.gitlab.com/omnibus/settings/database.html#troubleshooting-upgrades-in-an-ha-cluster):

```plaintext
pg_basebackup: could not create temporary replication slot "pg_basebackup_12345": ERROR:  all replication slots are in use
HINT:  Free one or increase max_replication_slots.
```

### Geo replication errors

If you receive errors like this example, read about how to resolve
[Geo replication errors](../geo/replication/troubleshooting.md#fixing-postgresql-database-replication-errors):

```plaintext
ERROR: replication slots can only be used if max_replication_slots > 0

FATAL: could not start WAL streaming: ERROR: replication slot "geo_secondary_my_domain_com" does not exist

Command exceeded allowed execution time

PANIC: could not write to file 'pg_xlog/xlogtemp.123': No space left on device
```

### Review Geo configuration and common errors

When troubleshooting problems with Geo, you should:

- Review [common Geo errors](../geo/replication/troubleshooting.md#fixing-common-errors).
- [Review your Geo configuration](../geo/replication/troubleshooting.md), including:
  - Reconfiguring hosts and ports.
  - Reviewing and fixing the user and password mappings.

### Mismatch in `pg_dump` and `psql` versions

If you receive errors like this example, read about how to
[back up and restore a non-packaged PostgreSQL database](https://docs.gitlab.com/omnibus/settings/database.html#backup-and-restore-a-non-packaged-postgresql-database):

```plaintext
Dumping PostgreSQL database gitlabhq_production ... pg_dump: error: server version: 13.3; pg_dump version: 14.2
pg_dump: error: aborting because of server version mismatch
```

### Extension `btree_gist` is not allow-listed

Deploying PostgreSQL on an Azure Database for PostgreSQL - Flexible Server may result in this error:

```plaintext
extension "btree_gist" is not allow-listed for "azure_pg_admin" users in Azure Database for PostgreSQL
```

To resolve this error, [allow-list the extension](https://learn.microsoft.com/en-us/azure/postgresql/flexible-server/concepts-extensions#how-to-use-postgresql-extensions) prior to install.
