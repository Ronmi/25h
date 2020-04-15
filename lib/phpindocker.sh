#!/bin/zsh -f
#
# [WIP] This is work in progress lib, content may vary or remove completely.
#
# Currently only one command provided.
#
# USAGE
#
#     phpindocker [docker image tag, default to cli]
#
#   See https://hub.docker.com/_/php for possible tags.
#
#   The project root is mounted at ~/app
#
# EXAMPLE
#
#     # using latest php cli image
#     phpindocker
#     # using php 7.1
#     phpindocker 7.1-cli
#
# CUSTOMIZE
#
#   You can create '/PATH_TO_YOUR_PROJECT/.rmi-work/php/img/init-hook.sh' to
#   install custom package/extension in the image. There's a helper for it:
#
#       pind_init vi # equals: vi "${_RMI_WORK_DIR}/php/img/init-hook.sh"
#
#   You can create '/PATH_TO_YOUR_PROJECT/.rmi-work/php/home/boot-hook.sh' to
#   install custom package/extension at runtime. There's a helper for it:
#
#       pind_boot vi # equals: vi "${_RMI_WORK_DIR}/php/home/boot-hook.sh"
#
#   You can set default image tag by adding 'export DEFAULT_PHP_VERSION=5.6-cli'
#   in 'conf.zsh'.

loadlib docker

export DEFAULT_PHPINDOCKER_VERSION=cli

function pind_init {
    mkdir -p "${_RMI_WORK_DIR}/php/img"
    touch "${_RMI_WORK_DIR}/php/img/init-hook.sh"
    "$1" "${_RMI_WORK_DIR}/php/img/init-hook.sh"
    chmod a+x "${_RMI_WORK_DIR}/php/img/init-hook.sh"
}

function pind_boot {
    mkdir -p "${_RMI_WORK_DIR}/php/home"
    touch "${_RMI_WORK_DIR}/php/home/boot-hook.sh"
    "$1" "${_RMI_WORK_DIR}/php/home/boot-hook.sh"
    chmod a+x "${_RMI_WORK_DIR}/php/home/boot-hook.sh"
}

function _phpindocker_gen_dockerfile {
    ver="${1:-${DEFAULT_PHPINDOCKER_VERSION}}"
    uid="$(id -un)"
    echo "FROM php:${ver}" > "${_RMI_WORK_DIR}/php/img/Dockerfile"
    echo "RUN sed -i 's#//httpredir#//deb#' /etc/apt/sources.list" >> "${_RMI_WORK_DIR}/php/img/Dockerfile"
    echo "RUN sed -i '/jessie-updates/s/^/# /' /etc/apt/sources.list" >> "${_RMI_WORK_DIR}/php/img/Dockerfile"
    echo 'RUN apt-get update && apt-get install -y --no-install-recommends sudo git unzip less wget zsh && apt-get clean -y && rm -fr /var/lib/apt/lists/*' >> "${_RMI_WORK_DIR}/php/img/Dockerfile"
    echo "RUN echo \"export $(dircolors -b|head -n 1)\" > /etc/profile.d/ls-color.sh" >> "${_RMI_WORK_DIR}/php/img/Dockerfile"
    echo "RUN echo \"alias ls='/bin/ls --color=auto'\" >> /etc/profile.d/ls-color.sh" >> "${_RMI_WORK_DIR}/php/img/Dockerfile"
    echo "RUN echo \"alias grep='/bin/grep --color=auto'\" >> /etc/profile.d/ls-color.sh" >> "${_RMI_WORK_DIR}/php/img/Dockerfile"
    echo "RUN echo \"${uid} ALL=(ALL:ALL) NOPASSWD:ALL\" >> /etc/sudoers.d/${uid}" >> "${_RMI_WORK_DIR}/php/img/Dockerfile"
    echo 'COPY boot.sh /usr/local/bin' >> "${_RMI_WORK_DIR}/php/img/Dockerfile"

    # run init script
    if [[ -f "${_RMI_WORK_DIR}/php/img/init-hook.sh" ]]
    then
        echo 'COPY init-hook.sh /usr/local/bin' >> "${_RMI_WORK_DIR}/php/img/Dockerfile"
        echo 'RUN /usr/local/bin/init-hook.sh' >> "${_RMI_WORK_DIR}/php/img/Dockerfile"
    fi
}

