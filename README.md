## Description

`Bash`-binding for `btsync` API.

`btsync` (aka `Bittorrent Sync`) can be found [here or there].

`btsync` provides API, but you need to register an account at
`btsync` home page. I simply... don't need that:)
Because I don't use any API service from `BitTorrentSync`.

So I write a `Bash` script, to get data from my `btsync` instance.

## Methods

I only write stuff that I need.
You are welcome to contribute to this project!

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
* `key/get`: return _(generate)_ a valid key pair
* `os/dir/create`: create a directory on remote system _(dangerous!)_.
  Argument:
  * `dir`: A path to directory on the remote server. The `dir` must be
    started by a slash (`/`). Please note that `btsync` normally accepts
    arbitary path name, but our script doesn't accept that.
* `folder/create`: create new share folder. Arguments:
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

## Usage

See many examples in `examples.md`.

## How it works

The normal steps of a browser session:

* Basic authentication
* Generate/Save session's cookie to browser
* Fetch a valid token from `gui/token.html`
* Use the `cookie` / `token` pair for any future `JSON` data fetch

Anything more? I don't know.

## License

This work is released under a MIT license.

## Author

Anh K. Huynh

[here or there]: http://www.bittorrent.com/sync/downloads
