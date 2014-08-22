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
* `cookie/get`: return a vallid cookie for `curl`-ing
* `curl/header/get`: return both cookie and token for your own test
* `folder/get`: return all shared folders you see in `web` console
* `folder/setting/get`: return the default folder
* `os/type/get`: return the type of host's operating system
* `version/get`: return the version number of `btsync`
* `setting/get`: return general settings
* `speed/get`: return the current download/upload speed
* `key/get`: return _(generate)_ a valid key pairs
* `os/dir/create`: create a directory on remote system _(dangerous!)_

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
