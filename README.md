## Build Error

If you get this error:

> error: linking with `cc` failed: exit status: 1
>  = note: /usr/bin/ld: cannot find -lsqlite3: No such file or directory

You can run

```
> sudo apt-get install libsqlite3-dev
```

To fix it.