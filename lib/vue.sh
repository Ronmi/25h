#!/usr/bin/zsh -f

loadlib nvm

alias serve='yarn serve'
alias lint='yarn lint'
alias build='vue build --mode=production'
alias modern='vue build --mode=production --modern'

# confvue pwa proxypath proxydest
#
#  - pwa: 1 to enable pwa, others disable it
#  - proxy: proxy setting, leave empty to disable
#
# Example
#
# confvue '' /api=http://127.0.0.1:8000/api
# confvue 1
function confvue {
    # validate arguments
    pwa="$1"
    shift
    proxy="$1"

    if [[ $proxy != '' ]]
    then
        p="$(echo "$proxy" | cut -d '=' -f 1)"
        d="$(echo "$proxy" | cut -d '=' -f 2-)"
        if [[ $p == '' || $d == '' ]]
        then
            echo 'Usage: confvue pwa proxy'
            echo ''
            echo 'Example:'
            echo ''
            echo 'confvue 1 "/api=http://test-server.example.com:9876/api"'
            echo ''
            return 1
        fi
    fi

    # header
    cat <<EOHeader > vue.config.js
const path = require('path');

module.exports = {
EOHeader

    # proxy
    if [[ $p != '' ]]
    then
        cat <<EOProxy >> vue.config.js
    devServer: {
        proxy: {
            '${p}': {
                toProxy: true,
                target: '${d}',
            },
        },
        contentBase: path.join(__dirname, 'public'),
    },
EOProxy
    fi

    # pwa
    if [[ $pwa == '1' ]]
    then
        cat <<EOPWA >> vue.config.js
    pwa: {
        workboxOptions: {
            offlineGoogleAnalytics: true,
            runtimeCaching: [
                { // your own cache rule
                    urlPattern: /^https?:\/\/[^/]+\/api\//,
                    handler: 'networkFirst',
                    options: {
                        networkTimeoutSeconds: 10,
                        cacheName: 'api-offline-cache',
                        cacheableResponse: {
                            statuses: [0, 200],
                        },
                    },
                },
                { // cache static assets
                    urlPattern: new RegExp('.{js,css,html,woff,woff2,ttf,eot}$'),
                    handler: 'cacheFirst',
                    options: {
                        cacheName: 'global-asset-cache',
                        cacheableResponse: {
                            statuses: [0, 200],
                        },
                    },
                },
                { // cache google fonts
                    urlPattern: new RegExp('^https?://fonts.googleapis.com/'),
                    handler: 'cacheFirst',
                    options: {
                        cacheName: 'google-font-cache',
                        cacheableResponse: {
                            statuses: [0, 200],
                        },
                    },
                }
            ]
        }
    },
EOPWA
    fi

    # footer
    cat <<EOFooter >> vue.config.js
};
EOFooter
}
