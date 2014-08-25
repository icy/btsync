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
* `folder/get`: return all shared folders you see in `web` console
* `folder/setting/get`: return the default folder or setting of a folder
* `os/type/get`: return the type of host's operating system
* `version/get`: return the version number of `btsync`
* `setting/get`: return general settings
* `speed/get`: return the current download/upload speed
* `key/get`: return _(generate)_ a valid key pair
* `os/dir/create`: create a directory on remote system _(dangerous!)_
* `folder/create`: create new share folder
* `folder/host/get`: return list of known hosts of a shared folder
* `key/onetime/get`: return a on-time key for a shared folder
* `folder/setting/update`: update settings for a shared folder. Parameters:
  * `relay`: use relay or not. Default: 0
  * `tracker`: user tracker or not. Default: 0
  * `lan`: search in local net or not. Default: 1
  * `dht`: search in `DHT` network or not. Default: 0
  * `trash`: save deleted files to trash or not. Default: 1
  * `host`: use list of predefined hosts, or not. Default: 1
* `folder/host/create`: add a new host to list of known hosts.
  Arguments:
  * `host`: the host name or IP address
  * `port`: the port number. `port` can be ommitted if you specify it
    in `host`, for example, `foobar:1234`.
* `folder/host/delete`: delete some host from the list of know hosts.
  Arguments:
  * `host`: the host name or IP address
  * `port`: the port number. `port` can be ommitted if you specify it
    in `host`, for example, `foobar:1234`.

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
