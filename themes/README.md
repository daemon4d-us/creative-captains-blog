# themes/

Each directory here with a `package.json` is a Ghost theme. On every push to `main` that touches
`themes/**`, the `deploy-theme` workflow zips each theme and uploads it through the Ghost Admin API
(it does not activate it; activate once in Ghost Admin > Design, after that uploads replace it in place).

Start from an official theme:

```sh
scripts/import-theme.sh source   # Ghost 6 default theme
scripts/import-theme.sh casper   # the classic
```

Validate locally before pushing:

```sh
npx gscan themes/source
```
