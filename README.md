# Obsidian Vault Self-Hosting

<!-- Allow inline HTML for e.g. <br> tags:
<!-- markdownlint-disable MD033 -->

## Discovery

- [Reddit guide](https://www.reddit.com/r/selfhosted/comments/1eo7knj/guide_obsidian_with_free_selfhosted_instant_sync)<br>
  (archived to [doc/guide.md](doc/guide.md))
- [obsidian-livesync plugin](https://github.com/vrtmrz/obsidian-livesync)

### Hosting web view

- [webtop](https://github.com/linuxserver/docker-webtop)

### Misc

- [markdown_supported_languages](https://github.com/jincheng9/markdown_supported_languages)

## Setup

```bash
make init
```

## Useful Commands

```bash
script/compose-shim.sh logs --follow obsidian-webclient
```
