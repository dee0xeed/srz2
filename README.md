# srz2
Another simple symbol ranking compressor

### build with

```
zig build -Drelease-fast
```

### compress

```
$ zig-out/bin/srz c ~/CC/enwik8 enwik8.srz
/home/zed/CC/enwik8 (100000000 bytes) -> enwik8.srz (30679469 bytes) in 9270 msec
```

### decompress

```
$ zig-out/bin/srz d enwik8.srz enwik8
enwik8.srz (30679469 bytes) -> enwik8 (100000000 bytes) in 11186 msec
```

### similar compressors

* [sr2](https://encode.su/threads/881-Symbol-ranking-compression)
* [srx](https://encode.su/threads/4038-SRX-fast-multi-threaded-SR-compressor)
