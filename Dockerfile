ARG HYRAX_IMAGE_VERSION=hyrax-v5.2.0
FROM ghcr.io/samvera/hyrax/hyrax-base:$HYRAX_IMAGE_VERSION AS hyku-web

USER root
RUN git config --system --add safe.directory \*
ENV PATH="/app/samvera/bin:${PATH}"

USER app
ENV LD_PRELOAD=/usr/lib/libjemalloc.so.2
ENV MALLOC_CONF='dirty_decay_ms:1000,narenas:2,background_thread:true'

ENV TESSDATA_PREFIX=/app/samvera/tessdata
ADD https://github.com/tesseract-ocr/tessdata_best/blob/main/eng.traineddata?raw=true /app/samvera/tessdata/eng_best.traineddata

############### KNAPSACK SPECIFIC CODE ###################
# This means bundler inject looks at /app/samvera/.bundler.d for overrides
ENV HOME=/app/samvera
# This is specifically NOT $APP_PATH but the parent directory
COPY --chown=1001:101 . /app/samvera
ENV BUNDLE_LOCAL__HYKU_KNAPSACK=/app/samvera
ENV BUNDLE_DISABLE_LOCAL_BRANCH_CHECK=true
ENV BUNDLE_DISABLE_LOCAL_REVISION_CHECK=true
RUN bundle install --jobs "$(nproc)"
############## END KNAPSACK SPECIFIC CODE ################

# Set to "true" for local/dev builds so no stale manifest gets baked into the
# assets volume, letting Sprockets live-compile SCSS/JS changes on each request.
# Leave unset (false) for production builds, which need real precompiled assets.
ARG SKIP_ASSET_PRECOMPILE=false
RUN if [ "$SKIP_ASSET_PRECOMPILE" != "true" ]; then \
      RAILS_ENV=production SECRET_KEY_BASE=`ruby -rsecurerandom -e 'print SecureRandom.hex(64)'` DB_ADAPTER=nulldb DB_URL='postgresql://fake' bundle exec rake assets:precompile; \
    fi && yarn install
CMD ./bin/web

FROM hyku-web AS hyku-worker
CMD ./bin/worker
