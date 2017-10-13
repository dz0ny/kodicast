# kodicast

Cast local file to remote Kodi instance.

## Example
```
$ ./kodicast-Linux-x86_64 -addr=192.168.1.230:9090 -file=gopro.mp4
```

## Help
```
Usage:
  kodicast-Linux-x86_64 [OPTIONS...]
Options:
  -addr    (*net.TCPAddr)   HTTP listen address (Default: 192.168.1.230:9090)
  -debug   (bool)           Verbose output
  -file    (string)         File-based storage directory, overrides piece storage (Default: gopro.mp4)
  ```