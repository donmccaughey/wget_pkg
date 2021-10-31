# GNU Wget 1.21.2 for macOS

This project builds a signed and notarized universal macOS installer package
for [GNU Wget][1], a command line tool for retrieving files using HTTP, HTTPS,
FTP and FTPS.  It contains the source distribution of Wget 1.21.2 and [OpenSSL
1.1.1l][2].

[1]: https://www.gnu.org/software/wget/
[2]: https://www.openssl.org

## Building

The [`Makefile`][3] in the project root directory builds the installer package.
The following makefile variables can be set from the command line:

- `APP_SIGNING_ID`: The name of the 
    [Apple _Developer ID Application_ certificate][4] used to sign the 
    `nginx` executable.  The certificate must be installed on the build 
    machine's Keychain.  Defaults to "Developer ID Application: Donald 
    McCaughey" if not specified.
- `INSTALLER_SIGNING_ID`: The name of the 
    [Apple _Developer ID Installer_ certificate][4] used to sign the 
    installer.  The certificate must be installed on the build machine's
    Keychain.  Defaults to "Developer ID Installer: Donald McCaughey" if 
    not specified.
- `TMP`: The name of the directory for intermediate files.  Defaults to 
    "`./tmp`" if not specified.

[3]: https://github.com/donmccaughey/wget_pkg/blob/main/Makefile
[4]: https://developer.apple.com/account/resources/certificates/list

To build and sign the executable and installer, run:

        $ make [APP_SIGNING_ID="<cert name 1>"] [INSTALLER_SIGNING_ID="<cert name 2>"] [TMP="<build dir>"]

Intermediate files are generated in the temp directory; the signed installer 
package is written into the project root with the name `wget-1.21.2.pkg`.  

To remove all generated files (including the signed installer), run:

        $ make clean

## License

The installer and related scripts are copyright (c) 2021 Don McCaughey.  Wget
and the installer are distributed under the GNU General Public License, version
3.  OpenSSL is distributed under its own BSD-style license.  See the
`wget/COPYING` and the `openssl/LICENSE` files for details. 

