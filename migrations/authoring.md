# Migration Authoring

**Append a new immutable migration for every change; never rewrite history that any environment may have applied.**

Use this guide when creating or reviewing a pg-migrate SQL file and its manifest entry. It defines the append-only rule, transaction directive, manifest-v1 format, and safe authoring workflow.

## Keep applied history immutable

Never edit an applied component name, migration basename, manifest position, SQL byte—including comments or whitespace—kind, or transaction mode. Append a corrective migration instead. If there is any chance another environment applied the file, treat it as immutable.

Use the service CLI’s `new` command to create the next file and append its manifest entry atomically:

```console
my-service-migrate new \
  --manifest migrations/application/manifest \
  --name 0003-add-status \
  --description "Add status"
```

Review and fill in the SQL, run `check`, rebuild the embedding module, then inspect `plan` and `list`.

## Prefer transactional SQL

SQL is transactional by default and may contain multiple statements. Do not write `BEGIN`, `COMMIT`, other transaction control, psql meta-commands, or `COPY FROM STDIN`; the runner owns the transaction boundary.

Use nontransactional mode only when PostgreSQL prohibits the command in a transaction. The exact directive must occur in the leading line-comment region, and the file must contain exactly one SQL statement:

```sql
-- pg-migrate: no-transaction
CREATE INDEX CONCURRENTLY accounts_email_idx ON accounts (email);
```

Unknown or duplicate `pg-migrate:` directives and directives placed after SQL begins are rejected. Codd-specific comments are ordinary inert SQL comments; they do not select pg-migrate transaction mode.

## Keep manifest v1 deliberately plain

The `manifest` contains exactly one relative, top-level, lowercase `.sql` filename per line. It has no comments, blank lines, header, nested paths, or duplicate entries. Validation rejects a UTF-8 BOM, invalid UTF-8, leading or trailing whitespace, missing listed files, and unlisted sibling SQL files.

Keep zero-padded numeric prefixes at one consistent width. Automatic numbering refuses irregular manifests or a next number that no longer fits the established width; choose the next explicit naming strategy rather than silently changing conventions.

## Related Patterns

- [The pg-migrate Model](./pg-migrate-model.md)
- [Service Migration Packages](./service-package.md)
- [Migration Testing](./testing.md)

