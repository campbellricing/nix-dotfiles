function install --description 'Install node_modules with the package manager matching the repo lockfile'
    if test -f pnpm-lock.yaml
        pnpm install
    else if test -f package-lock.json
        npm install
    else if test -f bun.lockb -o -f bun.lock
        bun install
    else if test -f yarn.lock
        yarn install
    else
        echo "install: no lockfile found, defaulting to yarn" >&2
        yarn install
    end
end
