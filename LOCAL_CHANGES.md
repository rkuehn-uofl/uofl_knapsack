<!-- UOFL OVERRIDE NEW FILE: Document local Bulkrax FileSet alt text customization. -->

# Local Changes

This file documents knapsack-owned local customizations that are not intended to
be added to the main project README.

## Bulkrax FileSet Alt Text

The file
[app/factories/bulkrax/bulkrax_file_set_alt_text_decorator.rb](/Users/daisy/Documents/GitHub/uofl_knapsack/app/factories/bulkrax/bulkrax_file_set_alt_text_decorator.rb)
adds per-file `alt_text` values to FileSets during Bulkrax imports and
importer reruns.

This is useful when one Bulkrax work row includes multiple attached files and
each generated FileSet needs distinct alt text.

### Current Behavior

The decorator is env-driven. It builds FileSet alt text from:

- `BULKRAX_FILESET_ALT_TEXT_ENABLED`
- `BULKRAX_FILESET_ALT_TEXT_FIELDS`
- `BULKRAX_FILESET_ALT_TEXT_SEPARATOR`
- `BULKRAX_FILESET_ALT_TEXT_SUFFIX`

The feature is opt-in. If `BULKRAX_FILESET_ALT_TEXT_ENABLED` is not set,
the decorator leaves Bulkrax's FileSet params unchanged.

To enable the generated alt text behavior:

```env
BULKRAX_FILESET_ALT_TEXT_ENABLED=true
BULKRAX_FILESET_ALT_TEXT_FIELDS=file_name
BULKRAX_FILESET_ALT_TEXT_SEPARATOR=" "
BULKRAX_FILESET_ALT_TEXT_SUFFIX=
```

With those settings, a generated FileSet alt text value looks like:

```text
rhino1.jpg
```

### Supported Field Tokens

`BULKRAX_FILESET_ALT_TEXT_FIELDS` currently supports:

- direct Bulkrax/Hyku attributes already available to the object factory, such as `resource_type` or `source_identifier`
- the special per-file tokens `file`, `file_name`, and `file_name_without_extension`

Notes:

- `BULKRAX_FILESET_ALT_TEXT_ENABLED` accepts `true`, `1`, `yes`, or `on`
- existing FileSet `alt_text` already present in Bulkrax's new FileSet params is preserved while those params are built
- `file` and `file_name` resolve to the individual attached filename for each FileSet, including the file extension
- `file_name_without_extension` resolves to the attached filename with the extension removed
- if no usable values are found, the decorator leaves that FileSet `alt_text` unchanged
- after a successful work import/update, existing child FileSets are recalculated from the current env formula
- changing `BULKRAX_FILESET_ALT_TEXT_*` env values affects FileSets the next time a Bulkrax importer option actually updates the work
- quote a literal space in `.env` as `BULKRAX_FILESET_ALT_TEXT_SEPARATOR=" "`; unquoted trailing spaces may be trimmed by the env parser
- `BULKRAX_FILESET_ALT_TEXT_SUFFIX` is joined after the configured fields using `BULKRAX_FILESET_ALT_TEXT_SEPARATOR`

### Bulkrax Update Modes

This decorator runs in two places:

- while Bulkrax builds params for new FileSets
- after a successful work import/update, when it finds the saved child FileSets
  and updates their persisted `alt_text`

Because of the saved FileSet sync, these Bulkrax options can recalculate
FileSet `alt_text` from the current env formula:

- update metadata for all works
- update metadata and files
- remove files and recreate them
- remove all works and import again

The option that only updates the importer form does not update works, so it does
not recalculate FileSet `alt_text`.

The saved FileSet sync pairs existing FileSets with the parsed `file` values by
position. If the parsed file list is not available, it falls back to the saved
FileSet title/original filename.

### Examples

```env
BULKRAX_FILESET_ALT_TEXT_ENABLED=true
BULKRAX_FILESET_ALT_TEXT_FIELDS=file_name
BULKRAX_FILESET_ALT_TEXT_SEPARATOR=" "
BULKRAX_FILESET_ALT_TEXT_SUFFIX=
```

```text
rhino1.jpg
```

```env
BULKRAX_FILESET_ALT_TEXT_ENABLED=true
BULKRAX_FILESET_ALT_TEXT_FIELDS=source_identifier,file_name
BULKRAX_FILESET_ALT_TEXT_SEPARATOR=" "
BULKRAX_FILESET_ALT_TEXT_SUFFIX=
```

```text
RHINO_001 rhino1.jpg
```

```env
BULKRAX_FILESET_ALT_TEXT_ENABLED=true
BULKRAX_FILESET_ALT_TEXT_FIELDS=resource_type,file_name_without_extension
BULKRAX_FILESET_ALT_TEXT_SEPARATOR=". "
BULKRAX_FILESET_ALT_TEXT_SUFFIX="Detailed description follows."
```

```text
Still Image. rhino1. Detailed description follows.
```

### Reloading the App

After changing the decorator or `.env`, reload the app:

```bash
docker compose restart web worker
```
