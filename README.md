[![Build](https://github.com/pdugas/multi-arch/actions/workflows/build.yml/badge.svg)](https://github.com/pdugas/multi-arch/actions/workflows/build.yml)

# Multi-Arch Builds

This is a test/demo project where I'm working out how to build and package a binary executable for multiple architectures. Here's how it works:

* The [`Makefile`](./Makefile) provides `make all` and `make test` targets that build and test the code in the _local_ environment. It's building a simple executable from [`eg.c`](./eg.c).

  ```shell
  $ make all
  cc  -DVERSION=\"0.0.2\"   eg.c   -o bin/x86_64-linux-gnu/eg
  $ make test
  PASSED
  $ ./bin/x86_64-linux-gnu/eg 
  eg 0.0.2
  Howdy!
  $ make clean
  ```

  There's logic in there to get version info from `git` and pass it into the compile and link command. Pretty simple.

* The `make build` target effectively runs four builds; x86 and ARM using glibc and musl libc.

  ```shell
  make buid-(x86|arm)-(gnu|musl)
  ```

  Those 4 targets run the `make builder` target with the `IMAGE` and `DOCKERFILE` variables set.

* The `make builder` target depends on the the `make qemu-binfmt` target that is doing some magic. It's using the [`multiarch/qemu-usr-static`](https://github.com/multiarch/qemu-user-static) image to install entries in `/proc/sys/fs/binfmt_misc/` that allows the kernel to invoke the [QEMU](https://www.qemu.org/) emulator when a non-native binary is executed. Once that's done, we can run ARM executables locally (and in containers) even though we're running on x86.

* With QEMU in place, the `make builder` target can build an image with the necessary tools installed then run `make all test` in a container using it. We mount the working directory into the container so the resulting binaries are left when the container exits.

* The [workflow](./.github/workflows/build.yml) runs on pushes and PRs to the default branch. After some setup steps, it runs `make build` to build all of the binaries, then it uses `docker buildx build ...` to build the multi-architecture Ubuntu and Alpine images.

### Container Images

We provide multi-architecture images for GNU and musl libc environments.

* `ghcr.io/pdugas/multi-arch:latest` - Most recent non-RC release of the Ubuntu version
* `ghcr.io/pdugas/multi-arch:${VERSION}-ubuntu` - Ubuntu version for GNU libc
* `ghcr.io/pdugas/multi-arch:${VERSION}-alpine` - Alpine version for musl libc

We're _caching_ our builder images to speed up builds. There are 4 of them currently for amd/arm and gnu/musl libc. These are for the build only - not useful by others.

* `ghcr.io/pdugas/multi-arch/builder-arm64-musl:latest`
* `ghcr.io/pdugas/multi-arch/builder-amd64-musl:latest`
* `ghcr.io/pdugas/multi-arch/builder-arm64-gnu:latest`
* `ghcr.io/pdugas/multi-arch/builder-amd64-gnu:latest`

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
* Attach `eg-$(ARCH)-$(LIBC)` binaries to the release as assets.
* Add a `install-eg.sh` script that can be run via `curl -Ls https://.../install-eg.sh | sh` to install the correct version of the program into `/usr/local/bin`.
* Autotools
