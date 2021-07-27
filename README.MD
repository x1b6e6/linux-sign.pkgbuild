# linux-sign

Package provides script `linux-sign` for signing linux kernels with initramfs in 'stub'

## Sign keys

by default script use keys from `/etc/efi.key.pam`(private key) and `/etc/efi.pub.pam`(public key)

## Dependencies
- `sbsigntools`
- `openssl`
- `efitools`


## Usage

for signing kernel from `linux` package:
```shell
linux-sign linux /path/to/output
```

from `linux-lts` package:
```shell
linux-sign linux-lts /path/to/output
```
