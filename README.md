# abn-bulk-extract

## Description

Fetches the Australian Business Register's weekly ABN bulk extract from data.gov.au, keeps each release after the first as its changes from the one before, and reads the records of the newest release held. It's a command line for the [data_gov_au](https://rubygems.org/gems/data_gov_au) gem's `DataGovAu::AbnBulkExtract`.

data.gov.au publishes the current release alone and overwrites it in place each Tuesday, so a week not fetched is gone for good. This is the thing to run each week from a scheduler.


## Installation

### 0. Have a recent version of Ruby installed

### 1. Install the gems it uses

```shell
gem install data_gov_au switches.rb
```

### 2. Put the program on your path

```shell
git clone https://github.com/thoran/abn-bulk-extract
cp ./abn-bulk-extract/bin/abn-bulk-extract to your preferred executable path
chmod +x /path/to/abn-bulk-extract
```


## Usage

### Fetching

```shell
abn-bulk-extract abr
```

Fetches the current release if it is not already held, then sets it against the release before it. A second run in the same week makes one call to the catalogue and no download, and compares nothing.

```
release:   20261028
catalogue: 20261027
licence:   Creative Commons Attribution 3.0 Australia
held:      0 of 5 files
  public_split_1_10.zip (477 MB)
  public_split_11_20.zip (477 MB)
  bulkextract.xsd (13 kB)
  abnlookupbulkextractreadme.pdf (150 kB)
  abn-bulk-extract-resources.csv (1 kB)
```

Two dates are reported because they differ. A release is named for the date the extract carries itself, read from the names of the files inside its zips; the catalogue's own date is when data.gov.au last touched its record, which moves whether or not the data did.

With `--dry-run` it reports what it would retrieve and compare, and does neither.

### Comparing

```shell
abn-bulk-extract abr --compare
```

Sets each release held whole against the newest one before it held whole, retrieving nothing; a run without switches does the same once it has fetched. A week missed, or one held only in part, is compared across. With `--dry-run` it names what it would compare, and compares nothing. It writes the newer release's delta and frame, rebuilds that release from the older one and them, and reports the rebuild only once every file has come out exactly. Where weeks have gone uncompared, each is compared in turn, oldest first.

```
comparing: 20261104 against 20261028
  15146 added, 47985 changed, 11 removed, in 4 m 38 s
  rebuilt exactly, in 7 m 0 s
```

### Parsing

```shell
abn-bulk-extract abr --parse
```

Reads every record of the newest release held, touching nothing on the network. Each file is set against the count it carries itself, so a file which gave up fewer records than it promised is reported, and the run exits 1, rather than passing for a smaller week. So is a file which reports an error, in the `error` attribute the schema requires of each, which is `none` in a file written out whole.

```
release:   20261028
  20261028_Public01.xml  1032000 of 1032000
  ...
  20261028_Public20.xml  1023294 of 1023294
total:     20631294 records in 5 m 48 s
```

### Options

```
  -c, --compare             Set each release held against the one before it, retrieving nothing
  -d, --directory DIR       Where the extract is kept (default: $XDG_DATA_HOME/abn-bulk-extract)
  -n, --dry-run             Report what would be retrieved and compared without doing either
  -p, --parse               Parse the newest release held, retrieving nothing
  -q, --quiet               Report nothing but errors
  -h, --help                Show this help
```

### Configuration

It reads `~/.config/abn-bulk-extract/config.yaml`, where present, and its switches override that. A switch left off, or a setting left blank, leaves what lies beneath it standing; a file which is not a mapping stops the run. The directory is the extract's own, holding `releases/`: `$XDG_DATA_HOME/abn-bulk-extract` unless set, or `~/.local/share/abn-bulk-extract` where `XDG_DATA_HOME` is unset.

```yaml
directory: /srv/abn-bulk-extract
user_agent: abn-bulk-extract
```

`directory`, `api_url` and `user_agent` are passed to `DataGovAu::AbnBulkExtract::Config`; anything else in the file is ignored.

Before 0.1.0 the setting was `data_directory`, the directory beneath which `abr/` held the extract. A file still holding it stops the run, saying so, rather than the releases being looked for where they aren't and retrieved again. Set `directory` to what was `data_directory`'s `abr/`.

### On disk

```
~/.local/share/abn-bulk-extract/
  releases/
    20261028/
      public_split_1_10.zip
      public_split_11_20.zip
      bulkextract.xsd
      abnlookupbulkextractreadme.pdf
      abn-bulk-extract-resources.csv
      catalogue.json
    20261104/
      ...
      delta.zst
      frame.json.zst
```


## Testing

```shell
ruby test/abn-bulk-extract_test.rb
```

Each case runs the program as a subprocess under a temporary home directory, and none goes to data.gov.au.


## Contributing

1. Fork it: `https://github.com/thoran/abn-bulk-extract/fork`
2. Create your feature branch: `git checkout -b my-new-feature`
3. Commit your changes: `git commit -am 'Add some feature'`
4. Push to the branch: `git push origin my-new-feature`
5. Create a new pull request


## License

MIT
