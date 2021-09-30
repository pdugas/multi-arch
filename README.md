[![Build](https://github.com/pdugas/multi-arch/actions/workflows/build.yml/badge.svg)](https://github.com/pdugas/multi-arch/actions/workflows/build.yml)

# Multi-Architecture Builds at GitHub

This is a test/demo project where I'm working out how to build and package a binary executable for multiple architectures using GitHub workflows. Here's how it works:

* The [`Makefile`](./Makefile) provides `make all` and `make test` targets that build and test the code in the _local_ environment. It's building a simple executable from [`eg.c`](./eg.c).

  ```shell
  $ make all
  cc  -DVERSION=\"0.0.2\"   eg.c   -o bin/eg-amd64-gnu
  $ make test
  PASSED
  $ ./bin/eg-amd64-gnu
  eg 0.0.2
  Howdy!
  $ make clean
  ```

  There's logic in there to get version info from `git` and pass it into the compile and link command. The name of the resulting binary includes the platform architecture (`amd64` or `arm64`) and libc variant (`gnu` or `musl`). Pretty simple.

* The `make builder-os OS=...` target is used to build container images with all the dependencies needed to build the project. There are two different build images; one based on Ubuntu for GNU libc, and another based on Alpine for musl libc. These are needed for building for the _non-local_ OS/ARCH configurations.

  Note that we're building multi-architecture images here. The `ghcr.io/pdugas/multi-arch-builder:ubuntu` image is Ubuntu with the necessary dev tools for both `arm64` and `amd64`. The same goes for `ghcr.io/pdugas/multi-arch-builder:alpine`.

* We use the [`multiarch/qemu-usr-static`](https://github.com/multiarch/qemu-user-static) image to install entries in `/proc/sys/fs/binfmt_misc/` that allow the kernel to invoke the [QEMU](https://www.qemu.org/) emulator when a non-native binary is executed. Once that's done, we can run ARM executables locally (and in containers) even though we're running on x86.

* The `make build-os-arch OS=... ARCH=...` target uses the builder images from the earlier steps, mounts the local directory to `/opt/appscope` in the container, and runs `make all test` to build the binary. When we run this with the different OS and ARCH options, we end up with 4 different binaries; `./bin/eg-(arm64|amd64)-(gnu|musl)`.

* The `make image-os OS=...` target builds another pair of muulti-architecture images that are the base OS plus the correct binary in `/usr/local/bin/eg`.

* The [workflow](./.github/workflows/build.yml) runs on pushes and PRs to the default branch. It handles building the images and pushing them to the GitHub registry.

## Container Images

We provide multi-architecture images for GNU and musl libc environments.

* `ghcr.io/pdugas/multi-arch:latest` - Most recent non-prelease version of the Ubuntu image
* `ghcr.io/pdugas/multi-arch:${VERSION}-ubuntu` - Ubuntu image for GNU libc
* `ghcr.io/pdugas/multi-arch:${VERSION}-alpine` - Alpine image for musl libc

We're _caching_ our builder images to speed up builds. There are 4 of them currently for amd/arm and gnu/musl libc. These are for the build only - not useful by others.

* `ghcr.io/pdugas/multi-arch-builder:ubuntu`
* `ghcr.io/pdugas/multi-arch-builder:alpine`

### To Do

* ~~Simple example binary and Maekfile.~~
* ~~Add `DOCKER_LOGIN` and `DOCKER_TOKEN` secrets.~~
* ~~Unit test~~
* ~~Workflow to build, test, and publish binary artifact.~~
* ~~Add version and tag.~~
* ~~Extend workflow to build and publish Docker image.~~
* ~~Build x86 & ARM binaries~~
* ~~Speed up the builds by caching the builder images here at GitHub.~~
* ~~Build multi-arch container image~~
* ~~Split out the build into separate jobs instead of serially in one. Can we use the `buildx --platform`?~~
* ~~Attach `eg-$(ARCH)-$(LIBC)` binaries to the release as assets.~~
* Add a `install-eg.sh` script that can be run via `curl -Ls https://.../install-eg.sh | sh` to install the correct version of the program into `/usr/local/bin`.
* Autotools?

