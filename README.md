# seatctl

Manage virtual machine for workshops and playgrounds

## Notes

Use provider `hcloud` (Hetzner Cloud) to add 5 virtual machines prefixed with `--name foo` starting with index 1 including tags `owner=seatctl`, `seat-set=foo`, `index=N`:

```bash
seactl --provider hcloud --start-index 1 --count 5 add --name foo
seactl --provider hcloud --list 1,2,5              add --name foo
```

Remove virtual machines:

```bash
seactl --provider hcloud --start-index 1 --count 5 remove --name foo
seactl --provider hcloud --list 1,2,5              remove --name foo
```

Run command on multiple virtual machines:

```bash
seactl --start-index 1 --count 5 run --name foo -- hostname
seactl --list 1,2,5              run --name foo -- hostname
```

Use my package management to install tools:

```bash
seactl --start-index 1 --count 5 install --name foo --packages docker,docker-compose
seactl --list 1,2,5              install --name foo --packages kind,kubectl
```

Add user and set password on virtual machine:

```bash
seactl --start-index 1 --count 5 user --name foo --username bar --random-password
seactl --list 1,2,5              user --name foo --username bar --password blarg
```

Add DNS record for virtual machines:

```bash
seactl --provider cloudflare --start-index 1 --count 5 dns --name foo --action add    --domain example.com
seactl --provider cloudflare --list 1,2,5              dns --name foo --action remove --domain example.com
```