function phpindocker {
    ver="${1:-${DEFAULT_PHPINDOCKER_VERSION}}"
    mkdir -p "${_RMI_WORK_DIR}/php/home"
    mkdir -p "${_RMI_WORK_DIR}/php/img"

    # prepare dockerfile
    _phpindocker_gen_dockerfile "$ver"

    # prepare boot script
    echo '#!/bin/bash

echo "done"

# hook to run env init script (mainly for installing ext)
if [[ -f "${home}/boot-hook.sh" ]]
then
    source "${home}/boot-hook.sh"
fi

# install composer
if [[ ! -f "${home}/composer.phar" ]]
then
    echo -n "installing composer... "
    HASHSUM="$(curl -sSL https://composer.github.io/installer.sig)"
    php -r "copy(\"https://getcomposer.org/installer\", \"${home}/composer-setup.php\");"
    ACTUAL="$(sha384sum -b "${home}/composer-setup.php"|cut -d " " -f 1)"
    if [[ $ACTUAL != $HASHSUM ]]
    then
        echo "invalid composer installer"
        rm "${home}/composer-setup.php"
        exit 1
    fi

    (cd "${home}" ; php composer-setup.php --quiet)
    err=$?
    rm "${home}/composer-setup.php"
    if [[ $err != 0 ]]
    then
        echo "cannot install composer"
        exit $err
    fi

    echo "done"
fi

if [[ ! -L /usr/local/bin/composer ]]
then
    ln -sf "${home}/composer.phar" /usr/local/bin/composer
fi

su -s /usr/bin/zsh - "$uid"
' > "${_RMI_WORK_DIR}/php/img/boot.sh"
    chmod a+x "${_RMI_WORK_DIR}/php/img/boot.sh"

    # build image
    suffix=$(basename "$_RMI_WORK_HERE")
    echo -n 'build runtime image... '
    d build -t "${suffix}_phpenv:${ver}" "${_RMI_WORK_DIR}/php/img" > /dev/null 2>&1
    if [[ $? != 0 ]]
    then
        echo "cannot prepare php runtime"
        return 1
    fi
    echo 'done'

    # copy default bash config
    if [[ ! -f "${_RMI_WORK_DIR}/php/home/.bashrc" ]]
    then
        cp "${HOME}/.bashrc" "${_RMI_WORK_DIR}/php/home/.bashrc" > /dev/null 2>&1
    fi
    if [[ ! -f "${_RMI_WORK_DIR}/php/home/.profile" ]]
    then
        cp "${HOME}/.profile" "${_RMI_WORK_DIR}/php/home/.profile" > /dev/null 2>&1
    fi

    # run
    echo -n "starting container... "
    docker run -it --rm \
           -e "uid=$(id -un)" \
           -e "home=${HOME}" \
           -e "LS_OPTIONS=${LS_OPTIONS}" \
           -v /etc/passwd:/etc/passwd:ro \
           -v /etc/group:/etc/group:ro \
           -v /etc/shadow:/etc/shadow:ro \
           -v "${_RMI_WORK_DIR}/php/home:${HOME}" \
           -v "${_RMI_WORK_HERE}:${HOME}/app" \
           -v "${HOME}/.zsh.d:${HOME}/.zsh.d:ro" \
           -v "${HOME}/.zsh.d/zshrc:${HOME}/.zshrc:ro" \
           --workdir "${HOME}/app" \
           "${suffix}_phpenv:${ver}" \
           "/usr/local/bin/boot.sh"
}
