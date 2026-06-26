# Serve docs locally (http://0.0.0.0:<random-port>)
doc:
    PORT=$(shuf -i 8000-9000 -n 1) && echo "→ http://0.0.0.0:$PORT" && nix run .#docs -- serve -a 0.0.0.0:$PORT --quiet 2>&1 | grep -v "│"
