Dominus
=======

Dominus is a world class command line tool to improve workflow with iOS projects. It allows completely automated deployment from console and is fully integrated with [Travis CI](https://travis-ci.com).

# Features

- Loading new devices from TestFlight to Apple Developer Portal
- Updating provisioning profiles
- Building and testing application with automatic scheme detection
- Deployment to TestFlight

In addition to features available on Travis CI, Dominus can also help with:

- Project creation

# Installation

To add Dominus to a project just add a Git submodule. Make sure you update it before launching.

# Configuration file

**Make sure to add configuration file to .gitignore, so it is not commited to the repository as it can contain sensitive data.** On Travis always use encrypted environment variables (can be done with travis encrypt command) instead.

# Travis CI

To integrate run the next command:

`dominus.sh setup travis`

This command will generate `.travis.yml` file which is then easily commited to your repository.

Contact
======

Dal Rupnik

- [legoless](https://github.com/legoless) on **GitHub**
- [@thelegoless](https://twitter.com/thelegoless) on **Twitter**
- [legoless@arvystate.net](mailto:legoless@arvystate.net)

License
======

Dominus is available under the MIT license. See [LICENSE](https://github.com/Legoless/Dominus/blob/master/LICENSE) file for more information.
