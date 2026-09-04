function dev --description 'Run the dev script with the package manager matching the repo lockfile'
    if test -f pnpm-lock.yaml
        pnpm dev
    else if test -f package-lock.json
        npm run dev
    else if test -f bun.lockb -o -f bun.lock
        bun dev
    else if test -f yarn.lock
        yarn dev
    else
        echo "dev: no lockfile found, defaulting to yarn" >&2
        yarn dev
    end
end
