ARG DOCKER_BASE_IMAGE='node:erbium-alpine3.15'
ARG APP_ENV="production"

# prod base image
FROM  $DOCKER_BASE_IMAGE AS prodbase
ARG NEXT_PUBLIC_APP_VERSION

# create app working directory
RUN mkdir -p /app && chown node:node -R /app

# change pwd
WORKDIR /app

# deps deps packages
COPY package.json package-lock.json  /app/

# install eslint and deps packages & clear cache files
RUN npm install --save-dev eslint \
    && npm install --production \
    && npm cache clean --force

# bundle sources files
COPY . .

# build app & remove deps
RUN npm run build \
    && npm audit fix \
    && npm prune --production

###############################################################################

# prod final image
FROM $DOCKER_BASE_IMAGE

# shell variables at build-time
ENV NEXT_PUBLIC_APP_VERSION=$NEXT_PUBLIC_APP_VERSION 
ENV UNAME="node" 
ENV APP_ENV=$APP_ENV

# setup default node user
USER ${UNAME}

# switch to /app pwd
WORKDIR /app

# copy sources files from prodbase image
COPY --chown=$UNAME:$UNAME --from=prodbase /app/next.config.js ./next.config.js
COPY --chown=$UNAME:$UNAME --from=prodbase /app/node_modules ./node_modules
COPY --chown=$UNAME:$UNAME --from=prodbase /app/package.json ./package.json
COPY --chown=$UNAME:$UNAME --from=prodbase /app/pages ./pages
COPY --chown=$UNAME:$UNAME --from=prodbase /app/public ./public
COPY --chown=$UNAME:$UNAME --from=prodbase /app/styles ./styles
COPY --chown=$UNAME:$UNAME --from=prodbase /app/.next ./.next

# setting expose
EXPOSE 3000

# run the app
CMD [ "npm", "run", "start" ]
