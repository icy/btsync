## Description

`Bash`-binding for `btsync` API.

`btsync` (aka `Bittorrent Sync`) can be found [here or there].

`btsync` provides API, but you need to register an account at
`btsync` home page. I simply... don't need that:)
Because I don't use any API service from `btsync`.

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
* `key/get`: return (generate) a valid key pairs

More method? Okay, stay tuned!.

## Usage

Here is an example

    $ chmod 755 ./api.sh

    $ epport BTSYNC_USER=admin
    $ export BTSYNC_PASSWD="your-very-simple-password"
    $ # export BTSYNC_HOST="localhost:8888"

    $ ./api.sh curl/header/get
    {
      "cookie": "xxxxxxxxxxxxx",
      "token": "xxxxxxxxxxxxx",
      "at": 1408615780
    }

    $ ./api.sh key/get
    { "rosecret": "B3MF5NHDCWI6JTVUU2R3LYMQDAK2QCEXG",
      "secret": "AHRAXZOGOMZ7B7VIFL5JK7VRH5URQVHMA" }

    $ ./api.sh folder/get
    {
      "folders": [
        {
            "date_added": 1408417054,
            "error": 0,
            "files": 0,
            "has_key": 1,
            "indexing": 0,
            "iswritable": 0,
            "last_modified": 1408578957,
            "name": "/home/btsync/data/kyanh-iphone4-camera",
            "peers": [
                {
                    "direct": 0,
                    "id": "xxxxxxxxxxxxx",
                    "is_connected": 0,
                    "last_seen": 1408454101,
                    "last_synced": 1408454085,
                    "name": "tinybox",
                    "status": "Synced on 08/19/14 20:14:45, Last seen 08/19/14 20:15:01"
                },
                {
                    "direct": 0,
                    "id": "xxxxxxxxxxxxx",
                    "is_connected": 0,
                    "last_seen": 1408579040,
                    "last_synced": 1408579040,
                    "name": "xxxxxxxxxxxxx",
                    "status": "Synced on 08/21/14 06:57:20, Last seen 08/21/14 06:57:20"
                }
            ],
            "secret": "xxxxxxxxxxxxx",
            "secrettype": 2,
            "size": 0,
            "status": "0 B in 0 files"
        },

All output data is in `JSON` format.

You can get `cookie` and `token` from your browser and feed
the script by setting `BTSYNC_COOKIE` and `BTSYNC_TOKEN` variables.

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
