# ====================================================================
# STAGE01: build step - use my-test-image-build image to build mds
# ====================================================================
FROM mcr.microsoft.com/powershell:7.0.0-rc.2-alpine-3.8 AS build

WORKDIR /out/test-tools/

# jq
RUN wget https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 -O jq \
    && chmod +x ./jq

# rabtap
RUN wget https://github.com/jandelgado/rabtap/releases/download/v1.22/rabtap-v1.22-linux-amd64.zip -O rabtap.zip \
    && mkdir rabtap_zip && unzip rabtap.zip -d ./rabtap_zip/ \
    && mv ./rabtap_zip/bin/rabtap-linux-amd64 ./rabtap \
    && rm -r ./rabtap_zip \
    && rm ./rabtap.zip 

# ====================================================================
# STAGE02: runtime image, my-test-image-build - should includes pwsh
# ====================================================================
FROM mcr.microsoft.com/powershell:7.0.0-rc.2-alpine-3.8 AS run

# copy output of previous publish
COPY --from=build /out/test-tools /test-tools/

# runtime deps
RUN apk --no-cache add libc6-compat zip npm gcompat openssh-client

# PATH and rabtap environmental variables
ENV PATH="/test-tools:${PATH}" \ 
    RABTAP_AMQPURI=amqp://guest:guest@rabbitmq:5672 \
    RABTAP_APIURI=http://guest:guest@rabbitmq:15672/api 

# vscode or the powershell extension as 2019-09-17 uses /usr/bin/stat during remote debugging connection, but this distro has it in /bin/stat. 
# To replicate the issue: remove the line, build&run, attach to container, install powershell extension via vscode extensions UI, check terminal output.
RUN cp /bin/stat /usr/bin/stat

# # copy only package.json and package-lock.json and run npm install
# WORKDIR /TestFramework/TestModules/nodejs/
# ADD ./TestFramework/TestModules/nodejs/package*.json ./
# RUN npm i 

# install sql pwsh module
RUN pwsh -c 'Set-PSRepository -Name PSGallery -InstallationPolicy Trusted; Install-Module -Name SqlServer -AllowClobber'

# define work directory
WORKDIR /TestFramework/

# run-entrypoint
# ENTRYPOINT [ "pwsh", "-File", "./main.ps1" ]

# debug-entrypoint
ENTRYPOINT [ "pwsh", "-File", "./debug.ps1"]

# copy content of test scripts (making this as last step, since this will change often)
# ADD ./.vscode-for-container ./.vscode
ADD ./TestFramework ./
