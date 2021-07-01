# Multi-Arch Builds

This is a test/demo project where I'm working out how to build and package a binary executable for multiple architectures. Here's how it works:

* The [`Makefile`](./Makefile) provides `make all` and `make test` targets that build and test the code in the _local_ environment. It's building a simple executable from [`eg.c`](./eg.c).

  ```shell
  $ ./bin/x86_64-linux-gnu/eg 
  eg 0.0.2
  Howdy!
  ```

  There's logic in there to get version info from `git` and pass it into the compile and link command. Pretty simple.
* The `make build` target effectively runs four builds; x86_64 and ARM using glibc and musl libc.

  ```shell
  make buid-(x86|arm)-(gnu|musl)
  ```

  Those 4 targets run the `make builder` target with the `IMAGE` and `DOCKERFILE` variables set.
* The `make builder` target depends on the the `make qemu-binfmt` target that is doing some magic. It's using the [`multiarch/qemu-usr-static`](https://github.com/multiarch/qemu-user-static) image to install entries in `/proc/sys/fs/binfmt_misc/` that allows the kernel to invoke the [QEMU](https://www.qemu.org/) emulator when a non-native binary is executed. Once that's done, we can run ARM executables locally (and in containers) even though we're running on x86_64.
* With QEMU in place, the `make builder` target can build an image with the necessary tools installed then run `make all test` in a container using it. We mount the working directory into the container so the resulting binaries are left when the container exits.

### To Do

* ~~Simple example binary and Maekfile.~~
* ~~Add `DOCKER_LOGIN` and `DOCKER_TOKEN` secrets.~~
* ~~Unit test~~
* ~~Workflow to build, test, and publish binary artifact.~~
* ~~Add version and tag.~~
* ~~Extend workflow to build and publish Docker image.~~
* ~~Build x86 & ARM binaries~~
* Build multi-arch container image
* Add asset to releaseS
  * name it "Release ${VERSION}"
  * Put links to assets and the container name in the description
* Create release automatically from `v*` tags
* Split out the build into separate jobs instead of serially in one.
