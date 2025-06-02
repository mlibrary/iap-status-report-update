########
# Base #
########

FROM ruby:2.4 as base

ARG UID=1000
ARG GID=1000
ARG UNAME=app
ENV APP_HOME /app
ENV BUNDLE_PATH /bundle

RUN groupadd ${UNAME} -g ${GID} -o &&  \
  useradd -m -d ${APP_HOME} -u ${UID} -o -g ${UNAME} -s /bin/bash ${UNAME} && \
  mkdir -p ${BUNDLE_PATH} ${APP_HOME}/out && \
  chown -R ${UNAME} ${BUNDLE_PATH} ${APP_HOME}

WORKDIR $APP_HOME

USER $UNAME

CMD ruby update-iap-status-reports.rb

###############
# Development #
###############
FROM base AS development

##############
# Production #
##############
FROM base AS production
USER $UNAME

COPY --chown=${UNAME}:${UNAME} Gemfile* ${APP_HOME}/
COPY --chown=${UNAME}:${UNAME} qualtrics_api/ ${APP_HOME}/qualtrics_api/

RUN bundle install

COPY --chown=${UNAME}:${UNAME} . ${APP_HOME}
