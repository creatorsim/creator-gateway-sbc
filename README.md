# creator-sbc-driver
CREATOR gateway driver for Linux-based RISC-V SBCs.

[Documentation](https://creatorsim.github.io/creator-wiki/web/gateway.md#executing-the-sbc-gateway).


## Development
This project uses [uv](https://docs.astral.sh/uv) to manage dependencies.

To add a new dependency, use `uv add <dep>`.

To generate the `requirements.txt` file:
```
uv export --format=requirements-txt --no-hashes
```
