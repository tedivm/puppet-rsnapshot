# Contributions Welcome!

Pull Requests and Community Contributions are the bread and butter of open
source software. Every contribution- from bug reports to feature requests, typos
to full new features- are greatly appreciated.


## Important Guidelines

* One Item Per Pull Request or Issue. This makes it much easier to review code
  and merge it back in, and prevents issues with one request from blocking
  another.

* Read the LICENSE document and make sure you understand it, because your code
  is going to be released under it.

* Be prepared to make revisions. Don't be discouraged if you're asked to make
  changes, as that is just another step towards refining the code and getting it
  merged back in.

* Remember to add the relevant documentation, both inline and in the README.


## Code Styling

This project follows the PSR standards set forth by
[The Puppet Language Style Guide](https://docs.puppetlabs.com/guides/style_guide.html).

All code most follow these standards to be accepted. The easiest way to confirm
this is to run `puppet-lind` once the new changes are finished.

    gem install puppet-lint
    puppet-lint --fix ./

