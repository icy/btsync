## Description

`Bash`-binding for `btsync` API.
`btsync` (aka `Bittorrent Sync`) can be found [here or there].

Actually this is a `wrapper` of your `browser` iteractions.
It isn't the official `btsync` API.

The script supports both `btsync` 1.3 and `btsync` 1.4.

Please make sure you read the section `Why this cript` for details.

## Usage

See many examples in `examples/` directory.

## Methods

I only write stuff that I need.
You are welcome to contribute to this project!

* `license/update`: accept `btsync` license. This is a must before
  you create/update other settings :)
* `token/get`: return a valid token for `curl`-ing
* `cookie/get`: return a valid cookie for `curl`-ing
* `curl/header/get`: return both cookie and token for your own test
* `folder/get`: return all shared folders you see in `web` console,
  or return information for a single folder.
  Argument: As in `folder/host/get`. In case both `key/dir` are missing,
  a list of all shared folder is returned.
* `folder/setting/get`: return the default folder or setting of a folder.
  Argument: As in `folder/get`.
* `os/type/get`: return the type of host's operating system
* `version/get`: return the version number of `btsync`
* `setting/get`: return general settings
* `speed/get`: return the current download/upload speed
* `key/get`: return _(generate)_ a valid key pair.
  Argument:
  * `encrypt`:
      Specify if you want to have encrypt support. Default: 0.
  * `key`: _(Optional)_
      Specify the `RW` or `ERW` key from that the `RO` or `ERO` key
      is generated. If `key` is not specified, new random key pair
      will be generated.
  * `master`: Generate only the master key. This will be very fast.
      Default: 0.
* `os/dir/create`: create a directory on remote system _(dangerous!)_.
  Argument:
  * `dir`: A path to directory on the remote server. The `dir` must be
    started by a slash (`/`). Please note that `btsync` normally accepts
    arbitary path name, but our script doesn't accept that.
* `folder/create`: create new share folder. Arguments:
  * `encrypt`: Create a shared folder with encryption support. Default: 0.
  * `dir`: As mentioned in `os/dir/create`
  * `key`: _(Optional)_
    A secret key (`RW`, `RO`, `ERO`, ...). If not specified,
    a random keypair of type `RW` will be created.
* `folder/host/get`: return list of known hosts of a shared folder.
  Arguments:
  * `dir`: A remote directory path.
  * `key`: A secret key of the shared folder, of any type.
  You must specify at least `dir` or `key`. If both of them are specified,
  `dir` will take precedence. _(This is because the path is always unique,
  while two different shared folder may have a same key.)_
* `key/onetime/get`: return a on-time key for a shared folder. Arguments:
  As in `folder/host/get`.
* `folder/setting/update`: update settings for a shared folder. Arguments:
  * `relay`: use relay or not. Default: 0
  * `tracker`: user tracker or not. Default: 0
  * `lan`: search in local net or not. Default: 1
  * `dht`: search in `DHT` network or not. Default: 0
  * `trash`: save deleted files to trash or not. Default: 1
  * `host`: use list of predefined hosts, or not. Default: 1
  * `dir/key`: as in `folder/host/get`.
* `folder/host/create`: add a new host to list of known hosts.
  Arguments:
  * `host`: the host name or IP address, or a hostname/IP followed by a port
    number, for example, `foobar:1234`.
  * `port`: the port number. This argument is ignored if `host` already
    contains a port number.
  * `dir/key`: As in `folder/host/get`
* `folder/host/delete`: delete some host from the list of know hosts.
  Arguments: As in `folder/host/create`. Please note that `btsync` does
  not check for duplication. This method will delete **all** entries
  that match user's criteria.
* `folder/delete`: Delete a shared folder. Arguments: As in `folder/get`.

More method? Okay, stay tuned!.

## How it works

The normal steps of a browser session:

* Basic authentication
* Generate/Save session's cookie to browser
* Fetch a valid token from `gui/token.html`
* Use the `cookie` / `token` pair for any future `JSON` data fetch

The data transferred between the browser and a `btsync` daemon are
in `JSON` format, and they are almost identical to the official `btsync` API.

The most tricky part is to generate an encryption secret keypair:

1. Generate a random string `foo`, which is actually a master `RW` key;
2. Invoke `folder/create` to create a shared folder _(`foo`)_ on the server;
3. Invoke `folder/get` to get information of the `foo` shared folder;
4. Invoke `folder/delete` to delete the shared folder.

The necessary data can be found on the 3rd step. After the 4th step,
the temporary folder will be deleted; however, the temporary directory
still remains on the remote server. For `btsync` 1.3, it is under
`/tmp/cnystb/`. For `btsync` 1.4, it will be under `.cnystb/` directory
inside the default folder. Further technical details can be read from
the implementation of `__key_push_and_pull` method.

## Security issues

When using `key/get`, please note that there may be a case when
`folder/create` is invoked to create a temporary shared folder.
Because the default settings of `btsync` is to allow to use remote
tracker and relay servers, newly created shared folder will trigger
`btsync` to send traffic to its home.

This is *true* for any newly created shared folder, though.

## Missing methods

`Selective download` must be very cool feature. Now you can only find
them from the official `btsync` API.

`Getting a list of files from a shared folder` is another missing thing.

## Why this script

`btsync` officialy provides their `API`, but you need to ask them for
an `API` key. That's free; you just need to wait some hours to get the key.

Though the `API` key comes from `btsync` team, your `API` server is
**yours**: When you start new `btsync` daemon, the `API` is already there,
but you just can't use it because you don't have the `unlock key`. Weird.

I don't believe in `btsync` way:) I think `btsync` should provide a way
so its users can generate as many `API` key as they want. If I have to
use the official `API` key, that should be the case when `API` end-point
is on `btsync` network.

That's why I write this script. I can write it in `Ruby`, `Python`;
however `bash` and `Perl` is enough for a `sysadmin`: I use `bash` to glue
things, and use `Perl` to read some `JSON` data -- which is unreadable
from `bash` brain.

## TODO

Support the official `btsync` API:)

## License

This work is released under a MIT license.

## Author

Anh K. Huynh

[here or there]: http://www.bittorrent.com/sync/downloads
