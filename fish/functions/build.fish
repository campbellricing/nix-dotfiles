function build --description 'Build the app with the package manager matching the repo lockfile'
    if test -f pnpm-lock.yaml
        pnpm build
    else if test -f package-lock.json
        npm run build
    else if test -f bun.lockb -o -f bun.lock
        bun build
    else if test -f yarn.lock
        yarn build
    else
        echo "build: no lockfile found, defaulting to yarn" >&2
        yarn build
    end
end
