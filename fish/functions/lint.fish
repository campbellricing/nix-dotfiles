function lint --description 'Lint with the package manager matching the repo lockfile'
    if test -f pnpm-lock.yaml
        pnpm lint
    else if test -f package-lock.json
        npm run lint
    else if test -f bun.lockb -o -f bun.lock
        bun lint
    else if test -f yarn.lock
        yarn lint
    else
        echo "lint: no lockfile found, defaulting to yarn" >&2
        yarn lint
    end
end
