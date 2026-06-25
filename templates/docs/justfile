# Serve docs locally (http://0.0.0.0:<random-port>)
doc:
    nix-build -E "with import <nixpkgs> {}; python312.withPackages (ps: [ ps.mkdocs ps.mkdocs-material ])" --no-out-link -o /tmp/mkdocs-env 2>/dev/null && PORT=$(shuf -i 8000-9000 -n 1) && echo "→ http://0.0.0.0:$PORT" && /tmp/mkdocs-env/bin/mkdocs serve -a 0.0.0.0:$PORT --quiet 2>&1 | grep -v "│"
