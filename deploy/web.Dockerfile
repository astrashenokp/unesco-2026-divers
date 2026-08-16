# The learner app, built and served as static files.
#
#   docker build -f deploy/web.Dockerfile -t evidence-gym-web \
#     --build-arg API_BASE_URL=https://your-api-host/ .
#
# Two stages: Flutter builds, nginx serves. The result carries no Dart
# toolchain, which is a few hundred megabytes that would otherwise ship
# for no reason.

# Pinned to a tag that is actually published, which is not the same as
# the version installed locally. `3.44.9` was neither — the registry
# answers 404 for it and the build fails on this line, before anything
# else in the file runs.
#
# 3.44.0 is the only 3.44.x image there is, and it is also the floor
# `apps/learner/pubspec.lock` records (flutter >=3.44.0, dart >=3.12.0),
# so it satisfies the lock exactly. Raising the local Flutter version
# without checking this file will break the build again; the tag list is
# at ghcr.io/cirruslabs/flutter.
FROM ghcr.io/cirruslabs/flutter:3.44.0 AS build

WORKDIR /src
COPY apps/learner/pubspec.yaml apps/learner/pubspec.lock apps/learner/
COPY packages/design_system/ packages/design_system/
RUN cd apps/learner && flutter pub get

COPY apps/learner/ apps/learner/

# Where the client should look for the API.
#
# Baked in at build time because Flutter web resolves
# String.fromEnvironment during compilation — there is no runtime
# configuration to change afterwards. A deployment pointing at the wrong
# host needs a rebuild, not a restart, and it is better to know that
# than to discover it.
#
# Defaults to empty rather than to localhost. A published copy pointed
# at localhost would try to reach the visitor's own machine, fail, and
# look broken; with no API configured the app opens on the reviewed pack
# bundled into the build and says so plainly.
ARG API_BASE_URL=""

# Deliberately no credential arguments. Release builds discard the dev
# tokens by design so none can ship in a bundle a stranger can read, and
# nothing here is going to hand them a way around that.
RUN cd apps/learner && \
    flutter build web --release \
      --dart-define=API_BASE_URL="${API_BASE_URL}"

FROM nginx:1.27-alpine

COPY --from=build /src/apps/learner/build/web /usr/share/nginx/html
COPY deploy/nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 8080
