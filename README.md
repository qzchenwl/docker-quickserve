# About this Repo

This is the Git repo of my Docker image for [quickserve](https://hub.docker.com/r/qzchenwl/quickserve/). See the Hub page for the full readme on how to use the Docker image.

# About quickserve

[Quickserve](http://xyne.archlinux.ca/projects/quickserve/) is a very simple HTTP server written in Python that is intended for quickly sharing files on an ad-hoc basis. Aside from opening a port in your firewall if you have one, quickserve requires no set-up and should work with no hassle.

Quickserve can serve single files or entire directories by simply passing it paths on the command line. It can also accept a list of files to share with the "--filelist" option. It is even possible to enable uploads using the "--upload" option, which accepts a directory path as its argument.

### Features

- Simple (simple to use, simple to understand the code)
- Support for file and filter lists
- Upload support
- HTTP Digest Authentication
- HTTPS with client certificates for secure connections
- Multicast support for automatic detection of other Quickserve servers

### Backend

As of quickserve-2013, the backend has been completely rewritten and moved to [python3-threaded_servers](http://xyne.archlinux.ca/projects/python3-threaded_servers/).

## Example

Your friend has just stopped by for a few minutes to grab a file from you (/home/foo/bar). He's using Windows and you don't have time to fiddle around with Samba shares or netcat or whatever. You just want to let him connect to your computer and grab "bar". All you need to do is run the following command:

```
quickserve /home/foo/bar
```

This will start up a server on all interfaces listening on port 8080. If you have a firewall you will have to open port 8080 in this case but that's it. Now your friend can open his web browser (or use "wget" or something similar) and navigate to your IP address on the lan. For example, if your internal IP is 192.168.0.1, then the address would be "http://192.168.0.1:8080/". This page will show a link to "bar" that can then be downloaded. Of course he could have just nativated to "http://192.168.0.1:8080/bar" to begin with, but if you share multiple files then the default page will list them all and you can use tools such as aria2c to grab everything at once.

See "quickserve -h" for options and usage.

## Try This

With the backend rewrite, Quickserve inherited the peer-to-peer functionality that was originally present in Pacserve. Now you can set up a network of file sharing servers as easily as

```
quickserve --multicast /path/to/share/directory
```

This will launch a server and detect other accessible servers automatically. These servers will be listed on the web interface under "peers". You can easily browse to them from there.

When a file request for a missing file is received, Quickserve will query other servers for that file and redirect the client if it is found. This only happens if multicast is enabled or static peers have been configured.

Of course, goig to each server to see what's available is tedious, so there's another option to make life easier: `--list-remote`

```
quickserve --multicast --list-remote /path/to/share/directory
```

This will collect all entries for a given server path from all known servers and present the results as though they were all in one directory on the local server, but with links pointing to the real location of each item.

Explore the options and web interface to discover what's there, or open up the source and start hacking away at new classes to extend the functionality.

## Certificate Generation

See the [python3-threaded_servers](http://xyne.archlinux.ca/projects/python3-threaded_servers/#certificate-generation) page for references and commands to generate certificates for HTTPS connections.

## Advanced Usage

This isn't really "advanced", but it is more than just the single command-line argument in the example above.

### Filelist

The input filelist can either be a plaintext list with one file or directory per line. In this case each line will be treated as though it had been passed as an argument on the command line. The advantage of the file list in this case is that the list can be updated while the server is running and the server will detect the change and reload it.

If the file is a JSON object instead of a list, it will be interpretted differently. The layout in this case must be:

```
{
  "path/to/server/directory" : [
    "/path/to/local/directory/a",
    "/path/to/local/directory/b",
    "/path/to/local/directory/c"
  ],
  "path/to/server/file" : "path/to/local/file"
}
```

The keys of the object are the paths that will appear on the server. If the key is mapped to a list then each item in the list must be a directory and the contents of each directory will appear to be in a single server directory. In the above example, all items in local directories "a", "b" and "c" would appear to be in "path/to/server/directory" on the server.

If the key maps to a string then the path will be treated as a file and requests for it will serve the file.

If the key maps to anything else, you dun goofed[^cyberpolice].

### Filterlist

For now, this is a list of regular expressions preceeded by either "i" (for "include") or "x" (for "exclude"). I would have named these "+" and "-", but "-" is interpretted as an option.

The order in which they are given is important. Each path requested by the server is matched in order. The last pattern to match determines if the path is visible.

Command-line options are matched after the filelist.

## Quickbrowse

To quickly browser a server from the command line, use the following alias:

```
alias quickbrowse="curl -G -d 'mimetype=text/plain'"

```

### Usage

```
$ quickbrowse http://localhost:8000/python-threaded_servers/

# /python-threaded_servers/

## Navigation Links
* [application/json](/python-threaded_servers/?mimetype=text%2Fplain&mimetype=application%2Fjson)
* [text/html](/python-threaded_servers/?mimetype=text%2Fplain)

## Directory Listing
Name          Size       Last Modified
-------- --------- -------------------
modules/           2013-05-10 16:50:21
COPYING  17.55 KiB 2013-05-10 16:01:58
TODO          62 B 2013-05-10 16:28:02
setup.py     569 B 2013-05-10 16:17:47
```

## Quickupload

Here's a simple script that uses curl to upload files to quickserve from the command line:

```
#!/bin/bash
set -e

# help message function
function display_help()
{
  cat <<HELP
usage: $0 [CURL OPTIONS] <URI> [FILES]

  The order of the arguments is not important. The arguments are simply filtered
  and passed to curl, wrapping detected files so that curl can upload them.

  See "curl --help" for information about curl options.
HELP
  exit
}

if [ -z "$1" ]; then
  display_help
fi


# argument filter
args=()
_i=1
for arg in "$@"; do
  case "$arg" in
    -h)
      display_help
    ;;
    --help)
      display_help
    ;;
  esac

  if [[ -f $arg ]]
  then
    args+=("-F")
    args+=("file=@$arg")
  else
    args+=("$arg")
  fi
done

curl "${args[@]}"


```

### Usage

```
$ quickupload <URI> [FILES]
```

## Quickdrop

[Quickdrop](http://xyne.archlinux.ca/projects/quickserve/quickdrop.tar.xz) is a Javascript-based drag'n'drop file uploader page for Quickserve.

### Dropzone.js

Quickdrop is powered by [Dropzone.js](http://www.dropzonejs.com/), which was created by Matias Meno and released under the MIT license. The necessary files can be retrieved using the included script `get_dropzone.sh`. The script also contains links to the Dropzone.js homepage and Git repository.

### Usage

To use Quickdrop, download and extract the [Quickdrop](http://xyne.archlinux.ca/projects/quickserve/quickdrop.tar.xz) archive. Share the extracted directory via Quickserve and enabled uploads with the `--upload` option, then navigate to `quickdrop.htm`. You can use Quickserve's `--index` option to display the page automatically when a user opens the directory.

## Screenshots

![](http://xyne.archlinux.ca/projects/quickserve/screenshots/quickserve_01.png)

![](http://xyne.archlinux.ca/projects/quickserve/screenshots/quickserve_02.png)

## Help Message

```
$ quickserve --help

usage: MulticastQuickserve.py [-h] [--root <directory path>] [-f <filepath>]
                              [--filter <ix><regex>] [--filterlist <filepath>]
                              [--show-hidden] [--upload <filepath>]
                              [--allow-overwrite] [--motd <filepath>]
                              [--index <filename>]
                              [--peer <scheme>://<host>:<port>/]
                              [--list-remote] [-a <interface|address>]
                              [-p <port>] [--ipv6] [--auth <string> <string>]
                              [--authfile <filepath>] [--ssl]
                              [--certfile <filepath>] [--keyfile <filepath>]
                              [--req-cert] [--ca-certs <filepath>]
                              [--multicast]
                              [--multicast-address <interface|address>]
                              [--multicast-port <port>]
                              [--multicast-group <group>]
                              [--multicast-interval <seconds>]
                              [--multicast-interface <interface|address>]
                              [<filepath> [<filepath> ...]]

MulticastQuickserve.py - Quickserve with p2p support.

positional arguments:
  <filepath>            The files and directories to share. These will appear
                        with the same name in server root. Use the filelist
                        option for more advanced features.

optional arguments:
  -h, --help            show this help message and exit

File Download Options:
  --root <directory path>
                        If given then the directory will be treated as the
                        root of the server and all other paths will be
                        ignored. This is useful for testing static websites.
                        Similar and more complicated effects can be achieved
                        using a JSON filelist.
  -f <filepath>, --filelist <filepath>
                        A file to specify what to share on the server. If it
                        is a flat plaintext file then each line will be
                        treated as though it had been passed on the command
                        line. If it is a JSON file then it should be a map of
                        server paths to either single files or lists of
                        directories. The contents of each directory in the
                        list will appear as a single directory on the server.
  --filter <ix><regex>  Regular expressions to filter paths that appear on the
                        server. These will be applied in order when
                        determining which files to share.
  --filterlist <filepath>
                        A file consisting of filter expressions on each line.
                        The file will be reloaded if it is modified.
  --show-hidden         Share hidden files and directories.

File Upload Options:
  --upload <filepath>   Enable uploads and save uploaded files in given
                        directory.
  --allow-overwrite     Allow uploaded files to overwrite existing files in
                        upload directory.

Content Options:
  --motd <filepath>     The MOTD message to display on the server. The file
                        will be reloaded if it is updated.
  --index <filename>    The name of the index page to display (if present)
                        when a directory is requested.

MulticastQuickserve Options:
  --peer <scheme>://<host>:<port>/
                        Static peers. Pass the option multiple times if
                        necessary. Example: "http://10.0.0.2:8000/"
  --list-remote         Include remote files in directory listings.

Server Address and Port:
  Configure the server's listening address and port.

  -a <interface|address>, --address <interface|address>
                        Bind the server to this address. By default the server
                        will listen on all interfaces.
  -p <port>, --port <port>
                        Set the server port (default: 8000)
  --ipv6                Use IPv6.

HTTP Authentication:
  HTTP digest authentication via a username and password.

  --auth <string> <string>
                        HTTP digest username and password. Multiple pairs may
                        be passed.
  --authfile <filepath>
                        The path to a file containing alternating lines of
                        usernames and passwords.

SSL (HTTPS):
  Options for wrapping sockets in SSL for encrypted connections. Simply
  enabling SSL does not guarantee a secure connection and it is the user's
  responsibility to check that the implementation is correct and secure and
  that the server is properly configured. You can find information about
  generating self-signed certificates in the OpenSSL FAQ:
  http://www.openssl.org/support/faq.html

  --ssl                 Enable SSL (HTTPS).
  --certfile <filepath>
                        The path to the server's certificate.
  --keyfile <filepath>  The path to the server's key.
  --req-cert            Require a certificate from the client.
  --ca-certs <filepath>
                        Set the path to a file containing concatenated CA
                        certificates for verifying the client certificate.
                        This defaults to the server's own certificate.

Multicast Options:
  Options that affect the behavior of the multicast (sub)server system.

  --multicast           Use multicasting to announce presence and detect other
                        servers.
  --multicast-address <interface|address>
                        The address to which to bind the multicast server
                        socket. Default: 0.0.0.0.
  --multicast-port <port>
                        The multicast port. Default: 15680.
  --multicast-group <group>
                        The multicast group. Default: 224.3.45.66.
  --multicast-interval <seconds>
                        The multicast announcement interval. Default: 300.
  --multicast-interface <interface|address>
                        The interface or address through which to announce
                        presence with multicast packets. If not given, all
                        interfaces are used.
```

## CHANGELOG

### 2013-05-10

- rewrote from scratch in Python 3
- added support for unified directories (multiple local directories can appear as one on the server)
- removed some options
- changed other options
- added more options (e.g. `--index`, `--unhide`)
- moved backend to python3-threaded_servers

### 2012-12-18

- added "--motd" option
- added workaround for handling multiple ranges in download request
- restructured some logging messages

### 2010.10.02

- added support for requiring client certificates

### 2010.09.28

- added regex filtering options (see "--help" and "--filterhelp")

### 2010.09.18

- added "text=plain" query to enable plaintext file listings (see above)

### 2010.09.18

- moved backend to [python2-xynehttpserver](http://xyne.archlinux.ca/projects/python2-xynehttpserver)
- added SSL (HTTPS) support

### 2010.07.14

- added threading support to handle multiple connection simultaneously
- fixed "Content-Range" bug
- added support for HEAD requests
- re-organized HTML generation
  - cleaner code
  - W3C XHTML Validation
  - W3C CSS Validation
- re-organized startup and info page output
- added icon
- fixed MIMEtype detection bug
- added "Content-Encoding" header



[^cyberpolice]: Expect the cyberpolice