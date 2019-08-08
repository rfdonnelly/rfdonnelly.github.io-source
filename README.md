# Personal Blog

## Requirements

[Hugo](https://gohugo.io/)

## Clone

```sh
git clone git@github.com:rfdonnelly/rfdonnelly.github.io-source.git --recrusive
```

## Create a New Post

```sh
hugo new posts/<post-name>.md
```

## Preview

```sh
hugo serve -D
```

## Publish

```sh
hugo
cd public
git add .
git commit -m "Publish $(date)"
git push
```
