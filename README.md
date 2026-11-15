# Surge rules proxy

The daily workflow downloads upstream rules into `public/surge/`, then generates
ChinaMax shards before committing the published files. The original
`blackmatrix7/ChinaMax_All.list` remains available.

## ChinaMax on Apple TV

`scripts/split-china-max.sh` copies the upstream file into **32 fixed URLs** under
`public/surge/custom/china_max/part-01.list` through `part-32.list`. It preserves
complete lines, their order, and all rule options. Concatenating the nonempty
source segments reconstructs the upstream file byte for byte. Unused shards
contain only a comment, so all 32 URLs continue to exist if the source shrinks.

Replace the original ChinaMax RULE-SET line with all 32 lines in
[`examples/china-max.conf`](examples/china-max.conf), at the same position in
your `[Rule]` section. Replace `YOUR_RULES_HOST` with your existing proxy host,
and `DIRECT` with the policy previously used by ChinaMax if different. Keep the
lines adjacent and in order. The example is a configuration snippet, not a
complete profile or an installed module.

The shard count never grows automatically, so normal upstream updates require
no configuration edits. Generation fails before writing shards if any file
exceeds 256 KiB. This is a conservative operational guardrail, **not an official
Surge limit**; successful updating still needs validation on Apple TV. A failed
generation prevents the workflow's commit/push step from running.

To regenerate from the existing local upstream copy without downloading:

```sh
bash scripts/split-china-max.sh
```

Files remain under `public/` for the existing static deployment. The existing
`/surge/custom/*` header rule also covers the shard URLs.
