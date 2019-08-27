None closed bouwdossiers files.
Exported from `stadsarchief` database:

```
COPY (select unnest(bestanden) as whitelisted from stadsarchief_subdossier sub, stadsarchief_bouwdossier bd where bd.id = sub.bouwdossier_id and bd.access = 'P' order by 1) to '/tmp/stadsarchief_whitelist' with CSV;
```
